#!/usr/bin/env bash
# Structural lint for agent-ready-projects.
# Catches drift between CLAUDE.md, memory/MEMORY.md, templates, and disk state.
# Run from any directory; the script cd's to repo root.

set -u
cd "$(dirname "$0")/../.."

ISSUES=0
fail() { printf 'FAIL  %s\n' "$1"; ISSUES=$((ISSUES + 1)); }

echo "[1/11] CLAUDE.md path references resolve on disk"
while IFS= read -r path; do
  [ -e "$path" ] || fail "CLAUDE.md references \`$path\` but it does not exist"
done < <(grep -oE '`[A-Za-z0-9_./-]+\.(md|yml|yaml|json|sh)`' CLAUDE.md | tr -d '`' | sort -u)

while IFS= read -r path; do
  # The two documented maintainer dirs (.claude/, memory/) are gitignored and may be
  # legitimately absent from a fresh clone — exempt them when absent AND still gitignored.
  # Scoped to an explicit allowlist, NOT a blanket "any gitignored dir" skip, so a shipped
  # dir mistakenly added to .gitignore and then deleted still FAILs.
  # (A stale ref to an exempted dir under its exact gitignored name is out of scope here.)
  [ -d "$path" ] && continue
  case "$path" in
    .claude/|memory/) git check-ignore -q "$path" && continue ;;
  esac
  fail "CLAUDE.md references directory \`$path\` but it does not exist"
done < <(grep -oE '`[A-Za-z0-9_./-]+/`' CLAUDE.md | tr -d '`' | sort -u)

echo "[2/11] memory/MEMORY.md index integrity"
while IFS= read -r name; do
  [ -e "memory/$name" ] || fail "memory/MEMORY.md references \`$name\` but it does not exist"
done < <(grep -oE '`project_[a-z_]+\.md`' memory/MEMORY.md | tr -d '`' | sort -u)

for f in memory/project_*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  grep -qF "$name" memory/MEMORY.md || fail "memory/$name exists but is not referenced in MEMORY.md"
done

echo "[3/11] skill template embedded SKILL.md frontmatter"
for f in templates/*.md; do
  grep -q 'SAVE AS:.*\.claude/skills/' "$f" || continue
  block=$(awk '/<!--/{c=1} c{print} /-->/{c=0}' "$f")
  printf '%s\n' "$block" | grep -qE '^[[:space:]]*name:' \
    || fail "$f: skill template missing \`name:\` in SAVE AS comment"
  printf '%s\n' "$block" | grep -qE '^[[:space:]]*description:' \
    || fail "$f: skill template missing \`description:\` in SAVE AS comment"
done

echo "[4/11] installed skills are loadable"
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

echo "[5/11] top-level YAML frontmatter closure"
for f in templates/*.md templates/checklists/*.md templates/physics-tests/*.md memory/*.md; do
  [ -f "$f" ] || continue
  [ "$(head -1 "$f")" = '---' ] || continue
  head -30 "$f" | awk 'NR>1 && /^---$/ {found=1; exit} END {exit !found}' \
    || fail "$f: opens with \`---\` but no closing \`---\` within first 30 lines"
done

echo "[6/11] skill templates and reference installs agree"
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

echo "[7/11] a skill that provisions a canonical row must quote it"
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

echo "[8/11] adopter-facing templates have not grown"
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
echo '[9/11] no bare $0-$9 in a skill body'
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

echo '[10/11] no ablation that cannot kill anything'
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

echo '[11/11] no fenced bash block that an adopter copies fails to parse'
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

echo
if [ $ISSUES -eq 0 ]; then
  echo "All lint checks passed."
  exit 0
else
  echo "$ISSUES issue(s) found."
  exit 1
fi
