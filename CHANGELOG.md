# Changelog

All notable changes to the `nex` environment are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Commits with `Co-Authored-By` trailers are blocked by `guard-destructive.sh`
  (Claude Code and OpenCode), and Claude Code's commit/PR attribution is
  disabled in `claude/settings.json`.
- macOS support: Homebrew branch in `system-install.sh`, darwin Engram
  binaries, Chrome for Testing for mac, and hooks/scripts that run on the stock
  Bash 3.2 without GNU coreutils (`timeout`, `sha256sum`, `stat -c`, `date -d`,
  `date -I`, `sed -i`, `readlink -f`, `flock`, `mapfile`).
- Windows support through WSL2; `nex verify` reports the platform and warns when
  the repo or tools live on the Windows filesystem.
- GitHub Actions CI: render check, shellcheck, and hook tests on Linux, macOS
  (Bash 3.2), and WSL2 Ubuntu 24.04.
- `.gitattributes` forcing LF so a Windows checkout stays runnable.
- Hook tests for oversized staged files, task verification, and `nex` symlink
  resolution.
- `nex project init` command to adopt existing projects (generate missing nex files).
- `docs/tools.md` — tool catalog with versions and sources.
- Shellcheck clean pass (`--severity=warning`).
- `frontend-design` skill: design-system inspection, AI-slop patterns to avoid,
  hierarchy, components, responsive, interface states, forms, accessibility,
  and a review checklist.
- `backend-design` skill: layer responsibilities, DTOs, N+1 and query count,
  transactions, server-side validation and authz, performance measurement.
- `Design system` section in the project template `AGENTS.md`.

### Changed
- README badges: CI status, macOS and Windows (WSL2) support, and Bash 3.2+
  instead of 5.3. Docs cover CI, hook portability rules, and per-OS updates.
- Hook and usage-log timestamps use `+%Y-%m-%dT%H:%M:%S%z` (offset `+0100`
  instead of `+01:00`) because BSD `date` has no `-I`.
- `tests/hooks.sh` no longer enables `set -e` midway, which aborted any later
  test expecting a non-zero exit.
- Global rules: understand step now requires identifying reusable code and
  dependents; quality rules forbid unrequested features, invented requirements,
  fake data or undisclosed stubs, unjustified abstractions, unexplained TODOs,
  unmeasured performance claims, and rewriting tests to fit incorrect code.
- Frontend and backend developer agents load their domain skill. Claude Code
  `frontend-developer`, `backend-developer`, `architect`, and `reviewer` now
  include the `Skill` tool; without it the skill could not be loaded.
- Architect: always considers extending existing code and justifies new layers.
- Reviewer: ten-point checklist including complexity, duplication, architecture,
  accessibility, and explicit AI-slop detection; no arbitrary aesthetic requests.
- Tester: coverage scaled to risk, including permissions and integration.
- `/plan` and `/review` commands reference the new standards.
- `docs/skills.md` and `docs/agents.md` now match the installed skills and agents.
- Quality rules: keep functions, classes, and components focused.
- `test-design`: validation, permissions, integration, risk-scaled coverage.
- `README.md` and `docs/workflow.md` reference the new domain skills;
  `docs/workflow.md` documents adding the design-system section to existing
  projects.

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
