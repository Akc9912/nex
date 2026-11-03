#!/usr/bin/env bash
# Create a project from projects/template.
set -euo pipefail
ROOT="${NEX_ROOT:-$HOME/nex}"
TEMPLATE="$ROOT/projects/template"

usage() {
  printf 'Usage: nex project new <name> [parent-directory]\n'
  printf 'Default parent: %s\n' "${NEX_PROJECTS_DIR:-$HOME/Projects}"
}

[ "${1:-}" = "new" ] && shift
name="${1:-}"
[ -n "$name" ] || { usage >&2; exit 2; }
if ! printf '%s' "$name" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*$'; then
  printf 'Invalid project name: %s\n' "$name" >&2
  exit 2
fi
parent="${2:-${NEX_PROJECTS_DIR:-$HOME/Projects}}"
dest="$parent/$name"

[ -d "$TEMPLATE" ] || { printf 'Template missing: %s\n' "$TEMPLATE" >&2; exit 1; }
if [ -e "$dest" ]; then
  printf 'Refusing to overwrite existing path: %s\n' "$dest" >&2
  exit 1
fi

mkdir -p "$parent"
cp -a "$TEMPLATE" "$dest"

# Replace the project-name placeholder in text files.
while IFS= read -r -d '' file; do
  sed -i "s/__PROJECT__/$name/g" "$file"
done < <(find "$dest" -type f ! -path '*/.git/*' -print0)

# A single instruction file, two native names.
if [ ! -e "$dest/CLAUDE.md" ]; then
  ln -s AGENTS.md "$dest/CLAUDE.md"
fi

chmod +x "$dest/scripts"/*.sh 2>/dev/null || true
mkdir -p "$dest/.nex" "$dest/.opencode/agents" "$dest/.claude/agents"

if [ "${NEX_NO_GIT:-0}" != "1" ]; then
  git -C "$dest" init -q
fi

printf 'Created %s\n' "$dest"
printf '\nNext:\n'
printf '  cd %s\n' "$dest
printf '  codegraph init .          # optional: build the code index\n'
printf '  ./scripts/verify.sh       # run the project checks\n'
printf '  claude                    # or: opencode\n'
