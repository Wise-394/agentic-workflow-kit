## Verify <milestone>

Run in the sprint's wrap-up, after every other issue in the milestone is merged into `sprint/m<k>`. The agent ticks its rows with real evidence; the person ticks theirs before merging the sprint PR.

## Agent checks

- [ ] The check command passes on the sprint branch head
- [ ] `docs/verify.md`: <flow> — evidence: <file under .agentkit/evidence or pasted lines>

## Checks only a person can do

- [ ] <step, in plain words> — expect: <what you should see>

A row is ticked only with a real result. A failed agent row becomes a fix issue in this milestone, linked here.
