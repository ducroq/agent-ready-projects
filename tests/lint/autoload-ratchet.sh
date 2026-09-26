#!/usr/bin/env bash
# Rule 15 — the AUTO-LOADED set only ratchets down.
#
# Usage: autoload-ratchet.sh <repo-root> [--update | --raise "<reason>"]
#
# Violations to stdout, coverage to stderr. Exit 0 clean (or SKIPPED), 1
# violations, 2 could not run. A `SKIPPED:` line on stderr means the rule did not
# bind and the caller must count it as not-run, never as a pass.
#
# WHY A RATCHET AND NOT A LIMIT. `templates/audit-context.md` flags the project
# file over 35,000 characters (soft) and 40,000 (hard), and says where those come
# from: 40,000 is **where Claude Code itself warns**. That is an alarm, not a
# budget — nothing anywhere claims 40,000 is a good size, and the same skill says
# outright that NO character threshold for the memory index has been derived.
# Rule 8 already settled how this repo handles that: "A ratchet, not a budget: no
# threshold invented". This is rule 8's mechanism pointed at the other surface.
#
# WHY THIS SURFACE. It is the session-start set: CLAUDE.md, which Claude Code
# auto-loads, plus memory/MEMORY.md, which it does NOT (only the user-level
# ~/.claude/projects/<slug>/memory/MEMORY.md is auto-loaded) but which a
# resumed session is told to read first — CLAUDE.md's "continue" row.
# Found 2026-09-26 by /audit-context Step 1. The old name "auto-loaded" survives
# in this script's output strings because the fixture asserts on them.
# templates/ is paid per invocation and is
# already ratcheted; this was measured and unbudgeted, at 49,172 bytes against
# the 40,000 alarm, and it GREW during the session that was cutting it.
#
# TWO NUMBERS, both ratcheted, neither derived: total bytes, and the index's line
# count. The line count is here because an index is a list — `audit-context`
# prescribes ~60 lines for it and declines to prescribe characters, so a ratchet
# is the only honest instrument for the second one.
set -u

root="${1:-}"; mode="${2:-}"; reason="${3:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: autoload-ratchet.sh <repo-root> [--update|--raise <reason>]" >&2; exit 2; }
cd "$root" || exit 2
BASELINE="tests/lint/autoload-baseline.tsv"

# DECLARED, not discovered — and that is the one place this differs from rule 8.
# The auto-loaded set is a fact about the tool, not a directory: CLAUDE.md is read
# every session by Claude Code, and memory/MEMORY.md by the CLAUDE.md row that
# routes to it. A `find` cannot know that, so the list is written down and a file
# joining it is a deliberate edit here.
AUTOLOAD="CLAUDE.md memory/MEMORY.md"

missing=""
for f in $AUTOLOAD; do [ -f "$f" ] || missing="$missing $f"; done
if [ -n "$missing" ]; then
  # memory/ is gitignored, so a fresh clone and CI have no index. Measuring the
  # remaining member would read as a large shrink and FAIL on the "lock it in"
  # arm — a green CI turned red by a file that was never supposed to be there.
  echo "SKIPPED: the auto-loaded set is incomplete —$missing absent (gitignored here). A partial measure reads as a shrink, so this rule does not bind." >&2
  echo "      0 of 2 auto-loaded file(s) measured" >&2
  exit 0
fi

bytes=0
for f in $AUTOLOAD; do bytes=$((bytes + $(wc -c < "$f"))); done
lines=$(wc -l < memory/MEMORY.md)

read_key() { sed -n "s/^# $1[[:space:]]\{1,\}\([0-9]\{1,\}\).*/\1/p" "$BASELINE" 2>/dev/null | head -1; }
prior_notes() { [ -f "$BASELINE" ] && grep -E '^# (RAISED|seeded|ratcheted) ' "$BASELINE" || :; }

