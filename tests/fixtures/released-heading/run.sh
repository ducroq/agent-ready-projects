#!/usr/bin/env bash
# Sensitivity fixture for lint rule 18 (tests/lint/released-heading.sh), #197.
#
# CASE COUNTS ARE COMMANDS, NOT DIGITS:  grep -cE '^want_' run.sh · grep -cE '^ablate ' run.sh
set -u
cd "$(dirname "$0")/../../.." || exit 2
RULE="$PWD/tests/lint/released-heading.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

# repo <dir> <changelog-text> <tag>... — a scratch repo with those tags.
repo() {
  local d="$1" text="$2"; shift 2
  mkdir -p "$d"; ( cd "$d" && git init -q . && git config user.email f@x && git config user.name f
    printf '%s\n' "$text" > CHANGELOG.md && git add CHANGELOG.md && git commit -qm c
    for t in "$@"; do git tag "$t"; done )
}
run() { OUT="$WORK/out"; ERR="$WORK/err"; bash "${2:-$RULE}" "$1" >"$OUT" 2>"$ERR"; RC=$?; }
want_fail()  { run "$2" "${4:-}"; if [ "$RC" -eq 1 ] && grep -qF -- "$3" "$OUT"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_clean() { run "$2" "${3:-}"; if [ "$RC" -eq 0 ] && [ ! -s "$OUT" ] && grep -q 'release tag(s) checked' "$ERR"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }

DATED=$'# Changelog\n\n## v1.1.0 (2026-01-02)\n\n## v1.0.0 (2026-01-01)'
repo "$WORK/t1" $'## v1.1.0 (candidate, unreleased)\n\n## v1.0.0 (2026-01-01)' v1.0.0 v1.1.0
repo "$WORK/t2" $'## v1.0.0 (2026-01-01)' v1.0.0 v1.1.0
repo "$WORK/n1" "$DATED" v1.0.0 v1.1.0
repo "$WORK/n2" $'## v1.2.0 (candidate, unreleased)\n\n## v1.1.0 (2026-01-02)\n\n## v1.0.0 (2026-01-01)' v1.0.0 v1.1.0
repo "$WORK/n3" $'## v2.0.0-rc1 (candidate, unreleased)\n\n## v1.0.0 (2026-01-01)' v1.0.0 v2.0.0-rc1 wip
repo "$WORK/n4" $'## v1.10.0 (2026-01-03)\n\n## v1.1.0 (candidate, unreleased)' v1.10.0
repo "$WORK/s1" "$DATED"
# c — both defects at once: each ablation must lose ITS case and keep the other.
repo "$WORK/c" $'## v1.1.0 (candidate, unreleased)\n\n## v1.0.0 (2026-01-01)' v1.0.0 v1.1.0 v1.2.0

want_fail  "T1 tagged release whose block is still a candidate" "$WORK/t1" "v1.1.0 is tagged but its block still reads"
want_fail  "T2 tagged release with no block at all"              "$WORK/t2" "v1.1.0 is tagged but has no '## v1.1.0' block"
want_clean "N1 every tag dated"                                  "$WORK/n1"
want_clean "N2 an untagged candidate block is the normal state" "$WORK/n2"
want_clean "N3 prerelease and non-version tags are not releases" "$WORK/n3"
# N4 — exact field match: v1.1.0's candidate block must not be read as v1.10.0's.
want_clean "N4 v1.10.0 is not matched by the v1.1.0 heading"     "$WORK/n4"
run "$WORK/s1"
if [ "$RC" -eq 3 ] && grep -q 'SKIPPED' "$ERR"; then printf '  PASS  S1 no release tags is SKIPPED (3), not clean\n'
else printf '  FAIL  S1 — no tags gave rc=%s, not 3\n' "$RC"; FAIL=1; fi

# Ablations — each mutant must stop catching exactly its case.
ablate() {  # ablate <label> <from> <to> <case-dir> <needle that must vanish> <control that must stay>
  local m="$WORK/mut.sh"
  python3 -c 'import sys; s=open(sys.argv[1]).read(); open(sys.argv[2],"w").write(s.replace(sys.argv[3], sys.argv[4], 1))' "$RULE" "$m" "$2" "$3"
  if cmp -s "$m" "$RULE"; then printf '  FAIL  %s — the mutation changed nothing\n' "$1"; FAIL=1; return; fi
  run "$4" "$m"
  # A mutant that crashed would also "stop catching": require its coverage line.
  if ! grep -q 'release tag(s) checked' "$ERR"; then printf '  FAIL  %s — the mutant did not run\n' "$1"; FAIL=1
  elif ! grep -qF -- "$6" "$OUT"; then printf '  FAIL  %s — the mutant lost the control (%s), so its silence proves nothing\n' "$1" "$6"; FAIL=1
  elif grep -qF -- "$5" "$OUT"; then printf '  FAIL  %s — the mutant still caught it\n' "$1"; FAIL=1
  else printf '  PASS  %s stops catching its case\n' "$1"; fi
}
ablate "A1 drop the candidate test" '*candidate*|*unreleased*)' 'NEVERMATCHES)' "$WORK/c" "still reads" "has no"
ablate "A2 drop the no-block arm"   'if [ -z "$h" ]; then'         'if false; then' "$WORK/c" "has no" "still reads"

echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || echo "SENSITIVITY REGRESSION — do not ship."
exit "$FAIL"
