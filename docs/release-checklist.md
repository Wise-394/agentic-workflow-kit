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
- [ ] **Bug issue:** the reproducing test fails before the fix; the decision log states the root cause
- [ ] **Sprint:** `sprint/<milestone>` branch and draft PR created; `max` ran before `min`; issue PRs merged into the sprint branch; verification issue ticked with evidence; sprint review posted; the sprint PR lists `Closes #N` for each issue
- [ ] **Stuck issue:** an issue with an unanswerable question gets `status:needs-input`, is skipped, and appears in the final report
- [ ] **Update:** bump `VERSION` locally, change one role, edit one installed file in the sandbox, run `UPDATE.md`: the edited file is shown as a merge, the unedited one is replaced, answers are kept

## Dry run on a real project

- [ ] Run setup on an existing project up to step 4 (preview) and stop. The preview keeps every existing rule and lists unknown tooling instead of deleting it.
