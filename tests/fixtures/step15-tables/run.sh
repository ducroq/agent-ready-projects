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
# T8/T9 — #144, reported by an adopter. T7 proves the guard FIRES; it says nothing
# about whether the message is TRUE. `infm { next }` sits above the fence and
# emphasis block as well as the table block, so an unclosed frontmatter loses all
# three checks while the message named only tables. T9 is the control and is the
# whole argument: the SAME body with the closing `---` present must report three
# findings of three DIFFERENT kinds, so T8's single line is a measured loss and
# not an empty body. The counts asserted below were run, not predicted.
FMBODY='\na | b\n--- | ---\n1 | 2 | 3\nSee **the `src/**` and `docs/**` trees** for detail.\n```\nunclosed fence\n'
printf -- "---\ndescription: x\n----$FMBODY" > t8_fm_loses_all.md
printf -- "---\ndescription: x\n---$FMBODY"  > t9_fm_control.md
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

# --- #150 / #151, all four reported by adopters and all four reproduced here
# before being fixed. Each seeds a class this repo holds ZERO instances of, so a
# run over the real tree cannot tell a working guard from a disabled one.
#
# t11 — a fenced block indented FOUR spaces IS scanned as markdown, so its table
# reports. That is a DOCUMENTED false positive, not an oversight (#150): three
# attempts to widen the fence rule each bought a worse class — one SILENCED a whole
# well-formed file — and the class has zero instances in a 5,168-file estate. This
# row pins the documented behaviour so a fourth attempt has to argue with a test.
printf -- '- item:\n\n    ```sh\n    | a | b |\n    |---|---|\n    | 1 | 2 | 3 |\n    ```\n' > t11_indent_fence_fp.md
# n11 — 10 estate files open `---` then a `#` YAML comment. Deciding the
# frontmatter on the first non-blank line reported their own frontmatter as a
# malformed table, which is the #52 class the skip exists to prevent.
printf -- '---\n# yaml-language-server: schema=x\ndescription: Runs a | b\n---\n\nprose\n' > n11_fm_comment.md
# n12 — a QUOTED key is legal YAML and equally common.
printf -- '---\n"description": Runs a | b\n---\n\nprose\n' > n12_fm_quoted.md
# t10 — a leading `---` is a valid CommonMark thematic break. Opening the
# frontmatter skip on line 1 alone silenced this whole WELL-FORMED file, losing a
# genuine lossy row: the silencing direction, which is the one a denominator
# guard must not have. Asserted with want_exact, because the pre-fix behaviour
# also printed something — the WRONG thing — and want_hit cannot tell them apart.
printf -- '---\n\n# Title\n\n| a | b |\n| - | - |\n| 1 | 2 | 3 |\n' > t10_hr_table.md
# n9 — ⚠️ THE ROW CI CAUGHT AND THIS MACHINE CANNOT. The first fix used
# `substr($(0),1,3)`, which is bytes in mawk and CHARACTERS in gawk under a
# UTF-8 locale — so it passed locally and failed on the runner, taking six
# ablation kill-sets with it. There is no gawk here; do not read a green local
# run as portability evidence for this row.
# A UTF-8 BOM is invisible in every editor and defeats `NR == 1`, so the
# frontmatter skip never fires and the file reports the EXACT false positive that
# skip was added to remove.
printf '\xef\xbb\xbf---\ndescription: a | piped value\n---\n\n# T\n' > n9_bom_fm.md
# n10 — Obsidian writes `---`, a BLANK LINE, then the first key. Confirming the
# frontmatter on line 2 alone — the fix as first proposed — reports these files'
# own frontmatter as a malformed table. Two such files exist in a 5,168-file
# estate, so the blank-line tolerance is measured, not defensive.
printf -- '---\n\nkanban-plugin: a | b\n---\n\nprose\n' > n10_kanban_fm.md

