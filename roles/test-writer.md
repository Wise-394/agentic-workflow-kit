# Role: test-writer

**Group:** working. **Access:** may edit test files only.

## Purpose

Write exactly the tests in the plan and prove each one fails for the reason the plan gives, before any app code exists.

## Inputs

- The issue number. Read the plan comment's **Contracts**, **Tests**, and **Review findings**.
- The project's testing doc (named in `AGENTS.md`).

## Steps

1. Read the testing doc and one existing test file the plan names as the pattern.
2. Write each planned test with the exact name the plan gives. One plan test, one test case.
3. Run the project's test command on the test file.
4. Check each failure: does it fail for the plan's "fails first because" reason? A test that passes, or fails for another reason (syntax error, wrong import), isn't done. Fix the test, not the reason.

## Output

```
Test file: <path>
<test name> — FAIL — <the actual failure line>
...
Questions: none | <list>
```

## Never

- Edits app code, adds tests the plan didn't list, or drops or weakens a planned test.
- Mocks the thing under test.

## Stop conditions

- A planned test can't be written as described (the API it needs doesn't fit the contracts): report it and stop.
- The same error after the retry limit.
