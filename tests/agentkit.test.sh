#!/usr/bin/env bash
# Offline tests for scripts/agentkit: a fake gh (tests/fake-gh) and a local bare repo as origin.
# Needs bash, git, and jq. Run: tests/agentkit.test.sh
set -uo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/agentkit-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
pass=0; fail=0

ok()   { pass=$((pass+1)); echo "ok   $1"; }
bad()  { fail=$((fail+1)); echo "FAIL $1"; [ -z "${2:-}" ] || echo "     got: $2"; }
expect() { # expect <name> <expected substring> <actual>
  case "$3" in *"$2"*) ok "$1";; *) bad "$1" "$3";; esac
}
expect_not() { case "$3" in *"$2"*) bad "$1" "$3";; *) ok "$1";; esac; }

# ---------- fixture -----------------------------------------------------------

fresh() { # fresh: a new project, origin, and fake tracker
  rm -rf "$T/w" "$T/o.git" "$T/fake"; mkdir -p "$T/fake/comments" "$T/fake/reviews" "$T/fake/graphql"
  export FAKE="$T/fake" AGENTKIT_GH="$KIT/tests/fake-gh" W="$T/w"
  git init -q --bare -b main "$T/o.git"
  git init -q -b main "$W"; cd "$W"
  git config user.email t@t; git config user.name t; git config commit.gpgsign false
  git remote add origin "$T/o.git"
  mkdir -p .agentkit src test
  cat > .agentkit/config <<'EOF'
[tracker]
	repo = o/r
	agentLogin = agent
[git]
	integrationBranch = main
	defaultBranch = main
[commands]
	check = true
	test = test -f {file}
	quick = true
[limits]
	issueSessions = 2
EOF
  printf '.agentkit/*\n!.agentkit/config\n' > .gitignore
  echo 'x' > src/a.js
  git add -A; git commit -q -m init; git push -q -u origin main
  echo '[]' > "$FAKE/issues.json"; echo '[]' > "$FAKE/prs.json"
  echo '[{"number":1,"title":"M1: First","state":"open"},{"number":2,"title":"M2: Second","state":"open"}]' > "$FAKE/milestones.json"
  : > "$FAKE/log"
}
issue() { # issue <N> <labels csv> [milestone-number|-] [author] [assoc] [body]
  local n="$1" labels="$2" m="${3:--}" au="${4:-agent}" as="${5:-NONE}" body="${6:-Goal}"
  jq --argjson n "$n" --arg l "$labels" --arg m "$m" --arg au "$au" --arg as "$as" --arg b "$body" \
     --slurpfile ms "$FAKE/milestones.json" \
    '. += [{number: $n, state: "open", title: ("Issue " + ($n|tostring)), body: $b,
            user: {login: $au}, author_association: $as, assignees: [],
            labels: ($l | split(",") | map(select(. != "")) | map({name: .})),
            milestone: (if $m == "-" then null else ($ms[0][] | select(.number == ($m|tonumber)) | {number, title}) end)}]' \
    "$FAKE/issues.json" > "$FAKE/i.tmp" && mv "$FAKE/i.tmp" "$FAKE/issues.json"
}
pr() { # pr <N> <state> <head> <base> [title] [draft]
  jq --argjson n "$1" --arg s "$2" --arg h "$3" --arg b "$4" --arg t "${5:-PR $1}" --argjson d "${6:-false}" \
    '. += [{number: $n, state: $s, headRefName: $h, baseRefName: $b, title: $t, isDraft: $d, body: "", headRefOid: "abc", statusCheckRollup: []}]' \
    "$FAKE/prs.json" > "$FAKE/p.tmp" && mv "$FAKE/p.tmp" "$FAKE/prs.json"
}
comment() { # comment <N> <login> <assoc> <created_at> <body>
  [ -f "$FAKE/comments/$1.json" ] || echo '[]' > "$FAKE/comments/$1.json"
  jq --arg u "$2" --arg a "$3" --arg t "$4" --arg b "$5" --argjson id "$RANDOM$RANDOM" \
    '. += [{id: $id, user: {login: $u}, author_association: $a, created_at: $t, body: $b}]' \
    "$FAKE/comments/$1.json" > "$FAKE/c.tmp" && mv "$FAKE/c.tmp" "$FAKE/comments/$1.json"
}
ak() { (cd "$W" && bash "$KIT/scripts/agentkit" "$@" 2>&1); }
labels() { jq -r ".[] | select(.number == $1) | [.labels[].name] | join(\",\")" "$FAKE/issues.json"; }
state() { jq -r ".[] | select(.number == $1) | .state" "$FAKE/issues.json"; }

