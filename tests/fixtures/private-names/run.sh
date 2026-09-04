#!/usr/bin/env bash
# Sensitivity fixture for lint rule 12 (tests/lint/private-names.sh).
#
# It exists because the rule it measures was prescribed in memory/gotcha-log.md
# one release BEFORE the leak it would have caught: private repo names reached
# shipped `templates/`, released `CHANGELOG.md` entries and four test fixtures,
# and the entry recording the lesson already said "needs a lint rule at the
# tracked-file boundary". A rule with no fixture is the other half of that
# failure, so every disposition below is asserted, including the SKIPS.
#
# The checker is INVOKED, never reimplemented, so it cannot drift.
set -u
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)" || exit 2
CHECK="$ROOT/tests/lint/private-names.sh"
[ -f "$CHECK" ] || { echo "CHECKER MISSING at $CHECK"; exit 1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
FAIL=0

# A throwaway repo, because the checker reads `git ls-files` — an untracked file
# is out of its population by design, and that is asserted below.
mkdir -p "$W/repo/templates" "$W/repo/docs"
cd "$W/repo" && git init -q . && git config user.email f@x && git config user.name f
cat > templates/shipped.md <<'EOF'
A cross-repo example: `PrivateThing/docs/X.md` — the shape adopters copy.
EOF
cat > docs/history.md <<'EOF'
Reported by an adopter (SecretProject, pinned v1.2.0) who ran it by hand.
Lowercased in an agent id: secretproject-a9 reviewed this.
A PUBLIC sibling is fine and deliberate: agent-ready-papers is linked on purpose.
The word infrastructure must not match a private repo called `infra`.
Ordinary research prose must not match a repo named research.
A vegan sandwich must not match a repo named Vega.
EOF
# UNTRACKED but not ignored: the new-file case, and it MUST be checked — this
# rule found a name in its own fixture only after the fixture was committed.
printf 'This file is UNTRACKED and names PrivateThing.\n' > docs/untracked.md
# GITIGNORED: maintainer-local by design (this repo's own memory/ is full of
# these names legitimately), so it must stay out of the population.
printf 'docs/ignored.md\nignored/\n' > .gitignore
printf 'This file is IGNORED and names PrivateThing.\n' > docs/ignored.md
mkdir -p ignored && printf 'PrivateThing\n' > ignored/notes.md
git add templates/shipped.md docs/history.md >/dev/null 2>&1
git commit -qm seed >/dev/null 2>&1

names="$W/names"
cat > "$names" <<'EOF'
PrivateThing
SecretProject
agent-ready-papers-NOT-THIS-ONE
infra
research
Vega
# a comment line, and a blank line, both ignored

EOF

run() { bash "$CHECK" "$W/repo" "$names" 2>"$W/err"; }
OUT="$(run)"; RC=$?
ERR="$(cat "$W/err")"

want() { # want <label> <needle-in-stdout>
  if grep -qF -- "$2" <<<"$OUT"; then printf '  PASS  %-38s %s\n' "$1" "reported"
  else printf '  FAIL  %-38s expected a violation naming: %s\n' "$1" "$2"; FAIL=1; fi
}
silent() { # silent <label> <needle-that-must-not-appear>
  if grep -qF -- "$2" <<<"$OUT"; then printf '  FAIL  %-38s reported, but it must not be\n' "$1"; FAIL=1
  else printf '  PASS  %-38s silent\n' "$1"; fi
}
err_has() { # err_has <label> <needle-in-stderr>
  if grep -qF -- "$2" <<<"$ERR"; then printf '  PASS  %-38s %s\n' "$1" "stated on stderr"
  else printf '  FAIL  %-38s expected on stderr: %s\n' "$1" "$2"; FAIL=1; fi
}

# POSITIVES — the two shapes that actually leaked
want "P1 name in a SHIPPED template"      "templates/shipped.md:1"
want "P2 name in an attribution"          "docs/history.md:1"
# Case-insensitive: an agent id derived from a repo name arrives lowercased, and
# that is exactly the form that reached a released entry here.
want "P3 lowercased in an agent id"       "docs/history.md:2"
want "P4 UNTRACKED new file is in scope"  "docs/untracked.md"

# NEGATIVES — the loosenings this rule must not cost
silent "N1 public sibling, deliberately linked"  "docs/history.md:3"
silent "N2 'infrastructure' vs a repo 'infra'"   "docs/history.md:4"
silent "N4 generic name never checked"           "docs/history.md:5"
silent "N5 short name never checked"             "docs/history.md:6"
silent "N3 gitignored file is out of population"  "docs/ignored.md"

# The two UNCHECKED dispositions must be VISIBLE, not silent. A rule that
# quietly cannot check a name is the failure this whole fixture guards.
err_has "S1 generic name declared unchecked"  "UNCHECKED (generic word"
err_has "S2 short name declared unchecked"    "UNCHECKED (shorter than"
err_has "S3 coverage line names both counts"  "name(s) checked against"

[ "$RC" -eq 1 ] && printf '  PASS  %-38s exit 1 with violations present\n' "exit status" \
  || { printf '  FAIL  %-38s expected exit 1, got %s\n' "exit status" "$RC"; FAIL=1; }

# ── The SKIP paths, which are the ones most likely to rot into a false pass ──
so="$(bash "$CHECK" "$W/repo" "$W/no-such-list" 2>&1)"; src=$?
if [ "$src" -eq 2 ] && grep -qF 'SKIPPED — no name list' <<<"$so"; then
  printf '  PASS  %-38s exit 2 and says NOTHING was checked\n' "missing list"
else
  printf '  FAIL  %-38s expected exit 2 + a SKIPPED line, got %s\n' "missing list" "$src"; FAIL=1
fi
: > "$W/empty-names"
eo="$(bash "$CHECK" "$W/repo" "$W/empty-names" 2>&1)"; erc=$?
if [ "$erc" -eq 2 ] && grep -qF '0 usable names' <<<"$eo"; then
  printf '  PASS  %-38s exit 2, not a clean 0\n' "empty list"
else
  printf '  FAIL  %-38s an empty list must not read as clean (got %s)\n' "empty list" "$erc"; FAIL=1
fi
# A list of ONLY unusable names is the subtle one: names were read, none could be
# checked, and the per-name loop produced no violation.
printf 'infra\nOPAL\n' > "$W/unusable"
uo="$(bash "$CHECK" "$W/repo" "$W/unusable" 2>&1)"; urc=$?
if [ "$urc" -eq 2 ]; then printf '  PASS  %-38s exit 2 when every name is unusable\n' "all-unusable list"
else printf '  FAIL  %-38s expected exit 2, got %s — this reads as clean\n' "all-unusable list" "$urc"; FAIL=1; fi

# ── ABLATIONS: each mutant must be lethal to its own row, control standing ──
mutate() {
  python3 - "$CHECK" "$W/mut.sh" "$1" "$2" <<'MPY'
import sys, pathlib
src, dst, old, new = sys.argv[1:5]
s = pathlib.Path(src).read_text()
if s.count(old) != 1: sys.exit("appears %d times, not once" % s.count(old))
pathlib.Path(dst).write_text(s.replace(old, new))
MPY
}
ablate() { # ablate <label> <old> <new> <must-appear | !must-not> <control>
  local why out lethal=0
  why="$(mutate "$2" "$3" 2>&1)" || {
    printf '  FAIL  ABLATION %-26s could not apply (%s)\n' "$1" "$why"; FAIL=1; return; }
  out="$(bash "$W/mut.sh" "$W/repo" "$names" 2>&1)"
  if [ "${4#\!}" != "$4" ]; then grep -qF -- "${4#\!}" <<<"$out" || lethal=1
  else grep -qF -- "$4" <<<"$out" && lethal=1; fi
  if [ "$lethal" -eq 0 ]; then
    printf '  FAIL  ABLATION %-26s mutant changed nothing — that row cannot fail\n' "$1"; FAIL=1
  elif ! grep -qF -- "$5" <<<"$out"; then
    printf '  FAIL  ABLATION %-26s killed the control too — proves nothing\n' "$1"; FAIL=1
  else
    printf '  PASS  ABLATION %-26s lethal to its own row, control survives\n' "$1"
  fi
}
ablate case-sensitivity 'grep -niIF' 'grep -nIF' \
  '!docs/history.md:2' 'templates/shipped.md:1'
# With the length gate open, a 4-char name matches ordinary prose — which is
# the whole reason the gate exists, and the reason recall is traded for signal.
ablate minlen-gate 'MINLEN=6' 'MINLEN=1' \
  'docs/history.md:6' 'templates/shipped.md:1'
ablate generic-gate "if printf '%s' \"\$name\" | tr 'A-Z' 'a-z' | grep -qE \"\$GENERIC\"; then" 'if false; then' \
  'docs/history.md:5' 'templates/shipped.md:1'
# The population must include untracked-but-not-ignored files and exclude
# ignored ones. Reverting to tracked-only makes the new-file row vanish.
ablate population-tracked-only 'git ls-files -z --cached --others --exclude-standard' 'git ls-files -z' \
  '!docs/untracked.md' 'templates/shipped.md:1'
ablate population-ignores-gitignore 'git ls-files -z --cached --others --exclude-standard' 'git ls-files -z --cached --others' \
  'docs/ignored.md' 'templates/shipped.md:1'
ablate missing-list-guard 'if [ ! -f "$NAMEFILE" ]; then' 'if false; then' \
  '!SKIPPED — no name list' 'templates/shipped.md:1'
ablate zero-usable-guard '[ "$names" -gt 0 ] ||' '[ "$names" -ge 0 ] ||' \
  '!0 usable names' 'templates/shipped.md:1'

echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." \
  || { echo "SENSITIVITY REGRESSION — do not ship."; printf '%s\n--- stderr ---\n%s\n' "$OUT" "$ERR"; }
exit "$FAIL"
