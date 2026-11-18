---
name: verify
description: Use when a project needs its verify-<project> skill created or refreshed, or when running a sprint's verification issue.
---

# Verify: proving changes work

Tests prove the code does what the tests say. Verification proves the app does what the issue says. Each project gets its own `verify-<project>` skill, because launching and driving an app is different in every project.

## Create or refresh the project's verify skill

1. **Find out how the app runs:** scripts in the build file, README instructions, the dev server command, health endpoints, seed data, existing end-to-end tests.
2. **Find out what agents may not run.** Anything in `forbiddenCommands` (for example builds, installs on a device, or deploys) can't be in an agent step. Those checks become user rows.
3. **Ask the user** to confirm, in one message: how to launch, how to tell it's healthy, and which flows matter most. Give your best guess for each.
4. **Write** `verify-<project>/SKILL.md` into the project's skills folder (the adapter says where) with these sections:

```
---
name: verify-<project>
description: Use when a change must be proven to work in the running <project> app, after its tests pass.
---

# Verify <project>

## Launch
<exact commands, with how long to wait>

## Health check
<command and expected output>

## Drive
| Flow | Agent steps | Expected evidence |
|---|---|---|
| <flow> | <commands or browser steps> | <output to capture> |

## Evidence
<where to save screenshots and logs; what to paste into the PR>

## Cleanup
<exact commands to stop everything started>

## User-only checks
<checks an agent may not run, written as steps for a person>
```

5. Show the file to the user before saving it. Add it to `installedFiles` in the lock file. Refresh it when the app's launch or main flows change.

## Run a verification (proof plan or sprint)

1. Follow the project's verify skill: launch, health check, drive each flow in the proof plan, capture evidence, clean up (always, even after a failure).
2. Record each row as PASS, FAIL, or USER CHECK with the real evidence.
3. For a sprint's `type:verify` issue: tick each agent row on the issue with its evidence, and leave the user rows unticked for the user.

## Rules

- "Should work" is never evidence.
- A check that couldn't run is reported as not run, with the reason. It is never PASS.
