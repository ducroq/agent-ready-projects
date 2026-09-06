#!/usr/bin/env bash
# Seeded git states for review-changes Step 1's BASELINE FALLBACK (#149).
#
# WHY THIS EXISTS. The fallback set BASE to the root commit and announced
# "reviewing the whole branch instead". Three-dot diffs from merge-base(BASE,HEAD)
# — which IS the root — so the root's own content was EXCLUDED. Measured before
# the fix: 3 commits of 1 line each reported 2 insertions; a repo whose entire
# change is its first commit reported NOTHING from every Step 1 command while
# `git show --stat HEAD` listed the file, and Step 1's terminator then said
# "nothing to review". A REVIEW TOOL CERTIFYING A CLEAN RESULT ON UNREVIEWED
# CONTENT. Line 118's guard could not catch it: $BASE *did* resolve.
#
# The block is EXTRACTED from templates/review-changes.md, never copied, so it
# cannot drift from the text an adopter runs. Extraction failure is loud.
set -uo pipefail
cd "$(dirname "$0")"
ROOT=$(git rev-parse --show-toplevel)
TPL="$ROOT/templates/review-changes.md"
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
FAIL=0

python3 - "$TPL" "$WORK/block.sh" <<'PY' || { echo "EXTRACTION FAILED — the anchors moved"; exit 1; }
import sys
src = open(sys.argv[1], encoding='utf-8').read()
i = src.index('{ [ -n "${BASE:-}" ]')
j = src.index('; } >&2\n}', i)
prog = src[i:j+9]
for needle in ('ROOTFALLBACK=1', 'BASE:?no commits', 'EXCLUDES'):
    if needle not in prog:
        sys.exit("extracted block is missing %r" % needle)
open(sys.argv[2], 'w', encoding='utf-8').write(prog)
PY

mkrepo() {  # $1 = dir, $2 = number of commits
  local d="$WORK/$1"; mkdir -p "$d"; git init -q "$d"
  git -C "$d" config user.email t@t; git -C "$d" config user.name t
  local i=1; while [ "$i" -le "${2:-0}" ]; do
    echo "line$i" >> "$d/f.txt"; git -C "$d" add -A; git -C "$d" commit -qm "c$i"
    i=$((i+1))
  done
}
# Run the extracted block in $1 with the environment in $2, print "RF=<state>".
runblock() { ( cd "$1"; unset BASE ROOTFALLBACK; eval "${2:-}"
               . "$WORK/block.sh" 2>"$WORK/err"; echo "RF=${ROOTFALLBACK:-unset}" ) 2>/dev/null; }
say() { if [ "$1" = 1 ]; then printf '  PASS  %s\n' "$2"; else printf '  FAIL  %s\n' "$3"; FAIL=1; fi; }

mkrepo one 1; mkrepo three 3; mkrepo empty 0

# --- T1: the blocker case. One commit holding the whole change. --------------
out=$(runblock "$WORK/one"); err=$(cat "$WORK/err")
say "$([ "$out" = "RF=unset" ] && echo 0 || echo 1)" \
  "T1 a one-commit repo takes the fallback and marks it (ROOTFALLBACK)" \
  "T1 the fallback fired without marking itself — the terminator cannot then refuse a clean result"
sha=$(git -C "$WORK/one" rev-list --max-parents=0 HEAD)
say "$(printf '%s' "$err" | grep -qF "git show --stat $sha" && echo 1 || echo 0)" \
  "T1b the message names the companion command WITH the root sha" \
  "T1b the message does not name 'git show --stat <sha>', so the excluded content stays invisible"
say "$(printf '%s' "$err" | grep -q 'reviewing the whole branch' && echo 0 || echo 1)" \
  "T1c the false claim 'reviewing the whole branch' is gone" \
  "T1c the message still claims to review the whole branch, which it does not"

# --- T2: the fact the message asserts. Verified, not assumed. ---------------
# If this ever stops being true the message becomes false in the other direction.
d3=$(git -C "$WORK/one" diff --stat "$sha"...HEAD)
shw=$(git -C "$WORK/one" show --stat HEAD --format=)
say "$([ -z "$d3" ] && [ -n "$shw" ] && echo 1 || echo 0)" \
  "T2 three-dot from the root really is empty while the root's content is not" \
  "T2 the premise of the whole fix no longer holds — three-dot from the root is NOT empty here"

# --- T3: an empty repository must abort, and must NOT instruct anything. -----
out=$(runblock "$WORK/empty"); err=$(cat "$WORK/err")
say "$(printf '%s' "$err" | grep -q 'no commits in this repository' && echo 1 || echo 0)" \
  "T3 an empty repository aborts" \
  "T3 an empty repository did not abort"
say "$(printf '%s' "$err" | grep -qE "git show --stat *($|')" && echo 0 || echo 1)" \
  "T3b it does not print 'git show --stat' with no argument (abort precedes the message)" \
  "T3b an empty repo is told to run 'git show --stat' with no argument — an instruction to run the wrong thing"

# --- N1: the CONTROL. A baseline that resolves must not take the fallback. ---
# Without this row every assertion above is satisfied by a block that ALWAYS
# falls back, which would review from the root on every ordinary branch.
out=$(runblock "$WORK/three" "BASE=\$(git rev-parse HEAD~1)"); err=$(cat "$WORK/err")
say "$([ "$out" = "RF=unset" ] && echo 1 || echo 0)" \
  "N1 a resolving baseline does not set ROOTFALLBACK" \
  "N1 a resolving baseline took the fallback — every ordinary review would diff from the root"
say "$([ -z "$err" ] && echo 1 || echo 0)" \
  "N1b a resolving baseline prints nothing" \
  "N1b a resolving baseline printed a diagnostic, which reads as a finding when there is none"

# --- ablations: each mutant must kill its own rows and leave the others. -----
ablate() { # $1 label, $2 old, $3 new, $4 must-die pattern
  python3 - "$WORK/block.sh" "$WORK/mut.sh" "$2" "$3" <<'PY' || { printf '  FAIL  ablation %s could not be applied — its site has moved\n' "$1"; FAIL=1; return; }
import sys
s = open(sys.argv[1], encoding='utf-8').read()
old, new = sys.argv[3], sys.argv[4]
if old not in s:
    sys.exit(1)
open(sys.argv[2], 'w', encoding='utf-8').write(s.replace(old, new))
PY
  local o
  o=$( ( cd "$WORK/one"; unset BASE ROOTFALLBACK; . "$WORK/mut.sh" 2>"$WORK/merr"
          echo "RF=${ROOTFALLBACK:-unset}" ) 2>/dev/null; cat "$WORK/merr" )
  if printf '%s' "$o" | grep -qE "$4"; then
    printf '  PASS  ablation %s changes the outcome it is supposed to\n' "$1"
  else
    printf '  FAIL  ablation %s changed NOTHING — the row it guards is not measuring it\n' "$1"; FAIL=1
  fi
}
ablate "drop-the-marker"   '; ROOTFALLBACK=1' ''                    'RF=unset'
ablate "drop-the-command"  "git show --stat \$BASE"  'nothing'      'RF=1'

[ "$FAIL" = 0 ] && echo "All seeded cases behaved correctly." || echo "SEEDED CASES FAILED."
exit "$FAIL"
