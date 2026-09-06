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
# CONTENT. The Step 1 guard could not catch it: $BASE *did* resolve.
#
# ⚠️ Three rows here exist because the FIRST version of this fixture was itself
# defective, and a four-lens review found all three:
#   * T1 accepted EMPTY output as a pass, so a block that printed nothing scored
#     PASS. Trigger, not hypothetical: `commit.gpgsign` with an unusable key
#     makes mkrepo silently produce a repo with no commits.
#   * `drop-the-command` asserted a pattern the UNMUTATED code already prints, so
#     it could never fail — an identity mutation passed it. `ablate` now takes a
#     `!pattern` form for "this must STOP appearing", which is the only shape
#     that can express that row.
#   * every row ran without `set -e`, which is the one mode the block was broken
#     in, so the fixture certified an ordering claim it could not test.
#
# The block is EXTRACTED from templates/review-changes.md, never copied, so it
# cannot drift from the text an adopter runs. Extraction failure is loud.
set -uo pipefail
cd "$(dirname "$0")" || { echo "cannot enter the fixture directory"; exit 2; }
# Diagnose the cause rather than blaming the anchors: outside a git work tree
# ROOT is empty and TPL becomes /templates/..., which used to print a Python
# traceback plus "the anchors moved" — naming the wrong cause (#125's shape).
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT=
[ -n "$ROOT" ] || { echo "NOT IN A GIT WORK TREE — cannot locate the template; this is not an anchor failure"; exit 2; }
TPL="$ROOT/templates/review-changes.md"
[ -f "$TPL" ] || { echo "TEMPLATE MISSING at $TPL — not an anchor failure"; exit 2; }
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
FAIL=0

python3 - "$TPL" "$WORK/block.sh" <<'PY' || { echo "EXTRACTION FAILED — the anchors moved"; exit 1; }
import sys
src = open(sys.argv[1], encoding='utf-8').read()
i = src.index('ROOTFALLBACK=          #')
j = src.index('same hole."; } >&2\n}', i)
prog = src[i:j+20]
for needle in ('ROOTFALLBACK=1', 'BASE:?no commits', 'EXCLUDES', '| tail -1) || :',
               'BASELINE UNRESOLVED (ROOTFALLBACK=1)'):
    if needle not in prog:
        sys.exit("extracted block is missing %r" % needle)
open(sys.argv[2], 'w', encoding='utf-8').write(prog)
PY

mkrepo() {  # $1 = dir, $2 = number of commits. Asserts what it produced.
  local d="$WORK/$1" i=1 n
  mkdir -p "$d"; git init -q "$d"
  git -C "$d" config user.email t@t; git -C "$d" config user.name t
  while [ "$i" -le "${2:-0}" ]; do
    echo "line$i" >> "$d/f.txt"; git -C "$d" add -A
    # -c commit.gpgsign=false: a global signing config with an unusable key makes
    # `git commit` fail, and without this postcondition mkrepo returned a repo
    # with zero commits while every row still reported PASS.
    git -C "$d" -c commit.gpgsign=false commit -qm "c$i"
    i=$((i+1))
  done
  n=$(git -C "$d" rev-list --count HEAD 2>/dev/null || echo 0)
  [ "$n" = "${2:-0}" ] || { printf '  FAIL  fixture setup: %s has %s commits, wanted %s\n' "$1" "$n" "${2:-0}"; FAIL=1; }
}
# Run the extracted block in $1 under shell mode $2, print RF=<state>.
runblock() { ( cd "$1"; /bin/bash -c "${2:-set -uo pipefail}; unset BASE ROOTFALLBACK
                 . '$WORK/block.sh'; echo \"RF=\${ROOTFALLBACK:-unset}\"" 2>"$WORK/err" ); }
say() { if [ "$1" = 1 ]; then printf '  PASS  %s\n' "$2"; else printf '  FAIL  %s\n' "$3"; FAIL=1; fi; }

mkrepo one 1; mkrepo three 3; mkrepo empty 0

# --- T1: the blocker case. One commit holding the whole change. --------------
# `= RF=1`, never `!= RF=unset`: empty output is neither, and the first draft's
# predicate accepted it.
out=$(runblock "$WORK/one"); err=$(cat "$WORK/err")
say "$([ "$out" = "RF=1" ] && echo 1 || echo 0)" \
  "T1 a one-commit repo takes the fallback and marks it (ROOTFALLBACK=1)" \
  "T1 the fallback did not mark itself, or the block printed nothing at all"
sha=$(git -C "$WORK/one" rev-list --max-parents=0 HEAD)
say "$(printf '%s' "$err" | grep -qF "git show --stat $sha" && echo 1 || echo 0)" \
  "T1b the message names the companion command WITH the root sha" \
  "T1b the message does not name 'git show --stat <sha>', so the excluded content stays invisible"
say "$(printf '%s' "$err" | grep -q 'reviewing the whole branch' && echo 0 || echo 1)" \
  "T1c the false claim 'reviewing the whole branch' is gone" \
  "T1c the message still claims to review the whole branch, which it does not"
# T1d — the marker must be PRINTED, not only set: the terminator keys off the
# printed line because a shell variable does not survive to the next tool call,
# and this marker degrades toward permitting a clean result.
say "$(printf '%s' "$err" | grep -qF 'BASELINE UNRESOLVED (ROOTFALLBACK=1)' && echo 1 || echo 0)" \
  "T1d the marker is printed, so it survives the shell that set it" \
  "T1d the marker exists only as a shell variable — it cannot reach the step that reads it"

