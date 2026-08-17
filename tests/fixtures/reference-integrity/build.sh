#!/usr/bin/env bash
# Materialise the reference-integrity fixture into $1 (default: a temp dir).
#
# Every seeded case is labelled T<n> (must be reported) or N<n> (must not be).
# The T cases that matter most are the ones a PERMISSIVE change would newly let
# through — those are the ones a "does it still find the old breaks?" fixture
# misses, which is how v1.15.1's first attempt certified itself.
set -euo pipefail

DEST="${1:-$(mktemp -d)}"
mkdir -p "$DEST"
cd "$DEST"

rm -rf repo sibling-repo docs dupname
mkdir -p repo/{src/utils,src/models,src/lib,packages/api/config,packages/worker/config,docs,memory,data,.claude/skills,infra,analysis,config}
mkdir -p sibling-repo/{scripts,deploy,data,shared} docs/runbooks docs/shared

for d in repo sibling-repo docs; do (cd "$d" && git init -q . && git config user.email f@x && git config user.name f); done

cd repo
printf 'data/*\n!data/.gitkeep\n.claude/\n' > .gitignore
touch src/utils/redaction.py src/utils/time_utils.py src/models/temporal.py \
      src/utils/helpers.py src/lib/helpers.py data/.gitkeep docs/ARCHITECTURE.md \
      packages/worker/config/settings.py infra/main.tf analysis/index.qmd config/live.env
echo '{}' > .claude/settings.json
touch ../sibling-repo/deploy/rung4_only.sh \
      ../sibling-repo/scripts/main.py ../sibling-repo/scripts/deploy_thing.sh \
      ../sibling-repo/deploy/main.py ../docs/runbooks/DEPLOY.md
# Rung-4 stale-marker material (#73 follow-ups). bare_named.sh and orphan_note.md
# are the same SHAPE — a bare basename next door — and differ only in whether the
# prose names the repo, which is the whole question B3 turns on. The two copies of
# shared/ambiguous_note.md make "which neighbour" unanswerable on purpose.
touch ../sibling-repo/scripts/bare_named.sh ../docs/runbooks/orphan_note.md \
      ../sibling-repo/data/pipeline_state.json ../sibling-repo/data/marked_state.json \
      ../sibling-repo/shared/ambiguous_note.md ../docs/shared/ambiguous_note.md

cat > CLAUDE.md <<'EOF'
# Fixture — fragment-convention document
| Component | Invariant |
|---|---|
| `utils/redaction.py` | N1 fragment, house style — enumerated, not a defect |
| `utils/time_utils.py` | N1 |
| `models/temporal.py` | N1 |
| `src/utils/nonexistent_thing.py` | T1 fabricated — must report |
| `helpers.py` | T2 local collision — must report |
| `.claude/skills/imaginary/SKILL.md` | T3 fabricated under gitignored dir — must report |
| `scripts/deploy_thing.sh` | T4 unmarked sibling coincidence — must report |
| `oldpkg/temporal.py` | T5 real move, parent changed — must report |

N2 a feed URL, not a path: `www.example.com/rss.xml`
N3 > **Deleted**: `src/utils/gone.py` — enrichment moved downstream
N5 runtime state: `data/source_states.json`
N6 <!-- verify: ! test -f `src/utils/removed.py` -->
N7 retired but with a live successor on the SAME line:
   ~~`src/utils/old_thing.py`~~ was removed; use `src/utils/redaction.py` instead.
EOF

cat > docs/ADVERSARIAL.md <<'EOF'
# Cases a permissive change newly lets through

T6 in-paragraph coincidence. Output is handed downstream to sibling-repo for
summarising, which is unrelated to the next table row.

| ref | note |
|---|---|
| `scripts/deploy_thing.sh` | T6 — exists only in the sibling and is NOT this repo's file; a proximity marker must not resolve it |

T7 a path that supplies its own cross-repo marker. The local deployment guide
was removed. Nothing in this sentence names a neighbouring repository, so the
only occurrence of the marker token is inside the reference itself:
`docs/DEPLOY.md` — must report, not silently resolve next door.

T8 substring marker. Our `infra/main.tf` is fine, but this reference to
`deploy/main.py` must not be resolved just because the word infrastructure
appears near it.

