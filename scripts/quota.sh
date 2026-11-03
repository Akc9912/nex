#!/usr/bin/env bash
# Report only the quota information that is actually available locally.
# Never invent subscription limits.
set -uo pipefail

printf '# Quotas and plans\n\n'

printf '## Claude Code\n\n'
if command -v claude >/dev/null 2>&1; then
  status=$(claude auth status --json 2>/dev/null || true)
  if [ -n "$status" ]; then
    logged=$(printf '%s' "$status" | jq -r '.loggedIn // false')
    method=$(printf '%s' "$status" | jq -r '.authMethod // "none"')
    provider=$(printf '%s' "$status" | jq -r '.apiProvider // "unknown"')
    printf -- '- installed: yes\n'
    printf -- '- logged in: %s\n' "$logged"
    printf -- '- auth method: %s\n' "$method"
    printf -- '- API provider: %s\n' "$provider"
    if [ "$logged" = "true" ]; then
      printf -- '- usage/quota: run `/usage` inside Claude Code for the live plan view.\n'
    else
      printf -- '- quota unavailable until you run `claude auth login`.\n'
    fi
  else
    printf -- '- auth status unavailable.\n'
  fi
else
  printf -- '- Claude Code is not installed.\n'
fi

printf '\n## OpenCode\n\n'
if command -v opencode >/dev/null 2>&1; then
  printf -- '- integrations:\n'
  opencode auth list 2>/dev/null | sed 's/^/  - /' || printf -- '  - unavailable\n'
  printf -- '- quota: OpenCode Console does not expose plan quotas through the CLI or\n'
  printf -- '  the local database. Check the Console account page for plan limits.\n'
  printf -- '- local spend is available with `nex usage report` (estimate, not a bill).\n'
else
  printf -- '- OpenCode is not installed.\n'
fi

printf '\n## Local usage\n\n'
if command -v ccusage >/dev/null 2>&1; then
  printf -- '- run `nex usage report` for token/cache/cost detail from local data.\n'
  printf -- '- costs are estimated from model pricing; they are not subscription quotas.\n'
else
  printf -- '- ccusage is not installed.\n'
fi
