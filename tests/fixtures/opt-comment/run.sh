#!/usr/bin/env bash
# Sensitivity fixture for lint rule 17 (tests/lint/opt-comment.sh).
#
# The rule is a four-line grep replacing the most expensive instrument there is:
# `set -u#` was found by a review lens reading a diff, with five other instruments
# green — the runners exited 0, `bash -n` passed, lint was 13/13, the fixture
# runner swallowed the stderr, and the author's "all PASS" was true.
#
# CASE COUNTS ARE COMMANDS, NOT DIGITS:  grep -cE '^(want_)' run.sh · grep -cE '^ablate ' run.sh
#
# READ BEFORE LOOSENING: N1 is the reason the predicate demands NO whitespace. A
# correct `set -u  # why` is the commonest line in this repo's shell; a rule that
# flags it would be turned off within a day.
set -u
cd "$(dirname "$0")/../../.." || exit 2
RULE="$PWD/tests/lint/opt-comment.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

run() { OUT="$WORK/out"; ERR="$WORK/err"; ( cd "$1" && bash "${2:-$RULE}" . ) >"$OUT" 2>"$ERR"; RC=$?; }
want_fail() { run "$2"; if [ "$RC" -eq 1 ] && grep -q "$3" "$OUT"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s\n' "$1" "$RC"; FAIL=1; fi; }
want_clean(){ run "$2"; if [ "$RC" -eq 0 ] && [ ! -s "$OUT" ] && grep -q 'file(s) found' "$ERR"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_rc()   { run "$2"; if [ "$RC" -eq "$3" ]; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s wanted %s\n' "$1" "$RC" "$3"; FAIL=1; fi; }

echo "rule 17 — seeded cases"

# N1 — the control AND the loosening bound: every correct form must stay silent,
# including the one-space form, which is what makes the defect hard to see.
mkdir -p "$WORK/n1"
{ echo 'set -u  # nounset, deliberately'; echo 'set -eo pipefail'; echo 'set -u'; echo '  set -e # indented, spaced'; } > "$WORK/n1/ok.sh"
want_clean "N1 correctly spaced options are silent" "$WORK/n1"

# N2 — LEGAL CONTENT the second draft flagged. Every line here is correct, and
# four of the five come from real idioms: a trailing command, `set --`, a vim
# option line in a fenced block, and a colour in prose.
mkdir -p "$WORK/n2"
{ echo 'set -x; echo "issue#123"'; echo 'set -- "$@" "#tag"'; } > "$WORK/n2/ok.sh"
{ echo '# Notes'; echo; echo '```vim'; echo 'set statusline=%#WarningMsg#'; echo '```'; echo; echo '  set accent=#ff0000 in the theme file'; } > "$WORK/n2/notes.md"
want_clean "N2 legal set-lines the loose draft flagged are silent" "$WORK/n2"

# N3 — a DECLARED exemption. A fixture seeding this very defect is not the defect;
# ten of this repo's runners seed heredocs, so without this the rule fires on the
# next seeded case.
mkdir -p "$WORK/n3"
printf 'set -u# demo   # lint-skip: opt-comment\n' > "$WORK/n3/seed.sh"
want_clean "N3 a declared exemption is not reported" "$WORK/n3"

# T1 — the live shape, in shell.
mkdir -p "$WORK/t1"; printf 'set -u# nounset for safety\n' > "$WORK/t1/bad.sh"
want_fail "T1 \`set -u#\` in a .sh is reported" "$WORK/t1" "NEVER APPLIED"

# T2 — the same shape inside markdown an adopter copies. bash -n never sees it.
mkdir -p "$WORK/t2"; printf '# Skill\n\n```bash\nset -eo pipefail# be strict\n```\n' > "$WORK/t2/skill.md"
want_fail "T2 the shape inside fenced bash is reported" "$WORK/t2" "NEVER APPLIED"

# T3 — bash -n is NOT the instrument. If it were, this rule would be redundant;
# the row that proposed it says so and this case is the measurement.
mkdir -p "$WORK/t3"; printf 'set -u# nounset\necho hi\n' > "$WORK/t3/bad.sh"
if bash -n "$WORK/t3/bad.sh" 2>/dev/null; then
  want_fail "T3 the case bash -n PASSES on is still reported" "$WORK/t3" "NEVER APPLIED"
else
  echo "  FAIL  T3 setup: bash -n now rejects this, so the rule's whole premise needs re-measuring"; FAIL=1
fi

# T9 — and the exemption is bounded: a marker on a line with NO defect is STALE.
# Without this, a declaration outlives what it declared and licenses whatever is
# written on that line next — the unused-suppression property the prior art has
# and the first draft of this rule did not.
mkdir -p "$WORK/t9"; printf 'echo hello   # lint-skip: opt-comment\n' > "$WORK/t9/stale.sh"
want_fail "T9 a marker on a line with no defect is reported STALE" "$WORK/t9" "STALE EXEMPTION"

# T10 — THE INTERLOCK. A marker in markdown is not policed for staleness, so it
# must not be honoured either. Before the fix it was honoured everywhere: a stale
# marker in a fenced block went unreported AND suppressed the real defect that
# landed on its line — in `templates/*.md`, the surface adopters copy.
mkdir -p "$WORK/t10"; printf '# Doc\n\n```bash\nset -eo pipefail# guard   # lint-skip: opt-comment\n```\n' > "$WORK/t10/doc.md"
want_fail "T10 a marker in markdown does not suppress a real defect" "$WORK/t10" "NEVER APPLIED"

# T4 — an empty population is not a clean one.
mkdir -p "$WORK/t4"
want_rc "T4 no files at all exits 2, never 0" "$WORK/t4" 2

# ── Ablations ─────────────────────────────────────────────────────────────────
ablate() {
  [ -n "${ABL_PRE+x}" ] || ABL_PRE=$FAIL; if [ "$ABL_PRE" -ne 0 ]; then printf '  UNSCORED  ablation %s — a seeded case already failed in this run, so it cannot fail (#161)\n' "$1"; return 0; fi
  local label="$1" old="$2" new="$3" want="$4" got="" mut="$WORK/mutant.sh"
  OLD="$old" NEW="$new" python3 -c '
import os, sys, pathlib
s = pathlib.Path(sys.argv[1]).read_text()
old, new = os.environ["OLD"], os.environ["NEW"]
if old not in s: sys.exit("ABLATION ANCHOR MISSING: %r" % old)
pathlib.Path(sys.argv[2]).write_text(s.replace(old, new, 1))
' "$RULE" "$mut" || { printf '  FAIL  ablation %s could not be applied\n' "$label"; FAIL=1; return; }
  for c in t1 t2 t3 t9 t10; do [ -d "$WORK/$c" ] || continue; run "$WORK/$c" "$mut"; [ "$RC" -eq 0 ] && got="$got,$c"; done
  got="${got#,}"
  if [ "$got" = "$want" ]; then printf '  PASS  ablation %s stops catching exactly [%s]\n' "$label" "$want"
  else printf '  FAIL  ablation %s should stop catching [%s], stopped [%s]\n' "$label" "$want" "$got"; FAIL=1; fi
}
# A1 restores the FIRST DRAFT predicate, keyed on the flag run. Kill set is T2 and
# T10 — both use the `set -eo pipefail#` shape the first draft misses, T10 inside
# markdown. Re-measured when T10 was added rather than carried forward: the set
# widened, and a `want` carried forward would have gone green on a stale claim.
# It must stop catching exactly T2 — the `set -eo pipefail#` shape where the `#` welds to the
# option NAME. That is the ablation the header argues for; a `set`->`setZZZ`
# mutant would only prove the grep exists, which T1-T3 already prove.
ablate "A1 the first-draft predicate (keyed on the flag run)" \
  "grep -nE '^[[:space:]]*set([[:space:]]+[-+]?[A-Za-z]+)+#' \"\$f\"" \
  "grep -nE '^[[:space:]]*set([[:space:]]+-[a-zA-Z]+)#' \"\$f\"" "t2,t10"

# A3 removes the stale-marker scan. Only T9 flips.
ablate "A3 no unused-suppression detection" 'done < <(stale_scan "$f")' 'done < <(: )' "t9"

# A4 — honour the marker everywhere while policing only shell, which is the state
# the interlock blocker describes. T10 flips: the markdown marker suppresses again.
ablate "A4 honour the marker where it is not policed" 'if policed "$f"; then' 'if true; then' "t10"
# A2 restores the SECOND draft — "any non-space before a `#` on a set line" — the
# loosening that looks more general and flagged five legal lines. It must break N2,
# the legal-content control, which is not in the ablation set above.
mut2="$WORK/m2.sh"; sed 's/set(\[\[:space:\]\]+\[-+\]?\[A-Za-z\]+)+#/set[[:space:]][^#]*[^[:space:]#]#/' "$RULE" > "$mut2"
run "$WORK/n2" "$mut2"
if [ "$RC" -eq 1 ]; then printf '  PASS  ablation A2 the loose predicate breaks N2, which is why this one is constrained\n'
else printf '  FAIL  ablation A2 did not break N2 — the tightness is untested\n'; FAIL=1; fi

echo
[ "$FAIL" -eq 0 ] && { echo "opt-comment: all cases behaved."; exit 0; }
echo "opt-comment: regressions above."; exit 1
