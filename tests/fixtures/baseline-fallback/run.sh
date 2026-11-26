#!/usr/bin/env bash
# Seeded git states for review-changes Step 1's baseline (#149, #153), which runs
# scripts/review-baseline.sh since #333.
#
# WHY THIS EXISTS. The fallback set BASE to the root commit and announced
# "reviewing the whole branch instead". Three-dot diffs from merge-base(BASE,HEAD)
# — which IS the root — so the root's own content was EXCLUDED. Measured before
# the fix: a repo whose entire change is its first commit reported NOTHING from
# every Step 1 command while `git show --stat HEAD` listed the file, and Step 1's
# terminator then said "nothing to review". A REVIEW TOOL CERTIFYING A CLEAN
# RESULT ON UNREVIEWED CONTENT.
#
# ⚠️ Lessons from this fixture's own earlier versions, each found by review:
#   * Empty output must never pass a row: compare against the exact marker.
#   * An ablation must assert what STOPS appearing when the unmutated code
#     already prints the positive (`!pattern` below), or an identity mutation
#     passes it.
#   * The block was once broken in one shell mode only. The script now runs in
#     its own shell, so the modes that matter are the CALLER's: T4 runs the
#     skill's caller lines, extracted from the template, under four of them.
#
# The script is copied, the caller lines EXTRACTED from templates/review-changes.md,
# so neither can drift from what an adopter runs. Extraction failure is loud.
set -uo pipefail
cd "$(dirname "$0")" || { echo "cannot enter the fixture directory"; exit 2; }
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT=
[ -n "$ROOT" ] || { echo "NOT IN A GIT WORK TREE — cannot locate the script; this is not an anchor failure"; exit 2; }
SCRIPT="$ROOT/scripts/review-baseline.sh"; TPL="$ROOT/templates/review-changes.md"
[ -f "$SCRIPT" ] && [ -f "$TPL" ] || { echo "SCRIPT OR TEMPLATE MISSING under $ROOT"; exit 2; }
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
FAIL=0
cp "$SCRIPT" "$WORK/rb.sh"

# The caller lines, from `out=$(bash "$RB")` to the BASE guard, with RB pointed
# at the copy (the template's RB names the clone, which may not exist here).
python3 - "$TPL" "$WORK/caller.sh" "$WORK/rb.sh" <<'PY' || { echo "EXTRACTION FAILED — the anchors moved"; exit 1; }
import sys
src = open(sys.argv[1], encoding='utf-8').read()
i = src.index('out=$(bash "$RB")')
j = src.index('do not review without one}"', i)
prog = 'RB=%s\n' % sys.argv[3] + src[i:j + len('do not review without one}"')] + '\n'
for needle in ("sed -n 's/^BASE=//p'", ': "${BASE:?'):
    if needle not in prog:
        sys.exit("caller block is missing %r" % needle)
open(sys.argv[2], 'w', encoding='utf-8').write(prog)
PY

mkrepo() {  # $1 = dir, $2 = number of commits. Asserts what it produced.
  local d="$WORK/$1" i=1 n
  mkdir -p "$d"; git init -q "$d"
  git -C "$d" config user.email t@t; git -C "$d" config user.name t
  while [ "$i" -le "${2:-0}" ]; do
    echo "line$i" >> "$d/f.txt"; git -C "$d" add -A
    # -c commit.gpgsign=false: a global signing config with an unusable key makes
    # `git commit` fail, and mkrepo would return a repo with zero commits.
    git -C "$d" -c commit.gpgsign=false commit -qm "c$i"
    i=$((i+1))
  done
  n=$(git -C "$d" rev-list --count HEAD 2>/dev/null || echo 0)
  [ "$n" = "${2:-0}" ] || { printf '  FAIL  fixture setup: %s has %s commits, wanted %s\n' "$1" "$n" "${2:-0}"; FAIL=1; }
}
# Run script $2 (default the copy) in $1; stdout to $WORK/out, stderr to $WORK/err.
run() { ( cd "$1" && bash "${2:-$WORK/rb.sh}" ) >"$WORK/out" 2>"$WORK/err"; RC=$?; OUT=$(cat "$WORK/out"); ERR=$(cat "$WORK/err"); }
# $1 is one or more 1/0 flags, one per condition; every one must be 1.
say() { if [ -n "$1" ] && [ -z "${1//1/}" ]; then printf '  PASS  %s\n' "$2"; else printf '  FAIL  %s\n' "$3"; FAIL=1; fi; }
has() { printf '%s' "$1" | grep -qF -- "$2" && echo 1 || echo 0; }
hasnt() { printf '%s' "$1" | grep -qF -- "$2" && echo 0 || echo 1; }

mkrepo one 1; mkrepo empty 0

