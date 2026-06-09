#!/usr/bin/env bash
# Structural lint for agent-ready-projects.
# Catches drift between CLAUDE.md, memory/MEMORY.md, templates, and disk state.
# Run from any directory; the script cd's to repo root.

set -u
cd "$(dirname "$0")/../.."

ISSUES=0
fail() { printf 'FAIL  %s\n' "$1"; ISSUES=$((ISSUES + 1)); }

echo "[1/4] CLAUDE.md path references resolve on disk"
while IFS= read -r path; do
  [ -e "$path" ] || fail "CLAUDE.md references \`$path\` but it does not exist"
done < <(grep -oE '`[A-Za-z0-9_./-]+\.(md|yml|yaml|json|sh)`' CLAUDE.md | tr -d '`' | sort -u)

while IFS= read -r path; do
  [ -d "$path" ] || fail "CLAUDE.md references directory \`$path\` but it does not exist"
done < <(grep -oE '`[A-Za-z0-9_./-]+/`' CLAUDE.md | tr -d '`' | sort -u)

echo "[2/4] memory/MEMORY.md index integrity"
while IFS= read -r name; do
  [ -e "memory/$name" ] || fail "memory/MEMORY.md references \`$name\` but it does not exist"
done < <(grep -oE '`project_[a-z_]+\.md`' memory/MEMORY.md | tr -d '`' | sort -u)

for f in memory/project_*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  grep -qF "$name" memory/MEMORY.md || fail "memory/$name exists but is not referenced in MEMORY.md"
done

echo "[3/4] skill template embedded SKILL.md frontmatter"
for f in templates/*.md; do
  grep -q 'SAVE AS:.*\.claude/skills/' "$f" || continue
  block=$(awk '/<!--/{c=1} c{print} /-->/{c=0}' "$f")
  printf '%s\n' "$block" | grep -qE '^[[:space:]]*name:' \
    || fail "$f: skill template missing \`name:\` in SAVE AS comment"
  printf '%s\n' "$block" | grep -qE '^[[:space:]]*description:' \
    || fail "$f: skill template missing \`description:\` in SAVE AS comment"
done

echo "[4/4] top-level YAML frontmatter closure"
for f in templates/*.md templates/checklists/*.md templates/physics-tests/*.md memory/*.md; do
  [ -f "$f" ] || continue
  [ "$(head -1 "$f")" = '---' ] || continue
  head -30 "$f" | awk 'NR>1 && /^---$/ {found=1; exit} END {exit !found}' \
    || fail "$f: opens with \`---\` but no closing \`---\` within first 30 lines"
done

echo
if [ $ISSUES -eq 0 ]; then
  echo "All lint checks passed."
  exit 0
else
  echo "$ISSUES issue(s) found."
  exit 1
fi