# ---------- ready -------------------------------------------------------------

fresh
issue 2 type:feature 1
issue 3 type:feature 1 stranger NONE
issue 4 type:feature,status:in-progress 1
issue 5 type:feature,status:blocked 1
issue 6 type:feature 1 stranger NONE
jq '(.[] | select(.number == 6) | .labels) += [{name: "agentkit:ready"}]' "$FAKE/issues.json" > "$FAKE/i" && mv "$FAKE/i" "$FAKE/issues.json"
echo '{"data":{"repository":{"issue":{"lastEditedAt":null,"timelineItems":{"nodes":[{"createdAt":"2026-01-01T00:00:00Z","label":{"name":"agentkit:ready"}}]}}}}}' > "$FAKE/graphql/6.json"
issue 7 type:verify 1
pr 12 MERGED feat/12-other main "feat(#12): other"
pr 20 MERGED sprint/m2 main "Sprint 2"
expect "ready: trusted issue starts" "start" "$(ak ready 2)"
expect "ready: no fuzzy match on #12 or 'Sprint 2'" "start" "$(ak ready 2)"
expect "ready: untrusted author is refused" "untrusted" "$(ak ready 3)"
expect "ready: in-progress resumes" "resume" "$(ak ready 4)"
expect "ready: blocked is not ready" "status:blocked" "$(ak ready 5)"
expect "ready: agentkit:ready label after last edit trusts it" "start" "$(ak ready 6)"
expect "ready: verify issues are wrap-up only" "verify issues" "$(ak ready 7)"
pr 30 MERGED feat/2-issue-2 sprint/m1 "feat(#2): Issue 2"
expect "ready: exact merged PR head means done" "merged PR already exists" "$(ak ready 2)"

# ---------- blockers ----------------------------------------------------------

fresh
issue 2 type:feature,status:merged 1
issue 3 type:feature 1 agent NONE "Blocked by #2"
issue 4 type:feature,status:merged 2
issue 5 type:feature 1 agent NONE "Blocked by #4"
pr 31 MERGED feat/2-issue-2 sprint/m1 "feat(#2): Issue 2"
pr 32 MERGED feat/4-issue-4 sprint/m2 "feat(#4): Issue 4"
expect "blockers: merged into the same sprint clears" "start" "$(ak ready 3)"
expect "blockers: merged into another sprint does not" "blocked by #4" "$(ak ready 5)"

# ---------- pick and pause ----------------------------------------------------

