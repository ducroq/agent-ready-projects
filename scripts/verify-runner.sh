#!/usr/bin/env bash
# curate Step 0 sub-step 3 — verify runner (canonical). Do not re-derive it; see issue #34.
# Usage: bash verify-runner.sh <file>...        VERIFY_TIMEOUT=<seconds> caps each command.
# Exit:  0 something was verified and nothing failed · 1 a claim failed, errored or was
#        malformed · 2 the run cannot be trusted — no files, an operand that is not a
#        readable file, nothing extracted, or nothing that produced a verdict.
set -u

[ "$#" -gt 0 ] || { echo "no files given — nothing was checked" >&2; exit 2; }
for f in "$@"; do [ -f "$f" ] && [ -r "$f" ] || { echo "UNREADABLE $f — the run would be short by a whole file" >&2; exit 2; }; done

extract() {
  awk '
    function isdelim(s,   x) { x = s; gsub(/\\\|/, "", x); gsub(/[ \t]/, "", x)
                               return (x ~ /-/ && x ~ /^[|:-]+$/) }
    function haspipe(s,   x) { x = s; gsub(/\\\|/, "", x); return index(x, "|") > 0 }
    function maskspans(m, orig,   res, pos, o, L, nb, p2, R, e, i, pad, span) {
      res = m                                    # CommonMark: a run of N backticks opens a
      pos = 1                                    # span that the next run of exactly N closes
      while (1) {
        o = substr(res, pos); if (!match(o, /`+/)) break
        L = pos + RSTART - 1; nb = RLENGTH; p2 = L + nb; e = 0
        while (1) {
          o = substr(res, p2); if (!match(o, /`+/)) break
          R = p2 + RSTART - 1
          if (RLENGTH == nb) { e = R + nb - 1; break }
          p2 = R + RLENGTH
        }
        if (!e) { pos = L + nb; continue }       # an unpaired run masks nothing
        span = substr(res, L, e - L + 1)
        if (tolower(span) ~ /<!--[ \t]*verify:/ && index(span, "-->") == 0)
          print "B\034" FILENAME "\034" substr(orig, L, 60)   # opener inside, closer outside
        pad = ""; for (i = L; i <= e; i++) pad = pad " "
        res = substr(res, 1, L - 1) pad substr(res, e + 1); pos = e + 1
      }
      return res
    }
    { sub(/\r+$/, "") }                                    # CRLF: strip before anything reads
                                                           # the line. isdelim() strips spaces and
                                                           # tabs but not \r, so intbl is never set,
                                                           # the table un-escape never runs, and an
                                                           # escaped-pipe command is still extracted,
                                                           # counted and EXECUTED — mangled.
                                                           # Corruption, not silence: the shape of
                                                           # #52 with a worse disposition. See #58.
                                                           # `\r+`, not `\r`: an index blob already
                                                           # holding CRLF, converted again, yields
                                                           # `\r\r\n`, and stripping one CR left the
                                                           # defect intact on the fixed runner.
                                                           # ⚠️ A LONE CR (no LF) is NOT fixed and
                                                           # cannot be here: awk reads the file as one
                                                           # record, so no table is entered and the
                                                           # un-escape never runs — a false PASS at
                                                           # exit 0. Same residual review-changes
                                                           # discloses beside its own #52 fix; worse
                                                           # here, because this runner EXECUTES.
                                                           # NB no apostrophe anywhere in this block:
                                                           # the awk program is single-quoted.
    # `$(0)`, never `\$0`: skill ARGUMENTS are substituted into the skill BODY,
    # so a bare `\$0` is delivered as the first argument word and this program
    # then reads a constant — no table entered, escaped pipes EXECUTED mangled.
    # `$(0)` is the only form correct on both that path and the extraction
    # path the fixture uses. Measured; see #77 and the v1.27.0 changelog entry.
    FNR == 1 {
      if (fch != "") print "U\034" curfile "\034" "a fence opened at line " openline " and never closed"
      fch = ""; intbl = 0; prev = ""; curfile = FILENAME    # no state may cross a file
    }
    {
      bare = $(0); sub(/^[ \t]*/, "", bare)                 # a fence may be indented
      if (bare ~ /^```/ || bare ~ /^~~~/) {                 # and opens on ``` or ~~~
        c = substr(bare, 1, 1); k = 0
        while (substr(bare, k + 1, 1) == c) k++
        if (fch == "") { fch = c; flen = k; openline = FNR }
        else if (c == fch && k >= flen) fch = ""            # closing only on the same
        intbl = 0; prev = ""; next                          # character, at least as long
      }
      if (fch != "") next                                   # inside a fence: documentation
      if (isdelim($(0)) && index($(0), "|") && prev != "") { intbl = 1; prev = $(0); next }
      if (intbl && !haspipe($(0))) intbl = 0                # a table ends at its last row
      line = $(0)
      mask = maskspans(tolower(line), line)                 # match case-insensitively, at
      while (match(mask, /<!--[ \t]*verify:[ \t]*/)) {      # preserved offsets
        p = RSTART + RLENGTH
        rest = substr(line, p)                              # take the command from the
        e = index(rest, "-->")                              # ORIGINAL line
        if (e == 0) { print "M\034" FILENAME "\034" substr(rest, 1, 60); break }
        cmd = substr(rest, 1, e - 1); sub(/[ \t]+$/, "", cmd)
        if (tolower(cmd) ~ /<!--[ \t]*verify:/) { print "D\034" FILENAME "\034" substr(cmd, 1, 60); break }
        if (intbl) gsub(/\\\|/, "|", cmd)                   # a table cell escapes its pipes
        if (cmd == "") print "E\034" FILENAME "\034" substr($(0), 1, 60)
        else print "C\034" FILENAME "\034" cmd
        mask = substr(mask, p + e + 2); line = substr(line, p + e + 2)
      }
      prev = $(0)
    }
    END { if (fch != "") print "U\034" curfile "\034" "a fence opened at line " openline " and never closed" }
  ' "$@"
}

