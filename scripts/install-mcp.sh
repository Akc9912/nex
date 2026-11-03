#!/usr/bin/env bash
# Register MCP servers in Claude Code. OpenCode servers live in opencode.jsonc.
# OAuth servers still require an interactive `/mcp` or `claude mcp auth` flow.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

if ! command -v claude >/dev/null 2>&1; then
  printf 'claude is not installed; run install-user-tools.sh first.\n' >&2
  exit 1
fi

add_stdio() {
  local name="$1"; shift
  if claude mcp get "$name" >/dev/null 2>&1; then
    printf 'claude mcp: %s already registered\n' "$name"
    return 0
  fi
  claude mcp add --scope user "$name" -- "$@"
}

add_http() {
  local name="$1" url="$2"
  if claude mcp get "$name" >/dev/null 2>&1; then
    printf 'claude mcp: %s already registered\n' "$name"
    return 0
  fi
  claude mcp add --scope user --transport http "$name" "$url"
}

# Engram is normally registered by `engram setup claude-code`; keep it idempotent.
add_stdio engram engram mcp --tools=agent
add_stdio codegraph codegraph serve --mcp
add_stdio playwright playwright-mcp
add_http context7 https://mcp.context7.com/mcp

if [ "${1:-}" = "--all" ] || [ "${NEX_MCP_ALL:-0}" = "1" ]; then
  add_http github https://api.githubcopilot.com/mcp/
  add_http sentry https://mcp.sentry.dev/mcp
  add_http supabase https://mcp.supabase.com/mcp
  add_stdio chrome-devtools chrome-devtools-mcp
fi

printf '\nRegistered Claude MCP servers:\n'
claude mcp list
printf '\nFor OAuth servers, complete sign-in in Claude Code with /mcp.\n'
printf 'For OpenCode, run `opencode mcp list` after restarting it, then /mcps.\n'