# --- T1: the blocker case. One commit holding the whole change. --------------
sha=$(git -C "$WORK/one" rev-list --max-parents=0 HEAD)
run "$WORK/one"
say "$(has "$OUT" "ROOTFALLBACK=1")$(has "$OUT" "BASE=$sha")" "T1 a one-commit repo takes the fallback and returns ROOTFALLBACK=1, BASE=<root>" \
  "T1 the fallback did not mark itself or did not return the root as BASE"
say "$(has "$ERR" "git show --stat $sha")" "T1b the message names the companion command WITH the root sha" \
  "T1b the message does not name 'git show --stat <sha>', so the excluded content stays invisible"
say "$(hasnt "$ERR" 'reviewing the whole branch')" "T1c the false claim 'reviewing the whole branch' is gone" \
  "T1c the message still claims to review the whole branch, which it does not"
say "$(has "$ERR" 'BASELINE UNRESOLVED (ROOTFALLBACK=1)')" "T1d the marker is printed, so it survives the shell that set it" \
  "T1d the marker is not printed — the terminator keys off the printed token"

# --- T2: the fact the message asserts. Verified, not assumed. ---------------
d3=$(git -C "$WORK/one" diff --stat "$sha"...HEAD)
shw=$(git -C "$WORK/one" show --stat HEAD --format=)
say "$([ -z "$d3" ] && [ -n "$shw" ] && echo 1 || echo 0)" \
  "T2 three-dot from the root really is empty while the root's content is not" \
  "T2 the premise of the whole fix no longer holds — three-dot from the root is NOT empty here"

# --- T3: an empty repository must abort, and must NOT instruct anything. -----
run "$WORK/empty"
say "$([ "$RC" = 2 ] && echo 1 || echo 0)$(has "$ERR" 'no commits in this repository')" "T3 an empty repository aborts with exit 2 and says why" \
  "T3 an empty repository did not abort with exit 2 and its reason"
