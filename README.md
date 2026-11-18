# Agentic Workflow Kit

A reusable setup for running a team of coding agents on any repository. It doesn't depend on any one tool or model, and it keeps its state in the issue tracker.

The kit is plain markdown that an agent follows. There's no installer. Point your coding agent at this repo and it sets itself up:

> Read https://github.com/wise-394/agentic-workflow-kit and follow SETUP.md to set it up in this project.

The agent looks at your repo, asks only what it can't work out (which models to use, commands agents must never run, whether merges are done by you or the agent), shows you every file it will write, and writes nothing until you say yes.

## What you get

- **Two run modes**
  - `run-issue`: paste an issue and get a reviewed, verified PR.
  - `run-sprint`: name a milestone. Every issue runs in dependency order on a `sprint/<milestone>` branch, and the sprint ends in one verified PR into your integration branch.
- **Project planning:** `plan-project` turns an idea into a PRD issue, milestones, and issues with acceptance tests, and updates them later.
- **Proof before "done":** each project gets its own `verify-<project>` skill. Every PR carries real evidence: test output, logs, and the checklist of checks that only a person can do.
- **Independent review:** a fresh reviewer sees only the issue and the diff, never the builder's reasoning.
- **Stateless:** issues, labels, a plan comment, branches, and PRs hold all the state, so any agent on any machine can resume.
- **One safety baseline:** written once and turned into your tool's permission settings.

## How it fits together

| Folder | What it holds |
|---|---|
| [SETUP.md](SETUP.md) | The install flow an agent follows |
| [UPDATE.md](UPDATE.md) | The update flow: compare versions, show the diff, keep your answers |
| [roles/](roles/) | The eight agent roles. They name no model and no tool |
| [skills/](skills/) | Portable `SKILL.md` workflows |
| [tracker/](tracker/) | The exact tracker commands (GitHub via `gh`) |
| [safety/](safety/) | The rules every project gets |
| [templates/](templates/) | `AGENTS.md`, the plan comment, PR bodies, issue bodies, the lock file, starter docs |
| [adapters/](adapters/) | How to turn roles, models, and permissions into a specific tool's files |
| [examples/sandbox/](examples/sandbox/) | A tiny repo for testing the kit |

Supported tools today: opencode and Claude Code. Adding a tool means adding one file in `adapters/`.

## Requirements

- A coding agent that can read files, run shell commands, and start subagents.
- `git`, plus `gh` logged in to the repo's GitHub account.

## Updating

> Read https://github.com/wise-394/agentic-workflow-kit and follow UPDATE.md.

## Developing the kit

Run `scripts/check-kit.sh` before every commit, and follow [docs/release-checklist.md](docs/release-checklist.md) before every release.

## License

MIT
