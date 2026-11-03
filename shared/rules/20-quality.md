## Code quality

- Follow the project's existing naming, module layout, error handling, and test
  conventions. Consistency beats personal preference.
- Handle errors at the level that can act on them. Do not swallow failures or
  convert them into misleading success values.
- Validate inputs at boundaries. Keep internal invariants explicit.
- Prefer clear code over clever code. Add a comment only for a non-obvious
  constraint or reason, not to narrate the next line.
- Avoid new dependencies unless the benefit is clear and the maintenance cost
  is acceptable. Check what is already installed first.
- Keep public behavior stable unless the change intentionally breaks it; if it
  does, update tests, docs, and callers together.
- Run the formatter and linter configured by the project. Do not introduce new
  warnings in files you touched.
- Tests should cover behavior and edge cases, not implementation details. Add a
  regression test for every bug fix when practical.
