#!/usr/bin/env bash
# Cross-step fixture (#113): update-drift Step 0's matchers DEFINE m(), and its
# reconciliation CONSUMES it. Both now live in scripts/pin-scan.sh (moved out of
# templates/update-drift.md on 2026-10-27); this suite runs that script, so the
# test cannot drift from what ships.
#
# The edge has a record. The #211 fix guarded the matchers and left the
# reconciliation on the old `grep ... 2>/dev/null || :`, so a failing engine
# shrank the stamped side and a pinned file read as unstamped. Each half was
# correct alone; review found the pair broken. A1 reverts the reconciliation to
# that state and T1 must catch it. A2 drops the exit status and T2 must catch it.
set -u
cd "$(dirname "$0")/../../.." || exit 2
SCRIPT="$PWD/scripts/pin-scan.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0
[ -s "$SCRIPT" ] || { echo "  FAIL  $SCRIPT is missing"; exit 2; }
grep -q '^m()' "$SCRIPT" || { echo "  FAIL  the script no longer defines m() — the edge moved"; exit 2; }
grep -q '^--- reconciliation' "$SCRIPT" 2>/dev/null || grep -q 'echo "--- reconciliation' "$SCRIPT" ||
  { echo "  FAIL  the script no longer labels its reconciliation — T1 cannot locate it"; exit 2; }

# A tree with one pin per matcher: version (1), and commit-with-connector (3).
tree() {
  mkdir -p "$1/docs"
  printf 'framework: agent-ready-projects v1.2.3\n' > "$1/CLAUDE.md"
  printf 'Adopted agent-ready-projects at commit 0d67131\n' > "$1/docs/a.md"
}

# An engine that rejects long patterns with exit 2, as ugrep 7.8.4 rejects
# matchers 1 and 3 (#211), and passes short ones to the real grep. It is reached
# through PATH, which is what `command grep` resolves.
mkdir -p "$WORK/fakebin"
REAL_GREP=$(command -v grep)
cat > "$WORK/fakebin/grep" <<FAKE
#!/bin/sh
for a in "\$@"; do case \$a in -*) ;; *) [ \${#a} -gt 70 ] && { echo "fakegrep: exceeds complexity limits" >&2; exit 2; }; break ;; esac; done
exec $REAL_GREP "\$@"
FAKE
chmod +x "$WORK/fakebin/grep"

# run <script> <tree> [path-prefix]: stdout and stderr in ONE stream, in order,
# so a failure can be placed before or after the reconciliation label.
run() {
  ( cd "$2" && PATH="${3:-}$PATH" bash "$1" CLAUDE.md docs ) >"$WORK/out" 2>&1
  echo $? > "$WORK/rc"
}
pass() { printf '  PASS  %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; FAIL=1; }

score() {  # score <script>  -> sets T1_OK (reconciliation reports) and T2_OK (exit 2)
  rm -rf "$WORK/t1"; tree "$WORK/t1"; run "$1" "$WORK/t1" "$WORK/fakebin:"
  if sed -n '/^--- reconciliation/,$p' "$WORK/out" | grep -q 'MATCHER FAILED'; then T1_OK=1; else T1_OK=0; fi
  if [ "$(cat "$WORK/rc")" = 2 ]; then T2_OK=1; else T2_OK=0; fi
}

echo "update-drift Step 0 handoff — seeded cases"

# N1 — the control: a working engine, every pin stamped, exit 0.
tree "$WORK/n1"; run "$SCRIPT" "$WORK/n1"
if grep -q 'mentioned pairs: 2  stamped pairs: 2' "$WORK/out" && ! grep -q 'MATCHER FAILED' "$WORK/out" && [ "$(cat "$WORK/rc")" = 0 ]; then
  pass "N1 working engine: 2 mentioned, 2 stamped, no failure, exit 0"
else bad "N1 control — rc $(cat "$WORK/rc"), out: $(tr '\n' ' ' < "$WORK/out")"; fi

# N2 — the reconciliation's point: a mention with no stamp is LISTED, not just counted.
tree "$WORK/n2"; printf 'see agent-ready-papers for the writing side\n' > "$WORK/n2/docs/b.md"; run "$SCRIPT" "$WORK/n2"
if grep -q 'mentioned pairs: 3  stamped pairs: 2' "$WORK/out" && grep -qx 'docs/b.md:agent-ready-papers' "$WORK/out"; then
  pass "N2 an unstamped mention is listed by file and framework"
else bad "N2 unstamped mention not listed — out: $(tail -3 "$WORK/out" | tr '\n' ' ')"; fi

score "$SCRIPT"
# T1 — THE EDGE. The reconciliation must say a matcher failed rather than print a
# smaller stamped side as if it were a finding.
[ "$T1_OK" = 1 ] && pass "T1 a failing engine is reported inside the reconciliation, not only by the matchers" \
                 || bad "T1 the reconciliation swallowed a failed matcher — out: $(tail -4 "$WORK/out" | tr '\n' ' ')"
# T2 — the exit status carries it too, so a caller need not read the text.
[ "$T2_OK" = 1 ] && pass "T2 a failing engine exits 2" || bad "T2 a failing engine exited $(cat "$WORK/rc"), not 2"

# ── Ablations ─────────────────────────────────────────────────────────────────
if [ "$FAIL" -ne 0 ]; then echo "  UNSCORED  ablations — a seeded case already failed in this run (#161)"
else
  # A1 puts back what the #211 fix first shipped: the reconciliation's greps on
  # bare `command grep` with errors discarded. T1 must flip.
  awk '/^echo "--- reconciliation/{r=1} r && /^m -rnoE/{sub(/^m /,"command grep ")} r && /^[{ ]*m -roE/{sub(/m -roE/,"command grep -roE"); sub(/"\$\{OPERANDS\[@\]\}"$/,"\"${OPERANDS[@]}\" 2>/dev/null || :")} {print}' \
    "$SCRIPT" > "$WORK/a1.sh"
  if cmp -s "$SCRIPT" "$WORK/a1.sh"; then bad "ablation A1 changed nothing — its site moved"
  elif ! bash -n "$WORK/a1.sh"; then bad "ablation A1 does not parse — it would flip T1 for the wrong reason"
  else score "$WORK/a1.sh"
    [ "$T1_OK" = 0 ] && pass "ablation A1 (the pre-review reconciliation, unguarded grep) stops T1" \
                     || bad "ablation A1 did not stop T1 — the case does not test the edge"
  fi
  # A2 drops the failure exit. T2 must flip.
  grep -v 'pin-scan: a matcher failed' "$SCRIPT" > "$WORK/a2.sh"
  if cmp -s "$SCRIPT" "$WORK/a2.sh"; then bad "ablation A2 changed nothing — its site moved"
  elif ! bash -n "$WORK/a2.sh"; then bad "ablation A2 does not parse — it would flip T2 for the wrong reason"
  else score "$WORK/a2.sh"
    [ "$T2_OK" = 0 ] && pass "ablation A2 (no failure exit) stops T2" \
                     || bad "ablation A2 did not stop T2 — the case does not test the exit"
  fi
fi

echo
[ "$FAIL" -eq 0 ] && { echo "drift-handoff: all cases behaved."; exit 0; }
echo "drift-handoff: regressions above."; exit 1
