# Writing docs/verify.md

Tests prove the code does what the tests say. Verification proves the app does what the issue says. Each project has a `docs/verify.md` that says how to run and drive its app, because that differs in every project. It is a plain doc, not a skill, so every harness can use it.

## Create or refresh it

1. **Find out how the app runs:** scripts in the build file, README instructions, the dev server command, health endpoints, seed data, existing end-to-end tests.
2. **Find out what agents may not run.** Anything in `forbidden.command` (builds, device installs, deploys) can't be an agent step. Those checks become rows under "Only a person can check".
3. **Write** `docs/verify.md` from [templates/docs/verify.md](../../../templates/docs/verify.md), with exact commands. Interactive: show it to the user first. During M0 bootstrap: it is part of the issue's PR, and the user reviews it in the sprint PR.
4. **Try it:** run Start, Healthy, one Drive recipe, and Stop once. Paste what happened into the PR's Evidence.
5. Refresh it when the app's launch or main flows change, in the issue that changes them.

## Run a verification (proof plan or sprint)

1. Run **Stop and clean up** first, in case an earlier session crashed.
2. Start, check health, drive each proof-plan row, capture evidence under `.agentkit/evidence/<issue>/`, and stop. Always stop, even after a failure.
3. Record each row as PASS, FAIL, or USER CHECK with real evidence, redacted (see the safety baseline).

## Rules

- "Should work" is never evidence.
- A check that couldn't run is reported as not run, with the reason. It is never PASS.
