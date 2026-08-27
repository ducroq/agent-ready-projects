#!/usr/bin/env bash
# Sensitivity fixture for curate Step 0.1's dead-reference extractor.
#
# It exists because that extractor shipped TWO false-positive classes in one day,
# both found by adopters running it rather than by any check here: `process.env`
# (a filename-shaped token the sibling step already documents) and qualified
# cross-repo paths (12 dead reported, 0 actually dead). Every class below is one
# that has actually bitten.
#
# The program is EXTRACTED from templates/curate.md, never copied, so it cannot
# drift from the shipped surface.
set -u
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)" || exit 2
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
FAIL=0

python3 - "$ROOT/templates/curate.md" "$W/deadref.py" <<'PY' || { echo "EXTRACTION FAILED — the anchors moved"; exit 1; }
import sys, pathlib
s = pathlib.Path(sys.argv[1]).read_text()
a = "python3 - memory/MEMORY.md CLAUDE.md <<'PY'"
i = s.index(a); j = s.index("\nPY\n", i)
prog = s[i+len(a):j]
for needle in ("DENY", "here = {p.name", "cross-repo", "filename-shaped", "ambiguous"):
    if needle not in prog:
        sys.exit("extracted program is missing %r" % needle)
pathlib.Path(sys.argv[2]).write_text(prog)
PY

mkdir -p "$W/repo/docs" "$W/repo/data" "$W/repo/node_modules/lodash" "$W/repo/memory" \
         "$W/repo/src/a" "$W/repo/src/b" "$W/NeighbourRepo/docs" "$W/NeighbourRepo/scripts"
cd "$W/repo" && git init -q . && git config user.email f@x && git config user.name f
printf 'data/\nnode_modules/\n' > .gitignore
: > docs/real.md; : > memory/notes.md
: > data/narrative_risk.json                     # real, GITIGNORED
echo '{}' > node_modules/lodash/package.json     # vendored
: > src/a/helpers.py; : > src/b/helpers.py       # two answers
: > "$W/NeighbourRepo/docs/OVER_THERE.md"
# The four-cell matrix for a self-qualifying cross-repo fragment. `AbsentRepo`
# is never created, so the neighbourless half is exercised in the SAME run.
: > "$W/NeighbourRepo/scripts/present.py"

# ⚠️ KNOWN, UNFIXED EXPOSURE, seeded so it is visible rather than theoretical.
# SparseRepo is a real sibling whose working tree OMITS the directory the
# reference points into. The file exists upstream; the extractor cannot see it
# and calls it dead. MEASURED, and narrower than the phrasing v1.34.0 shipped:
# `--depth 1` truncates history and `--filter=blob:none` fetches blobs at
# checkout — both leave every file present and neither reproduces this. Sparse
# checkout is the only mode that omits files from the working tree.
# This case asserts the CURRENT behaviour. If someone fixes it, this row turns
# red and tells them the exposure is closed — which is the point of seeding a
# defect you have decided not to fix.
#
# ⚠️ REVISIT: 2027-02-27, or on the first sparse-checkout sibling observed in any
# real estate, whichever is first. A diagnosis without a revisit date decays the
# same way an undiagnosed finding does — an adopter put it best: *a finding that
# survives many runs stops being read as a question, and the defence of keeping
# it becomes the reason nobody asks what it is.* Measured on their side: 16
# siblings, none sparse, so this exposure has no instance in the one estate that
# has looked. That is a window, not a property.
( mkdir -p "$W/sparse-origin/scripts" "$W/sparse-origin/docs"
  cd "$W/sparse-origin" && git init -q . && git config user.email f@x && git config user.name f
  : > scripts/upstream_only.py; : > docs/keep.md
  git add -A && git commit -qm seed ) >/dev/null 2>&1
( git clone -q "file://$W/sparse-origin" "$W/SparseRepo"
  cd "$W/SparseRepo" && git sparse-checkout init --cone && git sparse-checkout set docs ) >/dev/null 2>&1
cat > CLAUDE.md <<'EOF'
Live at `docs/real.md`, and a bare `notes.md` one directory down.
Dead: `docs/ghost.md`.
The manifest is `package.json` at the root.
Runtime data lives at `narrative_risk.json`.
Sibling reference: `NeighbourRepo/docs/OVER_THERE.md`.
Sibling, present there: `NeighbourRepo/scripts/present.py`.
Sibling, PROVABLY absent there: `NeighbourRepo/scripts/ghost.py`.
No such sibling on disk: `AbsentRepo/scripts/whatever.py`.
Sparse sibling, file exists upstream: `SparseRepo/scripts/upstream_only.py`.
Removed package: `oldpkg/gone.py`.
Ambiguous: `helpers.py`.
Identifier: `process.env`. Shape: `docs/work-items/<slug>.md`. Glob: `memory/project_*.md`.
EOF
git add -A >/dev/null 2>&1; git commit -qm x >/dev/null 2>&1
OUT="$(python3 "$W/deadref.py" CLAUDE.md 2>&1)"

