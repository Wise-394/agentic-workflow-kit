# <Project name> — rules for every agent

This file is the single home of the project rules. The kit's workflow lives in the skills folder; this file says what is true for **this** project.

## 0. User override

A prompt may contain a section marked **USER OVERRIDE**. For that run it wins over this file and every skill. Say `using override: <short name>` once. Nothing is written back.

## 1. Where things are

| Need | Read |
|---|---|
| Requirements by ID | The issue labelled `prd` |
| Work to do, status | Issues, milestones, and labels in the tracker |
| The plan for an issue | The issue comment that starts with `<!-- agentkit:plan -->` |
| How code should look | `docs/patterns.md` |
| How to write tests | `docs/testing.md` |
| Review checklist | `docs/clean-code.md` |
| How to prove a change works | The `verify-<project>` skill |
| Commands, branches, merge policy, models | `.agentkit/lock.json` |

## 2. Hard rules

1. Follow the safety baseline that setup installed. These rules add to it.
2. Do only what the plan says. Never start another issue.
3. Never guess a product, data, API, library, or architecture decision. Ask.
4. Never weaken, skip, or delete a test to make it pass.
5. Never claim a command passed unless you ran it and saw it pass.
6. Preserve work you didn't make.
7. Never run a command listed in `forbiddenCommands` in `.agentkit/lock.json`.
<project hard rules from setup, one per line>

## 3. Commands

| Command | What it does |
|---|---|
| `<check>` | Everything (types, lint, tests). Must pass before a PR. |
| `<test> <file>` | One test file |
| `<format>` | Formatter. Run it, then the check command again. |

## 4. Architecture (never break these)

<invariants from setup or the PRD, one per line>

## 5. Folders and naming

<folder map and naming rules from setup>

## 6. Tests

- Read `docs/testing.md`. Test our behavior, not libraries.
- Test names start with the requirement ID from the PRD, for example `'AUTH-02: …'`.

## 7. Delivery

- Branches: `<branchPattern>` from `<integrationBranch>`; sprints use `<sprintBranchPattern>`.
- Commit only the plan's files. Never `git add .`.
- PRs into `<integrationBranch>`. Merge policy: `<merge>`.
