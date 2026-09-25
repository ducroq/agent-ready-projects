#!/usr/bin/env bash
# Sensitivity fixture for lint rule 19 (tests/lint/release-growth.sh), H-022.
#
# CASE COUNTS ARE COMMANDS, NOT DIGITS:  grep -cE '^want_' run.sh · grep -cE '^ablate ' run.sh
set -u
cd "$(dirname "$0")/../../.." || exit 2
RULE="$PWD/tests/lint/release-growth.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

# repo <dir> <v1.0.0 template bytes> <head template bytes> <changelog> [tag-head-as]
# A scratch repo: v1.0.0 tagged with a template of the first size, then HEAD with
# the second size and the given CHANGELOG. The last argument tags HEAD too.
repo() {
  local d="$1" a="$2" b="$3" text="$4" tag="${5:-}"
  mkdir -p "$d/templates"; ( cd "$d" && git init -q . && git config user.email f@x && git config user.name f
    head -c "$a" /dev/zero | tr '\0' x > templates/s.md
    printf '## v1.0.0 (2026-01-01)\n' > CHANGELOG.md
    git add -A && git commit -qm a && git tag v1.0.0
    head -c "$b" /dev/zero | tr '\0' x > templates/s.md
    printf '%s\n' "$text" > CHANGELOG.md
    git add -A && git commit -qm b
    [ -z "$tag" ] || git tag "$tag" )
}
run() { OUT="$WORK/out"; ERR="$WORK/err"; bash "${2:-$RULE}" "$1" >"$OUT" 2>"$ERR"; RC=$?; }
want_fail()  { run "$2" "${4:-}"; if [ "$RC" -eq 1 ] && grep -qF -- "$3" "$OUT"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_clean() { run "$2" "${3:-}"; if [ "$RC" -eq 0 ] && [ ! -s "$OUT" ]; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_skip()  { run "$2"; if [ "$RC" -eq 3 ] && grep -q 'SKIPPED' "$ERR"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s\n' "$1" "$RC"; FAIL=1; fi; }

D=$'## v1.1.0 (2026-01-02)\n\nSome change.\n\n## v1.0.0 (2026-01-01)'
repo "$WORK/t1" 100 150 "$D"
repo "$WORK/t2" 100 150 $'## v1.1.0 (2026-01-02)\n\nAdopter-facing size: +20 bytes.\n\n## v1.0.0 (2026-01-01)'
repo "$WORK/t3" 100 150 "$D" v1.1.0
repo "$WORK/t4" 100 150 $'## v1.1.0 (2026-01-02)\n\n## v1.0.9 (2026-01-01)\n\nAdopter-facing size: +50 bytes.'
repo "$WORK/n1" 100 150 $'## v1.1.0 (2026-01-02)\n\n**Adopter-facing size:** +50 bytes (a new skill).\n\n## v1.0.0 (2026-01-01)'
repo "$WORK/n2" 100 150 $'## v1.1.0 (candidate, unreleased)\n\n## v1.0.0 (2026-01-01)'
repo "$WORK/n3" 150 100 "$D"
repo "$WORK/n4" 100 1100 $'## v1.1.0 (2026-01-02)\n\nAdopter-facing size: +1,000 bytes.\n\n## v1.0.0 (2026-01-01)'
mkdir -p "$WORK/s1/templates" && ( cd "$WORK/s1" && git init -q . && git config user.email f@x && git config user.name f &&
  echo x > templates/s.md && printf '%s\n' "$D" > CHANGELOG.md && git add -A && git commit -qm a )

echo "cases"
want_fail  "growth with no size line fails"                   "$WORK/t1" "grows templates/ by +50 bytes"
want_fail  "a size line with the wrong number fails"          "$WORK/t2" "says 'Adopter-facing size: +20 bytes'"
want_fail  "a tagged release is measured at its tag"          "$WORK/t3" "grows templates/ by +50 bytes"
want_fail  "a size line in an older block does not count"     "$WORK/t4" "grows templates/ by +50 bytes"
want_clean "growth with the right size line passes"           "$WORK/n1"
want_clean "a candidate top block is not checked"             "$WORK/n2"
want_clean "a shrink needs no size line"                      "$WORK/n3"
want_clean "a size with a thousands comma is read"            "$WORK/n4"
want_skip  "no earlier release tag SKIPS, never passes"       "$WORK/s1"

# Ablations: remove one guard and require its own defect to appear.
echo "ablations"
ablate() {
  local name="$1" expr="$2" case_dir="$3" mut="$WORK/mut.sh"
  if ! sed "$expr" "$RULE" > "$mut" || [ ! -s "$mut" ]; then printf '  FAIL  %s — the mutation did not run\n' "$name"; FAIL=1; return; fi
  if cmp -s "$mut" "$RULE"; then printf '  FAIL  %s — the mutation did not land\n' "$name"; FAIL=1; return; fi
  run "$case_dir" "$mut"
  if [ "$RC" -eq 1 ]; then printf '  FAIL  %s — still caught the defect with the guard removed\n' "$name"; FAIL=1
  else printf '  PASS  %s\n' "$name"; fi
}
ablate A1-no-growth-check 's/\[ "\$grow" -gt 0 \] || exit 0/exit 0/'              "$WORK/t1"
ablate A2-no-number-check 's/elif \[ "\$said" != "\$grow" \]; then/elif false; then/' "$WORK/t2"
ablate A3-block-scope     's|f \&\& /\^## v\[0-9\]/ { exit }||'                    "$WORK/t4"

echo
if [ "$FAIL" -eq 0 ]; then echo "All release-growth fixture cases passed."; else echo "release-growth fixture: FAILURES above."; exit 1; fi
