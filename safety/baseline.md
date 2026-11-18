# Safety baseline

Every project that uses the kit gets these rules. Project rules in `AGENTS.md` and `forbiddenCommands` in `.agentkit/lock.json` add to them and never weaken them. The adapter for your tool turns this file into permission settings once, at the project level, not copied into each agent.

## Never, for any role

| Category | Forbidden |
|---|---|
| History | `git push --force`, `git push -f`, `git rebase`, `git commit --amend` on a pushed commit, `git filter-branch` |
| Discarding work | `git reset`, `git stash`, `git clean`, `git checkout -- <path>`, `git restore` on files the agent didn't create in this run |
| Deletion | `git branch -D`, `git push --delete`, `gh repo delete`, `gh api ... -X DELETE`, `rm -rf` |
| Machine | `sudo`, changing global config, `curl`/`wget` piped into a shell |
| Secrets | Reading or editing `.env*`, key files, or credential stores; printing tokens |
| Dependencies | Adding, removing, or upgrading packages, unless a plan step names the exact package and version |
| Tracker | Closing issues by hand (see the one exception in [tracker/github.md](../tracker/github.md)), deleting comments, editing other people's comments, changing repository settings |
| Merging | Merging into the integration branch unless the lock file says `"merge": "agent"` and every merge condition holds |
| Project | Anything in the project's `forbiddenCommands` |

Merging an approved issue PR into its sprint branch during `run-sprint` is always allowed.

## Merge conditions (integration branch)

All of these must hold, checked right before merging:

1. An approval review exists from the pr-reviewer (or a review comment marked approved, see [tracker/github.md](../tracker/github.md)) on the current head commit.
2. CI is green, or the repo has no CI and the PR body holds a passing check-command result for the current head commit.
3. The PR body has an evidence section with real output, not a description of what should happen.
4. No `status:needs-input` or `status:blocked` label on the PR or its issues.

If any one fails, report which and stop.

## Role permissions

| Role | Read code | Edit app code | Edit tests | Run commands | Tracker writes | Git writes |
|---|---|---|---|---|---|---|
| planner | yes | no | no | read-only commands | plan comment, labels, questions | no |
| scout | yes | no | no | read-only commands | no | no |
| test-writer | yes | no | yes | test command | no | no |
| coder | yes | yes | no | all allowed project commands | no | no |
| checker | yes | no | no | check, format, test | no | no |
| verifier | yes | no | no | verify skill commands | evidence comment | no |
| delivery | yes | no | no | git, `gh` | PRs, labels, PR body | branch, commit, push, merge (per policy) |
| pr-reviewer | yes | no | no | read-only commands, tests | PR review only | no |

"Read-only commands" means commands that change nothing: `git log`, `git diff`, `git status`, `gh issue view`, `gh pr view`, `gh pr diff`, `ls`, `grep`.

## Limits

- **Same error, retried:** a worker stops after the number in `limits.sameErrorRetries` (default 8) and returns each attempt in one line.
- **Steps:** each worker runs with the step limit its tool supports (default 60). Hitting it means stop and summarize.
- **Scope:** a worker never edits a file that isn't on the plan's file list. Needing one is a stop condition, not a judgment call.

## When unsure

Stop and ask. A paused run costs minutes; an unwanted force push, merge, or deleted file can cost the user their work.
