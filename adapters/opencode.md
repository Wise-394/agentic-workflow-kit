# Adapter: opencode

How to turn the kit's generic parts into opencode files. Written against the opencode config format that uses an ordered `permissions` list (`action` / `resource` / `effect`, last match wins), an `agents` map, and `provider/model#variant` model IDs. Before writing, run `opencode --version` and check the config schema at https://opencode.ai/config.json. If the installed version uses a different format (for example an older `permission` object), follow the installed version's docs and tell the user what you adapted.

## Files written

| Kit source | Project file |
|---|---|
| `roles/planner.md` | `.opencode/agents/planner.md` (`mode: primary`) |
| other `roles/*.md` | `.opencode/agents/<role>.md` (`mode: subagent`) |
| models, shared permissions, default agent | `opencode.json` |
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
permissions:
  <only this role's rules, see below>
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
    "scout":       { "model": "<working model>", "steps": 60 },
    "test-writer": { "model": "<working model>", "steps": 60 },
    "coder":       { "model": "<working model>", "steps": 60 },
    "checker":     { "model": "<working model>", "steps": 60 },
    "verifier":    { "model": "<working model>", "steps": 60 },
    "delivery":    { "model": "<working model>", "steps": 60 }
  },
  "permissions": [ "<shared rules, see below>" ]
}
```

- A model answer of `inherit` means: leave out `model` for that agent. A subagent with no model uses its parent's.
- If the user would rather keep model IDs out of the repo, write `"{env:AGENTKIT_THINKING_MODEL}"` and `"{env:AGENTKIT_WORKING_MODEL}"` and tell them to set those variables. opencode substitutes `{env:…}` in config strings.
- `steps` comes from `limits.workerSteps` in the lock file.
- Never write API keys into any config. If the user's provider config holds a plain key, suggest moving it to `{env:…}`.

## Permissions

**Shared rules** go once in `opencode.json`. Start with `{ "action": "*", "resource": "*", "effect": "allow" }`, then one `deny` per baseline item and per `forbiddenCommands` entry:

| Baseline item | Rules |
|---|---|
| History | `shell` deny `git push --force*`, `git push -f*`, `git rebase*`, `git filter-branch*` |
| Discarding work | `shell` deny `git reset*`, `git stash*`, `git clean*`, `git checkout -- *`, `git restore*` |
| Deletion | `shell` deny `git branch -D*`, `git push --delete*`, `gh repo delete*`, `*gh api*-X DELETE*`, `rm -rf*` |
| Machine | `shell` deny `sudo *`, `*curl * \| *sh*`, `*wget * \| *sh*` |
| Secrets | `read` and `edit` deny `.env*`, `**/.env*`, `**/*.pem`, `**/*.key` |
| Dependencies | `shell` deny the package manager's add, install, remove, upgrade forms (for example `npm install*`, `npm i *`, `npm uninstall*`, `npm update*`) |
| Tracker | `shell` deny `gh issue delete*`, `gh repo edit*`, `gh pr merge*` (delivery re-allows merge) |
| Project | `shell` deny each `forbiddenCommands` entry followed by `*` |

**Role rules** go in each agent's frontmatter. Agent rules apply after the shared ones, so they can tighten or re-allow:

| Role | Rules |
|---|---|
| planner | `edit` deny `*`; `subagent` deny `*`, then allow each of the seven other roles |
| scout, pr-reviewer | `edit` deny `*`; `shell` deny `git push*`, `git commit*`, `git switch*`, `git checkout*`, `gh issue edit*`, `gh issue comment*` (pr-reviewer re-allows `gh pr review*` and `gh api*pulls*comments*`) |
| test-writer | `edit` deny `*`, then allow the test folders and test file patterns from `docs/testing.md` |
| coder | `edit` deny the test folders and patterns, `.agentkit/**`, `.opencode/**`, `AGENTS.md`, package manifests and lock files; `shell` deny `git *` except `git status*`, `git diff*`, `git log*`, `git rm src/*` |
| checker, verifier | `edit` deny `*` (the checker's format command still runs as a shell command) |
| delivery | `edit` deny `*`; `shell` allow `gh pr merge*` |

## Check after writing

- Start `opencode` in the project. The planner is the default agent and the other seven appear as subagents.
- Ask the planner to list the subagents it can call. It should list exactly the seven.
- Ask the scout to create a file. It should be refused.
