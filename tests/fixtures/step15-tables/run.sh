#!/usr/bin/env bash
# Sensitivity fixture for review-changes Step 1.5's table/fence checker (#52).
#
# The program is EXTRACTED from templates/review-changes.md rather than copied,
# so it cannot drift from the shipped surface — same technique as the
# verify-runner fixture. A copy would pass while the template rotted.
#
# Exit: 0 all seeded cases behaved, 1 a regression.
set -u
cd "$(dirname "$0")/../../.." || exit 2
TPL="templates/review-changes.md"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

python3 - "$TPL" "$WORK/check.awk" <<'PY' || { echo "EXTRACTION FAILED — the anchors moved"; exit 1; }
import sys, pathlib
s = pathlib.Path(sys.argv[1]).read_text()
a = '  awk -v F="$f" \''
i = s.index(a); j = s.index("' \"$f\"", i)
prog = s[i+len(a):j]
# Loud rather than silent: an extraction that yields a program without the
# constructs under test is the same failure this fixture exists to catch.
for needle in ("isdelim", "sub(/\\r$/", "infm"):
    if needle not in prog:
        sys.exit("extracted program is missing %r" % needle)
pathlib.Path(sys.argv[2]).write_text(prog)
PY

cd "$WORK" || exit 2
printf 'a | b\n--- | ---\n1 | 2 | 3\n'                                   > t1_lf_lossy.md
sed 's/$/\r/' t1_lf_lossy.md                                             > t2_crlf_lossy.md
printf 'a | b\n--- | ---\n1 | 2\n' | sed 's/$/\r/'                       > n1_crlf_clean.md
printf -- '---\ndescription: Runs a | b\n---\n\nprose\n'                 > n2_frontmatter.md
printf -- '---\ndescription: Runs a | b\n---\n\nx | y\n--- | ---\n1 | 2 | 3\n' > t3_fm_then_table.md
# T7 — #103. An UNCLOSED frontmatter leaves `infm` set, so `infm { next }` eats
# the rest of the file and no table is examined: the check printed exactly what
# a clean run prints, in the one step whose purpose is catching corruption that
# is invisible in the diff. The seeded row is the same lossy 3-against-2 as t1,
# so the ONLY difference from a reported case is the missing closing `---`.
printf -- '---\ndescription: unclosed\n\na | b\n--- | ---\n1 | 2 | 3\n'    > t7_unclosed_fm.md
printf 'a | b\n--- | ---\n1 | 2 | 3\n'                                   > n3_fenced.md
printf '```\na | b\n--- | ---\n1 | 2 | 3\n```\n'                          > n3_fenced.md
printf 'a | b\n--- | ---\n1 | 2 | | \n'                                   > t4_empty_excess.md
printf 'a | b | c\n--- | ---\n1 | 2\n'                                     > t5_header_mismatch.md
# #50 — emphasis. t6 is the observed break: two `**`-globs in one bolded phrase.
# n4/n5 are the two shapes that must stay quiet, and n5 is what this repo itself
# ships, so a rule that fires on it would report every template here.
printf 'See **the `src/**` and `docs/**` trees** for detail.\n'             > t6_emphasis.md
printf 'See `src/**` for detail, no bold on this line.\n'                   > n4_glob_no_bold.md
printf 'A **bolded phrase** with a plain `src/lib.py` token.\n'             > n5_bold_and_code.md
# Verbatim shape of this framework's own risk-tier rows: bold OPENS AND CLOSES in
# one cell, and several **-globs sit in the next. Two risky tokens, so it survives
# a count-based rule only because of the bold-nesting test — which is what A5
# reverts. 15 lines of this exact shape were reported before that test existed.
printf '| **HIGH** | `templates/**`, `tests/**`, `scripts/**` | Full battery |\n' > n6_tier_row.md

run() { awk -v F="$1" -f "$WORK/check.awk" "$1"; }
want_hit()   { if [ -n "$(run "$1")" ]; then printf '  PASS  %s %s\n' "$1" "$2"; else printf '  FAIL  %s reported nothing — %s\n' "$1" "$2"; FAIL=1; fi; }
want_quiet() { if [ -z "$(run "$1")" ]; then printf '  PASS  %s %s\n' "$1" "$2"; else printf '  FAIL  %s reported [%s] — %s\n' "$1" "$(run "$1")" "$2"; FAIL=1; fi; }

