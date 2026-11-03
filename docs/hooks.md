# Hooks

The same Bash scripts run from Claude Code's native hooks and from the OpenCode
V2 plugin. They are guardrails and evidence collectors, not a sandbox.

| Script | Trigger | Behavior |
|---|---|---|
| `session-start.sh` | session start | prints git/project/stack/usage context |
| `session-end.sh` | session end / idle | writes a handoff file and usage record |
| `post-edit.sh` | after edit/write | formatter, linter, syntax checks on that file |
| `pre-commit.sh` | before `git commit` | secrets, whitespace, staged files, targeted lint |
| `guard-destructive.sh` | before any shell | blocks obvious destructive commands and commits with `Co-Authored-By` trailers |
| `task-verify.sh` | agent stop | runs the project verifier once per changed tree |

## Claude Code mapping

`claude/settings.json` maps:

| Event | Matcher | Script |
|---|---|---|
| `SessionStart` | `startup\|resume\|clear\|compact` | `session-start.sh` |
| `SessionEnd` | all reasons | `session-end.sh` |
| `PreToolUse` | `Bash` | `guard-destructive.sh` |
| `PreToolUse` | `Bash`, `if: Bash(git commit *)` | `pre-commit.sh` |
| `PostToolUse` | `Edit\|Write\|MultiEdit` | `post-edit.sh` |
| `Stop` | all | `task-verify.sh` |

Exit code 2 blocks the action and returns stderr to the agent. Other non-zero
codes are reported by Claude Code but do not block.

## OpenCode mapping

`opencode/plugins/nex.ts`:

- `ctx.session.hook("context")` runs `session-start.sh` once per session and
  appends the output to the system prompt.
- `ctx.permission.hook("evaluate")` runs `guard-destructive.sh` for shell
  commands and `pre-commit.sh` for `git commit`. A failure sets the permission
  effect to `deny` with the script's message.
- `ctx.tool.hook("execute.after")` runs `post-edit.sh` for edit/write/patch and
  logs failures to the plugin log and tool metadata.
- `ctx.event.subscribe` filters `session.idle` and `session.deleted`, then runs
  `session-end.sh` (debounced to 10 seconds).

The plugin is loaded automatically from `~/.config/opencode/plugins/nex.ts`.

## Environment switches

| Variable | Effect |
|---|---|
| `NEX_ALLOW_DESTRUCTIVE=1` | bypass the destructive guard for one command |
| `NEX_SKIP_STOP_VERIFY=1` | skip the stop verifier (use only with user consent) |
| `NEX_PRECOMMIT_TESTS=1` | run the project test command on commit |
| `NEX_ENGRAM_AUTOSAVE=1` | also save the deterministic session handoff to Engram |
| `NEX_USAGE_ONLINE=1` | refresh ccusage pricing instead of offline cache |
| `NEX_ROOT` | override the repository root |

A project can also use:

- `.nex/pre-commit` — extra executable pre-commit checks
- `.nex/tests-on-commit` — run tests on every commit
- `.nex/verify` — override `scripts/verify.sh` for the stop hook

## Testing

```bash
nex hooks test
```

The smoke test covers blocked and allowed destructive commands, force-push and
reset detection, session context, malformed JSON post-edit, staged `.env`
blocking, and the status line. It uses a temporary git repository and no network.

## Limitations

- Regex guards cannot parse shell. A determined command can evade them.
- The co-author guard reads the command text only: a commit message passed with
  `-F <file>` is not inspected. Claude Code's own trailer is also disabled with
  `attribution: {"commit": "", "pr": ""}` in `claude/settings.json`.
- Claude Code subagents with `Bash` can write through shell redirection; the
  read-only guarantee is enforced by the absence of edit tools plus the guard,
  not by an OS sandbox.
- The stop verifier runs only when a verifier exists and the tree changed.
- Hook output must stay small; large logs slow down sessions.
