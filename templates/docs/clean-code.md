# Clean code checklist

The reviewer's checklist. Blocking items only.

1. **Behavior** matches the issue's requirements and acceptance tests.
2. **Tests** exist for each requirement in the issue, catch a real bug, and weren't weakened.
3. **Contracts:** names, files, and shapes match the plan.
4. **Project invariants** in `AGENTS.md` section 4 hold.
5. **Scope:** no files outside the plan, no new packages, no leftover debug code.
6. **Blast radius:** every caller of changed code still works.
7. **Errors:** failure paths the requirement names are handled and tested.
<project-specific items from setup>
