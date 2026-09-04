#!/usr/bin/env bash
# Sensitivity fixture for lint rules 1 and 2 (tests/lint/run.sh), under the
# environment CI actually runs in: a checkout with no memory/ and no .claude/
# settings, because both are gitignored maintainer-local state.
#
# WHY THIS EXISTS. Before #115 the two rules behaved like this on a fresh clone:
#
#   rule 1  four FAILs, every one false — CLAUDE.md correctly references
#           memory/MEMORY.md and friends, which are gitignored by design.
#   rule 2  ZERO failures and no output, because `grep memory/MEMORY.md` wrote
#           its error to stderr and the loop read an empty stream. An absent
#           index and a clean index produced byte-identical results.
#
# Rule 1 was fixed by ADDING AN EXEMPTION, which makes the check more permissive,
# and this repo's own constraint says a loosening ships with seeded true positives
# or not at all: "a run that finds nothing cannot distinguish a fixed check from a
# disabled one." T2, T3 and T7 are the failures the exemption must still catch.
#
# The rules under test are EXTRACTED from tests/lint/run.sh, never copied, so this
# fixture cannot drift from the thing it measures (the tests/fixtures/verify-runner
# trick). If the extraction stops matching, this exits 2 rather than reporting a
# pass over an empty program.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)" || exit 2
LINT="$ROOT/tests/lint/run.sh"
[ -f "$LINT" ] || { echo "cannot find $LINT"; exit 2; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
FAIL=0

# --- extraction ------------------------------------------------------------
extract() {
  awk '/^echo "\[1\/[0-9]+\]/{f=1} /^echo "\[3\/[0-9]+\]/{f=0} f' "$LINT"
}
BODY="$W/body.sh"; extract > "$BODY"
lines=$(wc -l < "$BODY")
if [ "$lines" -lt 20 ] || ! grep -q 'check-ignore' "$BODY" || ! grep -q 'MEMORY.md' "$BODY"; then
  echo "EXTRACTION FAILED: rules 1-2 not found in tests/lint/run.sh (got $lines lines)."
  echo "The rule headers are the anchors — if they were renumbered or reworded, fix this fixture."
  exit 2
fi
printf '  PASS  extraction found %s lines of rule 1-2 from tests/lint/run.sh\n' "$lines"

# Wrap the extracted rules in the same scaffolding run.sh gives them.
mkblock() { # $1 = body file, $2 = output program
  { printf 'set -u\nISSUES=0\nSKIPPED=0\n'
    printf 'fail() { printf "FAIL  %%s\\n" "$1"; ISSUES=$((ISSUES + 1)); }\n'
    cat "$1"
    printf 'printf "RESULT issues=%%s skipped=%%s\\n" "$ISSUES" "$SKIPPED"\n'
  } > "$2"
}
PRISTINE="$W/pristine.sh"; mkblock "$BODY" "$PRISTINE"

# --- seeded repos ----------------------------------------------------------
mkrepo() {
  d="$W/repos/$1"; mkdir -p "$d"
  ( cd "$d" && git init -q . && git config user.email f@x && git config user.name f )
  printf '/memory/\n.claude/*\n!.claude/skills/\n' > "$d/.gitignore"
  echo "$d"
}
# A fresh clone: CLAUDE.md references maintainer-local paths, none of them present.
clone_shape() {
  cat > "$1/CLAUDE.md" <<'MD'
See `memory/MEMORY.md` and `memory/gotcha-log.md` and `.claude/settings.json`.
Also `templates/curate.md` and `tests/lint/run.sh`.
MD
  mkdir -p "$1/templates" "$1/tests/lint"
  : > "$1/templates/curate.md"; : > "$1/tests/lint/run.sh"
}

d=$(mkrepo T1); clone_shape "$d"; echo 'Missing: `docs/nowhere.md`' >> "$d/CLAUDE.md"
d=$(mkrepo T2); clone_shape "$d"; echo 'Install: `.claude/skills/curate/SKILL.md`' >> "$d/CLAUDE.md"
# T3 — memory/ is NOT gitignored here, so its absence is a real break, not a
# maintainer-local one. The exemption tests BOTH conditions or this passes.
d=$(mkrepo T3); clone_shape "$d"; printf '.claude/*\n' > "$d/.gitignore"
# T7 — a gitignored path OUTSIDE the two documented maintainer dirs. The
# exemption is allowlisted, not "anything git ignores".
d=$(mkrepo T7); clone_shape "$d"; printf '/memory/\n.claude/*\n!.claude/skills/\ndocs/generated/\n' > "$d/.gitignore"
echo 'Built: `docs/generated/out.md`' >> "$d/CLAUDE.md"
# T4/T5 — the maintainer's shape: memory/ present, so rule 2 must RUN.
d=$(mkrepo T4); clone_shape "$d"; mkdir -p "$d/memory"
printf 'index\n- `project_gone.md`\n' > "$d/memory/MEMORY.md"
d=$(mkrepo T5); clone_shape "$d"; mkdir -p "$d/memory"
printf 'index with no pointers\n' > "$d/memory/MEMORY.md"; : > "$d/memory/project_orphan.md"
# T6 — the directory arm of rule 1, untouched by #115 and asserted anyway.
d=$(mkrepo T6); clone_shape "$d"; echo 'Dir: `docs/nope/`' >> "$d/CLAUDE.md"
# N1 — the CI shape itself: clean, with rule 2 reporting a SKIP.
d=$(mkrepo N1); clone_shape "$d"
# N2 — the maintainer shape: memory/ present and consistent.
d=$(mkrepo N2); clone_shape "$d"; mkdir -p "$d/memory"
printf 'index\n- `project_real.md`\n' > "$d/memory/MEMORY.md"; : > "$d/memory/project_real.md"
# N3 — .claude/skills/ IS tracked (negated in .gitignore); present, so silent.
d=$(mkrepo N3); clone_shape "$d"; mkdir -p "$d/.claude/skills/curate"
echo 'Install: `.claude/skills/curate/SKILL.md`' >> "$d/CLAUDE.md"
: > "$d/.claude/skills/curate/SKILL.md"

run_case() { ( cd "$W/repos/$1" && bash "$2" 2>&1 ); }

# --- expectations ----------------------------------------------------------
# Each case names what a positive looks like, so a silent run cannot read as a pass.
expect() { # $1 case, $2 output
  local c="$1" o="$2" i s
  i=$(sed -n 's/^RESULT issues=\([0-9]*\) skipped=.*/\1/p' <<<"$o")
  s=$(sed -n 's/^RESULT issues=[0-9]* skipped=\([0-9]*\)/\1/p' <<<"$o")
  [ -n "$i" ] || return 1
  case "$c" in
    T1) grep -q 'docs/nowhere.md' <<<"$o" ;;
    T2) grep -q '.claude/skills/curate/SKILL.md' <<<"$o" ;;
    T3) grep -q 'memory/MEMORY.md' <<<"$o" && [ "$i" -ge 1 ] ;;
    T7) grep -q 'docs/generated/out.md' <<<"$o" ;;
    T4) grep -q 'project_gone.md' <<<"$o" ;;
    T5) grep -q 'project_orphan.md' <<<"$o" ;;
    T6) grep -q 'docs/nope/' <<<"$o" ;;
    N1) [ "$i" -eq 0 ] && [ "$s" -eq 1 ] && grep -q 'SKIPPED' <<<"$o" \
        && grep -qE '[0-9]+ file reference\(s\) checked; [0-9]+ exempt' <<<"$o" ;;
    N2) [ "$i" -eq 0 ] && [ "$s" -eq 0 ] \
        && grep -qE '1 index reference\(s\) and 1 topic file\(s\) checked' <<<"$o" ;;
    N3) [ "$i" -eq 0 ] ;;
  esac
}
CASES="T1 T2 T3 T7 T4 T5 T6 N1 N2 N3"
declare -A WHY=(
  [T1]="an absent non-maintainer file is still a FAIL"
  [T2]=".claude/skills/ is tracked, so its files are never exempt"
  [T3]="absent is not enough — the path must also be gitignored"
  [T7]="the exemption is allowlisted to memory/ and .claude/, not to anything git ignores"
  [T4]="rule 2 still catches a dangling index pointer where it can run"
  [T5]="rule 2 still catches an orphan topic file"
  [T6]="the directory arm still fires"
  [N1]="the CI shape is clean AND reports rule 2 as skipped, not passed"
  [N2]="the maintainer shape is clean and prints its coverage"
  [N3]="a present tracked install is silent"
)
for c in $CASES; do
  out=$(run_case "$c" "$PRISTINE")
  if expect "$c" "$out"; then printf '  PASS  %-3s %s\n' "$c" "${WHY[$c]}"
  else printf '  FAIL  %-3s %s\n      got: %s\n' "$c" "${WHY[$c]}" "$(tr '\n' '|' <<<"$out")"; FAIL=1; fi
