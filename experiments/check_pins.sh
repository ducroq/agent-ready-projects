#!/usr/bin/env bash
# Re-hash each pinned section of backlog.md and compare it with pins.tsv.
# A section runs from its "## EXP-NNN:" heading to the line before the next "## EXP-"
# heading (or end of file), with trailing blank lines dropped.
# Exit 0 all match, 1 a section changed or is missing, 2 nothing was checked.
set -o pipefail
d=$(cd "$(dirname "$0")" && pwd); n=0; bad=0
while IFS=$'\t' read -r id sha rest; do
  case "$id" in ''|'#'*|id) continue;; esac
  got=$(awk -v id="$id" '$0 ~ "^## "id":" {on=1} on && /^## EXP-/ && $0 !~ "^## "id":" {exit} on' "$d/backlog.md" \
        | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' | sha256sum | cut -c1-64)
  n=$((n + 1))
  if [ "$got" = "$sha" ]; then echo "PASS $id ${sha:0:12}"; else echo "FAIL $id: pinned ${sha:0:12}, now ${got:0:12}"; bad=1; fi
done < "$d/pins.tsv"
[ "$n" -gt 0 ] || { echo "CANNOT VERIFY: no pins in $d/pins.tsv"; exit 2; }
exit $bad
