# Acceptance run

The offline tests cover the script. This run proves the whole kit with a real agent, on a throwaway repository you own. Never run it in a real project.

## Setup

```bash
cp -r tests/sandbox <temp>/kit-sandbox && cd <temp>/kit-sandbox
git init -b main && git add . && git commit -m "chore: sandbox"
gh repo create kit-sandbox --private --source . --push
```

Install the kit in your tool (see `adapters/`), open the sandbox, and ask the agent to set up the agentic workflow kit.

## The run

| # | Do | Expect |
|---|---|---|
| 1 | Setup: answer the questions; pick `kit` for every slot | `.agentkit/config`, labels, adapter files, nothing else |
| 2 | `agentkit-plan`: plan "add `average(numbers)`, 0 for an empty list" and "`sum` should accept numeric strings" | `docs/prd.md`, `docs/design.md`, milestones `M0` and `M1`, issues with acceptance tests, a verify issue per milestone |
| 3 | Run `agentkit-next` repeatedly through M0 | Each session ends with an `AGENTKIT_RESULT` line; M0 issues merge into `sprint/m0`; wrap-up marks the sprint PR ready; then `awaiting-merge` |
| 4 | Merge the M0 sprint PR yourself, run `agentkit-next` | Housekeeping closes the M0 issues and milestone; M1 starts |
| 5 | Mid-issue, kill the session (Ctrl-C while the coder is working), run `agentkit-next` | `rescue` makes a WIP commit, the issue resumes, no task is redone |
| 6 | Make one M1 issue vague (remove its acceptance tests, keep its requirement IDs); make another need a secret the runner doesn't have | The vague one is built, with its acceptance tests written from the PRD and listed under **Assumptions**. The other ends `blocked` with the reason in the result `note`; other issues continue. No question comments anywhere |
| 7 | Add the secret, run `agentkit unblock <N>` | The next session builds it |
| 8 | Label any issue `agentkit:pause` | `paused` until you remove the label |
| 9 | Finish M1 and merge its sprint PR | All M1 issues closed, milestone closed, a `Retro M1` issue with proposals |
| 10 | Run `agentkit-run-issue #N --plan-only` on a new issue, then `agentkit-run-issue #N` | The plan is posted and nothing is built; the second run resumes from the plan and builds it |

Any step that doesn't behave as written is a kit bug: file it with the session's output and `.agentkit/runs/`.
