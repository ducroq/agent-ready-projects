#!/usr/bin/env bash
# Sensitivity fixture for lint rule 24 (tests/lint/fetch-validates.sh, #268).
#
# Half A seeds each way a fetch line can be wrong. Half B runs the lines that ship,
# with a stub curl, against a whole, an empty and a cut-off download: the rule reads
# text, and only running the line shows that the text refuses a bad file.
set -u
cd "$(dirname "$0")/../../.." || exit 2
ROOT="$PWD"; RULE="$ROOT/tests/lint/fetch-validates.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FAIL=0
U=https://raw.githubusercontent.com/ducroq/agent-ready-projects/master/scripts
ok()  { printf '  PASS  %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; FAIL=1; }

# tree <line>: a repo with one script and one skill template holding that line
tree() {
  rm -rf "$WORK/t"; mkdir -p "$WORK/t/templates" "$WORK/t/scripts"
  printf '%s\n' '#!/bin/sh' 'echo "$log"' 'echo done here' > "$WORK/t/scripts/x.sh"
  printf '%s\n' '```bash' "$1" '```' > "$WORK/t/templates/s.md"
}
run()  { OUT=$(bash "$RULE" "$WORK/t" 2>"$WORK/err"); RC=$?; }
red()  { tree "$2"; run; if [ "$RC" -eq 1 ] && printf '%s' "$OUT" | grep -qF "$3"; then ok "$1"; else bad "$1 — rc=$RC $OUT"; fi; }
green(){ tree "$2"; run; if [ "$RC" -eq 0 ] && [ -z "$OUT" ] && grep -q 'script fetch(es)' "$WORK/err"; then ok "$1"; else bad "$1 — rc=$RC $OUT"; fi; }

echo "A — seeded lines"
red   "A1 unchecked fetch (the curate shape)"      "# curl -fsSL $U/x.sh -o /tmp/x.sh && X=/tmp/x.sh" 'uses it unchecked'
red   "A2 check after the assignment"              "curl -fsSL $U/x.sh -o /tmp/x && X=/tmp/x && tail -n 1 /tmp/x | grep -q 'done here'" 'uses it unchecked'
red   "A3 checks another file"                     "curl -fsSL $U/x.sh -o /tmp/x && tail -n 1 /tmp/y | grep -q 'done here' && X=/tmp/x" 'must be the same file'
red   "A4 text is not the script's last line"      "curl -fsSL $U/x.sh -o /tmp/x && tail -n 1 /tmp/x | grep -q 'old ending' && X=/tmp/x" 'every fetch would be refused'
red   "A5 text also matches an earlier line"       "curl -fsSL $U/x.sh -o /tmp/x && tail -n 1 /tmp/x | grep -q 'echo' && X=/tmp/x" 'cut off there passes'
red   "A6 text matches an empty line"              "curl -fsSL $U/x.sh -o /tmp/x && tail -n 1 /tmp/x | grep -q '.*' && X=/tmp/x" 'checks nothing'
red   "A7 names a script this repo does not have"  "curl -fsSL $U/gone.sh -o /tmp/x && tail -n 1 /tmp/x | grep -q 'done' && X=/tmp/x" 'is not in this repo'
red   "A8 piped straight into bash"                "curl -fsSL $U/x.sh | bash" 'uses it unchecked'
red   "A9 second fetch on a checked line"          "curl -fsSL $U/x.sh -o /tmp/x && tail -n 1 /tmp/x | grep -q 'done here' && X=/tmp/x; curl $U/x.sh | sh" 'two script fetches'
red   "A15 fallback after the assignment"           "curl -fsSL $U/x.sh -o /tmp/x && tail -n 1 /tmp/x | grep -q 'done here' && X=/tmp/x || X=/tmp/x" 'more shell follows'
red   "A16 run after the assignment"                "curl -fsSL $U/x.sh -o /tmp/x && tail -n 1 /tmp/x | grep -q 'done here' && X=/tmp/x; bash /tmp/x" 'more shell follows'
red   "A17 unescaped mid-pattern \$ (#378)"         "curl -fsSL $U/x.sh -o /tmp/x && tail -n 1 /tmp/x | grep -q 'done\$ here' && X=/tmp/x" 'unescaped $'
green "A18 end anchor \$ is allowed"               "curl -fsSL $U/x.sh -o /tmp/x && tail -n 1 /tmp/x | grep -q 'done here\$' && X=/tmp/x"
green "A10 checked, literal path"                  "curl -fsSL $U/x.sh -o /tmp/x && tail -n 1 /tmp/x | grep -qF 'done here' && X=/tmp/x"
green "A11 checked, quoted variable"               "[ -f \"\$X\" ] || { t=\$(mktemp) && curl -m 10 -fsSL $U/x.sh -o \"\$t\" && tail -n 1 \"\$t\" | grep -q 'done here' && X=\$t; }"
tree "no fetch here"; run; [ "$RC" -eq 2 ] && ok "A12 nothing to check exits 2, not clean" || bad "A12 rc=$RC"
bash "$RULE" >/dev/null 2>&1; [ $? -eq 2 ] && ok "A13 no root refuses" || bad "A13"
A=$(sed "s/        if not m or not URL.search(m.group(0)):/        if False:/" "$RULE"); tree "curl $U/x.sh | bash"
[ "$A" != "$(cat "$RULE")" ] || bad "A14 ablation did not apply"
printf '%s\n' "$A" > "$WORK/abl.sh"; bash "$WORK/abl.sh" "$WORK/t" >"$WORK/o" 2>/dev/null
grep -q 'uses it unchecked' "$WORK/o" && bad "A14 ablated rule still reports A8" || ok "A14 ablation: without the form check, A8 is not reported"

echo "B — the shipped lines, run"
mkdir -p "$WORK/bin" "$WORK/tmp"
cat > "$WORK/bin/curl" <<'C'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do case "$1" in -o) o=$2; shift ;; https:*) u=$1 ;; esac; shift; done
src="$FIX_ROOT/scripts/${u##*/}"
case "$FIX_MODE" in whole) cp "$src" "$o" ;; empty) : > "$o" ;; cut*) head -n "${FIX_MODE#cut}" "$src" > "$o" ;; esac
C
chmod +x "$WORK/bin/curl"
# value <line> <mode> <var>: preset <var> to a missing clone, as the skills do, run one
# shipped line, and print the path it assigned, or nothing if the preset survived
value() {
  FIX_ROOT="$ROOT" FIX_MODE="$2" TMPDIR="$WORK/tmp" PATH="$WORK/bin:$PATH" \
    bash -c "$3=/no/clone"$'\n'"$1"$'\n'"[ \"\$$3\" = /no/clone ] || printf '%s' \"set:\$$3\"" 2>/dev/null
}
n=0
while IFS= read -r line; do
  n=$((n + 1))
  name=$(printf '%s' "$line" | grep -o 'scripts/[a-z0-9-]*\.sh' | head -1); name=${name#scripts/}
  var=$(printf '%s' "$line" | sed -E "s/.*'[[:space:]]+&&[[:space:]]+([A-Za-z_]+)=.*/\1/")
  cmd=$(printf '%s' "$line" | sed -E "s/^[[:space:]]*(# No clone\? )?//; s#/tmp/#$WORK/tmp/#g")
  [ -n "$(value "$cmd" whole "$var")" ] || bad "$name: a whole download was refused"
  [ -z "$(value "$cmd" empty "$var")" ] || bad "$name: an empty download was accepted"
  total=$(wc -l < "scripts/$name"); k=1; took=""
  while [ "$k" -lt "$total" ]; do
    [ -z "$(value "$cmd" "cut$k" "$var")" ] || took="$took $k"
    k=$((k + 1))
  done
  [ -z "$took" ] && ok "$name: whole accepted; empty and $((total - 1)) cut-off copies refused" || bad "$name: accepted when cut at line(s)$took"
done < <(grep -hE 'raw\.githubusercontent\.com/.*/scripts/[a-z0-9-]+\.sh' templates/*.md)
[ "$n" -ge 7 ] && ok "B covered $n shipped fetch lines" || bad "B found only $n shipped fetch lines, expected at least 7"

echo
[ "$FAIL" -eq 0 ] && { echo "All fetch-validates cases passed."; exit 0; }
echo "fetch-validates fixture FAILED."; exit 1
