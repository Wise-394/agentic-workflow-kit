---
name: agentkit-plan
description: Use when the user wants to plan a product or a change with the kit - turn an idea into docs/prd.md, docs/design.md, milestones, and issues - or update an existing plan. Interactive; the user takes part in every step.
---

# Plan the project together

You and the user plan; agents build later. The plan lives in the repo (`docs/prd.md`, `docs/design.md`, `docs/decisions/`) and the work lives in the tracker (milestones and issues). Nothing is written or created until the user has seen it and said yes.

**Find the kit:** `<kit>` is the folder two levels above this file's real path (resolve symlinks). `agentkit` means `bash <kit>/scripts/agentkit`. If `.agentkit/config` doesn't exist, run the [agentkit-setup](../agentkit-setup/SKILL.md) skill first (its interactive part); it works on an empty repository.

Ask one question at a time, in plain words, with a concrete example and your suggested answer. Never ask what you can find in the repo.

## Create mode

1. **Understand.** Find out the problem and who has it, the core flows, what must never happen (data loss, privacy, money), the platform and constraints, what is explicitly out of scope, and what "done" means for the first usable version.
2. **Challenge.** Before writing anything, push back once, as a product lead and an engineering lead would. Is this the smallest version a person would actually use? What could be cut? What is the riskiest assumption, and how would the first milestone test it? Which choices are expensive to change later? Agree on the answers.
3. **PRD.** Write `docs/prd.md` from [templates/docs/prd.md](../../templates/docs/prd.md):
   - Requirements are grouped by area. Each has an ID with the area's prefix (`AUTH-02`), is one testable sentence in EARS form ("When <trigger>, the <system> shall <response>"), and has a priority.
   - Non-functional requirements (performance, reliability, privacy, accessibility, security) get a number wherever one exists.
   - A requirement you can't picture a test for is rewritten, or becomes a question.
4. **Design.** Write `docs/design.md` from [templates/docs/design.md](../../templates/docs/design.md): principles (five to ten non-negotiables), stack, architecture and layers, data model, external services, and how it will be tested and verified. Every choice with a real alternative gets a short decision record in `docs/decisions/NNNN-<slug>.md` (context, decision, consequences). Ask before choosing anything the user may have an opinion on: language, framework, database, hosting, paid services.
5. **Milestones.** `M0: Bootstrap` always comes first ([bootstrap.md](references/bootstrap.md)). `M1` is the smallest version a person can use end to end. Each later milestone adds one coherent step. Every `must` requirement lands in a milestone.
6. **Issues.** Write issues from [templates/issue.md](../../templates/issue.md), sized and split with [split.md](references/split.md). One issue is one PR inside the size limits and passes the INVEST check. Prefer vertical slices; split by layer only for foundations shared by several later issues. Each issue lists:
   - its requirement IDs
   - acceptance tests as given / when / then
   - what to read and starting points
   - out of scope (with the owning issue)
   - a size estimate
   - checks only a person can do
   - `Blocked by #N` lines

   Order inside a milestone: shared foundations first, then slices in the order a person would use them.
7. **Verification issue.** Add one `type:verify` issue per milestone from [templates/verification-issue.md](../../templates/verification-issue.md).
8. **Analyze**, before showing anything:
   - Every `must` requirement is covered by at least one acceptance test.
   - Every acceptance test names a real requirement ID.
   - No two issues build the same thing.
   - Every out-of-scope item has an owner or is marked not planned.
   - `Blocked by` lines form no cycle and never point to a later milestone.
   - Every issue meets the Definition of Ready.

   Keep a traceability table: requirement ID → issues → acceptance tests.
9. **Show everything:** the PRD, the design, the decisions, a table of milestones and issues (title, type, requirement IDs, size, blockers), and the traceability table. Change what the user asks for.
10. **Write and create**, after the yes:
    - **Commit the docs and the kit's project files.** Include `docs/`, `.agentkit/config`, `.gitignore`, `AGENTS.md` and `CLAUDE.md` if setup wrote them, and the adapter's files. Unattended runs need all of them in the repository, and a run refuses to start on a checkout with uncommitted changes.
      - If the repository has no commits yet, commit them directly as the first commit on the default branch and push. This is the one time anything is committed without a PR.
      - Otherwise, put them on a branch `docs/plan`, open a PR into the integration branch, and ask the user to merge it before the first run.
    - **Labels.** `agentkit labels`. The integration branch is created from the default branch on the first run, if it doesn't exist.
    - **Milestones.** Create each with `agentkit new-milestone "M<k>: <name>" <description-file>`.
    - **Issues.** Create them with `agentkit new-issue <milestone> <type> <title> <body-file>`, in blocker order so `Blocked by #N` can use real numbers.
11. **Report:** the docs, the milestones, the issue count, and how to start:
    - one issue: `agentkit-run-issue #N`;
    - a sprint: `agentkit-run-sprint M0`;
    - unattended: point your runner at `agentkit-next`, see [reference/orchestrator.md](../../reference/orchestrator.md).

## Update mode

1. Read `docs/prd.md`, `docs/design.md`, and the open milestones.
2. Ask what changed, one question at a time.
3. Write the change:
   - New or revised requirement rows. Never reuse a retired ID.
   - A changelog line at the end of the PRD.
   - A decision record for any design change.
4. Map the change to issues, sized with the split reference:
   - Edit open issues the change touches (`agentkit issue-body` for issues the agent wrote; for others, ask the user).
   - Add new issues.
   - List closed issues whose behavior the change reverses; each becomes a new issue.
5. Run the analyze check on the changed requirements. Show the doc diff, the issue changes, and any coverage gaps. Apply only after a yes. The docs change goes through a `docs/plan-<date>` PR.
