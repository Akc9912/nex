#!/usr/bin/env bash
# Local usage reporting for OpenCode and Claude Code.
# Data comes from ccusage (local session files) and OpenCode's own database.
set -euo pipefail
# shellcheck source=_lib.sh
source "$HOME/nex/shared/hooks/_lib.sh"

usage() {
  cat <<'EOF'
Usage: nex usage [command] [args]

Commands:
  report [days]   Markdown summary: totals, cache, models, top sessions (default 30)
  today           Today's OpenCode usage (ccusage table)
  daily [args]    ccusage opencode daily (pass through --since/--until)
  session [id]    Per-session usage; filter to one session ID when given
  models [days]   Per-model table with cache and estimated cost
  history         Append-only session records written by the session-end hook
  export          Write a JSON snapshot to the nex state directory
  quota           What subscription-quota information is actually available
  all [args]      ccusage across every detected agent (Claude, OpenCode, ...)
  claude [args]   ccusage claude (requires Claude Code usage data)
  help            This message

Costs are estimates from LiteLLM pricing, not a bill. Use NEX_USAGE_ONLINE=1
to refresh pricing instead of using ccusage's offline cache.
EOF
}

need_ccusage() {
  have ccusage || { printf 'nex usage: ccusage is not installed (run scripts/install-user-tools.sh)\n' >&2; exit 1; }
}

# ccusage's offline pricing flag. Use an array so it disappears cleanly when
# online pricing is requested instead of passing an empty argument.
offline=()
[ "${NEX_USAGE_ONLINE:-0}" = "1" ] || offline=(-O)

since_date() {
  date -d "$1 days ago" +%F 2>/dev/null || date -v-"$1"d +%F
}

cmd="${1:-report}"
shift || true

