#!/usr/bin/env bash
# Lint rule 8 — the adopter-facing surfaces may not grow silently.
#
# Two costs, charged differently, and only one of them was ever measured:
#   - ALWAYS-LOADED: the project file and memory index, paid every session.
#     `curate` sub-step 8 already budgets the project file.
#   - PER-INVOCATION: skill bodies, paid every time the skill runs. `/curate` is
#     meant to run every session, so its body is effectively a per-session cost.
#     Nothing measured this, and between v1.15.0 and v1.23.0 `templates/curate.md`
#     grew 11,358 -> 37,971 bytes (+234%), more than half of it in one session,
#     unremarked until someone asked.
#
# This is a RATCHET, not a budget. No threshold is invented — Step 4 already has
# the scar from a calibrated cut-off that turned out to suppress 100% of its
# input. The baseline is simply "what it was", growth fails, and shrinkage fails
# until it is locked in, so the recorded number can only ever go down.
#
# Usage: size-ratchet.sh <repo-root> [--update]
# Exit:  0 clean · 1 violations on stdout · 2 could not run
set -u
root="${1:-}"; mode="${2:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: size-ratchet.sh <repo-root> [--update]" >&2; exit 2; }

BASELINE="$root/tests/lint/size-baseline.tsv"

# The tracked set is every adopter-facing template, discovered rather than
# listed: a new template must be added to the baseline deliberately, so nothing
# escapes the ratchet by being new.
tracked() { find "$root/templates" -maxdepth 1 -name '*.md' -type f | sed "s|^$root/||" | sort; }

if [ "$mode" = "--update" ]; then
  { echo "# Lint rule 8 baseline — bytes per adopter-facing template."
    echo "# Regenerate with: bash tests/lint/size-ratchet.sh . --update"
    echo "# Growth fails. Shrinkage fails until locked in here, so this file only goes down."
    while IFS= read -r rel; do printf '%s\t%s\n' "$rel" "$(wc -c < "$root/$rel")"; done < <(tracked)
  } > "$BASELINE"
  echo "baseline updated: $(grep -vc '^#' "$BASELINE") file(s), $(awk -F'\t' '!/^#/{s+=$2} END{print s+0}' "$BASELINE") bytes total"
  exit 0
fi

[ -f "$BASELINE" ] || { echo "cannot read $BASELINE — the ratchet has no baseline to compare against" >&2; exit 2; }

issues=0; checked=0; total_now=0; total_base=0
declare -A base=()
while IFS=$'\t' read -r rel bytes; do
  case "$rel" in ''|'#'*) continue ;; esac
  base["$rel"]="$bytes"
done < "$BASELINE"

while IFS= read -r rel; do
  now=$(wc -c < "$root/$rel")
  total_now=$((total_now + now))
  if [ -z "${base[$rel]:-}" ]; then
    echo "$rel is not in the size baseline — a new adopter-facing template must be added deliberately (--update), or it grows unmeasured"
    issues=$((issues + 1)); continue
  fi
  was="${base[$rel]}"; total_base=$((total_base + was)); checked=$((checked + 1))
  if [ "$now" -gt "$was" ]; then
    echo "$rel grew ${was} -> ${now} bytes (+$((now - was))). Adopters pay this: an always-loaded file every session, a skill body every invocation. Shrink something, or record why in CHANGELOG.md and run --update"
    issues=$((issues + 1))
  elif [ "$now" -lt "$was" ]; then
    echo "$rel shrank ${was} -> ${now} bytes (-$((was - now))) — lock it in with: bash tests/lint/size-ratchet.sh . --update"
    issues=$((issues + 1))
  fi
done < <(tracked)

for rel in "${!base[@]}"; do
  [ -f "$root/$rel" ] || { echo "$rel is in the size baseline but no longer exists — remove it with --update if that was deliberate"; issues=$((issues + 1)); }
done

# Silence from a checker that did not run is indistinguishable from a clean
# result, which is the failure this repo keeps re-learning. Always say the size.
echo "      $checked template(s) measured; $total_now bytes total, baseline $total_base" >&2
[ "$issues" -eq 0 ] || exit 1
exit 0
