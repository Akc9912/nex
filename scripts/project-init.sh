#!/usr/bin/env bash
# Adopt an existing project: generate missing nex files without overwriting.
# Usage: nex project init [directory]
set -euo pipefail
ROOT="${NEX_ROOT:-$HOME/nex}"
dest="${1:-$PWD}"
[ -d "$dest" ] || { printf 'nex project init: directory not found: %s\n' "$dest" >&2; exit 1; }
dest=$(cd "$dest" && pwd)

created=0
skipped=0
make_file() {
  # make_file <relative path> <content via stdin>
  local rel="$1"
  local full="$dest/$rel"
  if [ -e "$full" ]; then
    printf '  skip   %s (exists)\n' "$rel"
    skipped=$((skipped + 1))
    # consume stdin
    cat >/dev/null
    return 0
  fi
  mkdir -p "$(dirname "$full")"
  cat > "$full"
  printf '  create %s\n' "$rel"
  created=$((created + 1))
}

# Detect stack
stack=""
test_cmds=""
build_cmds=""
if [ -f "$dest/package.json" ]; then
  stack="Node.js"
  if [ -f "$dest/pnpm-lock.yaml" ]; then stack="Node.js (pnpm)"; pm="pnpm"
  elif [ -f "$dest/yarn.lock" ]; then stack="Node.js (yarn)"; pm="yarn"
  elif [ -f "$dest/bun.lockb" ] || [ -f "$dest/bun.lock" ]; then stack="Node.js (bun)"; pm="bun"
  else stack="Node.js (npm)"; pm="npm"; fi
  if jq -e '.scripts.test' "$dest/package.json" >/dev/null 2>&1; then test_cmds="$pm test"; fi
  if jq -e '.scripts.build' "$dest/package.json" >/dev/null 2>&1; then build_cmds="$pm run build"; fi
  if jq -e '.scripts.lint' "$dest/package.json" >/dev/null 2>&1; then lint_cmds="$pm run lint"; fi
fi
[ -f "$dest/pyproject.toml" ] && { stack="${stack:+$stack, }Python (pyproject)"; test_cmds="${test_cmds:-pytest}"; }
[ -f "$dest/requirements.txt" ] && { stack="${stack:+$stack, }Python"; test_cmds="${test_cmds:-pytest}"; }
[ -f "$dest/Cargo.toml" ] && { stack="${stack:+$stack, }Rust (cargo)"; test_cmds="${test_cmds:-cargo test}"; build_cmds="${build_cmds:-cargo build}"; }
[ -f "$dest/go.mod" ] && { stack="${stack:+$stack, }Go"; test_cmds="${test_cmds:-go test ./...}"; build_cmds="${build_cmds:-go build ./...}"; }
[ -z "$stack" ] && stack="Unknown (fill in manually)"

# AGENTS.md
make_file "AGENTS.md" <<EOF
# Project instructions

Stack: $stack

## Conventions
- Follow existing naming, module layout, error handling, and test conventions.
- Keep changes small and scoped.

## Development commands
- Test: ${test_cmds:-<fill in>}
- Build: ${build_cmds:-<fill in>}
- Lint: ${lint_cmds:-<fill in>}

## Architecture
<!-- Describe modules, data flow, and invariants here. -->

## Decisions
<!-- Record architectural decisions (ADR-style) here. -->
EOF

# CLAUDE.md symlink to AGENTS.md
if [ ! -e "$dest/CLAUDE.md" ]; then
  ln -s AGENTS.md "$dest/CLAUDE.md"
  printf '  create CLAUDE.md -> AGENTS.md (symlink)\n'
  created=$((created + 1))
else
  printf '  skip   CLAUDE.md (exists)\n'
  skipped=$((skipped + 1))
fi

# scripts/verify.sh
verify_content='#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
'
if [ -n "$test_cmds" ]; then
  verify_content+="
# Run tests
$test_cmds
"
fi
if [ -n "$lint_cmds" ]; then
  verify_content+="
# Run lint
$lint_cmds
"
fi
if [ -z "$test_cmds" ] && [ -z "$lint_cmds" ]; then
  verify_content+="
echo 'No test/lint command detected; add them to scripts/verify.sh'
"
fi
make_file "scripts/verify.sh" <<< "$verify_content"
chmod +x "$dest/scripts/verify.sh" 2>/dev/null || true

# .nex directory
make_file ".nex/README.md" <<'EOF'
# .nex

Project-local nex markers and hooks.
- verify: executable at .nex/verify (optional)
- tests-on-commit: create this file to run tests on every commit
EOF

make_file ".nex/pre-commit" <<'EOF'
#!/usr/bin/env bash
# Optional project-specific pre-commit checks.
exit 0
EOF
chmod +x "$dest/.nex/pre-commit" 2>/dev/null || true

# .gitignore additions (append if missing)
if [ -f "$dest/.gitignore" ]; then
  if ! grep -q '^.nex/state/' "$dest/.gitignore" 2>/dev/null; then
    printf '\n# nex\n.nex/state/\n' >> "$dest/.gitignore"
    printf '  update .gitignore (appended nex entries)\n'
    created=$((created + 1))
  fi
else
  make_file ".gitignore" <<'EOF'
# nex
.nex/state/
EOF
fi

printf '\nnex project init: %s created, %s skipped in %s\n' "$created" "$skipped" "$dest"
printf 'Next: review AGENTS.md and scripts/verify.sh, then run ./scripts/verify.sh\n'