# AWKF is indirection with a purpose: it lets an ablation re-run the REAL
# assertions against a mutated program instead of re-implementing them. A6's
# first two drafts both scored their mutant with a private copy of the
# comparison, so weakening the assertion left the ablation green.
AWKF="$WORK/check.awk"
run() { awk -v F="$1" -f "$AWKF" "$1"; }
want_hit()   { if [ -n "$(run "$1")" ]; then printf '  PASS  %s %s\n' "$1" "$2"; else printf '  FAIL  %s reported nothing — %s\n' "$1" "$2"; FAIL=1; fi; }
want_quiet() { if [ -z "$(run "$1")" ]; then printf '  PASS  %s %s\n' "$1" "$2"; else printf '  FAIL  %s reported [%s] — %s\n' "$1" "$(run "$1")" "$2"; FAIL=1; fi; }
# want_hit cannot see a message that is WRONG, only one that is absent — #144
# shipped under a green fixture for exactly that reason.
# ⚠️ EXACT, not a substring. `grep -qF` passed a message that APPENDED a false
# narrowing to the true one — re-asserting #144's own defect — and the whole suite
# stayed green. Found by review, not by this suite. A6 below is the measurement.
want_exact() { if [ "$(run "$1")" = "$2" ]; then printf '  PASS  %s %s\n' "$1" "$3"; else printf '  FAIL  %s said [%s], wanted EXACTLY [%s] — %s\n' "$1" "$(run "$1")" "$2" "$3"; FAIL=1; fi; }
want_n()     { n=$(run "$1" | grep -c .); if [ "$n" = "$2" ]; then printf '  PASS  %s %s\n' "$1" "$3"; else printf '  FAIL  %s reported %s finding(s), wanted %s — %s\n' "$1" "$n" "$2" "$3"; FAIL=1; fi; }

want_hit   t1_lf_lossy.md      "a lossy row under LF is reported"
want_hit   t2_crlf_lossy.md    "a lossy row under CRLF is reported — the #52 defect: without the \\r strip NO table in the file is examined and the run is byte-identical to clean"
want_hit   t3_fm_then_table.md "frontmatter is skipped WITHOUT disabling the rest of the file — the control on n2"
want_hit   t7_unclosed_fm.md   "an unclosed frontmatter is REPORTED, not silent — without this the file's tables are all skipped and the run is byte-identical to clean (#103)"
# ⚠️ t9 is in the ablate() population and NO ablation can zero it — it carries
# three findings, so no single-check mutant empties it. Stated rather than
# hidden, as n1 is: its value is the count assertion below, not the ablations.
want_n     t9_fm_control.md   3 "CONTROL: closing --- present, this body yields THREE findings — table, emphasis and fence"
want_n     t8_fm_loses_all.md 1 "identical body, --- typo'd: ONE finding, so two whole checks are lost and not just tables (#144)"
EXPECT_FM="unclosed YAML frontmatter — no check ran on any line of this file"
want_exact t8_fm_loses_all.md "t8_fm_loses_all.md: $EXPECT_FM" "the guard says NO CHECK RAN and nothing else: it claimed 'NO table' while also losing fence and emphasis (#144)"
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
want_hit   t11_indent_fence_fp.md "a 4-space-indented fence IS scanned as markdown — the DOCUMENTED false positive, pinned so a widening has to argue with a test (#150)"
want_quiet n11_fm_comment.md    "frontmatter opening with a YAML comment is still frontmatter (#151)"
want_quiet n12_fm_quoted.md     "a quoted YAML key is still a key (#151)"
want_quiet n9_bom_fm.md         "a BOM must not defeat the frontmatter skip (#151)"
want_quiet n10_kanban_fm.md     "frontmatter with a BLANK LINE before the first key is still frontmatter (#151)"
want_exact t10_hr_table.md "t10_hr_table.md:7: row has 3 cells, table defines 2 — the excess is dropped when rendered" \
  "a leading --- is a THEMATIC BREAK: the file is well-formed and its lossy row must be reported, not silenced (#151)"

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
  for f in t1_lf_lossy.md t2_crlf_lossy.md t3_fm_then_table.md t4_empty_excess.md t5_header_mismatch.md t6_emphasis.md t7_unclosed_fm.md t8_fm_loses_all.md t9_fm_control.md t10_hr_table.md t11_indent_fence_fp.md n1_crlf_clean.md n2_frontmatter.md n3_fenced.md n4_glob_no_bold.md n5_bold_and_code.md n6_tier_row.md n9_bom_fm.md n10_kanban_fm.md n11_fm_comment.md n12_fm_quoted.md; do
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
# Its kill set WIDENED when n9/n10 were seeded — the BOM and blank-line cases
# both depend on this entry too. Re-measured, not carried forward.
ablate "A2 never enter frontmatter"   'NR == 1 && $(0) ~ /^---[ \t]*$/' 'NR == 0 && $(0) ~ /^---[ \t]*$/' "n2_frontmatter.md,n9_bom_fm.md,n10_kanban_fm.md,n11_fm_comment.md,n12_fm_quoted.md"
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

