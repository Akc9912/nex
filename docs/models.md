# Model profiles

The four profiles are defined once in `shared/models.json`.

| Profile | Claude Code | OpenCode | Intended use |
|---|---|---|---|
| FAST | `haiku` | `opencode/claude-haiku-5-5` | inventory, search, docs, mechanical edits |
| STANDARD | `sonnet` | `opencode/claude-sonnet-5-5` | default implementation, tests, routine debugging |
| ADVANCED | `opus` | `opencode/claude-opus-5-5` | architecture, ambiguous design, hard debugging |
| REVIEW | `opus` | `opencode/gpt-5.5` | independent review on a different model family |

The OpenCode default is `opencode/claude-sonnet-5-5`. The built-in `build` agent
is the default primary agent. Switch primary agents in the TUI, or launch a
specific one with `opencode --agent architect`.

## Changing a profile

1. Edit `shared/models.json`.
2. Confirm the OpenCode ID exists:

   ```bash
   opencode models | grep '^opencode/'
   ```

3. Regenerate and relink:

   ```bash
   nex render
   nex link
   ```

4. Restart OpenCode so it reloads agent files. Claude Code watches user agents
   and picks up changes without a restart (a new `agents/` directory may need
   one).

## Why these mappings

- FAST uses the smallest capable model to keep exploration and documentation
  cheap.
- STANDARD is the default because most work is ordinary implementation.
- ADVANCED is reserved for decisions that are expensive to get wrong.
- REVIEW deliberately uses a different family in OpenCode (`gpt-5.5`) so the
  reviewer does not share the implementer's blind spots. Claude Code uses
  `opus` because that is the strongest available reviewer in that runtime.

## Variants and availability

Do not add a `#variant` unless you have confirmed it exists for the selected
model. Variants change reasoning effort and can change cost. The current mapping
uses plain model IDs.

Model availability depends on the provider account. If an ID disappears,
`opencode models` is the source of truth; update `shared/models.json` and rerun
the render step. Claude Code resolves `haiku`/`sonnet`/`opus` to the versions
allowed by the account.

## Cost awareness

`nex usage` reports estimated cost per model and per session. The estimates come
from local token counts and LiteLLM pricing, not from a provider invoice. Use
them to spot expensive sessions, not to reconcile a bill.
