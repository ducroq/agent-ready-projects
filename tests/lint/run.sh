#!/usr/bin/env bash
# Structural lint for agent-ready-projects.
# Catches drift between CLAUDE.md, memory/MEMORY.md, templates, and disk state.
# Run from any directory; the script cd's to repo root.

set -u
cd "$(dirname "$0")/../.."

ISSUES=0
SKIPPED=0
fail() { printf 'FAIL  %s\n' "$1"; ISSUES=$((ISSUES + 1)); }

echo "[1/12] CLAUDE.md path references resolve on disk"
# The two documented maintainer dirs (.claude/, memory/) are gitignored, so their
# CONTENTS are absent from every fresh clone — CI's included. A file reference under
# one of them is exempt only when it is BOTH absent AND still gitignored: a tracked
# file that was deleted still FAILs, a file under any other path still FAILs, and
# `.claude/skills/` is negated in .gitignore so its files are never exempt.
# The exemption is COUNTED AND REPORTED, never silent — an exempted reference is a
# reference nobody checked, and this rule reported four FAILs on every fresh clone
# before the exemption existed, which is part of why it was never in CI (#115).
#
# ⚠️ And the rule gates on its own coverage. The line below reports how much was
# checked; reporting it is not the same as failing on it, and rule 2 one screen
# down refuses exactly that silence. An absent or emptied CLAUDE.md made this rule
# print `0 file reference(s) checked` and exit 0 — visible, ungated, and green.
r1_checked=0; r1_exempt=0; r1_dirs=0; r1_dir_exempt=0
while IFS= read -r path; do
  r1_checked=$((r1_checked + 1))
  [ -e "$path" ] && continue
  case "$path" in
    # ⚠️ memory/ — the whole DIR must be absent, which is the fresh-clone shape and
    # the only state this exemption is for. A per-file test was wrong and was
    # measured wrong: `/memory/` is gitignored wholesale, so EVERY absent memory/
    # reference was exempt on a fully populated checkout too, and the stale pointer
    # `/curate` leaves behind when it renames or archives a topic file — this rule's
    # load-bearing class, still advertised in CLAUDE.md — scanned green. The
    # loosening had quietly traded the local catch for a clean CI run.
    memory/*)
      if [ ! -d memory ] && git check-ignore -q "$path" 2>/dev/null; then
        r1_exempt=$((r1_exempt + 1)); continue
      fi ;;
    # .claude/ cannot use that test: the directory exists in every clone, because
    # .claude/skills/ is tracked. So it stays per-file, and the residual gap is
    # DECLARED rather than hidden — a stale pointer to a renamed .claude/ file is
    # not caught. There are none today (all four exemptions in CI are memory/), and
    # .claude/skills/ is negated in .gitignore, so its files are never exempt.
    .claude/*)
      if git check-ignore -q "$path" 2>/dev/null; then
        r1_exempt=$((r1_exempt + 1)); continue
      fi ;;
  esac
  fail "CLAUDE.md references \`$path\` but it does not exist"
# LC_ALL=C: under the maintainer's en_US.UTF-8, `gotcha-log.md` and `gotcha_log.md`
# collate equal and `sort -u` drops one — so the population, and the count printed
# below as evidence, would differ between this machine and CI. No collision exists
# today (27 references either way); this keeps it that way.
done < <(grep -oE '`[A-Za-z0-9_./-]+\.(md|yml|yaml|json|sh)`' CLAUDE.md | tr -d '`' | LC_ALL=C sort -u)

while IFS= read -r path; do
  # The two documented maintainer dirs (.claude/, memory/) are gitignored and may be
  # legitimately absent from a fresh clone — exempt them when absent AND still gitignored.
  # Scoped to an explicit allowlist, NOT a blanket "any gitignored dir" skip, so a shipped
  # dir mistakenly added to .gitignore and then deleted still FAILs.
  # (A stale ref to an exempted dir under its exact gitignored name is out of scope here.)
  r1_dirs=$((r1_dirs + 1))
  [ -d "$path" ] && continue
  case "$path" in
    # 2>/dev/null for the same reason the file loop has it: outside a git repo this
    # prints `fatal: not a git repository` into the middle of the FAIL list.
    .claude/|memory/) if git check-ignore -q "$path" 2>/dev/null; then
                        r1_dir_exempt=$((r1_dir_exempt + 1)); continue
                      fi ;;
  esac
  fail "CLAUDE.md references directory \`$path\` but it does not exist"
done < <(grep -oE '`[A-Za-z0-9_./-]+/`' CLAUDE.md | tr -d '`' | LC_ALL=C sort -u)
printf '      %s file and %s directory reference(s) checked; %s + %s exempt (absent AND gitignored, under .claude/ or memory/)\n' \
  "$r1_checked" "$r1_dirs" "$r1_exempt" "$r1_dir_exempt"
if [ ! -f CLAUDE.md ]; then
  fail "CLAUDE.md is absent — rule 1 checked nothing"
elif [ "$r1_checked" -eq 0 ] && [ "$r1_dirs" -eq 0 ]; then
  fail "rule 1 extracted 0 references from CLAUDE.md — it checked nothing"
elif [ "$r1_checked" -eq 0 ] && [ "$r1_dirs" -gt 0 ]; then
  # One arm dead while the other works. Rule 2 got this shape and rule 1 did not:
  # breaking the file regex alone printed `0 file and 17 directory` and exited 0.
  fail "rule 1 extracted 0 FILE references while $r1_dirs directory reference(s) were found — the file pattern is matching nothing"
fi

echo "[2/12] memory/MEMORY.md index integrity"
# ⚠️ SKIPPED IS NOT A PASS. memory/ is gitignored maintainer-local state, so on a
# fresh clone this file is absent and the rule can check NOTHING. Before #115 that
# was silent: `grep` wrote "No such file or directory" to stderr, the loop read an
# empty stream, zero failures were recorded, and the run printed "All lint checks
# passed" — an absent index and a clean index producing byte-identical output. That
# is the trap rules 6 and 12 are both built around, live in the rule two lines above
# them. In CI this skip is the EXPECTED state and must stay legible as one.
if [ ! -f memory/MEMORY.md ]; then
  echo "      SKIPPED: memory/MEMORY.md is absent (gitignored maintainer-local) — this rule checked nothing"
  SKIPPED=$((SKIPPED + 1))
else
  # ⚠️ The `memory/` prefix is optional in the pattern because the index writes it:
  # every pointer in it reads `memory/project_x.md`, and the original pattern
  # anchored on a backtick immediately before `project_`, so it matched ZERO of
  # them — this arm had been checking nothing for its whole life. Nothing said so
  # until the coverage line below was added; the rule was green either way, which
  # is #115's own lesson landing on #115's own fix.
  r2_refs=0; r2_files=0
  while IFS= read -r name; do
    r2_refs=$((r2_refs + 1))
    [ -e "memory/$name" ] || fail "memory/MEMORY.md references \`$name\` but it does not exist"
  done < <(grep -oE '`(memory/)?project_[a-z_]+\.md`' memory/MEMORY.md | tr -d '`' | sed 's|^memory/||' | LC_ALL=C sort -u)


  for f in memory/project_*.md; do
    [ -f "$f" ] || continue
    r2_files=$((r2_files + 1))
    name=$(basename "$f")
    grep -qF "$name" memory/MEMORY.md || fail "memory/$name exists but is not referenced in MEMORY.md"
  done
  # Scoped to "topic files exist but none was extracted", which is the pattern-miss
  # above and nothing else. A bare `-eq 0` would fail an index that legitimately
  # has no topic files yet — inventing a defect to avoid a silence is not a trade
  # this rule makes.
  if [ "$r2_refs" -eq 0 ] && [ "$r2_files" -gt 0 ]; then
    fail "rule 2 extracted 0 index references while $r2_files topic file(s) exist — the pattern is matching nothing"
  fi
  printf '      %s index reference(s) and %s topic file(s) checked\n' "$r2_refs" "$r2_files"
fi

echo "[3/12] skill template embedded SKILL.md frontmatter"
for f in templates/*.md; do
  grep -q 'SAVE AS:.*\.claude/skills/' "$f" || continue
  block=$(awk '/<!--/{c=1} c{print} /-->/{c=0}' "$f")
  printf '%s\n' "$block" | grep -qE '^[[:space:]]*name:' \
    || fail "$f: skill template missing \`name:\` in SAVE AS comment"
  printf '%s\n' "$block" | grep -qE '^[[:space:]]*description:' \
    || fail "$f: skill template missing \`description:\` in SAVE AS comment"
done

echo "[4/12] installed skills are loadable"
# Rule 3 checks that each template CARRIES installable frontmatter in its SAVE AS
# comment. It cannot check that an install CONVERTED it. That gap is not theoretical:
# an adopter repo was found holding all three skills copied verbatim, SAVE AS comment
# and all, frontmatter still inside the comment — none had ever registered, silently,
# for months. A skill that does not load fails by doing nothing, so nothing reports it.
# These are the reference installs every adopter copies; if they break, the copies do.
for d in .claude/skills/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d")
  f="${d}SKILL.md"   # $d already ends in /
  if [ ! -f "$f" ]; then
    fail ".claude/skills/$name/ has no SKILL.md — the directory registers nothing"
    continue
  fi
  if [ "$(head -1 "$f" | tr -d '\r')" != '---' ]; then
    fail "$f: no YAML frontmatter — will not register as a skill"
    continue
  fi
  # An unclosed block is not frontmatter: the fields below would be read from the body,
  # so a file that cannot register would pass. Rule 5 makes this check for templates/;
  # .claude/skills/*/SKILL.md is not in its glob, so it is made here.
  if ! head -40 "$f" | tr -d '\r' | awk 'NR>1 && /^---$/{found=1; exit} END{exit !found}'; then
    fail "$f: frontmatter opens but never closes within 40 lines — will not register"
    continue
  fi
  fm_name=$(tr -d '\r' < "$f" | awk 'NR>1 && /^---$/{exit} /^name:/{sub(/^name:[[:space:]]*/,""); sub(/[[:space:]]+$/,""); gsub(/^["'"'"']|["'"'"']$/,""); print; exit}')
  [ -n "$fm_name" ] || fail "$f: frontmatter has no \`name:\`"
  [ "$fm_name" = "$name" ] || fail "$f: frontmatter name \`$fm_name\` does not match directory \`$name\`"
  tr -d '\r' < "$f" | awk 'NR>1 && /^---$/{exit} /^description:[[:space:]]*[^[:space:]]/{found=1} END{exit !found}' \
    || fail "$f: frontmatter has no non-empty \`description:\` — the agent is never told when to use it"
