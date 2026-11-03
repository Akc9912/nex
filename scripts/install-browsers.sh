#!/usr/bin/env bash
# Install Playwright's Chromium and, optionally, Chrome for Testing for the
# Chrome DevTools MCP. Chrome DevTools MCP does not officially support Chromium.
set -euo pipefail

printf 'Installing Playwright Chromium (used by playwright-mcp)...\n'
npx -y playwright install chromium

if [ "${1:-}" = "--with-chrome" ] || [ "${NEX_INSTALL_CHROME:-0}" = "1" ]; then
  printf 'Installing Chrome for Testing...\n'
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64) platform=linux64; bin="chrome" ;;
    Darwin-arm64) platform=mac-arm64; bin="Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" ;;
    Darwin-x86_64) platform=mac-x64; bin="Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" ;;
    *) printf 'No Chrome for Testing build for %s %s\n' "$(uname -s)" "$(uname -m)" >&2; exit 1 ;;
  esac
  dest="$HOME/.local/share/chrome-for-testing"
  mkdir -p "$dest"
  json=$(curl -fsSL https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json)
  url=$(printf '%s' "$json" | jq -r --arg p "$platform" '.channels.Stable.downloads.chrome[] | select(.platform == $p) | .url' | head -1)
  [ -n "$url" ] || { printf 'Could not resolve Chrome for Testing URL\n' >&2; exit 1; }
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  curl -fsSL "$url" -o "$tmp"
  rm -rf "${dest:?}/chrome-$platform"
  unzip -q "$tmp" -d "$dest"
  exe="$dest/chrome-$platform/$bin"
  ln -sfn "$exe" "$dest/chrome"
  "$exe" --version
  printf 'Chrome for Testing: %s\n' "$exe"
  printf 'Enable chrome-devtools in opencode.jsonc and pass:\n'
  printf '  --executablePath "%s"\n' "$exe"
else
  printf 'Skipped Chrome for Testing. Re-run with --with-chrome to install it.\n'
fi
