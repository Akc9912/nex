## Security and destructive actions

- Never commit secrets, tokens, private keys, credentials, or real customer data.
  Use environment variables or a secret store; keep examples fake.
- Do not print secrets in logs or summaries. If a secret is exposed, say so and
  recommend rotation instead of quietly deleting evidence.
- Treat shell input, file paths, URLs, and model output as untrusted. Validate
  before using them in commands or queries.
- Do not pipe remote scripts into a shell, disable TLS verification, or add
  broad `sudo` rules without explicit user approval.
- Destructive operations require explicit approval: recursive deletes outside a
  build directory, `git reset --hard`, `git clean -fdx`, force pushes, history
  rewrites, database drops/truncates, disk writes, and service shutdowns.
- Prefer `--force-with-lease` over `--force`; prefer a new commit over rewriting
  shared history; prefer a dry run before a bulk change.
- The hooks in this repository are guardrails, not a sandbox. Do not rely on
  them as the only control for untrusted code.