done

# --- ablations: each mutant must break a NAMED, NON-EMPTY set of cases ------
# Rule 10 forbids an ablation that cannot kill anything; the kill sets below are
# asserted exactly, so a mutation that stops mattering shows up as a FAIL here
# rather than as a guard nobody notices is inert.
ablate() { # $1 label, $2 sed program, $3... kill set
  local label="$1" prog="$2"; shift 2
  local mut="$W/mut.sh" body="$W/mutbody.sh"
  sed "$prog" "$BODY" > "$body"
  if cmp -s "$body" "$BODY"; then
    printf '  FAIL  ablation %s changed nothing — it cannot kill anything\n' "$label"; FAIL=1; return
  fi
  mkblock "$body" "$mut"
  local killed=() survived=()
  for c in $CASES; do
    out=$(run_case "$c" "$mut")
    if expect "$c" "$out"; then survived+=("$c"); else killed+=("$c"); fi
  done
  local want; want=$(printf '%s\n' "$@" | sort | tr '\n' ' ')
  local got; got=$(printf '%s\n' "${killed[@]:-}" | sort | sed '/^$/d' | tr '\n' ' ')
  if [ "$want" = "$got" ]; then printf '  PASS  ablation %s fails exactly [%s]\n' "$label" "${want% }"
  else printf '  FAIL  ablation %s: expected to kill [%s], killed [%s]\n' "$label" "${want% }" "${got% }"; FAIL=1; fi
}

