#!/usr/bin/env bash
# Structural lint for agent-ready-projects.
# Catches drift between CLAUDE.md, memory/MEMORY.md, templates, and disk state.
# Run from any directory; the script cd's to repo root.

set -u
cd "$(dirname "$0")/../.."

ISSUES=0
fail() { printf 'FAIL  %s\n' "$1"; ISSUES=$((ISSUES + 1)); }

echo "[1/6] CLAUDE.md path references resolve on disk"
while IFS= read -r path; do
  [ -e "$path" ] || fail "CLAUDE.md references \`$path\` but it does not exist"
done < <(grep -oE '`[A-Za-z0-9_./-]+\.(md|yml|yaml|json|sh)`' CLAUDE.md | tr -d '`' | sort -u)

while IFS= read -r path; do
  # The two documented maintainer dirs (.claude/, memory/) are gitignored and may be
  # legitimately absent from a fresh clone — exempt them when absent AND still gitignored.
  # Scoped to an explicit allowlist, NOT a blanket "any gitignored dir" skip, so a shipped
  # dir mistakenly added to .gitignore and then deleted still FAILs.
  # (A stale ref to an exempted dir under its exact gitignored name is out of scope here.)
  [ -d "$path" ] && continue
  case "$path" in
    .claude/|memory/) git check-ignore -q "$path" && continue ;;
  esac
  fail "CLAUDE.md references directory \`$path\` but it does not exist"
done < <(grep -oE '`[A-Za-z0-9_./-]+/`' CLAUDE.md | tr -d '`' | sort -u)

echo "[2/6] memory/MEMORY.md index integrity"
while IFS= read -r name; do
  [ -e "memory/$name" ] || fail "memory/MEMORY.md references \`$name\` but it does not exist"
done < <(grep -oE '`project_[a-z_]+\.md`' memory/MEMORY.md | tr -d '`' | sort -u)

for f in memory/project_*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  grep -qF "$name" memory/MEMORY.md || fail "memory/$name exists but is not referenced in MEMORY.md"
done

echo "[3/6] skill template embedded SKILL.md frontmatter"
for f in templates/*.md; do
  grep -q 'SAVE AS:.*\.claude/skills/' "$f" || continue
  block=$(awk '/<!--/{c=1} c{print} /-->/{c=0}' "$f")
  printf '%s\n' "$block" | grep -qE '^[[:space:]]*name:' \
    || fail "$f: skill template missing \`name:\` in SAVE AS comment"
  printf '%s\n' "$block" | grep -qE '^[[:space:]]*description:' \
    || fail "$f: skill template missing \`description:\` in SAVE AS comment"
done

echo "[4/6] installed skills are loadable"
# Rule 3 checks that each template CARRIES installable frontmatter in its SAVE AS
# comment. It cannot check that an install CONVERTED it. That gap is not theoretical:
# an adopter repo was found holding all three skills copied verbatim, SAVE AS comment
# and all, frontmatter still inside the comment — none had ever registered, silently,
# for months. A skill that does not load fails by doing nothing, so nothing reports it.
# These are the reference installs every adopter copies; if they break, the copies do.
for d in .claude/skills/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  f="${d}SKILL.md"   # $d already ends in /
  if [ ! -f "$f" ]; then
    fail ".claude/skills/$name/ has no SKILL.md — the directory registers nothing"
    continue
  fi
  if [ "$(head -1 "$f" | tr -d '\r')" != '---' ]; then
    fail "$f: no YAML frontmatter — will not register as a skill"
    continue
  fi
  # An unclosed block is not frontmatter: the fields below would be read from the body,
  # so a file that cannot register would pass. Rule 5 makes this check for templates/;
  # .claude/skills/*/SKILL.md is not in its glob, so it is made here.
  if ! head -40 "$f" | tr -d '\r' | awk 'NR>1 && /^---$/{found=1; exit} END{exit !found}'; then
    fail "$f: frontmatter opens but never closes within 40 lines — will not register"
    continue
  fi
  fm_name=$(tr -d '\r' < "$f" | awk 'NR>1 && /^---$/{exit} /^name:/{sub(/^name:[[:space:]]*/,""); sub(/[[:space:]]+$/,""); gsub(/^["'"'"']|["'"'"']$/,""); print; exit}')
  [ -n "$fm_name" ] || fail "$f: frontmatter has no \`name:\`"
  [ "$fm_name" = "$name" ] || fail "$f: frontmatter name \`$fm_name\` does not match directory \`$name\`"
  tr -d '\r' < "$f" | awk 'NR>1 && /^---$/{exit} /^description:[[:space:]]*[^[:space:]]/{found=1} END{exit !found}' \
    || fail "$f: frontmatter has no non-empty \`description:\` — the agent is never told when to use it"
done

echo "[5/6] top-level YAML frontmatter closure"
for f in templates/*.md templates/checklists/*.md templates/physics-tests/*.md memory/*.md; do
  [ -f "$f" ] || continue
  [ "$(head -1 "$f")" = '---' ] || continue
  head -30 "$f" | awk 'NR>1 && /^---$/ {found=1; exit} END {exit !found}' \
    || fail "$f: opens with \`---\` but no closing \`---\` within first 30 lines"
done

echo "[6/6] skill templates and reference installs agree"
# Rules 3 and 4 check each side in isolation; neither compares them. Factored into
# its own script so tests/fixtures/skill-template-sync/ can drive it against seeded
# drift — a run over this repo finds nothing, which is also what a broken check
# looks like.
#
# Hence the two guards below, and they are the point of this block rather than
# defensive garnish. `done < <(cmd)` discards the command's exit status entirely,
# so the first draft of this rule printed "All lint checks passed" and exited 0
# with the checker deleted, renamed, or exiting 3. Empty stdout from a checker
# that never ran is byte-identical to a clean result — the same trap the fixture
# for this rule was hardened against, reintroduced one file away in the path that
# actually gates commits.
sync_out=$(mktemp); sync_err=$(mktemp)
bash tests/lint/skill-sync.sh templates .claude/skills >"$sync_out" 2>"$sync_err"; sync_rc=$?
cat "$sync_err"
sync_pairs=$(sed -n 's/^ *\([0-9]\{1,\}\) template\/install pair(s) compared.*/\1/p' "$sync_err")
if [ $sync_rc -gt 1 ]; then
  fail "rule 6 checker could not run (exit $sync_rc) — this rule checked nothing"
elif [ -z "$sync_pairs" ]; then
  fail "rule 6 checker produced no coverage line — this rule checked nothing"
elif [ "$sync_pairs" -eq 0 ]; then
  # The coverage line alone is not enough: a checker that runs fine against an
  # empty or renamed .claude/skills/ reports "0 pair(s) compared" and exits 0,
  # which is the same green as five clean pairs. Rule 4 does not fire either —
  # its glob simply finds nothing to iterate.
  fail "rule 6 compared 0 template/install pairs — .claude/skills/ is empty or misnamed"
else
  while IFS= read -r line; do
    [ -n "$line" ] && fail "$line"
  done < "$sync_out"
fi
rm -f "$sync_out" "$sync_err"

echo
if [ $ISSUES -eq 0 ]; then
  echo "All lint checks passed."
  exit 0
else
  echo "$ISSUES issue(s) found."
  exit 1
fi
