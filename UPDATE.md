# Update

You are an agent updating this kit in a project that already has `.agentkit/lock.json`. Nothing is written before the user approves the preview.

## 1. Compare versions

1. Read `.agentkit/lock.json`: `kitVersion`, `installedFiles`, and the user's answers.
2. Get the new kit (clone it to a temporary folder outside the project) and read `VERSION` and `CHANGELOG.md`.
3. If the versions match, say so and stop.
4. Summarize the changelog entries between the two versions in plain words.

## 2. Classify each installed file

For every path in `installedFiles`, compare its current sha256 with the recorded one:

| Current file | Kit changed it? | Action |
|---|---|---|
| Same hash (user didn't edit) | Yes | Replace with the new generated version |
| Same hash | No | Leave it |
| Different hash (user edited) | Yes | Show both changes side by side; propose a merge that keeps the user's edit; never replace silently |
| Different hash | No | Leave it; record it under `localEdits` |
| Missing (user deleted) | Either | Ask whether to restore it; default no |

New kit files that the project doesn't have yet are added. Generated files (agents, permissions, skills) are generated again through the adapter with the saved answers, then classified the same way.

## 3. New questions

If the new version added a setup question (for example a new lock file field), ask only that question, with its default.

## 4. Preview

Show: the version change, each file with its action, each diff, and any new labels. Wait for a yes.

## 5. Write and verify

1. Apply the approved changes.
2. Update `.agentkit/lock.json`: `kitVersion`, new hashes in `installedFiles`, `localEdits`, and any new answers. Keep every existing answer.
3. Run step 6 of [SETUP.md](SETUP.md) and report the results.

Commit nothing unless the user asks. If they do, use a branch named `chore/agentic-workflow-kit-<version>` and a PR into the integration branch.
