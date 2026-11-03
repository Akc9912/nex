#!/usr/bin/env bash
# SessionStart hook for Claude Code and OpenCode.
# Prints a small context block. Claude adds stdout to the session context;
# the OpenCode plugin injects the same text into its context hook.
set -uo pipefail
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

payload=$(cat 2>/dev/null || true)
cwd=$(hook_field "$payload" '.cwd')
cwd="${cwd:-${NEX_CWD:-$PWD}}"
[ -d "$cwd" ] || cwd="$PWD"
root=$(project_root "$cwd")

printf '<nex-context>\n'
printf 'date: %s\n' "$(date -Iseconds)"
printf 'cwd: %s\n' "$cwd"
printf 'project: %s\n' "$(basename "$root")"
session_git_context "$root"
stack_hint "$root"
usage_today_line
printf 'memory: Engram is available; use mem_context / mem_search before related work.\n'
printf 'rules: global rules are loaded from AGENTS.md; project instructions override them.\n'
printf '</nex-context>\n'

log_hook session-start "$root"
exit 0
