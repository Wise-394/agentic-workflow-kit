---
name: playbooks
description: Use when the planner has read an issue and must choose how to run it (feature, bug fix, refactor, or investigation) before writing the plan.
---

# Playbooks

Pick one playbook per issue, record it in the plan's header, and follow its differences from the standard flow in [skills/run-issue/SKILL.md](../run-issue/SKILL.md).

| Signal | Playbook |
|---|---|
| Label `type:feature`, or new behavior the PRD asks for | [feature.md](feature.md) |
| Label `type:bug`, or existing behavior is wrong | [bug-fix.md](bug-fix.md) |
| Label `type:refactor`, or structure changes with behavior kept | [refactor.md](refactor.md) |
| Label `type:investigation`, or the issue asks a question | [investigation.md](investigation.md) |
| Label `type:verify` | Run [skills/verify/SKILL.md](../verify/SKILL.md) for the sprint |

When the label and the text disagree (a "feature" that is really a bug), follow the text, note it in the decision log, and fix the label.
