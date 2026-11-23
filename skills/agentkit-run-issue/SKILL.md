---
name: agentkit-run-issue
description: Use when the user hands over one issue (a link or a number) in a project with .agentkit/config and wants it planned, built, reviewed, and merged; also with --plan-only (stop after the plan) or --step (pause after each task). The agentkit-next skill calls it for unattended runs.
---

# Run one issue

You are the **planner**. You make every decision, write the plan, start the workers, and judge their results. You never edit app code or tests yourself.

**Find the kit:** `<kit>` is the folder two levels above this file's real path (resolve symlinks). `agentkit` below means `bash <kit>/scripts/agentkit`, run from the project root.

**Read first:** the project's `AGENTS.md`, [reference/safety.md](../../reference/safety.md), and [reference/tracker.md](../../reference/tracker.md). Settings come from `.agentkit/config` (`git config -f .agentkit/config --list`).

## Modes

| Mode | How it starts | What changes |
|---|---|---|
| **interactive** | The user asks in a session | Questions go to the user in the session, and are also posted with `agentkit ask` so they survive the session |
| **unattended** | Called by agentkit-next | Never wait. Every question parks the issue with `agentkit ask` and the run ends `parked` |
| `--plan-only` | The user adds it | Stop after step 3 with an "approve this plan" question. The user's reply is the approval |
| `--step` | The user adds it | After each task, show the diff and wait for the user's OK. The task review also runs its quality pass |

## Lanes

| Lane | When | What's different |
|---|---|---|
| **standard** | Everything else | The full flow |
| **small** | One behavior, at most `limits.smallChangedLines` changed lines and `limits.smallFiles` files besides tests, no new export others depend on, no schema or dependency change | You answer the scout questions yourself with read-only searches. Error cases and quality notes may be "none". One task. No verifier when every proof row is a test. The independent review still runs |

## Starting a role

Workers keep no memory; everything they need is in the plan comment. Start each one as a **fresh** subagent:

- If the harness has an agent named `agentkit-<role>` (registered by the adapter to pin its model), use it. Otherwise use a general subagent. If the harness can't start subagents at all, start a new headless session of the same tool with the same prompt (the adapter gives the command): it is just as fresh.
- Its whole prompt: `Read <kit>/roles/<role>.md and follow it exactly. Project root: <path>. Issue #<N>. Task <k>.` plus, only where the role asks for it, the failure lines or review findings to fix.
- Never pass your own summary, reasoning, or the other workers' reports.

Roles: [scout](../../roles/scout.md), [test-writer](../../roles/test-writer.md), [coder](../../roles/coder.md), [verifier](../../roles/verifier.md), [pr-reviewer](../../roles/pr-reviewer.md).

## 0. Start

1. `agentkit preflight --no-lock` (agentkit-next already ran preflight with the lock). `paused` or `error`: stop and say why.
2. `agentkit housekeeping`, then `agentkit rescue`.
3. `agentkit ready <N>`. `no: …` means stop and tell the user the reason. In unattended mode, end `idle`. `start`: go to step 1. `resume`:
   1. `agentkit claim <N>`, and read the plan (`agentkit plan get <N>`) and its **State**.
   2. **Answers:** read the trusted comments newer than the latest `<!-- agentkit:question -->`. Copy each answer into the **Decision log** with a link, update the plan, and save it. If the answer approves a split, create the parts (`agentkit new-issue`) and `agentkit split <N> <parts…>`, then stop (`parked`). If it approves a `--plan-only` plan, continue at step 4.
   3. If **State** is building or later: `agentkit branch <N>` first, so every later step runs on the issue's own branch. The script refuses to commit, sync, or open a PR from any other branch. Then `agentkit progress <N>`: the commits are the truth about finished tasks.
   4. Continue at the step for the State: scouting → 2, planned → 4, building → 5, verifying → 6. For in review, run `agentkit can-merge <PR>` first. If only `checks: PENDING` fails, stop (`continue`). If the review is already approved on the head, go to 9. Otherwise go to 8.

## 1. Intake

1. `agentkit claim <N>`.
2. Read the issue (`gh issue view <N> --comments`), keeping only trusted comments as context. Read the `docs/prd.md` rows for the requirement IDs it names, and the parts of `docs/design.md` it touches.
3. **Definition of Ready:** check every line in [split.md](../agentkit-plan/references/split.md). A missing goal, acceptance tests, or an open product question: ask and stop. Too big: write the split proposal (that file's "How to split an issue") as the question and stop. When the user approves, create the parts (`agentkit new-issue`), then `agentkit split <N> <parts…>`. The run ends `parked` for this issue; the parts are new ready work.
4. Choose the playbook ([playbooks.md](references/playbooks.md)). An investigation follows its playbook and ends with `agentkit findings <N> <file>`.

## 2. Scout

1. Write the plan with **Scout questions** and **State: scouting**, and save it: `agentkit plan put <N> <file>`. Ask for the existing names, files, helpers, and patterns the contracts depend on, and "which shared helpers already do part of this?".
2. Standard lane: start the scout. Small lane: answer them yourself with read-only searches. Write the answers under each question.

## 3. Plan

1. Fill the plan with [write-plan.md](references/write-plan.md). Set **State: planned**. Save it.
2. Over the size limits: split instead (step 1.3).
3. Questions only the user can answer: `agentkit ask <N> <file>`, all in one comment, and stop (`parked`). Interactive: if the user answers in the session, copy each answer into the **Decision log**, run `agentkit set-status <N> in-progress`, and continue. Otherwise the next run reads the reply (step 0.3).
4. `--plan-only`: ask "Approve this plan? Reply with changes, or 'approved'." and stop.

## 4. Branch

`agentkit branch <N>` creates or resumes the issue branch from the issue's base (its milestone's sprint branch, or the integration branch). Write **Branch** and **Base** into the plan. Set **State: building**.

