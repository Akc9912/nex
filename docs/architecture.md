# Architecture

`nex` is a **provider-agnostic configuration repository**, not a runtime.
Claude Code and OpenCode are the supported providers today; the shared layer
(`shared/`) is tool-agnostic, and provider-specific adapters live under
`claude/` and `opencode/`. Adding a new provider means adding a new adapter
directory without touching the shared layer.

> No harness. No orchestrator. No custom TUI. Just modular configuration.

---

## 🔄 Data flow

```text
┌─────────────────────┐     ┌─────────────────────┐
│  shared/models.json │     │  shared/agents/*.json│
│  shared/rules/*.md  │────▶│  shared/agents/prompts│
│  shared/skills/     │     │  shared/hooks/*.sh   │
└─────────────────────┘     └──────────┬──────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │ scripts/render.mjs│
                              └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                  ▼                  ▼
            claude/agents/*.md  opencode/agents/*.md  shared/AGENTS.md
                    │                  │                  │
                    └────────┬─────────┘                  │
                             ▼                            │
                      scripts/link.sh ──────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ~/.claude/      ~/.config/      ~/.local/bin/
        (CLAUDE.md,     opencode/       (nex, engram,
         settings.json,  (AGENTS.md,     codegraph, ...)
         agents, skills, opencode.jsonc,
         commands)      agents, skills,
                        commands, plugins)
```

### At runtime

- **Claude Code** reads `~/.claude/CLAUDE.md`, user agents, skills, commands,
  and the hook table in `~/.claude/settings.json`.
- **OpenCode** reads `~/.config/opencode/AGENTS.md`, `agents/`, `skills/`,
  `commands/`, `opencode.jsonc`, and auto-loads `plugins/nex.ts`.
- **Engram** is one MCP server + one SQLite store shared by both tools.
- **ccusage / OpenUsage** read OpenCode's local data; neither is a billing system.

---

## 📦 What is canonical

| Concern | Canonical location | Generated / adapter |
|---|---|---|
| Rules | `shared/rules/*.md` | `shared/AGENTS.md`, root `AGENTS.md` |
| Model profiles | `shared/models.json` | agent frontmatter |
| Agents | `shared/agents/*.json`, `prompts/*.md` | `claude/agents`, `opencode/agents` |
| Skills | `shared/skills/*/SKILL.md` | symlinked into both tools |
| Hooks | `shared/hooks/*.sh` | Claude hook table + OpenCode plugin |
| MCP catalog | `opencode/opencode.jsonc` | live tool config |
| Project template | `projects/template/` | new repositories |
| Usage | OpenCode local data | `ccusage`, `nex usage`, `openusage` |

---

## 🔗 Why symlinks

Both tools support symlinked instruction, skill, and agent files. Symlinks keep a
single edit point and avoid drift. The renderer exists only because the two tools
use different agent frontmatter; the content and intent stay shared.

`link.sh` never deletes a real user file. It moves conflicts into a timestamped
backup directory, then creates the link.

---

## 🔌 Why a plugin for OpenCode

Claude Code has native hook events for session start/end, tool use, commits, and
stop. OpenCode V2 exposes equivalent behavior through its plugin API:
`ctx.session.hook`, `ctx.tool.hook`, `ctx.permission.hook`, and
`ctx.event.subscribe`. `opencode/plugins/nex.ts` is a **thin adapter** that runs
the same Bash scripts. It adds no orchestration, scheduling, or UI.

---

## 🚫 Boundaries

- No custom harness, queue, scheduler, TUI, or agent runtime.
- No shadow model routing: OpenCode and Claude choose models from their own
  configuration.
- No secret storage in this repository.
- No automatic commits, pushes, or destructive cleanup.
- Hooks are guardrails and evidence collectors, not a sandbox or compliance
  system.

---

## 🛡️ Failure behavior

Hooks are written to fail open for observability and fail closed for destructive
actions:

| Hook | On failure |
|---|---|
| session start/end, usage logging | log warning, do not block |
| post-edit checks | report, do not undo edit |
| destructive guard, pre-commit | block (exit 2) |
| stop verification | block once when verifier fails |

---

## 🧩 Extension points

To add a new agent: create `shared/agents/<id>.json` + `shared/agents/prompts/<id>.md`,
then `nex render && nex link`.

To add a new skill: create `shared/skills/<name>/SKILL.md`, then `nex link`.

To add an MCP server: edit `opencode/opencode.jsonc` (and `scripts/install-mcp.sh`
for Claude), then `opencode reload`.

To change model profiles: edit `shared/models.json`, then `nex render && nex link`.
