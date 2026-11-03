## Persistent memory (Engram)

Engram is shared by Claude Code and OpenCode. Use it deliberately, not as a log.

- At the start of nontrivial or possibly-related work, call
  `mem_current_project`, then `mem_context` and/or `mem_search` with concrete
  keywords. Read full results with `mem_get_observation` before relying on them.
- Save only verified, durable knowledge: decisions with rationale, non-obvious
  root causes, real constraints, reusable patterns, and resumption-relevant
  pending work. Do not save every turn, raw tool output, secrets, or speculation.
- Group related conclusions. For an evolving topic, use a stable `topic_key`
  (for example `architecture/auth-model`) and update it instead of creating
  competing memories.
- At significant closure or handoff, call `mem_session_summary` with goal,
  instructions, discoveries, accomplished work, next steps, and relevant files.
- If a memory operation fails, continue the actual task and report the failure
  honestly. Never claim persistence you did not confirm.
