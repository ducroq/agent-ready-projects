#!/usr/bin/env bash
# Sensitivity fixture for curate Step 0.1's dead-reference extractor.
#
# It exists because that extractor shipped TWO false-positive classes in one day,
# both found by adopters running it rather than by any check here: `process.env`
# (a filename-shaped token the sibling step already documents) and qualified
# cross-repo paths (12 dead reported, 0 actually dead). Every class below is one
# that has actually bitten. The 2026-08-28 batch added SIX more, from an adopter
# run whose own repo went `3 dead -> 0 dead`: brace expansion (#104), `[slug]`
# placeholders and `../` fragments resolved one level too high (#106), and THREE
# nobody filed, found by running the reproduction rather than by reading it —
# `./`-prefixed live references, POSIX absolute paths (which reached the
# qualified-sibling rung before the arm written for them and came out DEAD), and
# Windows drive/UNC paths, which got there by another route: no `/` at all, so
# the rung never saw them and the basename lookup found nothing.
# A SEVENTH was found by review rather than by running, and is seeded below: the
# relative arm resolved against the repo root as well as the document, so a stray
# file beside the repo silenced a dead reference (`../stray-outside.md`).
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
for needle in ("DENY", "here = {p.name", "cross-repo", "filename-shaped", "ambiguous",
               "doc-relative", "path on another host"):
    if needle not in prog:
        sys.exit("extracted program is missing %r" % needle)
pathlib.Path(sys.argv[2]).write_text(prog)
PY

mkdir -p "$W/repo/docs" "$W/repo/data" "$W/repo/node_modules/lodash" "$W/repo/memory" \
         "$W/repo/src/a" "$W/repo/src/b" "$W/NeighbourRepo/docs" "$W/NeighbourRepo/scripts" \
         "$W/repo/docs/sub" "$W/repo/scripts/research" "$W/SiblingDir/notes/topics"
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
# ⚠️ `[slug]` is a LITERAL directory name in Next.js and SvelteKit — 4 tracked
# files in one estate repo — so the shape arm must resolve it rather than skip it,
# and the SKIPPED row for `docs/work-items/[slug].md` is its same-arm control.
mkdir -p "$W/repo/app/[slug]" "$W/fakehome/fixture-home-marker"
: > "$W/repo/app/[slug]/page.tsx"
# The `~` RESOLVING branch carries 19 of the 23 real absolute resolutions in the
# estate and had no case at all: asserted under an overridden HOME so the row
# does not depend on the machine's real one.
: > "$W/fakehome/fixture-home-marker/present.md"
# ⚠️ A DIRECTORY whose name carries a file extension. Both new arms have an
# is_dir branch, added by review because `ap == root` could only ever be true of
# the root itself — and that branch shipped with no case, which is the class this
# whole session is about. Reached absolutely (host arm) and doc-relatively.
mkdir -p "$W/repo/docs/bundle.json"
# `SiblingDir` is a sibling DIRECTORY, not a repo — the shape `../SiblingDir/x.md`
# is what a doc in a repo one level down names when it points at one.
# repo one directory down. Both members of the brace pair exist, which is what
# makes the skip a knowing trade rather than a miss: nothing here checks them.
: > "$W/SiblingDir/notes/topics/live.md"
: > "$W/repo/scripts/research/prop1_result_cap25.json"
: > "$W/repo/scripts/research/prop1_result_capoff.json"

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
Brace pair, both members on disk: `scripts/research/prop1_result_{cap25,capoff}.json`.
Brace pair, NEITHER member on disk: `scripts/research/absent_{one,two}.json`.
Square-bracket shape: `docs/work-items/[slug].md`.
Up one, live: `../SiblingDir/notes/topics/live.md`.
Up one, directory on disk and file absent: `../SiblingDir/notes/topics/ghost.md`.
Up one, nothing on disk to decide it: `../NoSuchNeighbour/deep/ghost.md`.
Dot-slash, live: `./docs/real.md`.
Absolute, absent here: `/opt/otherhost/config.json`.
Literal bracketed path, ON DISK: `app/[slug]/page.tsx`.
Home-relative and present under the overridden HOME: `~/fixture-home-marker/present.md`.
Windows drive path: `C:\devroot\project\notes.md`.
Windows UNC path: `\\fileserver\share\spec.md`.
Home-relative, absent: `~/nosuchdir-dead-reference-fixture/elsewhere.md`.
EOF
# An absolute path that IS on this host, so the arm's two branches both run. The
# extractor's pattern excludes whitespace, so a $TMPDIR containing a space puts
# these fragments outside the population. The first version of this guard printed
# a SKIP and then ran the rows anyway — one passed vacuously and two ablations
# went red accusing the extractor. It now actually gates them.
case $W in
  *[[:space:]]*) ABS=0; echo "  SKIP  absolute-path rows and their 2 ablations — \$TMPDIR has whitespace, so the fragments are not extractable";;
  *) ABS=1;;
