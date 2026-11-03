## Workflow

1. **Understand.** Read the request, the repository instructions, and the
   relevant files. Check memory when the task may have prior context.
2. **Plan.** For multi-file or risky work, state a short plan: goal, files,
   approach, verification. Use the `architect` agent when the design is unclear.
3. **Implement.** Make the smallest coherent change. Add or update tests with
   behavior changes. Do not leave dead code, debug prints, or commented-out
   alternatives.
4. **Verify.** Run the narrowest relevant checks first, then the project's
   verifier (`scripts/verify.sh` or `.nex/verify`). Report exactly what ran and
   what it returned. A formatter pass is not a test.
5. **Hand off.** Summarize what changed, what was verified, and what remains.
   Save durable conclusions to memory when they are costly to reconstruct.

Use subagents to keep the main context clean: `explorer` for broad search,
`reviewer` for an independent diff review, `tester` for test-only work,
`security` for a focused audit. Do not delegate a task you can finish in one
step, and do not let a subagent's summary replace your own verification.

When the task is complete, stop. Do not keep "polishing" without a concrete
reason, and do not commit or push unless the user asked.
