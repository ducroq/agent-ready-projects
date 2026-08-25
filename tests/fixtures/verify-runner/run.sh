#!/usr/bin/env bash
# Sensitivity harness for the canonical verify runner shipped in
# templates/curate.md, Step 0 sub-step 5 (issue #34).
#
# The runner's failure mode is silence: it reports nothing wrong having checked
# nothing, which is byte-for-byte what a clean pass looks like. A run that finds
# no problems is therefore not evidence — and neither is a run against this
# repo, whose two real annotations exercise none of the defects below. Every
# case here seeds a claim the runner must classify a particular way, or prose it
# must refuse to execute; the ablations at the end remove one guard at a time
# and require its own specific defect to appear.
#
# The runner under test is EXTRACTED FROM THE TEMPLATE rather than copied here.
# The shipped text is the only source, so this harness cannot drift from what
# adopters actually run — the drift trap that cost this repo lint rule 6.
set -u
cd "$(dirname "$0")"
ROOT="$(cd ../../.. && pwd)"
TEMPLATE="$ROOT/templates/curate.md"
[ -f "$TEMPLATE" ] || { echo "cannot find $TEMPLATE" >&2; exit 2; }

# Deliberately LONG, and that is the point (#80). The MALFORMED row prints
# `substr(rest, 1, 60)` of the annotation body, so any assertion that greps that
# text for a marker sitting at the END of an absolute $CANARY path passes on a
# short $TMPDIR and fails on a long one. m01 did exactly that: PASS on /tmp,
# FAIL on a ~100-char scratch path, on master and on every open branch. Making
# the hostile length permanent turns an environment accident into a fixed test
# condition, so the class cannot come back unnoticed on somebody else's machine.
# macOS's default TMPDIR (/var/folders/<2>/<~30>/T/) is ~49 chars and was the
# motivating unmeasured case; this makes every run at least that hostile.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/verify-runner-deliberately-long-path-for-truncation-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
CANARY="$WORK/canary"
mkdir -p "$CANARY"

# ---- extract the runner from the shipped template ---------------------------
# The block is a four-backtick fence (its own body contains three-backtick
# lines) carrying the sentinel below. Exactly one must exist: two would mean a
# reader cannot tell which one is canonical, none means the fixture is testing
# a runner that is no longer shipped.
extract_runner() {
  awk '
    /^[ \t]*````/ {
      if (inblk) { if (keep) { printf "%s", buf; found++ } ; inblk = 0 }
      else { inblk = 1; buf = ""; keep = 0; match($0, /^[ \t]*/); ind = RLENGTH }
      next
    }
    inblk {
      l = $0
      for (i = 0; i < ind; i++) sub(/^[ \t]/, "", l)
      buf = buf l "\n"
      if (index($0, "verify runner (canonical)")) keep = 1
    }
    END {
      if (found != 1) {
        printf "expected exactly 1 canonical runner block, found %d\n", found > "/dev/stderr"
        exit 3
      }
    }
  ' "$1"
}

RUNNER="$WORK/runner.sh"
if ! extract_runner "$TEMPLATE" > "$RUNNER"; then
  echo "  FAIL  could not extract the canonical runner from templates/curate.md" >&2
  exit 1
fi
[ -s "$RUNNER" ] || { echo "  FAIL  extracted runner is empty" >&2; exit 1; }

