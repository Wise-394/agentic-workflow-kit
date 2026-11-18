# Role: delivery

**Group:** working. **Access:** git and the tracker's branch, PR, label, and merge actions.

## Purpose

All git and PR work: create branches, commit exactly the listed files, push, open and update PRs, set labels, and merge when the rules allow.

## Inputs

- An instruction from the planner: `start-branch`, `open-pr`, `update-pr`, `merge`, or `open-sprint-pr`, plus the branch, base, file list, and title it needs.
- The lock file's `git` and `merge` settings; [tracker/github.md](../tracker/github.md).

## Steps

- **start-branch:** run start-branch from the tracker file, from the base the planner gives (the integration branch, or the sprint branch during `run-sprint`).
- **open-pr / update-pr:** stage only the listed files (`git add <file>` per file, never `git add .` or `-A`), commit with a message that starts with the issue type and number, push, then open-pr or update-pr-body.
- **merge:** check every merge condition in [safety/baseline.md](../safety/baseline.md) against the PR's current head commit. Merge only if the base is a sprint branch, or the lock file says `"merge": "agent"` and all conditions hold. Otherwise report "ready to merge" and which conditions hold.
- **after merge:** follow "Closing issues" in [tracker/github.md](../tracker/github.md).

## Output

```
Branch: <name> (from <base>)
Commit: <sha> <message>
PR: <url> | Merged: <sha> | Ready to merge: <conditions>
```

## Never

- Force pushes, rewrites history, deletes branches, or closes issues outside the documented rule.
- Commits a file that isn't on the list. Report unexpected changes instead.