write_baseline() { # write_baseline <bytes> <lines> <note>
  local carried; carried=$(prior_notes)
  { echo "# Lint rule 15 baseline — the AUTO-LOADED set. Both numbers only go DOWN."
    echo "# Lock a reduction in:  bash tests/lint/autoload-ratchet.sh . --update"
    echo "# Pay for growth deliberately:  ... --raise \"why this must get bigger\""
    echo "# Every raise is recorded below, oldest first; notes accumulate, never replace."
    echo "# BYTES $1"
    echo "# LINES $2"
    [ -n "$carried" ] && printf '%s\n' "$carried"
    [ -n "${3:-}" ] && echo "# $3"
    for f in $AUTOLOAD; do printf '%s\t%s\n' "$f" "$(wc -c < "$f")"; done
  } > "$BASELINE"
}

case "$mode" in
  --update)
    if [ ! -f "$BASELINE" ]; then
      write_baseline "$bytes" "$lines" "seeded $(date +%Y-%m-%d)"
      echo "baseline seeded at $bytes bytes / $lines index lines"; exit 0
    fi
    wb=$(read_key BYTES); wl=$(read_key LINES)
    if { [ -n "$wb" ] && [ "$bytes" -gt "$wb" ]; } || { [ -n "$wl" ] && [ "$lines" -gt "$wl" ]; }; then
      echo "REFUSED: --update cannot raise the ceiling (bytes ${wb:-none} -> $bytes, lines ${wl:-none} -> $lines)." >&2
      echo "Pay for it with a cut elsewhere, or raise it deliberately:" >&2
      echo "    bash tests/lint/autoload-ratchet.sh . --raise \"why this must get bigger\"" >&2
      exit 2
    fi
    write_baseline "$bytes" "$lines" "ratcheted down $(date +%Y-%m-%d)"
    echo "baseline updated: $bytes bytes / $lines index lines"; exit 0 ;;
  --raise)
    [ -n "$reason" ] || { echo "REFUSED: --raise needs a reason argument. The reason is the whole point." >&2; exit 2; }
    ob=$(read_key BYTES); ol=$(read_key LINES)
    write_baseline "$bytes" "$lines" "RAISED $(date +%Y-%m-%d) from ${ob:-none}b/${ol:-none}l to ${bytes}b/${lines}l: $reason"
    echo "ceiling RAISED ${ob:-none} -> $bytes bytes, ${ol:-none} -> $lines lines: $reason"; exit 0 ;;
  ''|--check) ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac

[ -f "$BASELINE" ] || { echo "cannot read $BASELINE — this rule has no ceiling to compare against and checked nothing" >&2; exit 2; }
wb=$(read_key BYTES); wl=$(read_key LINES)
{ [ -n "$wb" ] && [ -n "$wl" ]; } || { echo "$BASELINE carries no '# BYTES'/'# LINES' line — this rule cannot bind and checked nothing" >&2; exit 2; }

issues=0
if [ "$bytes" -gt "$wb" ]; then
  echo "auto-loaded set GREW: $bytes bytes against $wb (+$((bytes - wb))). This is paid every session before anyone asks for anything. Cut something, or raise it deliberately with --raise \"<reason>\"."
  issues=$((issues + 1))
elif [ "$bytes" -lt "$wb" ]; then
  echo "auto-loaded set is $((wb - bytes)) bytes SMALLER than the ceiling — lock it in so it cannot drift back: bash tests/lint/autoload-ratchet.sh . --update"
  issues=$((issues + 1))
fi
if [ "$lines" -gt "$wl" ]; then
  echo "memory/MEMORY.md GREW to $lines lines against $wl (+$((lines - wl))). An index is a list; a line is a unit of content there."
  issues=$((issues + 1))
elif [ "$lines" -lt "$wl" ]; then
  echo "memory/MEMORY.md is $((wl - lines)) line(s) shorter than the ceiling — lock it in with --update"
  issues=$((issues + 1))
fi

# Always say the size: silence from a checker that did not run is what this whole
# rule family exists to prevent.
echo "      2 auto-loaded file(s) measured; $bytes bytes against $wb, index $lines lines against $wl" >&2
[ "$issues" -eq 0 ] && exit 0
exit 1
