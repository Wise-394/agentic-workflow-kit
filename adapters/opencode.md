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
    "scout":       { "model": "<light model>", "steps": 60 },
    "test-writer": { "model": "<working model>", "steps": 60 },
    "coder":       { "model": "<working model>", "steps": 60 },
    "checker":     { "model": "<light model>", "steps": 60 },
    "verifier":    { "model": "<working model>", "steps": 60 },
    "delivery":    { "model": "<light model, or working if merge is agent>", "steps": 60 },
    "test-writer-escalated": { "model": "<escalation tier model>", "steps": 60 },
    "coder-escalated":       { "model": "<escalation tier model>", "steps": 60 }
  },
  "permissions": [ "<shared rules, see below>" ]
}
```

- A model answer of `inherit` means: leave out `model` for that agent. A subagent with no model uses its parent's.
- If the user would rather keep model IDs out of the repo, write `"{env:AGENTKIT_THINKING_MODEL}"`, `"{env:AGENTKIT_WORKING_MODEL}"`, and `"{env:AGENTKIT_LIGHT_MODEL}"` and tell them to set those variables. opencode substitutes `{env:…}` in config strings.
- `steps` comes from `limits.workerSteps` in the lock file.
- Typical suggestion for setup's model question (only a suggestion; setup always asks and writes what the user chooses): for each tier, pick from the providers the user has configured (`opencode models` lists them): the provider's strongest model for **thinking**, its mid-tier model for **working**, and its small, fast model for **light**. A model with reasoning variants can use a higher `#variant` for thinking and a lower one for the others.
- Escalation: opencode fixes each agent's model in config, so add two more subagents, `test-writer-escalated` and `coder-escalated`, each with its base role's prompt and permissions and the `models.escalation` tier's model. The planner may call one of them once for a stuck task (allow both in the planner's `subagent` rules). Leave them out if `models.escalation` is `none`.
- Never write API keys into any config. If the user's provider config holds a plain key, suggest moving it to `{env:…}`.

## Permissions

**Shared rules** go once in `opencode.json`. Start with `{ "action": "*", "resource": "*", "effect": "allow" }`, then one `deny` per baseline item and per `forbiddenCommands` entry:

| Baseline item | Rules |
|---|---|
| History | `shell` deny `git push --force*`, `git push -f*`, `git push*--force*`, `git push* +*`, `git rebase*`, `git filter-branch*` |
| Protected branches | `shell` deny `git push* <integrationBranch>`, `git push*:<integrationBranch>*`, `git push*/<integrationBranch>*`, and the same three for `<defaultBranch>` |
| Discarding work | `shell` deny `git reset*`, `git stash*`, `git clean*`, `git checkout -- *`, `git checkout -f*`, `git switch -f*`, `git switch --discard-changes*`, `git restore*` |
| Deletion | `shell` deny `git branch -D*`, `git push --delete*`, `git push* :*`, `gh repo delete*`, `*gh api*DELETE*`, `rm -rf*`, `rm -fr*`, `rm -r -f*`, `rm -f -r*`, `rm --recursive*` |
| Bypassing review | `shell` deny `*gh pr merge*--admin*`, `*gh api*merge*`, `*gh api*git/refs*`, `*gh api*branches*`, `*gh api*protection*` (the kit's own `gh api` calls never touch these paths) |
| Machine | `shell` deny `sudo *`, `git config --global*`, `*curl * \| *sh*`, `*wget * \| *sh*`, `pnpm dlx*`, `yarn dlx*`, `uvx *`, `pipx run*`, and `npx *` (allow back the exact `npx <installed tool>` forms the project's scripts use) |
| Secrets | `read` and `edit` deny `.env*`, `**/.env*`, `**/*.pem`, `**/*.key` |
| Dependencies | `shell` deny the package manager's add, install, remove, upgrade forms (for example `npm install*`, `npm i *`, `npm uninstall*`, `npm update*`) |
| Tracker | `shell` deny `gh issue delete*`, `gh repo edit*`, `gh pr merge*` (delivery re-allows merge; see below) |
| Project | `shell` deny each `forbiddenCommands` entry followed by `*` |

**Role rules** go in each agent's frontmatter. Agent rules apply after the shared ones, so they can tighten or re-allow:

| Role | Rules |
|---|---|
| planner | `edit` deny `*`, then allow `AGENTS.md`, `docs/**`, `.agentkit/**`, and `.opencode/skills/verify-*/**` (project docs and kit files, for verify-skill creation and retro edits); `subagent` deny `*`, then allow each of the seven other roles and the escalated ones |
| scout, pr-reviewer | `edit` deny `*`; `shell` deny `git push*`, `git commit*`, `git merge*`, `git switch*`, `git checkout*`, `gh issue edit*`, `gh issue comment*`, `gh pr edit*`, `gh pr comment*` (pr-reviewer re-allows `gh pr review*` and `gh api*pulls*comments*`) |
| test-writer | `edit` deny `*`, then allow the test folders and test file patterns from `docs/testing.md`; `shell` deny `git *` except `git status*`, `git diff*`, `git log*`, `git show*`; `shell` deny `gh *` |
| coder | `edit` deny the test folders and patterns, `.agentkit/**`, `.opencode/**`, `AGENTS.md`, package manifests and lock files; `shell` deny `git *` except `git status*`, `git diff*`, `git log*`, `git show*`, `git rm <source folders>/*`; `shell` deny `gh *` |
| test-writer, coder (shell writes) | `shell` deny `sed -i*`, `perl -i*`, `*tee *` when they name a path the role may not edit, where the glob can express it; the pr-reviewer's scope check is the backstop |
| test-writer-escalated, coder-escalated | the same rules as their base role |
| checker | `edit` deny `*` (the format command still runs as a shell command); `shell` deny `gh *`, `git merge*`, `git switch*`, `git checkout*` (it may `git add`, `git commit`, and `git push origin <branch>` for commit-task) |
| verifier | `edit` deny `*`; `shell` deny `git *` except `git status*`, `git log*`; `shell` deny `gh *` |
| delivery | `edit` deny `*`; `shell` allow `gh pr merge*` (then deny `*gh pr merge*--admin*` again) |

opencode can't check a PR's base inside a permission rule, so with `"merge": "user"` delivery's `gh pr merge` stays allowed (sprints need it), and the delivery role's merge steps are the guard. Tell the user this, and recommend branch protection on the integration branch so a wrong merge is refused by GitHub.

Setup, update, and the kit's own config files: the planner may not edit `opencode.json` or `.opencode/agents/**`. Run setup and update with opencode's built-in `build` agent (switch with Tab), not the planner.

Glob rules match the command's text, so a determined variant can still slip past them. If the installed opencode supports plugins that run before a tool call, offer the user a small guard plugin with the same checks as the Claude Code adapter's command guard.

## Check after writing

- Start `opencode` in the project. The planner is the default agent and the other seven (plus the escalated ones) appear as subagents.
- Ask the planner to list the subagents it can call. It should list exactly those.
- Ask the scout to create a file. It should be refused.
- Ask the coder to run `gh issue list` and `git push`. Both should be refused.