T9 cross-repo ambiguity. sibling-repo holds two files named main.py, so
`sibling-repo/scripts/main.py` written as `main.py` is a collision there:
`main.py` — must report as ambiguous, not pick one.
EOF

cat > docs/MONOREPO.md <<'EOF'
# T10 — deletion masked by a same-suffix survivor
`packages/api/config/settings.py` was the API's config and has been deleted.
A doc that names it by fragment would suffix-match the worker's surviving
twin. Written as a fragment here: `config/settings.py` — must not be presented
as clean; the enumeration must show which file it actually matched.
EOF

cat > docs/PLACEHOLDERS.md <<'EOF'
# T12/N8/N9 — paths that were never meant to resolve (#45)

Adding an aggregator: copy the template to `src/aggregators/my_new_aggregator.py` <!-- placeholder -->
and register it.

T14: a marker on a line carrying no path at all is an ineffective marker, and
silently doing nothing is the failure mode. <!-- placeholder -->

A work item lives at `docs/work-items/<slug>.md`, and a filter's config at
`filters/<name>/<version>/config.yaml`. Both announce themselves; neither needs
a marker, and neither is a defect.

T12 is the failure this skip newly permits: a marker on a path that DOES
resolve, which is how a real break gets hidden by mislabelling it.
`src/models/temporal.py` <!-- placeholder -->

T13: an angle-bracket path that resolves is the same defect by the other marker.
`src/<real>/exists.py`

T15 — the hiding vector. The marker is span-scoped, so it covers only the path
before it; a genuine break sharing the line must stay a finding:
copy `src/aggregators/another_template.py` <!-- placeholder --> and register it in `src/registry/wire_up.py`.

N11 — and a live reference after a marker must not become a stale-marker
finding: `src/utils/gone_placeholder.py` <!-- placeholder --> superseded by `src/utils/redaction.py`.

N12 — a path whose FIRST character is the angle bracket is the commonest real
form and must be extracted, not invisible: `<slug>.md` and `<root>/memory/MEMORY.md`.

N13 — a document explaining the convention mentions the marker inside backticks:
write `<!-- placeholder -->` on the line. That is a mention, not a use.
EOF
mkdir -p "src/<real>"
printf 'x\n' > "src/<real>/exists.py"

cat > docs/EXOTIC.md <<'EOF'
# T11 — extensions outside the whitelist must not be silently invisible
`infra/nonexistent.tf` and `notebooks/missing.ipynb` are broken references.
If the extractor's whitelist omits their extension they vanish with no report.

# T16 — a Quarto project's own extension
`analysis/missing.qmd` is broken and must be reported. Before `qmd` was
whitelisted this file was invisible, so an adopter whose entire content layer
is `.qmd` got a clean audit that had examined none of it.

`analysis/index.qmd` exists. It must stay silent: widening the whitelist must
add coverage, not turn every real Quarto source into a phantom reference.

# T17 / N15 — `env` is filename-shaped, not extension-shaped (#70)
`config/missing.env` is a genuine broken reference and must stay reported:
the fix for the phantom below must not cost the path form its coverage.
`config/live.env` exists and must stay silent.
`process.env` is a code identifier, not a file. It can never resolve at any
rung, and reporting it is the phantom-reference failure the whitelist exists
to prevent, arriving through the whitelist rather than around it.

# T18 — the marker must reach PAST an identifier to the real path
`config/absent.env` and `process.env` <!-- placeholder -->
The marker is span-scoped and takes the nearest ELIGIBLE path before it. If the
identifier filter is applied only where findings are emitted and not where the
eligible list is built, the marker lands on `process.env`, and the real broken
path beside it silently stays a finding — the two filters must agree.

# T19 — a marker on a path that lives in a SIBLING repo is stale (#73)
# Its own file, NOT T4's `scripts/deploy_thing.sh`: sharing that needle made T4
# satisfied by T19's finding line, so T4 went from live to vacuous. Keep the
# needles of any two cases disjoint.
# The path is QUALIFIED (it has a `/`), which is what lets rung 4 search an
# unnamed sibling at all — a bare basename must be named in prose (#73/B3).
`deploy/rung4_only.sh` <!-- placeholder -->
It resolves nowhere locally, so rungs 1-2 excuse it and it leaves the checked
set forever — but it exists next door. The remedy is to qualify the reference,
not to mark it: a qualified reference is checked on every run.