# --- T2: the fact the message asserts. Verified, not assumed. ---------------
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

# --- T4: EVERY shell mode, because the block was broken in exactly one. ------
# Under `set -eo pipefail` the rev-list pipeline's 128 used to kill the shell
# before the abort, printing nothing — and the fixture, running without -e,
# certified the ordering anyway. A mismatched instrument, seeded so it cannot
# recur.
for mode in "set -eo pipefail" "set -uo pipefail" "set -e" "set -o pipefail"; do
  o=$(runblock "$WORK/one" "$mode"); e=$(cat "$WORK/err")
  say "$([ "$o" = "RF=1" ] && printf '%s' "$e" | grep -qF 'BASELINE UNRESOLVED' && echo 1 || echo 0)" \
    "T4 [$mode] one-commit repo: fallback fires and marks itself" \
    "T4 [$mode] the fallback did not fire or did not mark itself"
  o=$(runblock "$WORK/empty" "$mode"); e=$(cat "$WORK/err")
  say "$(printf '%s' "$e" | grep -q 'no commits in this repository' && echo 1 || echo 0)" \
    "T4b [$mode] empty repo: aborts loudly" \
    "T4b [$mode] empty repo produced NO diagnostic — the abort was skipped"
done

# --- N1: the CONTROL. A baseline that resolves must not take the fallback. ---
out=$( ( cd "$WORK/three"; /bin/bash -c "set -uo pipefail; BASE=\$(git rev-parse HEAD~1); unset ROOTFALLBACK
           . '$WORK/block.sh'; echo \"RF=\${ROOTFALLBACK:-unset}\"" 2>"$WORK/err" ) )
err=$(cat "$WORK/err")
say "$([ "$out" = "RF=" ] || [ "$out" = "RF=unset" ] && echo 1 || echo 0)" \
  "N1 a resolving baseline does not set the marker" \
  "N1 a resolving baseline took the fallback — every ordinary review would diff from the root"
say "$([ -z "$err" ] && echo 1 || echo 0)" \
  "N1b a resolving baseline prints nothing" \
  "N1b a resolving baseline printed a diagnostic, which reads as a finding when there is none"

# --- ablations. `!pattern` = must STOP appearing; otherwise must APPEAR. -----
ablate() { # $1 label, $2 old, $3 new, $4 [!]pattern, $5 repo=one, $6 mode
  local pat="$4" neg=0 o repo="${5:-one}" mode="${6:-set -uo pipefail}"
  case "$pat" in !*) neg=1; pat="${pat#!}" ;; esac
  python3 - "$WORK/block.sh" "$WORK/mut.sh" "$2" "$3" <<'PY' || { printf '  FAIL  ablation %s could not be applied — its site has moved\n' "$1"; FAIL=1; return; }
import sys
s = open(sys.argv[1], encoding='utf-8').read()
old, new = sys.argv[3], sys.argv[4]
if s.count(old) != 1:
    sys.exit("mutation site occurs %d times, not once" % s.count(old))
open(sys.argv[2], 'w', encoding='utf-8').write(s.replace(old, new))
PY
  o=$( ( cd "$WORK/$repo"; /bin/bash -c "$mode; unset BASE ROOTFALLBACK
           . '$WORK/mut.sh'; echo \"RF=\${ROOTFALLBACK:-unset}\"" 2>&1 ) )
  if [ "$neg" = 1 ]; then
    if printf '%s' "$o" | grep -qF "$pat"
      then printf '  FAIL  ablation %s changed NOTHING — the row it guards is not measuring it\n' "$1"; FAIL=1
      else printf '  PASS  ablation %s removes what its row asserts\n' "$1"; fi
  else
    if printf '%s' "$o" | grep -qF "$pat"
      then printf '  PASS  ablation %s produces the failure its row forbids\n' "$1"
      else printf '  FAIL  ablation %s changed NOTHING — the row it guards is not measuring it\n' "$1"; FAIL=1; fi
  fi
}
ablate "drop-the-marker"   '  ROOTFALLBACK=1' '  ROOTFALLBACK='  'RF='
# Repointed: the old form asserted RF=1, which the UNMUTATED block already
# prints, so an identity mutation passed. It must assert T1b's needle DISAPPEARS.
ablate "drop-the-command"  "Run 'git show --stat \$BASE'" 'Run nothing'  '!git show --stat'
ablate "drop-the-token"    'BASELINE UNRESOLVED (ROOTFALLBACK=1)' 'BASELINE UNRESOLVED' '!(ROOTFALLBACK=1)'
# ⚠️ This one MUST run in the empty repo under `-eo pipefail`, the only state
# the guard matters in. A first draft ran it in the one-commit repo under
# `-uo pipefail` and asserted RF=1 — the unmutated outcome — so it was the same
# vacuous shape as `drop-the-command`, in the fixture written to fix that shape.
ablate "drop-the-pipefail-guard" ' | tail -1) || :' ' | tail -1)' \
  '!no commits in this repository' empty "set -eo pipefail"

[ "$FAIL" = 0 ] && echo "All seeded cases behaved correctly." || echo "SEEDED CASES FAILED."
exit "$FAIL"
