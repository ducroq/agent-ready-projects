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

rm -rf repo sibling-repo docs dupname exitcodes
mkdir -p repo/{src/utils,src/models,src/lib,packages/api/config,packages/worker/config,docs,memory,data,.claude/skills,infra,analysis,config}
mkdir -p sibling-repo/{scripts,deploy,data,shared,docs} docs/runbooks docs/shared

for d in repo sibling-repo docs; do (cd "$d" && git init -q . && git config user.email f@x && git config user.name f); done

cd repo
printf 'data/*\n!data/.gitkeep\n.claude/\n' > .gitignore
touch src/utils/redaction.py src/utils/time_utils.py src/models/temporal.py \
      src/utils/helpers.py src/lib/helpers.py data/.gitkeep docs/ARCHITECTURE.md \
      packages/worker/config/settings.py infra/main.tf analysis/index.qmd config/live.env
# #54/#55/#56 material. `backlog.md` exists in THREE places on purpose: next to
# the doc that references it bare (docs/guides/), in templates/, and under
# packages/ — so a bare basename collides at rung 2 unless the doc-relative rung
# resolves it first, and so a template's placeholder has a suffix twin to be
# wrongly convicted by.
mkdir -p docs/guides templates
touch docs/guides/backlog.md templates/backlog.md packages/api/backlog.md \
      templates/writing-guide.md docs/writing-guide.md \
      docs/guides/review-prompt.md packages/api/review-prompt.md
echo '{}' > .claude/settings.json
touch ../sibling-repo/deploy/rung4_only.sh \
      ../sibling-repo/scripts/main.py ../sibling-repo/scripts/deploy_thing.sh \
      ../sibling-repo/deploy/main.py ../docs/runbooks/DEPLOY.md
# Rung-4 stale-marker material (#73 follow-ups). bare_named.sh and orphan_note.md
# are the same SHAPE — a bare basename next door — and differ only in whether the
# prose names the repo, which is the whole question B3 turns on. The two copies of
# shared/ambiguous_note.md make "which neighbour" unanswerable on purpose.
touch ../sibling-repo/docs/RUNBOOK.md ../docs/runbooks/RUNBOOK.md \
      ../sibling-repo/scripts/bare_named.sh ../docs/runbooks/orphan_note.md \
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
# EVERY candidate sibling must be named in prose. A draft exempted qualified
# paths on the argument that a `/` "carries its own evidence"; measured false —
# 544 qualified relative paths occur in >1 neighbour across 30 repos, headed by
# memory/gotcha-log.md (21) and docs/RUNBOOK.md (8), files this framework tells every
# adopter to create. N22 below pins that regression.
The sibling-repo checkout still carries it and ours was never written:
`deploy/rung4_only.sh` <!-- placeholder -->
It resolves nowhere locally, so rungs 1-2 excuse it and it leaves the checked
set forever. The remedy is to qualify the reference, not to mark it.

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
Both sibling-repo and docs keep a copy in step, and picking whichever sorts first
`shared/ambiguous_note.md` <!-- placeholder -->
is a guess wearing the costume of a fact. Rung 4 already reports a COLLISION
when one neighbour holds two matches; two neighbours holding one each is the
same ambiguity and must not resolve to a single name.

# N22 — a marked QUALIFIED path with no neighbour named must stay excused
This is the shape an adopter writes before creating a file the framework tells
them to create, and the path is common across repos rather than owned by one:
`docs/RUNBOOK.md` <!-- placeholder -->
Nothing here names a checkout, so no neighbour may claim it. Measured on the
real estate, the ungated version reported this in 27 places at once.

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

cat > docs/guides/LINKS.md <<'EOF'
# T23/T24/N23/N24 — markdown links, and doc-relative references

N24: a bare `backlog.md` written here means the file NEXT TO THIS ONE, which is
how the rendered link resolves. Three files in this tree share the basename, so
without a doc-relative rung this is a COLLISION — a defect requiring a decision
when there is nothing to decide.

N23: the house style puts a backticked filename in the link TEXT and the real
path in the URL — [`writing-guide.md`](templates/writing-guide.md). The URL is
the reference; the label is presentation, and extracting it manufactures a
phantom collision. The TWIN at `docs/writing-guide.md` is what makes this case
load-bearing: with only one file of that basename the extracted label resolves
at rung 2 and the case passes against the unfixed checker — measured, and the
first draft of this case did exactly that.

T23: a link whose URL is genuinely broken must still be reported, or masking the
label has removed coverage rather than noise —
[`phantom.md`](docs/does_not_exist_anywhere.md).

