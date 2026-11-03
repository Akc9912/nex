---
name: technical-writing
description: Use when writing or updating README, setup guides, architecture notes, runbooks, or changelogs. Keeps docs verifiable and task-oriented.
---

# Technical writing

## Before writing

- Identify the reader and the task they are trying to complete.
- Read the code and existing docs; do not document imagined behavior.
- Decide whether to update an existing page instead of adding a new one.
- Collect the real commands, paths, versions, and outputs.

## Structure

1. Outcome: what the reader gets.
2. Prerequisites and assumptions.
3. Steps in execution order, with exact commands.
4. Verification: how to know it worked.
5. Troubleshooting: the failures people actually hit.
6. Limits: what is not supported or not verified.

## Rules

- Use the project's terminology and heading style.
- Short paragraphs, concrete nouns, active voice.
- Every command should be runnable from the stated directory.
- Mark unverified claims explicitly.
- Link to the source of truth instead of duplicating large sections.
- Do not include real secrets, customer data, or internal URLs.