fresh
issue 2 type:feature 1
issue 3 type:feature,status:in-progress 1
issue 9 type:feature 2
expect "pick: resume before start" "resume 3" "$(ak pick)"
jq 'map(if .number == 3 then .labels = [{name:"type:feature"},{name:"status:merged"}] else . end)' "$FAKE/issues.json" > "$FAKE/i" && mv "$FAKE/i" "$FAKE/issues.json"
expect "pick: lowest ready issue of the active milestone" "start 2" "$(ak pick)"
issue 50 type:chore - agent NONE
jq '(.[] | select(.number == 50) | .labels) += [{name: "agentkit:pause"}]' "$FAKE/issues.json" > "$FAKE/i" && mv "$FAKE/i" "$FAKE/issues.json"
expect "pick: pause label pauses" "paused" "$(ak pick)"
jq 'map(select(.number != 50))' "$FAKE/issues.json" > "$FAKE/i" && mv "$FAKE/i" "$FAKE/issues.json"
touch "$W/.agentkit/PAUSE"; expect "pick: pause file pauses" "paused" "$(ak pick)"; rm "$W/.agentkit/PAUSE"
jq 'map(if .number == 2 then .labels = [{name:"type:feature"},{name:"status:blocked"}] else . end)' "$FAKE/issues.json" > "$FAKE/i" && mv "$FAKE/i" "$FAKE/issues.json"
pr 40 OPEN sprint/m1 main "Sprint M1" true
expect "pick: nothing ready, sprint has merged work → wrap" "wrap 1" "$(ak pick)"
jq 'map(if .number == 40 then .isDraft = false else . end)' "$FAKE/prs.json" > "$FAKE/p" && mv "$FAKE/p" "$FAKE/prs.json"
expect "pick: sprint PR ready → awaiting-merge" "awaiting-merge 40" "$(ak pick)"
expect "status: JSON with blocked issue" '"blocked":[2]' "$(ak status)"
expect "base: milestone issue targets its sprint branch" "sprint/m1" "$(ak base 2)"
issue 60 type:bug -
expect "base: issue without milestone targets integration" "main" "$(ak base 60)"

# ---------- housekeeping: splits, investigations, old labels, unblock --------

fresh
issue 2 type:feature,status:needs-input 1
comment 2 owner OWNER 2026-01-02T00:00:00Z "Blue."
issue 3 type:feature 1
issue 4 type:feature,status:split 1
comment 4 agent OWNER 2026-01-01T00:00:00Z "<!-- agentkit:split #5 #6 -->"
issue 5 type:feature 1; issue 6 type:feature 1
jq 'map(if .number == 5 or .number == 6 then .state = "closed" else . end)' "$FAKE/issues.json" > "$FAKE/i" && mv "$FAKE/i" "$FAKE/issues.json"
issue 7 type:investigation 1
comment 7 agent OWNER 2026-01-01T00:00:00Z "<!-- agentkit:findings -->
Answer"
out="$(ak housekeeping)"
expect "housekeeping: old needs-input becomes blocked" "status:blocked" "$(labels 2)"
expect_not "housekeeping: a comment never un-blocks" "needs-input" "$(labels 2)"
expect "housekeeping: reports the old label" "older kit" "$out"
printf 'Needs a Stripe key.\nAdd STRIPE_KEY to the runner.\n' > "$T/why"
expect "block: sets the label" "#3 blocked" "$(ak block 3 "$T/why")"
expect "block: status" "status:blocked" "$(labels 3)"
expect "result: blocked carries the reason" 'Needs a Stripe key.' "$(ak result blocked 3)"
expect "pick: only blocked issues left is idle" "every remaining issue is blocked" "$(ak pick)"
expect "unblock: clears the label" "#3 unblocked" "$(ak unblock 3)"
expect_not "unblock: status gone" "status:blocked" "$(labels 3)"
expect "unblock: refuses an issue that isn't blocked" "not blocked" "$(ak unblock 3)"
expect "housekeeping: split closes when parts are closed" "closed" "$(state 4)"
expect "housekeeping: investigation with findings closes" "closed" "$(state 7)"

# ---------- housekeeping: merged sprint PR -------------------------------------

fresh
git -C "$W" config -f .agentkit/config git.integrationBranch dev
issue 2 type:feature,status:merged 1
issue 3 type:feature,status:blocked 1
issue 4 type:verify 1
pr 40 MERGED sprint/m1 dev "Sprint M1"
jq 'map(if .number == 40 then .body = "Closes #2\nCloses #4" else . end)' "$FAKE/prs.json" > "$FAKE/p" && mv "$FAKE/p" "$FAKE/prs.json"
out="$(ak housekeeping)"
expect "sprint merged: issue closed" "closed" "$(state 2)"
expect "sprint merged: verify issue closed" "closed" "$(state 4)"
expect "sprint merged: blocked issue carried over" "carried over to M2" "$out"
expect "sprint merged: milestone closed" "milestone 1: closed" "$out"