case "$cmd" in
  help|-h|--help) usage ;;

  today)
    need_ccusage
    # shellcheck disable=SC2046
    exec ccusage opencode daily --last 1 ${offline[@]+"${offline[@]}"}
    ;;

  daily)
    need_ccusage
    # shellcheck disable=SC2046
    exec ccusage opencode daily ${offline[@]+"${offline[@]}"} "$@"
    ;;

  session)
    need_ccusage
    if [ "${1:-}" != "" ]; then
      id="$1"; shift
      json=$(ccusage opencode session --json ${offline[@]+"${offline[@]}"} 2>/dev/null) || {
        printf 'nex usage: could not read OpenCode usage\n' >&2; exit 1;
      }
      printf '%s' "$json" | jq --arg id "$id" '
        .sessions[] | select(.sessionId == $id)
      '
      exit 0
    fi
    # shellcheck disable=SC2046
    exec ccusage opencode session --since "$(since_date 30)" ${offline[@]+"${offline[@]}"} "$@"
    ;;

  models)
    need_ccusage
    days="${1:-30}"
    json=$(ccusage opencode daily --json --since "$(since_date "$days")" ${offline[@]+"${offline[@]}"} 2>/dev/null) || {
      printf 'nex usage: could not read OpenCode usage\n' >&2; exit 1;
    }
    printf '%s' "$json" | jq -r '
      [.daily[].modelBreakdowns[]]
      | group_by(.modelName)
      | map({
          model: .[0].modelName,
          input: (map(.inputTokens // 0) | add // 0),
          output: (map(.outputTokens // 0) | add // 0),
          cacheRead: (map(.cacheReadTokens // 0) | add // 0),
          cacheWrite: (map(.cacheCreationTokens // 0) | add // 0),
          cost: (map(.cost // 0) | add // 0)
        })
      | sort_by(-.cost)
      | (["model","input","output","cache read","cache write","cost est."] | @tsv),
        (.[] | [.model, .input, .output, .cacheRead, .cacheWrite, ((.cost * 10000 | round) / 10000)] | @tsv)
    ' | column -t -s $'\t'
    ;;

  report)
    need_ccusage
    days="${1:-30}"
    daily=$(ccusage opencode daily --json --since "$(since_date "$days")" ${offline[@]+"${offline[@]}"} 2>/dev/null) || {
      printf 'nex usage: could not read OpenCode usage\n' >&2; exit 1;
    }
    sessions=$(ccusage opencode session --json --since "$(since_date "$days")" ${offline[@]+"${offline[@]}"} 2>/dev/null) || sessions='{"sessions":[]}'
    printf '# nex usage report\n\n'
    printf 'Source: local OpenCode data via ccusage. Period: last %s day(s).\n' "$days"
    printf 'Cost is an estimate from model pricing, not an invoice.\n\n'
    printf '%s' "$daily" | jq -r '
      [.daily[]] as $d
      | ($d | map(.inputTokens // 0) | add // 0) as $input
      | ($d | map(.outputTokens // 0) | add // 0) as $output
      | ($d | map(.cacheReadTokens // 0) | add // 0) as $cacheRead
      | ($d | map(.cacheCreationTokens // 0) | add // 0) as $cacheWrite
      | ($d | map(.totalCost // 0) | add // 0) as $cost
      | ($input + $cacheRead + $cacheWrite) as $denom
      | "## Totals\n\n" +
        "| metric | value |\n|---|---:|\n" +
        "| input tokens | \($input) |\n" +
        "| output tokens | \($output) |\n" +
        "| cache read tokens | \($cacheRead) |\n" +
        "| cache write tokens | \($cacheWrite) |\n" +
        "| cache hit ratio | \(if $denom > 0 then (($cacheRead * 10000 / $denom | round) / 100) else 0 end)% |\n" +
        "| estimated cost | $\((($cost * 10000 | round) / 10000)) |\n"
    '
    printf '%s' "$daily" | jq -r '
      [.daily[].modelBreakdowns[]]
      | group_by(.modelName)
      | map({
          model: .[0].modelName,
          input: (map(.inputTokens // 0) | add // 0),
          output: (map(.outputTokens // 0) | add // 0),
          cacheRead: (map(.cacheReadTokens // 0) | add // 0),
          cacheWrite: (map(.cacheCreationTokens // 0) | add // 0),
          cost: (map(.cost // 0) | add // 0)
        })
      | sort_by(-.cost)
      | "## Models\n\n| model | input | output | cache read | cache write | cost est. |\n|---|---:|---:|---:|---:|---:|\n" +
        (map("| \(.model) | \(.input) | \(.output) | \(.cacheRead) | \(.cacheWrite) | $\(((.cost * 10000 | round) / 10000)) |") | join("\n")) + "\n"
    '
    printf '%s' "$sessions" | jq -r '
      [.sessions[]] | sort_by(-.totalCost) | .[0:10]
      | "## Top sessions\n\n| session | models | input | output | cache | total | cost est. |\n|---|---|---:|---:|---:|---:|---:|\n" +
        (map("| \(.sessionId | .[0:18])… | \(.modelsUsed | join(", ")) | \(.inputTokens) | \(.outputTokens) | \(.cacheReadTokens + .cacheCreationTokens) | \(.totalTokens) | $\(((.totalCost * 10000 | round) / 10000)) |") | join("\n")) + "\n"
    '
    if [ -f "$USAGE_DIR/sessions.jsonl" ]; then
      count=$(wc -l <"$USAGE_DIR/sessions.jsonl" | tr -d ' ')
      printf 'Local session records: %s (see `nex usage history`).\n' "$count"
    fi
    ;;

  history)
    file="$USAGE_DIR/sessions.jsonl"
    [ -f "$file" ] || { printf 'No session history yet. It is written by the session-end hook.\n'; exit 0; }
    jq -rs '
      (["date","tool","session","model","input","output","cache r","cache w","cost est."] | @tsv),
      (.[] | [.ts, .tool, (.session_id | .[0:18]), (.model // "-"), .input, .output, .cache_read, .cache_write, (.cost // "-")] | @tsv)
    ' "$file" | column -t -s $'\t'
    ;;

  export)
    need_ccusage
    mkdir -p "$USAGE_DIR"
    out="$USAGE_DIR/export-$(date +%F-%H%M%S).json"
    daily=$(ccusage opencode daily --json ${offline[@]+"${offline[@]}"} 2>/dev/null)
    sessions=$(ccusage opencode session --json ${offline[@]+"${offline[@]}"} 2>/dev/null)
    jq -n --arg ts "$(iso_now)" --argjson daily "$daily" --argjson sessions "$sessions" \
      '{exported_at: $ts, source: "ccusage opencode", daily: $daily, sessions: $sessions}' >"$out"
    printf '%s\n' "$out"
    ;;

  quota)
    exec "$HOME/nex/scripts/quota.sh"
    ;;

  all)
    need_ccusage
    # shellcheck disable=SC2046
    exec ccusage daily ${offline[@]+"${offline[@]}"} "$@"
    ;;

  claude)
    need_ccusage
    # shellcheck disable=SC2046
    exec ccusage claude "$@"
    ;;

  *)
    printf 'nex usage: unknown command: %s\n\n' "$cmd" >&2
    usage
    exit 2
    ;;
esac
