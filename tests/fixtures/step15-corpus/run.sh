#!/usr/bin/env bash
# Sensitivity fixture for lint rule 14 (tests/lint/step15-corpus.sh).
#
# Rule 14 runs review-changes Step 1.5 over this repo's own markdown. On a clean
# tree it prints nothing — which is also what a failed extraction, an empty
# population and a silenced checker print. This fixture is what distinguishes
# them: every case below seeds a failure the rule must still catch.
#
# The scratch repo is built from scratch rather than copied from this one, so a
# case cannot pass because of something incidental in the real tree.
#
# CASE COUNTS ARE COMMANDS, NOT DIGITS:
#   t/n  grep -oE '^\s*(want_fail|want_clean|want_rc) ' run.sh | wc -l
#   abl  grep -cE '^ablate ' run.sh
#
# READ BEFORE LOOSENING: A3 is the counterfactual for this rule's entire reason
# to exist. Replacing the working-tree `find` with a git-sourced population —
# which is what the shipped skill does — must break T2. If A3 stops killing T2,
# the rule has lost the only thing it does that Step 1.5 could not already do.
set -u
cd "$(dirname "$0")/../../.." || exit 2
ROOT="$PWD"
RULE="$ROOT/tests/lint/step15-corpus.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0
# "" means: no override, use the checker's built-in list. Named rather than bare
# so a reader can tell a deliberate use of the shipped exemptions from an omission.
SHIPPED=""

# The one CHANGELOG line the shipped exemption points at, quoted verbatim from
# the real file so the fixture cannot drift from the exemption it tests. Extracted
# by pattern, never by line number — CHANGELOG.md grows from the top.
EXEMPT_LINE=$(grep -m1 'An adopter porting the magnitude gate' "$ROOT/CHANGELOG.md")
[ -n "$EXEMPT_LINE" ] || { echo "FAIL  could not find the exempted CHANGELOG line — the exemption or the line moved"; exit 1; }

# build <dir> [--no-exempt-line] [--no-md]
# A minimal repo carrying only what rule 14 reads: the template it extracts from,
# the extractor, a gitignored memory/, and clean markdown.
build() {
  local d="$1"; shift
  local want_exempt=1 want_md=1
  for a in "$@"; do
    case $a in (--no-exempt-line) want_exempt=0 ;; (--no-md) want_md=0 ;; esac
  done
  mkdir -p "$d/templates" "$d/tests/lint" "$d/memory"
  cp "$ROOT/templates/review-changes.md" "$d/templates/review-changes.md"
  cp "$ROOT/tests/lint/extract-step15.py" "$d/tests/lint/extract-step15.py"
  printf '/memory/\n' > "$d/.gitignore"
  if [ "$want_md" -eq 1 ]; then
    printf '# Doc\n\n| a | b |\n|---|---|\n| 1 | 2 |\n' > "$d/doc.md"
    printf '# Memory\n\n| a | b |\n|---|---|\n| 1 | 2 |\n' > "$d/memory/MEMORY.md"
  else
    rm -f "$d/templates/review-changes.md"   # no template => extraction cannot run
  fi
  if [ "$want_exempt" -eq 1 ]; then
    { echo "# Changelog"; echo; printf '%s\n' "$EXEMPT_LINE"; } > "$d/CHANGELOG.md"
  else
    { echo "# Changelog"; echo; echo "nothing quoted here"; } > "$d/CHANGELOG.md"
  fi
  git -C "$d" init -q 2>/dev/null
  git -C "$d" add -A 2>/dev/null
  git -C "$d" -c user.email=f@x -c user.name=f commit -qm seed 2>/dev/null
}

