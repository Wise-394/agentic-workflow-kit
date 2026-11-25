#!/usr/bin/env bash
# Structural checks for the kit itself. Run before every commit: tests/check-kit.sh
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
fail=0
report() { echo "FAIL: $1"; fail=1; }

required=(
  README.md LICENSE .claude-plugin/plugin.json .claude-plugin/marketplace.json
  scripts/agentkit reference/safety.md reference/tracker.md reference/orchestrator.md
  templates/config templates/AGENTS.md templates/plan-comment.md templates/pr-body.md templates/review.md
  templates/issue.md templates/sprint-pr-body.md templates/verification-issue.md
  templates/docs/prd.md templates/docs/design.md templates/docs/verify.md
  templates/docs/clean-code.md templates/docs/testing.md templates/docs/patterns.md
  adapters/claude-code.md adapters/opencode.md adapters/codex.md
)
for f in "${required[@]}"; do [ -f "$f" ] || report "missing required file $f"; done

for r in scout builder verifier pr-reviewer; do
  [ -f "roles/$r.md" ] || report "missing role roles/$r.md"
done
for f in roles/*.md; do
  case "$(basename "$f" .md)" in scout|builder|verifier|pr-reviewer) ;; *) report "unexpected role $f";; esac
  grep -q 'reference/safety.md' "$f" || report "$f doesn't list the safety baseline as an input"
done

# Entry skills: exactly these, with frontmatter; references have none.
entry=(agentkit-setup agentkit-plan agentkit-run-issue agentkit-run-sprint agentkit-next)
for s in "${entry[@]}"; do [ -f "skills/$s/SKILL.md" ] || report "missing entry skill skills/$s/SKILL.md"; done
while IFS= read -r f; do
  dir="$(basename "$(dirname "$f")")"
  head -1 "$f" | grep -qx -- '---' || { report "$f has no frontmatter"; continue; }
  name="$(sed -n '2,/^---$/p' "$f" | sed -n 's/^name: *//p')"
  desc="$(sed -n '2,/^---$/p' "$f" | sed -n 's/^description: *//p')"
  [ "$name" = "$dir" ] || report "$f name '$name' does not match folder '$dir'"
  case "$name" in agentkit-*) ;; *) report "$f: entry skills are prefixed agentkit-";; esac
  case "$desc" in "Use when"*) ;; *) report "$f description must start with 'Use when'";; esac
  grep -q 'Find the kit' "$f" || report "$f doesn't say how to find <kit>"
done < <(find skills -name SKILL.md)
while IFS= read -r f; do
  head -1 "$f" | grep -qx -- '---' && report "$f is a reference but has frontmatter (it would load as a skill)"
done < <(find skills -path '*/references/*.md')

# Kit files name no tool or model (adapters, README, the plugin manifest, and tests may).
leak='claude|opencode|anthropic|openai|gpt-|sonnet|opus|haiku|gemini|deepseek|llama|mistral'
while IFS= read -r f; do
  hits=$( { grep -n -i -E "\b($leak)" "$f"; grep -n -E "\b(Cursor|Codex)\b" "$f"; } | grep -v 'CLAUDE.md' || true)
  [ -n "$hits" ] && report "$f names a tool or model: $(echo "$hits" | head -3 | tr '\n' ' ')"
done < <(find skills roles reference templates scripts -type f)

placeholders=$(grep -rn -E '\b(TODO|TBD|FIXME)\b' skills roles reference templates adapters README.md || true)
[ -n "$placeholders" ] && report "placeholders found: $(echo "$placeholders" | head -3 | tr '\n' ' ')"

# Relative links resolve inside the kit.
while IFS= read -r f; do
  dir="$(dirname "$f")"
  while IFS= read -r link; do
    target="${link%%#*}"
    [ -z "$target" ] && continue
    case "$target" in http*|mailto:*) continue ;; esac
    [ -e "$dir/$target" ] || report "$f links to missing $target"
    case "$(cd "$dir" && realpath -m "$target")" in "$root"*) ;; *) report "$f links outside the kit: $target";; esac
  done < <(grep -o -E '\]\([^)]+\)' "$f" | sed -E 's/^\]\(//; s/\)$//')
done < <(find . -name '*.md' -not -path './.git/*' -not -path './tests/sandbox/*')

# Every `agentkit <command>` in the docs exists in the script.
cmds=" $(sed -n 's/^  \([a-z|-]*\))$/\1/p' scripts/agentkit | tr '|' ' ' | tr '\n' ' ') "
while IFS= read -r c; do
  case "$cmds" in *" $c "*) ;; *) report "docs use 'agentkit $c', which scripts/agentkit doesn't define";; esac
done < <(grep -rhoE '`agentkit [a-z][a-z-]*' skills roles reference templates adapters README.md | sed 's/`agentkit //' | sort -u)

# Every config key named in the docs exists in templates/config.
while IFS= read -r key; do
  sec="${key%%.*}"; k="${key#*.}"
  git config -f templates/config --get-regexp "^$sec\.$k\$" >/dev/null 2>&1 \
    || report "docs use config key '$key', which templates/config doesn't define"
done < <(grep -rhoE '`(limits|commands|models|slots|merge|git|tracker)\.[a-zA-Z]+' skills roles reference templates adapters README.md | tr -d '`' | sort -u)

# Plan sections that roles and skills read exist in the plan template.
plan=templates/plan-comment.md
while IFS= read -r section; do
  [ -z "$section" ] && continue
  grep -q -E "^#+ ($section)\b|\*\*$section:?\*\*" "$plan" || report "a role or skill reads plan section '$section', but $plan has no such section"
done < <(grep -rh -E "plan( comment)?'s \*\*" roles skills | sed -E "s/^.*plan( comment)?'s //" | grep -o -E '\*\*[A-Z][A-Za-z ]+\*\*' | tr -d '*' | sort -u)

bash -n scripts/agentkit || report "scripts/agentkit has a syntax error"
[ -x scripts/agentkit ] || report "scripts/agentkit is not executable"
for f in .claude-plugin/*.json; do python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" 2>/dev/null || report "$f is not valid JSON"; done

if [ "$fail" -eq 0 ]; then echo "kit check: PASS"; else echo "kit check: FAIL"; fi
exit "$fail"
