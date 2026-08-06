#!/usr/bin/env bash
# Sensitivity harness for audit-context Step 4.
#
# Any change that makes Step 4 more permissive must still report every seeded
# case below. Run this BEFORE and AFTER such a change and compare.
set -euo pipefail
cd "$(dirname "$0")"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
bash build.sh "$WORK" >/dev/null

DOCS="CLAUDE.md docs/ADVERSARIAL.md docs/MONOREPO.md docs/EXOTIC.md memory/MEMORY.md memory/gotcha-log.md"
OUT="$(python3 refcheck.py "$WORK/repo" $DOCS || true)"
FINDINGS="$(printf '%s' "$OUT" | sed -n '/== FINDINGS/,/^  total:/p')"

# Each seeded break, and the substring that proves it was reported.
declare -a CASES=(
  "T1 fabricated path|src/utils/nonexistent_thing.py"
  "T2 local basename collision|helpers.py"
  "T3 fabricated under gitignored dir|.claude/skills/imaginary/SKILL.md"
  "T4 unmarked sibling coincidence|scripts/deploy_thing.sh"
  "T5 real move, parent changed|oldpkg/temporal.py"
  "T7 path supplies its own marker|docs/DEPLOY.md"
  "T8 substring marker must not mark|deploy/main.py"
  "T9 ambiguous inside sibling|main.py"
  "T10 deletion with surviving twin|packages/api/config/settings.py"
  "T11 unlisted extension .tf|infra/nonexistent.tf"
  "T11 unlisted extension .ipynb|notebooks/missing.ipynb"
)
# Must NOT appear in findings.
declare -a NEG=(
  "N2 hostname is not a path|www.example.com/rss.xml"
  "N3 prose deletion marker|src/utils/gone.py"
  "N6 negated existence assertion|src/utils/removed.py"
  "N7 struck path on a live line|src/utils/old_thing.py"
)

FAIL=0
for c in "${CASES[@]}"; do
  name="${c%%|*}"; needle="${c##*|}"
  if printf '%s' "$FINDINGS" | grep -qF -- "$needle"; then
    printf '  PASS  %s\n' "$name"
  else printf '  FAIL  %s (expected a finding for %s)\n' "$name" "$needle"; FAIL=1; fi
done
for c in "${NEG[@]}"; do
  name="${c%%|*}"; needle="${c##*|}"
  if printf '%s' "$FINDINGS" | grep -qF -- "$needle"; then
    printf '  FAIL  %s (must NOT be a finding: %s)\n' "$name" "$needle"; FAIL=1
  else printf '  PASS  %s\n' "$name"; fi
done

# N7's live successor must survive the strikethrough on the same line.
if printf '%s' "$OUT" | grep -q "old_thing.py.*asserted-absent"; then
  printf '  PASS  N7 struck path skipped, successor kept\n'
else printf '  FAIL  N7 strikethrough handling\n'; FAIL=1; fi

echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || echo "SENSITIVITY REGRESSION — do not ship."
exit "$FAIL"
