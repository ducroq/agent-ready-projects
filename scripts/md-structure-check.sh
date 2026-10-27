#!/usr/bin/env bash
# md-structure-check.sh — markdown that reads fine in a diff but renders wrong.
# review-changes Step 1.5 runs this; so does lint rule 14 (via extract-step15.py).
#
# Usage: md-structure-check.sh FILE...   or file names on stdin, one per line.
#   Names not ending in .md, and names that are not files, are skipped.
# Output: one line per finding on stdout; on stderr, the number of markdown
#   files examined. A clean run and an empty list both print no findings, so
#   read the count: zero while the caller listed markdown files is a broken
#   pipeline, not a clean change.
# Exit: 0 no findings, 1 findings, 2 usage error.
#
# Checks: a table row with more cells than its delimiter row (GFM drops the
# excess), a header disagreeing with its delimiter row, an unclosed code fence,
# a code span holding ** inside a bold run (a formatter can corrupt it), and
# unclosed YAML frontmatter (then no check ran on that file).
#
# KNOWN FALSE POSITIVES — do not "fix" these: a setext heading, a spaced
# `- - -`, frontmatter not at line 1, a table inside a fenced block indented
# four or more spaces, and unrecognised frontmatter whose closing `---` reads
# as a delimiter row.
# KNOWN BLIND SPOTS: tables in blockquotes or with no delimiter row, a bold span
# crossing a line break; a lone-CR file can go entirely silent, and so can every
# line above the next `---` when a leading `---` is followed by key-shaped prose
# such as `Note: ...` (#163). A name git quotes (one holding a tab, newline,
# `"` or `\`) does not end in .md as printed, so it is skipped and not counted.
# Before widening any of these trades, read
# docs/rationale/review-changes.md.
#
# The awk program below is byte-identical to the one Step 1.5 embedded through
# v1.50.0, so its fixture history (#52, #103, #150, #151, #158, #159, #164)
# applies unchanged. Keep the awk call's opening and closing lines as they are:
# tests/lint/extract-step15.py anchors on them, and quoting them here would make
# it extract this comment instead.
set -u

list() {
  if [ "$#" -gt 0 ]; then printf '%s\n' "$@"; else cat; fi
}

n=0; hits=0
while IFS= read -r f; do
  case $f in (*.md) ;; (*) continue ;; esac
  [ -f "$f" ] || continue
  n=$((n + 1))
  out=$(
  awk -v F="$f" '
    function cells(s,   t, n) {
      t = s; gsub(/\\\|/, "", t)
      sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
      sub(/^\|/, "", t); sub(/\|$/, "", t)
      n = gsub(/\|/, "|", t); return n + 1
    }
    function isdelim(s,   t) {
      t = s; gsub(/\\\|/, "", t); gsub(/[ \t]/, "", t)
      return (t ~ /-/ && t ~ /^[|:-]+$/)
    }
    # `$(0)`, never `\$0` (#77). BOM stripped by an octal sub, not `\x` (#151, #164).
    { if (NR == 1) sub(/^\357\273\277/, "")
      sub(/\r$/, "") }              # CRLF first, or isdelim() never matches (#52)
    # Frontmatter: line 1 arms the skip, the first non-blank line decides (#52, #151,
    # #163). `\047` is an apostrophe; a literal one ends the shell string (#105).
    NR == 1 && $(0) ~ /^---[ \t]*$/ { fmpend = 1; next }
    fmpend && $(0) ~ /^([ \t]*|[ \t]*#.*)$/ { next }
    fmpend { fmpend = 0
             if ($(0) ~ /^["\047]?[A-Za-z_][A-Za-z0-9_.-]*["\047]?[ \t]*:/) { infm = 1; next } }
    infm && $(0) ~ /^(---|\.\.\.)[ \t]*$/ { infm = 0; prev = ""; next }
    infm { next }
    {
      # Do not widen the 3-space strip (#150). A substr loop: mawk mis-strips a regex.
      bare = $(0); for (k = 0; k < 3 && substr(bare, 1, 1) == " "; k++) bare = substr(bare, 2)
      if (bare ~ /^```/ || bare ~ /^~~~/) {
        c = substr(bare, 1, 1); n = 0
        while (substr(bare, n + 1, 1) == c) n++
        if (fch == "") { if (n >= 3) { fch = c; flen = n } }
        else if (c == fch && n >= flen) fch = ""
        intbl = 0; prev = ""; next
      }
      if (fch != "") next
      # Emphasis (#50, #158): TWO risky spans in one bold run, or ONE in a run closed
      # on the line. Spans close on an equal backtick run, as in CommonMark (#159).
      { masked = ""; rest = $(0)
        while (match(rest, /`+/)) {
          s = RSTART; n = RLENGTH; after = substr(rest, s + n); t = after; off = 0; cl = 0
          while (match(t, /`+/)) {
            if (RLENGTH == n) { cl = off + RSTART; break }
            off += RSTART + RLENGTH - 1; t = substr(t, RSTART + RLENGTH)
          }
          if (!cl) { masked = masked substr(rest, 1, s + n - 1); rest = after; continue }
          inner = substr(after, 1, cl - 1)
          if (inner ~ /^ .* $/) inner = substr(inner, 2, length(inner) - 2)
          # Risky: any `**` in the span (#158).
          mark = "\002"
          if (index(inner, "**")) mark = "\001"
          masked = masked substr(rest, 1, s - 1) mark
          rest = substr(after, cl + n)
        }
        masked = masked rest
        inb = 0; nrisk = 0; run = 0; nclosed = 0
        for (i = 1; i <= length(masked); i++) {
          if (substr(masked, i, 2) == "**") { if (inb) nclosed += run; run = 0; inb = 1 - inb; i++; continue }
          if (inb && substr(masked, i, 1) == "\001" && ++run > nrisk) nrisk = run
        }
        # A line with no backtick has no span, whatever bytes it holds.
        if (index($(0), "`")) {
          if (nrisk > 1)
            printf "%s:%d: two backticked tokens abutting ** inside one bold span — a formatter can join the runs and corrupt both\n", F, NR
          else if (nclosed > 0)
            printf "%s:%d: a code span holding ** in a bold span closed on this line\n", F, NR
        }
      }
      if (isdelim($(0)) && prev != "" && (index($(0), "|") || index(prev, "|"))) {
        base = cells($(0)); intbl = 1
        if (cells(prev) != base)
          printf "%s:%d: header has %d cells, delimiter row defines %d — not a valid table\n", F, NR-1, cells(prev), base
        prev = $(0); next
      }
      if (intbl) {
        if ($(0) ~ /^[ \t]*$/) intbl = 0
        else if (index($(0), "|") && cells($(0)) > base)
          printf "%s:%d: row has %d cells, table defines %d — the excess is dropped when rendered\n", F, NR, cells($(0)), base
      }
      prev = $(0)
    }
    END { if (fch != "") printf "%s: unclosed %s code fence\n", F, fch
          # Unclosed frontmatter swallowed the file: say no check ran (#103, #144).
          if (infm) printf "%s: unclosed YAML frontmatter — no check ran on any line of this file\n", F }
  ' "$f"
  ) || { echo "md-structure-check: awk failed on $f" >&2; exit 2; }
  [ -n "$out" ] && { printf '%s\n' "$out"; hits=$((hits + 1)); }
done < <(list "$@" | sort -u)

echo "md-structure-check: $n markdown file(s) examined" >&2
[ "$hits" -eq 0 ]