T24: a broken path OUTSIDE the brackets must still be extracted, even on a line
that also carries a link: `src/utils/outside_the_brackets.py` next to
[`backlog.md`](templates/backlog.md).

N26 — the regression the first draft of #55 caused, in the direction that hurts
most. Masking the label removed the only backticked token from a struck span, so
the span-scoped skip collector found nothing and a DELIBERATE retirement was
reported as a break. Measured against HEAD, both directions:
~~[`link_gone.py`](src/utils/link_gone.py)~~ was removed; use `src/utils/redaction.py` instead.

N27 — the same regression through the other marker:
**Deleted**: [`dlink_gone.md`](docs/dlink_gone.md)

N28 — and through the third. A placeholder on a link used to produce BOTH a skip
and a `COVERS NO PATH` finding in the same run, which is self-contradictory
output: [`futuredoc.md`](docs/aspirational/futuredoc.md) <!-- placeholder -->

T26 — a ROOT-RELATIVE link must be declined for the right REASON. It used to
report "extension outside the whitelist: .md", and `.md` is whitelisted; the
rejection is the leading slash. Root-relative is the standard GitHub link form,
so it is a wrong message an adopter meets early: [`GUIDE.md`](/docs/ARCHITECTURE.md).

T27 — a link-shaped construct the parser cannot handle drops BOTH label and URL,
so it must at least be counted: [[`nested.md`]](docs/nested.md).

T25 — a link URL the whitelist declines is REPORTED, never dropped. Before this,
the label gave it accidental coverage and masking removed that silently: an
extension outside the whitelist on a file that does not exist appears in neither
the findings nor the extensions-in-tree trailer, which only names extensions the
tree actually holds. [`the report`](out/nonexistent_report.pdf).
EOF

cat > templates/TEMPLATE_CLAUDE.md <<'EOF'
# N25 — a template placeholder in a repo that also ships instances (#56)

Read `review-prompt.md` <!-- placeholder --> — YOUR project's review prompt,
which does not exist here and is not meant to. The path does not resolve AS
WRITTEN from the repo root; it only suffix-matches two unrelated files. Convicting it of being
a stale marker on that evidence left the author no correct move — marked
reported STALE, unmarked reported COLLISION — so the stale test is rung 1 only.
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

# --- X: the exit-status truth table (#93). Self-contained for the same reason
# D1 is: it needs a sibling root that holds NOTHING, and pointing the main
# fixture at one would disarm every rung-4 case in the suite.
#
# The point of the table is that no single row can carry the change. Exit 2 says
# "this run could not decide", and the two ways to get it wrong pull in opposite
# directions — collapse it into 1 and a correct repo fails on its environment;
# collapse it into 0 and a genuine break passes wherever the neighbours happen to
# be absent. Each row below is the other rows' control.
cd "$DEST"
mkdir -p exitcodes/repo/src/dup exitcodes/repo/docs \
         exitcodes/neighbours/sibling-repo/scripts exitcodes/empty
# ⚠️ `exitcodes/repo` is the audited ROOT and is deliberately NOT `git init`ed.
# It sits at `*/*` from $DEST, which is the main run's --sibling-root, so a .git
# here makes it a fourth neighbour of the MAIN fixture — named `repo`, a token
# `_marked_siblings` then finds in 13 lines of that fixture's prose (every
# mention of `sibling-repo`, since a hyphen is a token boundary), sorting ahead
# of the real neighbour in a loop that breaks on the first hit. Measured: the
# main run went from 3 neighbours to 4, and a probe document flipped from a
# reported break to a clean rung-4 resolution. That is the class this file's own
# header records as history. `check()` never requires the root to be a repo.
# The neighbour below is three levels down, which the `*` and `*/*` globs from
# $DEST do not reach.
(cd exitcodes/neighbours/sibling-repo && git init -q . \
   && git config user.email f@x && git config user.name f)
touch exitcodes/repo/src/present.py exitcodes/repo/src/helpers.py \
      exitcodes/repo/src/dup/helpers.py exitcodes/neighbours/sibling-repo/scripts/over_there.sh \
      exitcodes/repo/docs/next_door.md 'exitcodes/repo/docs/<shape>.md'
