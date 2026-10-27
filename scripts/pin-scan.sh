#!/usr/bin/env bash
# pin-scan.sh — every agent-ready-* framework pin in a repo, and every mention without one.
# update-drift Step 0 runs this from the root of the repo being checked.
#
# Usage: pin-scan.sh <project file> [operand...]
#   With no operands after the project file it searches the project file plus
#   docs memory .claude templates. Absent operands are named, not searched.
#   Keep operands disjoint: overlap (adding `.`, or a parent of another operand)
#   makes the reconciliation report a stamped file as unstamped.
# Output: three labelled matcher regions (version pins, commit-hash pins, prose
#   commit pins), then the reconciliation: the counts of mentioned and stamped
#   (file, framework) pairs, and every mentioned pair with no stamp.
# Exit: 0 ran; 2 nothing could be searched, or a matcher FAILED (a grep exit
#   above 1, printed as MATCHER FAILED on stderr) — then a short stamped side is
#   the engine, not a finding. Every exit prints a line.
#
# Do not simplify. Every gap, character class and the \b is load-bearing, and so
# are the (file, framework) unit, the printed counts, sort -u and LC_ALL=C on both
# sides and on comm, and m() on every grep. Read docs/rationale/update-drift.md
# (Step 0) before changing any of them. Keep \b, not a (^|[^A-Za-z]) group: ugrep
# refuses the group form (#211).
#
# Moved out of templates/update-drift.md Step 0 on 2026-10-27, matchers and
# reconciliation unchanged. Two additions: a single-operand run says so, and a
# failed matcher sets exit 2 instead of only printing.
P=${1:-}
[ -n "$P" ] || { echo "CANNOT SCAN: usage: pin-scan.sh <project file> [operand...]" >&2; exit 2; }
shift
[ $# -gt 0 ] || set -- docs memory .claude templates
OPERANDS=()
for o in "$P" "$@"; do
  case $o in -*) o=./$o ;; esac   # else grep reads it as an option
  if [ -e "$o" ]; then OPERANDS+=("$o"); else echo "operand absent, not searched: $o"; fi
done
[ ${#OPERANDS[@]} -gt 0 ] || { echo "CANNOT SCAN: no operand exists, so nothing can be searched" >&2; exit 2; }
[ ${#OPERANDS[@]} -gt 1 ] || echo "SINGLE OPERAND: a self-reconciliation always agrees — report this run as a finding"

M= S= F=; trap 'rm -f "$M" "$S" "$F"' EXIT
M=$(mktemp) && S=$(mktemp) && F=$(mktemp) || { echo "CANNOT SCAN: mktemp failed" >&2; exit 2; }
# `command grep` skips an alias to another engine; exit 2 is a FAILED matcher (#211).
# LABEL each matcher: an empty region otherwise reads the same as "never ran".
m() { rc=0; command grep "$@" || rc=$?; [ "$rc" -le 1 ] || { echo "MATCHER FAILED (exit $rc): this is not 'no pins'" >&2; echo x >> "$F"; }; }
echo "--- 1. version-shaped pins"
m -rnE "agent-ready-[a-z]+(-[a-z][a-z]+)*[^0-9]{0,60}v?[0-9]+\.[0-9]+[0-9.]*" "${OPERANDS[@]}"
echo "--- 2. commit-hash pins"
m -rnE "agent-ready-[a-z]+(-[a-z][a-z]+)*[^A-Za-z0-9]{0,24}[0-9a-f]{7,40}" "${OPERANDS[@]}"
echo "--- 3. prose commit pins — a connector word carries the hash (#134)"
m -rnEi "agent-ready-[a-z]+(-[a-z][a-z]+)*[^0-9]{0,40}\b(commit|rev|sha|ref|pinned to)[^A-Za-z0-9]{1,4}[0-9a-f]{7,40}" "${OPERANDS[@]}"

echo "--- reconciliation: mentioned (file, framework) pairs with no stamp"
# every (file, framework) PAIR that is mentioned...
m -rnoE "agent-ready-[a-z]+(-[a-z][a-z]+)*" "${OPERANDS[@]}" |
  sed -E 's/:[0-9]+:/:/' | LC_ALL=C sort -u > "$M" || :
# ...against every pair a stamp was actually found for
{ m -roE "agent-ready-[a-z]+(-[a-z][a-z]+)*[^0-9]{0,60}v?[0-9]+\.[0-9]+[0-9.]*" "${OPERANDS[@]}"
  m -roE "agent-ready-[a-z]+(-[a-z][a-z]+)*[^A-Za-z0-9]{0,24}[0-9a-f]{7,40}" "${OPERANDS[@]}"
  # Matcher 3 too, or a pin only it finds reads as UNSTAMPED here (#134).
  m -roEi "agent-ready-[a-z]+(-[a-z][a-z]+)*[^0-9]{0,40}\b(commit|rev|sha|ref|pinned to)[^A-Za-z0-9]{1,4}[0-9a-f]{7,40}" "${OPERANDS[@]}"
} | awk '{ i = index($(0), ":agent-ready-"); f = substr($(0), 1, i - 1); r = substr($(0), i + 1)
       # A stamp belongs to the LAST name before it, not the first (#134).
       while (match(r, /agent-ready-[a-z]+(-[a-z][a-z]+)*/)) { n = substr(r, RSTART, RLENGTH); r = substr(r, RSTART + RLENGTH) }
       print f ":" n }' | LC_ALL=C sort -u > "$S"
printf 'mentioned pairs: %s  stamped pairs: %s\n' "$(wc -l < "$M")" "$(wc -l < "$S")"
[ -s "$M" ] || echo 'EMPTY — the mention grep matched nothing. Check the operands before reading this as clean.'
LC_ALL=C comm -23 "$M" "$S"
[ ! -s "$F" ] || { echo "pin-scan: a matcher failed; read no count above as a finding" >&2; exit 2; }
