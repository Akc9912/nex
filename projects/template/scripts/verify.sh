#!/usr/bin/env bash
# Project verifier used by the nex Stop hook. Keep this fast and deterministic.
# Edit the stack-specific section when the project adds checks.
set -uo pipefail
fail=0
ran=0

run() {
  printf '==> %s\n' "$*"
  ran=$((ran + 1))
  if ! "$@"; then
    fail=$((fail + 1))
    printf 'FAILED: %s\n' "$*" >&2
  fi
}

if [ -f package.json ]; then
  pm="npm"
  [ -f pnpm-lock.yaml ] && pm="pnpm"
  [ -f yarn.lock ] && pm="yarn"
  { [ -f bun.lockb ] || [ -f bun.lock ]; } && pm="bun"
  has_script() { jq -e --arg s "$1" '.scripts[$s]? // empty' package.json >/dev/null 2>&1; }
  has_script typecheck && run "$pm" run typecheck
  has_script lint && run "$pm" run lint
  has_script test && run "$pm" test
fi

if [ -f pyproject.toml ] || [ -f pytest.ini ]; then
  command -v ruff >/dev/null 2>&1 && run ruff check .
  command -v pytest >/dev/null 2>&1 && run pytest -q
fi

if [ -f Cargo.toml ]; then
  run cargo test
fi

if [ -f go.mod ]; then
  run go test ./...
fi

if [ -d scripts ] && command -v shellcheck >/dev/null 2>&1; then
  mapfile -t shells < <(find scripts -name '*.sh' -type f)
  [ "${#shells[@]}" -gt 0 ] && run shellcheck -x "${shells[@]}"
fi

if [ "$ran" -eq 0 ]; then
  printf 'No checks configured yet. Add scripts to package.json, or edit scripts/verify.sh.\n'
  exit 0
fi

if [ "$fail" -gt 0 ]; then
  printf '\n%s check(s) failed.\n' "$fail" >&2
  exit 1
fi
printf '\nAll checks passed.\n'
