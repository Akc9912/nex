# Architecture

`nex` is a configuration repository, not a runtime. Claude Code and OpenCode
remain the runtimes; `nex` gives them the same rules, specialists, memory, and
guardrails without forking either tool.

## Data flow

```text
shared/models.json ──┐
shared/agents/*.json ├─> scripts/render.mjs ─> claude/agents/*.md
shared/agents/prompts│                         opencode/agents/*.md
shared/rules/*.md ───┘                         shared/AGENTS.md
                                                    │
scripts/link.sh ──> ~/.claude/{CLAUDE.md,settings.json,agents,skills,commands}
                └─> ~/.config/opencode/{AGENTS.md,opencode.jsonc,agents,skills,commands,plugins}
```

At runtime:

- **Claude Code** reads `~/.claude/CLAUDE.md`, user agents, skills, commands, and
  the hook table in `~/.claude/settings.json`.
- **OpenCode** reads `~/.config/opencode/AGENTS.md`, `agents/`, `skills/`,
  `commands/`, `opencode.jsonc`, and auto-loads `plugins/nex.ts`.
- **Engram** is one MCP server and one SQLite store shared by both tools. Project
  detection comes from the working directory and `.engram/config.json`.
- **ccusage** reads OpenCode's local database/files; OpenCode's own `stats`
  command is a second view. Neither is a billing system.

## What is canonical

| Concern | Canonical location | Generated / adapter |
|---|---|---|
| Rules | `shared/rules/*.md` | `shared/AGENTS.md`, root `AGENTS.md` |
| Model profiles | `shared/models.json` | agent frontmatter |
| Agents | `shared/agents/*.json`, `prompts/*.md` | `claude/agents`, `opencode/agents` |
| Skills | `shared/skills/*/SKILL.md` | symlinked into both tools |
| Hooks | `shared/hooks/*.sh` | Claude hook table + OpenCode plugin |
| MCP catalog | `opencode/opencode.jsonc`; `scripts/install-mcp.sh` | live tool config |
| Project template | `projects/template/` | new repositories |
| Usage | OpenCode local data | `ccusage`, `nex usage` |

## Why symlinks

Both tools support symlinked instruction, skill, and agent files. Symlinks keep a
single edit point and avoid drift. The renderer exists only because the two tools
use different agent frontmatter; the content and intent stay shared.

`link.sh` never deletes a real user file. It moves conflicts into a timestamped
backup directory, then creates the link.

## Why a plugin for OpenCode

Claude Code has native hook events for session start/end, tool use, commits, and
stop. OpenCode V2 exposes equivalent behavior through its plugin API:
`ctx.session.hook`, `ctx.tool.hook`, `ctx.permission.hook`, and
`ctx.event.subscribe`. `opencode/plugins/nex.ts` is a thin adapter that runs the
same Bash scripts. It adds no orchestration, scheduling, or UI.

## Boundaries

- No custom harness, queue, scheduler, TUI, or agent runtime.
- No shadow model routing: OpenCode and Claude choose models from their own
  configuration.
- No secret storage in this repository.
- No automatic commits, pushes, or destructive cleanup.
- Hooks are guardrails and evidence collectors, not a sandbox or a compliance
  system.

## Failure behavior

Hooks are written to fail open for observability and fail closed for destructive
actions:

- session start/end and usage logging: log a warning, do not block the session
- post-edit checks: report failures, do not undo the edit
- destructive guard and pre-commit: block with exit code 2
- stop verification: block once when the project verifier fails