# ---------- result ------------------------------------------------------------

fresh
issue 2 type:feature 1
expect "result: false 'merged' becomes error" '"outcome":"error"' "$(ak result merged 2)"
jq 'map(if .number == 2 then .labels += [{name:"status:merged"}] else . end)' "$FAKE/issues.json" > "$FAKE/i" && mv "$FAKE/i" "$FAKE/issues.json"
expect "result: true 'merged' passes" '"outcome":"merged"' "$(ak result merged 2)"
expect "result: writes last-result.json" "merged" "$(cat "$W/.agentkit/last-result.json")"
expect "result: unknown outcome is error" '"outcome":"error"' "$(ak result done)"

# ---------- preflight lock ----------------------------------------------------

fresh
expect "preflight: ok and takes the lock" "ok" "$(ak preflight)"
expect "preflight: a second runner is refused" "another runner" "$(ak preflight)"
ak result idle >/dev/null
expect "preflight: result releases the lock" "ok" "$(ak preflight)"

# ---------- sessions ----------------------------------------------------------

fresh
issue 2 type:feature 1
expect "session: first" "session 1 of 2" "$(ak session 2)"
expect "session: second" "session 2 of 2" "$(ak session 2)"
expect "session: over the limit blocks" "blocked" "$(ak session 2)"
expect "session: label set" "status:blocked" "$(labels 2)"

# ---------- git: branch, check-task, rescue -----------------------------------

