#!/usr/bin/env bash
# Run every sensitivity fixture under tests/fixtures/ and report one summary.
#
# CLAUDE.md's "How to Work Here" listed thirteen `bash tests/fixtures/*/run.sh`
# invocations by hand, which is a list that goes stale and a choice the runner
# makes about which of them to bother with. This enumerates the directory instead,
# so a fixture added tomorrow is run tonight without anyone remembering it.
#
# THREE THINGS IT REFUSES TO DO SILENTLY (#115):
#   1. Report a pass over an empty population — no fixture directories is exit 2.
#   2. Skip a directory it cannot run. A fixture without run.sh is a FAILURE
#      unless it is DECLARED below, the same "declared, not guessed" rule lint
#      rule 11 uses for unparseable blocks.
#   3. Stop at the first failure. Every suite runs; one red fixture must not hide
#      the state of the other twelve.
#
# It does NOT stop on the first failure and it does NOT parallelise: the whole
# set is ~2.5 min wall clock, dominated by verify-runner (~110s), and the
# ordering keeps the log readable.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

# Declared non-gates. A directory listed here is expected to have no run.sh.
# review-bench SCORES a review configuration against seeded defects; it has no
# pass/fail by design, and CLAUDE.md says so. Wiring it in as a gate would turn a
# measurement into a threshold nobody chose.
NOT_A_GATE=" review-bench "

total=0; ran=0; failed=0; declared=0
FAILED_NAMES=""
printf '%-26s %6s %5s  %s\n' "FIXTURE" "RESULT" "SECS" "LAST LINE"
printf -- '---------------------------------------------------------------------------\n'
for d in tests/fixtures/*/; do
  [ -d "$d" ] || continue
  n=$(basename "$d")
  total=$((total + 1))
  if [ ! -f "$d/run.sh" ]; then
    case "$NOT_A_GATE" in
      *" $n "*) declared=$((declared + 1))
                printf '%-26s %6s %5s  %s\n' "$n" "n/a" "-" "declared not a gate — scores, does not assert" ;;
      *) failed=$((failed + 1)); FAILED_NAMES="$FAILED_NAMES $n"
         printf '%-26s %6s %5s  %s\n' "$n" "FAIL" "-" "no run.sh and not declared in NOT_A_GATE" ;;
    esac
    continue
  fi
  s=$SECONDS
  out=$(bash "$d/run.sh" 2>&1); rc=$?
  el=$((SECONDS - s)); ran=$((ran + 1))
  last=$(printf '%s' "$out" | grep -v '^[[:space:]]*$' | tail -1)
  if [ "$rc" -eq 0 ] && [ -z "$last" ]; then
    # A suite that exits 0 having printed nothing asserted nothing — the same
    # silence rule 12 refuses. Verified: a zero-byte run.sh otherwise reports `ok`.
    failed=$((failed + 1)); FAILED_NAMES="$FAILED_NAMES $n"
    printf '%-26s %6s %5s  %s\n' "$n" "FAIL" "$el" "exited 0 with no output — it asserted nothing"
  elif [ "$rc" -eq 0 ]; then
    printf '%-26s %6s %5s  %s\n' "$n" "ok" "$el" "$last"
  else
    failed=$((failed + 1)); FAILED_NAMES="$FAILED_NAMES $n"
    printf '%-26s %6s %5s  %s\n' "$n" "FAIL" "$el" "$last"
    printf '%s\n' "$out" | sed 's/^/    | /'
  fi
done

echo
if [ "$total" -eq 0 ]; then
  echo "NO FIXTURE DIRECTORIES FOUND under tests/fixtures/ — this run measured nothing."
  exit 2
fi
echo "$ran of $total fixture suite(s) executed; $declared declared not-a-gate; $failed failed."
if [ "$failed" -ne 0 ]; then
  echo "FAILED:$FAILED_NAMES"
  exit 1
fi
echo "All fixture suites passed."