# N17 — a marker on a path that resolves NOWHERE must stay excused
`src/aggregators/never_anywhere.py` <!-- placeholder -->
EOF

cat > docs/RUNG4.md <<'EOF'
# Cases the unconditional rung-4 walk newly permits (#73 follow-ups)

# T21 — a marked bare basename whose repo IS named must still be reported
The sibling-repo copy is the live one and ours was never written.
`bare_named.sh` <!-- placeholder -->
Naming the neighbour is what makes the claim checkable, so the arm must keep
firing here. This case passes today; its job is to fail if the fix for N18
disables the arm instead of gating it.

# N18 — the same shape with no neighbour named must stay excused
Nothing in these three lines names a checkout next door, so a bare filename
`orphan_note.md` <!-- placeholder -->
is far too weak a token to pin on any one of them. A confident wrong provenance
is worse than a miss: the finding tells the author to qualify the reference
against a repository that has nothing to do with it.

# N19 — a marked path resolving in TWO neighbours must not assert one of them
Both checkouts next door keep a copy in step, and picking whichever sorts first
`shared/ambiguous_note.md` <!-- placeholder -->
is a guess wearing the costume of a fact. Rung 4 already reports a COLLISION
when one neighbour holds two matches; two neighbours holding one each is the
same ambiguity and must not resolve to a single name.

# N20 / T22 — rung 3 still comes before rung 4 when the path is MARKED
`data/pipeline_state.json` is this project's own runtime state. A neighbour
holding a copy does not make the file theirs, and the resolver's own comment
says so: letting a neighbour claim it first produces a provenance that is
simply false. Marked and unmarked must agree about who owns it.
Marked:   `data/marked_state.json` <!-- placeholder -->
# Its OWN path, not the unmarked one above. Sharing it made the counted-section
# assertion satisfiable by the two unmarked occurrences, which are rung-3
# resolutions — so the marked entry could be dropped entirely and nothing failed.
Unmarked: `data/pipeline_state.json`

# N21 — a marker on a dropped identifier must say WHY it covers no path (#70)
We read `process.env` <!-- placeholder --> at startup.
Marking it is the reflex the old phantom taught, so the ineffective-marker
message must name the identifier case. Without that, the reader is sent to hunt
a whitelist gap that is not there.
EOF

cat > memory/MEMORY.md <<'EOF'
# Full-path-convention document
- `src/utils/redaction.py` is the single definition
- `src/models/temporal.py` owns scheduling
- `docs/ARCHITECTURE.md` carries the reasoning
- `src/utils/time_utils.py` for datetimes
- `utils/redaction.py` — N8 fragment in a full-path doc; enumerated either way
EOF

cat > memory/gotcha-log.md <<'EOF'
# Gotchas
### A wrapped cross-repo reference (N4)
**Problem**: sibling-repo's entrypoint moved when
`scripts/main.py` changed. Marked on the line above, so rung 3 applies.
EOF

git add -A >/dev/null && git commit -qm fixture

# --- D1: a self-contained tree where two REACHABLE siblings share a basename.
# Kept out of the main fixture on purpose: with the listing cache keyed on the
# name, seeding the collision in the shared tree would make T4/T9/T19 flake too,
# and a suite that fails at random teaches people to re-run it. Its own root is
# two levels inside $DEST so the sibling glob never reaches the system temp dir.
cd "$DEST"
mkdir -p dupname/shared/b dupname/mid/repo dupname/mid/shared/a
for d in dupname/shared dupname/mid/repo dupname/mid/shared; do
  (cd "$d" && git init -q . && git config user.email f@x && git config user.name f)
done
touch dupname/mid/shared/a/wanted.py dupname/shared/b/unrelated.py
cat > dupname/mid/repo/CLAUDE.md <<'EOF'
# D1 — two reachable neighbours share the basename `shared`
The scorer in the shared checkout is `a/wanted.py`, and we call it every run.
Only one of the two holds it. A listing cache keyed on the neighbour's NAME
collapses them, and because ties in the sort land in hash order the survivor
changes from process to process — so the verdict here changes from run to run.
EOF

echo "$DEST"
