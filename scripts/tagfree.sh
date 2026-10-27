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
if git rev-parse --verify --quiet "refs/tags/$t" >/dev/null; then
  echo "LOCAL TAG $t EXISTS — STOP"; exit 1
fi
lsr=$(git ls-remote --tags origin "refs/tags/$t" 2>/dev/null) || {
  echo "CANNOT VERIFY $t on the remote — ls-remote failed (offline? no origin?)"
  exit 2
}
if [ -n "$lsr" ]; then
  echo "REMOTE TAG $t EXISTS — STOP"; exit 1
fi
echo "tag $t free, local and remote"
