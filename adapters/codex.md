# Adapter: Codex

Codex reads skills in the open `SKILL.md` format. Check the installed version's docs for where it looks for skills and whether it can start subagents, and adapt if they differ from this page.

## Install

```bash
git clone https://github.com/wise-394/agentic-workflow-kit ~/.local/share/agentkit
mkdir -p ~/.codex/skills
for s in ~/.local/share/agentkit/skills/agentkit-*; do ln -sfn "$s" ~/.codex/skills/; done
```

Updating the kit is `git -C ~/.local/share/agentkit pull`, then agentkit-setup again in each project. `<kit>` is the folder two levels above a skill's real path.

## Roles and models

- If the installed Codex can start subagents, the planner starts each role as one, with the role prompt from agentkit-run-issue's "Starting a role".
- If it can't, the planner starts each role as its own process, which is just as fresh:

```bash
codex exec -m <model for the role's tier> "Read <kit>/roles/<role>.md and follow it exactly. Project root: <path>. Issue #<N>. Task <k>."
```

Setup records the model names in `[models]`; leave them `inherit` to use the configured default.

## Files setup writes in the project

| File | Content |
|---|---|
| `AGENTS.md` | Codex reads it automatically |

## Unattended runs

```bash
codex exec "Use the agentkit-next skill."
```

Run it inside a sandbox that holds only this checkout and a token scoped to this repository (see [reference/orchestrator.md](../reference/orchestrator.md)). Use Codex's own sandbox and approval settings to allow the project's commands and `bash <kit>/scripts/agentkit` without prompts, and keep network access limited to GitHub and the package registry.

## Check after setup

- The five `agentkit-*` skills appear in Codex's skill list.
- `codex exec "Use the agentkit-next skill."` in a test repository prints an `AGENTKIT_RESULT` line.
