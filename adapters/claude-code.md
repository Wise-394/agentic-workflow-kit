# Adapter: Claude Code

How to turn the kit's generic parts into Claude Code files.

## How the planner runs

In Claude Code, subagents can't start other subagents. So the **planner is the main session**: the user starts work in a normal session with "run issue #12" or "run sprint 2", which loads the `run-issue` or `run-sprint` skill. The other seven roles are subagents the main session starts. Setup, update, verify-skill creation, and retro edits also run in the main session, which can edit files.

## Files written

| Kit source | Project file |
|---|---|
| `roles/<role>.md` (all but planner) | `.claude/agents/<role>.md` |
| `roles/planner.md` | Added to the `run-issue` and `run-sprint` skills as "You are the planner" context, and linked from `CLAUDE.md` |
| `skills/*` | `.claude/skills/<name>/` (copied as they are, including the playbook files) |
| the project's verify skill | `.claude/skills/verify-<project>/SKILL.md` |
| shared permissions | `.claude/settings.json` |
| command guard (hook) | `.claude/hooks/agentkit-guard.sh`, registered in `.claude/settings.json` |
| per-role file guards (hooks) | `hooks` in the test-writer and coder subagent frontmatter, calling `.claude/hooks/agentkit-paths.sh` |
| `AGENTS.md` | Project root, plus a `CLAUDE.md` whose content is `@AGENTS.md` (Claude Code reads `CLAUDE.md`; the import keeps one source of rules). If `CLAUDE.md` exists, add the import line to it instead. |

Kit files that skills and roles link to (`tracker/github.md`, `safety/baseline.md`, `templates/*`) are copied into `.agentkit/kit/` keeping their paths, and the links in the copied roles and skills are rewritten to point there.

## Subagent files

```markdown
---
name: <role>
description: <the role's Purpose, one sentence>. Use when the planner hands over <the role's input>.
tools: <see table>
model: <the role's tier model (thinking, working, or light), or inherit>
---

<body of roles/<role>.md, links rewritten>
```

| Role | `tools` | `model` |
|---|---|---|
| scout | `Read, Grep, Glob, Bash` | light |
| test-writer | `Read, Grep, Glob, Edit, Write, Bash` | working |
| coder | `Read, Grep, Glob, Edit, Write, Bash` | working |
| checker | `Read, Grep, Glob, Bash` | light |
| verifier | `Read, Grep, Glob, Bash` | working |
| delivery | `Read, Grep, Glob, Bash` | light (working if `merge` is `agent`) |
| pr-reviewer | `Read, Grep, Glob, Bash` | thinking |

- `model` takes an alias (`opus`, `sonnet`, `haiku`), a full model ID, or `inherit`. Write the user's answer as given. `inherit` uses the main session's model.
- Typical suggestion for setup's model question (only a suggestion; setup always asks and writes what the user chooses): **thinking** `opus` (the main session runs the planner), **working** `sonnet`, **light** `haiku`. Aliases follow the newest model of each family, so they don't go stale. If the user's plan or budget favors fewer tiers, `sonnet` for both working and light is a safe middle.
- Escalation: Claude Code's subagent tool accepts a `model` override per call, so the planner retries a stuck test-writer or coder task by starting the same subagent with the `models.escalation` tier's model. Add that instruction to the `run-issue` skill's copy under "You are the planner".
- Step limit: if the installed version supports a per-subagent turn limit in the frontmatter (check the subagent docs), set it from `limits.workerSteps`. Otherwise the kit's retry and round limits are what bound a worker.
- The planner's model is whatever the user picks for the main session. Tell them how to set it (`/model`, or `"model"` in `.claude/settings.json`) if the thinking answer isn't `inherit`.

## Permissions

Claude Code's `.claude/settings.json` applies to the main session and every subagent. Write the baseline and `forbiddenCommands` there as `deny` rules:

```json
{
  "permissions": {
    "deny": [
      "Bash(git push --force:*)", "Bash(git push -f:*)", "Bash(git rebase:*)", "Bash(git filter-branch:*)",
      "Bash(git reset:*)", "Bash(git stash:*)", "Bash(git clean:*)", "Bash(git checkout -- :*)", "Bash(git checkout -f:*)", "Bash(git restore:*)",
      "Bash(git branch -D:*)", "Bash(git push --delete:*)", "Bash(git config --global:*)",
      "Bash(gh repo delete:*)", "Bash(gh issue delete:*)", "Bash(gh repo edit:*)", "Bash(gh pr merge --admin:*)",
      "Bash(rm -rf:*)", "Bash(rm -fr:*)", "Bash(sudo:*)",
      "Read(**/.env)", "Read(**/.env.*)", "Edit(**/.env)", "Edit(**/.env.*)",
      "Read(**/*.pem)", "Read(**/*.key)", "Edit(**/*.pem)", "Edit(**/*.key)",
      "Bash(<package manager add/install/remove/upgrade forms>:*)",
      "Bash(<package runners that download: npx, pnpm dlx, yarn dlx, uvx, pipx run>:*)",
      "Bash(<each forbiddenCommands entry>:*)"
    ]
  }
}
```

Don't add a static deny for `gh pr merge`, whatever the merge setting: a sprint must merge approved issue PRs into its sprint branch. The command guard below decides by the PR's base instead.

If the project calls installed tools through `npx` (for example `npx tsc`), allow those exact forms in `permissions.allow` instead of dropping the `npx` deny.

Deny rules match by prefix, so they miss variants (`rm -r -f`, `git push origin +main`, `bash <(curl …)`). The hooks below close those gaps. Keep the deny rules too: they're the first line, the hooks the second.

