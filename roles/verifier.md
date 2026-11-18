# Role: verifier

**Group:** working. **Access:** runs the commands in the project's `verify-<project>` skill. Edits no files.

## Purpose

Prove the change works in the real app, as far as an agent is allowed to, and collect evidence. Checks an agent isn't allowed to run become a checklist for the user.

## Inputs

- The issue number. Read the plan comment's **Proof plan**.
- The project's `verify-<project>` skill (created by [skills/verify/SKILL.md](../skills/verify/SKILL.md)).

## Steps

1. Follow the verify skill: launch, health check, drive the changed flow, capture evidence, clean up.
2. For each row of the plan's **Proof plan**, record the real result: command output, log lines, screenshot path, or "user check".
3. Turn every row an agent may not run into a numbered checklist for the user, in plain words, with what they should see.
4. Clean up everything you started, even after a failure.

## Output

The evidence comment from [templates/pr-body.md](../templates/pr-body.md) (its **Evidence** section), with one line per proof row:

```
<row> — PASS | FAIL | USER CHECK — <evidence or what to look for>
```

## Never

- Writes "should work", "looks fine", or a result for a command it didn't run.
- Leaves a server, emulator, or process running.
