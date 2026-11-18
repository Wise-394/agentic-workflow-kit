<!-- Example only: a filled plan comment for a small feature issue in the kit's sandbox project. Copy its level of detail, not its content. -->

<!-- agentkit:plan -->
# Plan — #4 Add average of a list of numbers

**Playbook:** feature · **Lane:** standard (two behaviors, so two tasks) · **Branch:** feat/4-average · **Base:** dev · **State:** planned

**Size:** about 30 changed lines in 2 files, 2 tasks (limits: 400 lines, 8 files)

## Scout questions

1. Is there an existing helper that adds a list of numbers? — **A:** yes, `sum(numbers)` in `src/sum.js:1`, returns 0 for an empty list.
2. Where do tests live and how are they named? — **A:** `test/<module>.test.js`, Node's built-in runner, names start with the requirement ID (`test/sum.test.js:5`).
3. Does any code already compute an average? — **A:** not found; searched `src/` and `test/` for `average`, `mean`, `/ numbers.length`.

## Contracts

- `src/average.js` — new — exports `average(numbers: number[]): number` — the arithmetic mean of `numbers`; 0 for an empty list
- Reuse: `src/sum.js` `sum`

### Error cases

| Input or situation | Result | Test |
|---|---|---|
| Empty list `[]` | `0` (not `NaN`) | Test 2 |

## Quality notes

- `src/average.js` — domain (pure function) — must not import anything outside `src/`, must not read the clock or any global state.
- clean-code §3: reuse `sum` for the total; don't write a second loop or `reduce`.
- clean-code §2: guard clause for the empty list first, then one return. No `else`.
- Existing helpers to reuse: `src/sum.js` `sum`.

## Tests

### Test 1 — MATH-02: average returns the mean of a list
- File: `test/average.test.js`
- Setup: none
- Action: `average([2, 4, 9])`
- Expect: `5`
- Fails first because: `src/average.js` doesn't exist yet (module not found)

### Test 2 — MATH-02: average of an empty list is 0
- File: `test/average.test.js`
- Setup: none
- Action: `average([])`
- Expect: `0`
- Fails first because: after task 1, `average([])` returns `NaN` (0 / 0)

### Existing test changes

none

## Tasks

Each task is one behavior and one commit, and leaves the quick check green.

### Task 1 — mean of a non-empty list
- Tests: Test 1; existing test changes: none
- Test files: `test/average.test.js`
- Files: `src/average.js`
- Pattern: `src/sum.js`
- Steps:
  1. Create `src/average.js` exporting `average(numbers)`, importing `sum` from `./sum.js`.
  2. Return `sum(numbers) / numbers.length`.
- Done when: `npm test -- test/average.test.js` shows 1 passing; the quick check passes (this project has none, so `npm run check`)
- Commit: `feat(#4): average of a list of numbers`

### Task 2 — empty list returns 0
- Tests: Test 2; existing test changes: none
- Test files: `test/average.test.js`
- Files: `src/average.js`
- Pattern: `src/sum.js`
- Steps:
  1. Add a guard clause at the top of `average`: an empty list returns 0.
- Done when: `npm test -- test/average.test.js` shows 2 passing; the quick check passes (`npm run check`)
- Commit: `feat(#4): average of an empty list is 0`

## Files allowed

- `src/average.js`
- `test/average.test.js`

## Commands

- `npm run check` (once, before the PR)
- `npm test -- test/average.test.js`

## Proof plan

| # | What proves it | How | Who |
|---|---|---|---|
| 1 | MATH-02 mean of a list | Test 1 | agent |
| 2 | MATH-02 empty list | Test 2 | agent |

## Review findings

- none yet

## Follow-ups

- none yet

## Counters

- Task rounds: none yet · Escalations: none · Review rounds: 0 · Approved sha: none

## Decision log

- 2026-11-18 — An empty list returns 0, not an error — the issue's acceptance test says so, and it matches `sum([])` returning 0.
- 2026-11-18 — Non-number input isn't validated — out of scope in the issue (owned by #5, the numeric-strings bug).
