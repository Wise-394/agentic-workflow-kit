# Adapter: Claude Code

How to turn the kit's generic parts into Claude Code files.

## How the planner runs

In Claude Code, subagents can't start other subagents. So the **planner is the main session**: the user starts work in a normal session with "run issue #12" or "run sprint 2", which loads the `run-issue` or `run-sprint` skill. The other seven roles are subagents the main session starts. Setup, update, verify-skill creation, and retro edits also run in the main session, which can edit files.

## Files written

| Kit source | Project file |
|---|---|
| `roles/<role>.md` (all but planner) | `.claude/agents/<role>.md` |
| `roles/planner.md` | Added to the `run-issue` and `run-sprint` skills as "You are the planner" context, and linked from `CLAUDE.md` |
| `skills/*` | `.claude/skills/<name>/` (copied as they are, including the playbook files) |
| the project's verify skill | `.claude/skills/verify-<project>/SKILL.md` |
| `AGENTS.md` | Project root, plus a `CLAUDE.md` whose content is `@AGENTS.md` (Claude Code reads `CLAUDE.md`; the import keeps one source of rules). If `CLAUDE.md` exists, add the import line to it instead. |

Kit files that skills and roles link to (`tracker/github.md`, `safety/baseline.md`, `templates/*`) are copied into `.agentkit/kit/` keeping their paths, and the links in the copied roles and skills are rewritten to point there.

## Subagent files

```markdown
---
name: <role>
description: <the role's Purpose, one sentence>. Use when the planner hands over <the role's input>.
model: <the role's tier model (thinking, working, or light), or inherit>
---

<body of roles/<role>.md, links rewritten>
```

| Role | `model` |
|---|---|
| scout | light |
| test-writer | working |
| coder | working |
| checker | light |
| verifier | working |
| delivery | light (working if `merge` is `agent`) |
| pr-reviewer | thinking |

Leave out `tools`, so every subagent gets the same tools as the main session.

- `model` takes an alias (`opus`, `sonnet`, `haiku`), a full model ID, or `inherit`. Write the user's answer as given. `inherit` uses the main session's model.
- Typical suggestion for setup's model question (only a suggestion; setup always asks and writes what the user chooses): **thinking** `opus` (the main session runs the planner), **working** `sonnet`, **light** `haiku`. Aliases follow the newest model of each family, so they don't go stale. If the user's plan or budget favors fewer tiers, `sonnet` for both working and light is a safe middle.
- Escalation: Claude Code's subagent tool accepts a `model` override per call, so the planner retries a stuck test-writer or coder task by starting the same subagent with the `models.escalation` tier's model. Add that instruction to the `run-issue` skill's copy under "You are the planner".
- Step limit: if the installed version supports a per-subagent turn limit in the frontmatter (check the subagent docs), set it from `limits.workerSteps`. Otherwise the kit's retry and round limits are what bound a worker.
- The planner's model is whatever the user picks for the main session. Tell them how to set it (`/model`, or `"model"` in `.claude/settings.json`) if the thinking answer isn't `inherit`.

## Permissions

The kit writes no permission rules, hooks, or per-role tool limits. Subagents run with the session's own permissions, and each role's limits (what it may edit, which commands it runs) are the written rules in its role file and in the safety baseline. Leave any existing `.claude/settings.json` untouched.

## Check after writing

- `/agents` lists the seven subagents with their models.
- The skills appear in the skill list (`run-issue`, `run-sprint`, `plan-project`, …).
