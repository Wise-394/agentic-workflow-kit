# Retro: make the next sprint better

A mistake made twice becomes a rule. The retro proposes; it never changes anything by itself.

## 1. Gather

For the milestone:

1. Every review on its PRs: findings with severity, and **rule proposals**.
2. Every **Follow-ups** list in its PR bodies.
3. Every issue that was blocked, with the reason, and every recorded assumption.
4. The **Counters** of each plan (task rounds, escalations, review rounds) and the sessions each issue used.

## 2. Group

Group findings by the rule they broke: a `docs/clean-code.md` section, an `AGENTS.md` rule, or "no rule". A group is worth acting on when it has two or more findings, or one blocker.

## 3. Propose

One proposal per group, the strongest that fits:

| Proposal | When |
|---|---|
| A checked rule ([rules-check.md](../../agentkit-setup/references/rules-check.md)) | A tool or a small script can detect it |
| A row in `docs/patterns.md` | Agents built the same kind of file in different shapes |
| A rule in `docs/clean-code.md` | A judgment call that kept going wrong, with a concrete example |
| An `AGENTS.md` hard rule or invariant | A project fact agents didn't know |
| A change to `docs/testing.md` | Tests kept missing the same kind of case |
| A fill for an empty slot in `.agentkit/config` | A skill would have caught a repeated finding (for example a security reviewer) |
| A limit change in `.agentkit/config` | Issues kept being split, or large PRs kept hiding problems |
| A follow-up issue | Existing code must change to meet a new rule |

Each proposal shows the findings it comes from (links), the exact text or setting, and what it would have caught.

## 4. Post

Create one issue with no milestone: `agentkit new-issue none chore "Retro M<k>: proposals" <file>`. Its body has one unticked checkbox per proposal, and the numbers from step 1.4 so the trend is visible next time.

The user ticks what they want, then either moves the issue into a milestone, so a run applies the ticked items as a normal chore, or runs `agentkit-run-issue` on it. Unticked proposals are declined.
