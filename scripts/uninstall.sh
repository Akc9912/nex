#!/usr/bin/env bash
# Remove nex symlinks from Claude Code and OpenCode config directories.
# Does not delete the repository or backups.
set -euo pipefail
ROOT="${NEX_ROOT:-$HOME/nex}"
CLAUDE="$HOME/.claude"
OPENCODE="$HOME/.config/opencode"
removed=0
for dest in \
  "$CLAUDE/CLAUDE.md" "$CLAUDE/settings.json" "$OPENCODE/AGENTS.md" \
  "$OPENCODE/opencode.jsonc" "$OPENCODE/plugins/nex.ts" "$HOME/.local/bin/nex"; do
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$ROOT"/* ] || [ -L "$dest" ]; then
    target=$(readlink "$dest" 2>/dev/null || true)
    case "$target" in
      "$ROOT"/*) rm -f "$dest"; removed=$((removed+1)); echo "removed $dest";;
    esac
  fi
done
for dir in "$CLAUDE/agents" "$CLAUDE/commands" "$CLAUDE/skills" "$OPENCODE/agents" "$OPENCODE/commands" "$OPENCODE/skills"; do
  [ -d "$dir" ] || continue
  for link in "$dir"/*; do
    [ -L "$link" ] || continue
    target=$(readlink "$link")
    case "$target" in
      "$ROOT"/*) rm -f "$link"; removed=$((removed+1)); echo "removed $link";;
    esac
  done
done
echo "nex uninstall: removed $removed symlink(s). Backups and repository are untouched."
echo "Remove PATH blocks from ~/.bashrc, ~/.profile, ~/.zshrc manually if desired."
