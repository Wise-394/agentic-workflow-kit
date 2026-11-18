# Adapter: Claude Code

How to turn the kit's generic parts into Claude Code files.

## How the planner runs

In Claude Code, subagents can't start other subagents. So the **planner is the main session**: the user starts work in a normal session with "run issue #12" or "run sprint 2", which loads the `run-issue` or `run-sprint` skill. The other seven roles are subagents the main session starts.

## Files written

| Kit source | Project file |
|---|---|
| `roles/<role>.md` (all but planner) | `.claude/agents/<role>.md` |
| `roles/planner.md` | Added to the `run-issue` and `run-sprint` skills as "You are the planner" context, and linked from `CLAUDE.md` |
| `skills/*` | `.claude/skills/<name>/` (copied as they are, including the playbook files) |
| the project's verify skill | `.claude/skills/verify-<project>/SKILL.md` |
| shared permissions | `.claude/settings.json` |
| `AGENTS.md` | Project root, plus a `CLAUDE.md` whose content is `@AGENTS.md` (Claude Code reads `CLAUDE.md`; the import keeps one source of rules). If `CLAUDE.md` exists, add the import line to it instead. |

Kit files that skills and roles link to (`tracker/github.md`, `safety/baseline.md`, `templates/*`) are copied into `.agentkit/kit/` keeping their paths, and the links in the copied roles and skills are rewritten to point there.

## Subagent files

```markdown
---
name: <role>
description: <the role's Purpose, one sentence>. Use when the planner hands over <the role's input>.
tools: <see table>
model: <thinking or working model, or inherit>
---

<body of roles/<role>.md, links rewritten>
```

| Role | `tools` | `model` |
|---|---|---|
| scout | `Read, Grep, Glob, Bash` | working |
| test-writer | `Read, Grep, Glob, Edit, Write, Bash` | working |
| coder | `Read, Grep, Glob, Edit, Write, Bash` | working |
| checker | `Read, Grep, Glob, Bash` | working |
| verifier | `Read, Grep, Glob, Bash` | working |
| delivery | `Read, Grep, Glob, Bash` | working |
| pr-reviewer | `Read, Grep, Glob, Bash` | thinking |

- `model` takes an alias (`sonnet`, `opus`, `haiku`), a full model ID, or `inherit`. Write the user's answer as given. `inherit` uses the main session's model.
- The planner's model is whatever the user picks for the main session. Tell them how to set it (`/model`, or `"model"` in `.claude/settings.json`) if the thinking answer isn't `inherit`.

## Permissions

Claude Code's `.claude/settings.json` applies to the main session and every subagent. Write the baseline and `forbiddenCommands` there as `deny` rules:

```json
{
  "permissions": {
    "deny": [
      "Bash(git push --force:*)", "Bash(git push -f:*)", "Bash(git rebase:*)", "Bash(git filter-branch:*)",
      "Bash(git reset:*)", "Bash(git stash:*)", "Bash(git clean:*)", "Bash(git checkout -- :*)", "Bash(git restore:*)",
      "Bash(git branch -D:*)", "Bash(git push --delete:*)", "Bash(gh repo delete:*)", "Bash(rm -rf:*)",
      "Bash(sudo:*)", "Bash(gh issue delete:*)", "Bash(gh repo edit:*)",
      "Read(./.env)", "Read(./.env.*)", "Edit(./.env)", "Edit(./.env.*)",
      "Bash(<package manager add/install/remove/upgrade forms>:*)",
      "Bash(<each forbiddenCommands entry>:*)"
    ]
  }
}
```

If the lock file says `"merge": "user"`, also deny `Bash(gh pr merge:*)` here. With `"merge": "agent"`, leave it allowed: Claude Code can't allow a command for the delivery subagent only, so the merge conditions in the safety baseline and the delivery role are what guard it.

Role limits that Claude Code can't set per subagent (the test-writer editing only tests, the coder never editing tests) are enforced by each role's instructions and checked again by the pr-reviewer. Tell the user this during setup.

Merge with any existing `.claude/settings.json`: keep every existing rule, and add only the missing ones.

## Check after writing

- `/agents` lists the seven subagents with their models.
- The skills appear in the skill list (`run-issue`, `run-sprint`, `plan-project`, …).
- Ask the scout subagent to create a file. It should have no edit tool.
- `/permissions` shows the deny rules.
