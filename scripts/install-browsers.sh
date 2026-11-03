#!/usr/bin/env bash
# Install Playwright's Chromium and, optionally, Chrome for Testing for the
# Chrome DevTools MCP. Chrome DevTools MCP does not officially support Chromium.
set -euo pipefail

printf 'Installing Playwright Chromium (used by playwright-mcp)...\n'
npx -y playwright install chromium

if [ "${1:-}" = "--with-chrome" ] || [ "${NEX_INSTALL_CHROME:-0}" = "1" ]; then
  printf 'Installing Chrome for Testing...\n'
  dest="$HOME/.local/share/chrome-for-testing"
  mkdir -p "$dest"
  json=$(curl -fsSL https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json)
  url=$(printf '%s' "$json" | jq -r '.channels.Stable.downloads.chrome[] | select(.platform == "linux64") | .url' | head -1)
  [ -n "$url" ] || { printf 'Could not resolve Chrome for Testing URL\n' >&2; exit 1; }
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  curl -fsSL "$url" -o "$tmp"
  rm -rf "$dest/chrome-linux64"
  unzip -q "$tmp" -d "$dest"
  ln -sfn "$dest/chrome-linux64/chrome" "$dest/chrome"
  "$dest/chrome" --version
  printf 'Chrome for Testing: %s\n' "$dest/chrome-linux64/chrome"
  printf 'Enable chrome-devtools in opencode.jsonc and pass:\n'
  printf '  --executablePath %s\n' "$dest/chrome-linux64/chrome"
else
  printf 'Skipped Chrome for Testing. Re-run with --with-chrome to install it.\n'
fi
