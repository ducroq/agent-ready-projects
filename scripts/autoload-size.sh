#!/usr/bin/env bash
# curate Step 0 sub-step 6 — size of the auto-loaded set. Do not re-derive it.
# Usage: bash autoload-size.sh <project-file> [<other auto-loaded file>...] [--instructed <file>...]
#   The first file is the project file. List every file your tool loads unasked
#   (for Claude Code: CLAUDE.md and the user-level memory index). Files after
#   --instructed are ones the project file tells the agent to read every session;
#   they are listed and sized, never summed.
# Exit: 0 under the soft target · 1 at or over it · 2 usage, or a file unreadable.
# It prints the over-budget procedure only when the set is near or over budget, so
# curate carries it nowhere else.
set -u
SOFT=35000 WARN=40000 NEAR=31500 PROJ=15000   # NEAR: within 10% of SOFT, a choice

auto=() instr=() mode=auto
for a in "$@"; do
  if [ "$a" = --instructed ]; then mode=instr; continue; fi
  case "$a" in --*) echo "unknown option: $a" >&2; exit 2 ;; esac
  [ -f "$a" ] && [ -r "$a" ] || { echo "UNREADABLE $a — the total would be short by a whole file" >&2; exit 2; }
  if [ "$mode" = auto ]; then auto+=("$a"); else instr+=("$a"); fi
done
[ "${#auto[@]}" -gt 0 ] || { echo "usage: autoload-size.sh <project-file> [<file>...] [--instructed <file>...]" >&2; exit 2; }

# wc -m counts characters only under a UTF-8 locale, and C.UTF-8 is missing on
# older macOS; there it silently counts bytes. Find one that works, or say so.
U=""; for l in C.UTF-8 en_US.UTF-8 UTF-8; do
  [ "$(printf '\303\251' | LC_ALL=$l wc -m 2>/dev/null | tr -d ' ')" = 1 ] && { U=$l; break; }; done
[ -n "$U" ] || { U=C; echo "NOTE: no UTF-8 locale found, so 'chars' below may be bytes." ; }
chars() { LC_ALL=$U wc -m < "$1" | tr -d ' '; }
bytes() { wc -c < "$1" | tr -d ' '; }
# What a table weighs without formatter padding: runs of spaces beside a pipe to
# one, delimiter dashes to three. Fenced blocks are left alone. Read from stdin,
# so a file named like an option is never parsed as one.
# pad() compares against the same awk pass with the edits off (e=0), so a missing
# final newline, which awk adds, cancels out.
depad() { LC_ALL=$U awk -v e="${2:-1}" '
  match($0, /^ ? ? ?(```+|~~~+)/) { m = substr($0, RSTART, RLENGTH); sub(/^ +/, "", m)
    if (!f) { f = m; print; next }
    if (substr(m, 1, 1) == substr(f, 1, 1) && length(m) >= length(f)) { f = ""; print; next } }
  e && !f && /^[ \t]*\|/ { gsub(/[ \t]+\|/, " |"); gsub(/\|[ \t]+/, "| ")
    if ($0 ~ /^[ \t|:-]+$/) gsub(/-----*/, "---") }
  { print }' < "$1" | LC_ALL=$U wc -m | tr -d ' '; }
pad() { echo $(( $(depad "$1" 0) - $(depad "$1") )); }
num() { case "$1" in ''|*[!0-9]*) echo "COULD NOT COUNT $2 (got '$1') — no total stands" >&2; exit 2 ;; esac; }
for f in "${auto[@]}" ${instr[@]+"${instr[@]}"}; do num "$(chars "$f")" "$f"; num "$(depad "$f")" "$f"; done

row() {  # row <file>
  local c b pad
  c=$(chars "$1"); b=$(bytes "$1"); pad=$(pad "$1")
  printf '  %7d chars %7d bytes  %s' "$c" "$b" "$1"
  [ "$pad" -gt 0 ] && printf '  (table padding %d chars)' "$pad"
  printf '\n'
}

echo "== AUTO-LOADED SET (characters, wc -m) =="
total=0 padtot=0
for f in "${auto[@]}"; do row "$f"; total=$((total + $(chars "$f"))); p=$(pad "$f"); [ "$p" -gt 0 ] && padtot=$((padtot + p)); done
echo "  total: $total chars in ${#auto[@]} file(s), against a soft target of $SOFT; Claude Code warns at $WARN."
echo "  Name the unit with every number you report: audit-context Step 1 counts bytes,"
echo "  which read higher on non-ASCII text, so a set under $SOFT here can be over it there."
echo "  A file your tool loads that is not listed above is not counted: name it."

if [ "${#instr[@]}" -gt 0 ]; then
  echo
  echo "== INSTRUCTION-LOADED (read when the project file says so; not always read, not summed) =="
  for f in "${instr[@]}"; do row "$f"; done
fi

pc=$(chars "${auto[0]}")
[ "$pc" -gt 0 ] || { echo; echo "== PROJECT FILE IS EMPTY: ${auto[0]} — a wrong path or a truncated file =="; }
if [ "$pc" -gt "$PROJ" ]; then
  echo
  echo "== PROJECT FILE OVER $PROJ CHARS: ${auto[0]} at $pc =="
  echo "  Flag it even with the set under budget: past $PROJ it is carrying narrative."
fi

if [ "$total" -ge "$NEAR" ]; then
  echo
  if [ "$total" -ge "$SOFT" ]; then echo "== OVER BUDGET: $total chars against $SOFT =="
  else echo "== NEAR BUDGET: $total chars, within 10% of $SOFT =="; fi
  echo "  In this order:"
  if [ "$padtot" -gt 0 ]; then
    echo "  1. Table padding is $padtot chars of it. If a formatter (prettier, dprint, markdownlint)"
    echo "     pads tables, judge the de-padded size before proposing any cut. If it is material,"
    echo "     de-pad the file AND exempt it from whatever re-pads it (format-on-save, pre-commit,"
    echo "     CI); confirm which one touches it, from the cwd it runs in (Prettier resolves its"
    echo "     ignore file from the cwd)."
  else
    echo "  1. No table padding measured."
  fi
  echo "  2. Session-narrative footers (_Last updated: ..._ / _Earlier ..._) in any auto-loaded"
  echo "     file usually duplicate the session files (memory/project_session_*.md). Keep at"
  echo "     most one, the most recent, and only if the index cannot carry it. An index row is"
  echo "     a pointer, not a re-summary."
  echo "  3. Any trim follows sub-step 6's trim rules (protected sections, facts to keep,"
  echo "     fresh reader, delete rather than reword)."
  echo "  4. If that is not enough, surface it to the engineer."
fi

[ "$total" -lt "$SOFT" ]
