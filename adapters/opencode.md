# Adapter: opencode

Written against opencode's skills and agents folders. Before writing, run `opencode --version` and check the installed version's docs (https://opencode.ai/docs) for skills, agents, and permissions. If they differ, follow the installed version and tell the user what you adapted.

## Install

Clone the kit once, anywhere outside your projects, and link its skills into opencode's global skills folder:

```bash
git clone https://github.com/wise-394/agentic-workflow-kit ~/.local/share/agentkit
mkdir -p ~/.config/opencode/skills
for s in ~/.local/share/agentkit/skills/agentkit-*; do ln -sfn "$s" ~/.config/opencode/skills/; done
```

Updating the kit is `git -C ~/.local/share/agentkit pull`; then run agentkit-setup again in each project to reconcile it. `<kit>` is the folder two levels above a skill's real path, so the links resolve to the clone.

## How the planner runs

The session that loads agentkit-run-issue, agentkit-run-sprint, or agentkit-next is the planner; it starts the roles as subagents. Don't make the planner opencode's default agent, and don't mention it in `AGENTS.md`: ordinary sessions stay ordinary.

## Files setup writes in the project

| File | Content |
|---|---|
| `AGENTS.md` | opencode reads it automatically |
| `.opencode/agents/agentkit-<role>.md` for scout, test-writer, coder, verifier, pr-reviewer | A thin subagent that pins the role's model |
| `.opencode/agents/agentkit-test-writer-escalated.md`, `agentkit-coder-escalated.md` | The same, on the `thinking` model, for the one escalation retry. Leave out if `models.escalation = none` |
| `opencode.json` permission block | Only if the user said yes to the unattended permission profile |

Thin agent file:

```markdown
---
description: The agentic workflow kit's <role>. Started only by the kit's run-issue and run-sprint skills.
mode: subagent
model: <provider/model for the role's tier; omit for inherit>
---

You are a worker in the agentic workflow kit. Your caller gives you the path of your role file. Read it first and follow it exactly.
```

Suggested models: for each tier, pick from the providers the user has configured (`opencode models`): the strongest for **thinking**, a mid-tier one for **working**. Never write API keys into any file; suggest `{env:…}` if a provider config holds a plain key.

## Unattended runs

```bash
opencode run "Use the agentkit-next skill."
```

If the installed version can't start subagents in `run` mode, the planner starts each role with its own `opencode run "<role prompt>"` instead: a separate process is just as fresh.

## Unattended permission profile

Added to `opencode.json` only when the user says yes in setup:

```jsonc
{
  "permission": {
    "edit": "allow",
    "bash": {
      "*": "allow",
      "git push --force*": "deny", "git push -f*": "deny", "git push --delete*": "deny",
      "git rebase*": "deny", "git reset*": "deny", "git stash*": "deny", "git clean*": "deny",
      "git checkout -- *": "deny", "git config --global*": "deny", "git filter-branch*": "deny",
      "rm -rf*": "deny", "sudo*": "deny",
      "gh pr merge*": "deny", "gh repo delete*": "deny", "gh issue close*": "deny",
      "<each command from [forbidden]>": "deny"
    }
  }
}
```

Secrets (`.env*`, keys) can't be denied by path here in every version. Keep them out of the runner's checkout, and rely on the safety baseline.

## Check after setup

- Starting `opencode` shows the five `agentkit-*` subagents, and the default agent is unchanged.
- `opencode run "Use the agentkit-next skill."` in a test repository prints an `AGENTKIT_RESULT` line.
