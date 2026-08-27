#!/usr/bin/env bash
# Builds the review benchmark corpus: two trees of identical shape, one carrying
# seeded defects and one clean. Usage: build.sh <dest>
#
# The trees imitate this framework's own shape — a skill template whose prose
# describes a checker, the checker itself, and a fixture that asserts it — because
# that is where every defect in the historical log actually lived.
set -eu
DEST="${1:?usage: build.sh <dest>}"
rm -rf "$DEST"; mkdir -p "$DEST/seeded" "$DEST/seeded-silent" "$DEST/clean"

# ---------------------------------------------------------------- clean tree
mkdir -p "$DEST/clean/templates" "$DEST/clean/tests"
cat > "$DEST/clean/templates/skill.md" <<'EOF'
# check-refs

## Step 2 — Resolve each reference

Rungs run in order: 1 (as written), 2 (suffix in the working tree), 3 (sibling
repo). A reference resolved by a rung that ran is decided.

| resolves at | meaning | section |
|---|---|---|
| rung 1 | as written | Resolved |
| rung 2 | suffix match | Resolved below rung 1 |
| rung 3 | in a sibling | Resolved below rung 1 |
| nowhere, sibling reachable | a rung ruled it out | Findings |
| nowhere, no sibling | undecided | Unconfirmed |

On the trees measured, rung 2 declines a path containing a glob character.

## Step 5 — Report

Report the counts by class. There are 4 counted sections.
EOF
cat > "$DEST/clean/tests/check.py" <<'EOF'
import sys, pathlib
def check(root, docs):
    findings, weak, undecided = [], [], []
    root = pathlib.Path(root)
    for d in docs:
        for frag in (root / d).read_text().split():
            if not frag.endswith('.py'):
                continue
            if (root / frag).exists():
                continue
            hits = [p for p in root.rglob('*') if p.is_file() and p.name == frag]
            if hits:
                weak.append((d, frag, 'suffix'))
            else:
                findings.append((d, frag, 'UNRESOLVED'))
    return findings, weak, undecided
if __name__ == '__main__':
    f, w, u = check(sys.argv[1], sys.argv[2:])
    for label, rows in (('FINDINGS', f), ('WEAK', w), ('UNDECIDED', u)):
        for r in rows: print(label, *r)
        print(f'  {label} total: {len(rows)}')
EOF
cat > "$DEST/clean/tests/fixture.sh" <<'EOF'
#!/usr/bin/env bash
# Seeded cases for check.py. T = must report, N = must stay silent.
set -u
W="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0
mkdir -p "$W/src"; : > "$W/src/real.py"
printf 'refs real.py and ghost.py\n' > "$W/t1.md"
run() { python3 "$(dirname "$0")/check.py" "$1" "$2"; }
[ -n "$(run "$W" t1.md | grep FINDINGS || true)" ] || { echo "FAIL t1"; FAIL=1; }
ablate() {  # mutate, then confirm the named case turns red
  sed "s|$2|$3|" "$(dirname "$0")/check.py" > "$W/mut.py"
  out="$(python3 "$W/mut.py" "$W" t1.md 2>&1 || true)"
  # grep the SECTION, not the reason string: A1 moves the row from FINDINGS to
  # WEAK and the reason travels with it, so matching on UNRESOLVED alone reports
  # "killed nothing" for a mutation that killed the thing under test.
  [ -z "$(grep '^FINDINGS' <<<"$out")" ] || { echo "FAIL ablation $1 killed nothing"; FAIL=1; }
}
ablate "A1 drop the findings arm" "findings.append" "weak.append"
exit "$FAIL"
EOF
cp -r "$DEST/clean/." "$DEST/seeded/"
cp -r "$DEST/clean/." "$DEST/seeded-silent/"

# ------------------------------------------------------------- seeded defects
S="$DEST/seeded"
# D1 lives ALONE in its own variant. It MASKS D7 — a loop that never runs cannot
# also drop an item — and a seeded defect that hides another makes the hidden one
# unscoreable, which would silently inflate every config's apparent recall.
python3 - "$DEST/seeded-silent/tests/check.py" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = s.replace("        for frag in (root / d).read_text().split():",
              "        for frag in []:  # D1")
p.write_text(s)
PY
# D7 silent-drop: a resolved-nowhere path enters no section at all
python3 - "$S/tests/check.py" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = s.replace("                findings.append((d, frag, 'UNRESOLVED'))",
              "                pass  # D7")
p.write_text(s)
PY
# D2 unhedged absolute / D3 stale restatement / D4 wrong count / D6 false row
python3 - "$S/templates/skill.md" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = s.replace("On the trees measured, rung 2 declines a path containing a glob character.",
              "Rung 2 declines every path containing a glob character, on any tree.")   # D2
s = s.replace("Rungs run in order: 1 (as written), 2 (suffix in the working tree), 3 (sibling\nrepo).",
              "Rungs run in order: 1 (as written), 3 (sibling repo).")                   # D3
s = s.replace("There are 4 counted sections.", "There are 6 counted sections.")          # D4
s = s.replace("| nowhere, sibling reachable | a rung ruled it out | Findings |",
              "| nowhere, sibling reachable | correctly marked | Unconfirmed |")         # D6
p.write_text(s)
PY
# D5 vacuous ablation: the mutation changes nothing the assertion measures
python3 - "$S/tests/fixture.sh" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
s = s.replace('ablate "A1 drop the findings arm" "findings.append" "weak.append"',
              'ablate "A1 drop the findings arm" "UNRESOLVED\'))" "UNRESOLVED \'))"  # D5')
p.write_text(s)
PY
# Verify the seeds LANDED. A replace that silently matched nothing would produce
# a benchmark where every config scores 100% recall against defects that are not
# there — the failure this whole harness exists to detect, inside itself.
miss=0
check_seed() { grep -rqF -- "$2" "$1" || { echo "SEED MISSING: $3 ($2)"; miss=1; }; }
check_seed "$DEST/seeded-silent/tests/check.py" "for frag in []"          D1
check_seed "$S/templates/skill.md" "declines every path"                  D2
check_seed "$S/templates/skill.md" "1 (as written), 3 (sibling"           D3
check_seed "$S/templates/skill.md" "6 counted sections"                   D4
check_seed "$S/tests/fixture.sh"   "# D5"                                 D5
check_seed "$S/templates/skill.md" "correctly marked"                     D6
check_seed "$S/tests/check.py"     "pass  # D7"                           D7
for f in "for frag in []" "declines every path" "6 counted sections" "correctly marked" "pass  # D7"; do
  grep -rqF -- "$f" "$DEST/clean" && { echo "CONTROL CONTAMINATED: clean carries [$f]"; miss=1; }
done
[ "$miss" -eq 0 ] || { echo "BUILD FAILED — the corpus does not carry what the manifest claims"; exit 1; }
echo "built: seeded (D2-D7, 6 defects), seeded-silent (D1), clean (0) — all seeds verified present, control verified clean"
