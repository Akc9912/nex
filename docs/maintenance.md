# Maintenance

## Routine update

```bash
cd ~/nex
git pull
bash scripts/install-user-tools.sh    # pinned tool refresh
nex render
nex link
nex verify
```

Official packages:

```bash
sudo pacman -Syu
```

## Update a pinned tool

Versions live in `scripts/install-user-tools.sh`. Change the pin, run the script,
then verify:

```bash
opencode models | grep '^opencode/'
codegraph --version
engram --version
ccusage --version
```

Do not pin a version you have not installed and tested. For Engram, update both
the install script and the checksum expectation; the script always verifies the
published checksum.

## Change a model profile

1. Edit `shared/models.json`.
2. Verify the OpenCode ID exists (`opencode models`).
3. `nex render && nex link`.
4. Restart OpenCode.

Claude aliases (`haiku`, `sonnet`, `opus`) resolve to the account's allowed
versions. If an alias is unavailable, Claude may fall back or warn.

## Change rules or agents

- Rules: edit `shared/rules/*.md`, run `nex render`.
- Agents: edit `shared/agents/*.json` and the matching prompt, run
  `nex render && nex link`.
- Skills: edit `shared/skills/<name>/SKILL.md`, run `nex link`.
- Hooks: edit `shared/hooks/*.sh`, run `nex hooks test`, then `nex verify`.

Never edit `shared/AGENTS.md`, `claude/agents/*.md`, or `opencode/agents/*.md`
directly; they are generated. `render --check` detects drift.

## Backups

What to back up:

| Path | Contents |
|---|---|
| `~/nex` | rules, agents, hooks, configs (Git) |
| `~/.engram/engram.db` | memory database |
| `~/.local/share/opencode/opencode.db` | sessions and usage |
| `~/.claude/` | Claude sessions, plugins, settings backup |
| `~/.local/state/nex/` | handoffs, usage history, link backups |

Use `engram export` for a portable memory snapshot. For OpenCode, stop the
service before copying the SQLite database, or use `sqlite3 .backup`.

## Recover from a bad link

`link.sh` backs up replaced files to:

```text
~/.local/state/nex/backups/<timestamp>/
```

Restore by copying the file back and removing the symlink. Then run `nex verify`.

## Recover from a stale OpenCode config

If OpenCode does not see the agents or MCP servers:

```bash
opencode debug config
opencode debug agents
opencode mcp list
opencode service restart
```

`opencode debug config` shows the merged sources. Look for a stray
`~/.config/opencode/opencode.json` (V1 shape) or a project-level config that
overrides a server.

## Uninstall

See the end of `docs/install.md`. Removing `~/nex` without removing the symlinks
leaves broken links; delete links first or restore the backups.
