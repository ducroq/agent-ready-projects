#!/usr/bin/env bash
# Lint rule 8 — the adopter-facing surface has a BUDGET, and it only ratchets down.
#
# Two costs, charged differently:
#   - ALWAYS-LOADED: the project file and memory index, paid every session.
#   - PER-INVOCATION: skill bodies, paid every time the skill runs. `/curate` is
#     meant to run every session, so its body is effectively a per-session cost.
#
# ⚠️ THIS WAS A RATCHET AND THE RATCHET NEVER HELD. Measured over its whole life:
# `templates/curate.md`'s recorded size moved **up 21 times and down 0 times**.
# Every growth was legal — the rule said "shrink something, or record why in
# CHANGELOG.md and run --update", and recording why is free, so the second branch
# was taken every single time, by every author including the one who wrote the
# rule. `templates/` went 113,639 bytes at v1.10.0 to 311,924 at v1.36.1: 2.75x,
# and almost perfectly linear at ~40KB per five releases. A rule whose escape
# hatch costs a paragraph is a logging mechanism wearing a budget's clothes.
#
# So the unit is now the TOTAL, not the file:
#   - Growth in one file is FREE if another file shrinks to pay for it. That is
#     the trade the old rule pretended to ask for and never enforced.
#   - Exceeding the budget FAILS, and `--update` CANNOT raise it. Raising takes
#     `--raise-budget "<reason>"`, which is a separate, loud, recorded act.
#   - Falling below the budget fails until locked in, so the ceiling follows the
#     surface down and can never drift back up.
#
# ⚠️ AND THE OLD SET MISSED 59KB. `tracked()` globbed `templates/*.md` at depth
# one, so `templates/physics-tests/` — 59,124 bytes, 19% of the surface — was
# never measured by the rule whose entire job is measuring the surface. The set
# is now recursive: everything under `templates/` that an adopter copies.
#
# Usage: size-ratchet.sh <repo-root> [--update | --raise-budget "<reason>"]
# Exit:  0 clean · 1 violations on stdout · 2 could not run / refused
set -u
root="${1:-}"; mode="${2:-}"; reason="${3:-}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: size-ratchet.sh <repo-root> [--update | --raise-budget \"<reason>\"]" >&2; exit 2; }

BASELINE="$root/tests/lint/size-baseline.tsv"

# Discovered, not listed: a new template must be added to the baseline
# deliberately, so nothing escapes the budget by being new — and nothing escapes
# it by living one directory down, which is how 59KB stayed invisible.
tracked() { find "$root/templates" -name '*.md' -type f | sed "s|^$root/||" | sort; }

measure_total() { local t=0 n; while IFS= read -r rel; do n=$(wc -c < "$root/$rel"); t=$((t + n)); done < <(tracked); echo "$t"; }

read_budget() { sed -n 's/^# BUDGET[[:space:]]\{1,\}\([0-9]\{1,\}\).*/\1/p' "$BASELINE" | head -1; }

write_baseline() { # write_baseline <budget> <note>
  { echo "# Lint rule 8 baseline — bytes per adopter-facing template, and the TOTAL budget."
    echo "# Regenerate rows with: bash tests/lint/size-ratchet.sh . --update"
    echo "# The budget only goes DOWN. Growth in one file must be paid for by a shrink in"
    echo "# another. Raising it takes --raise-budget \"<reason>\" and is recorded below."
    echo "# BUDGET $1"
    [ -n "${2:-}" ] && echo "# $2"
    while IFS= read -r rel; do printf '%s\t%s\n' "$rel" "$(wc -c < "$root/$rel")"; done < <(tracked)
  } > "$BASELINE"
}

now_total=$(measure_total)

