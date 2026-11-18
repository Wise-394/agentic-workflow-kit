---
name: retro
description: Use when a sprint ends, or when the user asks, to turn repeated review findings and stuck runs into better patterns, standards, and checked rules.
---

# Retro: make the next sprint better

The kit gets better the same way a team does: a mistake made twice becomes a rule. Nothing here changes code; it changes the project's docs and rules check, and only after the user says yes.

## 1. Gather

For the milestone (or the issues the user names):

1. Every review on its PRs: findings with severity, and **rule proposals**.
2. Every **Follow-ups** list in its PR bodies.
3. Every issue that stopped (`needs-input`, `blocked`), with the reason in its plan comment.
4. The **Counters** section of each issue's plan comment (task rounds, escalations, review rounds) and task commits per PR.

## 2. Group

Group findings by the rule they broke (a `docs/clean-code.md` section, an `AGENTS.md` rule, or "no rule"). A group is worth acting on when it has two or more findings, or one blocker.

## 3. Propose

For each group, one proposal, the strongest that fits:

| Proposal | When |
|---|---|
| A checked rule ([skills/rules-check/SKILL.md](../rules-check/SKILL.md)) | A tool or a small script can detect it |
| A new or changed row in `docs/patterns.md` | Agents built the same kind of file in different shapes |
| A new or sharper rule in `docs/clean-code.md` | A judgment call that kept going wrong, with a concrete example |
| A new `AGENTS.md` hard rule or invariant | A project fact agents didn't know |
| A change to `docs/testing.md` | Tests kept missing the same kind of case |
| A follow-up issue | Existing code needs fixing to meet a new rule |
| A size change in the lock file `limits` | Issues kept being split, or reviews kept missing things in large PRs |

Each proposal shows: the findings it comes from (links), the exact text or config to add, and what it would have caught.

## 4. Apply

Show the user every proposal at once. Apply only the approved ones, each through the normal flow:

- Docs edits: delivery start-branch `chore/retro-<milestone-slug>`; the planner edits the approved docs (project docs are files it may edit); the checker runs full mode and commits them with commit-task; delivery opens a PR into the integration branch.
- Follow-up issues go into the next milestone.
- Rules go through the rules-check skill.

## 5. Report

One message: what was learned, what changed, what was declined, and the numbers from step 1.4 so the trend is visible next time.