# run <dir> <rule-script> [exemption-file]  -> stdout $OUT, stderr $ERR, status $RC
# The third argument seeds $STEP15_EXEMPTIONS. An EMPTY file means "no exemptions",
# which is what N1 needs: with the shipped list in force every clean case is really
# "everything was exempted", and that cannot tell a silent checker from a fully
# suppressed one. A review measured exactly that — no case here had zero raw hits.
run() {
  OUT="$WORK/out"; ERR="$WORK/err"
  if [ "${3:-}" = "" ]; then
    STEP15_EXEMPTIONS= bash "$2" "$1" >"$OUT" 2>"$ERR"; RC=$?
  else
    STEP15_EXEMPTIONS="$3" bash "$2" "$1" >"$OUT" 2>"$ERR"; RC=$?
  fi
}

want_fail() {  # label, dir, needle the violation must name, [exemption file]
  local label="$1" d="$2" needle="$3"
  run "$d" "$RULE" "${4:-}"
  if [ "$RC" -eq 1 ] && grep -q "$needle" "$OUT"; then
    printf '  PASS  %s\n' "$label"
  else
    printf '  FAIL  %s — rc=%s, stdout: %s\n' "$label" "$RC" "$(head -2 "$OUT" | tr '\n' ' ')"; FAIL=1
  fi
}

want_clean() {  # label, dir, [exemption file], [expected raw hits]
  local label="$1" d="$2" want_raw="${4:-0}"
  run "$d" "$RULE" "${3:-}"
  if [ "$RC" -eq 0 ] && [ ! -s "$OUT" ] && grep -q "$want_raw raw hit(s)" "$ERR" && grep -q 'markdown file(s) found' "$ERR"; then
    printf '  PASS  %s\n' "$label"
  else
    printf '  FAIL  %s — rc=%s, stdout: %s\n' "$label" "$RC" "$(head -2 "$OUT" | tr '\n' ' ')"; FAIL=1
  fi
}

want_rc() {  # label, dir, expected rc, [exemption file] — the could-not-run cases
  local label="$1" d="$2" want="$3"
  run "$d" "$RULE" "${4:-}"
  if [ "$RC" -eq "$want" ]; then printf '  PASS  %s\n' "$label"
  else printf '  FAIL  %s — rc=%s, wanted %s\n' "$label" "$RC" "$want"; FAIL=1; fi
}

echo "rule 14 — seeded cases"

# N1 — the control, and it is the whole argument for every T below: a repo with
# no seeded defect must be silent, or a T passing proves nothing.
# ⚠️ Run with NO exemptions and asserting ZERO raw hits. A first draft ran with
# the shipped list and a CHANGELOG line that hit and was exempted — so "clean"
# meant "fully suppressed", and a checker that found nothing at all would have
# passed it identically. Found by review, not by this suite.
build "$WORK/n1" --no-exempt-line
: > "$WORK/no-exemptions"
want_clean "N1 clean tree, no exemptions in force, is silent with ZERO raw hits" "$WORK/n1" "$WORK/no-exemptions" 0

# T1 — the ordinary case. Left UNCOMMITTED on purpose: A3 below must distinguish
# "not staged" from "ignored", and a committed T1 would let it pass by killing both.
build "$WORK/t1"
printf '# T\n\n| a | b |\n|---|---|\n| 1 | 2 | 3 |\n' > "$WORK/t1/lossy.md"
want_fail "T1 a seeded lossy row is reported" "$WORK/t1" "lossy.md"

# T2 — THE CASE THIS RULE EXISTS FOR. The same defect in gitignored memory/,
# which every term of Step 1.5's own git-sourced file list misses.
build "$WORK/t2"
printf '# M\n\n| a | b |\n|---|---|\n| 1 | 2 | 3 |\n' > "$WORK/t2/memory/lossy.md"
git -C "$WORK/t2" check-ignore -q memory/lossy.md ||
  { echo "  FAIL  T2 setup: memory/lossy.md is not gitignored, so the case tests nothing"; FAIL=1; }
want_fail "T2 gitignored lossy row is reported (the skill cannot reach it)" "$WORK/t2" "memory/lossy.md"

# T3 — the exemption fires on the file it names. Distinct from N1 in both
# directions now: the shipped list is in force, and ONE raw hit must have been
# found and then exempted. Asserting the hit count is what makes this a test of
# the exemption rather than a second copy of the control.
build "$WORK/t3"
want_clean "T3 the #159 CHANGELOG prose is found, then exempted" "$WORK/t3" "$SHIPPED" 1

