---
name: backend-design
description: Use when implementing or reviewing server-side code - services, repositories, controllers, DTOs, queries, or persistence. Focuses on clear responsibilities, data access efficiency, and safe boundaries.
---

# Backend design

For HTTP/RPC contract design, use `api-design`. This skill covers what sits
behind the contract.

## Responsibilities

- Controllers/handlers: parse, validate, authorize, delegate, map the response.
  No business logic.
- Services: business rules. Split a service when it owns unrelated concerns, not
  preemptively.
- Repositories: data access only, no business decisions.
- Use DTOs at the boundaries; do not expose persistence models directly.
- Do not introduce interfaces, factories, or extra layers before a second real
  implementation or need exists.

## Boundaries and errors

- Validate all input on the server; frontend validation is a convenience only.
- Enforce authentication and per-resource authorization on every path.
- Keep error shapes and status codes consistent with the existing API. Do not
  leak internal errors or stack traces to clients.
- Do not catch generic exceptions to hide failures.

## Data access

- Count the queries a request makes. Look for N+1 patterns and queries inside
  loops; prefer joins, batching, or bulk operations.
- Load only the fields and rows needed; paginate collections.
- Use transactions when several writes must succeed or fail together; keep them
  short.

## Performance

Do not optimize prematurely, but do not ship obvious problems: repeated
queries, oversized responses, expensive synchronous work on request paths,
unbounded memory use. When a change can significantly affect performance,
measure before and after, and report the numbers.

## Tests

Cover behavior at the service level, validation failures, authorization
denials, transaction rollback paths, and the regression that motivated the
change. Use integration tests for real persistence behavior.
