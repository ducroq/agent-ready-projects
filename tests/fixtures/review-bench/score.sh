#!/usr/bin/env bash
# Scores one review run against the manifest. MECHANICAL on purpose: the person
# who seeded the defects must not be the person deciding whether a finding counts.
#
# Usage: score.sh <findings-file> <variant>
#   <findings-file>  one finding per line, starting `path/to/file:LINE`
#   <variant>        seeded | seeded-silent | clean
#
# A finding matches a defect when the file matches and the line is within +/-4 of
# the hint. The window is generous because a correct finding often points at the
# consequence rather than the seeded line; a tighter window would score correct
# reviews as misses.
set -u
F="${1:?usage: score.sh <findings-file> <variant>}"
V="${2:?usage: score.sh <findings-file> <variant>}"
M="$(dirname "$0")/manifest.tsv"
[ -r "$F" ] || { echo "cannot read $F"; exit 2; }

case "$V" in
  seeded)        WANT="D2 D3 D4 D5 D6 D7" ;;
  seeded-silent) WANT="D1" ;;
  clean)         WANT="" ;;
  *) echo "unknown variant: $V"; exit 2 ;;
esac

TOTAL=0; HIT=0; MATCHED_LINES=""
for id in $WANT; do
  row="$(awk -F'\t' -v i="$id" '$1==i' "$M")"
  file="$(cut -f3 <<<"$row")"; hint="$(cut -f4 <<<"$row")"; cls="$(cut -f2 <<<"$row")"
  TOTAL=$((TOTAL+1)); found=""
  while IFS= read -r line; do
    lf="$(sed -n 's|^[^ ]*\b\('"$(basename "$file")"'\):\([0-9]\+\).*|\2|p' <<<"$line")"
    [ -n "$lf" ] || continue
    if [ "$lf" -ge $((hint-4)) ] && [ "$lf" -le $((hint+4)) ]; then found="$line"; break; fi
  done < "$F"
  if [ -n "$found" ]; then
    HIT=$((HIT+1)); MATCHED_LINES="$MATCHED_LINES$found"$'\n'
    printf '  FOUND    %s  %-20s %s:%s\n' "$id" "$cls" "$file" "$hint"
  else
    printf '  MISSED   %s  %-20s %s:%s\n' "$id" "$cls" "$file" "$hint"
  fi
done

REPORTED="$(grep -c ':[0-9]' "$F" || true)"
FP=$((REPORTED - HIT))
echo
if [ "$TOTAL" -gt 0 ]; then
  printf 'recall:    %d/%d\n' "$HIT" "$TOTAL"
fi
printf 'reported:  %d findings, %d matched a seeded defect, %d did not\n' "$REPORTED" "$HIT" "$FP"
if [ "$V" = clean ]; then
  echo
  echo "NOTE: on the clean variant EVERY reported finding is a false positive by"
  echo "construction — unless it is a real defect the corpus author did not know"
  echo "about, which is a result worth more than the benchmark run."
fi
