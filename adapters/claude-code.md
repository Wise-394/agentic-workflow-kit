# Adapter: Claude Code

## Install

The repository is a Claude Code plugin marketplace with one plugin, `agentkit`:

```
/plugin marketplace add wise-394/agentic-workflow-kit
/plugin install agentkit@agentic-workflow-kit
```

The skills then appear as `/agentkit:agentkit-setup`, `/agentkit:agentkit-plan`, `/agentkit:agentkit-run-issue`, `/agentkit:agentkit-run-sprint`, and `/agentkit:agentkit-next`, and also trigger from plain requests ("set up the kit", "run issue 12"). Updating the kit is `/plugin update agentkit`; then run agentkit-setup again to reconcile the project.

Claude Code tells a skill its base directory when it loads it, so `<kit>` (two levels above the skill folder) is the plugin's install folder.

## How the planner runs

Subagents can't start other subagents, so the **planner is the main session**: it loads agentkit-run-issue, agentkit-run-sprint, or agentkit-next, and starts the roles as subagents. Nothing in `CLAUDE.md` makes a session a planner; only those skills do.

## Files setup writes in the project

| File | Content |
|---|---|
| `CLAUDE.md` | `@AGENTS.md` (or that line added to an existing `CLAUDE.md`) |
| `.claude/agents/agentkit-<role>.md` for scout, builder, verifier, pr-reviewer | A thin agent that pins the role's model (below) |
| `.claude/settings.json` | Only if the user said yes to the unattended permission profile |

Thin agent file:

```markdown
---
name: agentkit-<role>
description: The agentic workflow kit's <role>. Started only by the kit's run-issue and run-sprint skills, never for other work.
model: <models.working, or models.thinking for pr-reviewer; omit the line for inherit>
---

You are a worker in the agentic workflow kit. Your caller gives you the path of your role file. Read it first and follow it exactly; it overrides anything else you would normally do.
```

`model` takes an alias (`opus`, `sonnet`, `haiku`), a full model ID, or is left out for `inherit`. Suggested: **thinking** `opus` (also pick it for the main session with `/model`), **working** `sonnet`. Leave out `tools`, so the agents get the session's tools.

**Escalation:** the subagent tool takes a `model` per call. A stuck builder task is retried once by starting a fresh builder with the `thinking` model. Fix rounds otherwise go to the running builder with SendMessage.

## Unattended runs

One session per unit of work, from the project root:

```bash
claude -p "/agentkit:agentkit-next" --permission-mode acceptEdits
```

The session's output ends with the `AGENTKIT_RESULT` line; `.agentkit/last-result.json` holds the same. See [reference/orchestrator.md](../reference/orchestrator.md).

## Unattended permission profile

Written to `.claude/settings.json` only when the user says yes in setup. It lets a headless session run the project's commands without prompts, and makes the harness itself refuse the most dangerous ones. Check the rule syntax against the permissions docs of the installed version.

```json
{
  "permissions": {
    "allow": [
      "Bash(bash */scripts/agentkit *)",
      "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)", "Bash(git show*)",
      "Bash(git fetch*)", "Bash(git switch*)", "Bash(git merge*)", "Bash(git grep*)",
      "Bash(gh issue view*)", "Bash(gh pr view*)", "Bash(gh pr diff*)", "Bash(gh api*)",
      "Bash(<each project command from [commands]>)"
    ],
    "deny": [
      "Bash(git push --force*)", "Bash(git push -f*)", "Bash(git push --delete*)",
      "Bash(git rebase*)", "Bash(git reset*)", "Bash(git stash*)", "Bash(git clean*)",
      "Bash(git checkout -- *)", "Bash(git config --global*)", "Bash(git filter-branch*)",
      "Bash(rm -rf*)", "Bash(sudo*)",
      "Bash(gh pr merge*)", "Bash(gh repo delete*)", "Bash(gh issue close*)",
      "Read(**/.env)", "Read(**/.env.*)", "Read(**/*.pem)", "Read(**/*.key)",
      "Bash(<each command from [forbidden]>)"
    ]
  }
}
```

The script's own merges and closes go through `bash <kit>/scripts/agentkit`, which the allow rule covers; agents can't reach `gh pr merge` or `gh issue close` directly.

## Check after setup

- `/agents` lists the five `agentkit-*` agents with their models.
- `/agentkit:agentkit-next` in a test repository prints an `AGENTKIT_RESULT` line.