# A6 — the ONLY ablation that tests a MESSAGE rather than a firing. ablate() above
# compares empty against non-empty, so it cannot see a finding whose TEXT is wrong,
# which is how #144 shipped green: T7 asserted the guard fires and nothing asserted
# what it said. Reverting the wording must turn want_out red while leaving the guard
# firing — a mutation that silences it would be evidence about something else.
# Generalised from the t8-only form: A10 needs it too, because the PRE-FIX
# behaviour on t10 also printed something — the unclosed-frontmatter message
# instead of the table finding — and empty-vs-non-empty cannot tell those apart.
msg_ablate() {
  local label="$1" file="$2" expect="$3" old="$4" new="$5" hits saved mutfail
  OLD="$old" NEW="$new" python3 -c '
import os, sys, pathlib
s = pathlib.Path(sys.argv[1]).read_text()
old, new = os.environ["OLD"], os.environ["NEW"]
if s.count(old) != 1: sys.exit("site occurs %d times, not once" % s.count(old))
pathlib.Path(sys.argv[2]).write_text(s.replace(old, new))
' "$WORK/check.awk" "$WORK/msg.awk" || { printf '  FAIL  ablation %s could not be applied — its site has moved\n' "$label"; FAIL=1; return; }
  # The mutant must still FIRE. A mutation that silences the guard would be
  # evidence about something else entirely.
  hits="$(awk -v F="$file" -f "$WORK/msg.awk" "$file")"
  if [ -z "$hits" ]; then printf '  FAIL  ablation %s silenced the guard — not a message-only mutation\n' "$label"; FAIL=1; return; fi
  # ⚠️ Score the mutant with want_exact ITSELF, not a copy of what it does. If
  # want_exact is ever weakened back to a substring test, this ablation goes red
  # — which is the whole point, and what two earlier drafts failed to do.
  saved=$FAIL; FAIL=0; AWKF="$WORK/msg.awk"
  want_exact "$file" "$expect" "(scored inside $label)" >/dev/null 2>&1
  mutfail=$FAIL
  AWKF="$WORK/check.awk"; FAIL=$saved
  if [ "$mutfail" = "1" ]; then
    printf '  PASS  ablation %s changes the MESSAGE while still firing, and want_exact — the real assertion, re-run — catches it\n' "$label"
  else
    printf '  FAIL  ablation %s left want_exact GREEN: the assertion cannot detect a WRONG message\n' "$label"; FAIL=1
  fi
}
msg_ablate "A6 append a false narrowing to the guard message" \
  t8_fm_loses_all.md "t8_fm_loses_all.md: $EXPECT_FM" \
  "$EXPECT_FM" "$EXPECT_FM — but only the TABLE check matters here"

# A7-A11 — one per guard added for #150/#151. Kill sets MEASURED by running each
# mutant, never predicted.
# A7/A8 guard the frontmatter DECIDING rule. Neither existed in the first draft of
# this batch, which widened the fence rule instead; that widening was reverted
# after review measured three separate regressions from it, so the row it would
# have guarded is now t11 — an assertion that the false positive is still there.
ablate "A7 a YAML comment decides the frontmatter" 'fmpend && $(0) ~ /^([ \t]*|[ \t]*#.*)$/ { next }' 'fmpend && $(0) ~ /^([ \t]*)$/ { next }' "n11_fm_comment.md"
ablate "A8 a quoted key is not a key" 'if ($(0) ~ /^["\047]?[A-Za-z_][A-Za-z0-9_.-]*["\047]?[ \t]*:/)' 'if ($(0) ~ /^[A-Za-z_][A-Za-z0-9_.-]*[ \t]*:/)' "n12_fm_quoted.md"
ablate "A9 drop the BOM strip" 'if (NR == 1) sub(/^\357\273\277/, "")' 'if (NR == 0) sub(/^\357\273\277/, "")' "n9_bom_fm.md"
ablate "A11 drop the blank line before the first key" 'fmpend && $(0) ~ /^([ \t]*|[ \t]*#.*)$/ { next }' 'fmpend && $(0) ~ /^([ \t]*#.*)$/ { next }' "n10_kanban_fm.md"
# A10 is a MESSAGE ablation, not a firing one: reverting to "open on line 1
# alone" leaves t10 printing the unclosed-frontmatter message, so ablate() would
# score the mutant GREEN. That is the #144 failure shape, and it is why this one
# is scored by re-running want_exact.
msg_ablate "A10 open the frontmatter skip on line 1 alone" \
  t10_hr_table.md "t10_hr_table.md:7: row has 3 cells, table defines 2 — the excess is dropped when rendered" \
  '/^---[ \t]*$/ { fmpend = 1; next }' '/^---[ \t]*$/ { infm = 1; next }'

echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || echo "SENSITIVITY REGRESSION — do not ship."
exit "$FAIL"
