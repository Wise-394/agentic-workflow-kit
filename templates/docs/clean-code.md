# Code standard

How code in this project must be written, and how a reviewer judges it. The builder reads this before writing; the pr-reviewer checks every change against it. Setup fills the `<…>` rows from the real repo and deletes rows it can't fill.

A rule in this file is never "taste". Breaking one is a finding with a severity (see **Severity** below). Anything this file doesn't cover is taste and never blocks.

Rules marked **(checked)** are enforced by `<rules command>`, which runs inside the check command. A reviewer doesn't re-check them by hand.

## 1. Modularity and boundaries

- **One responsibility per file.** A file has one reason to change. When describing what a file does needs "and", split it.
- **Layers and direction.** Dependencies point one way. Setup fills this table from `AGENTS.md` section 5:

  | Layer | May import | Must not import |
  |---|---|---|
  | <for example: domain> | <other domain modules> | <UI, data access, framework> **(checked)** |
  | <for example: data / services> | <domain> | <UI> **(checked)** |
  | <for example: UI> | <services through their interfaces, domain types> | <data access directly> **(checked)** |

- **Business rules live in the domain layer**, never in UI components, route handlers, controllers, or database code.
- **Side effects at the edges.** Storage, network, clock, randomness, and device APIs sit behind narrow typed interfaces and are passed in, not imported from deep inside logic.
- **No import cycles.** **(checked when the stack has a tool for it)**
- **Public surface is small.** Export only what callers use. No barrel files that re-export a folder unless the project already uses them.

## 2. Readability

- **Names say intent.** Functions are verbs (`calculateTotal`), booleans read as questions (`isExpired`, `hasAccess`), and no abbreviations the domain doesn't use. A name that needs a comment is the wrong name. (Exception: UI components and types are nouns, named after what they show or hold.)
- **Small functions.** About <40> lines or fewer, nesting <3> levels or fewer, <4> parameters or fewer (more parameters become one typed object). **(checked: complexity and length limits)**
- **Shallow control flow.** Guard clauses and early returns instead of nested `if`/`else`. No `else` after `return`.
- **No flag arguments** that switch a function between two behaviors. Write two functions.
- **No magic values.** A number or string with meaning gets a named constant next to where it's used, or in the domain's constants file.
- **Comments:** <the project's policy, for example "none: code says what, commit messages say why" or "only to explain why, never what">. **(checked when the policy is "none")**
- **Consistency beats preference.** Follow the shape of the pattern file named in the plan, even if another shape seems nicer.

## 3. Reuse without speculation

- **Search before writing.** Before adding a helper, search `<shared helper folders>` and `docs/patterns.md`. A second implementation of an existing helper is a major finding.
- **DRY for knowledge, not for text.** Merge code that encodes the same rule. Leave code that only looks similar but changes for different reasons.
- **YAGNI.** No options, settings, factories, wrappers, generic repositories, base classes, or extension points without a current requirement that needs them. The smallest design that meets the issue wins.
- **No pass-through layers.** A function that only forwards its arguments to another function is removed. (Exception: a thin adapter that puts a side effect behind the narrow interface section 1 asks for is not a pass-through.)

## 4. Types, inputs, and errors

- **Explicit types at every boundary** (exports, service methods, API handlers). No `any`, unchecked casts, or non-null assertions without a reason the reviewer can verify. **(checked when the stack has a tool for it)**
- **Make invalid states unrepresentable.** Prefer a union or enum over several booleans; prefer a required field over an optional one that is "always set in practice".
- **Validate at the boundary** (user input, API input, file and network data), once. Inner code trusts validated types.
- **One error strategy per layer:** <for example: "domain and services return a result type `{ ok, value } | { ok: false, error }`; only reads may throw"; or "throw typed errors; the handler maps them to responses">.
- **No swallowed errors.** Every `catch` either handles the error in a way the requirement names, converts it to the layer's error type, or rethrows. An empty `catch` is a blocker; a `catch` that only logs is a major. (Exception: the top-level handler of a process, request, or job may log and report, because nothing above it can handle the error.)
- **No partial writes.** A change that touches several records runs in one transaction or is safe to retry.

## 5. State and side effects

