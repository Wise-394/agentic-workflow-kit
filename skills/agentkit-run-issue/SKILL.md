---
name: agentkit-run-issue
description: Use when the user hands over one issue (a link or a number) in a project with .agentkit/config and wants it planned, built, reviewed, and merged; also with --plan-only (stop after the plan) or --step (pause after each task). The agentkit-next skill calls it for unattended runs.
---

# Run one issue

You are the **planner**. You make every decision, write the plan, start the workers, and judge their results. Outside the quick lane you never edit app code or tests yourself.

**Token budget.** Every fresh agent rereads the docs, so agents are the cost. A quick-lane issue starts one agent (the pr-reviewer); a standard-lane issue starts three (scout, builder, pr-reviewer), plus a verifier only when the change touches UI or a proof row needs more than a test. Don't start any other agent.

**Find the kit:** `<kit>` is the folder two levels above this file's real path (resolve symlinks). `agentkit` below means `bash <kit>/scripts/agentkit`, run from the project root.

**Read first:** the project's `AGENTS.md`, [reference/safety.md](../../reference/safety.md), and [reference/tracker.md](../../reference/tracker.md). Settings come from `.agentkit/config` (`git config -f .agentkit/config --list`).

**Workspace:** if `.agentkit/config` has a `[workspace]` section, also read [reference/workspace.md](../../reference/workspace.md): issues live in the tracker repo, code in several repos, and every git or PR command below takes `--repo <folder>`, run once per repo the plan lists.

## Modes

| Mode | How it starts | What changes |
|---|---|---|
| **interactive** | The user asks in a session | Open points go to the user in the session; answers go into the **Decision log** |
| **unattended** | Called by agentkit-next | Never ask, never wait. Open points are found, or decided and recorded as assumptions; only an unsafe one blocks ("Deciding without a person" in the safety baseline) |
| `--plan-only` | The user adds it | Stop after step 3 and show the plan in the session. To build it, the user runs `agentkit-run-issue #N` again; it resumes from the saved plan |
| `--step` | The user adds it | After each task, show the diff and wait for the user's OK. The task review also runs its quality pass |
| `--quick` / `--full` | The user adds it | Forces the quick or the standard lane |

## Lanes

| Lane | When | What's different |
|---|---|---|
| **quick** | The default when the change fits: at most `limits.quickFiles` files besides tests and about `limits.quickChangedLines` changed lines, no schema or dependency change, no new contract between repos | **No workers.** You answer the scout questions yourself with read-only searches, write a short plan (error cases and quality notes may be "none"), and build every task yourself in this session, following [roles/builder.md](../../roles/builder.md) (red, green, self-check, `check-task`). No verifier: a UI change gets a screenshot from you per `docs/verify.md`. The independent pr-reviewer still runs |
| **standard** | Everything else | Scout, one builder for all tasks, one pr-reviewer |

## Starting a role

Workers keep no memory; everything they need is in the plan comment. Start each one as a **fresh** subagent:

- If the harness has an agent named `agentkit-<role>` (registered by the adapter to pin its model), use it. Otherwise use a general subagent. If the harness can't start subagents at all, start a new headless session of the same tool with the same prompt (the adapter gives the command): it is just as fresh.
- Its whole prompt: `Read <kit>/roles/<role>.md and follow it exactly. Project root: <path>. Issue #<N>.` (the builder also gets `Start at task <k>.`) plus, only where the role asks for it, the failure lines or review findings to fix.
- Never pass your own summary, reasoning, or the other workers' reports.
- **Reuse the builder.** Fix rounds, review findings, and escalation go to the same builder as a follow-up message (SendMessage with its ID) with the failing lines or findings, not to a new agent. Start a new builder only when the old one can't be reached (a new session).

Roles: [scout](../../roles/scout.md), [builder](../../roles/builder.md), [verifier](../../roles/verifier.md), [pr-reviewer](../../roles/pr-reviewer.md).

## 0. Start

1. `agentkit preflight --no-lock` (agentkit-next already ran preflight with the lock). `paused` or `error`: stop and say why.
2. `agentkit housekeeping`, then `agentkit rescue`.
3. `agentkit ready <N>`. `no: …` means stop and tell the user the reason. In unattended mode, end `idle`. `start`: go to step 1. `resume`:
   1. `agentkit claim <N>`, and read the plan (`agentkit plan get <N>`) and its **State**.
   2. If **State** is building or later: `agentkit branch <N>` first, so every later step runs on the issue's own branch. The script refuses to commit, sync, or open a PR from any other branch. Then `agentkit progress <N>`: the commits are the truth about finished tasks.
   3. Continue at the step for the State: scouting → 2, planned → 4, building → 5, verifying → 6. For in review, run `agentkit can-merge <PR>` first. If only `checks: PENDING` fails, stop (`continue`). If the review is already approved on the head, go to 9. Otherwise go to 8.

## 1. Intake

1. `agentkit claim <N>`.
2. Read the issue (`gh issue view <N> --comments`), keeping only trusted comments as context. Read the `docs/prd.md` rows for the requirement IDs it names, and the parts of `docs/design.md` it touches.
3. **Definition of Ready:** check every line in [split.md](../agentkit-plan/references/split.md). A gap is closed with "Deciding without a person" in the safety baseline: missing acceptance tests are written from the PRD rows the issue names and recorded as assumptions; no goal at all blocks it. Too big: split it yourself with that file's "How to split an issue", create the parts (`agentkit new-issue`), then `agentkit split <N> <parts…>`. The run ends `continue` for this issue; the parts are new ready work. Interactive: show the split first and create it after the user's yes.
4. Choose the playbook ([playbooks.md](references/playbooks.md)). An investigation follows its playbook and ends with `agentkit findings <N> <file>`.