# ---- the seeded memory tree -------------------------------------------------
# Three files, and the order they are passed in matters: a-unclosed.md leads
# with an unterminated fence, because fence state that leaks across files
# silently blanks every later file — the whole run then reconciles as prose.
seed() {
  local d="$1"
  mkdir -p "$d"
  cat > "$d/a-unclosed.md" <<EOF
# A file whose fence is never closed

A gotcha entry that pasted a traceback and forgot the closing fence:

\`\`\`
Traceback (most recent call last):
  <!-- verify: touch "$CANARY/n02" -->
EOF
  cat > "$d/claims.md" <<EOF
# Seeded claims

- Plain passing claim. <!-- verify: echo p01-evidence=42 -->
- Guarded claim, host unreachable, guard exits 2. <!-- verify: echo "CANNOT VERIFY: p03 host down"; exit 2 -->
- Claim whose command ends in an explicit exit. <!-- verify: echo p04-ok; exit 0 -->
- Claim checked over ssh, i.e. a command that reads stdin. <!-- verify: cat; echo p05-drained -->
- Claim whose command succeeds in silence. <!-- verify: true # p06 -->
- Claim that is no longer true. <!-- verify: echo p07-mismatch; exit 1 -->
- Claim whose tool disappeared mid-command. <!-- verify: echo p08-partial; p08-no-such-command -->
- Claim that cannot be automated. <!-- verify: manual — p09 needs prod credentials -->
- Claim that cannot be automated, capitalised. <!-- verify: Manual — p19 also needs them -->
- Claim whose command redirects. <!-- verify: test -f "$WORK/p10-target" >/dev/null && echo p10-redirected -->
- Claim whose command carries a long flag. <!-- verify: echo p11-longflag --with-a-long-flag -->
- Rows split on the \`|\` separator, so prose here holds a pipe in a code span. <!-- verify: awk 'BEGIN { if ("b" ~ /^b\|/) { print "p27-bad"; exit 1 } else print "p27-ok" }' -->
- Claim outside a table whose command escapes a pipe for awk, not for GFM. <!-- verify: awk 'BEGIN { if ("a" ~ /^a\|/) { print "p13-bad"; exit 1 } else print "p13-ok" }' -->
- Claim whose command greps for an HTML comment marker. <!-- verify: grep -q '<!-- p32-generated' /etc/hostname && echo p32-gen || { echo p32-nogen; exit 0; } -->
- Claim whose command substitutes a backtick. <!-- verify: [ "\`printf p14\`" = p14 ] && echo p14-subst-ok -->
- Guarded claim whose guard warns on stderr first. <!-- verify: { echo "warn: p15 added host to known hosts" >&2; echo "CANNOT VERIFY: p15 host offline"; } -->
- Claim whose command forks a child that outlives it. <!-- verify: (sleep 5 &); echo p17-forked -->
- Claim written the way this framework taught until v1.21.0. <!-- verify: false && echo p20-ok || echo FAIL -->
- Claim whose real check is named like a note. <!-- verify: manual-p21() { echo p21-ok; }; manual-p21 -->
- Claim annotated with the older capitalisation. <!-- VERIFY: echo p22-caps-ok -->
- Claim whose evidence is indented. <!-- verify: printf '   CANNOT VERIFY: p26 indented reason\n' -->
- Two claims on one line. <!-- verify: echo p24-first --> and <!-- verify: echo p25-second -->
- Guard written without the conventional colon. <!-- verify: echo "CANNOT VERIFY - p30 has no colon" -->
- Claim whose evidence happens to start with the word FAIL. <!-- verify: echo "FAIL: 0  WARN: 0  OK: 12  p31" -->
- Outer bullet.
  - Inner bullet whose example is an indented fence:

    \`\`\`
    <!-- verify: touch "$CANARY/n10" -->
    \`\`\`

- An empty annotation, m04. <!-- verify: -->
- An annotation that opens twice. <!-- verify: echo m02-one and then <!-- verify: echo m02-two -->
- A stray \` m03 backtick in prose, then a command. <!-- verify: echo \`printf alive\`-now -->

A line mentioning the \`a | b\` operator, followed by a rule rather than a table:
---
- Outside any table, so its pipe escape belongs to awk. <!-- verify: awk 'BEGIN { if ("c" ~ /^c\|/) { print "p29-bad"; exit 1 } else print "p29-ok" }' -->

## Prose that merely mentions the syntax

An extractor that stops at the first \`>\` yields \`[^>]*\` fragments — see the note
on \`<!-- verify: touch $CANARY/n05 -->\` — and the sed form
\`sed 's/^<!-- verify: touch $CANARY/n06 *//; s/ *-->\$//'\` is prose about prose.
A code span such as \`<!-- verify: touch $CANARY/n01 -->\` documents the syntax, and
so does a double-backtick one, which is how you write a span holding a backtick:
\`\` <!-- verify: touch "$CANARY/n11" --> \`\`

Some entries carry no annotation at all and only say verify: in running text,
which is a mention (n03) and not a command.

An annotation that was never closed, <!-- verify: : m01; touch "$CANARY/m01"
runs off the end of the line: MALFORMED, not silently skipped.

~~~
A tilde-fenced example block, which is a fenced block too:
<!-- verify: touch "$CANARY/n07" -->
~~~

\`\`\`\`markdown
A four-backtick block quoting a three-backtick one, which is what this repo's own
skill files look like:
\`\`\`
<!-- verify: touch "$CANARY/n08" -->
\`\`\`
\`\`\`\`

\`\`\`
A three-backtick block quoting a tilde fence:
~~~
<!-- verify: touch "$CANARY/n09" -->
~~~
\`\`\`
EOF
  cat > "$d/table.md" <<EOF
# Seeded claims in tables

| Item | Status |
|------|--------|
| Recovery branch reachable | done <!-- verify: false \\|\\| echo p02-recovered --> |
| Backup appliance | live <!-- verify: test -e /nonexistent-p12 \\|\\| echo "CANNOT VERIFY: p12 appliance offline" --> |

A pipe-less table, which GFM renders exactly the same way:

Item | Status
-----|-------
Mirror | synced <!-- verify: false \\|\\| echo p16-recovered -->
synced <!-- verify: false \\|\\| echo p28-firstcell --> | Mirror
- A bullet straight after the last row, with no blank line between. <!-- verify: awk 'BEGIN { if ("e" ~ /^e\|/) { print "p33-bad"; exit 1 } else print "p33-ok" }' -->

Prose mentioning the \`a | b\` operator, then a rule, then a line that has a pipe:
---
Notes | more notes. <!-- verify: awk 'BEGIN { if ("d" ~ /^d\|/) { print "p34-bad"; exit 1 } else print "p34-ok" }' -->
EOF
  : > "$WORK/p10-target"
}

SEED="$WORK/memory"
seed "$SEED"
FILES="$SEED/a-unclosed.md $SEED/claims.md $SEED/table.md"

run_runner() {  # run_runner <runner-path> <output-file>; returns the runner's exit status
  # VERIFY_TIMEOUT exists so the 30-second cap can be exercised in a second rather
  # than being the one shipped disposition no case ever reaches.
  # shellcheck disable=SC2086
  VERIFY_TIMEOUT=1 bash "$1" $FILES > "$2" 2>&1
}

FAIL=0
run_runner "$RUNNER" "$WORK/base.out"; BASE_RC=$?
OUT="$(cat "$WORK/base.out")"

row_is() {  # row_is <marker> <expected-disposition>
  local marker="$1" want="$2" line got
  line="$(printf '%s\n' "$OUT" | grep -F -- " :: " | grep -F -- "$marker" | head -n1)"
  if [ -z "$line" ]; then
    printf '  FAIL  %s — no row: the command was never extracted\n' "$marker"; FAIL=1; return
  fi
  got="${line%% *}"
  if [ "$got" = "$want" ]; then printf '  PASS  %-4s %s\n' "$marker" "$want"
  else printf '  FAIL  %s — expected %s, got %s (%s)\n' "$marker" "$want" "$got" "$line"; FAIL=1; fi
}

echo "positives — each must be extracted and classified:"
row_is p01 PASS           # plain command printing evidence
row_is p02 PASS           # table cell: `\|` must be un-escaped before running
row_is p03 CANNOT-VERIFY  # prefix wins over a non-zero exit
row_is p04 PASS           # `exit` inside a command must not end the run
row_is p05 PASS           # a stdin-reading command must not eat the command list
row_is p06 ERROR          # silent success proves nothing
row_is p07 FAIL           # non-zero with output
row_is p08 ERROR          # 127 after partial output — not FAIL
row_is p09 MANUAL         # never executed
row_is p10 PASS           # `>` redirect must survive extraction
row_is p11 PASS           # long flag must survive extraction
row_is p12 CANNOT-VERIFY  # table cell whose fallback branch is the passing one
row_is p17 PASS           # a forked child must not hold the runner open
row_is p19 MANUAL         # `Manual` is the older capitalisation, still never run
# p13 is the regression from the hostile-repo run against agent-ready-papers: a
# passing `awk -F'|' '/^\| P[0-9]+ \|/…'` row-count check, outside any table,
# that a blanket un-escape turned into an alternation with an empty operand and
# reported FAIL. Un-escaping is a GFM concern and belongs only to table rows.
row_is p13 PASS
# p14 and p15 are the two silent false PASSes the review battery found. p14: a
# backtick command substitution is ordinary shell, and stripping code spans out
# of the line gutted the command into `[ "" = p14 ]` — a check that checks
# nothing, reported as verified. p15: stderr merged into stdout arrives first
# and masks the CANNOT VERIFY prefix, so an `ssh` guard's "Warning: Permanently
# added …" turns an unreachable host into a PASS.
row_is p14 PASS
row_is p15 CANNOT-VERIFY
# p16 and p28: GFM makes the leading pipe optional, so a table detected by `^\|`
# alone misses a legal table and leaves the dead-fallback-branch defect live. p28
# puts the annotation in the FIRST cell, where no pipe precedes it at all.
row_is p16 PASS
row_is p28 PASS
# p27 is the converse, and the reason table detection cannot be "the line has a
# pipe in it": a bullet whose prose mentions a pipe is not a table row, and
# un-escaping there breaks the command exactly as it broke agent-ready-papers'.
row_is p27 PASS
# Everything below was added by the second review battery.
row_is p20 FAIL           # `&& echo OK || echo FAIL` — what this framework taught until v1.21.0
row_is p21 PASS           # a real check named `manual-…` must run, not be filed as a note
row_is p22 PASS           # `<!-- VERIFY:` is the older capitalisation
row_is p24 PASS           # two annotations on one line: the first
row_is p25 PASS           # ...and the second
row_is p26 CANNOT-VERIFY  # the prefix must survive leading whitespace
row_is p29 PASS           # `---` under a pipe-bearing line is a rule, not a table delimiter
row_is p30 CANNOT-VERIFY  # the colon is conventional; the older spec had none
row_is p31 PASS           # evidence beginning "FAIL:" is evidence, not a legacy verdict
row_is p32 PASS           # a command that greps for `<!--` is a command, not a second opener
row_is p33 PASS           # a table ends at its last row, not at the next blank line
row_is p34 PASS           # `---` with no pipe is a rule, even when the next line has one

echo
echo "malformed — a broken annotation must be loud, never silently dropped:"
# The marker must appear EARLY in the annotation body, because the MALFORMED row
# carries only substr(rest, 1, 60) — see the $WORK comment above. m01 leads with
# `: m01;`, a no-op that still executes the touch if the command is ever wrongly
# run, so the "it was executed" guard below keeps its teeth.
malformed_is() {  # malformed_is <marker> <why>
  if printf '%s\n' "$OUT" | grep '^MALFORMED' | grep -qF -- "$1"; then printf '  PASS  %-4s %s\n' "$1" "$2"
  else printf '  FAIL  %s — not reported MALFORMED (%s)\n' "$1" "$2"; FAIL=1; fi
  if [ -e "$CANARY/$1" ]; then printf '  FAIL  %s — it was executed\n' "$1"; FAIL=1; fi
}
malformed_is m01 "never closed"
# u01: a fence that opens and never closes swallows every claim after it in that
# file. Round 1 fixed the leak *across* files; within one file the claims simply
# vanished, with no row and nothing in the malformed count.
if printf '%s\n' "$OUT" | grep '^MALFORMED' | grep -q 'never closed'; then printf '  PASS  u01  an unterminated fence is reported\n'
else printf '  FAIL  u01 — an unterminated fence swallowed the rest of its file silently\n'; FAIL=1; fi
# m02: a second `<!-- verify:` on the line supplies a `-->` to the first, so the
# opener looked closed and ran as one nonsense command reported ERROR.
malformed_is m02 "opens twice on one line"
# m03: one stray backtick in prose makes the mask span from it into the command,
# blanking the annotation itself. Round 1 traded a silent drop for a silent drop;
# an annotation swallowed by an unbalanced span is now reported, not lost.
malformed_is m03 "unbalanced backticks on the line"
# m04: an empty annotation used to be dropped with no row at all — the silent
# skip this whole design forbids, in the runner's own extractor.
malformed_is m04 "empty"

echo
echo "negatives — prose the runner must refuse to execute:"
for n in n01 n02 n03 n05 n06 n07 n08 n09 n10 n11; do
  if [ -e "$CANARY/$n" ]; then
    printf '  FAIL  %s — prose was executed as shell\n' "$n"; FAIL=1
  elif printf '%s\n' "$OUT" | grep -F -- " :: " | grep -qF -- "$n"; then
    printf '  FAIL  %s — prose was extracted as a command\n' "$n"; FAIL=1
  else
    printf '  PASS  %s not executed\n' "$n"
  fi
done

echo
echo "the report must carry the evidence, not just a verdict:"
if printf '%s\n' "$OUT" | grep -q 'p01-evidence=42'; then printf '  PASS  stdout of a passing command is shown\n'
else printf '  FAIL  the command output is captured and then discarded\n'; FAIL=1; fi
if printf '%s\n' "$OUT" | grep -q 'command not found'; then printf '  PASS  stderr of a failing command is shown\n'
else printf '  FAIL  stderr is captured and then discarded\n'; FAIL=1; fi
if printf '%s\n' "$OUT" | grep -q 'output begins FAIL yet it exited 0'; then printf '  PASS  a FAIL-prefixed evidence line is warned about, not rescored\n'
else printf '  FAIL  a command whose output begins FAIL but exits 0 passes with no warning\n'; FAIL=1; fi
if printf '%s\n' "$OUT" | grep -q 'legacy verdict word'; then printf '  PASS  the legacy idiom is named, not silently rescored\n'
else printf '  FAIL  a legacy `|| echo FAIL` command is rescored with no explanation\n'; FAIL=1; fi

echo
echo "reconciliation and exit status:"
# Asserting both numbers is the point: an extractor that silently yields fewer
# commands still prints a summary line, and that line is the only place the
# shortfall becomes visible. The denominator counts `<!--`-shaped annotations,
# not every occurrence of the word — a bare mention in prose is not a candidate,
# and `CANNOT VERIFY:` in a command is not one either.
if printf '%s\n' "$OUT" | grep -q 'ran 30 of 46 annotations'; then
  printf '  PASS  ran 30 of 46\n'
else
  printf '  FAIL  expected "ran 30 of 46", got: %s\n' \
    "$(printf '%s\n' "$OUT" | grep ' annotations —' || echo '<no summary line — the run died mid-loop>')"
  FAIL=1
fi
# The seed contains failures, so a runner that carries its disposition only in
# words nothing parses would exit 0 here — which is the defect the step's own
# writing rule forbids in the commands it runs.
if [ "$BASE_RC" -eq 1 ]; then printf '  PASS  exit 1 with failures present\n'
else printf '  FAIL  expected exit 1 with failures present, got %d\n' "$BASE_RC"; FAIL=1; fi

structural() {  # structural <id> <expected-rc> <description> <args...>
  local id="$1" want="$2" what="$3"; shift 3
  local got
  VERIFY_TIMEOUT=1 timeout 10 bash "$RUNNER" "$@" >/dev/null 2>&1; got=$?
  if [ "$got" -eq 124 ]; then
    printf '  FAIL  %s — the runner hung (%s)\n' "$id" "$what"; FAIL=1
  elif [ "$got" -eq "$want" ]; then printf '  PASS  %s — %s\n' "$id" "$what"
  else printf '  FAIL  %s — expected exit %d, got %d (%s)\n' "$id" "$want" "$got" "$what"; FAIL=1; fi
}
printf 'x\n' > "$WORK/clean.md"
printf 'A claim. <!-- verify: echo clean-ok -->\n' >> "$WORK/clean.md"
structural S1-no-arguments   2 "no file arguments must refuse, not read stdin"
structural S2-missing-file   2 "an unreadable operand must refuse, not skip silently" "$SEED/claims.md" "$WORK/nosuch.md"
structural S3-nothing-found  2 "a file with no annotations must refuse" "$WORK/p10-target"
structural S4-all-clear      0 "a clean file must exit 0" "$WORK/clean.md"
printf 'A claim. <!-- verify: manual — needs prod creds -->\n' > "$WORK/manualonly.md"
printf 'A claim. <!-- verify: echo "CANNOT VERIFY: appliance offline" -->\n' > "$WORK/cvonly.md"
structural S5-manual-only    2 "a run where nothing executed is not all-clear" "$WORK/manualonly.md"
structural S6-cannot-only    2 "a run where nothing was reachable is not all-clear" "$WORK/cvonly.md"

# ---- micro cases ------------------------------------------------------------
# Three behaviours are timing- or file-handle-dependent. Seeding them in the main
# tree would cost several seconds on each of the ablation runs, so they get
# their own two-line inputs — and their own mutants, so each is still ablated.
echo
echo "timing and file-handle cases:"
micro_expect() {  # micro_expect <id> <what> <runner> <file> <timeout> <needle>
  local id="$1" what="$2" r="$3" f="$4" to="$5" needle="$6" o
  o=$(VERIFY_TIMEOUT="$to" bash "$r" "$f" 2>&1)
  case "$o" in
    *"$needle"*) printf '  PASS  %s — %s\n' "$id" "$what" ;;
    *) printf '  FAIL  %s — %s; expected %s in:\n%s\n' "$id" "$what" "$needle" "$o"; FAIL=1 ;;
  esac
}
printf 'A slow claim. <!-- verify: sleep 4; echo M1-late -->\n' > "$WORK/m1.md"
micro_expect M1 "a hanging command is capped" "$RUNNER" "$WORK/m1.md" 1 "(timed out)"
sed 's|command -v timeout|command -v not-a-real-timeout|' "$RUNNER" > "$WORK/m1a.sh"
micro_expect M1a "without the cap it runs to completion instead" "$WORK/m1a.sh" "$WORK/m1.md" 1 "M1-late"

# A backgrounded child keeps the previous command's stdout open. With one shared
# temp file it writes into the NEXT command's output at offset 0, and a real FAIL
# is reported un-checkable. p17 makes forking commands explicitly supported, so
# this is not an exotic input.
{ printf 'Forks a child. <!-- verify: (sleep 1; echo "CANNOT VERIFY: M2 stray") & true -->\n'
  printf 'A genuinely failing claim. <!-- verify: echo M2-mismatch; sleep 2; exit 1 -->\n'; } > "$WORK/m2.md"
micro_expect M2 "a fresh output file per command" "$RUNNER" "$WORK/m2.md" 9 "FAIL"
sed 's|OUTF="\$TMPD/\$n.out"; ERRF="\$TMPD/\$n.err"|OUTF="\$TMPD/s.out"; ERRF="\$TMPD/s.err"|' "$RUNNER" > "$WORK/m2a.sh"
micro_expect M2a "sharing one file lets a child poison the next verdict" "$WORK/m2a.sh" "$WORK/m2.md" 9 "CANNOT-VERIFY"

structural M3-directory      2 "a directory operand must refuse, not be read as a file" "$WORK"

# ---- CRLF (#58) -------------------------------------------------------------
# isdelim() strips spaces and tabs but not \r, so on a CRLF checkout intbl is
# never set, the table-cell pipe un-escape never runs, and an escaped-pipe
# command is still extracted, counted and EXECUTED — mangled. Corruption, not
# silence, which is what makes it worse than #52 in review-changes.
#
# The assertion is EQUIVALENCE, not a needle: a CRLF file must produce the same
# OUTPUT as its LF twin — dispositions and the echoed command string both, which
# is stronger than dispositions alone and catches a left-over `\|` even where the
# verdict happens to match. A needle per row would pass for a file that was never
# examined; identical output cannot.
#
# ⚠️ The reconciliation line reads "ran 3 of 3" under BOTH line endings, so the
# runner's headline guarantee — the denominator assertion — is blind to this
# class BY CONSTRUCTION. Extraction never depended on intbl. Recorded here so
# nobody reads that assertion as covering it.
echo
echo "CRLF (#58) — same dispositions as LF, or the un-escape never ran:"
# Row 2 needs its own file, and the fixture makes it rather than reaching for one
# on the host. `/etc/hostname` was absent on macOS; `false \| cat` was worse — it
# writes NOTHING, so the runner's no-output rule scored it ERROR on both sides and
# the row stopped distinguishing anything on the platform it was measured on.
# `grep -c nomatch FILE \| cat` un-escapes to a pipeline whose tail exits 0 with
# stdout "0" (PASS); mangled, grep is handed `\|` and `cat` as extra FILENAMES,
# exits 2, and prints a filename-prefixed count (FAIL). Measured both.
printf 'content\n' > "$WORK/row2.txt"
{ printf '| claim | check |\n'
  printf '|---|---|\n'
  printf '| false pass under CRLF | <!-- verify: echo hello \\| grep -c nomatch --> |\n'
  printf '| false failure under CRLF | <!-- verify: grep -c nomatch %s \\| cat --> |\n' "$WORK/row2.txt"
  printf '| the idiom this framework teaches | <!-- verify: test -f /nonexistent && echo PASS \\|\\| echo FAIL --> |\n'
} > "$WORK/crlf-lf.md"
sed 's/$/\r/' "$WORK/crlf-lf.md" > "$WORK/crlf.md"
# the inputs differ ONLY by line ending; assert that rather than trusting sed
if ! cmp -s <(tr -d '\r' < "$WORK/crlf.md") "$WORK/crlf-lf.md"; then
  printf '  FAIL  C0 — the CRLF input differs from its LF twin by more than line endings\n'; FAIL=1
fi
# Only the filename is normalised. An earlier version also blanked the `ran N of N`
# line, which carries no filename and therefore never needed blanking — it only
# narrowed what C1 compares. Including it is free and strictly stronger.
norm() { sed -e 's|[^ ]*crlf\(-lf\)\?\.md|FILE|g' "$1"; }
bash "$RUNNER" "$WORK/crlf-lf.md" > "$WORK/c-lf.out" 2>&1 || true
bash "$RUNNER" "$WORK/crlf.md"    > "$WORK/c-crlf.out" 2>&1 || true
if cmp -s <(norm "$WORK/c-lf.out") <(norm "$WORK/c-crlf.out"); then
  printf '  PASS  C1 — CRLF and LF produce identical dispositions\n'
else
  printf '  FAIL  C1 — CRLF and LF disagree:\n'; diff <(norm "$WORK/c-lf.out") <(norm "$WORK/c-crlf.out") | sed 's/^/        /'
  FAIL=1
fi
# CRLF with NO trailing newline. `sed 's/$/\r/'` always terminates its output, so
# C1-C3 structurally cannot reach this shape — a file whose last line is the
# annotation is exactly the shape a table at end-of-file has.
printf '| c | k |\r\n|---|---|\r\n| last | <!-- verify: echo hello \\| grep -c nomatch --> |\r' > "$WORK/crlf-nonl.md"
bash "$RUNNER" "$WORK/crlf-nonl.md" > "$WORK/c-nonl.out" 2>&1 || true
if grep -q '^FAIL' "$WORK/c-nonl.out"; then
  printf '  PASS  C4 — CRLF with no final newline still un-escapes and fails correctly\n'
else
  printf '  FAIL  C4 — expected FAIL on the unterminated-final-line CRLF file, got:\n'
  sed 's/^/        /' "$WORK/c-nonl.out"; FAIL=1
fi

# C5 — `\r\r\n`. A blob already holding CRLF, converted again, produces a doubled
# CR; so does applying the fixture's own `sed 's/$/\r/'` idiom to an already-CRLF
# checkout. `sub(/\r$/, "")` strips ONE, which left the defect fully intact on the
# fixed runner — measured: base PASS, single-CR strip PASS, `\r+` FAIL (correct).
printf '| p | k |\r\r\n|---|---|\r\r\n| x | <!-- verify: echo hello \\| grep -c nomatch --> |\r\r\n' > "$WORK/crcrlf.md"
bash "$RUNNER" "$WORK/crcrlf.md" > "$WORK/c-dbl.out" 2>&1 || true
if grep -q '^FAIL .*echo hello | grep' "$WORK/c-dbl.out"; then
  printf '  PASS  C5 — a doubled CR is stripped, so the un-escape still runs\n'
else
  printf '  FAIL  C5 — expected an un-escaped FAIL on the \\r\\r\\n file, got:\n'
  sed 's/^/        /' "$WORK/c-dbl.out"; FAIL=1
fi

# The guard must be load-bearing: without the strip the SAME input must diverge.
sed '/CRLF: strip before anything reads/d' "$RUNNER" > "$WORK/c-mut.sh"
if cmp -s "$WORK/c-mut.sh" "$RUNNER"; then
  printf '  FAIL  C2 — the ablation changed nothing; it no longer targets the runner\n'; FAIL=1
else
  bash "$WORK/c-mut.sh" "$WORK/crlf.md" > "$WORK/c-mut.out" 2>&1 || true
  if cmp -s <(norm "$WORK/c-lf.out") <(norm "$WORK/c-mut.out"); then
    printf '  FAIL  C2 — removing the CRLF strip changed nothing; C1 passes vacuously\n'; FAIL=1
  else
    printf '  PASS  C2 — removing the CRLF strip does corrupt the dispositions\n'
  fi
  # and specifically: the false PASS, which is the one nothing in the run signals
  if grep -q '^PASS .*echo hello' "$WORK/c-mut.out"; then
    printf '  PASS  C3 — without the strip the failing claim reports PASS, exit 0\n'
  else
    printf '  FAIL  C3 — expected a false PASS on the escaped-pipe row without the strip\n'; FAIL=1
  fi
fi

# ---- ablations --------------------------------------------------------------
# "the output changed" is too weak a consequence to assert. A mutation that
# breaks the runner in some unrelated way also changes the output, so a
# differs-from-baseline test passes without ever demonstrating the defect the
# guard exists to prevent. Each ablation therefore names the specific row,
# canary or summary shape it must move, and FAILS if the runner merely breaks
# differently.
echo
echo "ablations — every guard must be load-bearing:"
ablate() {  # ablate <id> <what it defends> <sed-expr> <consequence>
  local id="$1" what="$2" expr="$3" want="$4"
  local mut="$WORK/$id.sh"
  sed "$expr" "$RUNNER" > "$mut"
  if cmp -s "$mut" "$RUNNER"; then
    printf '  FAIL  %s — the ablation changed nothing; it no longer targets the runner (%s)\n' "$id" "$what"
    FAIL=1; return
  fi
  rm -rf "$CANARY"; mkdir -p "$CANARY"
  local mout ok=0 detail=""
  run_runner "$mut" "$WORK/$id.out"; mout="$(cat "$WORK/$id.out")"
  case "$want" in
    canary:*)
      [ -e "$CANARY/${want#canary:}" ] && ok=1
      detail="expected prose ${want#canary:} to execute" ;;
    nosummary:*)
      printf '%s\n' "$mout" | grep -q ' annotations —' || ok=1
      detail="expected the run to die before its summary line" ;;
    drain:*)  # the stdin-eater must swallow LATER commands while the run survives
      if printf '%s\n' "$mout" | grep -q ' annotations —' \
         && printf '%s\n' "$mout" | grep -F " :: " | grep -q p05 \
         && ! printf '%s\n' "$mout" | grep -F " :: " | grep -q p07; then ok=1; fi
      detail="expected p05 to run, p07 to be swallowed, and the summary to survive" ;;
    notrow:*)  # for a consequence whose exact shape is implementation-dependent
      # (both branches also require the summary line: a mutant that dies outright
      # satisfies "the row is gone" without demonstrating anything)
      local m2="${want#notrow:}"; local mk2="${m2%%=*}" bad2="${m2#*=}"
      local l2; l2="$(printf '%s\n' "$mout" | grep -F -- " :: " | grep -F -- "$mk2" | head -n1)"
      printf '%s\n' "$mout" | grep -q ' annotations —' && [ "${l2%% *}" != "$bad2" ] && ok=1
      detail="expected $mk2 to stop being $bad2, it is still ${l2%% *}" ;;
    norow:*)
      printf '%s\n' "$mout" | grep -q ' annotations —' \
        && ! printf '%s\n' "$mout" | grep -F -- " :: " | grep -qF -- "${want#norow:}" && ok=1
      detail="expected ${want#norow:} to disappear from the report" ;;
    row:*)
      local m="${want#row:}"; local marker="${m%%=*}" wantd="${m#*=}"
      local line; line="$(printf '%s\n' "$mout" | grep -F -- " :: " | grep -F -- "$marker" | head -n1)"
      [ "${line%% *}" = "$wantd" ] && ok=1
      detail="expected $marker to misclassify as $wantd, got ${line%% *}" ;;
  esac
  rm -rf "$CANARY"; mkdir -p "$CANARY"
  if [ $ok -eq 1 ]; then printf '  PASS  %s — %s\n' "$id" "$what"
  else printf '  FAIL  %s — removing %s did not produce its defect: %s\n' "$id" "$what" "$detail"; FAIL=1; fi
}

ablate A1-fence-strip    "fenced-block stripping"          '/inside a fence: documentation/d'   canary:n02
ablate A2-span-mask      "code-span masking"               's|mask = maskspans(tolower(line), line)|mask = tolower(line)|' canary:n01
ablate A3-pipe-unescape  "table-cell pipe un-escaping"     '/a table cell escapes its pipes/d'  row:p02=ERROR
ablate A4-stdin-closed   "closing each command's stdin"    's|</dev/null ||'                    drain:
# A5 also removes the timeout, because both live on one line. That confound is why
# M1/M1a exist: the timeout is ablated separately, so neither guard rests on this row.
ablate A5-subshell       "the per-command subshell"        's|\${TO:-} bash -c "\$cmd" </dev/null >"\$OUTF"|eval "\$cmd" >"\$OUTF"|' nosummary:
ablate A6-empty-error    "scoring silence as ERROR"        '/no output — it proved nothing/d'   row:p06=PASS
# p10's marker sits *after* its redirect, so a truncated p10 is not merely
# misclassified — it stops being recognizable as p10 at all. The consequence
# asserted is the fragment that runs in its place: a bare `test -f`, silent and
# therefore ERROR, where the whole command was a PASS.
ablate A7-comment-close  'requiring a closing `-->`'       's|index(rest, "-->")|index(rest, ">")|' row:p10-target=ERROR
ablate A8-unclosed       "reporting an unclosed annotation" 's|if (e == 0) { print "M\\034" FILENAME "\\034" substr(rest, 1, 60); break }|if (e == 0) break|' norow:m01
# The guard the hostile-repo run added: un-escaping everywhere, not only in
# tables. Separate from A3 because it fails in the opposite direction — A3 leaves
# table cells broken, A9 breaks everything else. p13's bad branch exits non-zero,
# and the consequence is "stops being PASS" rather than a named disposition,
# because which one it becomes depends on whether the local awk rejects an empty
# alternation (mawk) or accepts it (busybox awk).
ablate A9-table-only     "restricting un-escaping to tables" 's|if (intbl) gsub|gsub|'          notrow:p13=PASS
ablate A10-fence-perfile "resetting all state per file"    '/no state may cross a file/d'       norow:p01
ablate A11-tilde-fence   "treating ~~~ as a fence"         's/ || bare ~ \/\^~~~\///'           canary:n07
ablate A12-mask-offsets  "extracting from the original line" 's|rest = substr(line, p)|rest = substr(mask, p)|' row:p14=ERROR
ablate A13-stderr-split  "capturing stderr separately"     's|2>"\$ERRF"; rc=\$?|2>\&1; rc=\$?|' row:p15=PASS
ablate A14-manual-gate   "the manual short-circuit"        '/manual=\$((manual + 1))/d'          row:p09=ERROR
ablate A15-cannot-gate   "the CANNOT VERIFY prefix"        's|"CANNOT VERIFY"\|"CANNOT VERIFY"\[!A-Za-z0-9\]\*)|"NO-SUCH-PREFIX")|' row:p03=FAIL
ablate A16-notfound      "scoring 127 as ERROR"            '/rc" -eq 127/d'                     row:p08=FAIL
ablate A17-table-detect  "detecting pipe-less tables"      's|if (intbl) gsub|if (intbl \&\& $(0) ~ /^[ \\t]*\\\|/) gsub|' row:p28=ERROR
# Everything below closes a hole the second review battery proved: each was a
# guard that did not exist, or one the fixture could not have noticed missing.
ablate A18-nested-fence  "closing a fence only on its own char" 's|else if (c == fch \&\& k >= flen) fch = ""|else fch = ""|' canary:n08
ablate A19-double-open   "rejecting a second opener on one line" '/print "D\\034" FILENAME/s|tolower(cmd) ~ /<!--\[ \\t\]\*verify:/|0|' row:m02=ERROR
ablate A20-legacy-fail   "rescoring the legacy verdict word" 's|{ rc=1; note="  ! legacy|{ note="  ! legacy|' row:p20=PASS
ablate A21-manual-glob   "requiring a word break after manual" 's|manual\[\[:space:\]:\]\*|manual*|' row:p21=MANUAL
ablate A22-caseless      "matching the marker case-insensitively" 's|maskspans(tolower(line), line)|maskspans(line, line)|' norow:p22
ablate A23-span-swallow  "reporting an annotation a span swallowed" 's|if (tolower(span) ~ /<!--\[ \\t\]\*verify:/ \&\& index(span, "-->") == 0)|if (0)|' norow:m03
ablate A25-empty-annotation "reporting an empty annotation" 's|if (cmd == "") print "E\\034"|if (0) print "E\\034"|' norow:m04
ablate A26-indented-fence "recognising an indented fence"  's|sub(/\^\[ \\t\]\*/, "", bare)|sub(/^ ? ? ?/, "", bare)|' canary:n10
ablate A27-delim-pipe    "requiring a pipe in the delimiter row" 's|isdelim(\$(0)) \&\& index(\$(0), "\|")|isdelim($(0))|' notrow:p34=PASS
ablate A29-table-end     "ending a table at its last row"   '/a table ends at its last row/d'    notrow:p33=PASS
ablate A30-unterminated  "reporting an unterminated fence"  '/and never closed/d' 'norow:a fence opened'
ablate A28-fail-exact    "matching the legacy word exactly" '/this framework taught/s|FAIL)|FAIL*)|' row:p31=FAIL

echo
if [ $FAIL -eq 0 ]; then echo "All verify-runner fixture cases passed."; else echo "Fixture failures above."; fi
exit $FAIL
