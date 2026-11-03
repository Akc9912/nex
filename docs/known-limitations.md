# Known limitations

## OS support

| OS | Status | Notes |
|---|---|---|
| Linux (Arch, Debian/Ubuntu, Fedora/RHEL, openSUSE, Alpine) | ✅ Supported | `system-install.sh` auto-detects the distro. Tested on Arch Linux. |
| macOS | ❌ Not supported yet | Symlinks and Bash work, but install scripts and paths are Linux-oriented. Homebrew-based install not implemented. |
| Windows | ❌ Not supported | Requires WSL2; native Windows is not supported (no Bash, symlinks, or Unix paths). |

- **Claude Code is not authenticated** in this setup. Authentication is
  interactive and must be completed by the user (`claude auth login`).
- **System packages** are installed via `scripts/system-install.sh`, which
  supports Arch, Debian/Ubuntu, Fedora/RHEL, openSUSE, and Alpine. Other
  distributions may need manual package installation.
- **semgrep** is installed via `uv tool install semgrep` (not an official Arch package).
- **Chrome DevTools MCP** officially supports Chrome/Chrome for Testing only;
  Chromium is unsupported.
- **OpenCode Console** does not expose plan quotas through the CLI or local
  database; only local spend estimates are available.
- **ccusage costs** are estimates from LiteLLM pricing, not invoices.
- **Engram memory is project-scoped**; cross-project recall requires
  `mem_search` with `all_projects=true`.
- **Generated agent permissions** are enforced by OpenCode/Claude, not by a
  sandbox; hooks are guardrails.
- **No commit has been made** to the `~/nex` repository; the user must review
  and commit.
- **Model IDs** are taken from the authenticated OpenCode Console; they may
  change with provider updates.