case "${VERIFY_TIMEOUT:-30}" in *[!0-9]*|'') echo "VERIFY_TIMEOUT must be whole seconds" >&2; exit 2 ;; esac
TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT
TO=""; command -v timeout >/dev/null 2>&1 && TO="timeout ${VERIFY_TIMEOUT:-30}"
pass=0 fail=0 err=0 manual=0 cannot=0 bad=0 seen=0 n=0 tmo=0

while IFS=$'\034' read -r kind file cmd; do
  if [ "$kind" != C ]; then
    bad=$((bad + 1))
    case "$kind" in
      M) why="never closed" ;; D) why="opens a second verify before closing the first" ;;
      B) why="inside a code span, but its --> is outside it" ;;
      U) why="every annotation after it was skipped" ;; *) why="empty" ;;
    esac
    printf 'MALFORMED      %s :: %s (%s)\n' "$file" "$cmd" "$why"; continue
  fi
  seen=$((seen + 1))
  case "$(printf '%s' "$cmd" | tr 'A-Z' 'a-z')" in
    manual|manual[[:space:]:]*)                          # `manual-check.sh` is a command
      manual=$((manual + 1)); printf 'MANUAL         %s :: %s\n' "$file" "$cmd"; continue ;;
  esac
  n=$((n + 1))
  OUTF="$TMPD/$n.out"; ERRF="$TMPD/$n.err"               # never reused: a backgrounded
  ${TO:-} bash -c "$cmd" </dev/null >"$OUTF" 2>"$ERRF"; rc=$?   # child still holds the old
  head1=$(awk 'NF { sub(/^[ \t]+/, ""); print; exit }' "$OUTF") # one and writes into it
  note=""
  case "$head1" in
    "CANNOT VERIFY"|"CANNOT VERIFY"[!A-Za-z0-9]*)        # the colon is conventional, not
      cannot=$((cannot + 1)); printf 'CANNOT-VERIFY  %s :: %s\n                 %s\n' "$file" "$cmd" "$head1"; continue ;;
    FAIL)                                                # this framework taught `|| echo FAIL`
      [ "$rc" -ne 0 ] || { rc=1; note="  ! legacy verdict word — rewrite it to exit non-zero"; } ;;
    FAIL*)                                               # cannot be told from evidence, so
      [ "$rc" -ne 0 ] || note="  ! output begins FAIL yet it exited 0 — if that is a verdict, rewrite it" ;;
  esac
  if   [ -n "$TO" ] && [ "$rc" -eq 124 ]; then d=ERROR; err=$((err + 1)); tmo=$((tmo + 1)); head1="(timed out at ${VERIFY_TIMEOUT:-30}s — the runner's limit, not the claim's)"
  elif [ "$rc" -eq 127 ];  then d=ERROR; err=$((err + 1)); [ -n "$head1" ] || head1="(command not found)"
  elif [ -z "$head1" ];    then d=ERROR; err=$((err + 1)); head1="(no output — it proved nothing)"
  elif [ "$rc" -eq 0 ];    then d=PASS;  pass=$((pass + 1))
  else                          d=FAIL;  fail=$((fail + 1))
  fi
  printf '%-14s %s :: %s\n                 %s%s\n' "$d" "$file" "$cmd" "$head1" "$note"
  [ "$d" = PASS ] || [ ! -s "$ERRF" ] || printf '                 ! %s\n' "$(awk 'NF { print; exit }' "$ERRF")"
done < <(extract "$@")

annotations=$(grep -ahoiE '<!--[[:space:]]*verify:' "$@" | wc -l)
printf 'ran %d of %d annotations — %d pass, %d fail, %d error, %d cannot-verify; %d manual, %d malformed\n' \
  "$n" "$annotations" "$pass" "$fail" "$err" "$cannot" "$manual" "$bad"
[ "$tmo" -eq 0 ] || echo "$tmo error(s) timed out — raise VERIFY_TIMEOUT before reading them as findings"
[ "$seen" -gt 0 ] || { [ "$bad" -eq 0 ] && echo 'ZERO COMMANDS EXTRACTED — a defect in the runner or the annotations, never a pass.' \
                                        || echo 'NO USABLE ANNOTATIONS — every one found was malformed.'; exit 2; }
[ $((pass + fail + err)) -gt 0 ] || { echo 'NOTHING PRODUCED A VERDICT — every annotation was manual or unreachable.'; exit 2; }
[ $((fail + err + bad)) -eq 0 ] || exit 1
