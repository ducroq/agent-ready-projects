#!/usr/bin/env bash
# Seeded cases for scripts/gotcha-headers.sh (curate Step 0 sub-step 2).
# Each positive is a defect the script exists to report; each negative pins a shape it
# must not report. Every case asserts the exit status AND a line of output, so a script
# that exits correctly while printing nothing (or the wrong list) still fails.
set -u
cd "$(dirname "$0")/../../.." || exit 2
S=scripts/gotcha-headers.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
FAIL=0

check() {   # id, file, want-rc, grep -E pattern that must appear, [pattern that must NOT appear]
  local id=$1 f=$2 want=$3 must=$4 mustnot=${5-} out rc
  out=$(bash "$S" "$f" 2>&1); rc=$?
  if [ "$rc" -ne "$want" ]; then
    printf '  FAIL  %s — exit %s, expected %s\n' "$id" "$rc" "$want"; FAIL=1; return
  fi
  if ! printf '%s\n' "$out" | grep -qE -- "$must"; then
    printf '  FAIL  %s — output lacks /%s/\n' "$id" "$must"; FAIL=1; return
  fi
  if [ -n "$mustnot" ] && printf '%s\n' "$out" | grep -qE -- "$mustnot"; then
    printf '  FAIL  %s — output contains /%s/\n' "$id" "$mustnot"; FAIL=1; return
  fi
  printf '  PASS  %s\n' "$id"
}

# A well-formed log. The comment holds a fake entry and fake table rows, as the
# template's does; neither may be listed or counted.
cat > "$T/clean.md" <<'EOF'
# Gotcha Log

<!-- Template:
### Fake entry (YYYY-MM-DD)
**Problem**: fake
| 9999-01-01 | fake row | 1 | x |
-->

### First (2026-01-01)
**Problem**: one.

### Second (2026-01-02)
**Problem**: two.
#### A sub-heading inside an entry is not an entry

## Promoted

<!-- prose -->
### Promoted rows sit under this nested heading
| Date | Gotcha | Occurrences | Promoted to |
|------|--------|-------------|-------------|
| 2026-01-01 | real row | 2 | topic.md |

## Mechanized

| 2026-02-02 | mechanized row | lint.sh | live | x |
EOF
check n1-grouping-note    "$T/clean.md" 0 'note: line [0-9]+ is a ### heading with no'
# ^ a ### with no Problem (a grouping heading) is a note, not a failure; strip it for the plain negative:
grep -v '^### Promoted rows' "$T/clean.md" > "$T/clean2.md"
check n2-reconciles       "$T/clean2.md" 0 '^2 entries, 2 \*\*Problem\*\* lines, 3 section headings$'
check n3-comment-skipped  "$T/clean2.md" 0 'real row' 'Fake entry|fake row'
check n4-promoted-bounded "$T/clean2.md" 0 'real row' 'mechanized row'

# Level-aware: rows after a ### nested under ## Promoted still belong to it.
printf '# Log\n### E (2026-01-01)\n**Problem**: p\n## Promoted\n### 2026\n**Problem**: q\n| a | row-under-nested | 1 | x |\n## Next\n| b | not-promoted | 1 | x |\n' > "$T/nested.md"
check p1-level-aware      "$T/nested.md" 0 'row-under-nested' 'not-promoted'

# Only the first Promoted heading is the table.
printf '# Log\n### E (2026-01-01)\n**Problem**: p\n## Promoted\n| a | first-table | 1 | x |\n## Promoted (archive)\n| b | second-table | 1 | x |\n' > "$T/twoprom.md"
check n7-first-promoted   "$T/twoprom.md" 0 'first-table' 'second-table'

# Rows inside a comment under Promoted are real: adopters fill the template's commented
# table (3 of 37 real logs, 2026-11-13 corpus run). A heading in that comment is not.
printf '# Log\n### E (2026-01-01)\n**Problem**: p\n## Promoted\n<!-- table:\n| d | commented-row | 1 | x |\n### not-a-heading\n-->\n' > "$T/commented.md"
check n8-commented-rows   "$T/commented.md" 0 'commented-row' 'not-a-heading'

# Positives: each is reported (p3 as a note, the rest as exit 1).
printf '# Log\n**Problem**: orphan\n### E (2026-01-01)\n**Problem**: p\n' > "$T/orphan.md"
check p2-orphan-problem   "$T/orphan.md" 1 'line 2: \*\*Problem\*\* under no entry heading'
printf '# Log\n### E (2026-01-01)\n**Problem**: p\n### Lost (2026-01-02)\nno problem line\n' > "$T/noprob.md"
check p3-entry-no-problem "$T/noprob.md" 0 'note: line 4 is a ### heading with no \*\*Problem'
printf '# Log\n### E (2026-01-01)\n**Problem**: p\n**Problem**: merged entry\n' > "$T/two.md"
check p4-two-under-one    "$T/two.md" 1 'line 2 owns 2 \*\*Problem\*\* lines'

# CRLF must give the same answer as LF.
sed 's/$/\r/' "$T/clean2.md" > "$T/crlf.md"
check n5-crlf             "$T/crlf.md" 0 '^2 entries, 2 \*\*Problem\*\* lines'

# Nothing examined is exit 2, never a clean 0.
check e1-missing          "$T/absent.md" 2 'NO READABLE LOG'
printf '<!--\n### only in a comment\n**Problem**: x\n-->\n' > "$T/allcomment.md"
check e2-no-headings      "$T/allcomment.md" 2 'NO HEADINGS'
check e3-no-argument      ""               2 'NO READABLE LOG'

# The shipped template must reconcile: it is what every adopter starts from.
check n6-template         templates/gotcha-log.md 0 '^2 entries, 2 \*\*Problem\*\* lines'

[ "$FAIL" -eq 0 ] && echo "All gotcha-headers fixture cases passed." || { echo "gotcha-headers fixture FAILED."; exit 1; }
