---
name: write-plan
description: Use when the planner is about to fill an issue's plan comment, after scouting and before any branch, test, or code exists.
---

# Write the plan

Workers are capable but literal: anything the plan leaves open, they will guess. Write the plan so every decision is already made. Use [templates/plan-comment.md](../../templates/plan-comment.md) and post it with create-plan-comment or update-plan-comment from [tracker/github.md](../../tracker/github.md).

## Sources, in order

1. The issue: its goal, requirements, acceptance tests, and every comment (a newer comment can override the body).
2. The PRD issue, for the requirement IDs the issue names. If the issue conflicts with the PRD, the PRD wins. A real conflict goes to the user.
3. The scout's answers.
4. `docs/patterns.md` for the file to copy.
5. The playbook for this issue type ([skills/playbooks/SKILL.md](../playbooks/SKILL.md)).

## Contracts

- Every new or changed file, with exact export names and type shapes.
- What to reuse, by file and symbol.
- For UI: every test ID, every prop, and which text rows from the project's copy doc to use.

## Tests

Every test gets all four lines: Setup, Action, Expect, Fails first because. For each test, ask: what bug in our code does it catch? Drop tests with no answer. Cover the boundaries and failure paths the requirement names; skip combinations nobody would break.

## Steps

Numbered, one file per step, in build order (inner layers first, screens and routes last). Name the pattern file for each. **Files allowed** lists every file the coder may touch.

## Proof plan

For each acceptance test in the issue, one row that says how it will be proven: a test, a verify-skill step, or a user check. A row that says "manual" must say exactly what to do and what to see.

## Decision log

Every decision the issue didn't spell out, with the doc or code line it came from. If it came from nowhere, it's a question for the user, not a decision.

## Size

A plan is usually 60–150 lines. Much longer usually means two issues. Ask the user before splitting.
