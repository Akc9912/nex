---
description: Show local token, cache, model, and cost usage
---
Run `nex usage report` in the shell and summarize the result for the user:

- total input, output, cache-read, and cache-write tokens
- estimated cost and the fact that it is an estimate
- the top models and sessions by cost
- any data that is unavailable (for example subscription quota)

Do not invent quota numbers. If `nex` is missing, say so instead of guessing.
