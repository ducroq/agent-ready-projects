#!/usr/bin/env bash
# Sensitivity harness for tests/lint/dollar-digit.sh (lint rule 9).
#
# A run against this repo is clean, because rule 9's own landing commit removed
# the last four violations — which is precisely what a dead check looks like.
# Every case below seeds a state the rule claims to catch, or one it must not
# report, and the ablations remove or add one guard at a time.
#
# The rule exists because #77 shipped a bare `$0` inside two awk programs and no
# instrument in this repo could see it: the two copies agreed with each other
# (rule 6 clean), and every fixture ran the extracted program directly, with the
# substitution nowhere on the path. This fixture inherits that blind spot — it
# also cannot substitute anything — so it tests the LEXICAL rule, which is the
# only thing an in-repo check can test.
#
# THE SHAPE MATTERS. All eight real occurrences were `#` comment lines inside a
# fenced ```bash block. A first draft of this fixture used bare lines with no
# fence and no comments, so both exemptions a maintainer would plausibly add —
# skip fenced regions, skip comment lines — passed the whole suite while
# silently un-fixing #77. mktree now builds the real shape, and A6/A7 ablate it.
set -u
cd "$(dirname "$0")"
CHECK="$(cd ../../lint && pwd)/dollar-digit.sh"
[ -f "$CHECK" ] || { echo "cannot find $CHECK" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'chmod -R u+rwX "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT

FAIL=0

# A skill body is discovered by the SAVE AS marker (anywhere under templates/)
# or by living at .claude/skills/**/SKILL.md. mktree builds one of each — with a
# fenced awk program carrying a comment, the shape every real occurrence had —
# plus the two shapes that must stay out of scope.
mktree() {  # mktree <root>
  local r="$1"
  mkdir -p "$r/templates/physics-tests" "$r/.claude/skills/demo" "$r/tests/lint"
  cat > "$r/templates/demo.md" <<'EOF'
# demo
<!-- SAVE AS: .claude/skills/demo/SKILL.md
name: demo
description: a demo skill
-->

```bash
awk '
  # SAFEFORM, never a bare one: arguments are substituted into the body
  { bare = $(0); print bare }
'
```
EOF
  cat > "$r/.claude/skills/demo/SKILL.md" <<'EOF'
---
name: demo
description: a demo skill
---

```bash
awk '
  # SAFEFORM, never a bare one: arguments are substituted into the body
  { bare = $(0); print bare }
'
```
EOF
  # Not a skill: no SAVE AS marker, and LaTeX math is a legitimate `$<digit>`.
  printf 'Over $10^4$ periods the error grows linearly.\n' > "$r/templates/physics-tests/conservation.md"
  # Not a skill: run by bash directly, never delivered through a skill body.
  printf 'awk "{ print \$0 }"\n' > "$r/tests/lint/helper.sh"
}

run_case() {  # run_case <id> <expect: HIT|CLEAN> <needle> <mutator>
  local id="$1" expect="$2" needle="$3" mut="$4"
  local r="$WORK/$id"; mkdir -p "$r"; mktree "$r"; "$mut" "$r"
  local out err rc; err="$WORK/$id.err"
  out="$(bash "$CHECK" "$r" 2>"$err")"; rc=$?
  if [ $rc -gt 1 ]; then
    printf '  FAIL  %s — checker exited %d: %s\n' "$id" "$rc" "$(cat "$err")"; FAIL=1; return
  fi
  # A checker that could not run prints nothing, which is byte-identical to a
  # clean result. The coverage line on stderr is what separates them, and every
  # case asserts it — a negative alone cannot detect a dead harness.
  if ! grep -q 'skill body(ies) scanned' "$err"; then
    printf '  FAIL  %s — no coverage line; the rule did not run\n' "$id"; FAIL=1; return
  fi
  if [ "$expect" = HIT ]; then
    # Needle first, THEN the exit code. The other order mislabels every missed
    # detection as "exited 0, not 1" — measured against a maxdepth-1 mutant,
    # where P12 reported nothing and the failure named the exit code instead of
    # the miss, in exactly the scenario the recursion fix exists for.
    if ! printf '%s' "$out" | grep -qF -- "$needle"; then
      printf '  FAIL  %s — expected a violation matching "%s", got: %s\n' "$id" "$needle" "${out:-<none>}"; FAIL=1; return
    fi
    # The exit code is part of the contract and nothing else asserts it: a
    # checker that printed findings and exited 0 would pass a needle match.
    if [ $rc -ne 1 ]; then
      printf '  FAIL  %s — reported the violation but exited %d, not 1\n' "$id" "$rc"; FAIL=1; return
    fi
    printf '  PASS  %s\n' "$id"
  else
    if [ $rc -ne 0 ]; then
      printf '  FAIL  %s — clean tree but exited %d\n' "$id" "$rc"; FAIL=1; return
    fi
    if [ -z "$out" ]; then printf '  PASS  %s\n' "$id"
    else printf '  FAIL  %s — expected no violation, got: %s\n' "$id" "$out"; FAIL=1; fi
  fi
}

# append <file> <line> — seed a line into a body
app() { printf '%s\n' "$2" >> "$1"; }
# bare <root> — turn mktree's safe comment into the real #77 defect: a bare `$0`
# in a `#` comment inside a fenced block.
bare_comment() { sed -i 's/SAFEFORM/`$0`/' "$1/templates/demo.md"; }

echo "positives — a bare \$N the substituter would eat:"

# THE REAL SHAPE, and the only one all eight master occurrences had.
run_case P1-comment-inside-fence HIT 'bare `$0`' bare_comment

p_awk0()  { app "$1/templates/demo.md" '    awk "{ print $0 }"'; }
run_case P2-awk-whole-line HIT 'bare `$0`' p_awk0

p_arg1()  { app "$1/templates/demo.md" '    sed -n "$1p" file'; }
run_case P3-dollar-one HIT 'bare `$1`' p_arg1

p_arg9()  { app "$1/templates/demo.md" '    echo $9'; }
run_case P4-dollar-nine HIT 'bare `$9`' p_arg9

# Prose is not exempt either — see P1 for why.
p_prose() { app "$1/templates/demo.md" 'Never write a bare `$0` in a skill body.'; }
run_case P5-in-prose HIT 'bare `$0`' p_prose

p_inst()  { app "$1/.claude/skills/demo/SKILL.md" '    awk "{ print $0 }"'; }
run_case P6-reference-install HIT '.claude/skills/demo/SKILL.md' p_inst

# An escaped BACKSLASH followed by a live `$0`. An even run of backslashes does
# not escape the dollar; a rule that merely looks one character back is fooled.
p_dblbs() { app "$1/templates/demo.md" '    gsub(/x/, "\\") ; print \\$0'; }
run_case P7-even-backslash-run HIT 'bare `$0`' p_dblbs

# No preceding character at all — the boundary of the backslash scan.
p_bol()   { app "$1/templates/demo.md" '$0 is the whole line'; }
run_case P8-start-of-line HIT 'bare `$0`' p_bol

# Two digits: `$10` still begins with a `$1` the substituter can claim.
p_two()   { app "$1/templates/demo.md" '    echo $10'; }
run_case P9-two-digit HIT 'bare `$1`' p_two

# One line, two live occurrences — both must be reported, not just the first.
p_twice() { app "$1/templates/demo.md" '    print $1, $2'; }
run_case P10a-two-on-one-line HIT 'bare `$1`' p_twice
run_case P10b-two-on-one-line HIT 'bare `$2`' p_twice

# A named variable on the same line does not launder an adjacent bare one.
p_mixed() { app "$1/templates/demo.md" '    echo "$BASE" "$0BAD" >/dev/null'; }
run_case P11-named-var-nearby HIT 'bare `$0`' p_mixed

# A skill one directory down. A maxdepth-1 glob missed this while the header
# claimed a new skill could not escape by being new.
p_nested_skill() {
  mkdir -p "$1/templates/skills"
  printf '# new\n<!-- SAVE AS: .claude/skills/newskill/SKILL.md\nname: newskill\ndescription: x\n-->\n    awk "{ print $0 }"\n' \
    > "$1/templates/skills/newskill.md"
}
run_case P12-nested-skill-template HIT 'templates/skills/newskill.md' p_nested_skill

echo
echo "negatives — forms the substituter leaves alone, and files out of scope:"

n_paren() { app "$1/templates/demo.md" '    awk "{ print $(0) }"'; }
run_case N1-dollar-paren CLEAN "" n_paren

n_brace() { app "$1/templates/demo.md" '    bash -c "echo ${0}"'; }
run_case N2-dollar-brace CLEAN "" n_brace

n_esc()   { app "$1/templates/demo.md" '    the literal form is \$0 here'; }
run_case N3-escaped CLEAN "" n_esc

# `"$@"` is load-bearing inside curate's verify runner and must never be flagged.
n_at()    { app "$1/templates/demo.md" '    bash -c "$cmd" "$@"'; }
run_case N4-dollar-at CLEAN "" n_at

n_named(){ app "$1/templates/demo.md" '    echo "$BASE/$file" "$_x"'; }
run_case N5-named-vars CLEAN "" n_named

n_bare()  { app "$1/templates/demo.md" '    cost is $ and $$ and $x'; }
run_case N6-dollar-no-digit CLEAN "" n_bare

# Three backslashes: an odd run, so the dollar IS escaped.
n_odd()   { app "$1/templates/demo.md" '    printf "\\\$0"'; }
run_case N7-odd-backslash-run CLEAN "" n_odd

# Out of scope by the SAVE AS predicate, not by depth: LaTeX math in a template
# that is not a skill. Both a top-level one and a nested one.
n_latex() { printf 'Over $10^4$ periods the RK4 error grows as $2^3$.\n' > "$1/templates/physics-notes.md"; }
run_case N8-latex-in-non-skill-template CLEAN "" n_latex

n_nested() { app "$1/templates/physics-tests/conservation.md" 'and $2^3$ again'; }
run_case N9-nested-non-skill CLEAN "" n_nested

n_tests() { app "$1/tests/lint/helper.sh" 'awk "{ print $0 }"'; }
run_case N10-tests-out-of-scope CLEAN "" n_tests

n_notskill() { printf 'awk "{ print $0 }"\n' > "$1/templates/notes.md"; }
run_case N11-template-without-save-as CLEAN "" n_notskill

# The clean control: mktree's own fenced comment uses the safe form.
n_none() { :; }
run_case N12-clean-control CLEAN "" n_none

echo
echo "structural:"

# Zero bodies scanned must refuse loudly. "0 scanned" and "0 violations" are the
# same green, and that exact confusion already cost this repo rule 6 once.
r="$WORK/S1"; mkdir -p "$r/templates" "$r/.claude/skills"
printf 'plain notes\n' > "$r/templates/notes.md"
out="$(bash "$CHECK" "$r" 2>&1)"; rc=$?
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -q 'scanned nothing'; then
  printf '  PASS  S1-no-skill-bodies refuses (exit 2)\n'
else printf '  FAIL  S1-no-skill-bodies — expected exit 2, got %d: %s\n' "$rc" "$out"; FAIL=1; fi

# A missing root must refuse rather than sweep the cwd.
out="$(bash "$CHECK" "$WORK/does-not-exist" 2>&1)"; rc=$?
if [ $rc -eq 2 ]; then printf '  PASS  S2-missing-root refuses (exit 2)\n'
else printf '  FAIL  S2-missing-root — expected exit 2, got %d: %s\n' "$rc" "$out"; FAIL=1; fi

# The reported line must be the line the defect is actually on — asserted
# against grep rather than against a hardcoded number, so mktree can change.
r="$WORK/S3"; mkdir -p "$r"; mktree "$r"; bare_comment "$r"
want=$(grep -n '`\$0`' "$r/templates/demo.md" | head -1 | cut -d: -f1)
got=$(bash "$CHECK" "$r" 2>/dev/null | head -1 | sed 's|^templates/demo\.md:\([0-9]*\):.*|\1|')
if [ -n "$want" ] && [ "$want" = "$got" ]; then
  printf '  PASS  S3-line-number-is-the-real-line (line %s)\n' "$want"
else printf '  FAIL  S3-line-number-is-the-real-line — defect on line %s, reported %s\n' "${want:-?}" "${got:-<none>}"; FAIL=1; fi

# A broken awk must not read as clean. This is the failure the first draft
# shipped: awk ran inside `< <(...)`, whose status is discarded, so a stubbed
# awk produced zero hits, printed the coverage line, and exited 0.
r="$WORK/S4"; mkdir -p "$r/bin"; mktree "$r"; bare_comment "$r"
printf '#!/bin/sh\necho "awk: not found" >&2\nexit 127\n' > "$r/bin/awk"; chmod +x "$r/bin/awk"
out="$(PATH="$r/bin:$PATH" bash "$CHECK" "$r" 2>&1)"; rc=$?
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -q 'did not examine it'; then
  printf '  PASS  S4-broken-awk refuses (exit 2)\n'
else printf '  FAIL  S4-broken-awk — expected exit 2, got %d: %s\n' "$rc" "$out"; FAIL=1; fi

# An unreadable candidate is worse than a missing one: the SAVE AS grep fails on
# it exactly as it fails on a non-skill, so it would be dropped in silence.
r="$WORK/S5"; mkdir -p "$r"; mktree "$r"; chmod 000 "$r/.claude/skills/demo/SKILL.md"
out="$(bash "$CHECK" "$r" 2>&1)"; rc=$?
chmod 644 "$r/.claude/skills/demo/SKILL.md"
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -q 'cannot read'; then
  printf '  PASS  S5-unreadable-body refuses (exit 2)\n'
else printf '  FAIL  S5-unreadable-body — expected exit 2, got %d: %s\n' "$rc" "$out"; FAIL=1; fi

# An unreadable DIRECTORY is worse than an unreadable file: find skips it, warns
# on stderr and exits 1, and a pipeline to sort discards all three. The
# readability loop cannot help — it only sees what find emitted.
r="$WORK/S6"; mkdir -p "$r/templates/locked"; mktree "$r"
printf 'DEFECT $0\n<!-- SAVE AS: .claude/skills/b/SKILL.md -->\n' > "$r/templates/locked/b.md"
chmod 000 "$r/templates/locked"
out="$(bash "$CHECK" "$r" 2>&1)"; rc=$?
chmod 755 "$r/templates/locked"
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -q 'could not fully traverse'; then
  printf '  PASS  S6-unreadable-directory refuses (exit 2)\n'
else printf '  FAIL  S6-unreadable-directory — expected exit 2, got %d: %s\n' "$rc" "$out"; FAIL=1; fi

# find does not descend a symlinked START point without -H, so a symlinked
# .claude/skills dropped the whole reference-install tree at rc 0.
r="$WORK/S7"; mkdir -p "$r/templates" "$r/.claude" "$r/real/d"
printf -- '---\nname: d\n---\n    awk "{ print $0 }"\n' > "$r/real/d/SKILL.md"
ln -s "$r/real" "$r/.claude/skills"
printf 'x\n<!-- SAVE AS: .claude/skills/t/SKILL.md -->\n' > "$r/templates/t.md"
out="$(bash "$CHECK" "$r" 2>&1)"; rc=$?
if [ $rc -eq 1 ] && printf '%s' "$out" | grep -q 'skills/d/SKILL.md'; then
  printf '  PASS  S7-symlinked-skills-dir is descended\n'
else printf '  FAIL  S7-symlinked-skills-dir — expected the install to be scanned, got %d: %s\n' "$rc" "$out"; FAIL=1; fi

echo
echo "the remedy the message prints must be true — measured, not asserted:"
# The checker tells the reader to write `$(N)` in awk, `${N}` in shell and `\$N`
# in prose. A first draft offered all three interchangeably; two of them are a
# syntax error in awk and one of them fails SILENTLY in bash. These cases pin
# the advice to this machine's awk and bash so it cannot rot into wrong advice.
t_ok() { # t_ok <id> <description> <cmd...>
  local id="$1" what="$2"; shift 2
  if "$@" >/dev/null 2>&1; then printf '  PASS  %s — %s\n' "$id" "$what"
  else printf '  FAIL  %s — %s: expected success\n' "$id" "$what"; FAIL=1; fi
}
t_bad() {
  local id="$1" what="$2"; shift 2
  if "$@" >/dev/null 2>&1; then printf '  FAIL  %s — %s: expected failure, it succeeded\n' "$id" "$what"; FAIL=1
  else printf '  PASS  %s — %s\n' "$id" "$what"; fi
}
t_ok  T1-awk-paren    'awk accepts $(0)'            awk 'BEGIN{}{ print $(0) }' /dev/null
t_bad T2-awk-brace    'awk REJECTS ${0}'            awk '{ print ${0} }' /dev/null
t_bad T3-awk-escaped  'awk REJECTS \$0 in code'     awk '{ print \$0 }' /dev/null
t_ok  T4-sh-brace     'shell accepts ${1}'          bash -c 'set -- a; [ "${1}" = a ]'
# The dangerous one: `$(1)` in shell is a command substitution that fails and
# yields the EMPTY STRING at exit 0 — the #41 shape, a wrong remedy that looks
# like it worked.
if [ -z "$(bash -c 'set -- a; printf %s "$(1)"' 2>/dev/null)" ]; then
  printf '  PASS  T5-sh-paren — shell $(1) yields empty, silently\n'
else printf '  FAIL  T5-sh-paren — expected $(1) to yield empty\n'; FAIL=1; fi

echo
echo "ablations — every guard must be load-bearing:"
# "the output changed" is too weak: a mutation that breaks the checker in an
# unrelated way also changes the output. Each ablation names the case it must
# move and the direction, asserts the coverage line reached stderr, and fails if
# the checker merely broke differently. Without that assertion a completely dead
# checker PASSES every CLEAN-direction ablation, because absence satisfies them
# — measured on the first draft, where A1 and A4 passed against a neutered scan
# loop. It is the same lesson tests/lint/README.md records for rule 6.
# CONTROL is the aliveness proof, and it is the whole reason these ablations mean
# anything. The coverage-line assertion alone closes only the CRASH form of a
# dead checker; a checker neutered by SILENCE — one that still lists, reads,
# runs awk, prints its coverage line and exits 0 while reporting nothing —
# satisfies every CLEAN-direction ablation by absence. Measured: mutating a
# single `printf` to `if (0) printf` failed all 13 positives and still PASSED
# six of nine ablations, including all four CLEAN ones. Every ablation tree now
# carries a defect no mutant is allowed to lose, seeded on a plain line outside
# any fence and outside any comment so no ablation can legitimately silence it.
CONTROL_NEEDLE='bare `$7`'
seed_control() { printf '%s\n' '    control probe $7 — every mutant must still report this' >> "$1/templates/demo.md"; }

ablate() {  # ablate <id> <what it defends> <sed-expr> <mutator> <want: HIT|CLEAN> <needle>
  local id="$1" what="$2" expr="$3" mut="$4" want="$5" needle="$6"
  local m="$WORK/$id.sh"
  sed "$expr" "$CHECK" > "$m"
  if cmp -s "$m" "$CHECK"; then
    printf '  FAIL  %s — the ablation changed nothing; it no longer targets the checker (%s)\n' "$id" "$what"
    FAIL=1; return
  fi
  local r="$WORK/$id"; mkdir -p "$r"; mktree "$r"; "$mut" "$r"; seed_control "$r"
  local out rc err="$WORK/$id.err"; out="$(bash "$m" "$r" 2>"$err")"; rc=$?
  if [ $rc -gt 1 ]; then
    printf '  FAIL  %s — mutant exited %d; it broke rather than losing the guard\n' "$id" "$rc"; FAIL=1; return
  fi
  if ! grep -q 'skill body(ies) scanned' "$err"; then
    printf '  FAIL  %s — mutant printed no coverage line; it died rather than losing the guard\n' "$id"; FAIL=1; return
  fi
  if ! printf '%s' "$out" | grep -qF -- "$CONTROL_NEEDLE"; then
    printf '  FAIL  %s — mutant lost the CONTROL defect; it is dead, so this ablation proves nothing\n' "$id"; FAIL=1; return
  fi
  local ok=0
  if [ "$want" = HIT ]; then printf '%s' "$out" | grep -qF -- "$needle" && ok=1
  else printf '%s' "$out" | grep -qF -- "$needle" || ok=1; fi
  if [ $ok -eq 1 ]; then printf '  PASS  %s — %s\n' "$id" "$what"
  else printf '  FAIL  %s — removing %s did not produce its defect; got: %s\n' "$id" "$what" "${out:-<none>}"; FAIL=1; fi
}

# Backslash PARITY, not mere presence: with "any backslash escapes", a live
# `\\$0` goes silent.
ablate A1-escape-parity 'backslash PARITY (\\$0 must still fire)' \
  's|while (j >= 1 \&\& substr(line, j, 1) == "\\\\") { b++; j-- }|if (j >= 1 \&\& substr(line, j, 1) == "\\\\") b = 1|' \
  p_dblbs CLEAN 'bare `$0`'

# The parity test itself: made unsatisfiable, a correctly escaped `\$0` becomes
# a false positive.
ablate A2-escape-honoured 'honouring an escaped \$0' \
  's|if (b % 2 == 1) continue|if (b % 2 == 99) continue|' \
  n_esc HIT 'bare `$0`'

ablate A3-save-as-scope 'scoping templates/ by the SAVE AS marker' \
  "s|grep -q 'SAVE AS:.*\\\\.claude/skills/' \"\$f\" \&\& printf|printf|" \
  n_latex HIT 'physics-notes.md'

ablate A4-install-scope 'scanning the reference installs' \
  "s|find -H .claude/skills -name 'SKILL.md' -type f|find -H .claude/skills -name 'NOPE.md' -type f|" \
  p_inst CLEAN '.claude/skills/demo/SKILL.md'

ablate A5-digit-test 'requiring a DIGIT after the dollar' \
  's|if (d !~ /\^\[0-9\]\$/) continue|if (d == "") continue|' \
  n_named HIT 'bare `$'

# The two exemptions a maintainer would plausibly add. Both would silently
# un-fix #77, because all eight real occurrences were comment lines inside a
# fence. Neither is in the checker — these ablations ADD them, and P1 must stop
# being reported, which is what proves P1 is load-bearing against that change.
ablate A6-no-fence-exemption 'the absence of a fenced-block exemption' \
  's|line = \$(0)|& ; if (line ~ /^[ \t]*```/) { inf = !inf; next } ; if (inf) next|' \
  bare_comment CLEAN 'bare `$0`'

ablate A7-no-comment-exemption 'the absence of a comment-line exemption' \
  's|line = \$(0)|& ; if (line ~ /^[ \t]*#/) next|' \
  bare_comment CLEAN 'bare `$0`'

# A8/A9/A10 cannot go through ablate(): their consequences are "the mutant goes
# green" and "the mutant exits 2", which ablate() rejects by design, and their
# trees are special. They therefore carry their OWN aliveness proof — without
# one they have the same hole ablate() just had, where a silently-dead checker
# satisfies them by absence.

# A8 — awk's exit status. Consequence needs a stubbed awk on PATH.
m="$WORK/A8.sh"; sed '/awk failed on/{n;s|.*|    hits=""|;}' "$CHECK" > "$m"
if cmp -s "$m" "$CHECK"; then
  printf '  FAIL  A8-awk-status — the ablation changed nothing\n'; FAIL=1
else
  # Aliveness first: the SAME mutant, with a working awk, must still find the
  # defect. Otherwise "it went green" proves only that the mutation broke it.
  r="$WORK/A8-alive"; mkdir -p "$r"; mktree "$r"; bare_comment "$r"
  alive="$(bash "$m" "$r" 2>/dev/null)"
  r="$WORK/A8"; mkdir -p "$r/bin"; mktree "$r"; bare_comment "$r"
  printf '#!/bin/sh\necho "awk: not found" >&2\nexit 127\n' > "$r/bin/awk"; chmod +x "$r/bin/awk"
  out="$(PATH="$r/bin:$PATH" bash "$m" "$r" 2>&1)"; rc=$?
  if ! printf '%s' "$alive" | grep -qF -- 'bare `$0`'; then
    printf '  FAIL  A8-awk-status — the mutant finds nothing even with a working awk; it is dead\n'; FAIL=1
  elif [ $rc -eq 0 ] && printf '%s' "$out" | grep -q 'skill body(ies) scanned'; then
    printf '  PASS  A8-awk-status — capturing awk'"'"'s exit status (without it a stubbed awk reads as clean)\n'
  else printf '  FAIL  A8-awk-status — expected the mutant to go green (rc 0 + coverage line), got %d: %s\n' "$rc" "$out"; FAIL=1; fi
fi

# A9 — the readability guard. The unreadable body is a TEMPLATE, so the
# reference install is the aliveness control: a live mutant still reports it.
m="$WORK/A9.sh"; sed '/it may be a skill body and this rule could not tell/d' "$CHECK" > "$m"
if cmp -s "$m" "$CHECK"; then
  printf '  FAIL  A9-readability — the ablation changed nothing\n'; FAIL=1
else
  r="$WORK/A9"; mkdir -p "$r"; mktree "$r"; bare_comment "$r"
  app "$r/.claude/skills/demo/SKILL.md" '    control probe $7 — the install stays readable'
  chmod 000 "$r/templates/demo.md"
  out="$(bash "$m" "$r" 2>&1)"; rc=$?
  chmod 644 "$r/templates/demo.md"
  # The needle is the report's own sentence, not the word "bare": the coverage
  # line reads "scanned for a bare $0-$9" and collides with the obvious choice.
  if ! printf '%s' "$out" | grep -qF -- 'bare `$7`'; then
    printf '  FAIL  A9-readability — mutant lost the CONTROL defect in the install; it is dead\n'; FAIL=1
  elif [ $rc -eq 1 ] && ! printf '%s' "$out" | grep -q 'templates/demo.md:.*in a skill body is delivered'; then
    printf '  PASS  A9-readability — refusing an unreadable candidate (without it the body is dropped in silence)\n'
  else printf '  FAIL  A9-readability — expected the mutant to miss the unreadable template, got %d: %s\n' "$rc" "$out"; FAIL=1; fi
fi

# A10 — find's own exit status and stderr. Round 1 fixed the per-file awk status
# and left this one layer out: an unreadable SUBDIRECTORY makes find skip it,
# warn, and exit 1, all of which a pipeline to sort discards. Same class, one
# layer out, created by the fix for it.
m="$WORK/A10.sh"; sed 's@if \[ "$_frc" -ne 0 \] || \[ -s "$_ferr" \]; then@if false; then@' "$CHECK" > "$m"
if cmp -s "$m" "$CHECK"; then
  printf '  FAIL  A10-find-status — the ablation changed nothing\n'; FAIL=1
else
  r="$WORK/A10"; mkdir -p "$r/templates/locked"; mktree "$r"
  seed_control "$r"                                   # readable, must still be found
  printf 'DEFECT $8 here\n<!-- SAVE AS: .claude/skills/b/SKILL.md -->\n' > "$r/templates/locked/b.md"
  chmod 000 "$r/templates/locked"
  out="$(bash "$m" "$r" 2>/dev/null)"; rc=$?
  chmod 755 "$r/templates/locked"
  if ! printf '%s' "$out" | grep -qF -- "$CONTROL_NEEDLE"; then
    printf '  FAIL  A10-find-status — mutant lost the CONTROL defect; it is dead\n'; FAIL=1
  elif [ $rc -eq 1 ] && ! printf '%s' "$out" | grep -qF -- 'bare `$8`'; then
    printf '  PASS  A10-find-status — refusing when find could not traverse (without it a locked dir is skipped in silence)\n'
  else printf '  FAIL  A10-find-status — expected the mutant to miss the locked dir, got %d: %s\n' "$rc" "$out"; FAIL=1; fi
fi

echo
if [ $FAIL -eq 0 ]; then echo "All dollar-digit fixture cases passed."; else echo "Fixture failures above."; fi
exit $FAIL
