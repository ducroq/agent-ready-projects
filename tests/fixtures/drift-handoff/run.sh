#!/usr/bin/env bash
# Cross-step fixture (#113): update-drift Step 0's matcher block PRODUCES m(), and
# its reconciliation block CONSUMES it. Every other suite here tests one step; this
# one feeds a real producer to a real consumer, both EXTRACTED from
# templates/update-drift.md so the test cannot drift from what ships.
#
# The edge has a record. The #211 fix guarded the matcher block and left the
# reconciliation on the old `grep ... 2>/dev/null || :`, so a failing engine
# shrank the stamped side and a pinned file read as unstamped. Each block was
# correct alone; review found the pair broken. A1 reverts the consumer to that
# state and T1 must catch it.
set -u
cd "$(dirname "$0")/../../.." || exit 2
TPL="$PWD/templates/update-drift.md"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

# Extract Step 0's two bash blocks, in order: 1 = matchers (defines m), 2 = reconcile.
extract() {  # extract <template> <outdir>
  awk '/^## Step 0/,/^## Step 1/' "$1" |
    awk -v d="$2" '/^```bash/{f=1;n++;next}/^```/{f=0}f{print > (d "/blk" n ".sh")}'
  [ -s "$2/blk1.sh" ] && [ -s "$2/blk2.sh" ] || { echo "  FAIL  could not extract both Step 0 blocks from $1"; exit 2; }
  grep -q '^m()' "$2/blk1.sh" || { echo "  FAIL  the producer block no longer defines m() — the edge moved"; exit 2; }
  grep -q '^m -r' "$2/blk2.sh" || { echo "  FAIL  the consumer block no longer calls m — the edge moved"; exit 2; }
  sed -i 's|"<project file>"|CLAUDE.md|' "$2/blk1.sh"
}

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

# run <blocks-dir> <tree> [path-prefix] [skip-producer]: out/err of the CONSUMER only.
run() {
  ( cd "$2" && PATH="${3:-}$PATH" bash -c '
      if [ -z "$SKIP" ]; then . "$B/blk1.sh" >/dev/null 2>&1; fi
      . "$B/blk2.sh"' ) >"$WORK/out" 2>"$WORK/err"
}
pass() { printf '  PASS  %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; FAIL=1; }

score() {  # score <blocks-dir>  -> sets T1_OK, T2_OK
  tree "$WORK/t1"; B="$1" SKIP="" run "$1" "$WORK/t1" "$WORK/fakebin:"
  if grep -q 'MATCHER FAILED' "$WORK/err"; then T1_OK=1; else T1_OK=0; fi
  tree "$WORK/t2"; B="$1" SKIP=1 run "$1" "$WORK/t2"
  if grep -qE 'EMPTY|not found' "$WORK/out" "$WORK/err"; then T2_OK=1; else T2_OK=0; fi
}
export B SKIP

echo "update-drift Step 0 handoff — seeded cases"
mkdir -p "$WORK/real"; extract "$TPL" "$WORK/real"

# N1 — the control: a working engine, producer then consumer, every pin stamped.
tree "$WORK/n1"; B="$WORK/real" SKIP="" run "$WORK/real" "$WORK/n1"
if grep -q 'mentioned pairs: 2  stamped pairs: 2' "$WORK/out" && ! grep -q 'MATCHER FAILED' "$WORK/err"; then
  pass "N1 working engine: 2 mentioned, 2 stamped, no failure reported"
else bad "N1 control — out: $(tr '\n' ' ' < "$WORK/out") err: $(head -2 "$WORK/err" | tr '\n' ' ')"; fi

score "$WORK/real"
# T1 — THE EDGE. The consumer, fed the producer's m(), must say a matcher failed
# rather than print a smaller stamped side as if it were a finding.
[ "$T1_OK" = 1 ] && pass "T1 a failing engine is reported by the CONSUMER block, not only the producer" \
                 || bad "T1 the reconciliation swallowed a failed matcher — err: $(head -2 "$WORK/err" | tr '\n' ' ')"
# T2 — the consumer run WITHOUT its producer (a fresh shell, which Step 0 warns
# against) must not read as a clean reconciliation.
[ "$T2_OK" = 1 ] && pass "T2 the consumer without its producer is loud, not clean" \
                 || bad "T2 the consumer ran without m() and looked clean — out: $(tr '\n' ' ' < "$WORK/out")"

# ── Ablation: the pre-review consumer ─────────────────────────────────────────
# A1 puts back what the #211 fix first shipped: the reconciliation on bare grep
# with its errors discarded. T1 must flip; T2 need not.
if [ "$FAIL" -ne 0 ]; then echo "  UNSCORED  ablation A1 — a seeded case already failed in this run (#161)"
else
  mkdir -p "$WORK/abl"; cp "$WORK/real/blk1.sh" "$WORK/abl/"
  # Exactly the pre-review lines: the piped mention grep kept its pipe, the three
  # stamp greps each ended `2>/dev/null || :`.
  sed -E -e 's/^m (-rnoE .*) \$OPERANDS \|$/command grep \1 $OPERANDS 2>\/dev\/null |/' \
         -e 's/^([{ ]*)m (-roEi? .*) \$OPERANDS$/\1command grep \2 $OPERANDS 2>\/dev\/null || :/' \
         "$WORK/real/blk2.sh" > "$WORK/abl/blk2.sh"
  if cmp -s "$WORK/real/blk2.sh" "$WORK/abl/blk2.sh"; then bad "ablation A1 changed nothing — its site moved"
  else
    score "$WORK/abl"
    [ "$T1_OK" = 0 ] && pass "ablation A1 (consumer on bare grep, errors discarded) stops T1" \
                     || bad "ablation A1 did not stop T1 — the case does not test the edge"
  fi
fi

echo
[ "$FAIL" -eq 0 ] && { echo "drift-handoff: all cases behaved."; exit 0; }
echo "drift-handoff: regressions above."; exit 1
