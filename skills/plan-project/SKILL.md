---
name: plan-project
description: Use when the user wants an idea turned into a PRD, milestones, and issues in the tracker, or wants an existing PRD and its issues updated with a change.
---

# Plan the project

Writes the PRD and issues. Nothing is created in the tracker until the user has seen the full list and said yes. Tracker commands are in [tracker/github.md](../../tracker/github.md).

## Create mode

1. **Interview** the user, one question at a time, in plain words with examples. Find out: the problem and who has it; the core flows; what must never happen (data loss, privacy); platform and constraints; what is explicitly out of scope; what "done" looks like for the first usable version.
2. **Write the PRD** from [templates/prd-issue.md](../../templates/prd-issue.md). Group requirements by area, each area with a short ID prefix. Each requirement is one testable sentence in EARS form ("When <trigger>, the <system> shall <response>") with a priority. Write non-functional requirements (performance, reliability, privacy, accessibility, security) with a number wherever one exists. A requirement you can't picture a test for is rewritten or turned into a question.
3. **Cut milestones.** Milestone 1 is the smallest version a person can actually use end to end. Each later milestone adds one coherent step. Every `must` requirement lands in a milestone.
4. **Write issues** from [templates/issue.md](../../templates/issue.md), sized and split with [skills/split-issue/SKILL.md](../split-issue/SKILL.md). One issue is one PR inside the size limits, and passes the INVEST check. Prefer vertical slices; split by layer only for foundations shared by several later issues. Each issue lists its requirement IDs, acceptance tests as given / when / then, what to read, starting points, out of scope (with the owning issue), a size estimate, checks only a person can do, and `Blocked by #N` lines. Order inside a milestone: shared foundations (storage, domain rules) first, then slices in the order a person would use them.
5. **Add one verification issue** per milestone from [templates/verification-issue.md](../../templates/verification-issue.md), labelled `type:verify`, blocked by every other issue in the milestone.
6. **Analyze.** Before showing anything, check the whole set and fix what fails:
   - Every `must` requirement (and every `must` non-functional requirement) is covered by at least one acceptance test in some issue. List any gap.
   - Every acceptance test names a requirement ID that exists. List any orphan.
   - No two issues build the same thing; every **Out of scope** item is owned by an issue or marked not planned.
   - `Blocked by` lines form no cycle, and no issue is blocked by a later milestone.
   - Every issue meets the Definition of Ready and the size rule.

   Keep the result as a traceability table: requirement ID → issues → acceptance tests.
7. **Show the user everything:** the PRD, a table of milestones and issues (title, type, requirement IDs, size, blockers), and the traceability table. Change what they ask for.
8. **Create:** ensure-labels, create the PRD issue (label `prd`, then pin-issue), create-milestone for each milestone, and create-issue for each issue in blocker order, so `Blocked by #N` can use real numbers.
9. **Report:** the PRD link, the milestones, and the issue count, and suggest running `run-sprint` on milestone 1.

## Update mode

1. Read the PRD issue and the open milestones.
2. Ask what changed, one question at a time.
3. Write the change: new or revised requirement rows (never reuse a retired ID), plus a line in the PRD's changelog.
4. Map the change to issues (sized with the split-issue skill): edit open issues that the change touches, add new issues to an open milestone or a new one, and list any closed issues whose behavior the change reverses (each becomes a new issue).
5. Run the analyze check from create mode on the changed requirements. Show the user the PRD diff, the issue changes, and any coverage gaps. Apply only after they say yes.
