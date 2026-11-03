# Memory (Engram)

Engram is the shared memory layer. It is a Go binary with a SQLite + FTS5 store,
exposed through CLI, HTTP, MCP, and a TUI. The database lives at
`~/.engram/engram.db` and is **not** part of this repository.

## Setup

```bash
engram setup claude-code
engram setup opencode
nex link        # removes Engram's V1-style OpenCode config; links the V2 one
nex verify
```

The Claude Code integration is a marketplace plugin plus a user-scope MCP server.
The OpenCode integration is a plugin plus an MCP server. Restart each tool after
setup.

## Project binding

Engram detects the project from the working directory. For a repository that is
not already bound, create a local binding:

```bash
cd ~/Projects/my-app
engram init my-app
```

This writes `.engram/config.json` in the project. The file contains only the
project name; it is safe to commit if the project convention allows it.

## What agents are told

`shared/rules/40-memory.md` is loaded globally. In short:

- Check `mem_current_project`, then `mem_context`/`mem_search` before related
  work. Use `mem_get_observation` for full content.
- Save verified decisions, non-obvious root causes, constraints, and reusable
  patterns with `mem_save`. Use a stable `topic_key` for evolving topics.
- Do not save every turn, raw tool output, secrets, or speculation.
- At closure, save `mem_session_summary` with goal, instructions, discoveries,
  accomplished work, next steps, and relevant files.

## Verifying cross-tool memory

This is the real test: write in one tool, read in the other.

1. In Claude Code:

   ```text
   Use mem_current_project, then mem_save with title "nex cross-tool memory test"
   and content "Written from Claude Code on <date>".
   ```

2. In OpenCode, in the same project:

   ```text
   Use mem_search for "nex cross-tool memory test" and show the full observation.
   ```

3. Reverse the direction.

Both tools should resolve the same project and the same database. If they do not,
check the working directory and `.engram/config.json` first.

CLI equivalents:

```bash
engram projects list
engram search "cross-tool memory test"
engram context
engram stats
engram doctor
```

## Session handoffs

The `session-end.sh` hook writes a deterministic Markdown handoff to
`~/.local/state/nex/sessions/`. It contains git state, token counts, and recent
excerpts, but no model-generated narrative. The narrative handoff is the agent's
`mem_session_summary` call, which is why the `/handoff` command exists.

Set `NEX_ENGRAM_AUTOSAVE=1` if you also want the deterministic file saved as an
Engram observation. It is off by default to avoid noise.

## Backup and maintenance

```bash
engram export ~/backups/engram-$(date +%F).json
engram import ~/backups/engram-YYYY-MM-DD.json
engram doctor
engram conflicts list
```

Do not copy a live SQLite database while Engram is writing. Use `engram export`
or stop the service first. `engram migrate-copy` exists for store upgrades; read
its help before using it.

## Troubleshooting

- **No memories in a project**: run `engram projects list`; check the working
  directory and `.engram/config.json`; run `engram doctor`.
- **Claude works, OpenCode does not**: confirm `opencode mcp list` reports engram
  connected and that the `engram` binary is on the server's PATH.
- **"degraded (HTTP)"**: a stale HTTP server or version mismatch. Restart the
  session; if it persists, run `engram doctor` and check for two Engram versions.
- **Setup recreated `opencode.json`**: run `nex link` again; it backs up and
  removes the V1-shaped file.
