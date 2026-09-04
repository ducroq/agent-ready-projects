#!/usr/bin/env bash
# Sensitivity fixture for lint rule 11 (tests/lint/block-parses.sh).
#
# The rule exists because #105 shipped for eight releases: an ASCII apostrophe
# inside a single-quoted awk program closed it, and the block an adopter copies
# was a shell syntax error rather than a check. T1 is that exact shape.
#
# The rule's own first draft reported "26 blocks parsed, 0 failures" while
# parsing one file's content 26 times, because awk's block counter restarts per
# file and the output names collided. It was caught by checking the count
# against a block known to fail, not by reading the code — which is why N4 is
# here: two files whose FIRST blocks differ, one broken and one clean. Under the
# collision bug the broken one is overwritten and the suite goes green.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)" || exit 2
CHK="$ROOT/tests/lint/block-parses.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
FAIL=0
mkdir -p "$W/repo/templates" "$W/repo/.claude/skills/x" "$W/repo/docs"
cd "$W/repo" || exit 2
: > adopt.md; : > README.md; : > docs/GUIDE.md
printf -- '---\nname: x\ndescription: d\n---\n' > .claude/skills/x/SKILL.md

blk() { printf '```bash\n%s\n```\n' "$2" >> "$1"; }

# --- T = must report -------------------------------------------------------
# T1 — #105's shape: an apostrophe closing a single-quoted awk program.
blk templates/t1.md "awk '
  # Step 1.5's property
  { print }
' \"\$f\""
# T2 — an unbalanced double quote.
blk templates/t2.md 'echo "unterminated'
# T3 — the marker is only honoured on the FIRST line; here it is buried, so the
# block must still be parsed and must still report. A marker anywhere would let
# an author bury an exemption in the middle of a long block.
blk templates/t3.md 'echo ok
# lint-skip: not-executable
echo "still broken'
# T4 — a reference install, not a template: the rule covers .claude/skills too,
# for the reason rule 6 does.
printf -- '---\nname: y\ndescription: d\n---\n' > .claude/skills/x/SKILL.md
blk .claude/skills/x/SKILL.md 'if [ -z "$x ]; then :; fi'

# --- N = must stay silent --------------------------------------------------
# N1 — an ordinary correct block.
blk templates/n1.md 'set -e
for f in a b; do printf "%s\n" "$f"; done'
# N2 — a declared not-executable block: unparseable BY DESIGN, marker on line 1.
blk templates/n2.md '# lint-skip: not-executable — placeholder the engineer fills in
git add CHANGELOG.md <each file updated in Step 5>'
# N3 — an angle-bracket placeholder INSIDE a quoted string or embedded program
# does not stop a block parsing, and must not be exempted. The rule's first
# draft skipped every block containing `<word>` and thereby exempted curate's
# extractor, the highest-traffic executable in the framework.
blk templates/n3.md 'OPERANDS="<project file> docs memory"
python3 - <<PY
print("<slug> is inside the program, not the shell")
PY'
# N4 — the collision control. Two files whose FIRST blocks differ: this clean
# one and T1 above. If block files are named by block ordinal alone, one
# overwrites the other and a real failure disappears.
blk templates/n4.md 'printf "first block of a second file\n"'

git init -q . 2>/dev/null; git config user.email f@x; git config user.name f; git add -A >/dev/null 2>&1

OUT="$(bash "$CHK" . 2>&1)"; RC=$?

for t in t1 t2 t3; do
  if grep -q "templates/$t.md" <<<"$OUT"; then printf '  PASS  %s reported\n' "$t"
  else printf '  FAIL  %s does not parse and was NOT reported\n' "$t"; FAIL=1; fi
done
if grep -q '.claude/skills/x/SKILL.md' <<<"$OUT"; then printf '  PASS  t4 reported (reference installs are in scope)\n'
else printf '  FAIL  t4 a broken block in a reference install was NOT reported\n'; FAIL=1; fi
for n in n1 n2 n3 n4; do
  if grep -q "templates/$n.md" <<<"$OUT"; then printf '  FAIL  %s is legal and was reported\n' "$n"; FAIL=1
  else printf '  PASS  %s stayed silent\n' "$n"; fi
done
# The coverage line must be present and must count every block, or "no output"
# from a checker that scanned nothing reads as clean.
if grep -qE 'block-parses: [0-9]+ fenced bash block\(s\) parsed' <<<"$OUT"; then
  n=$(grep -oE 'block-parses: [0-9]+' <<<"$OUT" | grep -oE '[0-9]+')
  if [ "$n" -eq 8 ]; then printf '  PASS  coverage line counts all 8 seeded blocks\n'
  else printf '  FAIL  coverage line counts %s blocks, 8 were seeded — blocks are being dropped\n' "$n"; FAIL=1; fi
else printf '  FAIL  no coverage line — a checker that scanned nothing reads as clean\n'; FAIL=1; fi
[ "$RC" -eq 1 ] && printf '  PASS  exits 1 when a block does not parse\n' || { printf '  FAIL  exited %s with 4 broken blocks seeded\n' "$RC"; FAIL=1; }
bash "$CHK" /nonexistent-for-this-test >/dev/null 2>&1; rc2=$?
[ "$rc2" -eq 2 ] && printf '  PASS  a bad root exits 2, not 0\n' || { printf '  FAIL  a bad root exited %s — a checker that cannot run must not read as clean\n' "$rc2"; FAIL=1; }

echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || echo "SENSITIVITY REGRESSION — do not ship."
exit "$FAIL"