want() { # want <class> <fragment> <why>
  if grep -qE "^$1:.*\b$(printf '%s' "$2" | sed 's/[].[^$\\*/]/\\&/g')\b" <<<"$OUT" \
     || grep -qF -- "$1: CLAUDE.md -> $2 " <<<"$OUT"; then
    printf '  PASS  %-34s %s\n' "$2" "$3"
  else
    printf '  FAIL  %-34s expected %s — %s\n' "$2" "$1" "$3"; FAIL=1
  fi
}
resolves() { grep -qF -- "-> $1 " <<<"$OUT" && { printf '  FAIL  %-34s reported, but it resolves\n' "$1"; FAIL=1; } || printf '  PASS  %-34s resolves silently\n' "$1"; }

# TRUE POSITIVES — the loosenings below must not cost these
want DEAD "docs/ghost.md"       "a dead path under a REAL top-level dir is still a defect"
want DEAD "package.json"        "node_modules must not rescue a missing root manifest (#51's own false negative)"
# THE TWO ADOPTER-REPORTED FALSE-POSITIVE CLASSES
# The four cells. A sibling ON DISK decides; only the neighbourless half falls
# through to CANNOT VERIFY. Adopter-measured: withholding a verdict the run HAS
# is #93's own sentence pointing the other way.
resolves "NeighbourRepo/docs/OVER_THERE.md"
resolves "NeighbourRepo/scripts/present.py"
want DEAD "NeighbourRepo/scripts/ghost.py" "sibling IS on disk and the file is provably absent there — decidable, so decide it"
want "CANNOT VERIFY" "AbsentRepo/scripts/whatever.py" "no sibling on disk — the fall-through, and the only environment-dependent cell"
# Asserts the exposure, not a fix. Guarded, because a git without cone-mode
# sparse-checkout would make this silently vacuous — the failure this whole
# fixture exists to prevent.
if [ -d "$W/SparseRepo" ] && [ ! -e "$W/SparseRepo/scripts" ]; then
  want DEAD "SparseRepo/scripts/upstream_only.py" "KNOWN EXPOSURE: sparse sibling omits the dir; the file exists upstream and reads as dead"
else
  printf '  SKIP  SparseRepo — this git could not produce a sparse checkout, so the exposure case did not run\n'
fi
# ⚠️ CONDITIONAL, and the condition is the point — this passes only because no
# `oldpkg` sibling exists beside the fixture repo. A review found the template
# prose stating this cost FLAT while the sibling rung decides it whenever such
# a sibling is on disk. Both halves are now asserted, so neither can be
# restated unconditionally without a row going red.
want "CANNOT VERIFY" "oldpkg/gone.py"  "KNOWN COST, and only while no sibling of that name is on disk"
mkdir -p "$W/oldpkg"
OUT="$(python3 "$W/deadref.py" CLAUDE.md 2>&1)"
want DEAD "oldpkg/gone.py" "...and the SAME path is decided DEAD once that sibling exists — the cost is conditional"
rmdir "$W/oldpkg"
OUT="$(python3 "$W/deadref.py" CLAUDE.md 2>&1)"
want SKIPPED "process.env"      "filename-shaped token, not a path"
want SKIPPED "memory/project_*.md" "glob"
want SKIPPED "docs/work-items/<slug>.md" "placeholder shape"
want "CANNOT VERIFY" "helpers.py" "two files answer to it — ambiguous, not resolved by iteration order"
# MUST RESOLVE SILENTLY
resolves "docs/real.md"
resolves "notes.md"
resolves "narrative_risk.json"

# The reconciliation line must exist and be internally consistent.
tail1="$(grep -E '^[0-9]+ dead / ' <<<"$OUT")"
[ -n "$tail1" ] || { printf '  FAIL  no reconciliation line — "0 dead" alone cannot be told from an extractor that caught nothing\n'; FAIL=1; }

echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || { echo "SENSITIVITY REGRESSION — do not ship."; printf '%s\n' "$OUT"; }
exit "$FAIL"
