#!/usr/bin/env bash
# Verify the nex installation: tools, links, config, generated files, hooks.
set -uo pipefail
ROOT="${NEX_ROOT:-$HOME/nex}"
fail=0
warn=0
pass=0

ok()   { printf '  ok    %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  FAIL  %s\n' "$1"; fail=$((fail + 1)); }
warn_() { printf '  warn  %s\n' "$1"; warn=$((warn + 1)); }
have() { command -v "$1" >/dev/null 2>&1; }

printf 'nex verify\n\n'

printf 'Platform\n'
case "$(uname -s)" in
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      ok "WSL2 detected"
      case "$ROOT" in /mnt/*) warn_ "nex is on the Windows filesystem ($ROOT); clone it inside WSL (~/nex) for correct permissions and speed" ;; esac
      for tool in claude opencode node; do
        case "$(command -v "$tool" 2>/dev/null)" in /mnt/*) warn_ "$tool resolves to a Windows binary; install it inside WSL" ;; esac
      done
    else
      ok "Linux"
    fi
    ;;
  Darwin) ok "macOS $(sw_vers -productVersion 2>/dev/null)" ;;
  *) bad "unsupported platform $(uname -s); on Windows, run nex inside WSL2" ;;
esac
printf '\n'

printf 'Tools\n'
for tool in claude opencode engram codegraph ccusage openusage node npm jq sqlite3 git rg; do
  if have "$tool"; then ok "$tool: $("$tool" --version 2>/dev/null | head -1)"; else bad "$tool missing"; fi
done
for tool in gitleaks trivy semgrep chromium uv shellcheck gh; do
  if have "$tool"; then ok "$tool: $("$tool" --version 2>/dev/null | head -1)"; else warn_ "$tool missing (see docs/install.md)"; fi
done
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ok "$HOME/.local/bin is on PATH" ;;
  *) warn_ "$HOME/.local/bin is not on PATH in this shell; run: exec bash" ;;
esac

printf '\nGenerated content\n'
if node "$ROOT/scripts/render.mjs" --check >/dev/null 2>&1; then
  ok "agents and AGENTS.md are current"
else
  bad "generated agents are stale (run: nex render)"
fi
for file in "$ROOT"/claude/agents/*.md "$ROOT"/opencode/agents/*.md; do
  [ -e "$file" ] || { bad "no generated agents found"; break; }
  if ! head -1 "$file" | grep -q '^---$'; then bad "missing frontmatter: $file"; fi
done
ok "$(find "$ROOT/claude/agents" -name '*.md' | wc -l | tr -d ' ') Claude agent(s), $(find "$ROOT/opencode/agents" -name '*.md' | wc -l | tr -d ' ') OpenCode agent(s)"

printf '\nConfiguration syntax\n'
if jq empty "$ROOT/claude/settings.json" >/dev/null 2>&1; then ok "claude/settings.json is valid JSON"; else bad "claude/settings.json is invalid"; fi
if node "$ROOT/scripts/jsonc-check.mjs" "$ROOT/opencode/opencode.jsonc" >/dev/null 2>&1; then ok "opencode/opencode.jsonc is valid JSONC"; else bad "opencode/opencode.jsonc is invalid"; fi
if grep -q '"servers"' "$ROOT/opencode/opencode.jsonc"; then ok "OpenCode uses mcp.servers (V2)"; else bad "OpenCode is missing mcp.servers"; fi
if grep -q '"permission"' "$ROOT/opencode/opencode.jsonc"; then bad "OpenCode contains V1 'permission' key"; fi
if [ -f "$HOME/.config/opencode/opencode.json" ]; then warn_ "V1-style ~/.config/opencode/opencode.json exists (run: nex link)"; fi

printf '\nSymlinks\n'
check_link() {
  local dest="$1" src="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok "$dest"
  elif [ -e "$dest" ]; then
    bad "$dest is not a symlink to $src"
  else
    bad "$dest is missing (run: nex link)"
  fi
}
check_link "$HOME/.claude/CLAUDE.md" "$ROOT/shared/AGENTS.md"
check_link "$HOME/.claude/settings.json" "$ROOT/claude/settings.json"
check_link "$HOME/.config/opencode/AGENTS.md" "$ROOT/shared/AGENTS.md"
check_link "$HOME/.config/opencode/opencode.jsonc" "$ROOT/opencode/opencode.jsonc"
check_link "$HOME/.config/opencode/plugins/nex.ts" "$ROOT/opencode/plugins/nex.ts"
check_link "$HOME/.local/bin/nex" "$ROOT/bin/nex"
for skill in "$ROOT"/shared/skills/*; do
  name=$(basename "$skill")
  [ -L "$HOME/.claude/skills/$name" ] || warn_ "Claude skill link missing: $name"
  [ -L "$HOME/.config/opencode/skills/$name" ] || warn_ "OpenCode skill link missing: $name"
done

printf '\nHooks\n'
for hook in "$ROOT"/shared/hooks/*.sh; do
  if [ ! -x "$hook" ]; then bad "not executable: $hook"; fi
  if ! bash -n "$hook" 2>/dev/null; then bad "syntax error: $hook"; fi
done
ok "hook scripts are executable and syntactically valid"
if have shellcheck; then
  if shellcheck -x --severity=warning "$ROOT"/shared/hooks/*.sh "$ROOT"/scripts/*.sh "$ROOT"/bin/nex >/dev/null 2>&1; then
    ok "shellcheck clean"
  else
    warn_ "shellcheck reported warnings (run it directly to inspect)"
  fi
fi
if bash "$ROOT/tests/hooks.sh" >/dev/null 2>&1; then
  ok "hook smoke tests pass"
else
  bad "hook smoke tests failed (run: nex hooks test)"
fi

printf '\nIntegrations\n'
if have claude; then
  if claude mcp list >/dev/null 2>&1; then ok "claude mcp list succeeds"; else warn_ "claude mcp list failed"; fi
  if claude auth status --json 2>/dev/null | jq -e '.loggedIn == true' >/dev/null 2>&1; then
    ok "Claude Code is authenticated"
  else
    warn_ "Claude Code is not authenticated (run: claude auth login)"
  fi
fi
if have opencode; then
  if opencode debug paths >/dev/null 2>&1; then ok "opencode CLI responds"; else warn_ "opencode CLI did not respond"; fi
fi
if have engram; then
  if engram doctor --json 2>/dev/null | jq -e '.status == "ok"' >/dev/null 2>&1; then
    ok "Engram doctor reports ok"
  else
    warn_ "Engram doctor did not report ok (run: engram doctor)"
  fi
fi
if have ccusage; then
  if ccusage opencode daily --json --last 1 -O >/dev/null 2>&1; then ok "ccusage can read OpenCode data"; else warn_ "ccusage could not read OpenCode data"; fi
fi

printf '\nSummary: %s passed, %s failed, %s warning(s)\n' "$pass" "$fail" "$warn"
if [ "$fail" -gt 0 ]; then
  printf 'Run `nex link` and `nex render` for link/generation issues; see docs/troubleshooting.md.\n'
  exit 1
fi
printf 'Environment is usable. Remaining interactive steps: authentication and OAuth consent.\n'
