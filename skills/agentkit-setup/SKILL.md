---
name: agentkit-setup
description: Use when the user wants the agentic workflow kit set up in a project (empty or not), wants it re-checked after the kit was updated, or when an M0 bootstrap issue asks for the project docs to be written from the real code.
---

# Set up the kit in a project

The kit itself holds no state and no version. A project that uses it has:

| File | What it is |
|---|---|
| `.agentkit/config` | Settings: tracker, branches, commands, models, slots, limits. Committed |
| `AGENTS.md` (plus `CLAUDE.md` containing `@AGENTS.md` for Claude Code) | Facts about this project for every session |
| `docs/prd.md`, `docs/design.md`, `docs/decisions/` | The plan, written with agentkit-plan |
| `docs/clean-code.md`, `docs/patterns.md`, `docs/testing.md`, `docs/verify.md` | How code is written, copied, tested, and proven here |
| Adapter files | Only what the adapter for the user's tool says (thin named agents to pin models, optionally a permission profile) |
| GitHub labels | Created by `agentkit labels` |

**Find the kit:** `<kit>` is the folder two levels above this file's real path (resolve symlinks). `agentkit` means `bash <kit>/scripts/agentkit`.

**Ground rules:** ask one question at a time, in plain words, with a concrete example and your suggested answer. Never guess what you can ask; never ask what you can detect. Never overwrite a file you didn't create without showing a diff and getting a yes. Write nothing until the preview is approved.

## Which mode

| Situation | Mode |
|---|---|
| No `.agentkit/config` | **Install**, then, if the repo has code, **Project docs** |
| `.agentkit/config` exists and the user asks to set up or check again (for example after updating the kit) | **Reconcile** |
| An M0 issue asks for the project docs | **Project docs**, unattended: record assumptions instead of asking |

## Install

### 1. Detect

Find each of these without asking, and note where it came from:

| What | How |
|---|---|
| Tool in use | Your own environment and tool folders in the project. Pick the matching file in [adapters/](../../adapters/). None matches: say which exist and stop |
| Empty or not | `git rev-parse HEAD` fails, or only docs exist: **empty** |
| Remote and account | `git remote -v`; `gh auth status`; `gh repo view --json nameWithOwner,defaultBranchRef`; `gh api user --jq .login`. No remote: ask the user to create the GitHub repository first (`gh repo create`) |
| Integration branch | Where recent PRs merged: `gh pr list --state merged --limit 20 --json baseRefName`. None: suggest the default branch |
| Branch protection | `gh api repos/<repo>/branches/<branch>/protection` (404 = not protected) |
| Commands | Scripts in package and build files: check, quick, test, format, rules. Empty repo: leave empty; M0 fills them |
| Existing agent setup | `AGENTS.md`, `CLAUDE.md`, rule files, skills, agent folders |
| Installed skills | The skills your tool can invoke right now (your own skill list), for the slot question |

### 2. Ask

Show what you found as a table (what, value, source) and ask the user to correct it. Then ask only what's left:

