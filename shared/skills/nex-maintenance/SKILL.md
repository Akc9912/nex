---
name: nex-maintenance
description: Use when changing this nex environment itself: rules, agents, models, hooks, MCP servers, links, or install scripts.
---

# Maintaining nex

## Source of truth

- Rules: `shared/rules/*.md`; never edit generated `shared/AGENTS.md` directly.
- Agents: `shared/agents/<id>.json` plus `shared/agents/prompts/<id>.md`.
- Models: `shared/models.json` profiles.
- Hooks: `shared/hooks/*.sh`.
- Tool adapters: `claude/` and `opencode/`; generated agent files are not canonical.
- Skills: `shared/skills/<name>/SKILL.md`.

## Change loop

```bash
nex render          # regenerate AGENTS.md and agent adapters
nex link            # refresh symlinks into Claude/OpenCode config dirs
nex verify          # tools, links, config, hooks, generated files
```

## Rules

- Keep shared content tool-agnostic. Put Claude-only syntax in `claude/` and
  OpenCode-only syntax in `opencode/`.
- Never add a fabricated package, model ID, or command. Verify with the installed
  tool (`opencode models`, `claude --help`, `pacman -Ss`).
- OpenCode V2 uses `permissions`, `mcp.servers`, and `agents/`; do not reintroduce
  V1 keys such as `permission`, `mcp.<name>`, or `tools`.
- Hooks are guardrails, not a sandbox. Document what they do not cover.
- Test destructive guards against both blocked and allowed commands.
