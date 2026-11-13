#!/usr/bin/env bash
# curate Step 0 sub-step 2 — the gotcha log's entry headers and Promoted table, with the
# entry count reconciled, so the log itself need not be read. Do not re-derive it.
# Usage: bash gotcha-headers.sh <gotcha-log>
# Exit:  0 every **Problem** sits under exactly one entry heading (a ### with none is a note) ·
#        1 they do not reconcile (named below) · 2 nothing was examined — no readable file,
#        or no headings outside comments.
# Headings and **Problem** lines inside <!-- --> are skipped (the template's example entry);
# Promoted table rows are not, because adopters fill in the template's commented table.
set -u

log=${1-}
[ -n "$log" ] && [ -f "$log" ] && [ -r "$log" ] || { echo "NO READABLE LOG: '${log}' — nothing was examined" >&2; exit 2; }

awk '
  { sub(/\r+$/, "") }
  prom && /^[ \t]*\|/ { rows[++nr] = $0 }               # Promoted rows count even inside a comment:
                                                       # adopters fill in the commented template table
  incom { if (index($0, "-->")) incom = 0; next }
  /^[ \t]*<!--/ { if (!index($0, "-->")) incom = 1; next }
  /^#+ / {
    lvl = $0; sub(/ .*/, "", lvl); L = length(lvl)
    if (L <= 3) {                                       # an entry or a section heading
      h++; hn[h] = NR; ht[h] = $0; hl[h] = L; owned[h] = 0
    }
    if (prom && L <= plvl) prom = 0                     # level-aware: entries nest under it
    if ($0 ~ /^#+ Promoted/ && !seenprom) { prom = 1; plvl = L; seenprom = 1 }
    next
  }
  /^\*\*Problem\*\*/ { problems++; if (h && hl[h] >= 2) owned[h]++; else orphan[++no] = NR; next }   # a title owns no entry
  END {
    if (h == 0) { print "NO HEADINGS outside comments — nothing was examined"; exit 2 }
    print "== headings (line: heading) =="
    for (i = 1; i <= h; i++) printf "%d: %s%s\n", hn[i], ht[i], (owned[i] ? "" : "   [no **Problem**]")
    print "== Promoted table =="
    if (!seenprom) print "(no Promoted heading)"
    else if (!nr) print "(no rows)"
    else for (i = 1; i <= nr; i++) print rows[i]
    entries = 0; bad = 0
    for (i = 1; i <= h; i++) {
      if (owned[i]) entries++
      if (owned[i] > 1) { printf "  line %d owns %d **Problem** lines: two entries under one heading?\n", hn[i], owned[i]; bad = 1 }
      if (!owned[i] && hl[i] == 3) { printf "  note: line %d is a ### heading with no **Problem**: a grouping heading, or a broken entry. Check it.\n", hn[i]; notes++ }
    }
    for (i = 1; i <= no; i++) { printf "  line %d: **Problem** under no entry heading\n", orphan[i]; bad = 1 }
    printf "%d entries, %d **Problem** lines, %d section headings\n", entries, problems + 0, h - entries
    if (bad) { print "exit 1: the counts do not reconcile. Read the lines named above before trusting the list."; exit 1 }
    print "exit 0: every **Problem** has exactly one entry heading" (notes ? "; read the notes above." : ".")
  }
' "$log"