esac
printf 'Absolute, present here: `%s`.\n' "$W/repo/docs/real.md" >> CLAUDE.md
# Absolute and INSIDE the repo: decidable here, so `path on another host` would be
# a false reason — the kind that sends a reader to the wrong place.
printf 'Absolute, inside this repo, absent: `%s`.\n' "$W/repo/docs/ghost-abs.md" >> CLAUDE.md
printf 'Absolute, and it is a DIRECTORY: `%s`.\n' "$W/repo/docs/bundle.json" >> CLAUDE.md
# ⚠️ A file beside the repo bearing the name a doc-relative fragment resolves to
# inside the tree. Found by review: with the repo root used as a second
# resolution base, this silenced the row below, and no row or ablation noticed.
: > "$W/stray-outside.md"
# A doc that is NOT at the root, so `../` has somewhere to land INSIDE the tree.
cat > docs/sub/sub-doc.md <<'EOF'
Up one, live: `../real.md`.
Up one, inside the tree, resolves nowhere: `../ghost-nearby.md`.
Up one into a directory that does not exist: `../nowhere/ghost.md`.
Up one, absent here but present BESIDE the repo: `../stray-outside.md`.
Up one, and it is a DIRECTORY: `../bundle.json`.
EOF
git add -A >/dev/null 2>&1; git commit -qm x >/dev/null 2>&1
run_ext() { python3 "$W/deadref.py" CLAUDE.md docs/sub/sub-doc.md 2>&1; }
OUT="$(run_ext)"

