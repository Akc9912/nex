# __PROJECT__

<!-- This file is the single instruction source for both Claude Code (CLAUDE.md
     is a symlink to it) and OpenCode (AGENTS.md is loaded natively). -->

## Overview

Describe what this project does, who uses it, and the one or two invariants that
must never break. Replace this paragraph.

## Commands

| Task | Command |
|---|---|
| install | `__INSTALL__` |
| test | `__TEST__` |
| lint | `__LINT__` |
| typecheck | `__TYPECHECK__` |
| verify | `./scripts/verify.sh` |

## Conventions

- Language/framework:
- Formatting and lint rules:
- Error handling:
- Test layout:
- Branch/commit style:

## Verification

Before declaring work complete, run `./scripts/verify.sh`. Report the exact
commands and results. If a check cannot run, say why.

## Constraints

- Do not commit secrets, generated build output, or vendor directories.
- Do not change public APIs without updating callers, tests, and docs.
- Do not add dependencies without a clear reason.

## Memory

Use Engram for decisions and non-obvious root causes. Search before related work;
save only durable, verified knowledge. Do not store secrets or raw logs.
