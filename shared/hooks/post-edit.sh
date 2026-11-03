#!/usr/bin/env bash
# Post-edit hook: fast, selective checks. Exit 2 feeds the message back to the
# agent (Claude Code) or is logged by the OpenCode plugin.
set -uo pipefail
# shellcheck source=_lib.sh
source "$(dirname "$0")/_lib.sh"

payload=$(cat 2>/dev/null || true)
file=$(hook_field "$payload" '.tool_input.file_path')
[ -n "$file" ] || file=$(hook_field "$payload" '.tool_input.path')
[ -n "$file" ] || file=$(hook_field "$payload" '.input.filePath')
[ -n "$file" ] || file=$(hook_field "$payload" '.input.path')
[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

case "$file" in
  */node_modules/*|*/.git/*|*/dist/*|*/build/*|*/vendor/*|*/.venv/*) exit 0 ;;
esac

root=$(project_root "$(dirname "$file")")
cd "$root" 2>/dev/null || exit 0
ext="${file##*.}"
failures=0
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

run_check() {
  local label="$1"; shift
  if ! timeout 15 "$@" >"$tmp" 2>&1; then
    failures=$((failures + 1))
    printf 'nex post-edit: %s failed for %s\n' "$label" "$file" >&2
    sed -n '1,40p' "$tmp" >&2
    printf '\n' >&2
  fi
}

prettier_bin=""
[ -x node_modules/.bin/prettier ] && prettier_bin="node_modules/.bin/prettier"
[ -z "$prettier_bin" ] && have prettier && prettier_bin=$(command -v prettier)
prettier_config=0
for candidate in .prettierrc .prettierrc.json .prettierrc.yml .prettierrc.yaml .prettierrc.js .prettierrc.cjs prettier.config.js prettier.config.cjs prettier.config.mjs; do
  [ -e "$candidate" ] && prettier_config=1
done
if [ "$prettier_config" = 0 ] && [ -f package.json ] && jq -e '.prettier? // empty' package.json >/dev/null 2>&1; then
  prettier_config=1
fi
case "$ext" in
  js|jsx|ts|tsx|json|css|scss|less|html|md|mdx|yaml|yml)
    if [ -n "$prettier_bin" ] && [ "$prettier_config" = 1 ]; then
      run_check "prettier --check" "$prettier_bin" --check "$file"
    fi
    ;;
esac

eslint_bin=""
[ -x node_modules/.bin/eslint ] && eslint_bin="node_modules/.bin/eslint"
[ -z "$eslint_bin" ] && have eslint && eslint_bin=$(command -v eslint)
eslint_config=0
for candidate in eslint.config.js eslint.config.mjs eslint.config.cjs eslint.config.ts .eslintrc .eslintrc.json .eslintrc.js .eslintrc.cjs; do
  [ -e "$candidate" ] && eslint_config=1
done
case "$ext" in
  js|jsx|ts|tsx|mjs|cjs)
    if [ -n "$eslint_bin" ] && [ "$eslint_config" = 1 ]; then
      run_check "eslint" "$eslint_bin" --no-error-on-unmatched-pattern "$file"
    elif [ -n "$eslint_bin" ] && [ -f package.json ] && jq -e '.eslintConfig? // empty' package.json >/dev/null 2>&1; then
      run_check "eslint" "$eslint_bin" --no-error-on-unmatched-pattern "$file"
    fi
    ;;
esac

case "$ext" in
  sh|bash)
    if have shellcheck; then run_check "shellcheck" shellcheck -x "$file"; fi
    run_check "bash -n" bash -n "$file"
    ;;
  py)
    run_check "python syntax" python3 -c 'import ast,sys; ast.parse(open(sys.argv[1], encoding="utf-8").read())' "$file"
    ;;
  json)
    if have jq; then run_check "jq empty" jq empty "$file"; fi
    ;;
  js|mjs|cjs)
    run_check "node --check" node --check "$file"
    ;;
esac

if [ "$failures" -gt 0 ]; then
  log_hook post-edit "failed $file"
  exit 2
fi
log_hook post-edit "ok $file"
exit 0
