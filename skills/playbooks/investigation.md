# Playbook: investigation

No code changes, no branch, no PR.

1. **Restate the question** in one sentence in the plan comment.
2. **Gather evidence.** Scout the code, run read-only commands, read logs and history. Every claim cites a file and line, a command output, or a commit.
3. **Separate facts from guesses.** The findings list what is confirmed, what is likely (and what would confirm it), and what is unknown.
4. **Recommend.** One recommendation, with the issues it would create (title and one-line goal each). Don't create them; the user decides.
5. **Finish:** post the findings as a comment on the issue, remove the status label, and tell the user. The user closes the issue.
