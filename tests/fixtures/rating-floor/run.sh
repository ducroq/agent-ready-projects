#!/usr/bin/env bash
# Sensitivity fixture for lint rule 23 (tests/lint/rating-floor.sh).
#
# The real log is clean today, so a run over it cannot tell a working rule from a
# disabled one. T1 is the Gloaguen block as it stood before 2026-09-12, reduced
# to its shape: Step 5 NEEDS WORK, Step 6 PARTIAL, Status VERIFIED, claims
# ESTABLISHED. Run against the real pre-fix files (git show 7f43360^:<path>) the
# rule reports that block and S2-1, S2-3 and S2-4.
set -u
cd "$(dirname "$0")/../../.." || exit 2
RULE="$PWD/tests/lint/rating-floor.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

# tree <dir> <step5 result> <step6 result> <status> <registry rating>
tree() {
  mkdir -p "$1/docs/vv/claims"
  cat > "$1/docs/vv/verification-log.md" <<EOF
# Verification Log

## Source 1: Example et al. 2026

Claims: S2-3, S2-4.

| Step | Check | Result | Notes |
|------|-------|--------|-------|
| 0 | Quick web verification | PASS | resolves |
| 5 | Exact location? | $2 | figures need verification against full text |
| 6 | Read relevant section? | $3 | secondary sources only |

**Status:** $4

## Source 2: Clean source

Claims: S4-1.

| Step | Check | Result | Notes |
|------|-------|--------|-------|
| 0 | Quick web verification | PASS | resolves |

**Status:** VERIFIED

## Summary
EOF
  cat > "$1/docs/vv/claims/claim_registry.md" <<EOF
| ID | Claim | Type | P | Status | Source | Grade | Done |
|----|-------|------|---|--------|--------|-------|------|
| S2-3 | a figure | CLAIM | P1 | $5 | Example | A | [ ] |
| S2-4 | another figure | CLAIM | P1 | $5 | Example | A | [ ] |
| S4-1 | a clean claim | CLAIM | P1 | ESTABLISHED | Clean | C | [ ] |
EOF
}

run() { OUT="$WORK/out"; ERR="$WORK/err"; bash "${2:-$RULE}" "$1" >"$OUT" 2>"$ERR"; RC=$?; }
want_fail() { run "$2"; if [ "$RC" -eq 1 ] && grep -q "$3" "$OUT"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_clean(){ run "$2"; if [ "$RC" -eq 0 ] && [ ! -s "$OUT" ] && grep -q 'source block(s)' "$ERR"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_rc()   { run "$2"; if [ "$RC" -eq "$3" ]; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s wanted %s\n' "$1" "$RC" "$3"; FAIL=1; fi; }

echo "rule 23 — seeded cases"

tree "$WORK/n1" PASS PASS VERIFIED ESTABLISHED
want_clean "N1 every step PASS: VERIFIED and ESTABLISHED are allowed" "$WORK/n1"

# N2 — a weak step with an honest rating is the fix, and must be quiet.
tree "$WORK/n2" "NEEDS WORK" PARTIAL "PARTIALLY VERIFIED" "PROVISIONAL"
want_clean "N2 weak steps with a weak rating are quiet" "$WORK/n2"

# N3 — a PASS that says it was closed must not read as weak.
tree "$WORK/n3" "**PASS (closed 2026-09-12)**" PASS VERIFIED ESTABLISHED
want_clean "N3 a closed PASS is a PASS" "$WORK/n3"

tree "$WORK/t1" "NEEDS WORK" PARTIAL VERIFIED ESTABLISHED
want_fail "T1 the #168 shape: Status VERIFIED over weak steps" "$WORK/t1" "has 2 step(s) PARTIAL / NEEDS WORK / FAIL but its Status is VERIFIED"

# T2 — the log honest, the registry not: the join must fire on its own.
tree "$WORK/t2" "NEEDS WORK" PARTIAL "PARTIALLY VERIFIED" ESTABLISHED
want_fail "T2 a claim from a weak block is ESTABLISHED" "$WORK/t2" "S2-3 is ESTABLISHED"

tree "$WORK/t3" PASS "**FAIL**" "**VERIFIED**" PROVISIONAL
want_fail "T3 one FAIL, bolded status" "$WORK/t3" "has 1 step(s)"

mkdir -p "$WORK/e1/docs/vv/claims"; printf '# Log\n' > "$WORK/e1/docs/vv/verification-log.md"; : > "$WORK/e1/docs/vv/claims/claim_registry.md"
want_rc "E1 no source block exits 2, never 0" "$WORK/e1" 2

# ── Ablations: every T above must be killable, or it is asserting nothing ──────
ablate() {  # label, old, new, comma-separated cases that must stop failing
  local label="$1" old="$2" new="$3" want="$4" got="" mut="$WORK/mutant.sh"
  OLD="$old" NEW="$new" python3 -c '
import os, sys, pathlib
s = pathlib.Path(sys.argv[1]).read_text()
old, new = os.environ["OLD"], os.environ["NEW"]
if s.count(old) != 1: sys.exit("site occurs %d times, not once" % s.count(old))
pathlib.Path(sys.argv[2]).write_text(s.replace(old, new))
' "$RULE" "$mut" || { printf '  FAIL  ablation %s could not be applied\n' "$label"; FAIL=1; return; }
  for c in t1 t2 t3; do
    run "$WORK/$c" "$mut"
    [ "$RC" -eq 0 ] && got="$got,$c"
  done
  got="${got#,}"
  if [ "$got" = "$want" ]; then printf '  PASS  ablation %s stops catching exactly [%s]\n' "$label" "$want"
  else printf '  FAIL  ablation %s should stop catching [%s], stopped [%s]\n' "$label" "$want" "$got"; FAIL=1; fi
}
ablate "A1 no step is ever weak"          'if (r ~ /PARTIAL|NEEDS WORK|FAIL/) weak++' 'if (0) weak++' "t1,t2,t3"
ablate "A2 the status is never compared"  '  case "$st" in VERIFIED*)' '  case "$st" in NEVER*)' "t3"
ablate "A3 the registry is never joined"  '    if grep -qE "^\|[[:space:]]*$id[[:space:]]*\|.*\|[[:space:]]*ESTABLISHED" "$REG"; then' '    if false; then' "t2"

echo
[ "$FAIL" -eq 0 ] && { echo "All seeded cases behaved correctly."; exit 0; }
echo "rating-floor: regressions above."; exit 1