# T4 — and the exemption is bounded: once its line is gone it is STALE, and a
# stale exemption fails the rule rather than sitting there silencing whatever
# occupies that file next.
build "$WORK/t4" --no-exempt-line
want_fail "T4 an exemption matching nothing is reported STALE" "$WORK/t4" "STALE EXEMPTION" "$SHIPPED"

# T5 — a broken instrument must not read as clean. Mangle the extraction anchor.
build "$WORK/t5"
python3 - "$WORK/t5/templates/review-changes.md" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
p.write_text(s.replace('  awk -v F="$f" \'', '  awk -v ZZZ="$f" \'', 1))
PY
want_rc "T5 extraction failure exits 2, never 0" "$WORK/t5" 2

# T6 — an empty population is not a clean one.
build "$WORK/t6" --no-md
want_rc "T6 absent template exits 2, never 0" "$WORK/t6" 2

# T7 — the CARDINALITY bound. The same substring on two lines, both producing the
# exempted shape: one exemption covering two findings is covering something nobody
# declared, so it fails rather than silently widening.
build "$WORK/t7"
{ echo "# Changelog"; echo; printf '%s\n' "$EXEMPT_LINE"; echo; printf '%s\n' "$EXEMPT_LINE"; } > "$WORK/t7/CHANGELOG.md"
want_fail "T7 an exemption matching twice is reported OVER-BROAD" "$WORK/t7" "OVER-BROAD" "$SHIPPED"

# T8 — THE TRANSFER CASE, and it is why the exemption carries a shape. A review
# built this one: delete the #159 prose, put a genuinely LOSSY ROW on a line that
# happens to carry the same phrase, and the pre-shape mechanism suppressed a data
# -losing defect at rc 0 with no stale report. The row must now be reported.
build "$WORK/t8" --no-exempt-line
{ echo "# Changelog"; echo; echo "| a | b |"; echo "|---|---|"
  echo "| An adopter porting the magnitude gate | 2 | 3 |"; } > "$WORK/t8/CHANGELOG.md"
want_fail "T8 an exemption cannot transfer to a different finding shape" "$WORK/t8" "the excess is dropped" "$SHIPPED"

# T9 — a file that could not be examined is a finding, not a silent skip. awk
# exits non-zero and prints nothing, which is what a clean file prints.
build "$WORK/t9"
printf '# T\n\n| a | b |\n|---|---|\n| 1 | 2 | 3 |\n' > "$WORK/t9/unreadable.md"
chmod 000 "$WORK/t9/unreadable.md"
if [ -r "$WORK/t9/unreadable.md" ]; then
  echo "  SKIP  T9 — the file is still readable (running as root?); this case asserts nothing here"
else
  want_fail "T9 an unexaminable file is reported, not counted as scanned" "$WORK/t9" "could not examine" "$SHIPPED"
fi
# ⚠️ Permissions are restored at the END of the run, not here. Restoring them
# before the ablations made the file readable again, so its seeded lossy row
# became an ordinary hit and A1's kill set silently widened to include t9 —
# a case passing for a different reason than the one it is named for.

