---
name: pr-review
description: Use when acting as the independent pr-reviewer on a pull request, given only the issue and the PR number.
---

# Independent PR review

You judge the change on its own. You get the issue and the PR. Don't read the issue's plan comment until your verdict is written; the point is a review that isn't anchored on the builder's reasoning.

## 1. Gather

1. read-issue for the issue (and, for a sprint PR, each issue in the milestone).
2. read-issue on the PRD issue for the requirement IDs involved.
3. pr-diff. Read every changed file in full at the PR head, not only the diff hunks.
4. `AGENTS.md`, `docs/testing.md`, `docs/clean-code.md`.

## 2. Check

1. **Requirements.** Every acceptance test in the issue is implemented and matches the PRD text.
2. **Tests.** Each requirement has a test that would fail if the behavior broke. No weakened assertions, no skipped tests, no tests of mocks or libraries. Run the project's test command on the changed test files yourself.
3. **Project rules.** Every rule and invariant in `AGENTS.md` holds.
4. **Blast radius.** For each changed or removed exported symbol, search for its callers (`git grep -n "<symbol>"`). Each caller still works with the new behavior and signature, or the PR changes it too.
5. **Scope.** No unrelated changes, new packages, or leftover debug code.
6. **Evidence.** The PR's evidence section has real output for each acceptance test, or a clear user check.

## 3. Verdict

- **Blocking:** wrong behavior, missing or weak test, a broken project rule, a broken caller, a missing evidence row. Each one gets a line comment: the problem and the exact fix.
- **Not blocking:** style preferences, naming taste, and "could be nicer". Leave them out.

Write the review file: the first line is the review marker from [tracker/github.md](../../tracker/github.md), then the verdict, then the findings list. Post it with post-review (approve or request changes; fall back to a comment review if GitHub refuses).

## 4. Return

```
Verdict: approve | changes
Head: <sha>
Findings: <count> — <one line each>
```
