# Token and cost observability

`nex usage` reports local usage for OpenCode and, where present, Claude Code. It
does not call a billing API and it does not invent quota numbers.

## Commands

```bash
nex usage                 # markdown report, last 30 days
nex usage report 7        # last 7 days
nex usage today           # ccusage table for today
nex usage daily           # ccusage opencode daily (pass-through)
nex usage session         # per-session table
nex usage session <id>    # one session as JSON
nex usage models          # per-model tokens, cache, estimated cost
nex usage history         # append-only session records from the hook
nex usage export          # JSON snapshot under ~/.local/state/nex/usage/
nex usage quota           # what quota data is actually available
nex usage all             # ccusage across every detected agent
nex usage claude          # ccusage claude (requires Claude data)
```

## What is measured

For OpenCode:

- input tokens
- output tokens
- cache-read tokens
- cache-write (cache creation) tokens
- per-model breakdown
- per-session breakdown
- estimated cost

Sources:

- `ccusage opencode daily|session --json`
- OpenCode's `~/.local/share/opencode/opencode.db` (`session_v2` columns
  `tokens_input`, `tokens_output`, `tokens_reasoning`, `tokens_cache_read`,
  `tokens_cache_write`, `cost`)
- `opencode stats --json` for the tool-level view

For Claude Code:

- `ccusage claude ...` reads the local transcript/project data when present.
- The session-end hook parses `message.usage` from the transcript for the local
  history file.

## Cache metrics

The report includes a cache hit ratio:

```text
cache_read / (input + cache_read + cache_write)
```

A high ratio is normal for long sessions with prompt caching. A cache-write spike
followed by low reads usually means the prompt prefix is changing (for example,
editing an early instruction file) or the session is being restarted often.

## Estimated cost

Cost is computed by ccusage from model pricing (LiteLLM data, with an offline
cache). It is an estimate:

- it may lag provider price changes
- it does not include subscription discounts, credits, or taxes
- unknown models may show zero or no cost

Set `NEX_USAGE_ONLINE=1` to refresh pricing. The default uses the offline cache
so reports work without network access.

## Subscription quotas

The CLIs do not expose plan quotas in a stable machine-readable way:

- **Claude Code**: run `/usage` in the session after `claude auth login`. The
  local CLI reports authentication status, not remaining plan allowance.
- **OpenCode Console**: plan limits are shown in the Console account page; the
  CLI and local database expose spend, not quota.

`nex usage quota` prints exactly this, plus local auth status. It deliberately
does not guess.

## Local history

`session-end.sh` calls `scripts/usage-log.sh`, which appends one deduplicated
record per session to:

```text
~/.local/state/nex/usage/sessions.jsonl
```

Each record contains timestamp, tool, session ID, project, model, agent, token
counts, cache counts, and estimated cost. This survives OpenCode database
changes better than a live query and is easy to export.

## Privacy

Usage records contain session IDs, project paths, model names, and token counts.
They do not contain prompts or responses. The deterministic session handoff in
`~/.local/state/nex/sessions/` may contain short excerpts of the last exchange;
treat that directory as private (`0700`/`0600`).
