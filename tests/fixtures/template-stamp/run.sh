#!/usr/bin/env bash
# Sensitivity fixture for lint rule 21 (tests/lint/template-stamp.sh).
#
# The real tree is clean for this class, so a run over it cannot tell a working
# rule from a disabled one. Each case builds a throwaway repo in one of the
# tag/stamp states #171 tabulated. T1 and T2 are v1.41.0 before and after its
# tag; F2 is the one legitimately-ahead state, a release commit awaiting its tag.
set -u
cd "$(dirname "$0")/../../.." || exit 2
RULE="$PWD/tests/lint/template-stamp.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

g() { git -C "$1" -c user.email=f@x -c user.name=f "${@:2}" >/dev/null 2>&1; }
# repo <dir> <top heading> <stamp>: one commit, CHANGELOG top block + two stamped templates.
# Every CHANGELOG here opens with a FENCED '## v9.9.9': read as the top block, it
# would fail F1 and F2, so those two also pin the fence skip.
repo() {
  mkdir -p "$1/templates"; git init -q "$1"
  stamp "$1" "$2" "$3"
}
stamp() {
  printf '# Changelog\n\n```\n## v9.9.9\n```\n\n%s\n\n- a change\n' "$2" > "$1/CHANGELOG.md"
  printf -- '---\nframework: agent-ready-projects %s   # a NUMBER\n---\n' "$3" > "$1/templates/project-file.md"
  printf -- '---\nframework: agent-ready-projects %s\n---\n' "$3" > "$1/templates/coordination.md"
  g "$1" add -A; g "$1" commit -qm "$3"
}

run() { OUT="$WORK/out"; ERR="$WORK/err"; bash "${2:-$RULE}" "$1" >"$OUT" 2>"$ERR"; RC=$?; }
want_fail() { run "$2"; if [ "$RC" -eq 1 ] && grep -q "$3" "$OUT"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_clean(){ run "$2"; if [ "$RC" -eq 0 ] && [ ! -s "$OUT" ] && grep -q 'checked against' "$ERR"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_rc()   { run "$2"; if [ "$RC" -eq "$3" ]; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s wanted %s\n' "$1" "$RC" "$3"; FAIL=1; fi; }

echo "rule 21 — seeded cases"

# F1 — ordinary development: candidate block, stamps equal the tag.
repo "$WORK/f1" '## v1.2.0 (2026-01-01)' v1.2.0; g "$WORK/f1" tag v1.2.0
stamp "$WORK/f1" '## v1.2.1 (candidate, unreleased)' v1.2.0
want_clean "F1 between releases, stamps equal the highest tag" "$WORK/f1"

# F2 — a release commit awaiting its tag: dated block one ahead of the tag.
repo "$WORK/f2" '## v1.2.0 (2026-01-01)' v1.2.0; g "$WORK/f2" tag v1.2.0
stamp "$WORK/f2" '## v1.3.0 (2026-02-01)' v1.3.0
want_clean "F2 release commit before tagging, stamps equal the dated block" "$WORK/f2"

# T1 — v1.41.0 BEFORE its tag: the block is dated, the stamps were not bumped.
repo "$WORK/t1" '## v1.2.0 (2026-01-01)' v1.2.0; g "$WORK/t1" tag v1.2.0
stamp "$WORK/t1" '## v1.3.0 (2026-02-01)' v1.2.0
want_fail "T1 dated block, stamps not bumped" "$WORK/t1" "the dated block v1.3.0 says v1.3.0"

# T2 — v1.41.0 AFTER its tag: the wrap-up commit bumped the stamps, so the working
# tree is right and only `git show <tag>:` can see the defect.
repo "$WORK/t2" '## v1.2.0 (2026-01-01)' v1.2.0; g "$WORK/t2" tag v1.2.0
stamp "$WORK/t2" '## v1.3.0 (2026-02-01)' v1.2.0; g "$WORK/t2" tag v1.3.0
stamp "$WORK/t2" '## v1.3.1 (candidate, unreleased)' v1.3.0
want_fail "T2 the tag ships an old stamp; the working tree is correct" "$WORK/t2" "the v1.3.0 tag ships it stamped v1.2.0"

# T3 — between releases, stamps BEHIND the tag.
repo "$WORK/t3" '## v1.2.0 (2026-01-01)' v1.2.0; g "$WORK/t3" tag v1.2.0
stamp "$WORK/t3" '## v1.2.1 (candidate, unreleased)' v1.1.0
want_fail "T3 candidate block, stamps behind the tag" "$WORK/t3" "highest reachable tag v1.2.0 says v1.2.0"

# T4 — between releases, stamps AHEAD of the tag: a bump with no release behind it.
repo "$WORK/t4" '## v1.2.0 (2026-01-01)' v1.2.0; g "$WORK/t4" tag v1.2.0
stamp "$WORK/t4" '## v1.2.1 (candidate, unreleased)' v1.4.0
want_fail "T4 candidate block, stamps ahead of the tag" "$WORK/t4" "stamped v1.4.0"

# S1 — candidate block and no tags: nothing can be checked, and it says so.
repo "$WORK/s1" '## v1.2.1 (candidate, unreleased)' v1.2.0
want_rc "S1 candidate block with no tags exits 3 (SKIPPED), never 0" "$WORK/s1" 3

# E1 — no stamped template: an empty population is not a clean one.
repo "$WORK/e1" '## v1.2.0 (2026-01-01)' v1.2.0; rm "$WORK/e1/templates/"*.md
want_rc "E1 no stamped template exits 2, never 0" "$WORK/e1" 2

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
ablate "A1 a dated block is treated as a candidate" '  *) want="$topv"; ran="dated block $topv" ;;' '  *) want="" ;;' "t1"
ablate "A2 never read the tag's own templates"      's=$(git show "$tag:$f" 2>/dev/null | stamp_of) || continue' 's=$tag' "t2"
ablate "A3 never compare with the highest tag"      '  want="$tag"; ran="highest reachable tag $tag"' '  ran="highest reachable tag $tag"' "t3,t4"

echo
[ "$FAIL" -eq 0 ] && { echo "All seeded cases behaved correctly."; exit 0; }
echo "template-stamp: regressions above."; exit 1
