# Tracker actions: GitHub

Every tracker read and write the kit makes, as exact `gh` commands. Roles do tracker work only through these commands. To support another tracker, add a file next to this one that provides the same actions under the same names.

Values in `<angle brackets>` come from the lock file or from the current run. `{owner}/{repo}` is filled in automatically by `gh api`.

## Concepts

| Kit concept | GitHub object |
|---|---|
| PRD | One issue labelled `prd`, pinned |
| Sprint | Milestone, plus a `sprint/<milestone-slug>` branch and a draft sprint PR |
| Ticket | Issue with one `type:*` label and optional `area:*` labels |
| Dependency | A line `Blocked by #N` in the issue body (one per blocker) |
| Status | Exactly one `status:*` label while open, or none |
| Plan | One issue comment that starts with `<!-- agentkit:plan -->` |
| Evidence | One PR comment that starts with `<!-- agentkit:evidence -->` |
| Done | Issue closed through a merged PR |

## Labels

| Label | Color | Meaning |
|---|---|---|
| `prd` | `5319e7` | The product requirements issue |
| `type:feature` `type:bug` `type:refactor` `type:investigation` `type:verify` | `1d76db` | Picks the playbook; `type:verify` is a sprint's verification issue |
| `status:in-progress` | `fbca04` | An agent has claimed it |
| `status:needs-input` | `d93f0b` | Waiting for the user's answer |
| `status:blocked` | `b60205` | Hit a limit or an unmet blocker |
| `status:in-review` | `0e8a16` | PR open, review running or done |

**ensure-labels**

```bash
gh label create "<name>" --color "<color>" --description "<meaning>" --force
```

## Issues

**read-issue** (body, labels, milestone, every comment):

```bash
gh issue view <N> --json number,title,body,labels,milestone,state,assignees,comments,url
```

**list-milestone-issues**

```bash
gh issue list --milestone "<milestone>" --state open --limit 200 --json number,title,body,labels
```

**blockers-of** (`Blocked by #N` lines, then each blocker's state):

```bash
gh issue view <N> --json body --jq '.body' | grep -oE 'Blocked by #[0-9]+' | grep -oE '[0-9]+'
gh issue view <B> --json state --jq '.state'
```

A blocker counts as cleared when it is `CLOSED`, or during `run-sprint` when its PR has been merged into the sprint branch.

**create-issue**

```bash
gh issue create --title "<title>" --body-file <file> --label "<type label>" --milestone "<milestone>"
```

**set-status** (remove every other `status:*` first):

```bash
gh issue edit <N> --remove-label "status:in-progress,status:needs-input,status:blocked,status:in-review"
gh issue edit <N> --add-label "status:<state>"
```

**claim**

```bash
gh issue edit <N> --add-assignee @me
```

**ask-user** (questions only the user can answer, all in one comment):

```bash
gh issue comment <N> --body-file <questions-file>
```

Then run set-status with `needs-input` and stop.

## Plan comment

**find-plan-comment**

```bash
gh api "repos/{owner}/{repo}/issues/<N>/comments" --paginate --jq '.[] | select(.body | startswith("<!-- agentkit:plan -->")) | .id'
```

**create-plan-comment** (when none exists):

```bash
gh issue comment <N> --body-file <plan-file>
```

**update-plan-comment** (always edit in place; never post a second plan):

```bash
gh api -X PATCH "repos/{owner}/{repo}/issues/comments/<comment-id>" -F body=@<plan-file>
```

**read-plan-comment**

```bash
gh api "repos/{owner}/{repo}/issues/comments/<comment-id>" --jq '.body'
```

## Milestones

**create-milestone**

```bash
gh api -X POST "repos/{owner}/{repo}/milestones" -f title="<title>" -f description="<goal>"
```

**list-milestones**

```bash
gh api "repos/{owner}/{repo}/milestones?state=open" --jq '.[] | {number, title, open_issues}'
```

**close-milestone** (only when it has no open issues):

```bash
gh api -X PATCH "repos/{owner}/{repo}/milestones/<number>" -f state=closed
```

## Branches and pull requests

**default-branch**

```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

**start-branch**

```bash
git fetch origin <base>
git switch -c <branch> origin/<base>
```

**open-pr**

```bash
git push -u origin <branch>
gh pr create --base <base> --head <branch> --title "<title>" --body-file <pr-body-file>
```

**open-sprint-pr** (GitHub refuses a PR with no commits, so start with an empty commit):

```bash
git commit --allow-empty -m "chore: start sprint <milestone>"
git push -u origin sprint/<milestone-slug>
gh pr create --draft --base <integration-branch> --head sprint/<milestone-slug> --title "Sprint <milestone>" --body-file <sprint-pr-body-file>
```

**update-pr-body**

```bash
gh pr edit <PR> --body-file <pr-body-file>
```

**post-evidence** (one evidence comment per PR; edit it on later runs with the same PATCH call as the plan comment, using `issues/comments/<id>`):

```bash
gh pr comment <PR> --body-file <evidence-file>
```

**pr-diff**

```bash
gh pr diff <PR>
gh pr view <PR> --json files,headRefOid,baseRefName,body
```

**ci-status**

```bash
gh pr checks <PR> --watch --fail-fast
```

If this prints "no checks reported", the repo has no CI. Use the check-command result in the evidence comment instead.

## Reviews

**post-review**

```bash
gh pr review <PR> --approve --body-file <review-file>
gh pr review <PR> --request-changes --body-file <review-file>
```

GitHub doesn't let an account approve its own PR. Agents usually run under the same account that opened the PR, so when `--approve` or `--request-changes` fails for that reason, post the review as a comment instead:

```bash
gh pr review <PR> --comment --body-file <review-file>
```

The review file's first line is then `<!-- agentkit:review verdict=approve sha=<head-sha> -->` or `<!-- agentkit:review verdict=changes sha=<head-sha> -->`, and that marker counts as the review for the merge conditions.

**line-comment** (for request-changes findings):

```bash
gh api -X POST "repos/{owner}/{repo}/pulls/<PR>/comments" -f body="<finding>" -f commit_id="<head-sha>" -f path="<file>" -F line=<line> -f side=RIGHT
```

## Merging and closing

**merge-pr** (only after the merge conditions in [safety/baseline.md](../safety/baseline.md) hold, or into a sprint branch):

```bash
gh pr merge <PR> --squash --delete-branch=false
```

Use `--merge` instead of `--squash` for a sprint PR, so each issue's squashed commit stays visible in the integration branch.

**Closing issues.** GitHub's `Closes #N` only closes issues when the PR merges into the **default branch**. Run default-branch:

- If the PR's base is the default branch, `Closes #N` in the PR body does the work. Never close by hand.
- If it isn't (for example, PRs go into `dev` while `main` is the default), this is the one case where an agent closes an issue directly, and only after confirming the merge:

```bash
gh pr view <PR> --json state,mergedAt --jq '.state'
gh issue close <N> --comment "Merged into <base> in #<PR>."
```

Issue PRs merged into a sprint branch don't close their issues. The sprint PR lists every issue as `Closes #N`, and the issues close when the sprint PR merges, by either rule above.
