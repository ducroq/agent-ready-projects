#!/usr/bin/env bash
# Rule 14: review-changes Step 1.5 finds nothing in this repo's own markdown.
#
# Usage: step15-corpus.sh <repo-root>
#
# Violations go to stdout, one per line, for the caller to count. The coverage
# line goes to stderr — the caller must assert it appeared rather than reading
# empty stdout as clean, because an extraction that failed, a population that
# came back empty and a genuinely clean tree all produce the same empty stdout.
#
# Exit: 0 clean, 1 violations, 2 could not run.
#
# WHY THIS EXISTS, and it is not "Step 1.5 might regress". The check already
# ships and already works; what it was not doing is RUNNING. Audited 2026-09-14:
# `.claude/review-profile.md` carried a corruptible two-glob bold span through
# four consecutive commits that touched it — `eea6530`..`1c443eb`, measured by
# running the shipped program against each revision — while Step 1.5 claims to
# run "at every tier and every magnitude" on every changed markdown file. Four
# diff-scoped chances, no fix. (A draft said "the last four commits", which was
# off by one from the moment the fix landed: HEAD is clean.) A check nobody executes is worth exactly what an unwritten
# one is worth, and this is the cheapest instrument in the skill.
#
# ⚠️ AND IT REACHES WHAT THE SKILL CANNOT. Every term of Step 1.5's own file
# list is git-sourced (`git diff`, `git diff --cached`, the baseline term,
# `ls-files --others`), so in this repo it cannot see ANY of the gitignored
# markdown under memory/ — the memory layer whose "predominantly wide tables"
# are the step's own stated motivation. This rule reads the working tree, so it
# does. The 17-cell row found in memory/MEMORY.md on 2026-09-14 could not have
# been reached by running the skill as shipped. Filed as an adopter-facing
# defect; this rule is the local half and does not fix the shipped one.
#
# ⚠️ In CI memory/ does not exist, so the gitignored half of the population is
# empty there and the rule is WEAKER, not equal. The coverage line reports the
# two counts separately for that reason — a green CI run is not a green local
# run, the same asymmetry rules 2 and 12 carry.
set -u

root="${1:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: step15-corpus.sh <repo-root>" >&2; exit 2; }
cd "$root" || exit 2

TPL="templates/review-changes.md"
[ -f "$TPL" ] || { echo "rule 14: $TPL absent — nothing to extract" >&2; exit 2; }

WORK="$(mktemp -d)" || exit 2
trap 'rm -rf "$WORK"' EXIT

# Extraction is delegated: tests/lint/extract-step15.py is the single authority,
# shared with tests/fixtures/step15-tables/run.sh. Its failures are loud and its
# exit status is the gate — a program that extracted wrong prints nothing, which
# is what a clean corpus prints.
if ! python3 tests/lint/extract-step15.py "$TPL" "$WORK/check.awk" >&2; then
  echo "rule 14: could not extract Step 1.5's program from $TPL" >&2
  exit 2
fi
if ! awk -f "$WORK/check.awk" -v F=probe </dev/null >/dev/null 2>"$WORK/parse.err"; then
  echo "rule 14: extracted program does not parse — $(head -1 "$WORK/parse.err")" >&2
  exit 2
fi

# ── Exemptions ────────────────────────────────────────────────────────────────
# One line per exemption, four tab-separated fields:
#   <path><TAB><substring of the offending SOURCE line><TAB><substring of the
#   FINDING message><TAB><why>
#
# Keyed on CONTENT, never on a line number: CHANGELOG.md grows from the top, so
# a line number here would name a different line after every release.
#
# ⚠️ AN EXEMPTION IS A LOOSENING, and a review measured the first version of this
# mechanism transferring to a defect it was never written for: with only the path
# and the source substring matched, deleting the #159 prose and adding a genuinely
# LOSSY ROW containing the same phrase suppressed the row defect at rc 0, and the
# staleness check did not notice because the exemption had matched *something*.
# Three bounds, all seeded (T4, T7, T8):
#   1. It must name ONE path.
#   2. It must match the source line AND the finding's SHAPE, so an exemption for
#      an emphasis false positive cannot silence a lossy row on the same line.
#   3. It must match EXACTLY ONCE. Zero is STALE; more than one is OVER-BROAD.
#      Both fail the rule. This is the unused-suppression detection that `# noqa`,
#      `// eslint-disable` and `# shellcheck disable` carry — ⚠️ but those are
#      LINE-scoped and this is content-scoped, so the cardinality bound is doing
#      work theirs gets from the host syntax for free.
#
# $STEP15_EXEMPTIONS names a file to read instead of the built-in list. It exists
# so the fixture can seed a run with NO exemptions — without it, every "clean"
# case in the fixture is really "everything was exempted", which cannot tell a
# silent checker from a fully-suppressed one. The override is REPORTED on the
# coverage line, never silent.
exemptions() {
  if [ -n "${STEP15_EXEMPTIONS:-}" ]; then
    [ -f "$STEP15_EXEMPTIONS" ] && cat "$STEP15_EXEMPTIONS"
    return
  fi
  # #159: prose that QUOTES the corrupt shape inside a double-backtick span. The
  # checker reads `` `` `` as two single-backtick spans, so the passage
  # DESCRIBING the defect reports as the defect. A documented false-positive
  # class of the shipped check, not a defect in this file.
  printf 'CHANGELOG.md\tAn adopter porting the magnitude gate\ttwo backticked tokens abutting\t#159 — prose quoting the shape inside a double-backtick span\n'
}

