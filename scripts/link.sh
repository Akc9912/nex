#!/usr/bin/env bash
# Install or refresh symlinks from this repository into the native tool config
# directories. Idempotent. Conflicting real files are backed up, never deleted.
set -euo pipefail
ROOT="${NEX_ROOT:-$HOME/nex}"
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="${XDG_STATE_HOME:-$HOME/.local/state}/nex/backups/$STAMP"
CLAUDE="$HOME/.claude"
OPENCODE="$HOME/.config/opencode"
changed=0
backed_up=0

mkdir -p "$CLAUDE/agents" "$CLAUDE/commands" "$CLAUDE/skills" "$OPENCODE/agents" "$OPENCODE/commands" "$OPENCODE/skills" "$OPENCODE/plugins" "$HOME/.local/bin"

link_file() {
  local src="$1" dest="$2"
  [ -e "$src" ] || { printf 'link: missing source %s\n' "$src" >&2; return 1; }
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP/$(dirname "${dest#"$HOME"/}")"
    mv "$dest" "$BACKUP/${dest#"$HOME"/}"
    backed_up=$((backed_up + 1))
    printf 'link: backed up %s -> %s\n' "$dest" "$BACKUP/${dest#"$HOME"/}"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  changed=$((changed + 1))
  printf 'link: %s -> %s\n' "$dest" "$src"
}

link_children() {
  local src_dir="$1" dest_dir="$2"
  [ -d "$src_dir" ] || return 0
  for src in "$src_dir"/*; do
    [ -e "$src" ] || continue
    link_file "$src" "$dest_dir/$(basename "$src")"
  done
}

prune_generated() {
  local dest_dir="$1" src_dir="$2"
  [ -d "$dest_dir" ] || return 0
  for dest in "$dest_dir"/*; do
    [ -L "$dest" ] || continue
    target=$(readlink "$dest")
    case "$target" in
      "$src_dir"/*)
        [ -e "$target" ] || { rm -f "$dest"; printf 'link: pruned stale %s\n' "$dest"; changed=$((changed + 1)); }
        ;;
    esac
  done
}

# Shared instructions and skills.
link_file "$ROOT/shared/AGENTS.md" "$CLAUDE/CLAUDE.md"
link_file "$ROOT/shared/AGENTS.md" "$OPENCODE/AGENTS.md"
link_children "$ROOT/shared/skills" "$CLAUDE/skills"
link_children "$ROOT/shared/skills" "$OPENCODE/skills"

# Claude Code.
link_file "$ROOT/claude/settings.json" "$CLAUDE/settings.json"
link_children "$ROOT/claude/agents" "$CLAUDE/agents"
link_children "$ROOT/claude/commands" "$CLAUDE/commands"
prune_generated "$CLAUDE/agents" "$ROOT/claude/agents"
prune_generated "$CLAUDE/commands" "$ROOT/claude/commands"

# OpenCode.
link_file "$ROOT/opencode/opencode.jsonc" "$OPENCODE/opencode.jsonc"
link_file "$ROOT/opencode/plugins/nex.ts" "$OPENCODE/plugins/nex.ts"
link_children "$ROOT/opencode/agents" "$OPENCODE/agents"
link_children "$ROOT/opencode/commands" "$OPENCODE/commands"
prune_generated "$OPENCODE/agents" "$ROOT/opencode/agents"
prune_generated "$OPENCODE/commands" "$ROOT/opencode/commands"

# The CLI itself.
link_file "$ROOT/bin/nex" "$HOME/.local/bin/nex"

# Engram 3.6.1 writes ~/.config/opencode/opencode.json using the V1 MCP shape
# (mcp.<name> plus "enabled"). V2 requires mcp.servers.<name>. Keep a backup and
# remove the conflicting file so the V2 config is authoritative.
if [ -f "$OPENCODE/opencode.json" ]; then
  if jq -e '.mcp and (.mcp.servers | not)' "$OPENCODE/opencode.json" >/dev/null 2>&1; then
    mkdir -p "$BACKUP/.config/opencode"
    mv "$OPENCODE/opencode.json" "$BACKUP/.config/opencode/opencode.json"
    backed_up=$((backed_up + 1))
    printf 'link: moved V1-style Engram OpenCode config to %s\n' "$BACKUP/.config/opencode/opencode.json"
  fi
fi

# Make direct script use possible even without a render step.
chmod +x "$ROOT"/shared/hooks/*.sh "$ROOT"/scripts/*.sh "$ROOT"/bin/nex 2>/dev/null || true

# Add ~/.local/bin to interactive shells once.
add_path_block() {
  local file="$1"
  [ -e "$file" ] || touch "$file"
  if grep -q '^# >>> nex >>>$' "$file" 2>/dev/null; then return 0; fi
  {
    printf '\n# >>> nex >>>\n'
    printf 'export PATH="$HOME/.local/bin:$PATH"\n'
    printf '# <<< nex <<<\n'
  } >>"$file"
  printf 'link: added PATH block to %s\n' "$file"
}
add_path_block "$HOME/.bashrc"
add_path_block "$HOME/.profile"
if command -v zsh >/dev/null 2>&1; then add_path_block "$HOME/.zshrc"; fi

printf '\nlink: %s link(s) changed, %s file(s) backed up\n' "$changed" "$backed_up"
if [ "$backed_up" -gt 0 ]; then printf 'link: backups in %s\n' "$BACKUP"; fi
printf 'link: restart the terminal (or run `exec "$SHELL"`) so ~/.local/bin is on PATH.\n'
printf 'link: restart OpenCode so it reloads config, agents, and the plugin.\n'
