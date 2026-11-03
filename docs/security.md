# Security model

## Principles

- Least privilege: read-only agents have no edit tools and, in OpenCode, explicit
  deny rules for edits and shell commands.
- Deny by default for destructive actions; allow only the specific commands an
  agent needs.
- No secrets in the repository. Use environment variables, OAuth, or a secret
  store.
- Hooks are guardrails, not a sandbox. Treat untrusted code as untrusted.

## Layers

| Layer | What it does | What it does not do |
|---|---|---|
| OpenCode permissions | ordered allow/ask/deny rules per agent | prevent a shell command that matches an allow rule |
| Claude tool allowlists | remove `Edit`/`Write` from read-only agents | prevent writes through `Bash` |
| `guard-destructive.sh` | block obvious destructive commands | parse arbitrary shell safely |
| `pre-commit.sh` | block staged secrets and whitespace errors | scan the entire history |
| `task-verify.sh` | run the project verifier before stopping | prove correctness |
| gitleaks/trivy/semgrep | detect known patterns | replace a human review |

## Secrets

- `.env`, `.env.*` (except examples), private keys, keystores, and files over
  2 MB are refused at commit.
- gitleaks scans staged changes. If it is missing, the hook warns; install it
  with `scripts/system-install.sh`.
- The session-end handoff may contain short excerpts of the last exchange. It
  is written with mode `0600` under a `0700` state directory, but it is still
  local plaintext. Do not paste secrets into a session.
- MCP credentials are stored by the tool, not in `opencode.jsonc`. Use
  `{env:NAME}` for API keys.

## Destructive commands

The guard blocks, among others:

- recursive deletes of `/`, `~`, `.`, `..`, or `*`
- recursive deletes under system directories
- `git reset --hard`, `git clean -f`, `git checkout -- .`, `git restore .`
- force pushes without `--force-with-lease`
- history rewrites (`filter-branch`, `filter-repo`)
- partition/filesystem tools, raw device writes, shutdown/reboot
- remote scripts piped into a shell
- `DROP DATABASE/TABLE`, `TRUNCATE TABLE`, `DELETE FROM` without `WHERE`

Override for one intentional command:

```bash
NEX_ALLOW_DESTRUCTIVE=1 <command>
```

This is an escape hatch, not a default. Ask the user first.

## Root commands

- Use `pacman` for official Arch packages.
- Explain a root command and its effect before running it.
- The agent shell cannot supply a sudo password; the user runs the
  `system-install.sh` command themselves.
- Do not add broad sudoers rules to make automation easier.

## Reporting a vulnerability

If you find a real vulnerability in a dependency or this configuration, do not
exploit it. Report the path, impact, and a remediation. Rotate any exposed
credential immediately; deleting the file is not enough.