say "$(printf '%s' "$ERR" | grep -qE "git show --stat *($|')" && echo 0 || echo 1)$(hasnt "$OUT" 'BASE=')" \
  "T3b no argument-less 'git show --stat', and no BASE= line to read as a baseline" \
  "T3b an empty repo printed an instruction to run the wrong thing, or a BASE= line"

# --- T4: the skill's caller lines, under every CALLER shell mode. -------------
for mode in "set -eo pipefail" "set -uo pipefail" "set -e" "set -o pipefail"; do
  o=$( ( cd "$WORK/one" && /bin/bash -c "$mode; unset BASE; . '$WORK/caller.sh'; echo \"GOT=\$BASE\"" ) 2>&1 )
  say "$(has "$o" "GOT=$sha")$(has "$o" 'BASELINE UNRESOLVED')" "T4 [$mode] one-commit repo: the caller gets BASE and sees the marker" \
    "T4 [$mode] the caller lost BASE or the marker: $o"
  o=$( ( cd "$WORK/empty" && /bin/bash -c "$mode; unset BASE; . '$WORK/caller.sh'; echo \"GOT=\$BASE\"" ) 2>&1 )
  say "$(has "$o" 'no commits in this repository')$(hasnt "$o" 'GOT=')" "T4b [$mode] empty repo: aborts loudly, no baseline reaches the caller" \
    "T4b [$mode] empty repo: no diagnostic, or the caller went on: $o"
done
# A runner that is missing (no clone, failed fetch) must stop the caller too.
# A file, not `. <(...)`: sourcing a process substitution fails on bash 3.2.
sed "s|^RB=.*|RB=$WORK/no-such.sh|" "$WORK/caller.sh" > "$WORK/caller-missing.sh"
o=$( ( cd "$WORK/one" && /bin/bash -c "set -u; unset BASE; . '$WORK/caller-missing.sh'; echo \"GOT=\$BASE\"" ) 2>&1 )
say "$(has "$o" 'no baseline')$(hasnt "$o" 'GOT=')" "T4c a missing script stops the caller at the BASE guard" \
  "T4c a missing script let the caller go on: $o"

# --- N1: the CONTROL. A feature branch off a real origin. --------------------
mkrepo up 3
git clone -q "$WORK/up" "$WORK/feat" && git -C "$WORK/feat" config user.email t@t && git -C "$WORK/feat" config user.name t
git -C "$WORK/feat" checkout -q -b topic; echo more >> "$WORK/feat/f.txt"
git -C "$WORK/feat" -c commit.gpgsign=false commit -qam topic
# Origin moves on after the branch: three-dot ignores that, two-dot would not.
echo upstream > "$WORK/up/u.txt"; git -C "$WORK/up" add u.txt
git -C "$WORK/up" -c commit.gpgsign=false commit -qm upstream; git -C "$WORK/feat" fetch -q origin
run "$WORK/feat"
say "$(has "$OUT" 'ROOTFALLBACK=0')$(printf '%s' "$OUT" | grep -qE '^BASE=origin/(main|master)$' && echo 1 || echo 0)$([ -z "$ERR" ] && echo 1 || echo 0)" \
  "N1 a feature branch resolves origin's default branch, silently, with no fallback" \
  "N1 the control misresolved or printed a diagnostic: $OUT / $ERR"
say "$(has "$OUT" 'committed on this branch: 1 file changed, 1 insertion(+)')$(hasnt "$OUT" 'u.txt')$(printf '%s' "$OUT" | grep -qE '^ f.txt +\| 1 \+$' && echo 1 || echo 0)" \
  "N1b the committed term and file list count the branch's commit only, not origin's later one" \
  "N1b the committed term is wrong: $OUT"

# --- U1: untracked lines, from a subdirectory (#145; root-anchored). ----------
mkdir -p "$WORK/feat/sub"; printf 'a\nb\nc\n' > "$WORK/feat/new.txt"; : > "$WORK/feat/sub/.keep"
run "$WORK/feat/sub"
say "$(has "$OUT" 'untracked:                3 lines')$(has "$OUT" 'untracked: new.txt')" \
  "U1 from a subdirectory, a root-level untracked file is listed and its 3 lines counted" \
  "U1 untracked file or lines missed from a subdirectory: $OUT"
rm -rf "$WORK/feat/new.txt" "$WORK/feat/sub"

# --- U2: every other term and listing the gate reads. ------------------------
# A non-ASCII untracked name (`-z`, quotePath), a broken symlink (the braced
# open), a staged rename (staged term and stat), an unstaged edit, and a
# committed rename on a second branch (--summary -M).
printf 'x\ny\n' > "$WORK/feat/é.txt"; ln -s nowhere "$WORK/feat/broken"
git -C "$WORK/feat" mv f.txt g.txt; echo edit >> "$WORK/feat/g.txt"
run "$WORK/feat"
say "$(has "$OUT" 'untracked:                2 lines')$(has "$OUT" 'untracked: é.txt')$(has "$OUT" 'untracked: broken')" \
  "U2 a non-ASCII name is listed unquoted and counted; a broken symlink is listed" \
  "U2 the non-ASCII name was quoted or not counted: $OUT"
say "$(printf '%s' "$OUT" | grep -qE '^staged: +1 file changed, 0 insertions' && echo 1 || echo 0)$(printf '%s' "$OUT" | grep -qE '^unstaged: +1 file changed, 1 insertion' && echo 1 || echo 0)$(printf '%s' "$OUT" | grep -qE '^ g.txt +\| 1 \+$' && echo 1 || echo 0)$(has "$OUT" ' f.txt => g.txt | 0')" \
  "U2b the staged rename and the unstaged edit each reach their term and their file list" "U2b staged or unstaged term wrong: $OUT"
say "$([ -z "$ERR" ] && echo 1 || echo 0)" "U2c a broken untracked symlink prints nothing on stderr" "U2c stderr noise: $ERR"
git -C "$WORK/feat" reset -q --hard; rm -f "$WORK/feat/é.txt" "$WORK/feat/broken"
git -C "$WORK/feat" checkout -q -b moved; git -C "$WORK/feat" mv f.txt h.txt
git -C "$WORK/feat" -c commit.gpgsign=false commit -qm moved
run "$WORK/feat"
say "$(has "$OUT" 'rename f.txt => h.txt')$(has "$OUT" 'unstaged:                 none')$(has "$OUT" 'staged:                   none')" \
  "U3 a committed rename shows under --summary -M; empty terms print none" "U3 rename hidden or empty term blank: $OUT"
git -C "$WORK/feat" checkout -q topic

# --- B1: a bare repository is not a work tree. --------------------------------
git clone -q --bare "$WORK/up" "$WORK/bare.git"
run "$WORK/bare.git"
say "$([ "$RC" = 2 ] && echo 1 || echo 0)$(hasnt "$OUT" 'BASE=')" "B1 a bare repository aborts with exit 2 and no BASE= line" \
  "B1 a bare repository was reviewed: rc=$RC $OUT"

# --- O1: an orphan branch shares no history with the baseline. ---------------
git -C "$WORK/feat" checkout -q --orphan lone; git -C "$WORK/feat" -c commit.gpgsign=false commit -qm lone
run "$WORK/feat"
say "$(has "$ERR" 'BASELINE UNRESOLVED (NO MERGE BASE)')" "O1 unrelated histories are a finding, not an empty committed term" \
  "O1 an orphan branch reported no marker: $ERR"
git -C "$WORK/feat" checkout -q topic

# --- #153: HEAD contained in $BASE. T5 and N2 are a PAIR. --------------------
# N2 needs a real upstream: without one the root fallback fires and the guard
# is silent for an unrelated reason (a vacuous row, caught by ablating it).
mkrepo behind 3
git -C "$WORK/behind" checkout -q --detach HEAD~1
run "$WORK/behind"
say "$(has "$ERR" 'HEAD IS CONTAINED IN')" "T5 HEAD strictly behind the baseline is announced (#153)" \
  "T5 HEAD is contained in the baseline and nothing said so"
git -C "$WORK/behind" checkout -q -
git -C "$WORK/behind" remote add origin "$WORK/up" 2>/dev/null || :
git -C "$WORK/behind" fetch -q origin 2>/dev/null || :
git -C "$WORK/behind" branch --set-upstream-to=origin/main 2>/dev/null ||
  git -C "$WORK/behind" branch --set-upstream-to=origin/master 2>/dev/null || :
git -C "$WORK/behind" reset -q --hard '@{u}'
echo "uncommitted" >> "$WORK/behind/f.txt"
run "$WORK/behind"
say "$(hasnt "$ERR" 'HEAD IS CONTAINED IN')$(has "$OUT" 'ROOTFALLBACK=0')" "N2 HEAD equal to the baseline with uncommitted work stays silent" \
  "N2 the diagnostic fired on the ordinary pre-commit run, or the baseline fell back: $ERR"

# --- ablations on the script copy. `!pattern` = must STOP appearing. ---------
ablate() { # $1 label, $2 old, $3 new, $4 [!]pattern, $5 repo dir, $6 stream (out|err)
  [ -n "${ABL_PRE+x}" ] || ABL_PRE=$FAIL; if [ "$ABL_PRE" -ne 0 ]; then printf '  UNSCORED  ablation %s — a seeded case already failed in this run, so it cannot fail (#161)\n' "$1"; return 0; fi
  local pat="$4" neg=0 got
  case "$pat" in !*) neg=1; pat="${pat#!}" ;; esac
  python3 - "$WORK/rb.sh" "$WORK/mut.sh" "$2" "$3" <<'PY' || { printf '  FAIL  ablation %s could not be applied — its site has moved\n' "$1"; FAIL=1; return; }
import sys
s = open(sys.argv[1], encoding='utf-8').read()
old, new = sys.argv[3], sys.argv[4]
if s.count(old) != 1:
    sys.exit("mutation site occurs %d times, not once" % s.count(old))
open(sys.argv[2], 'w', encoding='utf-8').write(s.replace(old, new))
PY
  run "$5" "$WORK/mut.sh"; [ "$6" = err ] && got=$ERR || got=$OUT
  if printf '%s' "$got" | grep -qF -- "$pat"; then hit=1; else hit=0; fi
  if [ "$hit" != "$neg" ]; then printf '  PASS  ablation %s breaks the row that guards it\n' "$1"
  else printf '  FAIL  ablation %s changed NOTHING — the row it guards is not measuring it\n' "$1"; FAIL=1; fi
}
ablate "drop-the-marker"   '  ROOTFALLBACK=1' '  ROOTFALLBACK=0' '!ROOTFALLBACK=1' "$WORK/one" out
ablate "drop-the-command"  "Run 'git show --stat \$BASE'" 'Run nothing' '!git show --stat' "$WORK/one" err
ablate "drop-the-token"    'BASELINE UNRESOLVED (ROOTFALLBACK=1)' 'BASELINE UNRESOLVED' '!(ROOTFALLBACK=1)' "$WORK/one" err
ablate "drop-the-abort"    '[ -n "${BASE:-}" ] || { echo "review-baseline: no commits' '[ -n "x" ] || { echo "review-baseline: no commits' 'BASE=' "$WORK/empty" out
git -C "$WORK/behind" checkout -q -- f.txt; git -C "$WORK/behind" checkout -q --detach HEAD~1
ablate "drop-the-ancestor-guard" 'if git merge-base --is-ancestor HEAD "$BASE" 2>/dev/null &&' 'if false &&' '!HEAD IS CONTAINED IN' "$WORK/behind" err
git -C "$WORK/behind" checkout -q -
mkdir -p "$WORK/feat/sub"; printf 'a\nb\nc\n' > "$WORK/feat/new.txt"
git -C "$WORK/feat" checkout -q lone
ablate "drop-the-merge-base-guard" 'git merge-base "$BASE" HEAD >/dev/null 2>&1 ||' 'true ||' '!NO MERGE BASE' "$WORK/feat" err
git -C "$WORK/feat" checkout -q topic
ablate "drop-the-root-anchor" 'wc -l < "$top/$f"' 'wc -l < "$f"' '!untracked:                3 lines' "$WORK/feat/sub" out

[ "$FAIL" = 0 ] && echo "All seeded cases behaved correctly." || echo "SEEDED CASES FAILED."
exit "$FAIL"
