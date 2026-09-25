#!/usr/bin/env bash
# Rule 20 — every shell file under tests/ and scripts/ parses (#160).
#
# Usage: shell-parse.sh <repo-root>
# Violations to stdout; coverage line to stderr. Exit 0 clean, 1 violations, 2 could not run.
#
# WHY. Rule 11 runs `bash -n` over fenced blocks in templates/ and .claude/skills/,
# so it caught the two quoting breaks that landed there and neither of the two in
# tests/. A fixture that does not parse still runs every line ABOVE the break: its
# assertions print PASS, its ablations print "mutant changed nothing", and the
# syntax error arrives last, reading like a sensitivity failure. Reported up front
# it names the file and line.
#
# ⚠️ WHAT THIS RULE CANNOT SEE. It parses; it does not execute. A backtick pair
# inside a double-quoted string PARSES, as a command substitution, and runs the
# quoted text as a command at runtime: the seed arrives empty and the fixture
# still exits. Rule 17's welded `set -u#` parses too. Both need their own rules.
set -u

root="${1:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: shell-parse.sh <repo-root>" >&2; exit 2; }
cd "$root" || exit 2

found=0; bad=0
# -print0: a path with a space or newline is legal and must not be word-split.
# `-type l` too: a symlinked script is parsed through its link, not skipped.
while IFS= read -r -d '' f; do
  [ -d "$f" ] && continue   # a link to a directory named *.sh is not a script
  found=$((found + 1))
  [ -e "$f" ] || { bad=$((bad + 1)); printf '%s: dangling symlink — there is no script to parse\n' "$f"; continue; }
  if ! err=$(bash -n "$f" 2>&1); then
    bad=$((bad + 1))
    printf '%s: does not parse — %s\n' "$f" "$(printf '%s' "$err" | head -1)"
  fi
done < <(find tests scripts -name '.git' -prune -o \( -type f -o -type l \) \( -name '*.sh' -o -name '*.bash' \) -print0 2>/dev/null)

echo "      $found shell file(s) found under tests/ and scripts/, $((found - bad)) parsed" >&2
# An empty population is not a clean one: a moved tree reads exactly like a clean run.
[ "$found" -gt 0 ] || { echo "no shell files found under tests/ or scripts/ — this rule checked nothing" >&2; exit 2; }
[ "$bad" -eq 0 ] || exit 1
exit 0
