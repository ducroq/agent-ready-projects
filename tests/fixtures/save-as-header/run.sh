#!/usr/bin/env bash
# Sensitivity fixture for lint rule 16 (tests/lint/save-as-header.sh), #184.
#
# The defect fails by DOING NOTHING: a template copied verbatim to a SKILL.md path
# carries its frontmatter inside a comment, so the skill never registers. It took
# three review rounds to stop finding instances, and no existing rule reaches the
# class — rule 3 checks only that the keys exist, rule 6 excludes the SAVE AS
# block by construction, so both copies agree while contradicting five surfaces.
#
# CASE COUNTS ARE COMMANDS, NOT DIGITS:  grep -cE '^(want_)' run.sh · grep -cE '^ablate ' run.sh
#
# READ BEFORE LOOSENING: the scope half (b) is derived from GLOBAL_SKILLS in the
# installer, never from a list here. T3/T4 are what stop someone "simplifying"
# that into a literal list — the drift this rule exists to catch, one file over.
set -u
cd "$(dirname "$0")/../../.." || exit 2
RULE="$PWD/tests/lint/save-as-header.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0

# build <dir> — a scratch repo with one global and one project-local skill template.
build() {
  local d="$1"; mkdir -p "$d/templates" "$d/scripts"
  printf 'GLOBAL_SKILLS="alpha"   # generic method\n' > "$d/scripts/install-global-skills.sh"
  { echo "# Alpha"; echo; echo "<!-- SAVE AS: ~/.claude/skills/alpha/SKILL.md (Claude Code, USER-GLOBAL — do not copy this file verbatim, its frontmatter is inside this comment.)"; echo "     ---"; echo "     name: alpha"; echo "     --- -->"; } > "$d/templates/alpha.md"
  { echo "# Beta"; echo; echo "<!-- SAVE AS: <repo>/.claude/skills/beta/SKILL.md (Claude Code, PROJECT-LOCAL — do not copy this file verbatim, its frontmatter is inside this comment.)"; echo "     ---"; echo "     name: beta"; echo "     --- -->"; } > "$d/templates/beta.md"
}
run() { OUT="$WORK/out"; ERR="$WORK/err"; ( cd "$1" && bash "${2:-$RULE}" . ) >"$OUT" 2>"$ERR"; RC=$?; }
want_fail() { run "$2"; if [ "$RC" -eq 1 ] && grep -q "$3" "$OUT"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_clean(){ run "$2"; if [ "$RC" -eq 0 ] && [ ! -s "$OUT" ] && grep -q 'skill template(s) checked' "$ERR"; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s, %s\n' "$1" "$RC" "$(head -1 "$OUT")"; FAIL=1; fi; }
want_rc()   { run "$2"; if [ "$RC" -eq "$3" ]; then printf '  PASS  %s\n' "$1"; else printf '  FAIL  %s — rc=%s wanted %s\n' "$1" "$RC" "$3"; FAIL=1; fi; }

echo "rule 16 — seeded cases"

build "$WORK/n1"
want_clean "N1 a correct global + a correct project-local template are silent" "$WORK/n1"

# T1 — half (a): the clause that stops the silent copy.
build "$WORK/t1"; sed -i 's/ — do not copy this file verbatim, its frontmatter is inside this comment\.//' "$WORK/t1/templates/alpha.md"
want_fail "T1 a missing do-not-copy-verbatim clause is reported" "$WORK/t1" "do-not-copy-verbatim"

# T2 — half (b), the half nothing else approaches: the header says project-local
# while the installer says the skill ships globally.
build "$WORK/t2"; sed -i 's|~/.claude/skills/alpha/|<repo>/.claude/skills/alpha/|; s/USER-GLOBAL/PROJECT-LOCAL/' "$WORK/t2/templates/alpha.md"
want_fail "T2 a global skill whose header says project-local is reported" "$WORK/t2" "GLOBAL_SKILLS"

# T3 — the reverse, and the more dangerous direction: a project-local skill
# written as a global one installs into the tree that SHADOWS every repo's copy.
build "$WORK/t3"; sed -i 's|<repo>/.claude/skills/beta/|~/.claude/skills/beta/|; s/PROJECT-LOCAL/USER-GLOBAL/' "$WORK/t3/templates/beta.md"
want_fail "T3 a project-local skill written as global is reported" "$WORK/t3" "shadows"

# T4 — the scope authority is the installer. If it cannot be read, the rule must
# refuse rather than fall back to a guess.
build "$WORK/t4"; rm -f "$WORK/t4/scripts/install-global-skills.sh"
want_rc "T4 an absent installer exits 2, never 0" "$WORK/t4" 2

# T5 — and an installer present but unreadable for GLOBAL_SKILLS is the same refusal.
build "$WORK/t5"; printf '# no list here\n' > "$WORK/t5/scripts/install-global-skills.sh"
want_rc "T5 an installer with no GLOBAL_SKILLS exits 2, never 0" "$WORK/t5" 2

# T6 — an empty population is not a clean one.
build "$WORK/t6"; rm -f "$WORK/t6/templates/alpha.md" "$WORK/t6/templates/beta.md"
want_rc "T6 no SAVE AS templates at all exits 2, never 0" "$WORK/t6" 2

# T7 — the floor. Deleting a template's SAVE AS header drops it out of the
# population, and the rule reported one fewer file at rc 0; rule 3 skips it too, so
# a template with no install header at all passed both.
build "$WORK/t7"; sed -i '3d' "$WORK/t7/templates/alpha.md"
want_fail "T7 a global skill whose template lost its SAVE AS header is reported" "$WORK/t7" "GLOBAL_SKILLS but no template"

# T8 — an unreadable template is not a checked one.
build "$WORK/t8"; chmod 000 "$WORK/t8/templates/alpha.md"
if [ -r "$WORK/t8/templates/alpha.md" ]; then echo "  SKIP  T8 — still readable (root?)"; else
  want_fail "T8 an unreadable template is reported, not skipped" "$WORK/t8" "could not be read"; fi
chmod 644 "$WORK/t8/templates/alpha.md" 2>/dev/null

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
  for c in t1 t2 t3 t7; do [ -d "$WORK/$c" ] || continue; run "$WORK/$c" "$mut"; [ "$RC" -eq 0 ] && got="$got,$c"; done
  got="${got#,}"
  if [ "$got" = "$want" ]; then printf '  PASS  ablation %s stops catching exactly [%s]\n' "$label" "$want"
  else printf '  FAIL  ablation %s should stop catching [%s], stopped [%s]\n' "$label" "$want" "$got"; FAIL=1; fi
}
ablate "A1 the do-not-copy clause is not required" '*"do not copy this file verbatim"*) ;;' '*) ;;' "t1"
# A2 makes every skill read as project-local — the scope decision stops consulting
# the derived list at all. Only T2 flips: T3 is the reverse direction and stays
# caught, which is what shows the two directions are checked independently.
# ⚠️ A draft of A2 hardcoded the list instead, and after the T5 floor was added it
# stopped isolating anything: a wrong list now trips the floor as well, so the
# mutant failed for a second reason and the ablation proved nothing. Measured, not
# predicted — that is why this one mutates the decision and not the data.
ablate "A2 the scope decision ignores the derived list" \
  'for g in $GLOBALS; do [ "$g" = "$name" ] && is_global=1; done' \
  'is_global=0' "t2"

# A3 removes the floor. T7 is the case that needs it: a template whose SAVE AS
# header is deleted leaves this rule's population silently, and rule 3 skips it too.
ablate "A3 no floor derived from GLOBAL_SKILLS" \
  'case " $seen " in' 'case " $seen $g " in' "t7"

echo
[ "$FAIL" -eq 0 ] && { echo "save-as-header: all cases behaved."; exit 0; }
echo "save-as-header: regressions above."; exit 1
