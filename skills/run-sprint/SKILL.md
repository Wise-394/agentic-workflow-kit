---
name: run-sprint
description: Use when the user names a milestone (sprint) and wants every issue in it built, reviewed, and verified on a sprint branch, ending in one pull request into the integration branch.
---

# Run a sprint

The planner runs this flow. Each issue goes through [skills/run-issue/SKILL.md](../run-issue/SKILL.md) with the sprint branch as its base. Tracker and git actions are in [tracker/github.md](../../tracker/github.md); limits are in [safety/baseline.md](../../safety/baseline.md).

The sprint branch is named by the lock file's `git.sprintBranchPattern` (default `sprint/<milestone-slug>`); below it is called `<sprint-branch>`.

## 0. Resume or start

1. Run list-milestones and find the milestone.
2. If `<sprint-branch>` exists on the remote (`git ls-remote --heads origin <sprint-branch>`): delivery resume-branch on it, run find-pr for it, and read the sprint PR body. Its issue table says where to continue; skip step 1. An issue marked in progress resumes through run-issue's own step 0.
3. Otherwise: start at step 1.

## 1. Sprint branch and draft PR

1. Delivery: start-branch `<sprint-branch>` from the integration branch.
2. Delivery: open-sprint-pr with the body from [templates/sprint-pr-body.md](../../templates/sprint-pr-body.md). The draft PR is the live progress view; update its issue table after every issue.

## 2. Order

1. list-milestone-issues. Keep the `type:verify` issue aside for the end.
2. Sort the rest so every issue comes after its blockers (blockers-of). An issue blocked by something outside the milestone that isn't cleared is marked blocked from the start.
3. Show the user the order, one line per issue, once. Start unless they change it.

## 3. Each issue

For each issue in order whose blockers are cleared:

1. **Start clean.** Treat each issue as if you'd never seen the earlier ones: re-read the sprint PR table, the issue, and its plan comment from the tracker. Don't carry facts from an earlier issue in your head; if a later issue needs them, they belong in its plan. If your tool can start a fresh session per issue, do.
2. Run run-issue with base `<sprint-branch>`. Its step 9 merges the approved issue PR into the sprint branch.
3. Update the sprint PR's issue table.

## 4. Stuck issues

When run-issue stops on an issue (`needs-input`, or `blocked` by a limit):

1. Leave its label and its plan comment as they are (the plan says where it stopped and why).
2. Mark every issue that depends on it as waiting in the sprint PR table.
3. Continue with the next issue that doesn't depend on it.

The questions from every stuck issue go to the user together in the final report, not one at a time during the run.

## 5. Bring the sprint up to date

When no runnable issue is left:

1. Delivery: resume-branch on `<sprint-branch>` (picks up every merged issue PR).
2. If the integration branch moved since the sprint started, delivery: sync-branch on the sprint branch. Conflicts follow the sync-branch rules; a conflict outside every merged issue's files goes to the user.
3. Checker, full mode, on the sprint branch head. A failure becomes a fix issue (step 8).

Steps 6 and 7 always run on this head. Any later commit to the sprint branch means running 5.3, 6, and 7 again.

## 6. Sprint verification

Run the `type:verify` issue: [skills/verify/SKILL.md](../verify/SKILL.md) on the sprint branch head, ticking each agent row with real evidence. Rows only a person can do stay open for the user. A failed row becomes a fix issue (step 8).

## 7. Sprint review

Start a fresh pr-reviewer with the sprint PR number and the milestone's issue numbers (and, on a repeat, the sha reviewed last). Besides its normal review pass, it looks across issues for conflicts, duplicate helpers, the same kind of file built in different shapes, inconsistent names, layer boundaries crossed, and blast radius. Blockers and majors become a fix issue (step 8). Minors and rule proposals go to the retro.

## 8. Fix issues

1. Each failure from steps 5–7 becomes a new issue in this milestone (create-issue, linked from the verification issue or the sprint PR), run with run-issue.
2. Then go back to step 5.
3. Do this at most `limits.sprintFixRounds` times. After that, leave the remaining failures open, mark them in the sprint PR table, and put them in the report; the sprint PR isn't marked ready.

## 9. Merge

1. Update the sprint PR body: `Closes #N` for every merged issue (not stuck ones), the full check result with the head sha, the verification results, the review verdict, and the checks only a person can do.
2. Delivery: ready-pr.
3. Delivery: `merge` with `--merge`. It merges only when the lock file says `"merge": "agent"` and every merge condition holds on the current head. Stuck issues aren't in the `Closes` list, so they don't block the merge; they stay open in the milestone.
4. After the merge, follow "Closing issues" in the tracker file. When the milestone has no open issues, close-milestone.

## 10. Retro

Run [skills/retro/SKILL.md](../retro/SKILL.md) on the milestone. Its proposals go into the report below; nothing is applied without the user's yes.

## 11. Report

One message to the user:

- Done: each issue with its PR.
- Stuck: each issue, why, and the exact question or failure.
- Open failures, if the fix rounds ran out.
- Retro proposals: each with what it would have caught.
- Evidence summary and the sprint PR link.
- Checks only a person can do, numbered, in plain words.
- Merged, or waiting for their merge.
