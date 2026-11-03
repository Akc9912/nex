#!/usr/bin/env bash
# SessionEnd hook: write a deterministic handoff and append a usage record.
# No model call is made here; this is evidence, not a narrative summary.
set -uo pipefail
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

payload=$(cat 2>/dev/null || true)
tool=$(hook_field "$payload" '.tool')
session_id=$(hook_field "$payload" '.session_id')
cwd=$(hook_field "$payload" '.cwd')
reason=$(hook_field "$payload" '.reason')

# Claude Code sends session_id/cwd; OpenCode is invoked by the plugin with tool set.
if [ -z "$tool" ]; then
  if [ -n "$(hook_field "$payload" '.transcript_path')" ]; then tool=claude; else tool=opencode; fi
fi
[ -n "$cwd" ] || cwd="${NEX_CWD:-$PWD}"
[ -d "$cwd" ] || cwd="$PWD"
root=$(project_root "$cwd")
[ -n "$session_id" ] || session_id="${NEX_SESSION_ID:-unknown-$(date +%s)}"

model="" agent="" tokens_input=0 tokens_output=0 tokens_cache_read=0 tokens_cache_write=0
tokens_reasoning=0 cost="" title=""

if [ "$tool" = "opencode" ]; then
  db="$HOME/.local/share/opencode/opencode.db"
  if [[ "$session_id" =~ ^[A-Za-z0-9_-]+$ ]] && have sqlite3 && [ -f "$db" ]; then
    row=$(sqlite3 -json "$db" \
      "SELECT title, model, agent, cost, tokens_input, tokens_output, tokens_reasoning, tokens_cache_read, tokens_cache_write FROM session_v2 WHERE id='$session_id' LIMIT 1;" \
      2>/dev/null || true)
    if [ -n "$row" ] && [ "$row" != "[]" ]; then
      title=$(printf '%s' "$row" | jq -r '.[0].title // empty')
      model=$(printf '%s' "$row" | jq -r '.[0].model // empty')
      agent=$(printf '%s' "$row" | jq -r '.[0].agent // empty')
      cost=$(printf '%s' "$row" | jq -r '.[0].cost // empty')
      tokens_input=$(printf '%s' "$row" | jq -r '.[0].tokens_input // 0')
      tokens_output=$(printf '%s' "$row" | jq -r '.[0].tokens_output // 0')
      tokens_reasoning=$(printf '%s' "$row" | jq -r '.[0].tokens_reasoning // 0')
      tokens_cache_read=$(printf '%s' "$row" | jq -r '.[0].tokens_cache_read // 0')
      tokens_cache_write=$(printf '%s' "$row" | jq -r '.[0].tokens_cache_write // 0')
    fi
  fi