done

echo "[5/12] top-level YAML frontmatter closure"
for f in templates/*.md templates/checklists/*.md memory/*.md; do
  [ -f "$f" ] || continue
  [ "$(head -1 "$f")" = '---' ] || continue
  head -30 "$f" | awk 'NR>1 && /^---$/ {found=1; exit} END {exit !found}' \
    || fail "$f: opens with \`---\` but no closing \`---\` within first 30 lines"
done

echo "[6/12] skill templates and reference installs agree"
# Rules 3 and 4 check each side in isolation; neither compares them. Factored into
# its own script so tests/fixtures/skill-template-sync/ can drive it against seeded
# drift — a run over this repo finds nothing, which is also what a broken check
# looks like.
#
# Hence the two guards below, and they are the point of this block rather than
# defensive garnish. `done < <(cmd)` discards the command's exit status entirely,
# so the first draft of this rule printed "All lint checks passed" and exited 0
# with the checker deleted, renamed, or exiting 3. Empty stdout from a checker
# that never ran is byte-identical to a clean result — the same trap the fixture
# for this rule was hardened against, reintroduced one file away in the path that
# actually gates commits.
sync_out=$(mktemp); sync_err=$(mktemp)
bash tests/lint/skill-sync.sh templates .claude/skills >"$sync_out" 2>"$sync_err"; sync_rc=$?
cat "$sync_err"
sync_pairs=$(sed -n 's/^ *\([0-9]\{1,\}\) template\/install pair(s) compared.*/\1/p' "$sync_err")
if [ $sync_rc -gt 1 ]; then
  fail "rule 6 checker could not run (exit $sync_rc) — this rule checked nothing"
