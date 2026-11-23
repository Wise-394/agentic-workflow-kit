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
| `continue` | Checkpoint mid-issue (`limits.tasksPerSession`), or CI still running on a PR | Run again (wait a few minutes if CI is slow) |
| `parked` | A question waits on the issue (`status:needs-input`) | Notify the user; run again (other issues may be ready) |
| `blocked` | A limit was hit (`status:blocked`) | Notify the user; run again |
| `milestone-complete` | Wrap-up done; the sprint PR is ready for the user | Notify the user to review and merge it |
| `awaiting-merge` | The sprint PR is still waiting for the user | Wait (for example an hour), then run again |
| `idle` | Nothing ready: all remaining issues wait for answers, or no open milestone | Wait, then run again |
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

## Answering questions

Parked issues carry a comment starting with `<!-- agentkit:question -->`. Reply in a normal comment on that issue. The next session's housekeeping sees a trusted reply newer than the question, clears the label, and the issue becomes ready again.
