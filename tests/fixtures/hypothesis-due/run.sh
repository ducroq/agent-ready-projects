#!/usr/bin/env bash
# Seeded cases for scripts/hypothesis-due.sh (curate Step 0 sub-step 5), plus ablations
# showing each guarded behaviour can fail.
set -euo pipefail
cd "$(dirname "$0")"
SCRIPT=../../../scripts/hypothesis-due.sh
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

cat > "$WORK/log.md" <<'LOG'
# Hypothesis Log

<!-- template example, must be ignored
### H-900 — commented entry
**Review by:** 2000-01-01
-->

```markdown
### H-901 — fenced example, must be ignored
**Review by:** 2000-01-01
```

~~~
### H-902 — tilde-fenced example, must be ignored
~~~

### [2020-01-01] H-001 — past date, template spelling
**Review by:** 2026-01-01 — backstop.
**Revisit trigger:** something fires.
**Status:** open (blocked on X)

### H-002 — future date, repo spelling, second mention ignored
**Review by**: 2027-06-01, or after five runs.
**Revisit trigger**: never.
**Position**: the **Review by** was once 2000-01-01.

### H-003 — no date at all
**Review by**: when the arm reads.

### H-006 — inline fields, downstream spelling
**Position.** x. **Trigger.** The next draft. **Review by** 2026-02-02. **Status.** Open: trigger fired.

### H-017 — not yet triggered must not be flagged
**Review by**: 2027-01-01
**Status**: open, not yet triggered

```x``` is inline code, not a fence

### H-007 — dormant by status
**Review by**: 2027-01-01
**Status**: dormant

## Dormant

### H-008 — dormant by section
**Review by**: 2027-01-01

## Unresolved questions (not a closed section)

### H-009 — open under a section that merely contains "resolved"
**Review by**: 2027-01-01

### H-014 — date or condition, condition wording
**Review by**: 2027-12-31, or after five runs, whichever is first.

### H-015 — date beyond the display cut
**Review by**: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 2026-03-03.
**Status**: TRIGGERED, awaiting review.

## resolved (lower case still closes)

### H-016 — resolved in lower case, must be ignored
**Review by**: 2000-01-01

## Resolved

### H-004 — resolved, must be ignored
**Review by**: 2000-01-01

## Archive

### H-010 — archived, must be ignored
**Review by**: 2000-01-01
LOG
printf '### H-005 — no review-by line\n**Revisit trigger**: x\n' > "$WORK/missing.md"
printf '### H-011 — CRLF\r\n**Review by**: 2020-05-05\r\n' > "$WORK/crlf.md"
printf '# Log\n\nNo entries here.\n' > "$WORK/noheads.md"
printf '### H-020\n**Review by**: 2027-01-01\n\n```\n### H-021 hidden by an unclosed fence\n' > "$WORK/fence.md"
printf '### H-012 — before\n**Review by**: 2027-01-01\n<!-- never closed\n### H-013\n' > "$WORK/unclosed.md"
: > "$WORK/many.md"
for i in $(seq 1 11); do printf '### H-%03d\n**Review by**: 2027-01-01\n\n' "$i" >> "$WORK/many.md"; done

