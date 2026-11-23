# Size and split work

Small pieces get reviewed well, fail cheaply, and resume cleanly. Work is cut at three levels, and each level has a hard size rule. Limits come from `[limits]` in `.agentkit/config`; the numbers below are the defaults.

## The three levels

| Level | What it is | Size rule | Done when |
|---|---|---|---|
| **Milestone** (sprint) | A version a person can use end to end | About 5–12 issues | Its verification issue is ticked and the sprint PR merges |
| **Issue** (one PR) | One reviewable change | ≤ `issueChangedLines` (400) changed lines, ≤ `issueFiles` (8) files, ≤ `issueAcceptanceTests` (5) acceptance tests, one vertical slice or one layer | The Definition of Done in [agentkit-run-issue](../../agentkit-run-issue/SKILL.md) holds |
| **Task** (one commit) | One behavior, one red-green cycle | ≤ `taskFiles` (3) files besides tests, about 2–15 minutes of work, one or two planned tests | Its **Done when** command prints the expected result, and the quick check is green |

Changed lines are estimated in the plan and measured by `agentkit check-full` against the point where the branch started. Generated files (lock files, migrations, snapshots) don't count.

## Definition of Ready (an issue may start only when every line holds)

1. A goal in one or two sentences, saying what a person can do afterwards.
2. Requirement IDs that exist in `docs/prd.md`, if the project has one and the issue comes from it. An issue outside the PRD (a reported bug, a chore) uses its own number instead (`#<N>`), and its tests are named that way.
3. Acceptance tests in plain words, each one checkable (given / when / then). For a bug, the reproduction steps and the expected result count.
4. **Out of scope** lists what it won't do, with the issue that owns each item when one exists. A small-lane issue may leave it out.
5. Every `Blocked by` issue is cleared (see blockers-of in the tracker file).
6. It fits the issue size rule above, judging by the acceptance tests and the files they need.
7. Nothing it needs is unsafe to decide (see "Deciding without a person" in the safety baseline).

`agentkit-run-issue` checks this at intake. A missing line 3 (or 2) is filled from the PRD and recorded as an assumption. A missing line 1 or a failed line 7 blocks the issue (`agentkit block`). A failed line 6 means split.

## INVEST check for every new issue

Independent (can merge on its own), Negotiable (says what, not how), Valuable (a person or a later issue gets something), Estimable (the files involved are known), Small (fits the size rule), Testable (acceptance tests are concrete). An issue that fails one of these is rewritten before it's created.

## How to split an issue

Prefer **vertical slices**: each piece goes through every layer it needs and delivers one working behavior. Split by layer (storage, then service, then screen) only when the lower layer is shared by several later issues, or a vertical slice would still be too big.

Pick the first rule that produces pieces inside the size limit:

1. **Path:** one issue for the main path, one for each alternative or failure path ("save an entry"; "save fails when storage is full").
2. **Rules:** one issue per business rule ("duplicate names are rejected" separate from "names are trimmed").
3. **Data:** one issue per data variant (one entry type first, the others later).
4. **Interface:** the simplest interface first, richer ones later (a plain list before sorting and filtering).
5. **Spike:** if the unknown is technical, an `investigation` issue first; the build issue is blocked by it, and is cleared once the findings are posted.

Then:

1. Write each piece with [templates/issue.md](../../../templates/issue.md). Every acceptance test of the original lands in exactly one piece.
2. Each piece's **Out of scope** names the sibling that owns what it leaves out.
3. Add `Blocked by #N` where one piece needs another.
4. Planning or interactive: show the user the pieces in a table (title, acceptance tests, blockers) and get a yes. Unattended: don't wait; the table goes into the plan's **Decision log** as an assumption.
5. Create them in blocker order in the same milestone (`agentkit new-issue`), then `agentkit split <original> <pieces…>`. The original gets `status:split`, and housekeeping closes it when every piece is closed.

## How to split an issue into tasks (in the plan)

1. List the behaviors the acceptance tests need, inner layers first (domain rules, then data, then services, then UI and routes).
2. One task per behavior. A task that would touch more than `taskFiles` files, or needs more than two planned tests, is two tasks.
3. Order tasks so each one leaves the quick check green. Pure moves and renames get their own task, never mixed with logic changes.
4. Each task names: its tests and test files, any existing test changes, its files, the pattern file to copy, its steps, a **Done when** (an exact command and its expected output), and its commit message.
5. If the tasks add up past the issue size rule, split the issue instead.
