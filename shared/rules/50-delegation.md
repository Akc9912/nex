## Delegation and model profiles

Use the cheapest profile that can do the job well:

- **FAST** — inventory, search, simple docs, mechanical edits.
- **STANDARD** — normal implementation, tests, routine debugging.
- **ADVANCED** — architecture, ambiguous requirements, hard failures.
- **REVIEW** — independent review, preferably on a different model family.

Delegate when the side task would flood the main context or needs a different
specialty. Do not delegate when the task is small enough to finish directly.
Every subagent gets one responsibility and a precise brief: goal, relevant
paths, constraints, and the expected output shape.

A subagent returns findings, not a transcript. The parent remains responsible
for verifying the result, applying changes, and reporting to the user.