- **One owner, one source of truth.** Each piece of state has one owner. Values that can be derived are computed, not stored.
- **Visible effects.** A function that changes state, writes storage, or calls the network says so in its name or its type. Getters never write.
- **Clean up what you start:** listeners, timers, subscriptions, file handles, processes.
- **Idempotent where repeated.** Anything that can run twice (retries, startup work, scheduled jobs, migrations) gives the same result the second time.

## 6. Performance, only where it matters

- **Bounded work on the changed path.** No query inside a loop (N+1), no loading a whole table to use one row, no unbounded lists or renders.
- **No caching, memoization, or optimization layer without a measured need** or a requirement that names one.

## 7. Repeatability and tests

- **Deterministic.** Code under test gets its clock, IDs, and randomness passed in, so tests control them. No test depends on the real time, network, order of other tests, or leftover data.
- **Tests follow `docs/testing.md`.** Every requirement has a test that would fail if the behavior broke.
- **Scripts and setup steps are idempotent.**

## 8. Hygiene

- No dead code, commented-out code, unused exports, or unused parameters. **(checked when the stack has a tool for it)**
- No debug output or temporary probes.
- No unrelated changes: formatting, renames, or refactors outside the plan's files.
- Docs that describe changed behavior are updated in the same change.
- No leftover to-do or fix-me comments without an issue number.

## 9. Security and correctness

A defect here is a finding even when no requirement mentions it.

- **Untrusted input** (user input, request data, files, environment, data from other services) is validated at the boundary and never used to build a query, command, path, or markup by string concatenation. Use parameterized queries, argument arrays, and the framework's escaping.
- **Authorization** is checked where the action happens (the service or handler), not only in the UI.
- **No secrets** in code, tests, fixtures, or logs; no personal data in logs beyond what the project's rules allow.
- **Safe parsing:** no evaluating or deserializing untrusted data into code or arbitrary objects.
- **Concurrency:** shared state changed by more than one caller (requests, jobs, async callbacks) is guarded by a transaction, a lock, or an atomic operation; no check-then-act races.
- **Compatibility:** a change to a public API, stored data, or a schema keeps existing callers and existing data working, or the plan includes the migration.
- **Resources:** inputs that control size (a page size, a file upload, a loop count) are bounded.

## 10. Project rules

<project-specific rules from setup, one per line, each with **(checked)** if a rule enforces it>

---

## Severity

Every review finding has exactly one severity.

| Severity | Meaning | Examples | Effect |
|---|---|---|---|
| **blocker** | Wrong behavior, data loss, security, or a broken contract | A requirement not met, a broken caller, an empty `catch`, a query built from user input, a skipped test | Blocks the merge |
| **major** | Breaks a rule in this file in a way that makes the code harder to change or easier to break | Business rule in a UI component, a duplicated helper, a 120-line function, a missing failure-path test, an unexplained `any` | Blocks the merge |
| **minor** | Breaks a rule in this file, but the cost is small and local | A vague name, a magic number, a missing early return | Listed in the PR under **Follow-ups**; doesn't block |
| **nit** | Taste, not covered by this file | "I'd name it differently" | Left out of the review |

When the same minor shows up in two or more files, or in two or more reviews, report it once as a **rule proposal** in the review. The retro turns rule proposals into checked rules or patterns.

## Review pass

The pr-reviewer works through these in order, and every area gets checked.

1. **Spec compliance:** each acceptance test is implemented and matches the PRD text; nothing extra was built.
2. **Correctness:** invariants from `AGENTS.md` section 4, invalid inputs, failure paths, state consistency, cleanup.
3. **Tests:** apply `docs/testing.md`. A test that can't fail, tests a mock, or asserts implementation details is a finding. Passing checks don't excuse missing coverage.
4. **Modularity:** sections 1 and 3 above.
5. **Readability:** section 2.
6. **Types and errors:** section 4.
7. **State, performance, repeatability:** sections 5–7, only where the change touches them.
8. **Security and correctness:** section 9, on every changed boundary.
9. **Hygiene and scope:** section 8, and the plan's file list.
10. **Blast radius:** every caller of a changed or removed export still works.

Each finding: severity, `file:line`, what it breaks (a section of this file, an `AGENTS.md` rule, a requirement, or `correctness:` / `security:` with the input that shows it), what can go wrong, and the exact fix.
