# Setup

You are an agent setting up this kit in the user's project. Follow the steps in order. Don't write anything into the project before step 4's preview is approved.

Setup writes kit files (tool config, `AGENTS.md`, `docs/`, `.agentkit/`), so run it in a session that may edit files. Some adapters say which agent to use for this.

The kit source is this repository. If you were given a URL, clone it into a temporary folder outside the project (`git clone --depth 1 <url> <temp>/agentic-workflow-kit`) and read the files from there. Never commit the kit's clone into the project.

## Ground rules

- Ask one question at a time, in plain words, with a concrete example and your suggested answer.
- Never guess something you can ask. Never ask something you can detect.
- Never overwrite a file you didn't create without showing the user a diff and getting a yes.
- If `.agentkit/lock.json` already exists, stop and follow [UPDATE.md](UPDATE.md) instead.

## 1. Detect

Find each of these without asking. Record the answer and where it came from.

| What | Where to look |
|---|---|
| Agent tool in use | Your own environment, and existing tool config folders in the project. Pick the matching file in `adapters/`. If none matches, tell the user which adapters exist and stop. |
| Existing agent setup | Agent, skill, rule, and instruction files in the project; `AGENTS.md` or similar |
| Stack | Build and package files (package manifests, Makefile, build scripts) |
| Commands | The scripts those files define: one command that runs everything (check), one for a single test file (test), a fast check on given files such as lint plus typecheck (quick), a formatter and whether it takes file paths (format), and any rules or architecture check (rules) |
| Quality tooling | Linter and type-checker configs and their rules (complexity, length, import restrictions, unused code), architecture or import-boundary tools, custom rule scripts |
| Code shape | The source folders and what each holds; the import direction between them; naming per kind of file; comment style; the error-handling style (thrown errors or result values); the cleanest existing file of each kind (for `docs/patterns.md`) |
| Git | `git remote -v`; the default branch (default-branch in [tracker/github.md](tracker/github.md)); the integration branch (where recent PRs merged: `gh pr list --state merged --limit 20 --json baseRefName`); branch naming (`git branch -r`) |
| Tracker | `gh auth status`; the repo name from `gh repo view --json nameWithOwner`; the account agents run as (agent-login in [tracker/github.md](tracker/github.md)); whether the integration and default branches are protected (`gh api repos/{owner}/{repo}/branches/<branch>/protection`, a 404 means not protected) |
| Formatting state | Run the formatter in check mode (or on a scratch copy) to see whether the repo is already formatted. A repo that isn't would make the first task's format run touch unrelated files. |
| Existing rules | Hard rules, invariants, and forbidden commands in existing instruction files |
| Existing work tracking | Sprint, ticket, or status files in the repo |
| Docs | Existing testing, pattern, style, code-standard, and copy docs |

## 2. Confirm

Show the user everything you found in one message, as a table: what, value, source. Ask them to correct anything wrong. If `gh` isn't logged in, or no check command exists, say so and ask how they want to continue.

## 3. Ask

Only what step 1 couldn't answer, one question at a time:

1. **Merge policy.** "When a PR into `<integration branch>` is approved and verified, who merges: you or the agent?" Record `user` or `agent`. Whatever the answer, recommend protecting the integration and default branches (no direct pushes, required checks) if step 1 found them unprotected, and explain that the agent's own approval is self-attestation.
2. **Models.** Always ask; the tiers below are only a suggestion, and the user decides. Roles come in three tiers, and each tier should get the cheapest model that does its job well. Show this table, then ask one tier at a time: "Which model for the *thinking* roles (planner, pr-reviewer)? I suggest <model>." Then the same for *working* and *light*. Suggestions come from the models the user's tool offers (the adapter lists typical choices). The user can pick any model for any tier, use the same model for all three, or say "same as now". Never write a model the user didn't confirm.

   | Tier | Roles | What the work needs | Suggest |
   |---|---|---|---|
   | **thinking** | planner, pr-reviewer | Judgment: reading the whole issue, making every design decision, cutting tasks, judging quality, catching what others missed. Mistakes here spread to every task. | The strongest model available |
   | **working** | test-writer, coder, verifier | Following a precise plan: writing code and tests to exact contracts, fixing its own failures. | A capable mid-tier model; the plan has already made the hard decisions |
   | **light** | scout, checker, delivery | Mechanical steps: finding facts in the code, running commands and copying output, git and tracker commands. | The fastest, cheapest model |

   Explain why in one line: the planner writes the plan so precisely that workers don't need to be as strong, and most tokens are spent by workers, so cheaper workers cut the cost a lot without lowering quality. Two adjustments to offer:
   - If the codebase is unusual or the coder keeps failing, move **working** up to the thinking model.
   - If merge policy (question 1) is `agent`, keep delivery on the **working** model, since it checks the merge conditions.

   Record exact model IDs, or `inherit`, in `models.thinking`, `models.working`, and `models.light`. `models.escalation` is the tier a stuck task is retried on once (default `thinking`; `none` turns it off).
