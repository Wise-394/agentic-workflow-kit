# Setup

You are an agent setting up this kit in the user's project. Follow the steps in order. Don't write anything into the project before step 4's preview is approved.

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
| Commands | The scripts those files define: one command that runs everything (check), one for a single test file (test), and a formatter (format) |
| Git | `git remote -v`; the default branch (default-branch in [tracker/github.md](tracker/github.md)); the integration branch (where recent PRs merged: `gh pr list --state merged --limit 20 --json baseRefName`); branch naming (`git branch -r`) |
| Tracker | `gh auth status`; the repo name from `gh repo view --json nameWithOwner` |
| Existing rules | Hard rules, invariants, and forbidden commands in existing instruction files |
| Existing work tracking | Sprint, ticket, or status files in the repo |
| Docs | Existing testing, pattern, style, and copy docs |

## 2. Confirm

Show the user everything you found in one message, as a table: what, value, source. Ask them to correct anything wrong. If `gh` isn't logged in, or no check command exists, say so and ask how they want to continue.

## 3. Ask

Only what step 1 couldn't answer, one question at a time:

1. **Models.** "Which model should do the *thinking* work: planning and reviewing? Which should do the *working* steps: scouting, writing tests, coding, running checks, verifying, git? You can say 'same as now' for either." Show the role list from `roles/` so they can see the groups. Record exact model IDs, or `inherit`.
2. **Forbidden commands.** Suggest a list from the stack (for example app builds, device installs, deploys, database resets) plus anything in existing rules. They confirm or edit.
3. **Merge policy.** "When a PR into `<integration branch>` is approved and verified, who merges: you or the agent?" Record `user` or `agent`.
4. **Integration branch**, only if step 1 found none or found several.
5. **Project rules**, only if no existing instruction file has them: "What must agents never break in this project? For example: 'all data stays on the device'." Collect them as one line each.
6. **Existing work tracking**, only if step 1 found ticket or sprint files: "Should I move the open tickets into issues and milestones now, later, or not at all?"

## 4. Preview

Build the full change list and show it, then wait for a yes:

- Every file to create, with its path.
- Every existing file to change, with a diff (`AGENTS.md` merges are always shown in full).
- Existing agent files the adapter would replace, listed with what replaces each.
- Labels to create (from [tracker/github.md](tracker/github.md)).
- What stays untouched, and anything unknown you'll leave alone (unknown tooling, scripts, plugins: list them so the user can decide later).

## 5. Write

1. **Rules.** Write `AGENTS.md` from [templates/AGENTS.md](templates/AGENTS.md), filled in with the detected and answered values. If one exists, merge: keep every existing rule, map it into the template's sections, and drop only what the kit now covers (status templates, file-based ticket flow), as shown in the preview.
2. **Docs.** For each of `docs/testing.md`, `docs/patterns.md`, `docs/clean-code.md`: if the project has an equivalent, keep it and point to it from `AGENTS.md`. Otherwise write the template, filled in from the real repo (a real pattern file per row, the real test runner). Leave out rows you can't fill; never leave `<placeholder>` text behind.
3. **Agents, models, permissions, skills.** Follow the chosen adapter file in `adapters/` exactly. It turns `roles/`, the model answers, [safety/baseline.md](safety/baseline.md) plus `forbiddenCommands`, and `skills/` into the tool's own files.
4. **Tracker.** Run ensure-labels for every label in [tracker/github.md](tracker/github.md).
5. **Lock file.** Write `.agentkit/lock.json` from [templates/lock.json](templates/lock.json). Fill `installedFiles` with every file you created or changed, each with the sha256 of the content you wrote (`sha256sum <file>`). `UPDATE.md` uses these hashes to tell your files apart from the user's later edits.
6. **Migration**, if the user said "now" in step 3.6: for each open ticket file, create an issue from [templates/issue.md](templates/issue.md) under a milestone named after its sprint, then show the user the mapping. Don't delete the old files; tell the user they are no longer used.

Commit nothing unless the user asks. If they do, put it on a branch (`chore/agentic-workflow-kit-setup`) and open a PR into the integration branch.

## 6. Verify

Run each check and report one line per row:

| Check | How |
|---|---|
| Files exist | Every path in `installedFiles` |
| Tool loads the config | The adapter's own check |
| Check command runs | Run it once and report the real result (a failing project is reported, not fixed) |
| Labels exist | `gh label list --search "status:"` |
| Roles reachable | The adapter's role list check |
| No leftover placeholders | `grep -rn "<[a-z-]*>" AGENTS.md docs/ .agentkit/` shows nothing unexpected |

## 7. Next steps

Offer, in this order:

1. Create the `verify-<project>` skill now ([skills/verify/SKILL.md](skills/verify/SKILL.md)). Recommended before the first run.
2. Plan the project ([skills/plan-project/SKILL.md](skills/plan-project/SKILL.md)) if there's no PRD issue yet.
3. Run an issue or a sprint: "paste an issue" or "run sprint <name>".
