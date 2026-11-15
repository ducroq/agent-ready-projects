#!/usr/bin/env bash
# Sensitivity fixture for scripts/autoload-size.sh (curate Step 0 sub-step 6).
# The script carries the over-budget procedure that curate no longer states, so a
# section that stops printing is a rule lost to the agent. Each row seeds the
# condition and asserts the section; the absence rows hold the conditional parts
# to their conditions, so "always print" goes red as surely as "never print".
set -u
cd "$(dirname "$0")"
S="$(cd ../../.. && pwd)/scripts/autoload-size.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
FAIL=0
ok() { printf '  PASS  %s\n' "$1"; }
no() { printf '  FAIL  %s\n' "$1"; FAIL=1; }
fill() { python3 -c "import sys; sys.stdout.write('$2' * $3)" > "$W/$1"; }   # name, unit, count

fill small.md 'plain line of prose here\n' 100          # 2,500 chars
fill near.md  'x' 32000
fill over.md  'x' 36000
fill proj.md  'x' 16000
fill utf.md   'é' 1000                                  # 1,000 chars, 2,000 bytes
printf '| a      | b        |\n|--------|----------|\n| x      | y        |\n' > "$W/tbl.md"

run() { out="$(bash "$S" "$@" 2>&1)"; rc=$?; }

run "$W/small.md"
[ "$rc" -eq 0 ] && grep -qF 'total: 2500 chars in 1 file(s)' <<<"$out" && ok "A1 under budget: total in chars, exit 0" || no "A1 under budget ($rc): $out"
grep -qE 'NEAR BUDGET|OVER BUDGET|PROJECT FILE OVER' <<<"$out" && no "A1b a small set prints a budget or project flag" || ok "A1b a small set prints no budget procedure and no project flag"
grep -qF 'audit-context Step 1 counts bytes' <<<"$out" && ok "A1c the unit note prints" || no "A1c the unit note is gone"

run "$W/near.md"
[ "$rc" -eq 0 ] && grep -qF 'NEAR BUDGET' <<<"$out" && grep -qF 'Session-narrative footers' <<<"$out" && ok "A2 near budget: procedure prints, exit 0" || no "A2 near budget ($rc)"

run "$W/small.md" "$W/over.md"
[ "$rc" -eq 1 ] && grep -qF 'OVER BUDGET: 38500 chars' <<<"$out" && ok "A3 two files summed, over budget exits 1" || no "A3 over budget ($rc): $out"
for n in 'Session-narrative footers' 'surface it to the engineer' "sub-step 6's trim rules (protected sections" 'No table padding measured.'; do
  grep -qF "$n" <<<"$out" && ok "A3 the procedure carries: $n" || no "A3 the procedure lost: $n"; done

run "$W/proj.md"
grep -qF 'PROJECT FILE OVER 15000 CHARS' <<<"$out" && ok "A4 a project file over 15k is flagged under budget" || no "A4 project flag missing"
run "$W/small.md" "$W/proj.md"
grep -qF 'PROJECT FILE OVER' <<<"$out" && no "A4b the flag reads the FIRST file only, and fired on the second" || ok "A4b only the first file is the project file"

run "$W/tbl.md"
grep -qF '(table padding 36 chars)' <<<"$out" && ok "A5 table padding is measured" || no "A5 padding: $out"
cat "$W/tbl.md" "$W/near.md" > "$W/tblnear.md"; run "$W/tblnear.md"
grep -qF 'Table padding is 36 chars of it' <<<"$out" && grep -qF 'Prettier resolves its' <<<"$out" && ok "A5b near budget with padding: the formatter step prints" || no "A5b formatter step missing"

run "$W/utf.md"
grep -qE '^ +1000 chars +2000 bytes' <<<"$out" && ok "A6 characters, not bytes, on non-ASCII text" || no "A6 utf: $out"

run "$W/small.md" --instructed "$W/over.md"
[ "$rc" -eq 0 ] && grep -qF 'INSTRUCTION-LOADED' <<<"$out" && grep -qF 'total: 2500 chars' <<<"$out" && ok "A7 instruction-loaded files are listed, not summed" || no "A7 instructed ($rc)"

printf '| a |\n|----------|\n' > "$W/sep.md"; run "$W/sep.md"
grep -qF '(table padding 7 chars)' <<<"$out" && ok "A5c delimiter dashes count as padding" || no "A5c sep: $out"
printf '```\n| a      |\n```\n' > "$W/fenced.md"; run "$W/fenced.md"
grep -qF 'table padding' <<<"$out" && no "A5d a table inside a fence was counted" || ok "A5d a fenced table is not counted"
cp "$W/over.md" "$W/-dash.md"; run_in() { out="$(cd "$W" && bash "$S" "$@" 2>&1)"; rc=$?; }
run_in -dash.md
if ! grep -qF '(table padding' <<<"$out" && grep -qF 'OVER BUDGET: 36000' <<<"$out"; then ok "A9 a dash-named file is read, not parsed as an option"; else no "A9 -dash.md: $out"; fi
printf '```\n| a |\n~~~\n| b      |\n```\n' > "$W/mixfence.md"; run "$W/mixfence.md"
grep -qF '(table padding' <<<"$out" && no "A5e a ~~~ line closed a \`\`\` fence" || ok "A5e a fence closes only on its own character"
printf '| a | ----------- |\n|---|---|\n' > "$W/datadash.md"; run "$W/datadash.md"
grep -qF '(table padding' <<<"$out" && no "A5f dashes in a data cell counted as padding" || ok "A5f dashes collapse only in delimiter rows"
: > "$W/empty.md"; run "$W/empty.md"
grep -qF 'PROJECT FILE IS EMPTY' <<<"$out" && ok "A10 an empty project file is flagged" || no "A10 empty: $out"
REAL_WC=$(command -v wc); mkdir -p "$W/bin"; printf '#!/bin/sh\ncase "$1" in -m) exit 1;; esac\nexec %s "$@"\n' "$REAL_WC" > "$W/bin/wc"; chmod +x "$W/bin/wc"
out="$(PATH="$W/bin:$PATH" bash "$S" "$W/small.md" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && grep -qF 'COULD NOT COUNT' <<<"$out" && ok "A11 a wc without -m exits 2, never a false under-budget" || no "A11 wc stub ($rc): $out"
run; [ "$rc" -eq 2 ] && ok "A8 no files: exit 2" || no "A8 no files exit $rc"
run "$W/nope.md"; [ "$rc" -eq 2 ] && ok "A8b an unreadable file: exit 2, not a short total" || no "A8b exit $rc"
run --bogus "$W/small.md"; [ "$rc" -eq 2 ] && ok "A8c an unknown option: exit 2" || no "A8c exit $rc"

echo
[ "$FAIL" -eq 0 ] && echo "All autoload-size cases passed." || echo "autoload-size fixture failures above."
exit "$FAIL"
