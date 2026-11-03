---
name: test-design
description: Use when adding tests for new behavior, fixing a bug, or improving a weak suite. Focuses on behavior, boundaries, and reliable evidence.
---

# Test design

## Start from behavior

Write the expectation in one sentence: "Given X, when Y, then Z." If you cannot,
the behavior is not defined yet.

## Choose the level

- Unit: pure logic, parsing, validation, state transitions.
- Integration: boundaries between modules, database, filesystem, HTTP.
- End-to-end: only critical user flows; keep them few and stable.

Prefer the lowest level that can catch the bug. Do not mock the thing under test.

## Cover

- the happy path
- empty, missing, and invalid input
- boundaries (0, 1, max, overflow, unicode, time zones)
- error and retry paths
- validation and permission checks (allowed and denied)
- integration between modules where a boundary changed
- concurrency or ordering when relevant
- the exact regression that motivated the change

## Rules

- One behavior per test; a clear name beats a comment.
- Assert observable behavior, not private implementation.
- Avoid sleeps and shared mutable state; use deterministic clocks and fixtures.
- A flaky test is a bug: fix or quarantine it with an owner and a reason.
- Run the test without the fix and confirm it fails for the right reason.
- Scale coverage to risk and complexity; trivial code does not need a suite.
- Never edit a test to fit incorrect code, or delete a failing test before
  understanding its cause.
