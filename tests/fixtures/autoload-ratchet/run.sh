#!/usr/bin/env bash
# Sensitivity fixture for lint rule 15 (tests/lint/autoload-ratchet.sh).
#
# A ratchet that never fires is indistinguishable from one that cannot. Every
# case below seeds a movement the rule must still catch, in BOTH directions:
# growth is the defect, but an unlocked shrink is also reported, because a
# reduction nobody locks in drifts straight back — which is the entire failure
# this rule was built after watching happen in one session.
#
# CASE COUNTS ARE COMMANDS, NOT DIGITS:
#   t/n  grep -cE '^(want|skip)_' run.sh
#   abl  grep -cE '^ablate ' run.sh
#
# READ BEFORE LOOSENING: the SKIP arm is the dangerous one. It exists because
# memory/MEMORY.md is gitignored and CI has half the population — but a skip is
# a loosening, and T5 is what stops it widening into "any missing file is fine".
set -u
cd "$(dirname "$0")/../../.." || exit 2
ROOT="$PWD"
RULE="$ROOT/tests/lint/autoload-ratchet.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

# build <dir> — a scratch tree carrying only what rule 15 reads.
build() {
  local d="$1"
  mkdir -p "$d/tests/lint" "$d/memory"
  printf '# Project\n\nsome orientation\n' > "$d/CLAUDE.md"
  { echo "# Memory"; echo; for i in 1 2 3 4 5; do echo "- pointer $i"; done; } > "$d/memory/MEMORY.md"
  ( cd "$d" && bash "$RULE" . --update >/dev/null 2>&1 )
}

run() { OUT="$WORK/out"; ERR="$WORK/err"; ( cd "$1" && bash "${3:-$RULE}" . ) >"$OUT" 2>"$ERR"; RC=$?; }

