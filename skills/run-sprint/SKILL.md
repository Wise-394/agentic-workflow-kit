---
name: run-sprint
description: Use when the user names a milestone (sprint) and wants every issue in it built, reviewed, and verified on a sprint branch, ending in one pull request into the integration branch.
---

# Run a sprint

The planner runs this flow. Each issue goes through [skills/run-issue/SKILL.md](../run-issue/SKILL.md) with the sprint branch as its base. Tracker commands are in [tracker/github.md](../../tracker/github.md).

## 0. Resume or start

Run list-milestones and find the milestone. If `sprint/<milestone-slug>` exists on the remote, read the draft sprint PR body: its issue table says where to continue.

## 1. Sprint branch and draft PR

1. Delivery: start-branch `sprint/<milestone-slug>` from the integration branch.
2. Delivery: open-sprint-pr with the body from [templates/sprint-pr-body.md](../../templates/sprint-pr-body.md). The draft PR is the live progress view; update its issue table after every issue.

## 2. Order

1. list-milestone-issues. Keep the `type:verify` issue aside for the end.
2. Sort the rest so every issue comes after its blockers (blockers-of). An issue blocked by something outside the milestone that is still open is marked blocked from the start.
3. Show the user the order, one line per issue, once. Start unless they change it.

## 3. Each issue

For each issue in order whose blockers are cleared:

1. Run run-issue with base `sprint/<milestone-slug>`. Its step 9 merges the approved issue PR into the sprint branch.
2. Update the sprint PR's issue table.

## 4. Stuck issues

When run-issue stops on an issue (`needs-input`, or blocked by a limit):

1. Leave its label and its plan comment as they are (the plan says where it stopped and why).
2. Mark every issue that depends on it as waiting in the sprint PR table.
3. Continue with the next issue that doesn't depend on it.

The questions from every stuck issue go to the user together in the final report, not one at a time during the run.

## 5. Sprint verification

When no runnable issue is left:

1. Delivery: `git fetch` and switch to the sprint branch head.
2. Checker: run the check command on the sprint branch.
3. Run the `type:verify` issue: [skills/verify/SKILL.md](../verify/SKILL.md) on the whole sprint branch, ticking each agent row with real evidence. Rows only a person can do stay open for the user.
4. A failed row becomes a new issue in this milestone (create-issue, linked from the verification issue). Run it with run-issue, then repeat this step.

## 6. Sprint review

Start a fresh pr-reviewer with the sprint PR number and the milestone's issue numbers. It looks across issues for conflicts, duplicate helpers, inconsistent names, and blast radius. Findings become a new issue in the milestone, handled as in step 5.

## 7. Merge

1. Update the sprint PR body: `Closes #N` for every merged issue (not stuck ones), the verification results, the review verdict, and the checks only a person can do.
2. Mark the PR ready (`gh pr ready <PR>`).
3. Delivery: `merge` with `--merge`. It merges only when the lock file says `"merge": "agent"` and every merge condition holds. Stuck issues don't block the merge; they stay open in the milestone.
4. After the merge, follow "Closing issues" in the tracker file. When the milestone has no open issues, close-milestone.

## 8. Report

One message to the user:

- Done: each issue with its PR.
- Stuck: each issue, why, and the exact question or failure.
- Evidence summary and the sprint PR link.
- Checks only a person can do, numbered, in plain words.
- Merged, or waiting for their merge.
