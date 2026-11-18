# Playbook: refactor

1. **Behavior stays the same.** No new behavior and no new behavior tests. If a behavior change is needed, it becomes its own issue.
2. **The safety net first.** Before changing anything, the plan lists the existing tests that cover the code being moved. If coverage is missing, the first steps add characterization tests that pass today, and the test-writer's report shows them passing, not failing (the exception to fail-first in run-issue step 5.1).
3. **Existing tests keep their assertions.** Moves and renames may need mechanical test changes (imports, paths, renamed symbols); the plan lists each one under **Existing test changes**, and the test-writer makes them in the same task as the move. A test whose assertion would need to change means behavior changed: stop and ask.
4. **Small tasks.** Each task leaves the quick check green and is its own commit. Moves and renames are their own tasks (with their mechanical test changes), separate from logic changes; the full check runs before the PR.
5. **The goal is the code standard.** The plan names the `docs/clean-code.md` rules the current code breaks and shows how each task brings it closer. A refactor that doesn't make a named rule hold is churn.
6. **Blast radius:** the plan lists every caller of each moved or renamed symbol, and the reviewer checks each one.
