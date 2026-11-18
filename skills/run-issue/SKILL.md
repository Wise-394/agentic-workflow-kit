---
name: run-issue
description: Use when the user hands over one issue (a link or a number) and wants it taken to a reviewed, verified pull request.
---

# Run one issue

The planner runs this flow and hands each step to a role. Tracker commands are in [tracker/github.md](../../tracker/github.md); limits and permissions are in [safety/baseline.md](../../safety/baseline.md). Read `AGENTS.md` and `.agentkit/lock.json` first.

**Base branch:** the lock file's `git.integrationBranch`, or the sprint branch when [skills/run-sprint/SKILL.md](../run-sprint/SKILL.md) calls this skill.

## 0. Resume or start

Run read-issue and find-plan-comment. If a plan comment exists, read its **State** and continue from the matching step below. Check the branch (`git branch -r --list "*<N>-*"`) and any open PR (`gh pr list --search "<N> in:body" --state open`).

## 1. Intake

1. Read the issue body, every comment, and each linked issue. Read the PRD issue's rows for the requirement IDs it names.
2. Check blockers with blockers-of. An open blocker stops the run: tell the user which issue blocks it.
3. Choose the playbook ([skills/playbooks/SKILL.md](../playbooks/SKILL.md)).
4. Claim the issue: claim, then set-status `in-progress`.

## 2. Scout

1. Post the plan comment with **Scout questions** filled in and **State: scouting**: the existing names, files, and helpers the contracts depend on.
2. Run the scout ([roles/scout.md](../../roles/scout.md)) with the issue number. Put its answers under each question.

## 3. Plan

1. Fill the rest of the plan with [skills/write-plan/SKILL.md](../write-plan/SKILL.md). Set **State: planned**.
2. Questions only the user can answer: ask-user, set-status `needs-input`, stop. When the user answers, update the plan and continue.

## 4. Branch

Run delivery ([roles/delivery.md](../../roles/delivery.md)) with `start-branch`, the branch name from `git.branchPattern`, and the base. Set **State: building**.

## 5. Build

1. **Tests.** Run the test-writer ([roles/test-writer.md](../../roles/test-writer.md)). Read the red evidence: every test must fail for the plan's reason. If one doesn't, add a review finding for the test-writer and run it again.
2. **Code.** Run the coder ([roles/coder.md](../../roles/coder.md)).
3. **Check.** Run the checker ([roles/checker.md](../../roles/checker.md)). On FAILED, run the coder with the failure lines, then the checker again.
4. **Self-review.** Read the real diff (`git diff origin/<base>` and `git status --short`; read every new file in full) against the plan. Blocking problems become **Review findings** in the plan comment, go back to the coder or test-writer, and the checker runs again.

## 6. Verify

Set **State: verifying**. Run the verifier ([roles/verifier.md](../../roles/verifier.md)) with the plan's **Proof plan**. Any FAIL goes back to step 5 as a review finding. If the project has no verify skill yet, run [skills/verify/SKILL.md](../verify/SKILL.md) to create one first, with the user's approval.

## 7. Pull request

1. Write the PR body from [templates/pr-body.md](../../templates/pr-body.md), using the checker's and verifier's real output.
2. Run delivery with `open-pr`: every changed file (code and tests), the base, and the title `<type>(#<N>): <title>`.
3. Post the evidence comment (post-evidence). Set-status `in-review`. Set **State: in review**.

## 8. Independent review

1. Start a **fresh** pr-reviewer ([roles/pr-reviewer.md](../../roles/pr-reviewer.md)) with only the issue number and the PR number. Don't pass the plan, your summary, or the workers' reports.
2. **Changes requested:** copy each finding into the plan's **Review findings**, then repeat step 5 (coder, checker, self-review) and step 6 for those findings only. Run delivery `update-pr`, then a fresh pr-reviewer again.
3. **Approved:** continue.

## 9. Merge

- **Inside a sprint:** run delivery `merge` into the sprint branch. Leave the issue open; the sprint PR closes it.
- **Otherwise:** run delivery `merge`. It merges only when the lock file says `"merge": "agent"` and every merge condition holds. Otherwise it reports "ready to merge", and you tell the user.
- After a merge into the integration branch, follow "Closing issues" in the tracker file. Set **State: done** and remove the status label.

## 10. Tell the user

In plain words: what was built, the PR link, the evidence summary, the checks only a person can do (numbered), and whether it was merged or is waiting for them.

## Rules

- Workers keep no memory. Everything they need is in the plan comment, not in your messages.
- Never claim a result you didn't see in a role's real output.
- The PR body and commits describe the result, not the session (no agent names, review rounds, or scout answers).
