#!/usr/bin/env bash
# tagfree.sh — is a release tag free, locally and on the remote?
# release Step 3, check 3 runs this from inside the repo being released.
#
# Usage: tagfree.sh vX.Y.Z
# Exit: 0 free, 1 taken (local or remote), 2 could not be decided (no tag
#   given, or ls-remote failed: offline, no origin). Every exit prints a line.
#   2 IS NOT A PASS for a release: the remote was never checked. Stop on it.
#
# THE VERDICT IS THE EXIT STATUS, never the word. `cmd && echo STOP || echo free`
# exits 0 on both branches, so anything scoring it reads PASS while it prints
# STOP (#136). Call it guarded — `if bash tagfree.sh vX.Y.Z; then rc=0; else
# rc=$?; fi` — because under `set -e` a bare call kills the shell on 1 and on 2,
# so the status line never prints and the remaining preconditions are skipped.
#
# Anchored to refs/tags: a bare `git rev-parse vX.Y.Z` also matches a BRANCH
# named vX.Y.Z and would block a legitimate release.
#
# Moved out of templates/release.md Step 3 on 2026-10-27, logic unchanged
# (`return` became `exit`). As a function in the skill body it had to write
# its argument braced, because a skill's arguments are substituted into its
# body (#77); a script has no such trap.
t=${1:-}
# An empty argument was a FALSE PASS once: it printed "tag  free" and exited 0,
# having checked nothing, with a double space as the only tell.
[ -n "$t" ] || { echo "CANNOT VERIFY: no tag given"; exit 2; }
# An unfilled placeholder (release Step 3 is written with vX.Y.Z) was a FALSE
# PASS too: no such tag exists, so it read "free" (#276). Pre-release and build
# suffixes (v1.2.3-rc1) pass.
[[ $t =~ ^v[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]] ||
  { echo "CANNOT VERIFY: '$t' is not a vX.Y.Z tag"; exit 2; }
git check-ref-format "refs/tags/$t" ||
  { echo "CANNOT VERIFY: '$t' is not a valid tag name"; exit 2; }
# A hung remote or a credential prompt must not stall the step: no prompt, and
# a 30 s limit where `timeout` exists (not stock macOS). A timeout exits
# non-zero, so it lands on the CANNOT VERIFY path below.
to=(); command -v timeout >/dev/null 2>&1 && to=(timeout 30)
if git rev-parse --verify --quiet "refs/tags/$t" >/dev/null; then
  echo "LOCAL TAG $t EXISTS — STOP"; exit 1
fi
# Resolve origin's URL first: with no such remote, `ls-remote origin` reads a
# ./origin directory as the remote and can answer "free" for the wrong repo.
url=$(git remote get-url origin 2>/dev/null) ||
  { echo "CANNOT VERIFY $t on the remote — no origin remote"; exit 2; }
lsr=$(GIT_TERMINAL_PROMPT=0 "${to[@]}" git ls-remote --tags -- "$url" "refs/tags/$t" 2>/dev/null) || {
  echo "CANNOT VERIFY $t on the remote — ls-remote failed (offline? no origin?)"
  exit 2
}
if [ -n "$lsr" ]; then
  echo "REMOTE TAG $t EXISTS — STOP"; exit 1
fi
echo "tag $t free, local and remote"
