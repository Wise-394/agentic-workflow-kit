# Playbooks

Pick one playbook per issue, record it in the plan's header, and follow its differences from the standard flow in [agentkit-run-issue](../SKILL.md).

| Signal | Playbook |
|---|---|
| Label `type:feature`, or new behavior the PRD asks for | [playbook-feature.md](playbook-feature.md) |
| Label `type:bug`, or existing behavior is wrong | [playbook-bug-fix.md](playbook-bug-fix.md) |
| Label `type:refactor`, or structure changes with behavior kept | [playbook-refactor.md](playbook-refactor.md) |
| Label `type:investigation`, or the issue asks a question | [playbook-investigation.md](playbook-investigation.md) |
| Label `type:verify` | Not run as an issue: the sprint wrap-up runs it ([agentkit-run-sprint](../../agentkit-run-sprint/SKILL.md)) |

When the label and the text disagree (a "feature" that is really a bug), follow the text, note it in the decision log, and fix the label.
