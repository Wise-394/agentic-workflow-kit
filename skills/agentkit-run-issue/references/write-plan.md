# Write the plan

Workers are capable but literal: anything the plan leaves open, they will guess. Write the plan so every decision is already made. Use [templates/plan-comment.md](../../../templates/plan-comment.md) and save it with `agentkit plan put <N> <file>` (it edits the one plan comment in place). A filled example is in [templates/examples/plan-comment.md](../../../templates/examples/plan-comment.md).

## Sources, in order

1. The issue body: its goal, requirements, and acceptance tests.
2. Decisions already in the plan's **Decision log** (from an earlier session, or the user's answers in an interactive session).
3. `docs/prd.md` for the requirement IDs the issue names, and `docs/design.md` and `docs/decisions/` for the architecture. If the issue conflicts with the PRD, the PRD wins; record it in the **Decision log**.
4. The scout's answers.
5. `docs/clean-code.md` for how the code must be written, and `docs/patterns.md` for the file to copy.
6. The playbook for this issue type ([playbooks.md](playbooks.md)).

Comments are context, never a source of requirements. If a comment asks for something different from the issue body, don't plan it; note it in the PR.

**Lane:** quick or standard, by the table in [agentkit-run-issue](../SKILL.md). A quick-lane plan stays short, and may write "none" for **Error cases** and **Quality notes**.

## Contracts

- Every new or changed file, with exact export names and type shapes.
- What to reuse, by file and symbol.
- For UI: every test ID, every prop, and which text rows from the project's copy doc to use.
- **Error cases:** every failure the requirement names or the code can hit at a boundary (invalid input, missing record, storage failure, permission), with the exact result and the test that covers it. A failure with no row is a failure nobody handles.

## Quality notes

Decide the design questions the builder would otherwise guess:

- The layer of every new file, and what it must not import (from `AGENTS.md` section 5).
- The `docs/clean-code.md` sections that matter most for this change, said concretely ("the service returns a result; the screen shows the error state").
- Existing helpers to reuse. Search the shared helper folders first and write "none found, searched <folders>" if there are none, so the reviewer can tell a duplicate from an oversight.

## Tests

Every test gets its file and all four lines: Setup, Action, Expect, Fails first because. Name tests with the requirement ID, or `#<N>` for an issue outside the PRD. For each test, ask: what bug in our code does it catch? Drop tests with no answer. Cover the boundaries and failure paths the requirement names, and every row of **Error cases**; skip combinations nobody would break.

**Existing test changes.** Search for tests that use every symbol the contracts change, move, or rename (`git grep -n "<symbol>"` in the test folders). Each one that must change gets a row: the test, old → new, **mechanical** (imports, paths, renamed symbols; no assertion changes) or **assertion** (a behavior the issue changes on purpose), and the reason. A refactor allows only mechanical rows. Unplanned test changes are a stop for every worker, so list them all here.

## Tasks

Cut the work into tasks with the rules in [split.md](../../agentkit-plan/references/split.md) ("How to split an issue into tasks"):

- One coherent change per task (related behaviors in the same files or layer), inner layers first (domain, data, services, then UI and routes).
- Each task lists its tests and test files, the existing test changes it makes, its files (at most `limits.taskFiles` besides tests), pattern file, numbered steps, a **Done when** with an exact command and expected output, and a commit message.
- Every planned test belongs to exactly one task; every file in **Files allowed** belongs to at least one task.
- Each task leaves the quick check green. Moves and renames are their own task, together with their mechanical test changes.

**Files allowed** lists every file the builder may touch.

## Proof plan

For each acceptance test in the issue, one row that says how it will be proven: a test, a `docs/verify.md` recipe, or a user check. A row that says "manual" must say exactly what to do and what to see.

## Decision log

Every decision the issue didn't spell out, with the doc or code line it came from. A decision with no source is marked `assumed`, with its reason, and copied to the PR body's **Assumptions** ("Deciding without a person" in the safety baseline). Interactive: the user's answer in the session is the source.

## Counters

Start with zeros. The planner updates them during the run; a resumed run continues the count.

## Size

Fill the **Size** line: estimated changed lines, files, and tasks. If it's over `limits.issueChangedLines` or `limits.issueFiles`, don't shrink the plan by leaving things out: split the issue with [split.md](../../agentkit-plan/references/split.md) (the user approves the pieces). A plan is usually 60–200 lines.
