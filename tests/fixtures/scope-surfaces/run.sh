#!/usr/bin/env bash
# Sensitivity fixture for lint rule 22 (tests/lint/scope-surfaces.sh).
#
# The real surfaces agree with the installer today, so a run over them cannot
# tell a working rule from a disabled one. Each case copies the REAL three
# surfaces and the installer into a scratch tree and seeds one disagreement.
# T1 is #195's own seed: GUIDE.md rewritten to install curate project-locally.
set -u
cd "$(dirname "$0")/../../.." || exit 2
ROOT="$PWD"
RULE="$ROOT/tests/lint/scope-surfaces.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

build() {
  mkdir -p "$1/docs" "$1/templates" "$1/scripts"
  cp "$ROOT/docs/GUIDE.md" "$1/docs/"; cp "$ROOT/templates/README.md" "$1/templates/"
  cp "$ROOT/adopt.md" "$1/"; cp "$ROOT/scripts/install-global-skills.sh" "$1/scripts/"
}
# seed <dir> <file> <old> <new>: exactly one replacement, or the case tests nothing
seed() {
  OLD="$3" NEW="$4" python3 -c '
import os, sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text(); old, new = os.environ["OLD"], os.environ["NEW"]
if old not in s: sys.exit("seed site absent: %r" % old)
p.write_text(s.replace(old, new, 1))' "$1/$2" || { echo "  FAIL  seed could not be applied in $1/$2"; FAIL=1; }
}

run() { OUT="$WORK/out"; ERR="$WORK/err"; bash "${2:-$RULE}" "$1" >"$OUT" 2>"$ERR"; RC=$?; }
want_fail() { run "$2"; if [ "$RC" -eq 1 ] && grep -q "$3" "$OUT"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_clean(){ run "$2"; if [ "$RC" -eq 0 ] && [ ! -s "$OUT" ] && grep -q 'install path(s) found' "$ERR"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_rc()   { run "$2"; if [ "$RC" -eq "$3" ]; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s wanted %s\n' "$1" "$RC" "$3"; FAIL=1; fi; }

echo "rule 22 — seeded cases"

build "$WORK/n1"
want_clean "N1 the real surfaces agree with the installer" "$WORK/n1"

build "$WORK/t1"; seed "$WORK/t1" docs/GUIDE.md '~/.claude/skills/curate/' '<repo>/.claude/skills/curate/'
want_fail "T1 GUIDE.md installs a global skill project-locally (#195's seed)" "$WORK/t1" "curate is in GLOBAL_SKILLS"

build "$WORK/t2"; seed "$WORK/t2" templates/README.md '~/.claude/skills/review-changes/' '<repo>/.claude/skills/review-changes/'
want_fail "T2 templates/README.md flips review-changes to <repo>/" "$WORK/t2" "review-changes is in GLOBAL_SKILLS"

build "$WORK/t3"; seed "$WORK/t3" docs/GUIDE.md '<repo>/.claude/skills/release/' '~/.claude/skills/release/'
want_fail "T3 a LOCAL_ONLY skill named under ~/" "$WORK/t3" "release is LOCAL_ONLY"

build "$WORK/t4"; printf '\nInstall at `~/.claude/skills/nonesuch/SKILL.md`.\n' >> "$WORK/t4/adopt.md"
want_fail "T4 a skill the installer does not know" "$WORK/t4" "nonesuch/\` names a skill the installer lists in neither"

# T5 — the floor. Every prefixed test-verify-memory path removed: the rule has
# lost its subject for that skill and must say so, not pass on fewer checks.
build "$WORK/t5"; sed -i 's|<repo>/\.claude/skills/test-verify-memory/|.claude/skills/test-verify-memory/|g' "$WORK/t5/templates/README.md"
grep -q '<repo>/.claude/skills/test-verify-memory/' "$WORK/t5/templates/README.md" "$WORK/t5/docs/GUIDE.md" "$WORK/t5/adopt.md" &&
  { echo "  FAIL  T5 setup: a prefixed test-verify-memory path survived, so the case tests nothing"; FAIL=1; }
want_fail "T5 a shipped skill no surface names is reported" "$WORK/t5" "test-verify-memory is shipped but no surface"

# T6 — the authority moves, the surfaces do not: scope is DERIVED from the installer.
build "$WORK/t6"
seed "$WORK/t6" scripts/install-global-skills.sh 'GLOBAL_SKILLS="curate audit-context update-drift review-changes"' 'GLOBAL_SKILLS="curate audit-context update-drift"'
seed "$WORK/t6" scripts/install-global-skills.sh 'LOCAL_ONLY="release test-verify-memory"' 'LOCAL_ONLY="release test-verify-memory review-changes"'
want_fail "T6 the installer changes a skill's scope and the surfaces lag" "$WORK/t6" "review-changes is LOCAL_ONLY"

# T7 — no trailing slash is still an install path (review finding).
build "$WORK/t7"; printf '\nInstall curate at `<repo>/.claude/skills/curate` for project use.\n' >> "$WORK/t7/adopt.md"
want_fail "T7 a path with no trailing slash is read" "$WORK/t7" "curate is in GLOBAL_SKILLS"

build "$WORK/e1"; rm "$WORK/e1/adopt.md"
want_rc "E1 a missing surface exits 2, never 0" "$WORK/e1" 2

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
  for c in t1 t2 t3 t4 t5 t6 t7; do
    run "$WORK/$c" "$mut"
    [ "$RC" -eq 0 ] && got="$got,$c"
  done
  got="${got#,}"
  if [ "$got" = "$want" ]; then printf '  PASS  ablation %s stops catching exactly [%s]\n' "$label" "$want"
  else printf '  FAIL  ablation %s should stop catching [%s], stopped [%s]\n' "$label" "$want" "$got"; FAIL=1; fi
}
ablate "A1 any prefix is fine for a global"  '[ "$prefix" = "~" ] ||' 'true ||' "t1,t2,t7"
ablate "A2 any prefix is fine for a local"   '[ "$prefix" = "<repo>" ] ||' 'true ||' "t3,t6"
ablate "A3 unknown names pass"               'echo "$f:$ln: \`$path\` names a skill the installer lists in neither GLOBAL_SKILLS nor LOCAL_ONLY"; bad=$((bad + 1))' ':' "t4"
ablate "A4 no floor"                         '    echo "rule 22: $s is shipped but no surface names its install path — its scope is not bound here"; bad=$((bad + 1)) ;;' '    : ;;' "t5"

echo
[ "$FAIL" -eq 0 ] && { echo "All seeded cases behaved correctly."; exit 0; }
echo "scope-surfaces: regressions above."; exit 1