# A1 — exempt on prefix alone, dropping the gitignore test. It kills T2 as well as
# T3: .claude/skills/ matches the .claude/* prefix and is saved ONLY by check-ignore
# reading .gitignore's negation, which is not obvious from the rule's text.
ablate A1 's|if git check-ignore -q "$path" 2>/dev/null; then|if true; then|' T2 T3
# A2 — exempt anything gitignored, dropping the maintainer-dir allowlist.
ablate A2 's|    memory/\*\|\.claude/\*)|    *)|' T7
# A3 — skip rule 2 without counting it: the run then prints no SKIPPED summary.
ablate A3 's|  SKIPPED=$((SKIPPED + 1))|  :|' N1
# A4 — the pre-#115 rule 2: the guard never fires, so an absent index runs the
# loops anyway. Written as a dead condition rather than by deleting the block,
# because deleting it leaves a dangling `fi` and every case dies of a syntax
# error — a mutant that kills everything measures nothing.
ablate A4 's|if \[ ! -f memory/MEMORY.md \]; then|if false; then|' N1
# A5 — drop rule 1's coverage line, so exempted references become invisible.
ablate A5 "/file reference(s) checked/,+1d" N1
# A6 — drop rule 2's coverage line.
ablate A6 "/index reference(s) and/d" N2

echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || echo "SENSITIVITY REGRESSION — do not ship."
exit "$FAIL"
