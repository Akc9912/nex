---
name: api-design
description: Use when designing or modifying HTTP/JSON APIs, RPC contracts, or public interfaces. Focuses on stable, evolvable contracts.
---

# API Design

## Principles
- Prefer explicit, predictable contracts over clever ones.
- Version deliberately; avoid breaking changes without migration path.
- Use consistent naming (plural nouns for collections, verbs for actions).
- Return structured errors with stable codes and human-readable messages.

## Request/response
- Validate at the boundary; reject unknown fields when appropriate.
- Use pagination for collections (cursor-based preferred).
- Keep payloads minimal; avoid leaking internal fields.
- Use idempotency keys for mutating operations where retries occur.

## Compatibility
- Additive changes are safe; removals/renames are breaking.
- Deprecate before removing; document migration.
- Keep backward-compatible defaults; do not change semantics silently.

## Security
- Authenticate every endpoint; authorize per resource.
- Rate-limit public endpoints.
- Avoid exposing internal IDs when sequential IDs leak counts.
- Never trust client-side validation alone.

Compacted for nex.
