#!/usr/bin/env bash
# Sensitivity harness for tests/lint/size-ratchet.sh (lint rule 8).
#
# A run against this repo passes, because the baseline was generated from it —
# which is exactly what a disabled ratchet looks like. Every case below seeds a
# state the rule claims to catch, or one it must not report.
#
# The rule exists because between v1.15.0 and v1.23.0 templates/curate.md grew
# 11,358 -> 37,971 bytes, more than half of it in a single session, and nothing
# in the framework reported it. The failure mode to protect against here is the
# same one: a check that measures nothing and says so quietly.
#
# ⚠️ REWRITTEN when the ratchet was measured and found never to have held: the
# recorded size of templates/curate.md moved UP 21 times and DOWN 0 times,
# because "record why and --update" is free. The unit is now the TOTAL budget,
# growth must be paid for by a shrink, and --update cannot raise the ceiling.
# Two cases below are inverted from the old version and say so.
set -u
cd "$(dirname "$0")"
CHECK="$(cd ../../lint && pwd)/size-ratchet.sh"
[ -f "$CHECK" ] || { echo "cannot find $CHECK" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mktree() {  # mktree <root>
  local r="$1"
  mkdir -p "$r/templates" "$r/tests/lint"
  printf 'aaaaaaaaaa\n' > "$r/templates/one.md"      # 11 bytes
  printf 'bbbbbbbbbbbbbbbbbbbb\n' > "$r/templates/two.md"   # 21 bytes
  bash "$CHECK" "$r" --update >/dev/null
}

FAIL=0
run_case() {  # run_case <id> <expect: HIT|CLEAN> <needle> <mutator>
  local id="$1" expect="$2" needle="$3" mut="$4"
  local r="$WORK/$id"; mkdir -p "$r"; mktree "$r"; "$mut" "$r"
  local out err rc; err="$WORK/$id.err"
  out="$(bash "$CHECK" "$r" 2>"$err")"; rc=$?
  if [ $rc -gt 1 ]; then
    printf '  FAIL  %s — checker exited %d: %s\n' "$id" "$rc" "$(cat "$err")"; FAIL=1; return
  fi
  # A checker that cannot run prints nothing, which is byte-identical to a clean
  # result. The size line on stderr is what separates them.
  if ! grep -q 'template(s) measured' "$err"; then
    printf '  FAIL  %s — no measurement line; the rule did not run\n' "$id"; FAIL=1; return
  fi
  if [ "$expect" = HIT ]; then
    if printf '%s' "$out" | grep -qF -- "$needle"; then printf '  PASS  %s\n' "$id"
    else printf '  FAIL  %s — expected a violation matching "%s", got: %s\n' "$id" "$needle" "${out:-<none>}"; FAIL=1; fi
  else
    if [ -z "$out" ]; then printf '  PASS  %s\n' "$id"
    else printf '  FAIL  %s — expected no violation, got: %s\n' "$id" "$out"; FAIL=1; fi
  fi
}

echo "positives — states the ratchet must report:"

m_grew() { printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n' > "$1/templates/one.md"; }
# Growth in one file with nothing paying for it now breaches the TOTAL, which is
# the binding constraint. The per-file line still prints, but on stderr.
run_case P1-growth-over-budget HIT "OVER BUDGET" m_grew

# Shrinkage is a failure too, deliberately: a gain that is not locked in leaves
# the ratchet loose at the old, higher number, so the next growth back to it is
# invisible. One command fixes it.
m_shrank() { printf 'a\n' > "$1/templates/one.md"; }
run_case P2-shrank-not-locked-in HIT "lock the reduction in" m_shrank

# A new template must be added deliberately, or growth escapes the ratchet
# simply by arriving in a new file — which is how a skill split into two would
# silently double the surface.
m_new_file() { printf 'cccccccccccccccccccc\n' > "$1/templates/three.md"; }
run_case P3-untracked-new-template HIT "not in the size baseline" m_new_file

m_deleted() { rm "$1/templates/two.md"; }
run_case P4-baseline-entry-vanished HIT "no longer exists" m_deleted

echo
echo "negatives — states it must not report:"

m_none() { :; }
run_case N1-unchanged CLEAN "" m_none

# Content may change freely as long as the size does not grow: the rule governs
# cost, not prose. Rewriting a paragraph to the same length is not a finding.
m_rewritten() { printf 'zzzzzzzzzz\n' > "$1/templates/one.md"; }
run_case N2-same-size-different-content CLEAN "" m_rewritten

# Files outside templates/ are not adopter-facing surfaces and are out of scope;
# tests/ and docs/ growing is not what this rule is about.
m_other_dir() { mkdir -p "$1/docs"; printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n' > "$1/docs/big.md"; }
run_case N3-non-template-growth CLEAN "" m_other_dir

# ⚠️ INVERTED. This case asserted that nested templates are out of scope. They
# are adopter-facing, and the exemption hid 59,124 bytes — templates/physics-tests/,
# 19% of the surface, never once measured by the rule whose job is measuring it.
m_nested() { mkdir -p "$1/templates/checklists"; printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n' > "$1/templates/checklists/x.md"; }
run_case P5-nested-template-in-scope HIT "not in the size baseline" m_nested

# The trade the whole rule exists to permit: one file grows, another pays.
m_paid_for() { printf 'aaaaaaaaaaaaaaaaaaaaaa\n' > "$1/templates/one.md"   # 11 -> 23
               printf 'b\n' > "$1/templates/two.md"; }                      # 21 -> 2
run_case N4-growth-paid-for-by-shrink HIT "UNDER budget" m_paid_for

echo
echo "structural:"
# A missing baseline must refuse loudly rather than report a clean tree.
r="$WORK/S1"; mkdir -p "$r/templates" "$r/tests/lint"; printf 'a\n' > "$r/templates/one.md"
out="$(bash "$CHECK" "$r" 2>&1)"; rc=$?
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -q 'no baseline'; then
  printf '  PASS  S1-missing-baseline refuses (exit 2)\n'
else printf '  FAIL  S1-missing-baseline — expected exit 2, got %d: %s\n' "$rc" "$out"; FAIL=1; fi

# --update round-trips a SHRINK — the direction the budget is allowed to move.
# It used to round-trip a GROWTH, which is the behaviour that made 21 straight
# approvals possible; that path is now S3 and must refuse.
r="$WORK/S2"; mkdir -p "$r"; mktree "$r"; printf 'a\n' > "$r/templates/one.md"
bash "$CHECK" "$r" --update >/dev/null
if [ -z "$(bash "$CHECK" "$r" 2>/dev/null)" ]; then printf '  PASS  S2-update-round-trips\n'
else printf '  FAIL  S2-update-round-trips — compare still reports after --update\n'; FAIL=1; fi

# ⚠️ THE ESCAPE HATCH IS THE WHOLE POINT OF THIS RULE, so it is asserted four
# ways. The old rule's hatch ("record why, then --update") was taken 21 times
# out of 21; if these rows ever go green-by-accident the rule is back to being a
# log with a fine name.
r="$WORK/S3"; mkdir -p "$r"; mktree "$r"; printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n' > "$r/templates/one.md"
out="$(bash "$CHECK" "$r" --update 2>&1)"; rc=$?
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -q 'cannot raise the budget'; then
  printf '  PASS  S3-update-cannot-raise-the-budget (exit 2)\n'
else printf '  FAIL  S3-update-cannot-raise-the-budget — expected exit 2, got %d: %s\n' "$rc" "$out"; FAIL=1; fi

out="$(bash "$CHECK" "$r" --raise-budget 2>&1)"; rc=$?
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -q 'needs a reason'; then
  printf '  PASS  S4-raise-budget-demands-a-reason (exit 2)\n'
else printf '  FAIL  S4-raise-budget-demands-a-reason — expected exit 2, got %d: %s\n' "$rc" "$out"; FAIL=1; fi

out="$(bash "$CHECK" "$r" --raise-budget "a deliberate, recorded enlargement" 2>&1)"; rc=$?
if [ $rc -eq 0 ] && grep -q 'RAISED' "$r/tests/lint/size-baseline.tsv" \
   && grep -q 'a deliberate, recorded enlargement' "$r/tests/lint/size-baseline.tsv"; then
  printf '  PASS  S5-raise-budget-records-the-reason-in-the-baseline\n'
else printf '  FAIL  S5-raise-budget-records-the-reason — rc=%d\n' "$rc"; FAIL=1; fi

# A baseline with rows but no ceiling cannot bind, and must say so rather than
# pass: the exact "silent zero" shape this repo keeps re-learning.
r="$WORK/S6"; mkdir -p "$r"; mktree "$r"
grep -v '^# BUDGET' "$r/tests/lint/size-baseline.tsv" > "$r/tmp" && mv "$r/tmp" "$r/tests/lint/size-baseline.tsv"
out="$(bash "$CHECK" "$r" 2>&1)"; rc=$?
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -q 'cannot bind'; then
  printf '  PASS  S6-baseline-without-a-budget-refuses (exit 2)\n'
else printf '  FAIL  S6-baseline-without-a-budget-refuses — expected exit 2, got %d: %s\n' "$rc" "$out"; FAIL=1; fi

echo
echo "ablations — each mutant must be lethal to its own row:"
ablate() { # ablate <label> <old> <new> <case-dir-setup> <must-appear|!absent>
  local lbl="$1" old="$2" new="$3" setup="$4" pat="$5"
  local m="$WORK/mut-$lbl.sh"
  python3 - "$CHECK" "$m" "$old" "$new" <<'MPY' || { printf '  FAIL  ABLATION %-34s could not apply\n' "$lbl"; FAIL=1; return; }
import sys, pathlib
src, dst, old, new = sys.argv[1:5]
s = pathlib.Path(src).read_text()
if s.count(old) != 1: sys.exit(1)
pathlib.Path(dst).write_text(s.replace(old, new))
MPY
  local r="$WORK/abl-$lbl"; mkdir -p "$r"; mktree "$r"; "$setup" "$r"
  local out; out="$(bash "$m" "$r" 2>&1; bash "$m" "$r" --update 2>&1)"
  if [ "${pat#\!}" != "$pat" ]; then
    grep -qF -- "${pat#\!}" <<<"$out" && { printf '  FAIL  ABLATION %-34s mutant changed nothing\n' "$lbl"; FAIL=1; return; }
  else
    grep -qF -- "$pat" <<<"$out" || { printf '  FAIL  ABLATION %-34s mutant changed nothing\n' "$lbl"; FAIL=1; return; }
  fi
  printf '  PASS  ABLATION %-34s lethal\n' "$lbl"
}
# Without the over-budget comparison the surface can grow unreported — the
# state the old rule was in for 21 consecutive approvals.
ablate over-budget-check 'if [ "$now_total" -gt "$budget" ]; then' 'if false; then' m_grew '!OVER BUDGET'
# Without the refusal, --update rubber-stamps growth again.
ablate update-refusal 'if [ -n "$budget" ] && [ "$now_total" -gt "$budget" ]; then' 'if false; then' m_grew '!cannot raise the budget'
# Without recursion the nested 59KB goes back to being invisible.
ablate recursive-scan '-type f | sed' '-maxdepth 1 -type f | sed' m_nested '!not in the size baseline'

echo
if [ $FAIL -eq 0 ]; then echo "All size-ratchet fixture cases passed."; else echo "Fixture failures above."; fi
exit $FAIL
