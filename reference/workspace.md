# Workspace: one tracker, several code repos

A **workspace** is a folder holding several git repos (for example a backend, a frontend, and infra) whose work is planned in **one tracker repo**. Every issue, label, milestone, plan comment, and block record lives in the tracker repo. One issue may change any number of the code repos.

A project is a workspace when `.agentkit/config` has a `[workspace]` section. Without one, nothing on this page applies.

## Layout

```
<workspace>/                  the project root: sessions and runners start here
  .agentkit/config            a link to the home repo's committed config
  .agentkit/runs/ …           runtime files (lock, results) for the whole workspace
  AGENTS.md, CLAUDE.md, docs/ links into a committed repo, so every role finds them at the root
  <home repo>/.agentkit/config  the committed config
  <repo-a>/  <repo-b>/  …     the code repos, each a clone with its own origin
```

```ini
[tracker]
	repo = owner/home-repo        # issues live here only
[workspace]
	root = ..                     # the workspace folder, relative to the home repo
	repo = repo-a                 # one line per code repo folder, in the order work usually flows
	repo = repo-b
[git]                             # shared defaults
	integrationBranch = main
[commands]                        # shared defaults (often empty in a workspace)
[repo "repo-a"]
	slug = owner/repo-a           # its GitHub repo: PRs live there
	integrationBranch = dev       # overrides [git]
	check = …                     # overrides [commands]: check, quick, test, format, rules
```

## How the script works in a workspace

- Commands that touch git or a pull request act in **one code repo** and need `--repo <folder>`: `branch`, `progress`, `sync`, `check-task`, `check-full`, `open-pr`, `review-post`, `can-merge`, `merge`, `ensure-sprint`, `sync-sprint`, `pr-body`. `base` takes it optionally. PR numbers are per repo, so `merge 41 --repo repo-b` is a different PR from `merge 41 --repo repo-a`.
- `rescue` without `--repo` rescues every repo.
- `agentkit repos` lists the code repos; `agentkit repos <N>` lists the repos that already have issue N's branch; `agentkit repos --sprint <milestone>` lists those with the sprint branch.
- Each repo gets the issue's branch (same name everywhere) and, for milestone issues, its own `sprint/m<k>` branch and draft sprint PR, created lazily by `branch` only in repos the issue touches.
- An issue becomes `status:merged` (or closes) only when **none of its PRs is still open in any repo**. Until then `merge` prints `waiting on <repo>#<PR>`.
- `pick` returns `awaiting-merge <refs>` only when every open sprint PR is ready, and `wrap` while any is open. `wrap get|set` keeps the phase on every open sprint PR.
- Housekeeping closes a sprint's issues only after the sprint PRs in **every** repo are merged.

## Rules for the planner and the roles

1. **Plan per repo.** The plan's header lists **Repos** (the folders this issue changes). Every task names its **Repo**, and its files are relative to that repo. One task never spans two repos; split it.
2. **Order across repos.** When one repo consumes another's contract (a frontend calling a new API), the producing repo's tasks come first, and its contract goes in **Contracts** with the repo named.
3. **Branch** in each repo the plan lists: `agentkit branch <N> --repo <r>`. Write every branch and base into the plan.
4. **Commands run in the task's repo:** `agentkit check-task <N> <k>/<n> "<msg>" --repo <r> --tests … --files …`. Workers `cd` into `<workspace>/<r>` and use that repo's commands (`git config -f .agentkit/config --get repo.<r>.<command>`, else `commands.<command>`).
5. **One PR per touched repo.** Each body starts with `Closes <tracker repo>#<N>` (the full `owner/repo#N` form outside the tracker repo, so GitHub links it) and links the issue's other PRs. Review and merge each PR on its own; the issue is done when the last one merges.
6. **Verify the whole change.** The verifier runs `docs/verify.md` against every touched repo together (for example the backend and the frontend running at once).
7. **Commits** use `<type>(<tracker repo>#<N>): …` outside the tracker repo.