elif [ -z "$sync_pairs" ]; then
  fail "rule 6 checker produced no coverage line — this rule checked nothing"
elif [ "$sync_pairs" -eq 0 ]; then
  # The coverage line alone is not enough: a checker that runs fine against an
  # empty or renamed .claude/skills/ reports "0 pair(s) compared" and exits 0,
  # which is the same green as five clean pairs. Rule 4 does not fire either —
  # its glob simply finds nothing to iterate.
  fail "rule 6 compared 0 template/install pairs — .claude/skills/ is empty or misnamed"
else
  while IFS= read -r line; do
    [ -n "$line" ] && fail "$line"
  done < "$sync_out"
fi
rm -f "$sync_out" "$sync_err"

echo "[7/12] a skill that provisions a canonical row must quote it"
# Factored out for the same reason rule 6 is: the check needs a fixture with
# seeded true positives, and tests/lint/README.md's own "adding a rule" checklist
# says so. The first draft of this rule was inline, had no fixture, and shipped a
# changelog claim ("seeded against three defects") that nobody could re-run.
pq_out=$(mktemp); pq_err=$(mktemp)
bash tests/lint/provision-quote.sh . >"$pq_out" 2>"$pq_err"; pq_rc=$?
cat "$pq_err"
if [ $pq_rc -gt 1 ]; then
  fail "rule 7 checker could not run (exit $pq_rc) — this rule checked nothing"
