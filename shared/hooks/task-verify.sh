#!/usr/bin/env bash
# Stop hook: verify the task before the agent declares completion.
# Exit 2 blocks the stop once and returns the failure to the agent.
set -uo pipefail
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

payload=$(cat 2>/dev/null || true)
if [ "$(hook_field "$payload" '.stop_hook_active')" = "true" ]; then
  exit 0
fi
if [ "${NEX_SKIP_STOP_VERIFY:-0}" = "1" ]; then
  exit 0
fi

cwd=$(hook_field "$payload" '.cwd')
cwd="${cwd:-${NEX_CWD:-$PWD}}"
cd "$cwd" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# A repository can have no commits yet. In that case compare the working tree
# and index against the empty tree instead of the missing HEAD ref.
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  base=HEAD
else
  base=$(git hash-object -t tree /dev/null)
fi

# Nothing changed since the last commit? Then there is nothing to verify.
if [ "$base" = "HEAD" ]; then
  git diff --quiet HEAD 2>/dev/null || dirty=1
else
  dirty=1
fi
[ -z "$(git status --porcelain 2>/dev/null)" ] && dirty=0
[ "${dirty:-0}" = "0" ] && exit 0

# Cheap correctness checks that apply to every project.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
if ! git diff --check "$base" >"$tmp" 2>&1; then
  {
    printf 'nex verify: whitespace errors in the working tree:\n'
    sed -n '1,40p' "$tmp"
  } >&2
  exit 2
fi
if git diff "$base" -U0 | grep -E '^\+(<<<<<<<|>>>>>>>)' >/dev/null 2>&1; then
  printf 'nex verify: unresolved merge conflict markers remain.\n' >&2
  exit 2
fi

verifier=""
[ -x scripts/verify.sh ] && verifier="./scripts/verify.sh"
[ -x .nex/verify ] && verifier="./.nex/verify"
if [ -z "$verifier" ]; then
  printf 'nex verify: changes are present and no project verifier exists. Run the relevant tests before finishing.\n' >&2
  log_hook task-verify "no verifier"
  exit 0
fi

# Avoid re-running the same verification on every stop of an unchanged tree.
root=$(git rev-parse --show-toplevel)
hash=$(git diff "$base" 2>/dev/null | sha256 | cut -d' ' -f1)
marker="$STATE_DIR/verify-$(printf '%s' "$root" | sha256 | cut -c1-12).hash"
if [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$hash" ]; then
  exit 0
fi

if ! run_timeout 180 "$verifier" >"$tmp" 2>&1; then
  {
    printf 'nex verify: %s failed; task is not complete.\n' "$verifier"
    tail -60 "$tmp"
    printf '\nFix the failure, or set NEX_SKIP_STOP_VERIFY=1 only if the user accepts the risk.\n'
  } >&2
  log_hook task-verify "failed $verifier"
  exit 2
fi

printf '%s\n' "$hash" >"$marker" 2>/dev/null || true
log_hook task-verify "ok $verifier"
exit 0
