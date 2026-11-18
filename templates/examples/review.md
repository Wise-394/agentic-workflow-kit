<!-- Example only: a filled review that requests changes. Copy its precision, not its content. -->

<!-- agentkit:review verdict=changes sha=3f2a9c1 -->
## Review — changes requested

Spec compliance: pass · Code quality: 2 findings

## Blocking

| # | Severity | Where | Problem | Rule | Fix |
|---|---|---|---|---|---|
| 1 | major | `src/average.js:3` | Adds the list again with its own `reduce`, so a future fix to `sum` (for example rejecting non-numbers) won't reach `average` | clean-code §3: search before writing; one implementation per rule | Import `sum` from `./sum.js` and return `sum(numbers) / numbers.length` |
| 2 | major | `test/average.test.js:9` | `assert.ok(Number.isFinite(average([])))` passes for any finite number, so returning 7 for an empty list wouldn't fail it | testing.md: exact expectations; a test that can't catch the bug | `assert.equal(average([]), 0)` |

## Follow-ups (not blocking)

- minor — `src/average.js:2` — `if (numbers.length === 0) { return 0; } else { … }` keeps an `else` after a return — clean-code §2

## Rule proposals

- none
