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

New kit files that the project doesn't have yet are added. Generated files (agents, permissions, hooks, skills) are generated again through the adapter with the saved answers, then classified the same way.

**Project docs are never regenerated.** `AGENTS.md`, `docs/clean-code.md`, `docs/patterns.md`, and `docs/testing.md` were filled from the project's own code and the user's answers, and the user owns them. For each one, compare the kit's template in the old version with the template in the new version. Every section the new template adds or changes becomes a proposed edit to the project's doc, filled in from the real repo the same way setup does, and shown as a diff. Nothing is replaced.

## 3. New questions

If the new version added setup questions or lock file fields, ask only those, with their defaults. From 0.1.0 to 0.2.0:

| New | Ask or fill | Default |
|---|---|---|
| `models.light` | Setup question 2, for scout, checker, and delivery | The current working model |
| `models.escalation` | "Retry a stuck task once on a stronger model?" | `thinking` |
| `commands.quick` | Detect a fast check on given files; confirm | Empty (the check command is used) |
| `commands.format` taking `{files}` | Detect whether the formatter takes file paths | The current format command |
| `commands.rules` | Setup question 8 (rules check) | Empty |
| `limits` (task rounds, review rounds, sprint fix rounds, issue and task sizes, small lane) | Setup question 7 | The template's values |
| `tracker.agentLogin`, `tracker.reviewerLogin` | Detect with agent-login | The logged-in account |
| `evidenceDir` | Add `.agentkit/evidence/` to `.gitignore` | `.agentkit/evidence` |
| `docs/clean-code.md` as a full standard | Proposed as a doc edit (above) | — |

**Work in flight.** Find open issues with a plan comment whose **State** isn't `done`. A plan written for 0.1.0 has **Steps**, not **Tasks**. Ask the user, for all of them at once: finish them on the old flow before updating, or convert each plan's **Steps** into **Tasks** (one task per step, with its tests and a Done-when line) when it next resumes.

## 4. Preview

Show: the version change, each file with its action, each diff, and any new labels. Wait for a yes.

## 5. Write and verify

1. Apply the approved changes.
2. Update `.agentkit/lock.json`: `kitVersion`, new hashes in `installedFiles`, `localEdits`, and any new answers. Keep every existing answer.
3. Run step 6 of [SETUP.md](SETUP.md) and report the results.

Commit nothing unless the user asks. If they do, use a branch named `chore/agentic-workflow-kit-<version>` and a PR into the integration branch.
