#!/usr/bin/env bash
# Sensitivity fixture for lint rule 20 (tests/lint/shell-parse.sh).
#
# The real tree parses today, so a run over it cannot tell a working rule from a
# disabled one. Every case here is seeded. T1 and T2 are the two forms #160
# observed; N1 carries both, correctly escaped, and must stay quiet.
set -u
cd "$(dirname "$0")/../../.." || exit 2
RULE="$PWD/tests/lint/shell-parse.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

run() { OUT="$WORK/out"; ERR="$WORK/err"; bash "${2:-$RULE}" "$1" >"$OUT" 2>"$ERR"; RC=$?; }
want_fail() { run "$2" "${4:-}"; if [ "$RC" -eq 1 ] && grep -q "$3" "$OUT"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s\n' "$1" "$RC"; FAIL=1; fi; }
want_clean(){ run "$2"; if [ "$RC" -eq 0 ] && [ ! -s "$OUT" ] && grep -q 'file(s) found' "$ERR"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_rc()   { run "$2"; if [ "$RC" -eq "$3" ]; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s wanted %s\n' "$1" "$RC" "$3"; FAIL=1; fi; }

echo "rule 20 — seeded cases"

# N1 — both observed forms, written correctly: an apostrophe as \047 inside a
# single-quoted awk program, and an escaped backtick inside double quotes.
mkdir -p "$WORK/n1/tests"
cat > "$WORK/n1/tests/ok.sh" <<'EOF'
awk '# the program\047s own comment
{ print }' /dev/null
echo "see \`code\` here"
EOF
want_clean "N1 correctly escaped apostrophe and backtick parse" "$WORK/n1"

# T1 — an ASCII apostrophe in a comment inside a single-quoted awk program closes
# the shell string; the rest of the file is shell. Instances 1 and 2 of #160.
mkdir -p "$WORK/t1/tests"
cat > "$WORK/t1/tests/bad.sh" <<'EOF'
awk '# the program's own comment
{ print }' /dev/null
EOF
want_fail "T1 an apostrophe inside single-quoted awk is reported" "$WORK/t1" "tests/bad.sh: does not parse"

# T2 — an unpaired backtick inside a double-quoted argument. Instance 4 of #160.
mkdir -p "$WORK/t2/scripts"
printf 'ablate "A1 drop the `x check" old new\n' > "$WORK/t2/scripts/bad.sh"
want_fail "T2 an unpaired backtick inside double quotes is reported" "$WORK/t2" "scripts/bad.sh: does not parse"

# T3 — a path with a space is one file, not two.
mkdir -p "$WORK/t3/tests/a b"
printf 'echo "unclosed\n' > "$WORK/t3/tests/a b/bad.sh"
want_fail "T3 a path with a space is reported whole" "$WORK/t3" "tests/a b/bad.sh: does not parse"

# T4 — an empty population is not a clean one.
mkdir -p "$WORK/t4/tests"
want_rc "T4 no shell files exits 2, never 0" "$WORK/t4" 2

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
  for c in t1 t2 t3 t4; do
    run "$WORK/$c" "$mut"
    [ "$RC" -eq 0 ] && got="$got,$c"
  done
  got="${got#,}"
  if [ "$got" = "$want" ]; then printf '  PASS  ablation %s stops catching exactly [%s]\n' "$label" "$want"
  else printf '  FAIL  ablation %s should stop catching [%s], stopped [%s]\n' "$label" "$want" "$got"; FAIL=1; fi
}
ablate "A1 never parse"             'if ! err=$(bash -n "$f" 2>&1); then' 'if ! err=$(true); then' "t1,t2,t3"
ablate "A2 an empty tree is clean"  '[ "$found" -gt 0 ] || {' '[ "$found" -ge 0 ] || {' "t4"

echo
[ "$FAIL" -eq 0 ] && { echo "All seeded cases behaved correctly."; exit 0; }
echo "shell-parse: regressions above."; exit 1