1. **Models.** Two tiers. **thinking** (the planner and the pr-reviewer: judgment, design, review) gets the strongest model. **working** (scout, test-writer, coder, verifier: following a precise plan) gets a capable mid-tier model. Suggest from the adapter's list. `inherit` is always allowed. The user can pick the same model for both.
2. **Slots.** For each slot, list the installed skills that fit and well-known ones that could be installed, suggest one with a reason, and offer `kit` (the kit's own step) and, for optional slots, `off`:

   | Slot | Used for | Kit fallback | Examples of fillers |
   |---|---|---|---|
   | `review` | An extra review pass before the kit's own independent reviewer, which always runs and decides | Only the kit reviewer | A code-review skill or command of the tool |
   | `qa` | Driving the running app during verification | `docs/verify.md` alone | A browser-testing or QA skill, a browser automation tool |
   | `securityReview` (optional) | A security pass on PRs touching input, auth, secrets, queries, or dependencies | The security section of `docs/clean-code.md`, inside the review | A security-review skill |

   Write the skill's name as the tool invokes it. Never fill a slot the user didn't confirm.
3. **Merge for issues outside milestones:** `user` (default) or `agent`. Explain: issue PRs into sprint branches are always merged by the agent after review; sprint PRs always by the user.
4. **Forbidden commands.** Suggest from the stack (deploys, device installs, database resets, paid APIs). The user confirms or edits.
5. **Unattended runs.** "Will an outside runner start sessions on its own?" If yes, show the adapter's "Unattended permission profile" and offer to write it. Write it only on a yes. Recommend branch protection and a separate GitHub account for the agent. If the user also wants reviews posted by a second account, set `tracker.reviewerLogin` to it: the runner must then provide that account's token as `AGENTKIT_REVIEWER_TOKEN`, or nothing can merge.
6. **Limits.** Show the defaults from [templates/config](../../templates/config) in one table; change only what the user asks.

### 3. Preview, then write

Show every file to create or change (with diffs for existing ones), the labels, and what stays untouched. After a yes:

1. `.agentkit/config` from [templates/config](../../templates/config), filled in.
2. `.gitignore`: add `.agentkit/*` and `!.agentkit/config`, so runtime files (runs, evidence, lock) stay out of git.
3. The adapter's files, exactly as [the adapter](../../adapters/) says.
4. `agentkit labels`.
5. **Empty repo:** stop here and run [agentkit-plan](../agentkit-plan/SKILL.md). Its first commit includes every file setup wrote, and its M0 milestone builds the rest. **Repo with code:** continue with Project docs (interactive), then offer agentkit-plan, whose `docs/plan` PR carries setup's files too.

These files must be committed before any run. A run refuses to start on a checkout with uncommitted changes to tracked files, and an unattended runner's checkout needs the config. The integration branch is created from the default branch on the first run if it doesn't exist.

## Project docs

Writes `AGENTS.md` and the docs from the real code. Interactive: ask about anything unclear. Unattended (an M0 issue): decide, and list every assumption in the PR body for the user.

1. **Read the code:** source folders and what each holds; the import direction between them; naming per kind of file; the error-handling style; comment style; the cleanest existing file of each kind; the test runner and helpers; formatter and linter configs; existing rules in instruction files.
2. **`AGENTS.md`** from [templates/AGENTS.md](../../templates/AGENTS.md). If one exists, merge: keep every existing rule, map it into the template's sections, and show the result in full. Hard rules also take the principles from `docs/design.md`. For Claude Code, add `CLAUDE.md` with `@AGENTS.md` (or add that line to an existing one).
3. **`docs/clean-code.md`, `docs/patterns.md`, `docs/testing.md`** from [templates/docs/](../../templates/docs/), filled from the real repo (a real pattern file per row, the real test runner, the real layer table). If the project has an equivalent doc, keep it, point to it, and propose the missing sections. Leave out rows you can't fill; never leave `<placeholder>` text.
4. **`docs/verify.md`**, if missing, with [verify-doc.md](../agentkit-run-issue/references/verify-doc.md).
5. **Commands.** Fill `[commands]` in `.agentkit/config` and run each once; report the real result.
6. **Rules check.** Propose which rules of the standard a tool can enforce, with [rules-check.md](references/rules-check.md). Interactive: the user picks. Unattended: propose them in the PR body only.
7. **Check:** `grep -rnE '<[^!/ >][^>]*>' AGENTS.md docs/ .agentkit/config` shows no leftover placeholders.

## Reconcile (run setup again)

The kit has no version: rerunning setup brings a project in line with the kit it has now. Show what would change and apply only after a yes.

1. **Config keys:** compare `.agentkit/config` with [templates/config](../../templates/config). Ask about each missing key, offering the template's default. Never change a value the user set.
2. **Labels:** `agentkit labels`.
3. **Adapter files:** regenerate them from the current adapter and show a diff against what's there.
4. **Project docs:** for `AGENTS.md` and each doc, list the template's sections the project doc lacks and propose filled-in additions as a diff. Never regenerate a doc.
5. **Slots:** offer skills installed since the last setup.
6. **Older kit leftovers:** if the project has `.agentkit/lock.json`, `.agentkit/kit/`, a PRD issue labelled `prd`, a `verify-<project>` skill, or agent files for `checker` or `delivery`, propose the move:
   - `lock.json` becomes `config`.
   - The PRD issue body becomes `docs/prd.md`.
   - The verify skill becomes `docs/verify.md`.
   - Remove the old files after a yes.

   For issues already merged into a sprint branch and still open with no label: `agentkit housekeeping` marks them.
7. Run `agentkit preflight --no-lock` and report.
