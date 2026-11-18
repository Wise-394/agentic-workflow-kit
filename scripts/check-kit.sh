#!/usr/bin/env bash
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
fail=0

report() {
  echo "FAIL: $1"
  fail=1
}

required=(
  README.md SETUP.md UPDATE.md VERSION CHANGELOG.md LICENSE
  safety/baseline.md tracker/github.md
  templates/AGENTS.md templates/lock.json templates/plan-comment.md templates/pr-body.md templates/review.md
  templates/docs/clean-code.md templates/docs/testing.md templates/docs/patterns.md
  templates/issue.md templates/prd-issue.md templates/sprint-pr-body.md templates/verification-issue.md
  templates/examples/plan-comment.md templates/examples/review.md
  adapters/opencode.md adapters/claude-code.md
)
for f in "${required[@]}"; do
  [ -f "$f" ] || report "missing required file $f"
done

roles=(planner scout test-writer coder checker verifier delivery pr-reviewer)
for r in "${roles[@]}"; do
  [ -f "roles/$r.md" ] || report "missing role roles/$r.md"
done

skills=(run-issue run-sprint write-plan playbooks pr-review verify plan-project split-issue rules-check retro)
for s in "${skills[@]}"; do
  [ -f "skills/$s/SKILL.md" ] || report "missing skill skills/$s/SKILL.md"
done

while IFS= read -r f; do
  dir="$(basename "$(dirname "$f")")"
  head -1 "$f" | grep -qx -- '---' || { report "$f has no frontmatter"; continue; }
  name="$(sed -n '2,/^---$/p' "$f" | sed -n 's/^name: *//p')"
  desc="$(sed -n '2,/^---$/p' "$f" | sed -n 's/^description: *//p')"
  [ "$name" = "$dir" ] || report "$f name '$name' does not match folder '$dir'"
  case "$desc" in
    "Use when"*) ;;
    *) report "$f description must start with 'Use when'" ;;
  esac
done < <(find skills -name SKILL.md 2>/dev/null)

generic=$(find . -name '*.md' -o -name '*.json' -o -name '*.sh' | grep -v -E '^\./(adapters|docs|examples|\.git)/' | grep -v -E '^\./(README|CHANGELOG)\.md$' | grep -v -E '^\./scripts/check-kit\.sh$')
leak='claude|opencode|anthropic|openai|gpt-|sonnet|opus|haiku|gemini|deepseek|llama|mistral'
leak_cased='Cursor|Codex'
while IFS= read -r f; do
  [ -z "$f" ] && continue
  hits=$( { grep -n -i -E "\b($leak)" "$f"; grep -n -E "\b($leak_cased)\b" "$f"; } || true)
  [ -n "$hits" ] && report "$f names a tool or model: $(echo "$hits" | head -3 | tr '\n' ' ')"
done <<< "$generic"

placeholders=$(grep -rn -E '\b(TODO|TBD|FIXME)\b' --include='*.md' --include='*.json' . | grep -v -E '^\./(\.git|scripts|docs)/' || true)
[ -n "$placeholders" ] && report "placeholders found: $(echo "$placeholders" | head -3 | tr '\n' ' ')"

while IFS= read -r f; do
  dir="$(dirname "$f")"
  while IFS= read -r link; do
    target="${link%%#*}"
    [ -z "$target" ] && continue
    case "$target" in http*|mailto:*) continue ;; esac
    [ -e "$dir/$target" ] || report "$f links to missing $target"
  done < <(grep -o -E '\]\([^)]+\)' "$f" | sed -E 's/^\]\(//; s/\)$//')
done < <(find . -name '*.md' -not -path './.git/*')

while IFS= read -r ref; do
  r="${ref#roles/}"; r="${r%.md}"
  [ -f "roles/$r.md" ] || report "reference to missing role $ref"
done < <(grep -rho -E 'roles/[a-z-]+\.md' --include='*.md' . | sort -u)

while IFS= read -r ref; do
  s="${ref#skills/}"; s="${s%%/*}"
  [ -d "skills/$s" ] || report "reference to missing skill $ref"
done < <(grep -rho -E 'skills/[a-z-]+/' --include='*.md' . | grep -v 'skills/<' | sort -u)

plan=templates/plan-comment.md
while IFS= read -r section; do
  [ -z "$section" ] && continue
  grep -q -E "^#+ ($section)\b|\*\*$section:?\*\*" "$plan" \
    || report "a role or skill reads plan section '$section', but $plan has no such section"
done < <(grep -rh -E "plan( comment)?'s \*\*" --include='*.md' roles skills \
  | sed -E "s/^.*plan( comment)?'s //" \
  | grep -o -E '\*\*[A-Z][A-Za-z ]+\*\*' | tr -d '*' | sort -u)

# Tracker actions named in roles and skills must exist in the tracker file.
actions=$(grep -oE '^\*\*[a-z]+(-[a-z]+)+\*\*' tracker/github.md | tr -d '*' | sort -u)
not_actions=" ${roles[*]} ${skills[*]} update-pr needs-input read-only in-progress in-review "
while IFS= read -r name; do
  [ -z "$name" ] && continue
  case "$not_actions" in *" $name "*) continue ;; esac
  echo "$actions" | grep -qx -- "$name" || report "roles or skills use tracker action '$name', which tracker/github.md doesn't define"
done < <(grep -rhoE '(\b[Rr]un|Delivery:|[Dd]elivery|with|then) `?[a-z]+(-[a-z]+)+`?' roles skills \
  | grep -oE '[a-z]+(-[a-z]+)+' | sort -u)

# Lock file fields named anywhere must exist in the lock template.
while IFS= read -r field; do
  key="${field#*.}"
  grep -q "\"$key\"" templates/lock.json || report "docs use lock field '$field', which templates/lock.json doesn't define"
done < <(grep -rhoE '`(limits|models|commands|git|tracker)\.[a-zA-Z]+' --include='*.md' --exclude-dir=docs --exclude-dir=.git . \
  | tr -d '`' | sort -u)

lock_version=$(sed -n 's/.*"kitVersion": *"\([^"]*\)".*/\1/p' templates/lock.json)
[ "$lock_version" = "$(cat VERSION)" ] || report "templates/lock.json kitVersion $lock_version does not match VERSION $(cat VERSION)"

if [ "$fail" -eq 0 ]; then
  echo "kit check: PASS"
else
  echo "kit check: FAIL"
fi
exit "$fail"