want() { # want <class> <fragment> <why>
  # The escape set covers every ERE metacharacter, not the eight it had: `{a,b}`
  # was the first input to reach it carrying braces, and on a strict-ERE grep an
  # unescaped `{` is a repeat ERROR on stderr while arm B quietly carries the row
  # to PASS. Measured by a review lens with ugrep 7.8.4.
  if grep -qE "^$1:.*\b$(printf '%s' "$2" | sed 's/[].[^$\\*/|(){}+?]/\\&/g')\b" <<<"$OUT" \
     || grep -qF -- "$1: CLAUDE.md -> $2 " <<<"$OUT"; then
    printf '  PASS  %-34s %s\n' "$2" "$3"
  else
    printf '  FAIL  %-34s expected %s — %s\n' "$2" "$1" "$3"; FAIL=1
  fi
}
# ⚠️ The class alone is not enough. Three of the rows below were DEAD at v1.36.1
# too — with the reason `absent in the sibling ..`, which is #106's own tell — so a
# class-only needle is satisfied by the very mechanism this change removes. That is
# the T12 collision in new dress; these rows pin the reason string.
want_why() { # want_why <class> <doc> <fragment> <reason-substring> <why>
  if grep -qF -- "$1: $2 -> $3 ($4" <<<"$OUT"; then
    printf '  PASS  %-34s %s\n' "$3" "$5"
  else
    printf '  FAIL  %-34s expected %s (%s — %s\n' "$3" "$1" "$4" "$5"; FAIL=1
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
OUT="$(run_ext)"
want DEAD "oldpkg/gone.py" "...and the SAME path is decided DEAD once that sibling exists — the cost is conditional"
rmdir "$W/oldpkg"
OUT="$(run_ext)"
want SKIPPED "process.env"      "filename-shaped token, not a path"
want SKIPPED "memory/project_*.md" "glob"
want SKIPPED "docs/work-items/<slug>.md" "placeholder shape"
# THE 2026-08-28 CLASSES. Every row here was a false DEAD at v1.36.1 — and the
# three DEAD rows further down were false for a DIFFERENT reason there, so they
# assert the reason string too. Class alone would have passed against v1.36.1.
want SKIPPED "scripts/research/prop1_result_{cap25,capoff}.json" "brace expansion is a shape (#104) — members deliberately NOT expanded"
# ⚠️ A CONSTRUCTED case, and the label matters. This fragment's members exist
# nowhere, so the skip hides a genuinely dead reference — that is the class. But
# the class has NO INSTANCE in the estate measured, and a draft of this comment
# claimed two, from a member check that used `(root/member).is_file()` instead of
# the extractor's own ladder. That bare check IS #51's false positive, the one the
# basename rung exists to remove: across 11 brace fragments in 66 directories (51
# git roots), 9 not already skipped by `<` or `*`, every member of every
# comma-brace fragment RESOLVES through the real ladder. Measured cost: nil.
# So expansion stays correct-but-unprioritised (#121) rather than urgent, and this
# row asserts the current disposition on a case built by hand. It goes red if
# someone implements expansion.
want SKIPPED "scripts/research/absent_{one,two}.json" "KNOWN COST: no member exists and the skip hides it (#121)"
want SKIPPED "docs/work-items/[slug].md" "the third placeholder convention in this framework's own templates (#106)"
resolves "../SiblingDir/notes/topics/live.md"
resolves "./docs/real.md"
resolves "app/[slug]/page.tsx"   # a shape that is also a real file: decided, not skipped
want_why DEAD CLAUDE.md "../SiblingDir/notes/topics/ghost.md" "relative path outside the tree, and the directory it names IS on disk" "leaves the tree, directory on disk — and NOT via the sibling rung, which is what v1.36.1 did"
want "CANNOT VERIFY" "../NoSuchNeighbour/deep/ghost.md" "leaves the tree with nothing on disk to decide it — quiet, not a false DEAD"
want "CANNOT VERIFY" "/opt/otherhost/config.json" "absolute and absent: another host, NOT a sibling of this repo"
[ "$ABS" = 1 ] && want_why DEAD CLAUDE.md "$W/repo/docs/ghost-abs.md" "absolute path inside this repo" "absolute and INSIDE the repo — decidable, so decided, and the reason says so"
[ "$ABS" = 1 ] && want_why "CANNOT VERIFY" CLAUDE.md "$W/repo/docs/bundle.json" "names a directory, not a file" "a directory is not a dead FILE reference — and it is inside the repo, so the branch above would have called it DEAD" "absolute and INSIDE the repo — decidable, so decided, and the reason says so"
[ "$ABS" = 1 ] && resolves "$W/repo/docs/real.md"   # absolute and PRESENT: a verdict the run has, so it gives it
want "CANNOT VERIFY" "C:\devroot\project\notes.md" "a Windows drive path is the same claim in other dress — and reached DEAD by another route"
want "CANNOT VERIFY" '\\fileserver\share\spec.md' "UNC, same class"
want "CANNOT VERIFY" "~/nosuchdir-dead-reference-fixture/elsewhere.md" "home-relative and absent: another host"
want "CANNOT VERIFY" "~/fixture-home-marker/present.md" "absent under the REAL home — the same fragment resolves under the overridden one below"
OUT_REAL="$OUT"; OUT="$(HOME="$W/fakehome" run_ext)"
# ⚠️ A POSITIVE first. `resolves` passes on ABSENCE, so with only that row an
# empty capture — a crash, a typo in the override, an arg-list change to
# run_ext — reads exactly like success. A lens proved it by replacing this
# capture with a command that emits nothing: the suite stayed green.
want "CANNOT VERIFY" "/opt/otherhost/config.json" "the fakehome capture produced real output at all"
resolves "~/fixture-home-marker/present.md"    # expanduser, exercised on a RESOLVING input
OUT="$OUT_REAL"
want_why DEAD docs/sub/sub-doc.md "../ghost-nearby.md" "doc-relative and resolves nowhere" "doc-relative INSIDE the tree — the near side of the cross-repo trade"
want_why DEAD docs/sub/sub-doc.md "../nowhere/ghost.md" "doc-relative and resolves nowhere" "inside the tree, enclosing dir absent — still decidable, so still DEAD"
want_why DEAD docs/sub/sub-doc.md "../stray-outside.md" "doc-relative and resolves nowhere" "a stray file BESIDE the repo must not resolve a doc-relative reference"
want_why "CANNOT VERIFY" docs/sub/sub-doc.md "../bundle.json" "names a directory, not a file" "same rule in the doc-relative arm, where it would otherwise be inside-the-tree DEAD"
want "CANNOT VERIFY" "helpers.py" "two files answer to it — ambiguous, not resolved by iteration order"
# MUST RESOLVE SILENTLY
resolves "docs/real.md"
resolves "../real.md"     # from the non-root doc: doc-relative and live
resolves "notes.md"
resolves "narrative_risk.json"

# ── ABLATIONS ────────────────────────────────────────────────────────────────
# Every row above was green at v1.36.1 too — for the four rows this session
# added, because they did not exist. *Could this assertion have failed?* is
# answered by running, not by reading (curate Step 0 sub-step 5), so each new
# arm is deleted in turn and the row it protects must go red. A mutant must be
# LETHAL to its own row and leave the control STANDING: one that disables the
# whole extractor proves nothing, which is lint rule 10's class.
mutate() { # mutate <old> <new> -> $W/mut.py
  python3 - "$W/deadref.py" "$W/mut.py" "$1" "$2" <<'MPY'
import sys, pathlib
src, dst, old, new = sys.argv[1:5]
s = pathlib.Path(src).read_text()
if s.count(old) != 1:
    sys.exit("appears %d times, not once" % s.count(old))
pathlib.Path(dst).write_text(s.replace(old, new))
MPY
}
ablate() { # ablate <label> <old> <new> <must-appear | !must-not-appear> <control>
  local why
  why="$(mutate "$2" "$3" 2>&1)" || {
    printf '  FAIL  ABLATION %-24s could not apply (%s) — a mutant that does not mutate\n' "$1" "$why"
    FAIL=1; return; }
  # `grep -qF -- ''` matches everything, so an empty pattern reports every mutant
  # lethal. One call already passes '' one position earlier (as the replacement),
  # so an argument slip lands here silently. Measured by a review lens.
  [ -n "${4#\!}" ] || { printf '  FAIL  ABLATION %-24s empty pattern — this row cannot fail\n' "$1"; FAIL=1; return; }
  local out lethal=0; out="$(run_mut)"
  if [ "${4#\!}" != "$4" ]; then
    grep -qF -- "${4#\!}" <<<"$out" || lethal=1
  else
    grep -qF -- "$4" <<<"$out" && lethal=1
  fi
  if [ "$lethal" -eq 0 ]; then
    printf '  FAIL  ABLATION %-24s mutant changed nothing — the row it guards cannot fail\n' "$1"; FAIL=1
  elif ! grep -qF -- "$5" <<<"$out"; then
    printf '  FAIL  ABLATION %-24s mutant killed the control too — kills too much to prove anything\n' "$1"; FAIL=1
  else
    printf '  PASS  ABLATION %-24s lethal to its own row, control survives\n' "$1"
  fi
}
MUT_HOME=""
run_mut() {
  if [ -n "$MUT_HOME" ]; then HOME="$MUT_HOME" python3 "$W/mut.py" CLAUDE.md docs/sub/sub-doc.md 2>&1
  else python3 "$W/mut.py" CLAUDE.md docs/sub/sub-doc.md 2>&1; fi
}
GHOST='DEAD: CLAUDE.md -> docs/ghost.md'
# ⚠️ The control is in the SAME ARM wherever one can be: a control from another
# arm can only die if the mutant crashes, so it gates whole-EXTRACTOR damage and
# not whole-arm damage. Deleting a whole arm turns several case rows red — that is
# what those rows are for; the control is not doing that work.
ablate quarantine-loses-brace "'<*{['" "'<*'" \
  'DEAD: CLAUDE.md -> scripts/research/prop1_result_{cap25,capoff}.json' \
  'SKIPPED: CLAUDE.md -> memory/project_*.md'
ablate quarantine-loses-bracket "'<*{['" "'<*{'" \
  'DEAD: CLAUDE.md -> docs/work-items/[slug].md' \
  'SKIPPED: CLAUDE.md -> scripts/research/prop1_result_{cap25,capoff}.json'
# The shape arm's own resolving branch, added because `[slug]` is a real directory
# name; its control is the shape that is NOT on disk.
ablate shape-arm-never-resolves 'if (root / frag).is_file() or (d.parent / frag).is_file(): ok += 1; continue' \
  'if False: ok += 1; continue' \
  'SKIPPED: CLAUDE.md -> app/[slug]/page.tsx' \
  'SKIPPED: CLAUDE.md -> docs/work-items/[slug].md'
# Reproduces #106's reported line VERBATIM, including the tell in its reason.
ablate relative-arm-deleted "if frag.split('/')[0] in ('.', '..'):" "if False:" \
  'DEAD: CLAUDE.md -> ../SiblingDir/notes/topics/live.md (absent in the sibling ..' "$GHOST"
# The arm exists AND precedes the rung; deleting it puts absolutes back in DEAD.
ablate host-arm-deleted "if frag.startswith(('/', '~')) or re.match(r'[A-Za-z]:[\\\\/]|\\\\\\\\', frag):" "if False:" \
  'DEAD: CLAUDE.md -> /opt/otherhost/config.json' "$GHOST"
# The other direction: the relative arm must not become a blanket excuse.
ablate relative-arm-always-live 'if rp.is_file(): ok += 1; continue' 'if True: ok += 1; continue' \
  '!DEAD: docs/sub/sub-doc.md -> ../ghost-nearby.md' "$GHOST"
# Inside the tree there is nothing to withhold a verdict FOR — and the control
# here is the sibling row that stays DEAD by the escape gate instead.
ablate inside-tree-branch-deleted 'if root in rp.parents:' 'if False:' '!DEAD: docs/sub/sub-doc.md -> ../nowhere/ghost.md' \
  'DEAD: docs/sub/sub-doc.md -> ../ghost-nearby.md'
# The host arm's resolving branch: four real repos depend on it.
[ "$ABS" = 1 ] && ablate host-arm-never-resolves 'if ap.is_file(): ok += 1' 'if False: ok += 1' \
  "DEAD: CLAUDE.md -> $W/repo/docs/real.md" \
  'CANNOT VERIFY: CLAUDE.md -> /opt/otherhost/config.json'
# The in-repo branch: without it an absolute path inside this repo is quarantined
# under a reason that is simply false.
[ "$ABS" = 1 ] && ablate host-arm-loses-inrepo 'elif root in ap.parents:' 'elif False:' \
  "CANNOT VERIFY: CLAUDE.md -> $W/repo/docs/ghost-abs.md" \
  'CANNOT VERIFY: CLAUDE.md -> /opt/otherhost/config.json'
# expanduser, ablated under the overridden HOME — the only way this branch is
# reachable at all.
MUT_HOME="$W/fakehome"
ablate host-arm-no-expanduser 'os.path.expanduser(frag)' 'frag' \
  "CANNOT VERIFY: CLAUDE.md -> ~/fixture-home-marker/present.md" \
  'CANNOT VERIFY: CLAUDE.md -> /opt/otherhost/config.json'
MUT_HOME=""
ablate host-arm-loses-windows "or re.match(r'[A-Za-z]:[\\\\/]|\\\\\\\\', frag)" '' \
  'DEAD: CLAUDE.md -> C:\devroot\project\notes.md' "$GHOST"
[ "$ABS" = 1 ] && ablate host-arm-loses-isdir "elif ap.is_dir():" "elif False:" \
  "DEAD: CLAUDE.md -> $W/repo/docs/bundle.json" \
  'CANNOT VERIFY: CLAUDE.md -> /opt/otherhost/config.json'
ablate relative-arm-loses-isdir "if rp.is_dir():" "if False:" \
  'DEAD: docs/sub/sub-doc.md -> ../bundle.json' \
  'DEAD: docs/sub/sub-doc.md -> ../ghost-nearby.md'
# Reintroduces the reviewed-out defect exactly: the repo root as a second base.
ablate relative-arm-root-base 'if rp.is_file(): ok += 1; continue' \
  'if rp.is_file() or Path(os.path.normpath(root / frag)).is_file(): ok += 1; continue' \
  '!DEAD: docs/sub/sub-doc.md -> ../stray-outside.md' 'DEAD: docs/sub/sub-doc.md -> ../ghost-nearby.md'
ablate escape-gate-always-decides 'if rp.parent.is_dir():' 'if True:' \
  'DEAD: CLAUDE.md -> ../NoSuchNeighbour/deep/ghost.md' \
  'CANNOT VERIFY: CLAUDE.md -> /opt/otherhost/config.json'

# ⚠️ OUTSIDE A GIT REPO the root falls back to `.`, and `Path('.')` is a parent of
# `../x.md` — so without `.resolve()` every missing `../` fragment read as inside
# the tree and was decided DEAD, in a directory that has no tree. Asserted both
# ways, because the fix is one word and nothing else here would notice its loss.
mkdir -p "$W/nongit"; cp CLAUDE.md "$W/nongit/CLAUDE.md"
# Guarded like the SparseRepo row: with $TMPDIR inside a git working tree there is
# no non-git directory to test in, and both rows below would go red accusing the
# extractor of a defect it does not have.
if git -C "$W/nongit" rev-parse --show-toplevel >/dev/null 2>&1; then
  printf '  SKIP  non-git rows — $TMPDIR is inside a git working tree, so there is no non-git case here\n'
else
NG="$(cd "$W/nongit" && python3 "$W/deadref.py" CLAUDE.md 2>&1)"
if grep -qF -- 'CANNOT VERIFY: CLAUDE.md -> ../NoSuchNeighbour/deep/ghost.md' <<<"$NG"; then
  printf '  PASS  %-34s undecided outside a git repo, not DEAD\n' "non-git ../"
else
  printf '  FAIL  %-34s expected CANNOT VERIFY outside a git repo\n' "non-git ../"; FAIL=1
fi
if why="$(mutate "or '.').resolve()" "or '.')" 2>&1)"; then
  NGM="$(cd "$W/nongit" && python3 "$W/mut.py" CLAUDE.md 2>&1)"
  if grep -qF -- 'DEAD: CLAUDE.md -> ../NoSuchNeighbour/deep/ghost.md' <<<"$NGM"; then
    printf '  PASS  ABLATION %-24s without .resolve() the same reference is DEAD\n' "nongit-root-unresolved"
  else
    printf '  FAIL  ABLATION %-24s dropping .resolve() changed nothing\n' "nongit-root-unresolved"; FAIL=1
  fi
else
  printf '  FAIL  ABLATION %-24s could not apply (%s)\n' "nongit-root-unresolved" "$why"; FAIL=1
fi
fi

# The reconciliation line must exist. It is NOT checked for internal consistency
# — the comment claimed that for four releases while only `-n` was ever tested;
# asserting the sum needs a second, independent fragment count.
tail1="$(grep -E '^[0-9]+ dead / ' <<<"$OUT")"
[ -n "$tail1" ] || { printf '  FAIL  no reconciliation line — "0 dead" alone cannot be told from an extractor that caught nothing\n'; FAIL=1; }

echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || { echo "SENSITIVITY REGRESSION — do not ship."; printf '%s\n' "$OUT"; }
exit "$FAIL"
