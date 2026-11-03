#!/usr/bin/env bash
# Append one deduplicated session usage record to the local history.
# Called by session-end.sh; can also be run manually with hook JSON on stdin.
set -uo pipefail
# shellcheck source=_lib.sh
source "$(dirname "$0")/../shared/hooks/_lib.sh"

payload=$(cat 2>/dev/null || true)
tool="${NEX_HOOK_TOOL:-$(hook_field "$payload" '.tool')}"
[ -n "$tool" ] || tool=opencode
session_id="${NEX_SESSION_ID:-$(hook_field "$payload" '.session_id')}"
[ -n "$session_id" ] || exit 0
cwd="${NEX_CWD:-$(hook_field "$payload" '.cwd')}"
cwd="${cwd:-$PWD}"
root=$(project_root "$cwd")

model="" agent="" title=""
input=0 output=0 reasoning=0 cache_read=0 cache_write=0 cost="null"

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
      cost=$(printf '%s' "$row" | jq -r '.[0].cost // "null"')
      input=$(printf '%s' "$row" | jq -r '.[0].tokens_input // 0')
      output=$(printf '%s' "$row" | jq -r '.[0].tokens_output // 0')
      reasoning=$(printf '%s' "$row" | jq -r '.[0].tokens_reasoning // 0')
      cache_read=$(printf '%s' "$row" | jq -r '.[0].tokens_cache_read // 0')
      cache_write=$(printf '%s' "$row" | jq -r '.[0].tokens_cache_write // 0')
    fi
  fi
else
  transcript=$(hook_field "$payload" '.transcript_path')
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    usage=$(jq -s '
      [.[] | .message.usage? // empty] as $u
      | {
          input: ($u | map(.input_tokens // 0) | add // 0),
          output: ($u | map(.output_tokens // 0) | add // 0),
          cache_read: ($u | map(.cache_read_input_tokens // 0) | add // 0),
          cache_write: ($u | map(.cache_creation_input_tokens // 0) | add // 0),
          model: ([.[] | .message.model? // empty] | last // "")
        }
    ' "$transcript" 2>/dev/null || true)
    if [ -n "$usage" ]; then
      input=$(printf '%s' "$usage" | jq -r '.input // 0')
      output=$(printf '%s' "$usage" | jq -r '.output // 0')
      cache_read=$(printf '%s' "$usage" | jq -r '.cache_read // 0')
      cache_write=$(printf '%s' "$usage" | jq -r '.cache_write // 0')
      model=$(printf '%s' "$usage" | jq -r '.model // empty')
    fi
    c=$(jq -rs '[.[] | .costUSD? // empty] | add // empty' "$transcript" 2>/dev/null || true)
    [ -n "$c" ] && cost="$c"
  fi
fi

mkdir -p "$USAGE_DIR"
file="$USAGE_DIR/sessions.jsonl"
touch "$file"
chmod 600 "$file"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

record=$(jq -cn \
  --arg ts "$(date -Iseconds)" \
  --arg tool "$tool" \
  --arg session_id "$session_id" \
  --arg cwd "$root" \
  --arg project "$(basename "$root")" \
  --arg model "$model" \
  --arg agent "$agent" \
  --arg title "$title" \
  --argjson input "$input" \
  --argjson output "$output" \
  --argjson reasoning "$reasoning" \
  --argjson cache_read "$cache_read" \
  --argjson cache_write "$cache_write" \
  --argjson cost "$cost" \
  '{ts: $ts, tool: $tool, session_id: $session_id, cwd: $cwd, project: $project,
    model: (if $model == "" then null else $model end),
    agent: (if $agent == "" then null else $agent end),
    title: (if $title == "" then null else $title end),
    input: $input, output: $output, reasoning: $reasoning,
    cache_read: $cache_read, cache_write: $cache_write, cost: $cost}')

(
  flock 9
  jq -c --arg id "$session_id" 'select(.session_id != $id)' "$file" >"$tmp" 2>/dev/null || true
  cat "$tmp" >"$file" 2>/dev/null || true
  printf '%s\n' "$record" >>"$file"
) 9>"$file.lock"

rm -f "$file.lock" 2>/dev/null || true
exit 0
