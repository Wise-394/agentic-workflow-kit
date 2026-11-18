---
name: plan-project
description: Use when the user wants an idea turned into a PRD, milestones, and issues in the tracker, or wants an existing PRD and its issues updated with a change.
---

# Plan the project

Writes the PRD and issues. Nothing is created in the tracker until the user has seen the full list and said yes. Tracker commands are in [tracker/github.md](../../tracker/github.md).

## Create mode

1. **Interview** the user, one question at a time, in plain words with examples. Find out: the problem and who has it; the core flows; what must never happen (data loss, privacy); platform and constraints; what is explicitly out of scope; what "done" looks like for the first usable version.
2. **Write the PRD** from [templates/prd-issue.md](../../templates/prd-issue.md). Group requirements by area, each area with a short ID prefix. Each requirement is one testable sentence with a priority.
3. **Cut milestones.** Milestone 1 is the smallest version a person can actually use end to end. Each later milestone adds one coherent step. Every `must` requirement lands in a milestone.
4. **Write issues** from [templates/issue.md](../../templates/issue.md). One issue is one PR that a reviewer can judge on its own (usually one flow or one layer of a flow). Each issue lists its requirement IDs, acceptance tests in plain words, checks only a person can do, and `Blocked by #N` lines. Order inside a milestone: foundations (storage, domain rules) before services, before screens.
5. **Add one verification issue** per milestone from [templates/verification-issue.md](../../templates/verification-issue.md), labelled `type:verify`, blocked by every other issue in the milestone.
6. **Show the user everything:** the PRD and a table of milestones and issues (title, type, requirement IDs, blockers). Change what they ask for.
7. **Create:** ensure-labels, create the PRD issue (label `prd`, then `gh issue pin <N>`), create-milestone for each milestone, and create-issue for each issue in blocker order, so `Blocked by #N` can use real numbers.
8. **Report:** the PRD link, the milestones, and the issue count, and suggest running `run-sprint` on milestone 1.

## Update mode

1. Read the PRD issue and the open milestones.
2. Ask what changed, one question at a time.
3. Write the change: new or revised requirement rows (never reuse a retired ID), plus a line in the PRD's changelog.
4. Map the change to issues: edit open issues that the change touches, add new issues to an open milestone or a new one, and list any closed issues whose behavior the change reverses (each becomes a new issue).
5. Show the user the PRD diff and the issue changes. Apply only after they say yes.