want_fail() {  # label, dir, needle
  run "$2"
  if [ "$RC" -eq 1 ] && grep -q "$3" "$OUT"; then printf '  PASS  %s\n' "$1"
  else printf '  FAIL  %s — rc=%s, stdout: %s\n' "$1" "$RC" "$(head -2 "$OUT" | tr '\n' ' ')"; FAIL=1; fi
}
want_clean() {  # label, dir
  run "$2"
  if [ "$RC" -eq 0 ] && [ ! -s "$OUT" ] && grep -q 'auto-loaded file(s) measured' "$ERR"; then printf '  PASS  %s\n' "$1"
  else printf '  FAIL  %s — rc=%s, stdout: %s\n' "$1" "$RC" "$(head -2 "$OUT" | tr '\n' ' ')"; FAIL=1; fi
}
want_rc() { run "$2"; if [ "$RC" -eq "$3" ]; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, wanted %s\n' "$1" "$RC" "$3"; FAIL=1; fi; }
skip_case() {  # label, dir — must SKIP loudly and NOT pass silently
  run "$2"
  if [ "$RC" -eq 0 ] && grep -q '^SKIPPED:' "$ERR" && [ ! -s "$OUT" ]; then printf '  PASS  %s\n' "$1"
  else printf '  FAIL  %s — rc=%s, stderr: %s\n' "$1" "$RC" "$(head -1 "$ERR")"; FAIL=1; fi
}

echo "rule 15 — seeded cases"

# N1 — the control. An untouched tree at its own ceiling is silent.
build "$WORK/n1"
want_clean "N1 a tree at its ceiling is silent and reports both numbers" "$WORK/n1"

# T1 — bytes grow. The defect this rule exists for.
build "$WORK/t1"; printf 'one more paragraph of orientation nobody asked for\n' >> "$WORK/t1/CLAUDE.md"
want_fail "T1 growth in the project file is reported" "$WORK/t1" "auto-loaded set GREW"

# T2 — the index grows in LINES while staying small in bytes. audit-context
# prescribes lines for an index and declines to prescribe characters, so a rule
# watching bytes alone would pass this.
# ⚠️ Bytes are held EXACTLY equal — a space is swapped for a newline, one byte
# for one byte. A first draft appended lines, which also grew the bytes, so the
# case passed on the bytes arm and A2 killed nothing: a case passing for a
# different reason than the one it is named for.
build "$WORK/t2"
python3 - "$WORK/t2/memory/MEMORY.md" <<'EOF'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
i = s.index("- pointer 1") + len("- pointer")
p.write_text(s[:i] + "\n" + s[i+1:])
EOF
b_was=$(sed -n 's/^# BYTES \([0-9]*\).*/\1/p' "$WORK/t2/tests/lint/autoload-baseline.tsv")
b_now=$(( $(wc -c < "$WORK/t2/CLAUDE.md") + $(wc -c < "$WORK/t2/memory/MEMORY.md") ))
[ "$b_was" = "$b_now" ] || { echo "  FAIL  T2 setup: bytes moved $b_was -> $b_now, so this case cannot isolate the line arm"; FAIL=1; }
want_fail "T2 index line growth is reported at IDENTICAL bytes" "$WORK/t2" "GREW to"

# T3 — a shrink NOBODY LOCKED IN is reported too. Not pedantry: an unlocked
# reduction leaves the ceiling where it was, so the bytes drift straight back and
# the rule reports nothing when they do.
build "$WORK/t3"; printf '# Project\n' > "$WORK/t3/CLAUDE.md"
want_fail "T3 an unlocked shrink is reported, not silently accepted" "$WORK/t3" "SMALLER than the ceiling"

# T4 — --update refuses to raise. The ratchet's whole contract: the ceiling moves
# down by itself and up only by a deliberate, recorded act.
build "$WORK/t4"; printf 'growth\n' >> "$WORK/t4/CLAUDE.md"
( cd "$WORK/t4" && bash "$RULE" . --update >/dev/null 2>&1 )
if [ "$?" -eq 2 ] && [ "$(sed -n 's/^# BYTES \([0-9]*\).*/\1/p' "$WORK/t4/tests/lint/autoload-baseline.tsv")" != "" ]; then
  run "$WORK/t4"
  if [ "$RC" -eq 1 ]; then printf '  PASS  %s\n' "T4 --update refuses to raise the ceiling"
  else printf '  FAIL  T4 --update raised the ceiling silently\n'; FAIL=1; fi
else printf '  FAIL  T4 --update did not refuse (rc was not 2)\n'; FAIL=1; fi

# T5 — the SKIP arm, and its bound. A missing member must SKIP LOUDLY: measuring
# the rest would read as a huge shrink and fail the lock-it-in arm, turning a
# green CI red for a file that was never meant to be there.
build "$WORK/t5"; rm -f "$WORK/t5/memory/MEMORY.md"
skip_case "T5 an absent index SKIPS loudly instead of measuring half the set" "$WORK/t5"

# T6 — no baseline is not a pass.
build "$WORK/t6"; rm -f "$WORK/t6/tests/lint/autoload-baseline.tsv"
want_rc "T6 a missing baseline exits 2, never 0" "$WORK/t6" 2

# ── Ablations ─────────────────────────────────────────────────────────────────
ablate() {  # label, old, new, cases that must flip to clean
  [ -n "${ABL_PRE+x}" ] || ABL_PRE=$FAIL; if [ "$ABL_PRE" -ne 0 ]; then printf '  UNSCORED  ablation %s — a seeded case already failed in this run, so it cannot fail (#161)\n' "$1"; return 0; fi
  local label="$1" old="$2" new="$3" want="$4" got="" mut="$WORK/mutant.sh"
  OLD="$old" NEW="$new" python3 -c '
import os, sys, pathlib
s = pathlib.Path(sys.argv[1]).read_text()
old, new = os.environ["OLD"], os.environ["NEW"]
if old not in s: sys.exit("ABLATION ANCHOR MISSING: %r" % old)
pathlib.Path(sys.argv[2]).write_text(s.replace(old, new, 1))
' "$RULE" "$mut" || { printf '  FAIL  ablation %s could not be applied\n' "$label"; FAIL=1; return; }
  for c in t1 t2 t3; do
    run "$WORK/$c" "" "$mut"
    [ "$RC" -eq 0 ] && got="$got,$c"
  done
  got="${got#,}"
  if [ "$got" = "$want" ]; then printf '  PASS  ablation %s stops catching exactly [%s]\n' "$label" "$want"
  else printf '  FAIL  ablation %s should stop catching [%s], stopped [%s]\n' "$label" "$want" "$got"; FAIL=1; fi
}

ablate "A1 bytes may grow" 'if [ "$bytes" -gt "$wb" ]; then' 'if [ 1 -eq 0 ]; then' "t1"
ablate "A2 index lines may grow" 'if [ "$lines" -gt "$wl" ]; then' 'if [ 1 -eq 0 ]; then' "t2"
# A3 — dropping the unlocked-shrink arm is the loosening most likely to be
# proposed ("a shrink is good, why fail?"). It must break T3, which is the case
# that says an unlocked reduction is a ceiling nobody moved.
ablate "A3 an unlocked shrink is accepted" \
  'elif [ "$bytes" -lt "$wb" ]; then' \
  'elif [ 1 -eq 0 ]; then' "t3"

echo
[ "$FAIL" -eq 0 ] && { echo "autoload-ratchet: all cases behaved."; exit 0; }
echo "autoload-ratchet: regressions above."; exit 1