## Hooks

Hooks are scripts Claude Code runs before a tool call. A `PreToolUse` hook reads the call as JSON on stdin (`tool_name`, `tool_input`, and, inside a subagent, `agent_type`) and blocks it by exiting with code 2 and a reason on stderr. Before writing them, check the installed version's hooks docs (https://code.claude.com/docs/en/hooks) and adapt if the format differs; tell the user what you adapted.

Write the scripts in bash with `jq` if `jq` is installed; otherwise in the project's runtime (Node or Python), with the same behavior. They read settings (`merge`, branches, `forbiddenCommands`) from `.agentkit/lock.json` at run time, so a lock file change needs no new hooks. Make them executable.

**Command guard** (all sessions and subagents). In `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/agentkit-guard.sh" } ] }
    ]
  }
}
```

`agentkit-guard.sh` reads `.tool_input.command` and blocks (exit 2, with the baseline rule in the message) when the command, anywhere in it, including after `&&`, `;`, `|`, or inside `$( )`:

- runs `rm` with both a recursive and a force flag, in any order or spelling (`-rf`, `-fr`, `-r -f`, `--recursive --force`);
- runs `git push` with `-f`, `--force`, `--force-with-lease`, a `+` refspec, a `:<branch>` (delete) refspec, or a destination that is `git.integrationBranch` or `git.defaultBranch` (as `<branch>`, `HEAD:<branch>`, or `refs/heads/<branch>`);
- runs `git` with `rebase`, `filter-branch`, `reset`, `clean`, `stash`, `restore`, `checkout --`, `checkout -f`, `switch -f`, `switch --discard-changes`, `branch -D`, `push --delete`, or `config --global` (match `git` followed by the subcommand, so `npm run reset-db` passes);
- runs `gh api` with a `DELETE` method in any spelling (`-X DELETE`, `-XDELETE`, `--method DELETE`, `--method=DELETE`), or with `PUT`, `PATCH`, or `POST` on a path containing `/merge`, `/git/refs`, `/branches`, or `/protection`;
- runs `gh pr merge` with `--admin`; or runs `gh pr merge <PR>` when the lock file says `"merge": "user"` and the PR's base (`gh pr view <PR> --json baseRefName --jq .baseRefName`) doesn't match `git.sprintBranchPattern` (a merge into a sprint branch is always allowed);
- pipes or substitutes a download into a shell (`curl` or `wget` together with `sh`, `bash`, or `zsh`);
- runs `sudo`, or reads a `.env` file or key file through a shell command (`cat`, `less`, `head`, `tail`, `source`, `cp` on `.env*`, `*.pem`, `*.key`);
- matches any `forbiddenCommands` entry, a package manager's add, install, remove, or upgrade form, or a package runner that downloads.

Anything else exits 0 with no output, so the normal permission rules still apply.

**Per-role guards.** Add to the frontmatter of the generated test-writer and coder files:

```yaml
hooks:
  PreToolUse:
    - matcher: "Edit|Write|MultiEdit|NotebookEdit|Bash"
      hooks:
        - type: command
          command: '"$CLAUDE_PROJECT_DIR"/.claude/hooks/agentkit-paths.sh <role>'
```

`agentkit-paths.sh <role>` reads the call and:

- For edit tools: takes `.tool_input.file_path`, makes it relative to the project, and
  - for `test-writer`: blocks any path that doesn't match the test folders and file patterns in `docs/testing.md`;
  - for `coder`: blocks any path that matches those test patterns, plus `.agentkit/**`, `.claude/**`, `AGENTS.md`, `CLAUDE.md`, package manifests, and lock files.
- For `Bash`: blocks `git` commands other than `status`, `diff`, `log`, `show`, `grep`, and `ls-files`; blocks every `gh` command; and blocks shell writes to the paths the role may not edit (`sed -i`, `perl -i`, `tee`, `>` or `>>` redirects, `cp` or `mv` onto them). This shell check is best effort; the pr-reviewer's scope check is the backstop.

The checker commits through commit-task and the verifier writes only to `evidenceDir`; neither has edit tools. The guards don't know the plan's file list; staying inside it is checked by the checker (which commits only the task's files), the planner's task review, and the pr-reviewer.

Merge with any existing `.claude/settings.json`: keep every existing rule, and add only the missing ones.

## Check after writing

- `/agents` lists the seven subagents with their models.
- The skills appear in the skill list (`run-issue`, `run-sprint`, `plan-project`, …).
- Ask the scout subagent to create a file. It should have no edit tool.
- `/permissions` shows the deny rules, and `/hooks` lists the guard hooks.
- **Guard test.** Pipe each sample into the script and check the exit code:

  | Script | Input `tool_input` | Expect |
  |---|---|---|
  | `agentkit-guard.sh` | `{"command":"rm -fr build"}` | 2 |
  | `agentkit-guard.sh` | `{"command":"git push origin HEAD:<integrationBranch>"}` | 2 |
  | `agentkit-guard.sh` | `{"command":"gh api --method DELETE repos/o/r/git/refs/heads/x"}` | 2 |
  | `agentkit-guard.sh` | `{"command":"git status"}` | 0 |
  | `agentkit-paths.sh test-writer` | `{"file_path":"src/app.ts"}` (an app file) | 2 |
  | `agentkit-paths.sh coder` | `{"command":"sed -i s/a/b/ <a test file>"}` | 2 |

  With `"merge": "user"`, also check that `gh pr merge` on a PR whose base is a sprint branch passes and on one whose base is the integration branch is blocked; skip this if there's no such PR yet, and say so.
