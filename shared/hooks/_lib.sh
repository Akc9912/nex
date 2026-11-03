#!/usr/bin/env bash
# Shared helpers for nex hooks. Sourced, never executed directly.
# shellcheck shell=bash

NEX_ROOT="${NEX_ROOT:-$HOME/nex}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nex"
SESSIONS_DIR="$STATE_DIR/sessions"
USAGE_DIR="$STATE_DIR/usage"
LOG_FILE="$STATE_DIR/hooks.log"
umask 077
mkdir -p "$SESSIONS_DIR" "$USAGE_DIR"

have() { command -v "$1" >/dev/null 2>&1; }

hook_field() {
  # hook_field <json> <jq expression>
  local json="$1" expr="$2"
  [ -n "$json" ] || return 0
  printf '%s' "$json" | jq -r "$expr // empty" 2>/dev/null || true
}

project_root() {
  local start="${1:-$PWD}"
  git -C "$start" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$start"
}

log_hook() {
  printf '%s\t%s\t%s\n' "$(date -Iseconds)" "${1:-hook}" "${2:-}" >>"$LOG_FILE" 2>/dev/null || true
}

# Print a markdown-ish context block, capped to a sane size.
session_git_context() {
  local root="$1"
  if ! git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'git: not a repository\n'
    return 0
  fi
  local branch changes last
  branch=$(git -C "$root" branch --show-current 2>/dev/null || true)
  [ -n "$branch" ] || branch="(detached)"
  changes=$(git -C "$root" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  last=$(git -C "$root" log -1 --format='%h %s' 2>/dev/null || true)
  printf 'git: branch %s | %s changed path(s)\n' "$branch" "$changes"
  [ -n "$last" ] && printf 'last commit: %s\n' "$last"
}

stack_hint() {
  local root="$1"
  if [ -f "$root/package.json" ]; then
    local pm="npm"
    [ -f "$root/pnpm-lock.yaml" ] && pm="pnpm"
    [ -f "$root/yarn.lock" ] && pm="yarn"
    [ -f "$root/bun.lockb" ] || [ -f "$root/bun.lock" ] && pm="bun"
    printf 'stack: Node (%s)\n' "$pm"
  fi
  [ -f "$root/pyproject.toml" ] && printf 'stack: Python (pyproject)\n'
  [ -f "$root/Cargo.toml" ] && printf 'stack: Rust (cargo)\n'
  [ -f "$root/go.mod" ] && printf 'stack: Go\n'
  if [ -x "$root/scripts/verify.sh" ]; then
    printf 'verify: ./scripts/verify.sh\n'
  elif [ -x "$root/.nex/verify" ]; then
    printf 'verify: ./.nex/verify\n'
  fi
}

usage_today_line() {
  have ccusage || return 0
  local json
  json=$(timeout 3 ccusage opencode daily --json --last 1 -O 2>/dev/null) || return 0
  [ -n "$json" ] || return 0
  printf '%s' "$json" | jq -r '
    [.daily[]] as $d
    | ($d | map(.totalCost // 0) | add // 0) as $cost
    | ($d | map((.inputTokens // 0) + (.outputTokens // 0) + (.cacheReadTokens // 0) + (.cacheCreationTokens // 0)) | add // 0) as $tokens
    | if $tokens > 0 then
        "usage today: \($tokens) tokens | $\(($cost * 100 | round) / 100) estimated"
      else empty end
  ' 2>/dev/null || true
}