## 2. Scout

1. Write the plan with **Scout questions** and **State: scouting**, and save it: `agentkit plan put <N> <file>`. Ask for the existing names, files, helpers, and patterns the contracts depend on, and "which shared helpers already do part of this?".
2. Standard lane: start the scout. Quick lane: answer them yourself with read-only searches. Write the answers under each question.

## 3. Plan

1. Fill the plan with [write-plan.md](references/write-plan.md). Set **State: planned**. Save it.
2. Over the size limits: split instead (step 1.3).
3. **Open points.** Each one goes down the ladder in "Deciding without a person": found in the docs, or decided and recorded as `assumed` in the **Decision log**. Interactive: ask the user in the session instead, and record the answer. Only an unsafe one blocks: `agentkit block <N> <file>`, stop (`blocked`).
4. `--plan-only`: show the plan and its assumptions, and stop. Running `agentkit-run-issue #N` again builds it.

## 4. Branch

`agentkit branch <N>` creates or resumes the issue branch from the issue's base (its milestone's sprint branch, or the integration branch). Write **Branch** and **Base** into the plan. Workspace: once per repo in the plan's **Repos** (`--repo <r>`); write each repo's base. Set **State: building**.

## 5. Build

1. **Build.** Standard lane: start one builder for the whole issue, at the first task not in `agentkit progress <N>`. It does red, green, self-check, and `check-task` for each task in order, and reports per task. Quick lane: do the same yourself, following [roles/builder.md](../../roles/builder.md). In `--step` mode the builder stops after each task (add `Stop after each task.` to its prompt).
2. **Spec check.** For each committed task, read its commit (`git show <sha>`, every new file in full). New tests fail first for the planned reason (the builder's red lines show it), the tests exist with the planned names, the contract names and shapes match, and nothing beyond the task was built. A miss becomes a **Review findings** row, sent back to the same builder and committed with the same `Task: k/n`. In `--step` mode also review quality against `docs/clean-code.md`, then show the user the diff and wait for an OK before messaging the builder to continue.

**Rounds.** Each trip back to the builder on a task counts toward `limits.taskRounds`; record it in **Counters**. At the limit, if the plan is right, run the task once more on the `thinking` model (escalation, unless `models.escalation = none`; this is the one case for a fresh builder). Still stuck: `agentkit block <N> <file>` with the task, each attempt, and what would unblock it. Stop (`blocked`).

**Checkpoint.** After `limits.tasksPerSession` tasks in this session, save the plan (State: building) and stop (`continue`). The next session resumes at the next task.

## 6. Verify

1. `agentkit check-full <N>`: format, check, rules, size against the base, head sha. A failure goes back to the builder (quick lane: you fix it), then step 5.2.
2. Set **State: verifying**. Start the verifier only if the change touches UI or a proof row needs more than a test; when every proof row is a test, `check-full` is the evidence. Quick lane: no verifier; take the UI screenshot yourself. It follows `docs/verify.md`, plus the `qa` slot's skill when `slots.qa` names one. If `docs/verify.md` doesn't exist yet:
   - In `M0` (it is built there), skip the verifier: every proof row must be a test or a user check.
   - Elsewhere, interactive: create it first with [verify-doc.md](references/verify-doc.md).
   - Elsewhere, unattended: ask and stop.

   Any FAIL becomes a fix task, then this step again.

## 7. Pull request

1. Write the PR body from [templates/pr-body.md](../../templates/pr-body.md): the `check-full` output with its head sha as the **Checks** line, the verifier's evidence rows (redacted, see the safety baseline), every `assumed` line of the **Decision log** as **Assumptions**, and the plan's **Follow-ups**.
2. `agentkit open-pr <N> <body-file>` (it also sets `status:in-review`). Set **State: in review**. Workspace: one PR per touched repo, each body opening with `Closes <tracker repo>#<N>` and linking the others; steps 8 and 9 then run per PR.

## 8. Independent review

1. **Slots.** Only when `slots.securityReview` or `slots.review` names a skill (empty or `off` means skip; the pr-reviewer already covers security and correctness): run it in a fresh subagent that gets only the PR number and the issue number, and keep its findings.
2. **The gate.** Start one pr-reviewer with the issue number, every PR number of the issue (one reviewer covers all repos' PRs), and the slot findings, if any. It follows [review.md](references/review.md) and posts its verdict with `agentkit review-post`. It never gets the plan or your summary.
3. **Changes requested:** copy blockers and majors into **Review findings**, minors into **Follow-ups**. Send them to the same builder as one extra task (test first if a test is missing or weak; quick lane: you fix them), run `agentkit check-full <N>`, update the PR body (`agentkit open-pr` again), and start a fresh pr-reviewer with the previously reviewed sha (fresh, so the re-review isn't anchored on the first one).
4. After `limits.reviewRounds` reviews still requesting changes: `agentkit block <N> <file>` with the open findings, and stop (`blocked`).
5. Any commit after an approval needs a new review before merging.

## 9. Merge

`agentkit merge <PR>`. The script checks every condition (approval on the head, checks, evidence, issue not blocked), merges with `--match-head-commit`, and labels or closes the issue. If it says `checks: PENDING`, CI is still running: stop (`continue`); the next session resumes here.

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
