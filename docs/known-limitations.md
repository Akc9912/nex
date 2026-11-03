# Known limitations

## OS support

| OS | Status | Notes |
|---|---|---|
| Linux (Arch, Debian/Ubuntu, Fedora/RHEL, openSUSE, Alpine) | ✅ Supported | `system-install.sh` auto-detects the distro. Tested on Arch Linux; CI on Ubuntu. |
| macOS | ✅ Supported | Homebrew install; hooks run on the stock Bash 3.2. CI runs the hook tests on macOS. |
| Windows | ✅ Via WSL2 | Run nex inside WSL2 with the repo in `~/nex`. CI runs the hook tests in WSL2 Ubuntu 24.04. Native Windows is not supported. |

CI covers rendering and the hook test suite on each platform. The full
installers (`system-install.sh`, `install-user-tools.sh`,
`install-browsers.sh`) and the Claude Code/OpenCode integrations have been run
only on Arch Linux. Native Windows is not supported (no Bash, symlinks, or
Unix paths).

- **Claude Code is not authenticated** in this setup. Authentication is
  interactive and must be completed by the user (`claude auth login`).
- **System packages** are installed via `scripts/system-install.sh`, which
  supports Arch, Debian/Ubuntu, Fedora/RHEL, openSUSE, Alpine, and macOS
  (Homebrew). Other distributions may need manual package installation.
- **macOS has no `flock`**: concurrent session ends can race when writing the
  usage log.
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
