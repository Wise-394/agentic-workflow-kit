# Playbook: feature

The standard flow, with these emphases:

1. **Requirements first.** Every acceptance test in the issue maps to at least one planned test. List any acceptance test that can only be checked by a person in the proof plan as a user row.
2. **Smallest complete slice.** Build the thinnest path that satisfies every acceptance test end to end before anything extra. No options, settings, or abstractions the issue didn't ask for. The first task is the thinnest path through every layer; later tasks add the failure paths and rules.
3. **Copy before inventing.** Each task names an existing pattern file. A step with no pattern to copy is a design decision: write it in the decision log with its reason.
4. **Wording comes from the docs.** User-facing text that the project's copy doc doesn't contain is a question for the user.
