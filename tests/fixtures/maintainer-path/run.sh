#!/usr/bin/env bash
# Sensitivity fixture for lint rule 13 (tests/lint/maintainer-path.sh), #139/#127.
#
# The rule is a REGRESSION GUARD: the class is at 0 in this repo, so a run over
# the real tree finds nothing and cannot distinguish a working rule from a
# disabled one. Everything below is seeded for that reason.
#
# The checker is INVOKED, not copied — it runs against throwaway git repos built
# here, so it cannot drift from the shipped script.
#
# Exit: 0 all seeded cases behaved, 1 a regression.
set -u
cd "$(dirname "$0")/../../.." || exit 2
CHECK="$PWD/tests/lint/maintainer-path.sh"
[ -f "$CHECK" ] || { echo "CHECKER MISSING: $CHECK"; exit 1; }
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

# A throwaway adopter-installed tree. $1 = repo dir.
build() {
  local d="$1"; mkdir -p "$d/templates" "$d/.claude/skills/curate" "$d/docs/rationale"
  git -C "$d" init -q 2>/dev/null
  git -C "$d" config user.email t@t; git -C "$d" config user.name t
  printf 'Step 1. See docs/rationale/curate.md for why.\n'        > "$d/templates/t1_template.md"
  printf 'Step 1. See docs/rationale/review-changes.md for why.\n' > "$d/.claude/skills/curate/t2_install.md"
  printf 'Record it in CHANGELOG.md and bump the version.\n'      > "$d/templates/n1_changelog.md"
  printf -- '- tests/lint/run.sh: deterministic checks, no network\n' > "$d/templates/n2_guarantee.md"
  printf 'See docs/rationale/curate.md. lint-skip: maintainer-path\n' > "$d/templates/n3_declared.md"
  # OUTSIDE the population: adopters never install docs/, so this must stay quiet.
  printf 'The rationale lives in docs/rationale/curate.md.\n'     > "$d/docs/n4_outside.md"
  git -C "$d" add -A >/dev/null 2>&1; git -C "$d" commit -qm seed >/dev/null 2>&1
}

run() { bash "$CHECK" "$1" 2>/dev/null; }

REPO="$WORK/repo"; build "$REPO"
# T3 is UNTRACKED on purpose: rule 12 shipped with a tracked-only population and
# passed clean over its own fixture, then reported it once committed.
printf 'New step, points at docs/rationale/release.md.\n' > "$REPO/templates/t3_untracked.md"

out="$(run "$REPO")"
want_hit()   { if printf '%s' "$out" | grep -q "$1"; then printf '  PASS  %s %s\n' "$1" "$2"; else printf '  FAIL  %s not reported — %s\n' "$1" "$2"; FAIL=1; fi; }
want_quiet() { if printf '%s' "$out" | grep -q "$1"; then printf '  FAIL  %s reported — %s\n' "$1" "$2"; FAIL=1; else printf '  PASS  %s %s\n' "$1" "$2"; fi; }

want_hit   t1_template.md  "a template pointing at docs/rationale/ is reported — the #139 class"
want_hit   t2_install.md   "a reference install pointing at it is reported — the copy adopters derive from"
want_hit   t3_untracked.md "an UNTRACKED new file is reported: population is tracked PLUS untracked-not-ignored"
want_quiet n1_changelog.md "CHANGELOG.md is an adopter's own file — 17 legitimate hits on the real surface"
want_quiet n2_guarantee.md "tests/lint/run.sh in the guarantee lens names a file in the ADOPTER's tree, by design"
want_quiet n3_declared.md  "a DECLARED exemption is honoured — rule 11's lesson: declared, never guessed"
want_quiet n4_outside.md   "docs/ is outside the population: adopters install templates/ and skills, not our docs"

# Exit code is part of the contract: run.sh keys on it.
run "$REPO" >/dev/null 2>&1; rc=$?
[ "$rc" = "1" ] && printf '  PASS  exit 1 on findings\n' || { printf '  FAIL  exit was %s, wanted 1 on findings\n' "$rc"; FAIL=1; }
CLEAN="$WORK/clean"; build "$CLEAN"
rm -f "$CLEAN/templates/t1_template.md" "$CLEAN/.claude/skills/curate/t2_install.md"
git -C "$CLEAN" add -A >/dev/null 2>&1; git -C "$CLEAN" commit -qm clean >/dev/null 2>&1
bash "$CHECK" "$CLEAN" >/dev/null 2>&1; rc=$?
[ "$rc" = "0" ] && printf '  PASS  exit 0 on a clean tree — precision control\n' || { printf '  FAIL  clean tree exited %s, wanted 0\n' "$rc"; FAIL=1; }

# A tree with no adopter-installed files at all must NOT read as a pass.
EMPTY="$WORK/empty"; mkdir -p "$EMPTY"; git -C "$EMPTY" init -q 2>/dev/null
bash "$CHECK" "$EMPTY" >/dev/null 2>&1; rc=$?
[ "$rc" = "2" ] && printf '  PASS  exit 2 on an EMPTY population — a rule that scanned nothing is not clean\n' || { printf '  FAIL  empty population exited %s, wanted 2\n' "$rc"; FAIL=1; }

# Ablations. Each reverts one guard; the kill set is MEASURED by running it.
ablate() {
  local label="$1" old="$2" new="$3" want="$4" got o
  sed "s|$old|$new|" "$CHECK" > "$WORK/mut.sh" || { printf '  FAIL  ablation %s could not be applied\n' "$label"; FAIL=1; return; }
  cmp -s "$CHECK" "$WORK/mut.sh" && { printf '  FAIL  ablation %s changed NOTHING — its site has moved\n' "$label"; FAIL=1; return; }
  o="$(bash "$WORK/mut.sh" "$REPO" 2>/dev/null)"
  got=""
  for c in t1_template.md t2_install.md t3_untracked.md n1_changelog.md n2_guarantee.md n3_declared.md n4_outside.md; do
    case "$c" in
      t*) printf '%s' "$o" | grep -q "$c" || got="$got,$c" ;;
      n*) printf '%s' "$o" | grep -q "$c" && got="$got,$c" ;;
    esac
  done
  got="${got#,}"
  [ "$got" = "$want" ] && printf '  PASS  ablation %s fails exactly [%s]\n' "$label" "$want" \
    || { printf '  FAIL  ablation %s should fail [%s], failed [%s]\n' "$label" "$want" "$got"; FAIL=1; }
}

ablate "A1 stop honouring the declared exemption" \
       'case "$hit" in \*"lint-skip: maintainer-path"\*) continue ;; esac' 'case "$hit" in *"ZZZNOTAMARKER"*) continue ;; esac' \
       "n3_declared.md"
ablate "A2 population becomes tracked-only" \
       'git ls-files --others --exclude-standard -- templates .claude/skills' 'true' \
       "t3_untracked.md"

[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || echo "SENSITIVITY REGRESSION — do not ship."
exit "$FAIL"
