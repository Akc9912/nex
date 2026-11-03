# Changelog

All notable changes to the `nex` environment are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `nex project init` command to adopt existing projects (generate missing nex files).
- `docs/tools.md` — tool catalog with versions and sources.
- Shellcheck clean pass (`--severity=warning`).

## [0.2.0] - 2026-11-03

### Added
- Backend Developer and Frontend Developer agents.
- `scripts/update.sh` and `scripts/uninstall.sh`.
- OpenUsage v0.26.3 (cross-provider usage dashboard).
- Semgrep 1.183.0 (via `uv tool install`).
- 23 new skills from Superpowers, Ponytail, and BMAD collections.
- Delegation policy documented in `docs/workflow.md`.
- `docs/troubleshooting.md` and `docs/known-limitations.md`.

### Changed
- Replaced overlapping nex skills with collection versions (code-review, git-workflow, minimal-implementation, requirements-analysis, security-audit, systematic-debugging, test-driven-development, writing-plans).
- Fixed `usage.sh` offline-flag quoting and jq variable bugs.
- Fixed `_lib.sh` token check (`length` → `> 0`).
- Fixed `task-verify.sh` to handle repositories with no HEAD.
- Fixed `guard-destructive.sh` to normalize `sudo`/`doas` prefixes.
- OpenCode MCP commands use `/bin/sh -c` with `$HOME` to avoid PATH issues.

### Removed
- V1-style `~/.config/opencode/opencode.json` (moved to backup).

## [0.1.0] - 2026-11-03

### Added
- Initial repository structure under `~/nex`.
- Shared rules (6 files), model profiles (FAST/STANDARD/ADVANCED/REVIEW).
- 6 canonical agents: architect, explorer, reviewer, security, tester, documenter.
- 6 initial skills: code-review, nex-maintenance, security-audit, systematic-debugging, technical-writing, test-design.
- Shared hook scripts: session-start, session-end, post-edit, pre-commit, guard-destructive, task-verify.
- OpenCode V2 config (`opencode.jsonc`) with `mcp.servers`.
- Claude Code settings with hooks, permissions, status line.
- OpenCode plugin (`nex.ts`) adapting shared hooks.
- `scripts/render.mjs`, `scripts/link.sh`, `scripts/verify.sh`.
- `bin/nex` CLI dispatcher.
- Project template under `projects/template/`.
- Documentation: architecture, install, mcp, models, security, skills, usage, workflow.
- Engram v3.6.1 and CodeGraph 1.6.2 integration.
- ccusage and tokscale for token observability.
- Claude Code and OpenCode MCP configurations.
- Symlinks installed into `~/.claude` and `~/.config/opencode`.
