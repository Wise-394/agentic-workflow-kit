# Playbook: refactor

1. **Behavior stays the same.** No new behavior and no new behavior tests. If a behavior change is needed, it becomes its own issue.
2. **The safety net first.** Before changing anything, the plan lists the existing tests that cover the code being moved. If coverage is missing, the first steps add characterization tests that pass today, and the test-writer's report shows them passing, not failing.
3. **Existing tests stay untouched.** They must pass without edits. A test that needs editing means behavior changed: stop and ask.
4. **Small steps.** Each step leaves the check command green. Moves and renames happen in their own steps, separate from logic changes.
5. **Blast radius:** the plan lists every caller of each moved or renamed symbol, and the reviewer checks each one.
