#!/usr/bin/env bash
# Install user-level tools into ~/.local without touching system paths.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin"

if ! command -v npm >/dev/null 2>&1; then
  printf 'npm is missing. Install nodejs/npm first (official Arch package).\n' >&2
  exit 1
fi

npm install -g --prefix "$HOME/.local" \
  @colbymchenry/codegraph@1.6.2 \
  @playwright/mcp@0.0.84 \
  chrome-devtools-mcp@1.12.0 \
  ccusage@20.0.48 \
  tokscale@4.21.0 \
  knip@6.44.1 \
  prettier@3.9.10 \
  eslint@10.14.0

# Engram: pinned release, checksum verified.
ENGRAM_VERSION="3.6.1"
if command -v engram >/dev/null 2>&1 && engram --version 2>/dev/null | grep -q "$ENGRAM_VERSION"; then
  printf 'engram %s already installed\n' "$ENGRAM_VERSION"
else
  case "$(uname -s)" in
    Linux) os=linux ;;
    Darwin) os=darwin ;;
    *) printf 'Unsupported OS: %s (on Windows, use WSL2)\n' "$(uname -s)" >&2; exit 1 ;;
  esac
  arch=$(uname -m)
  case "$arch" in
    x86_64) asset="engram_${ENGRAM_VERSION}_${os}_amd64.tar.gz" ;;
    aarch64|arm64) asset="engram_${ENGRAM_VERSION}_${os}_arm64.tar.gz" ;;
    *) printf 'Unsupported architecture: %s\n' "$arch" >&2; exit 1 ;;
  esac
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  base="https://github.com/Gentleman-Programming/engram/releases/download/v${ENGRAM_VERSION}"
  printf 'Downloading Engram %s...\n' "$ENGRAM_VERSION"
  curl -fsSL "$base/checksums.txt" -o "$tmp/checksums.txt"
  curl -fsSL "$base/$asset" -o "$tmp/$asset"
  if command -v sha256sum >/dev/null 2>&1; then sha_check="sha256sum -c -"; else sha_check="shasum -a 256 -c -"; fi
  (cd "$tmp" && grep "  $asset$" checksums.txt | $sha_check)
  tar -xzf "$tmp/$asset" -C "$tmp" engram
  install -m 0755 "$tmp/engram" "$HOME/.local/bin/engram"
fi

# Semgrep is not in the official Arch repositories; use uv's isolated tool env.
if command -v uv >/dev/null 2>&1; then
  uv tool install semgrep
else
  printf 'uv is missing; install it with sudo bash scripts/system-install.sh, then run: uv tool install semgrep\n' >&2
fi

# Claude Code official native installer, only if missing.
if ! command -v claude >/dev/null 2>&1; then
  printf 'Installing Claude Code with the official installer...\n'
  tmp=$(mktemp)
  curl -fsSL https://claude.ai/install.sh -o "$tmp"
  bash "$tmp"
  rm -f "$tmp"
else
  printf 'claude already installed: %s\n' "$(claude --version 2>/dev/null | head -1)"
fi

if ! command -v opencode >/dev/null 2>&1; then
  printf 'OpenCode is not installed. Install it from https://opencode.ai (or the official installer), then re-run this script.\n' >&2
fi

printf '\nUser tools installed under %s\n' "$HOME/.local/bin"
printf 'Run `exec bash`, then `nex verify`.\n'
