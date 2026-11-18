# Playbook: investigation

No code changes, no branch, no PR.

1. **Restate the question** in one sentence in the plan comment.
2. **Gather evidence.** Scout the code, run read-only commands, read logs and history. Every claim cites a file and line, a command output, or a commit.
3. **Separate facts from guesses.** The findings list what is confirmed, what is likely (and what would confirm it), and what is unknown.
4. **Recommend.** One recommendation, with the issues it would create (title and one-line goal each). Don't create them; the user decides.
5. **Finish:** post the findings with post-findings (its first line is `<!-- agentkit:findings -->`), remove the status label, and tell the user. The user closes the issue. From then on, the issue counts as cleared for any issue it blocks (see blockers-of in the tracker file), so a sprint can continue without waiting for the user to close it.
6. **Inside a sprint**, an investigation that blocks a build issue whose plan depends on the answer: the build issue's planner reads the findings and the recommendation. If the recommendation needs a decision only the user can make, the build issue stops with `needs-input` like any other question.
