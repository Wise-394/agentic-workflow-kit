# Changelog

## 0.2.0 — 2026-11-18

Code quality and smaller units of work.

- **Code standard:** `docs/clean-code.md` is now a full standard (modularity and layers, readability, reuse without speculation, types and errors, state, performance, repeatability, hygiene) with a severity scale (blocker, major, minor, nit) and a review pass. The coder and test-writer read it before writing.
- **Two-pass review:** the pr-reviewer checks spec compliance, then code quality. Blockers and majors block; minors become **Follow-ups** in the PR; repeated minors become rule proposals. New `templates/review.md`.
- **Rules check:** new `rules-check` skill and `commands.rules`; setup proposes tools or a small script that enforce the standard inside the check command.
- **Work in three sizes:** new `split-issue` skill with milestone, issue, and task size rules, a Definition of Ready, INVEST, and a split procedure. New `limits` in the lock file.
- **Tasks:** plans have **Tasks** instead of **Steps**. `run-issue` builds one task at a time (red, green, check, task review, commit), with fresh workers per task.
- **Plans:** new **Error cases**, **Quality notes**, **Size**, and **Follow-ups** sections. A filled example plan and review in `templates/examples/`.
- **Planning:** PRD requirements in EARS form, non-functional requirements, and an analyze pass that builds a requirement → issue → test traceability table.
- **Retro:** new `retro` skill, run at the end of each sprint, turns repeated findings into patterns, standards, or checked rules.
- **Fixes:** the coder stops instead of fixing failures outside its files; the refactor exception to fail-first is explicit; new `sync-branch` (merge, never rebase) for conflicts; review rounds are capped; the self-approval marker is documented as self-attestation; the Claude Code adapter adds guard hooks; `check-kit.sh` checks plan sections and the lock version.
- **Model tiers:** three tiers instead of two. **thinking** (planner, pr-reviewer) gets the strongest model, **working** (test-writer, coder, verifier) a mid-tier one, and **light** (scout, checker, delivery) the cheapest. Setup asks for a model per tier, offering a suggestion with the reasons, and a stuck task can be retried once on a stronger model (`models.escalation`).
- **Trust:** comments never steer the work. Requirements come from the issue body and the user; kit markers and answers count only from the agent's account or the repo's collaborators (`tracker.agentLogin`, `tracker.reviewerLogin`); a USER OVERRIDE only comes from the user's prompt and never weakens the safety baseline.
- **Resume anywhere:** every task commit is pushed with a `Task: k/n` trailer, and resume reads progress from the commits. New tracker actions resume-branch, task-progress, find-pr, find-review, ready-pr, pin-issue, post-findings, read-issue-for-review.
- **Small-change lane:** one behavior up to `limits.smallChangedLines` lines skips the scout, the long plan, the task review, and the verifier when its test is the proof; the independent review stays.
- **Less overhead per task:** the checker commits after its checks pass (no delivery run per task), runs the new `commands.quick` and formats only the task's files; the full check runs once before the PR.
- **Loops have exits:** `limits.taskRounds` and `limits.sprintFixRounds`, a **Counters** section in the plan, and a re-review whenever the head moves after an approval. Merges use `--match-head-commit`.
- **Tests:** the plan lists **Existing test changes** (mechanical or assertion), so renames and signature changes no longer stall; tasks list their test files.
- **Review:** the reviewer reads the issue without the plan comment; security and correctness defects are blockers even when no requirement names them (new clean-code section 9).
- **Safety:** pushing to the integration or default branch, refspec deletes, `gh api` DELETE and merge/ref calls, `--admin`, global git config, and download-and-run package runners are forbidden; and secrets are off limits at any depth.
- **No generated permissions:** the adapters no longer write permission rules, guard hooks, or per-role tool limits. Subagents run with the session's own permissions; role limits and the safety baseline are written rules.
- **Evidence** lives in the PR body only, with the head sha the checks ran on; verifier output goes to the git-ignored `.agentkit/evidence/`.
- **Without a PRD:** requirement IDs are optional; issues outside the PRD name their tests `#<N>:`. Investigations clear their blockers once findings are posted.
- **Update** never regenerates project docs; it proposes template changes as diffs, lists every new 0.2.0 question, and handles plans in flight.
- **AGENTS.md template:** a folder table with a **Must not** column, size rules, and Definitions of Ready and Done.

## 0.1.0 — 2026-11-18

- First release: setup and update flows, eight roles, `run-issue`, `run-sprint`, `plan-project`, `write-plan`, `pr-review`, `verify`, playbooks, GitHub tracker actions, safety baseline, templates, opencode and Claude Code adapters, sandbox.
