# Agents

Agents are defined once in `shared/agents/<id>.json` and rendered into native
Claude Code and OpenCode files. The prompt lives in
`shared/agents/prompts/<id>.md`.

| Agent | Mode | Profile | Writes | Purpose |
|---|---|---|---|---|
| `architect` | primary | ADVANCED | no | design, options, ordered plan |
| `reviewer` | subagent | REVIEW | no | independent diff review |
| `explorer` | subagent | FAST | no | file/symbol/flow map |
| `tester` | subagent | STANDARD | tests only | reproduce, write tests, run suites |
| `documenter` | subagent | FAST | docs only | README/docs from verified behavior |
| `security` | subagent | REVIEW | no | focused security audit |

## Permissions

OpenCode uses ordered permission rules; the last match wins. Read-only agents
start with:

```yaml
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: deny
```

`reviewer` re-allows only `git diff`, `git log`, `git show`, and `git status`.
`security` re-allows only scanner and read-only git commands. `tester` re-allows
test-file edits and common test commands. `documenter` re-allows Markdown/doc
edits.

Claude Code subagents use a tool allowlist. Read-only agents have no `Edit` or
`Write` tool. `reviewer` and `security` keep `Bash` because they need `git diff`
and scanners; Claude Code has no per-agent shell-command sandbox, so the global
`guard-destructive.sh` hook is the second layer. `architect` and `explorer` run
with `permissionMode: plan`.

## Invoking

Claude Code:

```text
Use the reviewer subagent to review the current diff.
```

```bash
claude --agent architect
```

OpenCode: ask the primary agent to use the subagent, or use a command with an
`agent` frontmatter field (`/review`, `/plan`). OpenCode can also launch an agent
directly with `opencode --agent architect`.

## Adding an agent

1. Create `shared/agents/<id>.json`:

   ```json
   {
     "id": "migrator",
     "description": "Plans and applies safe schema migrations.",
     "mode": "subagent",
     "profile": "STANDARD",
     "color": "#73daca",
     "opencode": {
       "steps": 20,
       "permissions": [
         { "action": "edit", "resource": "*", "effect": "deny" },
         { "action": "edit", "resource": "migrations/**", "effect": "allow" },
         { "action": "shell", "resource": "*", "effect": "deny" },
         { "action": "shell", "resource": "npm run migrate*", "effect": "allow" }
       ]
     },
     "claude": {
       "tools": ["Read", "Grep", "Glob", "Edit", "Bash"],
       "permissionMode": "default",
       "maxTurns": 20
     }
   }
   ```

2. Write `shared/agents/prompts/<id>.md`. State the responsibility, the output
   shape, and what the agent must not do.
3. Run `nex render && nex link`.
4. Restart OpenCode. Claude Code picks up user agents automatically once the
   directory exists.

## Rules for agent design

- One responsibility per agent; if the description needs "and", split it.
- Read-only means no write tools and no broad shell access.
- Give the agent the context it needs in the delegation prompt; do not make it
  rediscover the whole repository.
- Keep descriptions short; they are loaded into the parent's context.
- Prefer an existing agent over adding another.