elif ! grep -q 'provisioning section(s) checked\|no canonical row\|ambiguous' "$pq_err"; then
  fail "rule 7 checker produced no coverage line — this rule checked nothing"
else
  while IFS= read -r line; do
    [ -n "$line" ] && fail "$line"
  done < "$pq_out"
fi
rm -f "$pq_out" "$pq_err"

echo "[8/12] adopter-facing templates have not grown"
# The surface nobody measured. curate.md went 11,358 -> 37,971 bytes across
# eight releases, more than half of it in one session, and the framework had no
# instrument that would have said so. A ratchet rather than a budget: no
# threshold is invented, growth fails, and shrinkage fails until it is locked in.
sz_out=$(mktemp); sz_err=$(mktemp)
bash tests/lint/size-ratchet.sh . >"$sz_out" 2>"$sz_err"; sz_rc=$?
cat "$sz_err"
if [ $sz_rc -gt 1 ]; then
  fail "rule 8 checker could not run (exit $sz_rc) — this rule measured nothing"
elif ! grep -q 'template(s) measured' "$sz_err"; then
  fail "rule 8 checker produced no measurement line — this rule measured nothing"
else
  while IFS= read -r line; do
    [ -n "$line" ] && fail "$line"
  done < "$sz_out"
fi
rm -f "$sz_out" "$sz_err"

# Single-quoted deliberately: in double quotes bash expands the very thing this
# rule forbids. The first draft died on `$9: unbound variable` under set -u —
# and printed NOTHING, because the expansion fails before echo emits anything.
# (`$0` had already expanded to the script path.)
echo '[9/12] no bare $0-$9 in a skill body'
# The one class no runtime check in this repo can reach. Skill ARGUMENTS are
# substituted into the skill BODY between the file and the model, so a bare
# `$0` in an embedded awk program ships as the first argument word: #77, where
# review-changes' Step 1.5 examined nothing and printed what a clean run prints,
# and curate's verify runner EXECUTED mangled commands. Rule 6 could not see it
# (both copies carried the same `$0` and agreed) and no fixture could (all of
# them extract the program and run it directly, with substitution nowhere on the
# path). Lexical is the only instrument available. Fixture at
# tests/fixtures/dollar-digit/.
dd_out=$(mktemp); dd_err=$(mktemp)
bash tests/lint/dollar-digit.sh . >"$dd_out" 2>"$dd_err"; dd_rc=$?
cat "$dd_err"
if [ $dd_rc -gt 1 ]; then
  fail "rule 9 checker could not run (exit $dd_rc) — this rule scanned nothing"
elif ! grep -q 'skill body(ies) scanned' "$dd_err"; then
  fail "rule 9 checker produced no coverage line — this rule scanned nothing"
else
  while IFS= read -r line; do
    [ -n "$line" ] && fail "$line"
  done < "$dd_out"
