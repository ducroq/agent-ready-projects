#!/usr/bin/env bash
# curate Step 0 sub-step 5 — each open hypothesis's heading, Review-by, trigger and status
# lines, with past dates flagged, so the log itself need not be read. Do not re-derive it.
# Usage: bash hypothesis-due.sh <hypothesis-log> [YYYY-MM-DD]   (date defaults to today, UTC)
# An entry is a ### heading outside comments and fences. It is skipped under a ## heading
# (or #) that STARTS with Resolved, Closed or Archive, any case; it is dormant under ## Dormant or when its
# status starts with "dormant". Labels are read anywhere on a line, first mention wins:
# **Review by:** x · **Review by**: x · … **Review by** x. **Status.** …
# Exit: 0 listed (0 open is a result) · 1 an open entry lacks a Review-by line (named) ·
#       2 nothing was examined — no readable file, no ### heading, an unclosed comment or fence.
set -u

log=${1-}
today=${2-$(date -u +%F)}
[ -n "$log" ] && [ -f "$log" ] && [ -r "$log" ] || { echo "NO READABLE LOG: '${log}' — nothing was examined" >&2; exit 2; }
printf '%s' "$today" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || { echo "BAD DATE: '$today'" >&2; exit 2; }

awk -v today="$today" '
  # The value after a bold label, up to the next bold label; cut only for display.
  function field(s, re) { match(s, re); s = substr(s, RSTART + RLENGTH)
                          sub(/^[^*]*\*\*[:.]?[ \t]*/, "", s)
                          if (match(s, /\*\*[A-Z][^*]*\*\*/)) s = substr(s, 1, RSTART - 1)
                          sub(/[ \t]+$/, "", s)
                          return s }
  function show(s) { return s == "" ? "(none)" : (length(s) > 220 ? substr(s, 1, 220) " …" : s) }
  function flush() {
    if (!cur) return
    dorm = insecdorm || tolower(st) ~ /^dormant/
    if (dorm) ndorm++; else n++
    flag = ""; cond = (tolower(rb) ~ /whichever| or after | or when | or once /)
    if (rb == "") { missing++; flag = "   [NO Review-by line]" }
    else if (match(rb, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
      d = substr(rb, RSTART, 10)
      if (d < today) { flag = "   [DATE PAST: " d " — is it the deadline?]"; ndue++ }
      if (cond) flag = flag "   [or a condition — has it been met?]"
    } else flag = "   [no date: a condition — has it been met?]"
    if (tolower(st) ~ /trigger(ed| fired)/ && tolower(st) !~ /(not( yet)?|un|never) ?trigger/)
      flag = flag "   [status says triggered]"
    printf "%d: %s%s%s\n", line, cur, (dorm ? "   [dormant]" : ""), flag
    printf "   review by: %s\n", show(rb)
    printf "   trigger:   %s\n", show(rt)
    printf "   status:    %s\n", show(st)
    cur = ""
  }
  { sub(/\r+$/, "") }
  !incom && /^ ? ? ?(```|~~~)/ {
    run = $0; sub(/^ */, "", run); c = substr(run, 1, 1); k = 0
    while (substr(run, k + 1, 1) == c) k++
    if (!fence) { if (c == "`" && index(substr(run, k + 1), "`")) next   # inline code, not a fence
                  fence = 1; fch = c; flen = k; fline = NR }
    else if (c == fch && k >= flen && substr(run, k + 1) ~ /^[ \t]*$/) fence = 0
    next
  }
  fence { next }
  incom { if (index($0, "-->")) incom = 0; next }
  /^[ \t]*<!--/ { if (!index($0, "-->")) { incom = 1; comline = NR }; next }
  /^##? / { flush(); h = tolower($0); closed = (h ~ /^##? +(resolved|closed|archive)/)
            insecdorm = (h ~ /^##? +dormant/); next }
  /^### / { heads++; flush(); if (!closed) { cur = $0; line = NR; rb = rt = st = "" }; next }
  cur && rb == "" && /\*\*Review by/ { rb = field($0, "\\*\\*Review by") }
  cur && rt == "" && /\*\*(Revisit trigger|Trigger)/ { rt = field($0, "\\*\\*(Revisit trigger|Trigger)") }
  cur && st == "" && /\*\*Status/ { st = field($0, "\\*\\*Status") }
  END {
    if (incom) { printf "UNCLOSED COMMENT from line %d — the rest of the file was not examined\n", comline; exit 2 }
    if (fence) { printf "UNCLOSED FENCE from line %d — the rest of the file was not examined\n", fline; exit 2 }
    if (!heads) { print "NO ### HEADINGS outside comments and fences — nothing was examined"; exit 2 }
    flush()
    printf "== %d open, %d dormant, %d past their Review-by date (as of %s) ==\n", n, ndorm, ndue, today
    if (n > 10) print "   More than ~10 open: memory-cluttering; promote, close or mark dormant."
    if (missing) { printf "== %d entr%s with no Review-by line ==\n", missing, (missing == 1 ? "y" : "ies"); exit 1 }
  }
' "$log"