check() { if eval "$2"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s\n' "$1"; FAIL=1; fi; }
run() { set +e; OUT="$(bash "$1" "$2" "${3-2026-11-14}" 2>&1)"; RC=$?; set -e; }

cases() {   # $1 = script under test
  run "$1" "$WORK/log.md"
  check "C1 exit 0 on a well-formed log"                 '[ "$RC" -eq 0 ]'
  check "C2 eight open, two dormant, three past"         'grep -qF "== 8 open, 2 dormant, 3 past" <<<"$OUT"'
  check "C3 past date flagged, heading date ignored"     'grep -qE "H-001 .*DATE PAST: 2026-01-01" <<<"$OUT"'
  check "C4 future date not flagged"                     '! grep -qE "H-002 .*DATE PAST" <<<"$OUT"'
  check "C5 both field spellings read"                   'grep -qxF "   review by: 2026-01-01 — backstop." <<<"$OUT" && grep -qF "review by: 2027-06-01" <<<"$OUT"'
  check "C6 commented, fenced, resolved, archived ignored" '! grep -qE "H-90[012]|H-004|H-010|H-016" <<<"$OUT"'
  check "C20 date-or-condition asks about the condition" 'grep -qE "H-014 .*or a condition — has it been met" <<<"$OUT"'
  check "C21 date found beyond the display cut"         'grep -qE "H-015 .*DATE PAST: 2026-03-03" <<<"$OUT" && grep -qF " …" <<<"$OUT"'
  check "C24 a negated trigger is not flagged"          '! grep -qE "H-017 .*status says triggered" <<<"$OUT"'
  check "C25 inline triple backticks are not a fence"   'grep -qE "^[0-9]+: ### H-007" <<<"$OUT"'
  check "C22 a triggered status is flagged"             'grep -qE "H-015 .*status says triggered" <<<"$OUT" && grep -qE "H-006 .*status says triggered" <<<"$OUT"'
  check "C9 inline fields read, value ends at next label" 'grep -qxF "   review by: 2026-02-02." <<<"$OUT" && grep -qxF "   trigger:   The next draft." <<<"$OUT"'
  check "C10 status surfaced"                            'grep -qxF "   status:    Open: trigger fired." <<<"$OUT" && grep -qxF "   status:    open (blocked on X)" <<<"$OUT"'
  check "C11 first Review-by mention wins"               '! grep -qF "was once" <<<"$OUT"'
  check "C12 a dateless Review-by is asked about"        'grep -qE "H-003 .*no date: a condition" <<<"$OUT"'
  check "C13 dormant by status and by section"           'grep -qE "H-007 .*\[dormant\]" <<<"$OUT" && grep -qE "H-008 .*\[dormant\]" <<<"$OUT"'
  check "C14 a section merely containing resolved is open" 'grep -qE "^[0-9]+: ### H-009" <<<"$OUT"'
  run "$1" "$WORK/missing.md"
  check "C7 missing Review-by exits 1 and is named"      '[ "$RC" -eq 1 ] && grep -qF "NO Review-by" <<<"$OUT"'
  run "$1" "$WORK/nope.md"
  check "C8 unreadable file exits 2"                     '[ "$RC" -eq 2 ]'
  run "$1" "$WORK/crlf.md"
  check "C15 CRLF lines parse"                           'grep -qxF "   review by: 2020-05-05" <<<"$OUT"'
  run "$1" "$WORK/noheads.md"
  check "C16 no ### heading exits 2, not 0 open"         '[ "$RC" -eq 2 ] && grep -qF "NO ### HEADINGS" <<<"$OUT"'
  run "$1" "$WORK/unclosed.md"
  check "C17 an unclosed comment exits 2"                '[ "$RC" -eq 2 ] && grep -qF "UNCLOSED COMMENT" <<<"$OUT"'
  run "$1" "$WORK/fence.md"
  check "C23 an unclosed fence exits 2"                 '[ "$RC" -eq 2 ] && grep -qF "UNCLOSED FENCE" <<<"$OUT"'
  run "$1" "$WORK/many.md"
  check "C18 more than 10 open is flagged"               'grep -qF "More than ~10 open" <<<"$OUT"'
  run "$1" "$WORK/log.md" "2026-13"
  check "C19 a malformed date argument exits 2"          '[ "$RC" -eq 2 ] && grep -qF "BAD DATE" <<<"$OUT"'
}

cases "$SCRIPT"

# Ablations: each mutant must turn the named case red. A moved site is reported, not fatal.
ablate() {
  local label="$1" old="$2" new="$3" want="$4" m="$WORK/mut.sh" got
  if ! OLD="$old" NEW="$new" python3 - "$SCRIPT" "$m" <<'PY'
import os, sys
s = open(sys.argv[1]).read(); o = os.environ['OLD']
if s.count(o) != 1: sys.exit('mutation site occurs %d times' % s.count(o))
open(sys.argv[2], 'w').write(s.replace(o, os.environ['NEW']))
PY
  then printf '  FAIL  ablation %s — mutation site moved\n' "$label"; FAIL=1; return; fi
  got="$(FAIL=0; cases "$m" | grep FAIL || true)"
  if grep -qF "  FAIL  $want " <<<"$got"; then printf '  PASS  ablation %s kills %s\n' "$label" "$want"
  else printf '  FAIL  ablation %s did not kill %s\n' "$label" "$want"; FAIL=1; fi
}
ablate "A1 no comment skip"        'incom { if (index($0, "-->")) incom = 0; next }' 'incom { incom = 0 }' "C6"
ablate "A2 no fence skip"          'fence { next }' 'fence { }' "C6"
ablate "A3 resolved counted"       'closed = (h ~ /^##? +(resolved|closed|archive)/)' 'closed = 0' "C6"
ablate "A4 no date compare"        'if (d < today)' 'if (0)' "C3"
ablate "A5 one spelling only"      'sub(/^[^*]*\*\*[:.]?[ \t]*/, "", s)' 'sub(/^[^*]*\*\*[ \t]*/, "", s)' "C5"
ablate "A6 missing not fatal"      'exit 1 }' '}' "C7"
ablate "A7 label must start line"  'cur && rb == "" && /\*\*Review by/' 'cur && rb == "" && /^\*\*Review by/' "C9"
ablate "A8 value runs on"          'if (match(s, /\*\*[A-Z][^*]*\*\*/)) s = substr(s, 1, RSTART - 1)' '' "C9"
ablate "A9 no status"              'cur && st == "" && /\*\*Status/' 'cur && 0' "C10"
ablate "A10 last mention wins"     'cur && rb == "" && /\*\*Review by/' 'cur && /\*\*Review by/' "C11"
ablate "A11 dateless not asked"    '} else flag = "   [no date: a condition — has it been met?]"' '}' "C12"
ablate "A12 dormant not separated" 'dorm = insecdorm || tolower(st) ~ /^dormant/' 'dorm = 0' "C13"
ablate "A13 unanchored closed"     '/^##? +(resolved|closed|archive)/' '/resolved|closed|archive/' "C14"
ablate "A14 CRLF kept"             '{ sub(/\r+$/, "") }' '{ }' "C15"
ablate "A15 no-heading is clean"   'if (!heads) { print "NO ### HEADINGS outside comments and fences — nothing was examined"; exit 2 }' '' "C16"
ablate "A16 unclosed is clean"     'if (incom) { printf "UNCLOSED COMMENT from line %d — the rest of the file was not examined\n", comline; exit 2 }' '' "C17"
ablate "A17 no clutter warning"    'if (n > 10) print' 'if (0) print' "C18"
ablate "A18 tilde fence ignored"   '/^ ? ? ?(```|~~~)/' '/^ ? ? ?```/' "C6"
ablate "A19 no condition flag"     'if (cond) flag = flag' 'if (0) flag = flag' "C20"
ablate "A20 date after the cut"    'return s }' 'return length(s) > 220 ? substr(s, 1, 220) " …" : s }' "C21"
ablate "A21 no triggered flag"     'if (tolower(st) ~ /trigger(ed| fired)/ &&' 'if (0 &&' "C22"
ablate "A22 unclosed fence clean"  'if (fence) { printf "UNCLOSED FENCE' 'if (0) { printf "UNCLOSED FENCE' "C23"
ablate "A24 negation not guarded"  '&& tolower(st) !~ /(not( yet)?|un|never) ?trigger/' '' "C24"
ablate "A25 inline code is a fence" 'if (c == "`" && index(substr(run, k + 1), "`")) next' '' "C1"
ablate "A23 case-sensitive closed" 'h = tolower($0)' 'h = $0' "C6"

echo
[ "$FAIL" -eq 0 ] && echo "All hypothesis-due fixture cases passed." || echo "HYPOTHESIS-DUE REGRESSION — do not ship."
exit "$FAIL"
