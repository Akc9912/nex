# 🧠 nex — Provider-Agnostic AI Development Environment

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?logo=arch-linux&logoColor=fff)](https://archlinux.org/)
[![Provider Agnostic](https://img.shields.io/badge/Provider-Agnostic-6E56CF)](docs/architecture.md)
[![Engram](https://img.shields.io/badge/Engram-v3.6.1-4B8BBE)](https://github.com/Gentleman-Programming/engram)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> A single source of truth for rules, agents, skills, hooks, MCP, memory, and
> token observability — **agnostic to the AI provider**.
>
> Claude Code and OpenCode are the supported providers today; the architecture
> allows adding more without rewriting the shared layer.
>
> No harness. No orchestrator. No custom TUI. Just modular configuration that
> turns supported AI CLIs into complete development environments.

---

## 📁 Layout

```
~/nex/
├── shared/              # tool-agnostic source of truth
│   ├── rules/           # small rule files → rendered into AGENTS.md
│   ├── agents/          # canonical agent definitions (JSON) + prompts
│   ├── skills/          # on-demand Agent Skills (SKILL.md)
│   ├── hooks/           # shared hook scripts (Bash)
│   └── models.json      # FAST / STANDARD / ADVANCED / REVIEW profiles
├── claude/              # Claude Code adapters
├── opencode/            # OpenCode adapters (config, plugin, agents)
├── projects/template/   # starting point for new repositories
├── scripts/             # render, link, install, verify, usage, project tooling
├── bin/nex              # small CLI dispatcher
└── docs/                # architecture, install, operations, limitations
```

Only `shared/` is canonical. Claude-only and OpenCode-only syntax lives in
`claude/` and `opencode/`. Generated files carry a header saying so.

---

## ⚡ Quick start

```bash
exec bash                 # reload PATH
nex verify                # check tools, links, config, and hooks
nex usage report          # local token/cost report
nex project new my-app    # create a project from the template
nex project init          # adopt an existing project
```

In a project:

```bash
claude                    # Claude Code
opencode                  # OpenCode
```

---

## 🤖 Agents (8)

One job each. Read-only agents have no edit tools in both CLIs.

| Agent | Profile | Role |
|---|---|---|
| `architect` | ADVANCED | Design, trade-offs, implementation plans (read-only) |
| `explorer` | FAST | Find files, symbols, flows, constraints (read-only) |
| `backend-developer` | STANDARD | APIs, services, repositories, DTOs, tests |
| `frontend-developer` | STANDARD | UI components, responsive, accessibility |
| `reviewer` | REVIEW | Independent diff review (different model family) |
| `tester` | STANDARD | Unit/integration tests, edge cases, coverage |
| `documenter` | FAST | README, docs, comments (no code changes) |
| `security` | REVIEW | Auth, vulnerabilities, secrets, dependencies |

---

## 🧩 Skills (33)

On-demand Agent Skills (SKILL.md standard). Loaded only when relevant — no
context bloat.

**Core nex:** `api-design` · `nex-maintenance` · `technical-writing` · `test-design`

**Superpowers:** `brainstorming` · `diagnosing-superpowers` · `dispatching-parallel-agents` · `executing-plans` · `finishing-a-development-branch` · `receiving-code-review` · `requesting-code-review` · `subagent-driven-development` · `systematic-debugging` · `test-driven-development` · `using-git-worktrees` · `using-superpowers` · `verification-before-completion` · `writing-plans` · `writing-skills`

**Ponytail:** `ponytail` · `ponytail-audit` · `ponytail-debt` · `ponytail-gain` · `ponytail-help` · `ponytail-review`

**BMAD:** `bmad-architecture` · `bmad-brainstorming` · `bmad-code-review` · `bmad-prd` · `bmad-product-brief` · `bmad-project-context` · `bmad-qa-generate-e2e-tests` · `bmad-retrospective`

---

## 🎯 Model profiles

Defined once in [`shared/models.json`](shared/models.json), rendered into agent
adapters. Change there → `nex render` → `nex link`.

| Profile | Claude Code | OpenCode | Use |
|---|---|---|---|
| **FAST** | `haiku` | `opencode/claude-haiku-5-5` | search, inventory, docs |
| **STANDARD** | `sonnet` | `opencode/claude-sonnet-5-5` | default implementation |
| **ADVANCED** | `opus` | `opencode/claude-opus-5-5` | architecture, hard debugging |
| **REVIEW** | `opus` | `opencode/gpt-5.5` | independent review |

---

## 🔌 MCP servers

| Server | Type | Status |
|---|---|---|
| `engram` | local (stdio) | ✅ connected |
| `codegraph` | local (stdio) | ✅ connected |
| `context7` | remote | ✅ connected |
| `playwright` | local | ⏸ disabled |
| `chrome-devtools` | local | ⏸ disabled |
| `github` | remote | ⏸ disabled (OAuth) |
| `sentry` | remote | ⏸ disabled (OAuth) |
| `supabase` | remote | ⏸ disabled (OAuth) |

Enable OAuth servers via `/mcps` inside the TUI.

---

## 🪝 Hooks

| Event | Script | Effect |
|---|---|---|
| Session start | `session-start.sh` | compact git/project/usage snapshot |
| Session end | `session-end.sh` | deterministic handoff + usage record |
| After edit | `post-edit.sh` | selective formatter/linter/syntax checks |
| Before `git commit` | `pre-commit.sh` | secrets, whitespace, staged-file checks, lint |
| Before any shell | `guard-destructive.sh` | blocks destructive commands |
| Task stop | `task-verify.sh` | runs project verifier when present |

Claude Code maps these in `claude/settings.json`. OpenCode registers them via
`opencode/plugins/nex.ts`.

---

## 🧠 Memory (Engram)

Persistent, project-scoped memory shared by both CLIs. Agents recover past
decisions, conventions, known issues, and task context via `mem_context` /
`mem_search`. Only durable knowledge is saved — not every conversation.

---

## 📊 Token observability

```bash
nex usage report          # markdown summary
nex usage today           # today's usage
nex usage models          # per-model breakdown
nex usage history         # session records
openusage                 # cross-provider TUI dashboard
```

Costs are estimates from model pricing, not invoices. Real subscription quotas
are reported honestly (only where the CLIs expose them).

---

## 🛠️ Maintenance

```bash
nex verify                # full environment check
nex update                # pull + render + link + verify
nex render                # regenerate agents and AGENTS.md
nex link                  # install/refresh symlinks
nex version              # tool versions
```

---

## 📚 Documentation

| Doc | Content |
|---|---|
| [architecture.md](docs/architecture.md) | Design, data flow, boundaries |
| [install.md](docs/install.md) | Installation steps and versions |
| [tools.md](docs/tools.md) | Tool catalog |
| [mcp.md](docs/mcp.md) | MCP servers and auth |
| [models.md](docs/models.md) | Model profiles |
| [hooks.md](docs/hooks.md) | Hook details |
| [skills.md](docs/skills.md) | Skill format and usage |
| [agents.md](docs/agents.md) | Agent definitions |
| [memory.md](docs/memory.md) | Engram usage |
| [usage.md](docs/usage.md) | Token reporting |
| [workflow.md](docs/workflow.md) | Delegation and workflow |
| [security.md](docs/security.md) | Security practices |
| [troubleshooting.md](docs/troubleshooting.md) | Common issues |
| [known-limitations.md](docs/known-limitations.md) | Honest limitations |

---

## 📜 Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

## 🤝 Contributing

This is a personal environment, but the structure is reusable. Fork it, adapt
the `shared/` layer, and run `nex render && nex link`.

---

## License

MIT
