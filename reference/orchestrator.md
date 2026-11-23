# Running the kit unattended

The kit does one unit of work per session and then stops. Something outside the kit (a scheduler, a CI job, another agent, a shell loop) starts those sessions. That outside runner owns the schedule, budgets, notifications, and the machine. This page is its contract.

## The loop

```bash
while true; do
  <kit>/scripts/agentkit status            # optional: JSON summary, no model tokens
  <harness> "<invoke the agentkit-next skill>"   # one fresh session, see your adapter
  # read the last line starting with AGENTKIT_RESULT, or .agentkit/last-result.json
  # decide: run again now, wait, or notify the user
done
```

Start a **new** session every time. Never resume one; the tracker and the branch hold all state.

## Outcomes

Every `agentkit-next` session ends with one line printed by `agentkit result`:

```
AGENTKIT_RESULT {"outcome":"merged","issue":12,"note":"","at":"20261123T101500Z"}
```

The script checks the outcome against the tracker before printing it, so a session can't report "merged" for an issue that isn't. The same line is written to `.agentkit/last-result.json` and `.agentkit/runs/<time>.json`.

| Outcome | Meaning | Suggested runner action |
|---|---|---|
| `merged` | An issue was merged into its sprint branch, or a wrap-up phase finished | Run again |
| `continue` | Checkpoint mid-issue (`limits.tasksPerSession`), an issue was split into parts, or CI still running on a PR | Run again (wait a few minutes if CI is slow) |
| `blocked` | The issue can't go on safely (`status:blocked`); `note` holds the reason, for example a missing secret | Run again (other issues go on). Fix the cause yourself if you can, or notify the user, then `agentkit unblock <N>` |
| `milestone-complete` | Wrap-up done; the sprint PR is ready for the user | Notify the user to review and merge it |
| `awaiting-merge` | The sprint PR is still waiting for the user | Wait (for example an hour), then run again |
| `idle` | Nothing ready: every remaining issue is blocked, or no open milestone | Fix the blocks, or wait; then run again |
| `paused` | An open issue is labelled `agentkit:pause`, or `.agentkit/PAUSE` exists | Wait |
| `error` | Preflight failed (including `locked` by another runner), a script failed, or the claimed outcome didn't match the tracker | Notify; back off. **No result line at all also means `error`** |

## Requirements for the runner

1. **One runner per repository.** `agentkit preflight` takes `.agentkit/runner.lock` and refuses a second runner. A stale lock (older than `limits.lockMinutes`, default 240) is replaced.
2. **A dedicated checkout.** Don't let a person edit the same working tree. A crashed session's leftovers are rescued into a WIP commit by the next session, which only works if nobody else is editing.
3. **Credentials.** `gh auth status` must pass. If `tracker.reviewerLogin` differs from `tracker.agentLogin`, also provide that account's token as `AGENTKIT_REVIEWER_TOKEN`; reviews are posted with it. The token needs to read and write issues, pull requests, labels, milestones, and contents for this one repository, and nothing more: no admin, no other repositories.
4. **A permission profile.** Headless sessions either stop on permission prompts or run with everything allowed. Apply the "Unattended permission profile" from your adapter so the most dangerous commands are refused by the harness itself.
5. **Isolation.** Run in a container or VM that holds only this checkout and these credentials. No host home directory, no other keys.
6. **Branch protection.** Protect the integration and default branches (no direct pushes, required checks). The M0 verify issue reminds the user.
7. **Budgets.** Spend, time, and how often to run are yours. The kit limits work per issue (sessions, rounds); it can't see your bill.

## Pausing

Open any issue and label it `agentkit:pause` (works from a phone), or create `.agentkit/PAUSE` in the checkout. Every session returns `paused` until the issue is closed or the file is removed. A session already running finishes its current step first.

## No questions, no waiting

The loop never asks a person and never waits for a reply. When an issue leaves something open, the agent finds the answer in the docs and code, or decides and records the assumption; see "Deciding without a person" in [safety.md](safety.md). Every assumption is listed in the sprint PR, so you review them all when you merge the sprint.

Only an issue with no safe way on is blocked. You hear about it through the `blocked` result and its `note`, not through a comment. Fix the cause (add the secret, change a doc, raise a limit), then:

```bash
<kit>/scripts/agentkit unblock <N>
```

The issue is ready again with a fresh session count. Blocked issues that are still blocked when you merge the sprint PR move to the next milestone.