cat > exitcodes/repo/clean.md <<'EOF'
# clean.md — rows X1/X2
The entry point is `src/present.py` and it resolves as written, at rung 1.
EOF
cat > exitcodes/repo/unresolved.md <<'EOF'
# unresolved.md — rows X3/X4
Nothing on disk answers to `src/nothing_here.py`. Because no repo is named
anywhere near it, rung 4 would decline this reference even with every neighbour
checked out — so with neighbours reachable the verdict is a confirmed break, and
without them it is a reference this run could not decide. Same document, same
byte, two different things to say.
EOF
cat > exitcodes/repo/collision.md <<'EOF'
# collision.md — rows X5/X6
Two files answer to `helpers.py`, so rung 2 reports a collision. Rung 4 has no
bearing on that: the collision is decided inside this repo, and it must keep its
exit status whether or not a neighbour is reachable.
EOF
cat > exitcodes/repo/angle.md <<'EOF'
# angle.md — rows X11/X12
Work items live at `docs/work-items/<slug>.md`, one per initiative. The angle
bracket announces the path as a shape rather than a file, and deciding that
takes a regex over the fragment and nothing on disk — so rung 4 declines it with
every neighbour reachable, and its verdict does not depend on whether any is.
Counting it as undecided sent a repo whose only references are placeholders of
this form from exit 0 to exit 2 in a fresh clone, which is the defect this whole
step is about, one bucket over.
EOF
cat > exitcodes/repo/both.md <<'EOF'
# both.md — rows X13/X14
Work items live at `docs/work-items/<slug>.md` <!-- placeholder -->, one per
initiative. The step says the two marker forms are both needed, so a path
carrying both is the documented case and not a corner. (An earlier version of
this paragraph cited the adopter project file as shipping four such markers;
measured, it ships five markers on four lines and NONE is angle-bracket-shaped.
The case is real, the evidence for it was not. The path is named in words here
rather than written out: this document is INPUT to the extractor, so quoting a
path adds a reference — which is what the first correction did, turning X13 and
X14 red and cascading into every ablation.)
The angle bracket decides this reference by its shape, so a redundant marker
must not turn it into rung-4 traffic. Round 3 tested the marker first and this
went exit 0 with a neighbour and exit 2 without one.
EOF
cat > exitcodes/repo/mixed.md <<'EOF'
# mixed.md — row X15
Two references, deliberately of different kinds. Nothing answers to
`src/absent_for_sure.py`, and it names no neighbour. The deploy script
`scripts/over_there.sh` <!-- placeholder --> lives next door. Two files answer to
`helpers.py`, which rung 2 rules a collision here and now — so with no neighbour
this run has a confirmed defect AND something it could not decide, and the
verdict has to say both. No other row mixes them, so without this one the
undecided half of that sentence can be deleted with the suite still green.
EOF
cat > exitcodes/repo/localmark.md <<'EOF'
# localmark.md — rows X17/X18
The module `present.py` <!-- placeholder --> is marked, and rung 2 answers it
inside this repo: one file in the working tree carries that suffix. A rung that
RAN and resolved the reference decides it, so this row must return the same
status with a neighbour on disk and without one. Round 5 found it returning exit
2 without and exit 0 with, because the marked arm ran rungs 1, 3 and 4 and
skipped 1b and 2 — #93's own defect a third time, in the one direction no row
covered. Unmarked, the identical reference is `fragment -> src/present.py` at
exit 0 in both environments; marking it must not make the run undecidable.

Two files answer to `helpers.py` <!-- placeholder --> here, and that stays
EXCUSED rather than reported: adjudicating a marker on a suffix match is #56,
which left an author shipping a template AND instances of it no correct move.
Deciding it and adjudicating it are different questions.
EOF
cat > exitcodes/repo/docs/docrel.md <<'EOF'
# docs/docrel.md — rows X19/X20
The companion note is `next_door.md` <!-- placeholder -->, and it sits beside
this document. Markdown link semantics ARE doc-relative, so this path resolves
AS WRITTEN and the marker is mislabelled in exactly the sense rung 1 means —
a finding, at exit 1, whether or not a neighbour is reachable. This is the arm
that adjudicates; the rung-2 pair in localmark.md is the arm that does not.

A second reference, `<shape>.md`, carries NO marker and resolves the same way —
a literal file of that name sits beside this document. It is a finding too, but
the WORD has to differ: telling this author to remove a stale placeholder marker
names something that is not in the document. Round 6 found the marker wording
printed for exactly this path.
EOF
cat > exitcodes/repo/marked.md <<'EOF'
# marked.md — rows X8/X9
The deploy script lives over in sibling-repo, not in this tree, so it carries a
marker: `scripts/over_there.sh` <!-- placeholder --> is invoked there. With the
neighbour on disk the marker is STALE and reporting it is the whole of #73. With
no neighbour, the rung-4 stale test cannot run — and excusing the reference then
exits 0 on a repo a reachable neighbour would have reported, which is the
direction Step 4 calls the worse one.
EOF

echo "$DEST"
