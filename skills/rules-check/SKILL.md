---
name: rules-check
description: Use when setting up or extending the project's automated rules check - during setup, or when a retro proposes turning a repeated review finding into a rule.
---

# Rules check: standards enforced by code

A rule written only in a doc drifts; a rule a command checks doesn't. The rules check is one command (`commands.rules` in the lock file) that runs inside the project's check command and fails with a clear message for every broken rule in `docs/clean-code.md` marked **(checked)**.

## Prefer the project's existing tools

Configure what the stack already has before writing a script. Common options:

| Rule | JavaScript / TypeScript | Python | Go | Java / Kotlin |
|---|---|---|---|---|
| Layer boundaries, forbidden imports | `eslint-plugin-boundaries`, ESLint `no-restricted-imports`, dependency-cruiser | import-linter | depguard (golangci-lint) | ArchUnit, Konsist |
| Import cycles | `import/no-cycle`, dependency-cruiser | import-linter | the compiler | ArchUnit |
| Function length, nesting, parameters, complexity | ESLint `max-lines-per-function`, `max-depth`, `max-params`, `complexity` | ruff `C901`, `PLR0913`, `PLR0915` | gocyclo, funlen | detekt, PMD |
| No unsafe types | `@typescript-eslint/no-explicit-any`, `no-non-null-assertion` | mypy `--strict` | — | — |
| Dead code, unused exports | knip, ts-prune, `no-unused-vars` | vulture, ruff `F401`, `F841` | `unused` (staticcheck) | detekt |
| No comments, no debug output | ESLint `no-console`, a small script | ruff `T20` | forbidigo | a small script |

Adding a lint plugin is a new package. It needs the user's yes in the setup preview, with the exact package and version, like any other dependency.

## When no tool fits: a small script

Write `scripts/check-rules.<ext>` in the project's main language, with no new packages:

1. Walk the source folders from `AGENTS.md` section 5.
2. For each rule, a small function returns findings as `path:line rule-name: message`.
3. Print every finding, then exit non-zero if there were any.
4. Add tests for the script itself next to the project's other tests (one passing and one failing sample per rule), so a rule can't silently stop working.

Keep each rule a plain text or import check. A rule that needs real code understanding stays a review rule.

## Setup steps

1. List the rows in `docs/clean-code.md` that could be **(checked)** for this stack.
2. Propose, in the setup preview: which tool or script checks each rule, the config change, and any package needed.
3. After a yes: write the config or script, set `commands.rules` in the lock file, and add it to the check command (for example a `rules` script that the `check` script calls).
4. Run the rules command once. Existing code that breaks a new rule is reported to the user with a count per rule. Offer three choices: fix now (as issues), allow-list the current files and fix later, or drop the rule. Never turn a rule on that fails the check command without the user choosing.
5. Mark each enforced row **(checked)** in `docs/clean-code.md`; delete the marker from rows that aren't.

## Adding a rule later (from a retro)

Same steps 2–5, for one rule. The rule proposal from the review says what to check and gives a failing example from the real code.
