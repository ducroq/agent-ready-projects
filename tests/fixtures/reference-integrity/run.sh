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

DOCS="CLAUDE.md docs/ADVERSARIAL.md docs/MONOREPO.md docs/EXOTIC.md docs/PLACEHOLDERS.md memory/MEMORY.md memory/gotcha-log.md"
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
  # #69 — the whitelist is a denominator. A repo whose PRIMARY source extension
  # is missing gets a clean audit having extracted nothing, and the instrument's
  # own "extensions not extracted" line reads as trivia under a zero.
  "T16 fabricated .qmd is caught|analysis/missing.qmd"
  # #45 — the failure the placeholder skip newly permits: a marker on a path
  # that resolves. Mislabelling must not become a way to hide a real break.
  "T12 stale placeholder marker on a resolving path|src/models/temporal.py"
  "T13 stale angle-bracket marker on a resolving path|src/<real>/exists.py"
  "T14 placeholder marker covering no path|COVERS NO PATH"
  # The hiding vector the issue demanded be seeded: line-scoping relabelled a
  # co-located genuine break as intentional. The marker is span-scoped, so this
  # must stay a finding.
  "T15 unmarked break sharing a marked line|src/registry/wire_up.py"
)
# Must NOT appear in findings.
declare -a NEG=(
  "N2 hostname is not a path|www.example.com/rss.xml"
  "N3 prose deletion marker|src/utils/gone.py"
  "N6 negated existence assertion|src/utils/removed.py"
  "N7 struck path on a live line|src/utils/old_thing.py"
  "N8 marked instructional placeholder|src/aggregators/my_new_aggregator.py"
  "N9 self-announcing angle-bracket path|docs/work-items/<slug>.md"
  "N10 angle-bracket path, second form|filters/<name>/<version>/config.yaml"
  "N11 live path after a marker is not a stale marker|src/utils/redaction.py"
  "N12 leading angle bracket is extracted, not invisible|<root>/memory/MEMORY.md"
  # The failure #69's widening newly permits: every real .qmd becoming a
  # phantom. Adding an extension must buy coverage, not noise.
  "N14 a resolving .qmd stays silent|analysis/index.qmd"
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

# N13 cannot be a needle test: T14 legitimately emits the same string, so
# "absent" is unassertable. Count instead — exactly one ineffective marker is
# seeded, and a marker MENTIONED inside backticks (any doc explaining the
# convention, including the shipped step itself) must not add a second.
N_INEFFECTIVE="$(printf '%s' "$FINDINGS" | grep -c 'COVERS NO PATH' || true)"
if [ "$N_INEFFECTIVE" -eq 1 ]; then
  printf '  PASS  N13 a mentioned marker is not a used one (1 ineffective marker, not 2)\n'
else
  printf '  FAIL  N13 expected exactly 1 COVERS NO PATH finding, got %s — a marker inside backticks is being read as a marker in use\n' "$N_INEFFECTIVE"; FAIL=1
fi

# The negatives above only prove a path is not a FINDING. A path that was never
# extracted also is not a finding — which is the silent-skip failure this whole
# step is built against. Assert the counted section names them.
PLACEHELD="$(printf '%s' "$OUT" | sed -n '/== SKIPPED as declared-placeholder/,/^  total:/p')"
for want in "src/aggregators/my_new_aggregator.py" "docs/work-items/<slug>.md" \
            "filters/<name>/<version>/config.yaml" "<slug>.md" "<root>/memory/MEMORY.md"; do
  if printf '%s' "$PLACEHELD" | grep -qF -- "$want"; then
    printf '  PASS  counted as declared-placeholder: %s\n' "$want"
  else
    printf '  FAIL  %s is not in the counted skip section — skipped and never-extracted are indistinguishable\n' "$want"; FAIL=1
  fi
done

echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || echo "SENSITIVITY REGRESSION — do not ship."
exit "$FAIL"
