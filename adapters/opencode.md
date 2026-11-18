# Adapter: opencode

How to turn the kit's generic parts into opencode files. Written against the opencode config format that uses an `agents` map and `provider/model#variant` model IDs. Before writing, run `opencode --version` and check the config schema at https://opencode.ai/config.json. If the installed version uses a different format, follow the installed version's docs and tell the user what you adapted.

## Files written

| Kit source | Project file |
|---|---|
| `roles/planner.md` | `.opencode/agents/planner.md` (`mode: primary`) |
| other `roles/*.md` | `.opencode/agents/<role>.md` (`mode: subagent`) |
| models, default agent | `opencode.json` |
| `skills/*` | `.opencode/skills/<name>/` (copied as they are, including the playbook files) |
| the project's verify skill | `.opencode/skills/verify-<project>/SKILL.md` |
| `AGENTS.md` | project root (opencode reads it automatically) |

Kit files that skills and roles link to (`tracker/github.md`, `safety/baseline.md`, `templates/*`) are copied into `.agentkit/kit/` keeping their paths, and the links in the copied roles and skills are rewritten to point there.

## Agent files

Each agent file has frontmatter, then the role file's body as its prompt.

```markdown
---
description: <the role's Purpose, one sentence>
mode: subagent
---

<body of roles/<role>.md, links rewritten>
```

Don't put `model` in agent frontmatter. Models go in `opencode.json`, so changing a model is a one-line edit.

## opencode.json

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "planner",
  "agents": {
    "planner":     { "model": "<thinking model>" },
    "pr-reviewer": { "model": "<thinking model>" },
    "scout":       { "model": "<light model>", "steps": 60 },
    "test-writer": { "model": "<working model>", "steps": 60 },
    "coder":       { "model": "<working model>", "steps": 60 },
    "checker":     { "model": "<light model>", "steps": 60 },
    "verifier":    { "model": "<working model>", "steps": 60 },
    "delivery":    { "model": "<light model, or working if merge is agent>", "steps": 60 },
    "test-writer-escalated": { "model": "<escalation tier model>", "steps": 60 },
    "coder-escalated":       { "model": "<escalation tier model>", "steps": 60 }
  }
}
```

- A model answer of `inherit` means: leave out `model` for that agent. A subagent with no model uses its parent's.
- If the user would rather keep model IDs out of the repo, write `"{env:AGENTKIT_THINKING_MODEL}"`, `"{env:AGENTKIT_WORKING_MODEL}"`, and `"{env:AGENTKIT_LIGHT_MODEL}"` and tell them to set those variables. opencode substitutes `{env:…}` in config strings.
- `steps` comes from `limits.workerSteps` in the lock file.
- Typical suggestion for setup's model question (only a suggestion; setup always asks and writes what the user chooses): for each tier, pick from the providers the user has configured (`opencode models` lists them): the provider's strongest model for **thinking**, its mid-tier model for **working**, and its small, fast model for **light**. A model with reasoning variants can use a higher `#variant` for thinking and a lower one for the others.
- Escalation: opencode fixes each agent's model in config, so add two more subagents, `test-writer-escalated` and `coder-escalated`, each with its base role's prompt and the `models.escalation` tier's model. The planner may call one of them once for a stuck task. Leave them out if `models.escalation` is `none`.
- Never write API keys into any config. If the user's provider config holds a plain key, suggest moving it to `{env:…}`.

## Permissions

The kit writes no permission rules: no shared rules in `opencode.json` and none in agent frontmatter. Agents run with opencode's own permissions, and each role's limits are the written rules in its role file and in the safety baseline. Leave any existing permission config untouched.

## Check after writing

- Start `opencode` in the project. The planner is the default agent and the other seven (plus the escalated ones) appear as subagents.
- Ask the planner to list the subagents it can call. It should list exactly those.
