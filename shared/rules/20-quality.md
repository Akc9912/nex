## Code quality

- Follow the project's existing naming, module layout, error handling, and test
  conventions. Consistency beats personal preference.
- Handle errors at the level that can act on them. Do not swallow failures or
  convert them into misleading success values.
- Validate inputs at boundaries. Keep internal invariants explicit.
- Prefer clear code over clever code. Add a comment only for a non-obvious
  constraint or reason, not to narrate the next line.
- Prefer simple, explicit solutions. Do not add layers, design patterns, or
  abstractions without a concrete need; do not wrap one-off operations in
  helpers. Remove duplication only when the shared concept is real.
- Keep functions, classes, and components focused; split one that mixes
  unrelated responsibilities, but do not fragment code into trivial pieces.
- Build only what was requested. Do not invent requirements, options, or
  configuration. Do not fake data or stub a real implementation to make a
  feature look done; if a placeholder is unavoidable, say so explicitly.
- Do not leave TODO/FIXME or provisional code without a stated reason.
- Do not claim a performance improvement without a measurement.
- Avoid new dependencies unless the benefit is clear and the maintenance cost
  is acceptable. Check what is already installed first.
- Keep public behavior stable unless the change intentionally breaks it; if it
  does, update tests, docs, and callers together.
- Run the formatter and linter configured by the project. Do not introduce new
  warnings in files you touched.
- Tests should cover behavior and edge cases, not implementation details. Add a
  regression test for every bug fix when practical. Never change a test to make
  incorrect code pass, or delete a failing test without understanding why.
- Domain standards load on demand: `frontend-design` for UI work,
  `backend-design` for server-side work.
