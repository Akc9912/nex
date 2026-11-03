#!/usr/bin/env bash
# Install the official Arch packages needed by the environment.
# Run as root: sudo bash ~/nex/scripts/system-install.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  printf 'This script installs system packages and needs root.\n' >&2
  printf 'Run: sudo bash %s\n' "$0" >&2
  exit 1
fi

printf 'Installing official packages with pacman...\n'
pacman -S --needed --noconfirm \
  gitleaks \
  trivy \
  chromium \
  uv \
  shellcheck \
  github-cli

printf '\nInstalled versions:\n'
for tool in gitleaks trivy chromium uv shellcheck gh; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '  %-12s %s\n' "$tool" "$("$tool" --version 2>/dev/null | head -1)"
  else
    printf '  %-12s missing\n' "$tool"
  fi
done

printf '\nNext: bash ~/nex/scripts/install-user-tools.sh\n'
