#!/usr/bin/env bash
# Rule 23 — a verification rating is the FLOOR of its steps, not the mode (#168).
#
# Usage: rating-floor.sh <repo-root>
# Violations to stdout; coverage line to stderr. Exit 0 clean, 1 violations, 2 could not run.
#
# WHY. docs/vv/verification-log.md recorded Step 5 NEEDS WORK and Step 6 PARTIAL
# for its most-cited source, rated the block VERIFIED anyway, and the registry
# marked its claims ESTABLISHED for five months. Four PASSes outvoted the two
# steps that mattered, and the figures turned out superseded.
#
# The rule, per "## Source" block of the log:
#   - a step whose Result cell reads PARTIAL, NEEDS WORK or FAIL means the
#     block's **Status:** may not begin with VERIFIED, and
#   - no claim ID (S<n>-<n>) named anywhere in that block may be rated
#     ESTABLISHED in docs/vv/claims/claim_registry.md.
#
# ⚠️ WHAT IT CANNOT SEE. It reads the step table's Result column and the claim IDs
# a block names; a weak finding written only in prose (a "NEEDS REVISION" bullet
# under the table) is not read, and a registry claim citing a source without its
# ID appearing in that source's block is not joined. Chosen over a verify probe
# because lint runs on every commit and in CI; a probe runs only at /curate.
set -u

root="${1:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: rating-floor.sh <repo-root>" >&2; exit 2; }
cd "$root" || exit 2
LOG="docs/vv/verification-log.md"; REG="docs/vv/claims/claim_registry.md"
for f in "$LOG" "$REG"; do
  [ -r "$f" ] || { echo "rule 23: $f is absent or unreadable — nothing was checked" >&2; exit 2; }
done

WORK=$(mktemp -d) || exit 2
trap 'rm -rf "$WORK"' EXIT

# One line per source block: <name> TAB <weak step count> TAB <status> TAB <claim IDs>
awk '
  function flush() {
    if (name != "") printf "%s\t%d\t%s\t%s\n", name, weak, status, ids
    name = ""; weak = 0; status = ""; ids = " "
  }
  { sub(/\r$/, "") }
  /^## / { flush(); if ($0 ~ /^## Source/) name = substr($0, 4); next }
  name == "" { next }
  # A step row: | <digit> | check | result | notes |
  /^\|[ \t]*[0-9]+[ \t]*\|/ {
    n = split($0, c, "|")
    if (n >= 5) { r = toupper(c[4]); if (r ~ /PARTIAL|NEEDS WORK|FAIL/) weak++ }
  }
  /^\*\*Status:\*\*/ { status = $0; sub(/^\*\*Status:\*\*[ \t]*/, "", status) }
  { s = $0
    while (match(s, /S[0-9]+-[0-9]+/)) {
      id = substr(s, RSTART, RLENGTH)
      if (index(ids, " " id " ") == 0) ids = ids id " "
      s = substr(s, RSTART + RLENGTH)
    } }
  END { flush() }' "$LOG" > "$WORK/blocks"

nb=$(grep -c . "$WORK/blocks")
[ "$nb" -gt 0 ] || { echo "rule 23: no '## Source' block found in $LOG — this rule checked nothing" >&2; exit 2; }

bad=0
while IFS=$'\t' read -r name weak status ids; do
  [ "$weak" -gt 0 ] || continue
  st=$(printf '%s' "$status" | tr -d '*')
  st=${st#"${st%%[![:space:]]*}"}
  case "$st" in VERIFIED*)
    echo "$LOG: $name has $weak step(s) PARTIAL / NEEDS WORK / FAIL but its Status is VERIFIED — the rating is the floor of its steps (#168)"
    bad=$((bad + 1)) ;;
  esac
  for id in $ids; do
    if grep -qE "^\|[[:space:]]*$id[[:space:]]*\|.*\|[[:space:]]*ESTABLISHED" "$REG"; then
      echo "$REG: $id is ESTABLISHED, but $name in $LOG has $weak step(s) PARTIAL / NEEDS WORK / FAIL (#168)"
      bad=$((bad + 1))
    fi
  done
done < "$WORK/blocks"

echo "      $nb source block(s) in $LOG checked, joined to $REG by claim ID" >&2
[ "$bad" -eq 0 ] || exit 1
exit 0
