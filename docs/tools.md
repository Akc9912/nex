# Tools

Catalog of tools installed for the `nex` environment. Versions reflect the
verified installation (run `nex version` to see current ones).

## Core runtimes

| Tool | Version | Source |
|---|---|---|
| Node.js | 26.13.0 | pacman / official |
| npm | 12.2.1 | pacman / official |
| pnpm | 12.17.0 | npm |
| Python | 3.14.9 | pacman / official |
| Rust / Cargo | 16.2.1 / 4.4.1 (make) | pacman / official |
| Docker | 29.9.2 | pacman / official |
| Git | 2.56.0 | pacman / official |
| Bash / Zsh | 5.3.20 / 5.9.2 (scripts need Bash ≥ 3.2) | pacman / official |

## AI CLIs

| Tool | Version | Source |
|---|---|---|
| Claude Code | 2.1.311 | `~/.local/bin/claude` (npm user install) |
| OpenCode | 2.2.5 | `~/.opencode/bin/opencode` |
| Engram | 3.6.1 | GitHub release (SHA-256 verified) |

## Development and analysis

| Tool | Version | Source |
|---|---|---|
| CodeGraph | 1.6.2 | npm (`@colbymchenry/codegraph`) |
| Knip | 6.44.1 | npm |
| Semgrep | 1.183.0 | `uv tool install semgrep` |
| Gitleaks | 8.30.1 | pacman |
| Trivy | 0.76.1 | pacman |
| Prettier | 3.9.10 | npm |
| ESLint | 10.14.0 | npm |
| Chromium | 156.0.8078.79 | pacman |
| uv | 0.13.7 | pacman |

## Memory and observability

| Tool | Version | Source |
|---|---|---|
| ccusage | 20.0.48 | npm |
| tokscale | 4.21.0 | npm |
| OpenUsage | 0.26.3 | GitHub release (SHA-256 verified) |

## MCP servers

| Server | Type | Status |
|---|---|---|
| engram | local (stdio) | connected |
| codegraph | local (stdio) | connected |
| context7 | remote | connected |
| playwright | local | disabled |
| chrome-devtools | local | disabled |
| github | remote | disabled |
| sentry | remote | disabled |
| supabase | remote | disabled |

## Browser automation MCP

| Tool | Version | Source |
|---|---|---|
| Playwright MCP | 0.0.84 | npm (`@playwright/mcp`) |
| Chrome DevTools MCP | 1.12.0 | npm (`chrome-devtools-mcp`) |

## Maintenance

- `nex verify` — full environment check.
- `nex update` — pull, render, link, verify.
- `nex uninstall` — remove symlinks only.
- `nex render` / `nex link` — regenerate and re-link.

See `docs/install.md` for installation steps and `docs/known-limitations.md` for
remaining manual steps.
