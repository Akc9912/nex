#!/usr/bin/env bash
# Claude Code status line. Reads the status JSON on stdin and prints one line.
# Tolerant of missing fields and of ccusage being unavailable.
set -uo pipefail

input=$(cat 2>/dev/null || true)
if [ -z "$input" ]; then
  printf 'nex'
  exit 0
fi

get() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null || true; }

model=$(get '.model.display_name')
[ -n "$model" ] || model=$(get '.model.id')
[ -n "$model" ] || model=$(get '.model')
dir=$(get '.workspace.current_dir')
[ -n "$dir" ] || dir=$(get '.cwd')
[ -n "$dir" ] || dir="$PWD"
cost=$(get '.cost.total_cost_usd')
pct=$(get '.context_window.used_percentage')
[ -n "$pct" ] || pct=$(get '.contextWindow.usedPercentage')

branch=""
if [ -n "$dir" ] && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)
  [ -n "$branch" ] || branch="detached"
fi

parts=("nex")
[ -n "$model" ] && parts+=("$model")
[ -n "$branch" ] && parts+=("$branch")
if [ -n "$cost" ]; then
  parts+=("$(printf '%.2f' "$cost" 2>/dev/null || printf '%s' "$cost")")
fi
if [ -n "$pct" ]; then
  parts+=("${pct}% ctx")
fi
printf '%s' "${parts[0]}"
for part in "${parts[@]:1}"; do printf ' | %s' "$part"; done
printf '\n'
