# Verify: proving a change works in the running app

The verifier role follows this doc. Agents run only the commands written here.

## Start

```bash
<command that starts the app, in the background, with its log going to .agentkit/evidence/<issue>/app.log>
```

## Healthy

<A command and its expected output that shows the app is up, for example `curl -fsS localhost:3000/health` prints `ok`.>

## Drive a flow

<How to exercise a behavior: HTTP calls, a browser script, a CLI invocation. One recipe per kind of change.>

## Evidence

<What to capture and where: response bodies, screenshots under .agentkit/evidence/<issue>/, log lines. Never secrets.>

## Stop and clean up

```bash
<commands that stop everything Start started and free its ports; safe to run when nothing is running>
```

Run this at the start of every verification too, in case an earlier session crashed.

## Only a person can check

<Things an agent may not or cannot do here: real devices, payments, emails to real people.>
