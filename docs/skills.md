# Skills

Skills are on-demand instruction packs in the Agent Skills format:
`shared/skills/<name>/SKILL.md` with `name` and `description` frontmatter. Only
the name and description are visible until the agent loads the skill, so the
global context stays small.

## Installed skills

| Skill | Use when |
|---|---|
| `code-review` | reviewing a diff or your own changes before commit |
| `systematic-debugging` | a failure is not obvious; avoid guess-and-check |
| `security-audit` | focused security review of code, deps, or containers |
| `test-design` | adding tests, fixing a bug, improving a weak suite |
| `technical-writing` | README, setup guide, architecture note, runbook |
| `nex-maintenance` | changing this environment itself |

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

Do not vendor large prompt collections (Superpowers, BMAD, Ponytail, or similar)
wholesale. They add context and overlap with the rules here. If a specific skill
is useful, adapt the idea into a small local `SKILL.md` with a clear trigger.
