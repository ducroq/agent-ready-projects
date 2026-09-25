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
# A clean result must also print what it compared: an early exit 0 is not a pass.
want_clean() { run "$2" "${4:-}"; if [ "$RC" -eq 0 ] && [ ! -s "$OUT" ] && grep -qF -- "$3" "$ERR"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
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
repo "$WORK/t5" 100 150 $'## v1.1.0(2026-01-02)\n\n## v1.0.0 (2026-01-01)'
repo "$WORK/n5" 100 150 $'<!--\n## v1.1.0 (2026-01-02)\n-->\n## v1.1.0 (candidate, unreleased)\n\n## v1.0.0 (2026-01-01)'
repo "$WORK/n6" 100 150 $'## v1.1.0 (2026-01-02)\n\nAdopter-facing size: +50 bytes.\n\n## v1.0.0 (2026-01-01)'
( cd "$WORK/n6" && echo 'templates/scratch.md' > .gitignore && echo 'not tracked' > templates/scratch.md )
repo "$WORK/n7" 100 150 $'## v1.1.0 (2026-01-02)\r\n\r\nAdopter-facing size: +50 bytes.\r\n\r\n## v1.0.0 (2026-01-01)\r'
mkdir -p "$WORK/s1/templates" && ( cd "$WORK/s1" && git init -q . && git config user.email f@x && git config user.name f &&
  echo x > templates/s.md && printf '%s\n' "$D" > CHANGELOG.md && git add -A && git commit -qm a )

echo "cases"
want_fail  "growth with no size line fails"                   "$WORK/t1" "grows templates/ by +50 bytes"
want_fail  "a size line with the wrong number fails"          "$WORK/t2" "says 'Adopter-facing size: +20 bytes'"
want_fail  "a tagged release is measured at its tag"          "$WORK/t3" "grows templates/ by +50 bytes"
want_fail  "a size line in an older block does not count"     "$WORK/t4" "grows templates/ by +50 bytes"
want_fail  "a heading glued to its date still parses as v1.1.0" "$WORK/t5" "grows templates/ by +50 bytes"
want_clean "growth with the right size line passes"           "$WORK/n1" "bytes against v1.0.0"
want_clean "a candidate top block is not checked"             "$WORK/n2" "is a candidate"
want_clean "a shrink needs no size line"                      "$WORK/n3" "bytes against v1.0.0"
want_clean "a size with a thousands comma is read"            "$WORK/n4" "bytes against v1.0.0"
want_clean "a dated heading inside a comment is skipped"      "$WORK/n5" "is a candidate"
want_clean "an ignored template file is not counted"          "$WORK/n6" "bytes against v1.0.0"
want_clean "CRLF line endings are read"                       "$WORK/n7" "bytes against v1.0.0"
want_skip  "no earlier release tag SKIPS, never passes"       "$WORK/s1"

# Ablations: remove one guard and show the case that depends on it now goes wrong.
# ablate: a seeded failure must now be missed (rc 0, with a coverage line).
# ablate_clean: a clean case must now be reported as a failure (rc 1).
echo "ablations"
mutate() { MUT="$WORK/mut.sh"
  if ! sed "$2" "$RULE" > "$MUT" || [ ! -s "$MUT" ]; then printf '  FAIL  %s — the mutation did not run\n' "$1"; FAIL=1; return 1; fi
  if cmp -s "$MUT" "$RULE"; then printf '  FAIL  %s — the mutation did not land\n' "$1"; FAIL=1; return 1; fi; }
ablate() { [ -n "${ABL_PRE+x}" ] || ABL_PRE=$FAIL; if [ "$ABL_PRE" -ne 0 ]; then printf '  UNSCORED  ablation %s — a seeded case already failed in this run, so it cannot fail (#161)\n' "$1"; return 0; fi
  mutate "$1" "$2" || return; run "$3" "$MUT"
  if [ "$RC" -eq 0 ] && grep -q 'bytes against' "$ERR"; then printf '  PASS  %s\n' "$1"
  else printf '  FAIL  %s — rc=%s; the guard is not what caught it\n' "$1" "$RC"; FAIL=1; fi; }
ablate_clean() { [ -n "${ABL_PRE+x}" ] || ABL_PRE=$FAIL; if [ "$ABL_PRE" -ne 0 ]; then printf '  UNSCORED  ablation %s — a seeded case already failed in this run, so it cannot fail (#161)\n' "$1"; return 0; fi
  mutate "$1" "$2" || return; run "$3" "$MUT"
  if [ "$RC" -eq 1 ]; then printf '  PASS  %s\n' "$1"
  else printf '  FAIL  %s — rc=%s; removing the guard changed nothing\n' "$1" "$RC"; FAIL=1; fi; }
ablate       A2-no-number-check 's/elif \[ "\$((10#\$said))" -ne "\$grow" \]; then/elif false; then/' "$WORK/t2"
ablate       A3-block-scope     's/NR > start \&\& \/\^## v\[0-9\]\/ { exit } //'            "$WORK/t4"
ablate_clean A4-shrink-guard    's/\[ "\$grow" -gt 0 \] || exit 0/true/'                   "$WORK/n3"
ablate_clean A5-tracked-only    "s/new=\$(git ls-files -z -- 'templates\/\*.md' | xargs -0 cat/new=\$(find templates -name '*.md' -type f -print0 | xargs -0 cat/" "$WORK/n6"
ablate_clean A6-comment-skip    's/^  incom { if (index(\$0, "-->")) incom = 0; next }$//; s/^  \/\^\[ \\t\]\*<!--\/ { if (!index(\$0, "-->")) incom = 1; next }$//' "$WORK/n5"

echo
if [ "$FAIL" -eq 0 ]; then echo "All release-growth fixture cases passed."; else echo "release-growth fixture: FAILURES above."; exit 1; fi
