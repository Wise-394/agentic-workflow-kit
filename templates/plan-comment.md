<!-- agentkit:plan -->
# Plan — #<N> <title>

**Playbook:** <feature | bug-fix | refactor | investigation> · **Lane:** <standard | small> · **Branch:** <branch> · **Base:** <base> · **State:** <scouting | planned | building | verifying | in review | done>

**Size:** about <lines> changed lines in <files> files, <tasks> tasks (limits: <issueChangedLines> lines, <issueFiles> files)

<!-- Small lane: Scout questions, Error cases, and Quality notes may be "none"; there is one task. -->

## Scout questions

1. <question> — **A:** <answer with path:line>

## Contracts

- `<path>` — <new | changed> — exports `<name>(<params>): <return type>` — <behavior in one line>
- Reuse: `<path>` `<symbol>`
- UI: testIDs `<id>`, props `<prop: type>`, text rows `<doc row>`

### Error cases

| Input or situation | Result | Test |
|---|---|---|
| <for example: empty name> | <for example: `{ ok: false, error: 'validation' }`, nothing stored> | Test <n> |

## Quality notes

- Layer for each new file, and what it must not import: `<path>` — <layer> — must not import <…>
- Standards that matter most here, by section of `docs/clean-code.md`: <for example "§4 one error strategy: services return results, never throw">
- Existing helpers to reuse instead of writing new ones: <path symbol | none found, searched <folders>>

## Tests

### Test 1 — <REQ-ID or #N>: <exact test name>
- File: `<test file>`
- Setup: <helpers and data, by name>
- Action: <one call or one user action>
- Expect: <exact values>
- Fails first because: <reason>

### Existing test changes

| Test file and name | Change | Kind | Reason |
|---|---|---|---|
| `<file>` `<test name>` | <old → new: an import path, a renamed symbol, or an assertion> | <mechanical \| assertion> | <the requirement or contract change that makes it necessary> |

<or "none">

## Tasks

Each task is one behavior and one commit, and leaves the quick check green.

### Task 1 — <behavior in a few words>
- Tests: Test <n>, Test <m>; existing test changes: <rows | none>
- Test files: `<path>`
- Files: `<path>`, `<path>` (≤ <taskFiles> besides tests)
- Pattern: `<path to copy>`
- Steps:
  1. <what to create or change, in order>
- Done when: `<test command> <test file>` shows <n> passing; the quick check passes
- Commit: `<type>(#<N>): <message>`

## Files allowed

- `<path>`

## Commands

- `<check command>` (once, before the PR)
- `<test command> <test file>`

## Proof plan

| # | What proves it | How | Who |
|---|---|---|---|
| 1 | <behavior> | <test name, verify-skill step, or user action> | agent \| user |

## Review findings

- [ ] <blocker | major> — <file>:<line> — <problem> — <rule> — <exact fix>

## Follow-ups

- <minor> — <file>:<line> — <problem> — <rule>

## Counters

- Task rounds: <task k: n> · Escalations: <task k> | none · Review rounds: <n> · Approved sha: <sha | none>

## Decision log

- <date> — <decision> — <why, with the doc, code line, or the user's answer (link) it came from>