# ── Population ────────────────────────────────────────────────────────────────
# The working tree, not the index: reaching gitignored memory/ is the point.
# -print0 because a markdown filename may legally contain a newline.
#
# ⚠️ KNOWN BLIND SPOT, stated rather than fixed: the shipped awk prints
# `file:line: message`, so a filename containing a newline splits one finding
# across two reported lines, and one containing a colon defeats the field split
# below, which costs the exemption match. Both over-report. Measured: this tree
# has no such names (`find . -name '.git' -prune -o -name '*.md' -print | grep -c
# '[:]'` -> 0; a positive would have listed the paths). Symlinked markdown is not
# scanned at all (`-type f`), also measured at 0 here.
total=0; scanned=0; ignored=0; hits=0; exempted=0
: > "$WORK/raw"; : > "$WORK/violations"

# `git check-ignore` fails for a reason that has nothing to do with the path when
# there is no work tree — a tarball export, a clone with .git removed. Reporting
# `0 gitignored` there would be a positive claim from a failed instrument, so the
# two cases are distinguished on the coverage line.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then IN_TREE=1; else IN_TREE=0; fi

while IFS= read -r -d '' f; do
  total=$((total + 1))
  [ "$IN_TREE" -eq 1 ] && git check-ignore -q "$f" 2>/dev/null && ignored=$((ignored + 1))
  # ⚠️ The exit status IS the gate. An unreadable file makes awk exit non-zero and
  # print nothing, which is what a clean file prints — the third member of the trio
  # this script's header names, and the only one that was unguarded until a review
  # seeded it (`chmod 000` on a file with a seeded lossy row: rc 0, "scanned", no
  # finding). A file that could not be examined is a FINDING, not a silent skip.
  if awk -f "$WORK/check.awk" -v F="$f" "$f" >> "$WORK/raw" 2>"$WORK/awk.err"; then
    scanned=$((scanned + 1))
  else
    echo "rule 14: could not examine $f — $(head -1 "$WORK/awk.err"). Not scanned; this is not a clean result." >> "$WORK/violations"
  fi
done < <(find . -name '.git' -prune -o -type f -name '*.md' -print0)

if [ "$total" -eq 0 ]; then
  echo "rule 14: no markdown files found under $root — the population is empty, not clean" >&2
  exit 2
fi

# ── Classify each hit ─────────────────────────────────────────────────────────
: > "$WORK/matched"
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  hits=$((hits + 1))
  file=${hit%%:*}; rest=${hit#*:}; line=${rest%%:*}; msg=${rest#*:}
  src=""
  case $line in (*[!0-9]*|'') ;; (*) src=$(sed -n "${line}p" "$file" 2>/dev/null) ;; esac
  skip=0
  while IFS=$'\t' read -r xpath xsub xshape xwhy; do
    [ -n "${xpath:-}" ] && [ -n "${xshape:-}" ] || continue
    [ "./$xpath" = "$file" ] || [ "$xpath" = "$file" ] || continue
    case $src in (*"$xsub"*) ;; (*) continue ;; esac
    # The SHAPE bound. Without it an exemption written for one finding class
    # silences every other class that lands on a line carrying the substring.
    case $msg in (*"$xshape"*) ;; (*) continue ;; esac
    skip=1; exempted=$((exempted + 1))
    printf '%s\t%s\n' "$xpath" "$xsub" >> "$WORK/matched"
    echo "      exempt: $file:$line — $xwhy" >&2
  done < <(exemptions)
  [ "$skip" -eq 1 ] || echo "$hit" >> "$WORK/violations"
done < "$WORK/raw"

# An exemption must match EXACTLY ONCE. Zero means it no longer covers anything
# and is an unbounded silencer of whatever lands in that file next; more than one
# means it is covering something nobody declared.
while IFS=$'\t' read -r xpath xsub xshape xwhy; do
  [ -n "${xpath:-}" ] || continue
  # No `|| echo 0`: `grep -c` PRINTS 0 and EXITS 1 when it matches nothing, so the
  # fallback appended a second zero and the count arrived as "0 0" — which is not
  # 1, so it reported OVER-BROAD for a stale exemption. Caught by the fixture's
  # own T4/A2 pair, which is what that pair is for.
  n=$(grep -Fxc "$(printf '%s\t%s' "$xpath" "$xsub")" "$WORK/matched" 2>/dev/null); n=${n:-0}
  case $n in
    1) ;;
    0) echo "rule 14: STALE EXEMPTION — $xpath / \"$xsub\" matched nothing this run ($xwhy). Delete it, or say what it now covers." >> "$WORK/violations" ;;
    *) echo "rule 14: OVER-BROAD EXEMPTION — $xpath / \"$xsub\" matched $n findings, not 1 ($xwhy). Narrow it; one exemption covers one line." >> "$WORK/violations" ;;
  esac
done < <(exemptions)

cat "$WORK/violations" 2>/dev/null

if [ "$IN_TREE" -eq 1 ]; then
  ig="$ignored of them gitignored and therefore invisible to the skill itself"
  [ "$ignored" -eq 0 ] && ig="$ig (none here — this run is WEAKER than one with a populated memory/)"
else
  ig="gitignored count UNKNOWN — not inside a git work tree, so nothing was exempted from the skill-reach claim"
fi
src_note=""
[ -n "${STEP15_EXEMPTIONS:-}" ] && src_note=" [exemptions overridden from \$STEP15_EXEMPTIONS]"
echo "      $total markdown file(s) found, $scanned scanned, $ig; $hits raw hit(s), $exempted exempted$src_note" >&2

# Exit 1 only when something is left AFTER exemptions and the cardinality checks.
[ -s "$WORK/violations" ] && exit 1
exit 0
