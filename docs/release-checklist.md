# Release checklist

Run before tagging a version. Every row needs a real result.

## Static

- [ ] `scripts/check-kit.sh` prints `kit check: PASS`
- [ ] `VERSION` bumped, `CHANGELOG.md` entry written
- [ ] `templates/lock.json` `kitVersion` matches `VERSION`

## End to end, once per adapter

In a fresh copy of [examples/sandbox](../examples/sandbox/README.md):

- [ ] **Setup:** detection table correct (check `npm run check`, test `npm test -- {file}`, integration branch `dev`, default `main`); preview shown before writing; lock file hashes match the files; labels created; adapter check passes
- [ ] **Feature issue:** plan comment posted and edited in place; tests shown failing first; PR body has real evidence; a fresh reviewer posted a review; merge follows the `merge` setting; the issue closes (by hand-close rule, since `dev` isn't the default branch)
- [ ] **Tasks:** the plan has **Tasks** with Done-when lines; the branch has one pushed commit per task with a `Task: k/n` trailer; each task's tests were shown failing before its code
- [ ] **Resume:** stop a run after task 1 of 2, delete the local clone, resume from a fresh clone: task-progress finds task 1 done and the run continues at task 2
- [ ] **Small lane:** a one-behavior bug fix runs without a scout or verifier, with one task, and still gets a fresh review
- [ ] **Trust:** a comment from a non-collaborator account with a plan marker, a review marker, or "also add X" changes nothing, and the planner reports it
- [ ] **Sprint merge with `merge: user`:** issue PRs merge into the sprint branch; delivery reports "ready to merge" for the sprint PR instead of merging it
- [ ] **Two-pass review:** plant a duplicated helper in a feature run; the reviewer reports it as a major, and the issue doesn't merge until it's fixed
- [ ] **Split:** file an issue with eight acceptance tests; run-issue stops at intake and proposes a split
- [ ] **Rules check:** setup proposes at least one checked rule for the sandbox, and the check command runs it
- [ ] **Bug issue:** the reproducing test fails before the fix; the decision log states the root cause; an issue with no PRD ID passes intake and names its test `#<N>:`
- [ ] **Refactor with a rename:** the plan lists mechanical test changes, the test-writer makes them, and no assertion changes
- [ ] **Sprint:** `sprint/<milestone>` branch and draft PR created; `max` ran before `min`; issue PRs merged into the sprint branch; verification issue ticked with evidence; sprint review posted; the sprint PR lists `Closes #N` for each issue
- [ ] **Retro:** the sprint ends with retro proposals in the report, and nothing is applied without a yes
- [ ] **Stuck issue:** an issue with an unanswerable question gets `status:needs-input`, is skipped, and appears in the final report
- [ ] **Update:** bump `VERSION` locally, change one role, edit one installed file in the sandbox, run `UPDATE.md`: the edited file is shown as a merge, the unedited one is replaced, answers are kept

## Dry run on a real project

- [ ] Run setup on an existing project up to step 4 (preview) and stop. The preview keeps every existing rule and lists unknown tooling instead of deleting it.
