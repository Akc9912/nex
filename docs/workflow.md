# Daily workflow

## Start a project

```bash
nex project new my-app
cd ~/Projects/my-app
codegraph init .          # optional
./scripts/verify.sh
```

The template gives you one `AGENTS.md`, a `CLAUDE.md` symlink, a project
verifier, and empty project-local agent directories. Global rules, agents,
skills, MCP servers, and hooks are loaded from the user configuration.

## Start a session

```bash
claude        # Claude Code
opencode      # OpenCode
```

The session-start hook injects a compact snapshot: directory, branch, changed
paths, last commit, stack, verifier, and today's estimated usage. It does not
dump the repository.

## Work loop

1. **Recall**: for related work, ask for Engram `mem_context`/`mem_search`.
2. **Explore**: read the relevant files; delegate broad search to `explorer`.
3. **Plan**: use `architect` or `/plan` when the design is unclear.
4. **Implement**: default `build`/`build` agent on STANDARD.
5. **Test**: `tester` for test-only work; run the narrow check first.
6. **Review**: `/review` or the `reviewer` subagent for an independent pass.
7. **Verify**: `./scripts/verify.sh`; the Stop hook runs it once per changed
   tree.
8. **Hand off**: `/handoff` or `mem_session_summary` for durable context.

## Commands

| Command | Claude Code | OpenCode |
|---|---|---|
| Plan | `/plan <goal>` | `/plan <goal>` |
| Review | `/review [range]` | `/review [range]` |
| Handoff | `/handoff [focus]` | `/handoff [focus]` |
| Usage | `/usage` | `/usage` |
| MCP status | `/mcp` | `/mcps` |
| Switch agent | `/agents` or `--agent` | agent picker or `--agent` |

## Delegation

Use subagents when the side task would flood the main context or needs a
different specialty:

- `explorer` — "where is X, how does it flow, what are the constraints?"
- `reviewer` — "review this diff, findings only"
- `tester` — "reproduce this failure and add a regression test"
- `documenter` — "update these docs from verified behavior"
- `security` — "audit this change for security issues"

Do not delegate a one-step task. Give the subagent a precise brief and verify its
conclusions yourself.

## Commits

Commits are manual unless the user asks. Before committing:

- the pre-commit hook scans staged files for secrets, whitespace errors, and
  targeted lint failures
- tests are opt-in (`.nex/tests-on-commit` or `NEX_PRECOMMIT_TESTS=1`) to keep
  commits fast
- force pushes and hard resets are blocked by the destructive guard

## Ending a session

The session-end hook writes a deterministic handoff and a usage record. The
agent should also save a narrative `mem_session_summary` at significant closure
or handoff. Ordinary task completion does not require a summary.

## Updating the environment

```bash
cd ~/nex
git pull
nex render
nex link
nex verify
```

Restart OpenCode after config or plugin changes. Claude Code reloads user agents
and skills automatically in most cases; restart if a new directory was created.
