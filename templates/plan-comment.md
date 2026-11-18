<!-- agentkit:plan -->
# Plan — #<N> <title>

**Playbook:** <feature | bug-fix | refactor | investigation> · **Branch:** <branch> · **Base:** <base> · **State:** <scouting | planned | building | verifying | in review | done>

## Scout questions

1. <question> — **A:** <answer with path:line>

## Contracts

- `<path>` — <new | changed> — exports `<name>(<params>): <return type>` — <behavior in one line>
- Reuse: `<path>` `<symbol>`
- UI: testIDs `<id>`, props `<prop: type>`, text rows `<doc row>`

## Tests

### Test 1 — <REQ-ID>: <exact test name>
- Setup: <helpers and data, by name>
- Action: <one call or one user action>
- Expect: <exact values>
- Fails first because: <reason>

## Steps

1. `<path>` — <what to do> — pattern: `<path>`

## Files allowed

- `<path>`

## Commands

- `<check command>`
- `<test command> <test file>`

## Proof plan

| # | What proves it | How | Who |
|---|---|---|---|
| 1 | <behavior> | <command, verify-skill step, or user action> | agent \| user |

## Review findings

- [ ] <file>:<line> — <problem> — <exact fix>

## Decision log

- <date> — <decision> — <why, with the doc or code it came from>