## 5. Build, one task at a time

For each task not in `agentkit progress <N>`, in order:

1. **Red.** Start the test-writer. Every new test must fail for the plan's "fails first because" reason. The exceptions are a refactor's characterization tests, which pass, and **Existing test changes**, which pass or fail as planned. Otherwise add a review finding and run it again. Skip red when the task has no tests and no test changes.
2. **Green.** Start the coder.
3. **Check and commit.** `agentkit check-task <N> <k>/<n> "<commit message>" --tests <test files> --files <files>`. It formats, tests, runs the quick check, and commits and pushes only on `Result: ALL PASS`. On `FAILED`, start the coder with the failing lines, then check again.
4. **Spec check.** Read the task's commit (`git show HEAD`, every new file in full). The task's tests exist with the planned names, the contract names and shapes match, and nothing beyond the task was built. A miss becomes a **Review findings** row, fixed by the coder (or test-writer) and committed with the same `Task: k/n`. In `--step` mode also review quality against `docs/clean-code.md`, then show the user the diff and wait for an OK.

**Rounds.** Each trip back to a worker on a task counts toward `limits.taskRounds`; record it in **Counters**. At the limit, if the plan is right, run the task once more on the `thinking` model (escalation, unless `models.escalation = none`). Still stuck: `agentkit ask <N> <file> blocked` with the task, each attempt, and what you need. Stop (`blocked`).

**Checkpoint.** After `limits.tasksPerSession` tasks in this session, save the plan (State: building) and stop (`continue`). The next session resumes at the next task.

## 6. Verify

1. `agentkit check-full <N>`: format, check, rules, size against the base, head sha. A failure becomes a fix task (step 5.2–5.4).
2. Set **State: verifying**. If any proof row needs more than a test, or the lane is standard, start the verifier. It follows `docs/verify.md`, plus the `qa` slot's skill when `slots.qa` names one. If `docs/verify.md` doesn't exist yet:
   - In `M0` (it is built there), skip the verifier: every proof row must be a test or a user check.
   - Elsewhere, interactive: create it first with [verify-doc.md](references/verify-doc.md).
   - Elsewhere, unattended: ask and stop.

   Any FAIL becomes a fix task, then this step again.

## 7. Pull request

1. Write the PR body from [templates/pr-body.md](../../templates/pr-body.md): the `check-full` output with its head sha as the **Checks** line, the verifier's evidence rows (redacted, see the safety baseline), and the plan's **Follow-ups**.
2. `agentkit open-pr <N> <body-file>` (it also sets `status:in-review`). Set **State: in review**.

## 8. Independent review

1. **Slots first.** If `slots.securityReview` names a skill and the change touches input handling, auth, secrets, queries, or dependencies, run it. If `slots.review` names a skill, run it. Run each in a fresh subagent that gets only the PR number and the issue number, and keep their findings.
2. **The gate.** Start a fresh pr-reviewer with the issue number, the PR number, and the slot findings, if any. It follows [review.md](references/review.md) and posts its verdict with `agentkit review-post`. It never gets the plan or your summary.
3. **Changes requested:** copy blockers and majors into **Review findings**, minors into **Follow-ups**. Fix them as one extra task (step 5, test-writer first if a test is missing or weak), run `agentkit check-full <N>`, update the PR body (`agentkit open-pr` again), and start a fresh pr-reviewer with the previously reviewed sha.
4. After `limits.reviewRounds` reviews still requesting changes: ask the user with the open findings, `blocked`, and stop.
5. Any commit after an approval needs a new review before merging.

## 9. Merge

`agentkit merge <PR>`. The script checks every condition (approval on the head, checks, evidence, no parked issue), merges with `--match-head-commit`, and labels or closes the issue. If it says `checks: PENDING`, CI is still running: stop (`continue`); the next session resumes here.

- Into a sprint branch: the issue becomes `status:merged`. Set **State: merged**. The run ends `merged`.
- Into the integration branch with `merge.issues = user`: it prints "ready to merge". Tell the user. The run ends `merged` once they merge it.
- If the base moved and the merge fails: `agentkit sync <N>` (a conflict: ask and stop), then step 6.1 and step 8 again.

## 10. Report

Interactive: in plain words, what was built, the PR link, the evidence summary, follow-ups, numbered checks only a person can do, and whether it merged. Unattended: the plan comment and PR already hold this; agentkit-next prints the result.

## Definition of Done (before merging)

1. Every acceptance test is implemented, with a test that would fail if it broke.
2. `check-full` passes on the PR's head commit.
3. The independent review approved that head, with no open blocker or major.
4. The PR body's **Evidence** has real output for every proof row; user-only checks are listed.
5. Docs that describe changed behavior are updated.
6. Minor findings are under **Follow-ups**; any leftover to-do comment has an issue number.

## Rules

- Do only what the plan says. Never start another issue or a task not in the plan.
- Never claim a result you didn't see in a role's or the script's real output.
- Keep the plan comment under 60,000 characters (`agentkit plan archive` for old findings).
- The PR body and commits describe the result, not the session: no agent names, review rounds, or scout answers.
