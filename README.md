# nex — a shared AI development environment for Claude Code and OpenCode

`nex` is a single source of truth for the rules, agents, skills, hooks, MCP servers,
memory, and usage reporting used by both Claude Code and OpenCode. It deliberately
does **not** implement a new harness, orchestrator, TUI, or agent runtime. It
configures the real tools and keeps their native formats.

## Layout

```text
~/nex/
├── shared/              # tool-agnostic source of truth
│   ├── rules/           # small rule files, rendered into AGENTS.md
│   ├── agents/          # canonical agent definitions (JSON) + prompts
│   ├── skills/          # on-demand Agent Skills (SKILL.md)
│   ├── hooks/           # shared hook scripts (Bash)
│   └── models.json      # FAST / STANDARD / ADVANCED / REVIEW profiles
├── claude/              # Claude Code adapters (settings, generated agents, commands)
├── opencode/            # OpenCode adapters (config, generated agents, plugin, commands)
├── projects/template/   # starting point for a new repository
├── scripts/             # render, link, install, verify, usage, project tooling
├── bin/nex              # small CLI that dispatches to those scripts
└── docs/                # architecture, install, operations, limitations
```

Only `shared/` is canonical. Claude-only and OpenCode-only syntax lives in
`claude/` and `opencode/`. Generated files carry a header saying so.

## Quick start (already installed)

```bash
exec bash                 # reload PATH
nex verify                # check tools, links, config, and hooks
nex usage report          # local token/cost report
nex project new my-app    # create a project from the template
nex project init          # adopt an existing project (generate missing files)
```

In a project:

```bash
claude                    # Claude Code
opencode                  # OpenCode
```

Use `nex project new` so the project gets `AGENTS.md`, a `CLAUDE.md` symlink,
`scripts/verify.sh`, and `.nex/` markers used by the hooks.
 
## Four model profiles

| Profile | Claude Code | OpenCode | Use |
|---|---|---|---|
| FAST | `haiku` | `opencode/claude-haiku-5-5` | search, inventory, docs |
| STANDARD | `sonnet` | `opencode/claude-sonnet-5-5` | default implementation |
| ADVANCED | `opus` | `opencode/claude-opus-5-5` | architecture, hard debugging |
| REVIEW | `opus` | `opencode/gpt-5.5` | independent review |

The profiles are defined once in [`shared/models.json`](shared/models.json) and
rendered into agent adapters. Change them there, run `nex render`, then `nex link`.

## Agents

`architect`, `backend-developer`, `frontend-developer`, `reviewer`, `explorer`,
`tester`, `documenter`, and `security` have one job each. Read-only agents have no edit tools in both tools; in OpenCode they
also have explicit permission rules that deny edits and most shell commands.
See [`docs/agents.md`](docs/agents.md).

## Hooks

| Event | Script | Effect |
|---|---|---|
| session start | `session-start.sh` | injects a compact git/project/usage snapshot |
| session end | `session-end.sh` | writes a deterministic handoff + usage record |
| after edit | `post-edit.sh` | selective formatter/linter/syntax checks |
| before `git commit` | `pre-commit.sh` | secrets, whitespace, staged-file checks, lint |
| before any shell | `guard-destructive.sh` | blocks obvious destructive commands |
| task stop | `task-verify.sh` | runs the project verifier when present |

Claude Code maps these in `claude/settings.json`. OpenCode registers the same
scripts from `opencode/plugins/nex.ts`. See [`docs/hooks.md`](docs/hooks.md).

## Memory

Engram is the shared memory layer. The memory protocol in `shared/rules/40-memory.md`
tells agents to check context before nontrivial work and save durable decisions,
bug fixes, and discoveries. Engram data lives in `~/.engram/engram.db`; it is not
stored in this repository. See [`docs/memory.md`](docs/memory.md).

## Usage

`nex usage` wraps `ccusage opencode` and OpenCode's own statistics. It reports
input, output, cache-read, cache-write, per-model, per-session, and estimated cost.
`nex usage history` reads the append-only session log written by the session-end
hook. See [`docs/usage.md`](docs/usage.md).

## Rebuild

A clean Arch Linux rebuild is documented step by step in
[`docs/install.md`](docs/install.md). The short version:

```bash
sudo bash ~/nex/scripts/system-install.sh
bash ~/nex/scripts/install-user-tools.sh
bash ~/nex/scripts/install-browsers.sh
nex render && nex link
nex verify
```

Authentication is interactive by design: `claude auth login`, `opencode auth login`,
and `/mcps` OAuth flows must be completed by the user.

## Design rules

- Use real tools and real versions; no fabricated packages, models, or credentials.
- Keep shared content tool-agnostic; generate or symlink adapters.
- Load skills on demand; do not paste large skill catalogs into global context.
- Grant the smallest useful permissions; prefer deny-by-default for read-only agents.
- Automate checks, not workflows. No custom orchestrator.
- Treat hooks as guardrails, not a security sandbox.
