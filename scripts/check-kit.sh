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
  templates/AGENTS.md templates/lock.json templates/plan-comment.md templates/pr-body.md
  adapters/opencode.md adapters/claude-code.md
)
for f in "${required[@]}"; do
  [ -f "$f" ] || report "missing required file $f"
done

roles=(planner scout test-writer coder checker verifier delivery pr-reviewer)
for r in "${roles[@]}"; do
  [ -f "roles/$r.md" ] || report "missing role roles/$r.md"
done

skills=(run-issue run-sprint write-plan playbooks pr-review verify plan-project)
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
leak='claude|opencode|anthropic|openai|gpt-|sonnet|opus|haiku|gemini|deepseek|cursor|codex|llama|mistral'
while IFS= read -r f; do
  [ -z "$f" ] && continue
  hits=$(grep -n -i -E "\b($leak)" "$f" || true)
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

if [ "$fail" -eq 0 ]; then
  echo "kit check: PASS"
else
  echo "kit check: FAIL"
fi
exit "$fail"
