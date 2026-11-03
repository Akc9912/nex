#!/usr/bin/env bash
# Pre-commit hook. Exit 2 blocks the commit. Run directly or via Claude/OpenCode.
set -uo pipefail
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

payload=$(cat 2>/dev/null || true)
cwd=$(hook_field "$payload" '.cwd')
cwd="${cwd:-${NEX_CWD:-$PWD}}"
cd "$cwd" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
git diff --cached --quiet && exit 0

failures=0
fail() {
  failures=$((failures + 1))
  printf 'nex pre-commit: %s\n' "$1" >&2
}
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Whitespace and conflict markers.
if ! git diff --cached --check >"$tmp" 2>&1; then
  fail "staged whitespace errors"
  sed -n '1,40p' "$tmp" >&2
fi
if git diff --cached -U0 | grep -E '^\+(<<<<<<<|>>>>>>>)' >/dev/null 2>&1; then
  fail "unresolved merge conflict markers"
fi

staged=()
while IFS= read -r -d '' file; do
  staged+=("$file")
done < <(git diff --cached --name-only --diff-filter=ACMR -z)
[ "${#staged[@]}" -gt 0 ] || exit 0

# Obvious secret-bearing files and oversized blobs.
for file in "${staged[@]}"; do
  base=$(basename "$file")
  case "$base" in
    .env|.env.*|*.pem|*.key|*.p12|*.pfx|*.keystore|id_rsa|id_ed25519)
      case "$base" in
        *.example|*.sample|*.template) : ;;
        *) fail "refusing to commit secret-bearing file: $file" ;;
      esac
      ;;
  esac
  if [ -f "$file" ]; then
    size=$(wc -c <"$file" 2>/dev/null | tr -d ' ')
    size=${size:-0}
    if [ "$size" -gt 2097152 ]; then
      fail "large staged file (${size} bytes): $file"
    fi
  fi
done

# Secret scanning.
if have gitleaks; then
  if ! run_timeout 60 gitleaks protect --staged --no-banner --redact --exit-code 1 >"$tmp" 2>&1; then
    # gitleaks exits 1 when leaks are found; other failures are also reported.
    if grep -qi 'leak\|secret\|finding' "$tmp"; then
      fail "gitleaks found staged secrets"
    else
      fail "gitleaks could not complete"
    fi
    sed -n '1,40p' "$tmp" >&2
  fi
else
  printf 'nex pre-commit: gitleaks is not installed; secret scan skipped (install it with system-install.sh)\n' >&2
fi

# Targeted lint of staged files.
eslint_bin=""
[ -x node_modules/.bin/eslint ] && eslint_bin="node_modules/.bin/eslint"
[ -z "$eslint_bin" ] && have eslint && eslint_bin=$(command -v eslint)
eslint_config=0
for candidate in eslint.config.js eslint.config.mjs eslint.config.cjs eslint.config.ts .eslintrc .eslintrc.json .eslintrc.js .eslintrc.cjs; do
  [ -e "$candidate" ] && eslint_config=1
done
js_files=()
for file in "${staged[@]}"; do
  case "$file" in
    *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs) [ -f "$file" ] && js_files+=("$file") ;;
  esac
done
if [ "${#js_files[@]}" -gt 0 ] && [ -n "$eslint_bin" ] && [ "$eslint_config" = 1 ]; then
  if ! run_timeout 60 "$eslint_bin" --no-error-on-unmatched-pattern "${js_files[@]}" >"$tmp" 2>&1; then
    fail "eslint reported errors in staged files"
    sed -n '1,60p' "$tmp" >&2
  fi
fi

sh_files=()
for file in "${staged[@]}"; do
  case "$file" in *.sh|*.bash) [ -f "$file" ] && sh_files+=("$file") ;; esac
done
if [ "${#sh_files[@]}" -gt 0 ] && have shellcheck; then
  if ! run_timeout 60 shellcheck -x "${sh_files[@]}" >"$tmp" 2>&1; then
    fail "shellcheck reported errors in staged files"
    sed -n '1,60p' "$tmp" >&2
  fi
fi

# Project-specific pre-commit hook.
if [ -x .nex/pre-commit ]; then
  if ! run_timeout 120 ./.nex/pre-commit >"$tmp" 2>&1; then
    fail ".nex/pre-commit failed"
    sed -n '1,60p' "$tmp" >&2
  fi
fi

# Tests are opt-in to keep commits fast. Enable per project with
# .nex/tests-on-commit or for one commit with NEX_PRECOMMIT_TESTS=1.
if [ "${NEX_PRECOMMIT_TESTS:-0}" = "1" ] || [ -f .nex/tests-on-commit ]; then
  if [ -f package.json ] && jq -e '.scripts.test? // empty' package.json >/dev/null 2>&1; then
    if ! run_timeout 180 npm test --silent >"$tmp" 2>&1; then
      fail "npm test failed"
      tail -40 "$tmp" >&2
    fi
  elif [ -f pyproject.toml ] || [ -f pytest.ini ]; then
    if have pytest && ! run_timeout 180 pytest -q >"$tmp" 2>&1; then
      fail "pytest failed"
      tail -40 "$tmp" >&2
    fi
  fi
fi

if [ "$failures" -gt 0 ]; then
  printf 'nex pre-commit: %s check(s) failed; commit blocked.\n' "$failures" >&2
  log_hook pre-commit "blocked $failures"
  exit 2
fi
log_hook pre-commit "ok"
exit 0