3. **Forbidden commands.** Suggest a list from the stack (for example app builds, device installs, deploys, database resets) plus anything in existing rules. They confirm or edit.
4. **Integration branch**, only if step 1 found none or found several.
5. **Project rules**, only if no existing instruction file has them: "What must agents never break in this project? For example: 'all data stays on the device'." Collect them as one line each.
6. **Code standard.** Show the layer table, naming rules, and error style you detected for `docs/clean-code.md` and `AGENTS.md` section 5, plus the default limits (functions about 40 lines or fewer, nesting 3 levels or fewer, 4 parameters or fewer). "Is this how code here should look? Change anything you want stricter or looser." Ask the comment policy only if step 1 couldn't tell.
7. **Size limits.** "Issues are kept to about 400 changed lines and 8 files, and tasks to 3 files, so each PR can be reviewed properly. Changes of one behavior and up to 50 lines take a shorter small lane. Keep these defaults?" Record them in `limits`.
   If the repo isn't format-clean (step 1) and the formatter can't take file paths, say so here: suggest the user formats the whole repo once in their own commit before the first run.
8. **Rules check.** Using [skills/rules-check/SKILL.md](skills/rules-check/SKILL.md), propose which standard rules a tool or script will enforce, including any package it needs. The user picks which to turn on.
9. **Existing work tracking**, only if step 1 found ticket or sprint files: "Should I move the open tickets into issues and milestones now, later, or not at all?"

## 4. Preview

Build the full change list and show it, then wait for a yes:

- Every file to create, with its path.
- Every existing file to change, with a diff (`AGENTS.md` merges are always shown in full).
- Existing agent files the adapter would replace, listed with what replaces each.
- Labels to create (from [tracker/github.md](tracker/github.md)).
- The rules check: each rule, the tool or script, any package to add, and how many places in the current code already break it.
- What stays untouched, and anything unknown you'll leave alone (unknown tooling, scripts, plugins: list them so the user can decide later).

## 5. Write

1. **Rules.** Write `AGENTS.md` from [templates/AGENTS.md](templates/AGENTS.md), filled in with the detected and answered values. If one exists, merge: keep every existing rule, map it into the template's sections, and drop only what the kit now covers (status templates, file-based ticket flow), as shown in the preview.
2. **Docs.** For each of `docs/testing.md`, `docs/patterns.md`, `docs/clean-code.md`: if the project has an equivalent, keep it, point to it from `AGENTS.md`, and show the user which sections of the kit's template it lacks (offer to add them). Otherwise write the template, filled in from the real repo and the step 3 answers (a real pattern file per row, the real test runner, the real layer table). Leave out rows you can't fill; never leave `<placeholder>` text behind.
3. **Rules check.** Set up the rules the user picked in step 3.8 with [skills/rules-check/SKILL.md](skills/rules-check/SKILL.md), set `commands.rules`, and mark those rows **(checked)** in `docs/clean-code.md`.
4. **Agents, models, skills.** Follow the chosen adapter file in `adapters/` exactly. It turns `roles/`, the model answers, and `skills/` into the tool's own files. The kit writes no permission rules or hooks; [safety/baseline.md](safety/baseline.md) and `forbiddenCommands` are rules the agents follow.
5. **Tracker.** Run ensure-labels for every label in [tracker/github.md](tracker/github.md).
6. **Lock file.** Write `.agentkit/lock.json` from [templates/lock.json](templates/lock.json), with `tracker.agentLogin` from step 1 (and `tracker.reviewerLogin` the same unless the user set up a separate reviewer account). Add `.agentkit/evidence/` to `.gitignore`. Fill `installedFiles` with every file you created or changed, each with the sha256 of the content you wrote (`sha256sum <file>`). `UPDATE.md` uses these hashes to tell your files apart from the user's later edits.
7. **Migration**, if the user said "now" in step 3.9: for each open ticket file, create an issue from [templates/issue.md](templates/issue.md) under a milestone named after its sprint, then show the user the mapping. Don't delete the old files; tell the user they are no longer used.

Commit nothing unless the user asks. If they do, put it on a branch (`chore/agentic-workflow-kit-setup`) and open a PR into the integration branch.

## 6. Verify

Run each check and report one line per row:

| Check | How |
|---|---|
| Files exist | Every path in `installedFiles` |
| Tool loads the config | The adapter's own check |
| Check command runs | Run it once and report the real result (a failing project is reported, not fixed) |
| Rules check runs | Run `commands.rules` once, if set; report the count of findings per rule |
| Labels exist | `gh label list --search "status:"` |
| Roles reachable | The adapter's role list check |
| No leftover placeholders | `grep -rnE '<[^!/ >][^>]*>' AGENTS.md docs/ .agentkit/lock.json` shows nothing except real markup |

## 7. Next steps

Offer, in this order:

1. Create the `verify-<project>` skill now ([skills/verify/SKILL.md](skills/verify/SKILL.md)). Recommended before the first run.
2. Plan the project ([skills/plan-project/SKILL.md](skills/plan-project/SKILL.md)) if there's no PRD issue yet.
3. Run an issue or a sprint: "paste an issue" or "run sprint <name>".