fi
rm -f "$dd_out" "$dd_err"

echo '[10/12] no ablation that cannot kill anything'
# The narrowest of the three shapes reviews keep re-finding, and the only one
# that is decidable lexically. Two forms: a mutation whose replacement equals its
# target modulo whitespace, and an ablation declaring an empty kill set. Both
# apply cleanly, both report as passing guards, both constrain nothing.
# Scope is a floor, not a ceiling — a mutation that changes something real which
# no assertion measures needs the mutant RUN, not a lexer. Fixture at
# tests/fixtures/vacuous-guard/.
vg_out=$(mktemp); vg_err=$(mktemp)
bash tests/lint/vacuous-guard.sh . >"$vg_out" 2>"$vg_err"; vg_rc=$?
cat "$vg_err"
if [ $vg_rc -gt 1 ]; then
  fail "rule 10 checker could not run (exit $vg_rc) — this rule scanned nothing"
elif ! grep -q 'shell file(s) under tests/ scanned' "$vg_err"; then
  fail "rule 10 checker produced no coverage line — this rule scanned nothing"
else
  while IFS= read -r line; do
    [ -n "$line" ] && fail "$line"
  done < "$vg_out"
fi
rm -f "$vg_out" "$vg_err"

echo '[11/12] no fenced bash block that an adopter copies fails to parse'
# Rule 11 — #105. `templates/review-changes.md`'s Step 1.5 block carried an ASCII
# apostrophe inside a single-quoted awk program; the apostrophe closed it and the
# block was a shell syntax error for eight releases. Nothing here could see it:
# rule 6 compares two copies carrying the SAME apostrophe, so they agree; the
# ratchet counts bytes; and every internal run transcribed the awk into a fresh
# heredoc instead of copying the shipped block, which is exactly why it worked
# for the maintainer and for no adopter. A block that cannot parse by design must
# say so on its first line — the exemption is declared, not guessed, because a
# draft that guessed exempted curate's extractor. Fixture at
# tests/fixtures/block-parses/.
bp_out=$(mktemp); bp_err=$(mktemp)
bash tests/lint/block-parses.sh . >"$bp_out" 2>"$bp_err"; bp_rc=$?
cat "$bp_err"
if [ $bp_rc -gt 1 ]; then
  fail "rule 11 checker could not run (exit $bp_rc) — this rule parsed nothing"
elif ! grep -q 'fenced bash block(s) parsed' "$bp_err"; then
  fail "rule 11 checker produced no coverage line — this rule parsed nothing"
else
  while IFS= read -r line; do
    [ -n "$line" ] && fail "$line"
  done < "$bp_out"
fi
rm -f "$bp_out" "$bp_err"

echo "[12/12] no private project name in a tracked file"
# ⚠️ SKIPPED IS NOT A PASS, and here it is the common case: the name list cannot
# be tracked without publishing exactly what it protects, so it lives outside the
# repo and an absent list means this rule checked NOTHING. That is reported as a
# skip and counted as not-run, never folded into "All lint checks passed" — the
# distinction #33 and rule 6 both exist to preserve.
pn_out=$(mktemp); pn_err=$(mktemp)
bash tests/lint/private-names.sh . >"$pn_out" 2>"$pn_err"; pn_rc=$?
cat "$pn_err"
if [ $pn_rc -eq 2 ]; then
  SKIPPED=$((SKIPPED + 1))
elif [ $pn_rc -gt 2 ]; then
  fail "rule 12 checker could not run (exit $pn_rc) — this rule checked nothing"
elif ! grep -q 'name(s) checked against' "$pn_err"; then
  fail "rule 12 checker produced no coverage line — this rule checked nothing"
else
  while IFS= read -r line; do
    [ -n "$line" ] && fail "$line"
  done < "$pn_out"
fi
rm -f "$pn_out" "$pn_err"

echo
if [ "${SKIPPED:-0}" -gt 0 ]; then
  echo "${SKIPPED} rule(s) SKIPPED — see above. A skipped rule is not a passed rule."
fi
if [ $ISSUES -eq 0 ]; then
  echo "All lint checks passed."
  exit 0
else
  echo "$ISSUES issue(s) found."
  exit 1
fi
