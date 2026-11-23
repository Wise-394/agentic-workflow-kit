# Playbook: bug fix

1. **Reproduce first.** Task 1's first planned test reproduces the bug through the public interface and fails today for the reported reason. If you can't reproduce it, don't fix anything: post what you tried as a question with `agentkit ask <N> <file>`, and stop (`parked`).
2. **Root cause before fix.** The plan's decision log states the root cause with the exact file and line, and why that line produces the bug. "Added a null check" is not a root cause; "the list is read before the load finishes because X" is.
3. **Fix the cause, not the symptom.** The fix changes the line that causes the bug. A guard around the symptom needs a reason in the decision log.
4. **Look for siblings.** Search for the same pattern elsewhere. Same-cause sites go in the plan or become new issues; never silently fix unplanned files.
5. **Proof:** the reproducing test fails before and passes after, and the verifier runs the original report's steps with `docs/verify.md`.
