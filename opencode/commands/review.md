---
description: Review current changes or a named path/commit
agent: reviewer
---
Review the change described by: $ARGUMENTS

If the argument is empty, establish scope with `git status`, `git diff`, and
`git diff --staged`, then review the current working tree. Otherwise review the
named path, commit, or range.

For UI changes, apply the `frontend-design` review checklist and name any
AI-slop pattern explicitly.

Return severity-ordered findings with `path:line`, impact, and a concrete fix.
Do not edit files. If there are no findings, say so and list residual risks.
