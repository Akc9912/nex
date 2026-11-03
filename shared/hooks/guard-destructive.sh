#!/usr/bin/env bash
# PreToolUse guard for shell commands. Exit 2 blocks the tool call and returns
# the message to the agent. This is a guardrail, not a sandbox.
set -uo pipefail
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

payload=$(cat 2>/dev/null || true)
cmd=$(hook_field "$payload" '.tool_input.command')
[ -n "$cmd" ] || cmd=$(hook_field "$payload" '.command')
[ -n "$cmd" ] || exit 0

if [ "${NEX_ALLOW_DESTRUCTIVE:-0}" = "1" ]; then
  exit 0
fi

deny() {
  log_hook guard-destructive "blocked: $1"
  {
    printf 'nex guard: blocked a potentially destructive command.\n'
    printf '  %s\n' "$cmd"
    printf 'Reason: %s\n' "$1"
    printf 'If this is intentional, ask the user and run it manually, or set\n'
    printf 'NEX_ALLOW_DESTRUCTIVE=1 for that single command after explicit approval.\n'
  } >&2
  exit 2
}

# Normalize whitespace for matching, but keep the original for display.
norm=$(printf '%s' "$cmd" | tr '\n\t' '  ' | sed 's/  */ /g')

# Remove privilege-escalation prefixes (sudo/doas and their options) at every
# command position so `sudo rm -rf /` is matched like `rm -rf /`.
strip_privilege() {
  printf '%s' "$1" \
    | sed -E 's/([;&|()])/ \1 /g' \
    | awk '
        {
          out = ""; in_priv = 0; need_arg = 0
          for (i = 1; i <= NF; i++) {
            t = $i
            if (in_priv) {
              if (need_arg) { need_arg = 0; continue }
              if (t ~ /^--$/) { in_priv = 0; continue }
              if (t ~ /^-/) {
                if (t ~ /^-[ugpChrtUD]$/) need_arg = 1
                continue
              }
              in_priv = 0
            }
            if (t ~ /(^|\/)(sudo|doas)$/) { in_priv = 1; continue }
            out = out (out == "" ? "" : " ") t
          }
          print out
        }'
}
scan=$(strip_privilege "$norm")

# Recursive deletes of root, home, cwd, parent, or a bare glob.
if printf '%s' "$scan" | grep -Eqi '(^|[;&|()][[:space:]]*)rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*-[a-zA-Z]*[rf][a-zA-Z]*[[:space:]]+(/|/\*|~|\$HOME|\$\{HOME\}|\.\.?|\*)([[:space:]]|$)'; then
  deny "recursive delete of a root, home, or current directory"
fi
if printf '%s' "$scan" | grep -Eqi '(^|[;&|()][[:space:]]*)rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*[[:space:]]+/(usr|etc|var|home|boot|dev|proc|sys)([[:space:]/]|$)'; then
  deny "recursive delete under a system directory"
fi

# Git history and working-copy destruction.
printf '%s' "$scan" | grep -Eqi '(^|[;&|][[:space:]]*)git[[:space:]]+reset[[:space:]]+--hard' && deny "git reset --hard discards uncommitted work"
printf '%s' "$scan" | grep -Eqi '(^|[;&|][[:space:]]*)git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f' && deny "git clean -f removes untracked work"
printf '%s' "$scan" | grep -Eqi '(^|[;&|][[:space:]]*)git[[:space:]]+checkout[[:space:]]+--[[:space:]]+\.' && deny "git checkout -- . discards working-tree changes"
printf '%s' "$scan" | grep -Eqi '(^|[;&|][[:space:]]*)git[[:space:]]+restore[[:space:]]+\.' && deny "git restore . discards working-tree changes"
if printf '%s' "$scan" | grep -Eqi '(^|[;&|][[:space:]]*)git[[:space:]]+push' && printf '%s' "$scan" | grep -Eqi '(--force([[:space:]]|$)|[[:space:]]-f([[:space:]]|$))' && ! printf '%s' "$scan" | grep -q -- '--force-with-lease'; then
  deny "force push; use --force-with-lease or ask the user"
fi
printf '%s' "$scan" | grep -Eqi '(^|[;&|][[:space:]]*)git[[:space:]]+(filter-branch|filter-repo)' && deny "history rewrite"

# Disk and system destruction.
printf '%s' "$scan" | grep -Eqi '(^|[;&|][[:space:]]*)(mkfs(\.[a-z0-9]+)?|wipefs|fdisk|parted|sgdisk)[[:space:]]' && deny "partition or filesystem modification"
printf '%s' "$scan" | grep -Eqi '(^|[;&|][[:space:]]*)dd[[:space:]].*of=/dev/' && deny "raw write to a block device"
printf '%s' "$scan" | grep -Eqi '>[[:space:]]*/dev/(sd|nvme|hd|vd)' && deny "redirect to a block device"
printf '%s' "$scan" | grep -Eqi '(^|[;&|][[:space:]]*)(shutdown|reboot|poweroff|halt)([[:space:]]|$)' && deny "system shutdown or reboot"
printf '%s' "$scan" | grep -Eqi 'chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/([[:space:]]|$)' && deny "world-writable root permissions"
printf '%s' "$scan" | grep -Eqi 'chown[[:space:]]+-R[[:space:]]+[^[:space:]]+[[:space:]]+/([[:space:]]|$)' && deny "recursive ownership change at root"
printf '%s' "$scan" | grep -Eqi 'find[[:space:]]+/[[:space:]].*-delete' && deny "find / -delete"

# Remote code execution pipes.
if printf '%s' "$scan" | grep -Eqi '(curl|wget)[^|]*\|[[:space:]]*(ba)?sh([[:space:]]|$)'; then
  deny "piping a remote script into a shell"
fi
printf '%s' "$scan" | grep -q ':(){[[:space:]]*:|:&' && deny "fork bomb"

# Database destruction.
printf '%s' "$scan" | grep -Eqi '\b(drop[[:space:]]+(database|table)|truncate[[:space:]]+table)\b' && deny "database or table destruction"
if printf '%s' "$scan" | grep -Eqi '\bdelete[[:space:]]+from[[:space:]]+[A-Za-z0-9_."]+\s*;' && ! printf '%s' "$scan" | grep -Eqi '\bwhere\b'; then
  deny "DELETE without WHERE"
fi

# User policy: commits carry no co-author trailers. Covers -m and heredoc
# messages; a message read from a file (-F <file>) is not inspected.
if printf '%s' "$scan" | grep -Eqi '(^|[;&|()][[:space:]]*)git[[:space:]]+([^;&|]*[[:space:]])?commit([[:space:]]|$)' \
  && printf '%s' "$cmd" | grep -qi 'co-authored-by:'; then
  deny "Co-Authored-By trailers are not allowed in commits; remove the trailer"
fi

exit 0
