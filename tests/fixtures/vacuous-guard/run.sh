#!/usr/bin/env bash
# Sensitivity fixture for lint rule 10. A rule that reports nothing on a clean
# repo is indistinguishable from one that cannot run — these are the cases that
# must fire, and the ones that must not.
set -u
# Absolute, captured ONCE. A first draft used "$OLDPWD" and every intervening
# `cd` reassigned it, so the fixture invoked a path that does not exist and all
# four positives reported "not detected" against a checker that works. The
# fixture was wrong and said so, which is the whole point of having one.
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)" || exit 2
CHK="$ROOT/tests/lint/vacuous-guard.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
FAIL=0
mkdir -p "$W/repo/tests" && cd "$W/repo" && git init -q . && git config user.email f@x && git config user.name f

seed() { printf '%s\n' "$2" > "tests/$1"; }
# T = must report
seed t1.sh 'ablate "A1 whitespace only" '"'"'if (x > 1)'"'"' '"'"'if (x > 1) '"'"' "case"'
seed t2.sh 'ablate "A2 identical" '"'"'foo=1'"'"' '"'"'foo=1'"'"' "case"'
seed t3.sh 'ablate "A3 empty kill set" '"'"'foo=1'"'"' '"'"'bar=2'"'"' ""'
# T4 — the shape that motivated the rule: a continued line
printf 'ablate "A4 continued" \\\n  %s %s "case"\n' "'x = 1'" "'x  =  1'" > tests/t4.sh
# T5/T6 — a runner whose name merely ENDS in `ablate`. The gate was
# `[^A-Za-z_]ablate[ \t]`, so a wrapper called `mablate` put `m` in the negated
# class and no such call was ever scanned: both shapes above went unreported on a
# real branch that added one. Measured before the widening — clean, exit 0.
seed t5.sh 'mablate "A7 whitespace only, wrapper name" '"'"'if (x > 1)'"'"' '"'"'if (x > 1) '"'"' "case"'
seed t6.sh 'mablate "A8 empty kill set, wrapper name" '"'"'foo=1'"'"' '"'"'bar=2'"'"' ""'
# N = must stay silent
seed n1.sh 'ablate "A5 real mutation" '"'"'if (x > 1)'"'"' '"'"'if (0)'"'"' "case"'
seed n2.sh 'ablate "A6 real, multiline" '"'"'findings.append'"'"' '"'"'weak.append'"'"' "c1,c2"'
seed n3.sh '# a comment mentioning ablate but not calling it'
# N4 — the widened gate must not start reporting a wrapper's REAL mutation, and
# N5 that it does not fire on an identifier that merely contains the word.
seed n4.sh 'mablate "A9 real mutation, wrapper name" '"'"'if (x > 1)'"'"' '"'"'if (0)'"'"' "case"'
seed n5.sh 'deablate_all=1   # an identifier, not a call'
git add -A >/dev/null 2>&1

OUT="$(cd "$W/repo" && bash "$CHK" . 2>/dev/null)"
for t in t1 t2 t3 t4 t5 t6; do
  if grep -q "tests/$t.sh" <<<"$OUT"; then printf '  PASS  %s reported\n' "$t"
  else printf '  FAIL  %s is a no-op ablation and was NOT reported\n' "$t"; FAIL=1; fi
done
for n in n1 n2 n3 n4 n5; do
  if grep -q "tests/$n.sh" <<<"$OUT"; then printf '  FAIL  %s is a real mutation and was reported\n' "$n"; FAIL=1
  else printf '  PASS  %s stayed silent\n' "$n"; fi
done
# the checker must refuse loudly rather than pass when it cannot run
cd "$ROOT" || exit 2
bash "$CHK" /nonexistent-dir-for-this-test >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && printf '  PASS  a bad root exits 2, not 0\n' || { printf '  FAIL  a bad root exited %s — a checker that cannot run must not read as clean\n' "$rc"; FAIL=1; }
echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || echo "SENSITIVITY REGRESSION — do not ship."
exit "$FAIL"
