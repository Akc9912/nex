#!/usr/bin/env bash
# Install the system packages needed by the environment.
# Supports Arch (pacman), Debian/Ubuntu (apt), Fedora/RHEL (dnf), openSUSE (zypper),
# Alpine (apk), and macOS (Homebrew). On Windows, run it inside WSL2.
# Linux: sudo bash ~/nex/scripts/system-install.sh
# macOS: bash ~/nex/scripts/system-install.sh   (Homebrew refuses to run as root)
set -euo pipefail

if [ "$(uname -s)" = Darwin ]; then
  if [ "$(id -u)" -eq 0 ]; then
    printf 'On macOS, run this script without sudo; Homebrew refuses to run as root.\n' >&2
    exit 1
  fi
  if ! command -v brew >/dev/null 2>&1; then
    printf 'Homebrew is required on macOS: https://brew.sh\n' >&2
    exit 1
  fi
  DISTRO_ID="macos"
else
  if [ "$(id -u)" -ne 0 ]; then
    printf 'This script installs system packages and needs root.\n' >&2
    printf 'Run: sudo bash %s\n' "$0" >&2
    exit 1
  fi
  if [ -f /etc/os-release ]; then
    . /etc/os-release
  else
    printf 'Cannot detect distribution: /etc/os-release missing.\n' >&2
    exit 1
  fi
  DISTRO_ID="${ID:-unknown}"
fi

detect_pm() {
  if [ "$DISTRO_ID" = macos ]; then echo brew; return; fi
  if command -v pacman >/dev/null 2>&1; then echo pacman; return; fi
  if command -v apt-get >/dev/null 2>&1; then echo apt; return; fi
  if command -v dnf >/dev/null 2>&1; then echo dnf; return; fi
  if command -v zypper >/dev/null 2>&1; then echo zypper; return; fi
  if command -v apk >/dev/null 2>&1; then echo apk; return; fi
  echo unknown
}

PM=$(detect_pm)
if [ "$PM" = unknown ]; then
  printf 'No supported package manager found (pacman/apt/dnf/zypper/apk/brew).\n' >&2
  exit 1
fi

printf 'Detected distribution: %s (package manager: %s)\n' "$DISTRO_ID" "$PM"

# Package name mapping per package manager.
# Format: "logical_name:pkg1 pkg2 ..."
case "$PM" in
  pacman)
    PKG_GITLEAKS="gitleaks"
    PKG_TRIVY="trivy"
    PKG_CHROMIUM="chromium"
    PKG_UV="uv"
    PKG_SHELLCHECK="shellcheck"
    PKG_GH="github-cli"
    INSTALL_CMD="pacman -S --needed --noconfirm"
    ;;
  apt)
    PKG_GITLEAKS="gitleaks"
    PKG_TRIVY="trivy"
    PKG_CHROMIUM="chromium-browser"
    PKG_UV=""
    PKG_SHELLCHECK="shellcheck"
    PKG_GH="gh"
    INSTALL_CMD="apt-get install -y"
    ;;
  dnf)
    PKG_GITLEAKS="gitleaks"
    PKG_TRIVY="trivy"
    PKG_CHROMIUM="chromium"
    PKG_UV="uv"
    PKG_SHELLCHECK="ShellCheck"
    PKG_GH="gh"
    INSTALL_CMD="dnf install -y"
    ;;
  zypper)
    PKG_GITLEAKS="gitleaks"
    PKG_TRIVY="trivy"
    PKG_CHROMIUM="chromium"
    PKG_UV="uv"
    PKG_SHELLCHECK="ShellCheck"
    PKG_GH="gh"
    INSTALL_CMD="zypper install -y"
    ;;
  apk)
    PKG_GITLEAKS="gitleaks"
    PKG_TRIVY="trivy"
    PKG_CHROMIUM="chromium"
    PKG_UV="uv"
    PKG_SHELLCHECK="shellcheck"
    PKG_GH="github-cli"
    INSTALL_CMD="apk add"
    ;;
  brew)
    PKG_GITLEAKS="gitleaks"
    PKG_TRIVY="trivy"
    # Playwright and Chrome for Testing cover browser needs on macOS.
    PKG_CHROMIUM=""
    PKG_UV="uv"
    PKG_SHELLCHECK="shellcheck"
    PKG_GH="gh"
    INSTALL_CMD="brew install"
    ;;
esac

# Update package index where applicable
case "$PM" in
  apt) apt-get update -qq ;;
  dnf) : ;;
  zypper) zypper refresh -q ;;
  apk) apk update -q ;;
  pacman|brew) : ;;
esac

install_pkg() {
  local name="$1" pkg="$2"
  if [ -z "$pkg" ]; then
    printf '  %-12s not available in %s repos (install manually)\n' "$name" "$PM"
    return 0
  fi
  if $INSTALL_CMD $pkg >/dev/null 2>&1; then
    printf '  %-12s ok\n' "$name"
  else
    printf '  %-12s FAILED (try manually: %s %s)\n' "$name" "$INSTALL_CMD" "$pkg" >&2
  fi
}

printf '\nInstalling packages...\n'
install_pkg gitleaks "$PKG_GITLEAKS"
install_pkg trivy "$PKG_TRIVY"
install_pkg chromium "$PKG_CHROMIUM"
install_pkg uv "$PKG_UV"
install_pkg shellcheck "$PKG_SHELLCHECK"
install_pkg gh "$PKG_GH"

printf '\nVerifying prerequisites...\n'
for tool in git node npm python3 jq sqlite3; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '  %-12s %s\n' "$tool" "$("$tool" --version 2>/dev/null | head -1)"
  else
    printf '  %-12s MISSING (install manually)\n' "$tool" >&2
  fi
done

printf '\nInstalled versions:\n'
for tool in gitleaks trivy chromium uv shellcheck gh; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '  %-12s %s\n' "$tool" "$("$tool" --version 2>/dev/null | head -1)"
  else
    printf '  %-12s missing\n' "$tool"
  fi
done

printf '\nNext: bash ~/nex/scripts/install-user-tools.sh\n'
printf 'Note: uv-dependent tools (semgrep) need uv; install with: uv tool install semgrep\n'
EOF