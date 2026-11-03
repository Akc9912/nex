# Install and rebuild

This is the clean-install procedure for Arch Linux. It was written against the
versions listed at the end of this page.

## 1. Base system and account

You need:

- Arch Linux (rolling), `x86_64`
- a normal user with `sudo` (hooks and user tools must **not** run as root)
- network access to the Arch mirrors, npm, GitHub, and the Claude/OpenCode
  authentication endpoints

Install the base packages if they are not already present:

```bash
sudo pacman -S --needed base-devel git nodejs npm python docker jq ripgrep fd \
  fzf bat eza
sudo systemctl enable --now docker   # optional; add your user to the docker group
```

This environment does not require Docker. If you use it, add yourself to the
group and start a new login session:

```bash
sudo usermod -aG docker "$USER"
```

## 2. Put this repository at `~/nex`

The paths in the generated configs and symlinks assume `~/nex`. Copy or clone the
repository there:

```bash
# from a backup or a Git remote you control
git clone <your-remote> ~/nex
# or: cp -a /path/to/nex-backup ~/nex
```

Do not use a different path unless you also set `NEX_ROOT` and update the
absolute paths in `claude/settings.json` and `opencode/plugins/nex.ts`.

## 3. System packages

```bash
sudo bash ~/nex/scripts/system-install.sh
```

This installs official Arch packages only:

| Package | Why |
|---|---|
| `gitleaks` | staged-secret scanning |
| `trivy` | dependency, secret, and misconfiguration scanning |
| `chromium` | browser fallback |
| `uv` | isolated install of Semgrep (not in the official repos) |
| `shellcheck` | shell linting in hooks |
| `github-cli` | optional `gh` workflows and issue reporting |

## 4. User-level tools

```bash
bash ~/nex/scripts/install-user-tools.sh
```

This installs into `~/.local` (no root):

| Tool | Pinned version | Purpose |
|---|---|---|
| `@colbymchenry/codegraph` | 1.6.2 | code index + MCP |
| `@playwright/mcp` | 0.0.84 | browser automation MCP |
| `chrome-devtools-mcp` | 1.12.0 | Chrome DevTools MCP |
| `ccusage` | 20.0.48 | token/cost reporting |
| `tokscale` | 4.21.0 | alternative usage viewer |
| `knip` | 6.44.1 | unused-code checks |
| `prettier` | 3.9.10 | formatting |
| `eslint` | 10.14.0 | linting |
| `engram` | 3.6.1 | persistent memory |
| `semgrep` | via `uv tool` | static analysis |

Engram is downloaded from its official GitHub release and verified against the
published SHA-256 checksum before installation. Claude Code is installed with
Anthropic's official native installer only if it is missing.

## 5. Browsers

```bash
bash ~/nex/scripts/install-browsers.sh
# optional: Chrome for Testing for chrome-devtools-mcp
bash ~/nex/scripts/install-browsers.sh --with-chrome
```

Playwright's Chromium is used by `playwright-mcp`. The Chrome DevTools MCP
officially supports Google Chrome/Chrome for Testing only; Chromium is not
supported by that project.

## 6. Engram integration (before linking)

Run the official setup for each agent **before** `nex link`. As of Engram 3.6.1,
`engram setup opencode` writes a V1-style `~/.config/opencode/opencode.json`; the
link step backs it up and removes it in favor of the V2 config in this repo.

```bash
export PATH="$HOME/.local/bin:$PATH"
engram setup claude-code
engram setup opencode
```

If Claude Code asks whether to add Engram tools to its allowlist, answer `y`.
The repository settings already allow `mcp__engram__*`.

## 7. Render and link

```bash
cd ~/nex
node scripts/render.mjs
bash scripts/link.sh
exec bash          # reload PATH (or open a new terminal)
```

`link.sh` is idempotent. It backs up conflicting real files to
`~/.local/state/nex/backups/<timestamp>/` before replacing them with symlinks.
It also adds `~/.local/bin` to `~/.bashrc`, `~/.profile`, and `~/.zshrc` once.

## 8. Authentication and consent

These are interactive by design and cannot be automated:

```bash
claude auth login          # Anthropic account or API key
opencode auth login        # OpenCode Console or another provider
```

Then, inside the TUIs:

- Claude Code: `/mcp` for OAuth servers and MCP health.
- OpenCode: `/mcps` for OAuth servers, `/models` to pick a model.

Optional OAuth servers are disabled in the default config. Enable one in
`opencode/opencode.jsonc` and run `nex link`, or register it in Claude with
`bash scripts/install-mcp.sh --all`.

## 9. Verify

```bash
nex verify
nex hooks test
nex usage report
```

Expected results:

- all required tools found
- generated agents current
- `claude/settings.json` valid, OpenCode JSONC valid
- symlinks correct
- hooks executable and smoke tests pass
- warnings only for authentication/OAuth that you have not completed

## 10. Optional: CodeGraph index

CodeGraph works per project:

```bash
cd ~/Projects/my-app
codegraph init .
codegraph status .
```

The MCP server is `codegraph serve --mcp` and is configured globally.

## Versions verified during setup

| Component | Version |
|---|---|
| Arch kernel | `6.18.60-1-lts` |
| bash | `5.3.20` |
| git | `2.56.0` |
| Node.js / npm / pnpm | `26.13.0` / `12.2.1` / `12.17.0` |
| Python | `3.14.9` |
| OpenCode | `2.2.5` |
| Claude Code | `2.1.311` |
| Engram | `3.6.1` |
| CodeGraph | `1.6.2` |
| ccusage | `20.0.48` |
| gitleaks | `8.30.1` |
| trivy | `0.76.1` |
| Chromium (Arch) | `156.0.8078.79` |
| uv | `0.13.7` |

## Clean removal

```bash
# remove symlinks only; backups remain under ~/.local/state/nex/backups
find ~/.claude ~/.config/opencode -type l -lname "$HOME/nex/*" -delete
rm -f ~/.local/bin/nex

# optional: remove user tools
npm uninstall -g --prefix ~/.local @colbymchenry/codegraph @playwright/mcp \
  chrome-devtools-mcp ccusage tokscale knip prettier eslint

# memory and usage data are separate and are not removed automatically
# ~/.engram/                 Engram database
# ~/.local/share/opencode/   OpenCode sessions and usage
# ~/.local/state/nex/        nex logs, session handoffs, backups
```