# ── Ablations: every T above must be killable, or it is asserting nothing ──────
# Kill sets are MEASURED by running each mutant, not predicted.
ablate() {  # label, old, new, comma-separated cases that must flip to clean
  [ -n "${ABL_PRE+x}" ] || ABL_PRE=$FAIL; if [ "$ABL_PRE" -ne 0 ]; then printf '  UNSCORED  ablation %s — a seeded case already failed in this run, so it cannot fail (#161)\n' "$1"; return 0; fi
  local label="$1" old="$2" new="$3" want="$4" got=""
  local mut="$WORK/mutant.sh"
  OLD="$old" NEW="$new" python3 -c '
import os, sys, pathlib
s = pathlib.Path(sys.argv[1]).read_text()
old, new = os.environ["OLD"], os.environ["NEW"]
if old not in s: sys.exit("ABLATION ANCHOR MISSING: %r" % old)
pathlib.Path(sys.argv[2]).write_text(s.replace(old, new, 1))
' "$RULE" "$mut" || { printf '  FAIL  ablation %s could not be applied\n' "$label"; FAIL=1; return; }
  for c in t1 t2 t4 t7 t8 t9; do
    [ -d "$WORK/$c" ] || continue
    run "$WORK/$c" "$mut"
    [ "$RC" -eq 0 ] && got="$got,$c"
  done
  got="${got#,}"
  if [ "$got" = "$want" ]; then printf '  PASS  ablation %s stops catching exactly [%s]\n' "$label" "$want"
  else printf '  FAIL  ablation %s should stop catching [%s], stopped [%s]\n' "$label" "$want" "$got"; FAIL=1; fi
}

# A1 silences the violation path for HITS only. T1 and T2 go green; T4 does NOT —
# its stale line is emitted by a different `echo`, which the single-replacement
# mutation never touches. ⚠️ A draft of this comment claimed T4 went with them
# "measured, not predicted", and it was neither: the kill set below was right and
# the sentence above it was wrong. Re-measured by running the mutant against t4.
ablate "A1 discard violations" 'echo "$hit" >> "$WORK/violations"' 'echo "$hit" >/dev/null' "t1,t2"
# A2 silences ONLY the stale-exemption report, so only T4 flips.
ablate "A2 never report a stale exemption" 'Delete it, or say what it now covers." >> "$WORK/violations"' 'Delete it, or say what it now covers." >/dev/null' "t4"
# A3 — THE COUNTERFACTUAL FOR THIS RULE. Take the population from git the way
# Step 1.5 does — tracked AND untracked-but-not-ignored, which is what
# `ls-files --others --exclude-standard` adds — and the ONLY case that stops
# being seen is the gitignored one. T1 is deliberately left untracked so this
# ablation has to distinguish "not committed" from "ignored"; a mutation that
# killed both would have measured staging, not reach.
# If A3 ever stops killing t2, this rule does nothing the skill could not.
# A4 drops the SHAPE bound — the exemption then matches on path+substring alone,
# which is the mechanism a review measured transferring an emphasis exemption onto
# a lossy row. T8 must go green, and ONLY T8: this is the counterfactual for the
# blocker that shape-matching was added to fix.
ablate "A4 exemption ignores the finding shape" \
  '    case $msg in (*"$xshape"*) ;; (*) continue ;; esac' \
  '    case $msg in (*) ;; esac' "t8"
# A5 drops the cardinality bound back to "matched anything", the form that shipped
# in the first draft. T7 must go green; T4 must NOT, since zero matches still
# leaves $n at 0 — measured, and the reason the two bounds are separate cases.
ablate "A5 exemption may match any number of times" \
  'Narrow it; one exemption covers one line." >> "$WORK/violations" ;;' \
  'Narrow it; one exemption covers one line." >/dev/null ;;' "t7"
# A6 — T9 was the only case here with no ablation, which the header's own doctrine
# forbids. Silencing the unexaminable-file report flips a chmod-000 tree from rc 1
# to rc 0 while the coverage line still reads `3 found, 2 scanned` — a mismatch
# nothing compares, so the runner would pass it.
ablate "A6 an unexaminable file is not reported" \
  'Not scanned; this is not a clean result." >> "$WORK/violations"' \
  'Not scanned; this is not a clean result." >/dev/null' "t9"
ablate "A3 git-sourced population (what the skill does)" \
  "done < <(find . -name '.git' -prune -o -type f -name '*.md' -print0)" \
  'done < <({ git ls-files -z "*.md"; git ls-files -z --others --exclude-standard "*.md"; })' "t2"

chmod 644 "$WORK/t9/unreadable.md" 2>/dev/null

echo
[ "$FAIL" -eq 0 ] && { echo "step15-corpus: all cases behaved."; exit 0; }
echo "step15-corpus: regressions above."; exit 1
