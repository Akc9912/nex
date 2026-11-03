# Skills

Skills are on-demand instruction packs in the Agent Skills format:
`shared/skills/<name>/SKILL.md` with `name` and `description` frontmatter. Only
the name and description are visible until the agent loads the skill, so the
global context stays small.

## Installed skills

nex-owned skills:

| Skill | Use when |
|---|---|
| `frontend-design` | building or reviewing UI; design-system consistency, hierarchy, states, accessibility, avoiding AI-looking interfaces |
| `backend-design` | server-side code; layer responsibilities, queries, transactions, authz |
| `api-design` | designing or changing HTTP/RPC contracts |
| `test-design` | adding tests, fixing a bug, improving a weak suite |
| `technical-writing` | README, setup guide, architecture note, runbook |
| `nex-maintenance` | changing this environment itself |

Skills adapted from external collections (kept close to upstream; do not edit
them to add nex standards, put those in nex-owned skills instead):

- Superpowers: `brainstorming`, `systematic-debugging`, `test-driven-development`,
  `writing-plans`, `executing-plans`, `requesting-code-review`,
  `receiving-code-review`, `verification-before-completion`, and related
  workflow skills.
- Ponytail: `ponytail`, `ponytail-review`, `ponytail-audit`, `ponytail-debt`,
  `ponytail-gain`, `ponytail-help`.
- BMAD: `bmad-*` skills.

`ls shared/skills` is the authoritative list.

## How they load

- Claude Code discovers `~/.claude/skills/` and invokes a skill when the task
  matches its description. Skills can also be preloaded in a subagent with the
  `skills` frontmatter field, but that puts the full text in context, so use it
  sparingly.
- OpenCode discovers `~/.config/opencode/skills/` and can add directories with
  the `skills` config key. `nex` uses the default directory via symlinks.

The link step creates one symlink per skill in both tool directories. The source
stays in `shared/skills/`.

## Adding a skill

```bash
mkdir -p ~/nex/shared/skills/my-skill
$EDITOR ~/nex/shared/skills/my-skill/SKILL.md
nex link
```

```markdown
---
name: my-skill
description: Use when ... (one or two sentences, concrete trigger)
---

# Title

## Procedure
1. ...
```

Guidelines:

- Put the trigger in `description`; that is what the model sees first.
- Keep the body procedural and specific to this environment.
- Do not duplicate global rules or a whole external manual.
- Include commands only if they are installed and safe.
- Re-run `nex verify` after adding a skill to confirm both symlinks exist.

## What not to install

Do not vendor large prompt collections wholesale. They add context and overlap
with the rules here. Pick individual skills with a clear trigger, remove nex
skills they replace, and record the choice in `CHANGELOG.md`.