else
  transcript=$(hook_field "$payload" '.transcript_path')
  if [ -n "$transcript" ] && [ -f "$transcript" ] && have jq; then
    usage=$(jq -s '
      [.[] | .message.usage? // empty] as $u
      | {
          input: ($u | map(.input_tokens // 0) | add // 0),
          output: ($u | map(.output_tokens // 0) | add // 0),
          cache_read: ($u | map(.cache_read_input_tokens // 0) | add // 0),
          cache_write: ($u | map(.cache_creation_input_tokens // 0) | add // 0)
        }
    ' "$transcript" 2>/dev/null || true)
    if [ -n "$usage" ]; then
      tokens_input=$(printf '%s' "$usage" | jq -r '.input // 0')
      tokens_output=$(printf '%s' "$usage" | jq -r '.output // 0')
      tokens_cache_read=$(printf '%s' "$usage" | jq -r '.cache_read // 0')
      tokens_cache_write=$(printf '%s' "$usage" | jq -r '.cache_write // 0')
    fi
    model=$(jq -rs '[.[] | .message.model? // empty] | last // empty' "$transcript" 2>/dev/null || true)
    cost=$(jq -rs '[.[] | .costUSD? // empty] | add // empty' "$transcript" 2>/dev/null || true)
  fi
fi

# Deterministic git snapshot.
git_block=""
if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$root" branch --show-current 2>/dev/null || true)
  [ -n "$branch" ] || branch="(detached)"
  git_block=$(printf 'branch: %s\n\n' "$branch")
  git_block+=$(git -C "$root" status --short 2>/dev/null | head -40)
  git_block+=$(printf '\n\ndiffstat:\n')
  git_block+=$(git -C "$root" diff --stat HEAD 2>/dev/null | tail -20)
else
  git_block="not a git repository"
fi

# Recent exchange excerpts, if a Claude transcript is available.
exchange=""
if [ "$tool" = "claude" ] && [ -n "${transcript:-}" ] && [ -f "$transcript" ]; then
  user_text=$(jq -r '
    select(.type == "user")
    | .message.content
    | if type == "string" then . else (map(.text? // "") | join(" ")) end
    | select(length > 0)
  ' "$transcript" 2>/dev/null | tail -1 | cut -c1-800)
  assistant_text=$(jq -r '
    select(.type == "assistant")
    | .message.content
    | if type == "string" then . else (map(.text? // "") | join(" ")) end
    | select(length > 0)
  ' "$transcript" 2>/dev/null | tail -1 | cut -c1-1600)
  [ -n "$user_text" ] && exchange+=$(printf '### Last user request\n%s\n\n' "$user_text")
  [ -n "$assistant_text" ] && exchange+=$(printf '### Last assistant response\n%s\n\n' "$assistant_text")
fi

stamp=$(date +%F)
safe_id=$(printf '%s' "$session_id" | tr -c 'A-Za-z0-9_-' '_' | cut -c1-40)
out="$SESSIONS_DIR/${stamp}-${safe_id}.md"

{
  printf '# Session %s\n\n' "$session_id"
  printf -- '- tool: %s\n' "$tool"
  printf -- '- date: %s\n' "$(date -Iseconds)"
  printf -- '- cwd: %s\n' "$root"
  printf -- '- reason: %s\n' "${reason:-unknown}"
  [ -n "$title" ] && printf -- '- title: %s\n' "$title"
  [ -n "$model" ] && printf -- '- model: %s\n' "$model"
  [ -n "$agent" ] && printf -- '- agent: %s\n' "$agent"
  printf -- '- tokens: input=%s output=%s cache_read=%s cache_write=%s reasoning=%s\n' \
    "$tokens_input" "$tokens_output" "$tokens_cache_read" "$tokens_cache_write" "$tokens_reasoning"
  [ -n "$cost" ] && printf -- '- estimated cost: $%s\n' "$cost"
  printf '\n## Git state\n\n```\n%s\n```\n\n' "${git_block:-no git state}"
  [ -n "$exchange" ] && printf '## Recent exchange\n\n%s\n' "$exchange"
  printf '## Handoff\n\n'
  printf 'This file is generated deterministically by `session-end.sh`. Use the\n'
  printf 'Engram `mem_session_summary` tool for the narrative handoff and next steps.\n'
} >"$out"
chmod 600 "$out"

# Append the same evidence to the usage history (deduplicated by usage-log.sh).
printf '%s' "$payload" | NEX_HOOK_TOOL="$tool" NEX_CWD="$root" NEX_SESSION_ID="$session_id" \
  "$NEX_ROOT/scripts/usage-log.sh" >/dev/null 2>&1 || true

if [ "${NEX_ENGRAM_AUTOSAVE:-0}" = "1" ] && have engram; then
  engram save "Session summary $stamp ${safe_id:0:8}" "$(cat "$out")" \
    --type session_summary --project "$(basename "$root")" >/dev/null 2>&1 || true
fi

log_hook session-end "$tool $session_id $out"
printf '%s\n' "$out"
exit 0