if [ "$mode" = "--update" ]; then
  [ -f "$BASELINE" ] || { write_baseline "$now_total" "seeded $(date +%Y-%m-%d)"; echo "baseline seeded at $now_total bytes"; exit 0; }
  budget=$(read_budget)
  if [ -n "$budget" ] && [ "$now_total" -gt "$budget" ]; then
    echo "REFUSED: --update cannot raise the budget ($budget -> $now_total, +$((now_total - budget)))." >&2
    echo "Pay for the growth with a shrink elsewhere, or raise it deliberately:" >&2
    echo "    bash tests/lint/size-ratchet.sh . --raise-budget \"why this surface must get bigger\"" >&2
    exit 2
  fi
  # At or under budget: the rows refresh and the ceiling follows the surface down.
  write_baseline "$now_total" "ratcheted down $(date +%Y-%m-%d)"
  echo "baseline updated: $(grep -vc '^#' "$BASELINE") file(s), budget now $now_total bytes"
  exit 0
fi

if [ "$mode" = "--raise-budget" ]; then
  [ -n "$reason" ] || { echo "REFUSED: --raise-budget needs a reason argument. The reason is the whole point." >&2; exit 2; }
  old=$(read_budget)
  write_baseline "$now_total" "RAISED $(date +%Y-%m-%d) from ${old:-none} to $now_total: $reason"
  echo "budget RAISED ${old:-none} -> $now_total (+$((now_total - ${old:-0}))): $reason"
  exit 0
fi

[ -f "$BASELINE" ] || { echo "cannot read $BASELINE — the budget has no baseline to compare against" >&2; exit 2; }
budget=$(read_budget)
[ -n "$budget" ] || { echo "$BASELINE carries no '# BUDGET <bytes>' line — this rule cannot bind and checked nothing" >&2; exit 2; }

issues=0; checked=0; grew=0; shrank=0
declare -A base=()
while IFS=$'\t' read -r rel bytes; do
  case "$rel" in ''|'#'*) continue ;; esac
  base["$rel"]="$bytes"
done < "$BASELINE"

# Per-file movement is REPORTED, not failed: paying for growth with a shrink is
# the behaviour this rule wants, and failing each half of that trade is what
# taught everyone to reach for --update.
while IFS= read -r rel; do
  now=$(wc -c < "$root/$rel"); checked=$((checked + 1))
  if [ -z "${base[$rel]:-}" ]; then
    echo "$rel is not in the size baseline — a new adopter-facing template must be added deliberately (--update), or it grows unmeasured"
    issues=$((issues + 1)); continue
  fi
  was="${base[$rel]}"
  if [ "$now" -gt "$was" ]; then
    grew=$((grew + 1)); echo "      $rel grew ${was} -> ${now} (+$((now - was)))" >&2
  elif [ "$now" -lt "$was" ]; then
    shrank=$((shrank + 1)); echo "      $rel shrank ${was} -> ${now} (-$((was - now)))" >&2
  fi
done < <(tracked)

for rel in "${!base[@]}"; do
  [ -f "$root/$rel" ] || { echo "$rel is in the size baseline but no longer exists — remove it with --update if that was deliberate"; issues=$((issues + 1)); }
done

if [ "$now_total" -gt "$budget" ]; then
  echo "adopter-facing surface is OVER BUDGET: $now_total bytes against $budget (+$((now_total - budget))). Adopters pay this — an always-loaded file every session, a skill body every invocation. Shrink something to pay for it, or raise the budget deliberately with --raise-budget \"<reason>\""
  issues=$((issues + 1))
elif [ "$now_total" -lt "$budget" ]; then
  echo "adopter-facing surface is UNDER budget by $((budget - now_total)) bytes — lock the reduction in so it cannot drift back: bash tests/lint/size-ratchet.sh . --update"
  issues=$((issues + 1))
fi

# Silence from a checker that did not run is indistinguishable from a clean
# result, which is the failure this repo keeps re-learning. Always say the size.
echo "      $checked template(s) measured; $now_total bytes total against a budget of $budget ($grew grew, $shrank shrank)" >&2
[ "$issues" -eq 0 ] || exit 1
exit 0
