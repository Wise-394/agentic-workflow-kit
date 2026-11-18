# Agentic Workflow Kit Implementation Plan

> **Historical.** This document describes version 0.1.0 as first designed (two model tiers, plans with **Steps**). The current behavior is in the kit's own files and [CHANGELOG.md](../../CHANGELOG.md).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build version 0.1.0 of the kit described in the spec and publish it as a public GitHub repo.

**Architecture:** Markdown only. Generic files (roles, skills, tracker, safety, templates, SETUP/UPDATE) never name a tool or model; `adapters/` are the only tool-aware files. A shell check script is the kit's test suite.

**Tech Stack:** Markdown, bash, `gh` CLI.

**Spec:** `docs/specs/2026-11-18-agentic-workflow-kit-design.md`

## Global Constraints

- Generic files must not name a tool, model, provider, stack, or real project (checked by `scripts/check-kit.sh`).
- Every skill is `skills/<name>/SKILL.md` with `name:` equal to the folder and a `description:` starting with "Use when".
- No placeholders (`TODO`, `TBD`) anywhere.
- Every relative markdown link resolves.
- Public repo: no personal data, keys, or project-specific details.

---

### Task 1: Skeleton and the kit test

**Files:** Create `scripts/check-kit.sh`, `README.md`, `VERSION`, `CHANGELOG.md`, `LICENSE`.

- [ ] Write `scripts/check-kit.sh` with checks: skill frontmatter, tool/model-name leak in generic files, placeholders, relative links, role references.
- [ ] Run it on the empty skeleton: expect FAIL (missing required files).
- [ ] Add README, VERSION (`0.1.0`), CHANGELOG, LICENSE (MIT).
- [ ] Commit.

### Task 2: Safety baseline and tracker actions

**Files:** Create `safety/baseline.md`, `tracker/github.md`.

- [ ] Write the baseline (spec section 10) and the GitHub action table (spec section 9) with exact `gh` commands, including: plan-comment marker lookup, own-PR approval fallback, issue closing when the integration branch is not the default branch, empty first commit for the sprint draft PR, no-CI fallback.
- [ ] Run check script; commit.

### Task 3: Roles

**Files:** Create `roles/{planner,scout,test-writer,coder,checker,verifier,delivery,pr-reviewer}.md`.

- [ ] Each role: group (thinking/working), purpose, inputs, steps, output format, allowed actions, stop conditions.
- [ ] Run check script; commit.

### Task 4: Templates

**Files:** Create `templates/{AGENTS.md,issue.md,plan-comment.md,pr-body.md,sprint-pr-body.md,verification-issue.md,prd-issue.md,lock.json}`, `templates/docs/{testing,patterns,clean-code}.md`.

- [ ] Run check script; commit.

### Task 5: Skills

**Files:** Create `skills/{run-issue,run-sprint,write-plan,pr-review,verify,plan-project}/SKILL.md`, `skills/playbooks/SKILL.md` plus `skills/playbooks/{feature,bug-fix,refactor,investigation}.md`.

- [ ] Run check script; commit.

### Task 6: SETUP and UPDATE

**Files:** Create `SETUP.md`, `UPDATE.md`.

- [ ] Run check script; commit.

### Task 7: Adapters

**Files:** Create `adapters/opencode.md`, `adapters/claude-code.md`.

- [ ] Map roles → agent files, models → config, baseline + project rules → permissions, skills → skill folders. Note where the orchestrating role runs (primary agent vs main session).
- [ ] Run check script; commit.

### Task 8: Sandbox and release checklist

**Files:** Create `examples/sandbox/{README.md,package.json,src/sum.js,test/sum.test.js}`, `docs/release-checklist.md`.

- [ ] Sandbox test runs with `node --test`.
- [ ] Run check script; commit.

### Task 9: Spec alignment and publish

- [ ] Update the spec with facts found while building (issue closing outside the default branch, own-PR approval).
- [ ] Run check script.
- [ ] `gh repo create agentic-workflow-kit --public --source . --push`.
