# Troubleshooting

## OpenCode

- **`opencode mcp list` shows `engram` or `codegraph` failed: NotFound** —
  OpenCode spawned the server before `~/.local/bin` was on its PATH. The config
  uses `/bin/sh -c 'exec "$HOME/.local/bin/engram" ...'` so reload should fix
  it. Run `opencode reload` or restart the OpenCode client/service.
- **Config changes do not apply** — OpenCode watches config files; run
  `opencode reload` to force a reload. Standalone runs use `--standalone`.
- **V1 `~/.config/opencode/opencode.json` recreated by Engram** — Run
  `nex link`; it moves the V1 file to a backup when it lacks `mcp.servers`.
- **Agents not visible** — Run `nex render` then `nex link`; check
  `opencode --standalone debug agents`.

## Claude Code

- **Not authenticated** — Run `claude auth login`. MCP and status-line features
  work after login.
- **`claude mcp list` fails** — Ensure Engram is registered in `~/.claude.json`
  (run `engram setup claude-code`).

## Tools

- **gitleaks/trivy/chromium/uv/shellcheck/gh missing** — Run
  `sudo bash ~/nex/scripts/system-install.sh` (pacman official packages).
- **npm tools missing** — Run `bash ~/nex/scripts/install-user-tools.sh`.
- **shellcheck warnings** — Run `shellcheck -x shared/hooks/*.sh scripts/*.sh`.

## Hooks

- **Hook exits 126** — Scripts are not executable; run `nex link` or
  `chmod +x shared/hooks/*.sh`.
- **Guard blocks a legitimate command** — Set `NEX_ALLOW_DESTRUCTIVE=1` for a
  single command after explicit approval.
- **Stop verification loops** — Set `NEX_SKIP_STOP_VERIFY=1` only if the user
  accepts the risk.

## Memory (Engram)

- **Ambiguous project** — Run `engram init <project>` in the repository, or
  pass `project` explicitly to memory tools.
- **Doctor warning about ambiguous sessions** — End stale sessions with
  `mem_session_end` or keep explicit `session_id` on writes.
- **Service not running** — `curl http://127.0.0.1:7437/health`; restart with
  `engram serve` if needed.

## Usage

- **ccusage cannot read data** — Ensure OpenCode has run at least once; costs
  are estimates from model pricing, not invoices.