want_hit   t1_lf_lossy.md      "a lossy row under LF is reported"
want_hit   t2_crlf_lossy.md    "a lossy row under CRLF is reported — the #52 defect: without the \\r strip NO table in the file is examined and the run is byte-identical to clean"
want_hit   t3_fm_then_table.md "frontmatter is skipped WITHOUT disabling the rest of the file — the control on n2"
want_hit   t7_unclosed_fm.md   "an unclosed frontmatter is REPORTED, not silent — without this the file's tables are all skipped and the run is byte-identical to clean (#103)"
# ⚠️ n1 is killed by NO ablation here, and that is stated rather than hidden: a
# clean CRLF table is silent whether or not the `\r` strip is present, because
# without it the table is never entered. t2 is what carries the CRLF sensitivity.
# n1's value is guarding a FUTURE change that introduces a false positive on CRLF
# input; as a measurement of today's code it is a seeded negative that cannot
# fail, which this repo's gotcha log already lists twice.
want_quiet n1_crlf_clean.md    "a clean CRLF table stays quiet (control only — no current ablation kills it)"
want_quiet n2_frontmatter.md   "YAML frontmatter whose description carries a pipe is not a malformed table"
want_quiet n3_fenced.md        "a table inside a code fence is not examined"
# NOT a negative, and the first draft of this fixture had it as one — written from
# reasoning ("empty cells lose nothing, so it must stay quiet") against a step whose
# own text says the opposite two screens up: "`| 1 | 2 | |` against a two-column
# delimiter reports, and loses nothing." The tool reports; the human adjudicates.
# Asserting the documented behaviour, not the behaviour that felt right.
want_hit   t4_empty_excess.md  "excess EMPTY cells still report — the step's documented harmless-hit class, for a human to judge"
# t5 — the HEADER branch, which had NO coverage at all. `grep -c 'header has'`
# across every other case returns 0: they all fire the ROW branch. Worse, this
# was a regression introduced by the frontmatter fix — n2_frontmatter.md was the
# only input reaching the header branch, the fix correctly silenced it, and
# nothing replaced it. So the branch that produced #52's own false positive
# became the branch with no test. Stubbing its printf flipped nothing.
want_hit   t5_header_mismatch.md "a genuine header/delimiter cell mismatch is reported" 
want_hit   t6_emphasis.md       "two backticked **-globs inside one bolded phrase are reported (#50)"
want_quiet n6_tier_row.md       "a risk-tier row: bold in one CELL, a **-glob in another — no adjacency, and 28 such lines exist in this repo"
want_quiet n4_glob_no_bold.md   "a **-glob with no bold on the line is not an emphasis risk"
want_quiet n5_bold_and_code.md  "ordinary bold beside an ordinary code span — the shape this repo ships everywhere" 

# Ablations. Each reverts one guard; the kill sets are MEASURED by running them.
ablate() {
  local label="$1" old="$2" new="$3" want="$4" got
  OLD="$old" NEW="$new" python3 - "$WORK/check.awk" "$WORK/mut.awk" <<'PY' || { printf '  FAIL  ablation %s could not be applied — its site has moved\n' "$label"; FAIL=1; return; }
import os, sys, pathlib
s = pathlib.Path(sys.argv[1]).read_text()
old, new = os.environ['OLD'], os.environ['NEW']
if s.count(old) != 1: sys.exit('site occurs %d times, not once' % s.count(old))
pathlib.Path(sys.argv[2]).write_text(s.replace(old, new))
PY
  got=""
  for f in t1_lf_lossy.md t2_crlf_lossy.md t3_fm_then_table.md t4_empty_excess.md t5_header_mismatch.md t6_emphasis.md t7_unclosed_fm.md n1_crlf_clean.md n2_frontmatter.md n3_fenced.md n4_glob_no_bold.md n5_bold_and_code.md n6_tier_row.md; do
    o="$(awk -v F="$f" -f "$WORK/mut.awk" "$f")"
    case "$f" in
      t*) [ -z "$o" ] && got="$got,$f" ;;
      n*) [ -n "$o" ] && got="$got,$f" ;;
    esac
  done
  got="${got#,}"
  if [ "$got" = "$want" ]; then printf '  PASS  ablation %s fails exactly [%s]\n' "$label" "$want"
  else printf '  FAIL  ablation %s should fail [%s], failed [%s]\n' "$label" "$want" "$got"; FAIL=1; fi
}

# Kill sets MEASURED by running each mutant, not predicted. A1's includes the clean
# CRLF file because without the strip that file's table is never entered at all —
# which is the #52 defect stated as a measurement rather than as prose.
ablate "A1 drop the CRLF strip"       'sub(/\r$/, "")' 'sub(/ZZZ$/, "")'  "t2_crlf_lossy.md"
# A2 mutates the ENTRY condition, not the `infm { next }` body: with entry intact
# the other two rules still consume both `---` lines and reset `prev`, so the body
# alone is not the guard. Measured — the first draft mutated the body and killed
# nothing, reading as a passing ablation over an unguarded rule.
ablate "A2 never enter frontmatter"   'NR == 1 && $(0) ~ /^---[ \t]*$/' 'NR == 0 && $(0) ~ /^---[ \t]*$/' "n2_frontmatter.md"
# A3 stubs the HEADER branch. It flipped NOTHING before t5 existed.
# SILENCES the branch — a first draft rewrote its printf TEXT, which still printed
# something, and `want_hit` only tests for non-empty output. A mutation that does
# not change what the assertion measures kills nothing and reads as a pass.
ablate "A3 silence the header report" 'if (cells(prev) != base)' 'if (0)' "t5_header_mismatch.md"
ablate "A4 silence the emphasis check" 'if (nrisk > 1 && index($(0), "`"))' 'if (0)' "t6_emphasis.md"
# A5 widens the emphasis rule to "any bold line with any code span" — the broad
# form that was rejected. It must break the negatives, which is WHY it was rejected.
# A5 reverts the >1 tightening to the >0 form that was actually written first.
# It must break n6 — the risk-tier row — which is why the tightening exists.
ablate "A5 emphasis rule ignores bold nesting" 'if (inb && substr(masked, i, 1) == "\001") nrisk++' 'if (substr(masked, i, 1) == "\001") nrisk++' "n6_tier_row.md"

echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || echo "SENSITIVITY REGRESSION — do not ship."
exit "$FAIL"