fresh
issue 2 type:feature 1
br="$(ak branch 2 | tail -1)"
expect "branch: named from type and title, from the sprint branch" "feat/2-issue-2" "$br"
expect "branch: sprint branch created on origin" "sprint/m1" "$(git -C "$W" ls-remote --heads origin)"
echo 'test' > "$W/test/a.test.js"; echo 'y' > "$W/src/a.js"; echo 'stray' > "$W/src/stray.js"
out="$(ak check-task 2 1/2 "feat(#2): add a" --tests test/a.test.js --files src/a.js)"
expect "check-task: passes" "Result: ALL PASS" "$out"
expect "check-task: stray file reported, not committed" "src/stray.js" "$out"
expect "check-task: commit has the Task trailer" "Task: 1/2" "$(git -C "$W" log -1 --format=%B)"
expect_not "check-task: stray file not in the commit" "stray" "$(git -C "$W" show --stat HEAD)"
expect "progress: reads trailers from origin" "1/2" "$(ak progress 2)"
git -C "$W" config -f .agentkit/config commands.quick false
echo 'z' > "$W/src/a.js"
out="$(ak check-task 2 2/2 "feat(#2): more" --files src/a.js)"
expect "check-task: failing check doesn't commit" "Result: FAILED" "$out"
expect "check-task: no commit made" "Task: 1/2" "$(git -C "$W" log -1 --format=%B)"
git -C "$W" config -f .agentkit/config commands.quick ''
git -C "$W" config -f .agentkit/config commands.check ''
expect "check-task: refuses when no check command is configured" "no command configured" "$(ak check-task 2 2/2 m --files src/a.js)"
out="$(ak rescue)"
expect "rescue: keeps dirty work as a WIP commit" "rescued uncommitted work" "$out"
expect "rescue: WIP commit has no Task trailer" "Rescue: true" "$(git -C "$W" log -1 --format=%B)"
expect "rescue: pushed" "" "$(git -C "$W" log --oneline '@{u}..HEAD')"
echo 'SECRET=1' > "$W/.env.local"
expect "rescue: refuses secret-like files" "refusing to commit secret-like file" "$(ak rescue)"
rm "$W/.env.local"

# ---------- merge rules -------------------------------------------------------

fresh
issue 2 type:feature 1
pr 40 OPEN sprint/m1 main "Sprint M1"
expect "can-merge: sprint PRs are refused" "refused: sprint PRs are merged by the user" "$(ak can-merge 40)"
pr 41 OPEN feat/2-issue-2 sprint/m1 "feat(#2): Issue 2"
expect "can-merge: no approval, no merge" "review: FAIL" "$(ak can-merge 41)"
echo '[{"user":{"login":"agent"},"body":"<!-- agentkit:review verdict=approve sha=abc -->\nok"}]' > "$FAKE/reviews/41.json"
jq 'map(if .number == 41 then .body = "**Checks:** ALL PASS on abc\n## Evidence\n| 1 | x | PASS | out |" else . end)' "$FAKE/prs.json" > "$FAKE/p" && mv "$FAKE/p" "$FAKE/prs.json"
out="$(ak merge 41)"
expect "merge: approval on head + checks merges" "merged #41 into sprint/m1" "$out"
expect "merge: issue marked status:merged" "status:merged" "$(labels 2)"
echo '[{"user":{"login":"agent"},"body":"<!-- agentkit:review verdict=approve sha=old -->"}]' > "$FAKE/reviews/41.json"
expect "can-merge: approval on an old head fails" "review: FAIL" "$(ak can-merge 41)"

# ---------- fixes from the final review ----------------------------------------

fresh
issue 2 type:feature 1
comment 2 agent OWNER 2026-01-01T00:00:00Z "<!-- agentkit:plan -->
# Plan"
expect "ready: an answered issue with a plan resumes" "resume" "$(ak ready 2)"
ak preflight >/dev/null
expect "preflight: second runner says locked" "locked" "$(ak preflight)"
ak result error --keep-lock >/dev/null
expect "result --keep-lock leaves the first runner's lock" "locked" "$(ak preflight)"
ak result idle >/dev/null
expect "milestone: M1 resolves to its number" "1" "$(ak milestone M1)"
echo 'junk' > "$W/notes.txt"
expect "rescue: untracked files on main are left alone" "left alone" "$(ak rescue)"
expect "check-task: refuses on the wrong branch" "not issue #2's branch" "$(ak check-task 2 1/1 m --files src/a.js)"
rm "$W/notes.txt"
ak branch 2 >/dev/null
out="$(ak check-task 2 1/2 "feat(#2): nothing new" --files src/a.js)"
expect "check-task: no changes still records the task" "Task: 1/2" "$(git -C "$W" log -1 --format=%B)"
echo 'k' > "$W/src/id_rsa"
expect "rescue: refuses key files" "secret-like" "$(ak rescue)"
rm "$W/src/id_rsa"

fresh
issue 2 type:feature,status:split 1
comment 2 agent OWNER 2026-01-01T00:00:00Z "<!-- agentkit:split #3 #4 -->"
issue 3 type:feature,status:merged 1; issue 4 type:feature,status:merged 1
pr 33 MERGED feat/3-issue-3 sprint/m1 "feat(#3): Issue 3"; pr 34 MERGED feat/4-issue-4 sprint/m1 "feat(#4): Issue 4"
issue 5 type:feature 1 agent NONE "Blocked by #2"
expect "blockers: a split whose parts are merged clears" "start" "$(ak ready 5)"
expect "result: a split ends the session with continue" '"outcome":"continue"' "$(ak result continue 2)"
expect "result: parked no longer exists" '"outcome":"error"' "$(ak result parked 2)"

fresh
git -C "$W" config -f .agentkit/config git.integrationBranch dev
jq 'map(select(.number == 1))' "$FAKE/milestones.json" > "$FAKE/m" && mv "$FAKE/m" "$FAKE/milestones.json"
issue 3 type:feature,status:blocked 1
pr 40 MERGED sprint/m1 dev "Sprint M1"
expect "carry-over: creates the next milestone when none exists" "created milestone M2: Carry-over" "$(ak housekeeping)"

# ---------- workspace: one tracker repo, code in several repos ----------------
# Layout: $T/ws/{be,fe} are git repos; tickets live in be's tracker (o/be).
# The config is committed in be and linked from $T/ws/.agentkit/config.

wsfresh() {
  rm -rf "$T/ws" "$T/be.git" "$T/fe.git" "$T/fake"; mkdir -p "$T/fake/comments" "$T/fake/reviews" "$T/fake/graphql"
  export FAKE="$T/fake" AGENTKIT_GH="$KIT/tests/fake-gh" WS="$T/ws"
  local r
  for r in be fe; do
    git init -q --bare -b main "$T/$r.git"
    git init -q -b main "$WS/$r"
    git -C "$WS/$r" config user.email t@t; git -C "$WS/$r" config user.name t; git -C "$WS/$r" config commit.gpgsign false
    git -C "$WS/$r" remote add origin "$T/$r.git"
    mkdir -p "$WS/$r/src" "$WS/$r/test"; echo x > "$WS/$r/src/a.js"
    printf '.agentkit/*\n!.agentkit/config\n' > "$WS/$r/.gitignore"
  done
  mkdir -p "$WS/be/.agentkit"
  cat > "$WS/be/.agentkit/config" <<'EOF2'
[tracker]
	repo = o/be
	agentLogin = agent
[workspace]
	root = ..
	repo = be
	repo = fe
[git]
	integrationBranch = main
	defaultBranch = main
[commands]
	check = true
	test = test -f {file}
	quick = true
[repo "be"]
	slug = o/be
[repo "fe"]
	slug = o/fe
	integrationBranch = dev
	quick = test -f src/a.js
EOF2
  for r in be fe; do git -C "$WS/$r" add -A; git -C "$WS/$r" commit -q -m init; git -C "$WS/$r" push -q -u origin main; done
  mkdir -p "$WS/.agentkit"; ln -s ../be/.agentkit/config "$WS/.agentkit/config"
  echo '[]' > "$FAKE/issues.json"; echo '[]' > "$FAKE/prs.json"
  echo '[{"number":1,"title":"M1: First","state":"open"},{"number":2,"title":"M2: Second","state":"open"}]' > "$FAKE/milestones.json"
  : > "$FAKE/log"
}
wak() { (cd "$WS" && bash "$KIT/scripts/agentkit" "$@" 2>&1); }
rpr() { # rpr <repo-slug> <N> <state> <head> <base> [title] [draft]
  pr "$2" "$3" "$4" "$5" "${6:-PR $2}" "${7:-false}"
  jq --argjson n "$2" --arg r "$1" 'map(if .number == $n and .repo == null then .repo = $r else . end)' "$FAKE/prs.json" > "$FAKE/p" && mv "$FAKE/p" "$FAKE/prs.json"
}

wsfresh
issue 2 type:feature 1
expect "ws: repos lists every code repo with its slug" "fe	o/fe" "$(wak repos)"
expect "ws: repo commands need --repo" "needs --repo" "$(wak branch 2)"
expect "ws: unknown repo is refused" "unknown repo" "$(wak branch 2 --repo nope)"
br="$(wak branch 2 --repo fe | tail -1)"
expect "ws: branch created in the named repo" "feat/2-issue-2" "$br"
expect "ws: branch checked out in fe" "feat/2-issue-2" "$(git -C "$WS/fe" rev-parse --abbrev-ref HEAD)"
expect "ws: fe sprint branch on fe's origin" "sprint/m1" "$(git -C "$WS/fe" ls-remote --heads origin)"
expect "ws: fe integration branch from its own config" "dev" "$(git -C "$WS/fe" ls-remote --heads origin)"
expect_not "ws: be untouched" "sprint/m1" "$(git -C "$WS/be" ls-remote --heads origin)"
expect "ws: repos <N> lists repos with a branch for the issue" "fe" "$(wak repos 2)"
expect_not "ws: repos <N> leaves out untouched repos" "be" "$(wak repos 2)"
echo t > "$WS/fe/test/a.test.js"
out="$(wak check-task 2 1/1 "feat(o/be#2): a" --repo fe --tests test/a.test.js --files src/a.js)"
expect "ws: check-task runs in the repo with its commands" "Result: ALL PASS" "$out"
expect "ws: check-task commits in fe" "Task: 1/1" "$(git -C "$WS/fe" log -1 --format=%B)"
git -C "$WS/be" config -f .agentkit/config repo.fe.quick false
expect "ws: per-repo command overrides the shared one" "Result: FAILED" "$(wak check-task 2 1/1 m --repo fe --files src/a.js)"
issue 60 type:bug -
expect "ws: base is per repo" "dev" "$(wak base 60 --repo fe)"
wak result idle >/dev/null
expect "ws: runtime files live in the workspace" "idle" "$(cat "$WS/.agentkit/last-result.json")"
expect "ws: preflight checks every repo" "ok" "$(wak preflight --no-lock)"

wsfresh
issue 2 type:feature,status:in-review 1
rpr o/fe 41 OPEN feat/2-issue-2 sprint/m1 "feat(o/be#2): Issue 2"
rpr o/be 41 OPEN feat/2-issue-2 sprint/m1 "feat(#2): Issue 2"
echo '[{"user":{"login":"agent"},"body":"<!-- agentkit:review verdict=approve sha=abc -->\nok"}]' > "$FAKE/reviews/41.json"
jq 'map(.body = "**Checks:** ALL PASS on abc\n## Evidence\n| 1 | x | PASS | out |")' "$FAKE/prs.json" > "$FAKE/p" && mv "$FAKE/p" "$FAKE/prs.json"
out="$(wak merge 41 --repo fe)"
expect "ws: merge acts on the repo's PR" "merged #41 into sprint/m1" "$out"
expect "ws: merge waits for the issue's other PRs" "waiting on" "$out"
expect_not "ws: issue not merged while be's PR is open" "status:merged" "$(labels 2)"
expect_not "ws: ready doesn't treat a partial merge as done" "merged PR already exists" "$(wak ready 2)"
wak merge 41 --repo be >/dev/null
expect "ws: last PR merged marks the issue merged" "status:merged" "$(labels 2)"

wsfresh
issue 2 type:feature,status:merged 1
rpr o/fe 50 OPEN sprint/m1 dev "Sprint M1" false
rpr o/be 51 OPEN sprint/m1 dev "Sprint M1" true
expect "ws: a draft sprint PR in any repo means wrap, not awaiting-merge" "wrap 1" "$(wak pick)"
jq 'map(.isDraft = false)' "$FAKE/prs.json" > "$FAKE/p" && mv "$FAKE/p" "$FAKE/prs.json"
expect "ws: every sprint PR ready → awaiting-merge" "awaiting-merge" "$(wak pick)"
expect "ws: awaiting-merge names each repo's sprint PR" "o/be#51" "$(wak pick)"
expect "ws: wrap get reads the open sprint PRs" "build 0" "$(wak wrap get 1)"
expect "ws: wrap set writes every open sprint PR" "on o/fe#50" "$(wak wrap set 1 verify)"
expect "ws: rescue without --repo covers every repo" "fe: rescue: clean" "$(wak rescue)"
jq 'map(if .number == 50 then .state = "MERGED" | .body = "Closes o/be#2" else . end)' "$FAKE/prs.json" > "$FAKE/p" && mv "$FAKE/p" "$FAKE/prs.json"
wak housekeeping >/dev/null
expect "ws: issue stays open while another repo's sprint PR is open" "open" "$(state 2)"
jq 'map(if .number == 51 then .state = "MERGED" | .body = "Closes #2" else . end)' "$FAKE/prs.json" > "$FAKE/p" && mv "$FAKE/p" "$FAKE/prs.json"
wak housekeeping >/dev/null
expect "ws: issue closes when every repo's sprint PR merged" "closed" "$(state 2)"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
