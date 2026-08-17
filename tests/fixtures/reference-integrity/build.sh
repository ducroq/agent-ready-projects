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

rm -rf repo sibling-repo docs
mkdir -p repo/{src/utils,src/models,src/lib,packages/api/config,packages/worker/config,docs,memory,data,.claude/skills,infra,config}
mkdir -p sibling-repo/{scripts,deploy} docs/runbooks

for d in repo sibling-repo docs; do (cd "$d" && git init -q . && git config user.email f@x && git config user.name f); done

cd repo
printf 'data/*\n!data/.gitkeep\n.claude/\n' > .gitignore
touch src/utils/redaction.py src/utils/time_utils.py src/models/temporal.py \
      src/utils/helpers.py src/lib/helpers.py data/.gitkeep docs/ARCHITECTURE.md \
      packages/worker/config/settings.py infra/main.tf config/live.env
echo '{}' > .claude/settings.json
touch ../sibling-repo/scripts/main.py ../sibling-repo/scripts/deploy_thing.sh \
      ../sibling-repo/deploy/main.py ../docs/runbooks/DEPLOY.md

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
echo "$DEST"
