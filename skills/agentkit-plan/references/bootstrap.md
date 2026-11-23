# M0: Bootstrap

Every plan starts with milestone `M0: Bootstrap`. It turns an empty (or tool-less) repository into one the agents can work in safely. Agents build it like any other milestone; the user merges its sprint PR. Skip an issue only when the repository already has what it delivers.

Create these issues in `M0`, in this order, each with `type:chore`. Use [templates/issue.md](../../../templates/issue.md) and fill in the choices from `docs/design.md`.

## 1. Walking skeleton

- **Goal:** the chosen stack runs, with the folder layout from `docs/design.md` and one trivial end-to-end path (for example a health route, or a screen that renders a title).
- **Acceptance tests:**
  - One test exercises the trivial path.
  - The project has these commands:
    - **check:** types, lint, and all tests.
    - **quick:** lint and typecheck on given files.
    - **test:** one test file.
    - **format:** given files.
  - Each command exits 0 on the skeleton.
  - The commands are written into `[commands]` in `.agentkit/config`. Until they exist, `agentkit check-task` refuses to pass anything, so the plan's first task lists `.agentkit/config` among its files and its coder writes them.
- **Out of scope:** product features.

## 2. Continuous integration and the verify doc

- **Goal:** every PR runs the check command in CI, and agents know how to prove a change works in the running app.
- **Acceptance tests:**
  - CI runs `check` on pull requests into the sprint branches, the integration branch, and the default branch.
  - `docs/verify.md` exists, written with [verify-doc.md](../../agentkit-run-issue/references/verify-doc.md). It says how to start the app, check it is healthy, drive the trivial path, capture evidence, and stop everything.
  - The verifier can follow it on the skeleton.
- **Blocked by:** issue 1.

## 3. Project docs from the real code

- **Goal:** the rules every agent reads describe this codebase.
- **Acceptance tests:**
  - The [agentkit-setup](../../agentkit-setup/SKILL.md) skill's "Project docs" mode has run.
  - `AGENTS.md`, `docs/clean-code.md`, `docs/patterns.md`, and `docs/testing.md` describe the skeleton's real folders, commands, and patterns, with no placeholders left.
  - Every assumption the agent made is listed in the PR body for the user to check.
- **Blocked by:** issues 1 and 2.

## 4. Verify M0

- **Type:** `type:verify`.
- **Agent rows:**
  - `check` passes on `sprint/m0`.
  - The verify doc's trivial path works.
- **User rows:**
  - "Protect the integration and default branches: no direct pushes, CI required. Settings → Branches." The agent account has no admin rights, so only the user can do this.
  - "Read the project docs from issue 3 and correct anything wrong."
