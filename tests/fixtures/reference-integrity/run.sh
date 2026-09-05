#!/usr/bin/env bash
# Sensitivity harness for audit-context Step 4.
#
# Any change that makes Step 4 more permissive must still report every seeded
# case below. Run this BEFORE and AFTER such a change and compare.
set -euo pipefail
cd "$(dirname "$0")"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
bash build.sh "$WORK" >/dev/null

DOCS="CLAUDE.md docs/ADVERSARIAL.md docs/MONOREPO.md docs/EXOTIC.md docs/PLACEHOLDERS.md docs/RUNG4.md docs/guides/LINKS.md templates/TEMPLATE_CLAUDE.md memory/MEMORY.md memory/gotcha-log.md docs/REMEDY.md"
# --sibling-root pins the search to the fixture. Without it the search
# reaches the system temp dir and adopts stray repos, including fixtures
# left behind by an interrupted run of this harness.
OUT="$(python3 refcheck.py --sibling-root "$WORK" "$WORK/repo" $DOCS || true)"
FINDINGS="$(printf '%s' "$OUT" | sed -n '/== FINDINGS/,/^  total:/p')"

# Each seeded break, and the substring that proves it was reported.
declare -a CASES=(
  "T1 fabricated path|src/utils/nonexistent_thing.py"
  "T2 local basename collision|helpers.py"
  "T3 fabricated under gitignored dir|.claude/skills/imaginary/SKILL.md"
  "T4 unmarked sibling coincidence|scripts/deploy_thing.sh"
  "T5 real move, parent changed|oldpkg/temporal.py"
  "T7 path supplies its own marker|docs/DEPLOY.md"
  "T8 substring marker must not mark|deploy/main.py"
  # Needle is the REASON (#116): `main.py` alone also matched
  # `deploy/main.py UNRESOLVED` and `main.py UNRESOLVED`, so the collision arm
  # could break and T9 would still pass on someone else's finding.
  "T9 ambiguous inside sibling|COLLISION (2 matches in sibling-repo)"
  "T10 deletion with surviving twin|packages/api/config/settings.py"
  "T11 unlisted extension .tf|infra/nonexistent.tf"
  "T11 unlisted extension .ipynb|notebooks/missing.ipynb"
  # #69 — the whitelist is a denominator. A repo whose PRIMARY source extension
  # is missing gets a clean audit having extracted nothing, and the instrument's
  # own "extensions not extracted" line reads as trivia under a zero.
  "T16 fabricated .qmd is caught|analysis/missing.qmd"
  # #70 — the loss this tightening could cause. `env` keeps its coverage for
  # the path form; only the identifier shape is dropped.
  "T17 broken .env with a directory is still caught|config/missing.env"
  # #73 — the stale-marker arm was rung 1-2 only, so a marker on a path that
  # exists in a SIBLING repo could never be reported and was excused forever.
  # The needle is the REASON, not the path. Asserting only the path passed with
  # the rung-4 arm reverted, because the marker then failed to attach and the
  # path was reported UNRESOLVED — a finding, for the wrong reason. Caught by
  # ablation; a positive that cannot distinguish why it fired is not a test.
  "T19 stale marker resolving at rung 4|STALE PLACEHOLDER MARKER (resolves at rung 4: sibling sibling-repo -> deploy/rung4_only.sh)"
  # The other direction of N18's gate. Same shape — a bare basename living next
  # door — but the prose NAMES the neighbour, so the claim is checkable and must
  # still be reported. Passes today; it exists to fail if the fix for N18 turns
  # the arm off rather than gating it.
  # Needle is the REASON, per T19's lesson: asserting the path alone would also
  # be satisfied by an UNRESOLVED finding if the marker failed to attach.
  "T21 marked bare basename WITH the neighbour named|STALE PLACEHOLDER MARKER (resolves at rung 4: sibling sibling-repo -> scripts/bare_named.sh)"
  # #45 — the failure the placeholder skip newly permits: a marker on a path
  # that resolves. Mislabelling must not become a way to hide a real break.
  # ⚠️ Needles are the REASONS, not the paths — #116. Until 2026-09-05 both
  # asserted only their path, so ANY other seeded case referencing the same file
  # satisfied them and the row went vacuous without the suite noticing. That was
  # measured on the withdrawn #76 branch: a second document naming
  # src/models/temporal.py made T12 pass under the very ablation it exists to
  # fail. FIFTH instance of this collision in this fixture. The two reasons are
  # distinguishable because the arm emits different text for a real marker than
  # for a bare placeholder SHAPE, and both differ from T19/T21's rung 4.
  "T12 stale placeholder marker on a resolving path|STALE PLACEHOLDER MARKER (resolves at rung 1"
  "T13 stale angle-bracket marker on a resolving path|PLACEHOLDER SHAPE THAT RESOLVES (resolves at rung 1"
  "T14 placeholder marker covering no path|COVERS NO PATH"
  # #102 — the remedy a rung-4 finding prints must work when followed. T28 is
  # the shape an author writes when the remedy says only "qualify it instead":
  # the repo name sits inside the path, and bullet 5 forbids a reference from
  # marking itself, so it does NOT resolve. Measured before the fix: an author
  # who applied the printed remedy literally saw the same finding count, the row
  # changing only from STALE PLACEHOLDER MARKER to UNRESOLVED.
  # ⚠️ These two needles are PATHS, and T21's "needle is the reason" rule cannot
  # be applied here — measured twice. The oracle prints `UNRESOLVED` for both
  # "the gate declined it" and "the target is not there", so no reason string
  # separates them; and a needle carrying the reason is keyed on the report's
  # COLUMN PADDING, which moves with the path's length (T29 failed on exactly
  # that, three spaces versus four). The discriminator is an existence check on
  # the target files instead — see the block below. #116 is the same shape one
  # fixture over, and this is the case where a better needle is not the answer.
  "T28 the qualified path alone does not resolve|remedy_unqualified.sh"
  # The backtick trap. A repo name inside backticks is stripped with every other
  # span, so it does not mark the reference and the author who followed the
  # advice in house style still gets a finding. Pinned so the "every span"
  # wording in the step cannot quietly revert to "the paths".
  "T29 a backticked repo name does not mark the reference|remedy_backticked.sh"
  # The hiding vector the issue demanded be seeded: line-scoping relabelled a
  # co-located genuine break as intentional. The marker is span-scoped, so this
  # must stay a finding.
  "T15 unmarked break sharing a marked line|src/registry/wire_up.py"
  # #55 — the loss the label-masking could cause. Before the fix, a broken link
  # URL was covered only BY ACCIDENT, because the label happened to name the
  # same missing file and was reported UNRESOLVED. Masking the label without
  # extracting the URL would have removed that coverage silently, which is the
  # seeded-true-positives rule applied to a change that is a loosening on one
  # side and a widening on the other.
  "T23 a broken markdown link URL is still reported|docs/does_not_exist_anywhere.md"
  # #55 over-reach guard: a backticked path that merely SITS NEAR a link is
  # still a reference. Only the span inside the brackets is a label.
  # DELIBERATELY INERT against the unfixed checker — it passes before and after,
  # because it is a CONTROL, not a regression test: its job is to go red if the
  # masking ever widens past the brackets. Measured alongside the other four,
  # which do each fail against the pre-fix oracle.
  "T24 a broken path outside the brackets is still extracted|src/utils/outside_the_brackets.py"
)
# Must NOT appear in findings.
declare -a NEG=(
  "N2 hostname is not a path|www.example.com/rss.xml"
  "N3 prose deletion marker|src/utils/gone.py"
  "N6 negated existence assertion|src/utils/removed.py"
  "N7 struck path on a live line|src/utils/old_thing.py"
  "N8 marked instructional placeholder|src/aggregators/my_new_aggregator.py"
  "N9 self-announcing angle-bracket path|docs/work-items/<slug>.md"
  "N10 angle-bracket path, second form|filters/<name>/<version>/config.yaml"
  "N11 live path after a marker is not a stale marker|src/utils/redaction.py"
  "N12 leading angle bracket is extracted, not invisible|<root>/memory/MEMORY.md"
  # The other half of #102, and the row that makes the corrected remedy a
  # measurement rather than a claim: qualified path AND the repo named in the
  # prose around it must RESOLVE. If this starts reporting, the remedy the step
  # prints has become wrong again.
  "N32 qualified path WITH the repo named in prose resolves|sibling-repo/scripts/remedy_qualified.sh"
  # The failure #69's widening newly permits: every real .qmd becoming a
  # phantom. Adding an extension must buy coverage, not noise.
  "N14 a resolving .qmd stays silent|analysis/index.qmd"
  # #70 — the phantom itself. No rung can resolve `process.env`; it is not a file.
  "N15 process.env is an identifier, not a path|process.env"
  "N15b a resolving .env with a directory stays silent|config/live.env"
  # #70/T18 — with the marker correctly reaching past the identifier, this is
  # placeheld rather than reported. Fails if only the findings loop is filtered.
  "N16 marker reaches past an identifier to the real path|config/absent.env"
  # #73's other direction: extending the arm to rung 4 must not start reporting
  # markers on paths that genuinely resolve nowhere.
  "N17 marker on a path absent everywhere stays excused|src/aggregators/never_anywhere.py"
  # N22 — the regression the qualified-path exemption caused. A marked path that
  # is common across repos, with no neighbour named, must not be claimed by one.
  "N22 marked qualified path, no neighbour named, stays excused|docs/RUNBOOK.md"
  # #73 — the unconditional walk drops rung 4's prose-naming gate, so a bare
  # basename gets pinned on whichever neighbour sorts first. Measured on an
  # adopter: one adopter's own `principes.md` was attributed to an unrelated
  # house-renovation repo, with instructions to qualify the reference against
  # it. A confident wrong provenance is worse than a miss.
  "N18 marked bare basename with NO neighbour named stays excused|orphan_note.md"
  # #73 — the marked arm runs before rung 3, so a file THIS repo's runtime
  # writes gets claimed by a neighbour that happens to hold a copy. The
  # resolver's own comment forbids exactly this ordering.
  "N20 marked runtime state is not a neighbour's file|data/marked_state.json"
  # #55 — the phantom itself. The better a document follows this framework's own
  # recommended link style, the more of these it used to generate.
  "N23 a markdown link label is not a reference|writing-guide.md"
  # #54 — 41% of the findings on one adopter repo were this: a correct
  # doc-relative reference downgraded to a collision against a same-named file
  # elsewhere in the tree.
  "N24 a doc-relative reference resolves|backlog.md"
  # #56 — a template placeholder in a repo that also ships instances of the
  # template. With the suffix arm in the stale test, marked reported STALE and
  # unmarked reported COLLISION: two findings, no defect, and no correct move
  # available to the author. Its own basename, not shared with N23/N24, because
  # this fixture has been bitten three times by one case being satisfied by
  # another case's output.
  "N25 a template placeholder with a suffix twin stays excused|review-prompt.md"
  # #55 round 2 — the three regressions label-masking caused, found by a review
  # running the change against seeded spans rather than by the suite, which was
  # green throughout. Masking removed the only backticked token from a marked
  # span, so all three span-scoped skips stopped covering a markdown link.
  "N26 a STRUCK markdown link stays suppressed|link_gone.py"
  "N27 a **Deleted** markdown link stays suppressed|dlink_gone.md"
  "N28 a placeholder on a markdown link covers it|futuredoc.md"
)

FAIL=0

# #116 — a needle that matches MORE THAN ONE reported line cannot distinguish its
# own subject from someone else's finding, so the row passes while testing
# nothing and no ablation can kill it. That has happened FIVE times in this
# fixture, always the same way: a later case reuses a path an earlier row
# asserted. Exact-duplicate needles are the degenerate case; the live one is a
# needle satisfied by a second finding, which is why the match is COUNTED and
# not just tested.
#
# ⚠️ A first draft of this comment claimed "every needle matching exactly once".
# That was never measured — only exact duplicates were (0 of 23) — and this
# guard refuted it on its first run: T4, T9 and T14 each matched several
# findings. T9 was fixed by switching to its reason string. T4 and T14 cannot
# be: their extra matches are the SAME reason reported from a different seeded
# document, and a doc-qualified needle would be keyed on the report's column
# padding, which moves with path length (T29 failed on exactly that). They are
# DECLARED below rather than silently tolerated — the rule-11 principle, an
# exemption is declared, not guessed.
#
# What a declared row still buys: nothing, for that row's discrimination. It is
# a marker saying "known weak", so the next person does not rediscover it as
# instance nine.
declare -A SEEN_NEEDLE=()
for c in "${CASES[@]}"; do
  name="${c%%|*}"; needle="${c##*|}"
  if [ -n "${SEEN_NEEDLE[$needle]:-}" ]; then
    printf '  FAIL  %s shares a needle with %s — one of them tests nothing\n' \
      "$name" "${SEEN_NEEDLE[$needle]}"; FAIL=1
  fi
  SEEN_NEEDLE[$needle]="$name"
done

for c in "${CASES[@]}"; do
  name="${c%%|*}"; needle="${c##*|}"
  hits=$(printf '%s' "$FINDINGS" | grep -cF -- "$needle" || true)
  case "$name" in
    # DECLARED weak needles — see the note above. Same reason string, different
    # seeded document; no discriminating needle exists that is not padding-keyed.
    "T4 unmarked sibling coincidence"|"T14 placeholder marker covering no path")
      if [ "$hits" -ge 1 ]; then
        printf '  PASS  %s (needle matched %s — DECLARED weak, #116)\n' "$name" "$hits"
      else
        printf '  FAIL  %s (expected a finding for %s)\n' "$name" "$needle"; FAIL=1
      fi
      continue ;;
  esac
  if [ "$hits" -eq 1 ]; then
    printf '  PASS  %s\n' "$name"
  elif [ "$hits" -eq 0 ]; then
    printf '  FAIL  %s (expected a finding for %s)\n' "$name" "$needle"; FAIL=1
  else
    printf '  FAIL  %s: needle matched %s findings — it cannot distinguish its own subject (#116)\n' \
      "$name" "$hits"; FAIL=1
  fi
done
for c in "${NEG[@]}"; do
  name="${c%%|*}"; needle="${c##*|}"
  if printf '%s' "$FINDINGS" | grep -qF -- "$needle"; then
    printf '  FAIL  %s (must NOT be a finding: %s)\n' "$name" "$needle"; FAIL=1
  else printf '  PASS  %s\n' "$name"; fi
done

# N28b — the other half of N28: the same marker used to emit a skip AND a
# `COVERS NO PATH` finding in one run. It cannot be a plain NEG entry, because
# T14 seeds a LEGITIMATE `COVERS NO PATH` and the bare string would be satisfied
# by T14's output — a needle collision, the failure this fixture has hit three
# times before. Scope it to the file the covered link lives in.
if printf '%s' "$FINDINGS" | grep -F 'COVERS NO PATH' | grep -qF 'LINKS.md'; then
  printf '  FAIL  N28b — a placeholder that DOES cover a link still reported COVERS NO PATH\n'; FAIL=1
else printf '  PASS  N28b no phantom COVERS NO PATH on a covered link\n'; fi

# T25 — a declined link URL must be REPORTED, not dropped. It is not a FINDING
# (the checker did not resolve it, so it cannot claim it is broken); it is a
# stated non-check, and the whole point is that it is visible. Asserted against
# its own section rather than against FINDINGS, and the REASON is the needle:
# the path alone would also match a run that reported it for the wrong cause.
if printf '%s' "$OUT" | sed -n '/== LINK URLs NOT CHECKED/,/^  total:/p' \
     | grep -qF 'extension outside the whitelist: .pdf'; then
  printf '  PASS  T25 a declined link URL is reported with its reason\n'
else printf '  FAIL  T25 — a link URL outside the whitelist was dropped silently\n'; FAIL=1; fi

# T26/T27 — the two shapes the second review round found dropped or misdiagnosed.
# Needles are the REASONS, per T19's lesson: the path alone would also be
# satisfied by a report for the wrong cause.
if printf '%s' "$OUT" | sed -n '/== LINK URLs NOT CHECKED/,/^  total:/p' | grep -q 'root-relative'; then
  printf '  PASS  T26 a root-relative link is declined for the right reason\n'
else printf '  FAIL  T26 — a root-relative link was misdiagnosed as a whitelist gap\n'; FAIL=1; fi
if printf '%s' "$OUT" | sed -n '/== LINK URLs NOT CHECKED/,/^  total:/p' | grep -q 'NOT PARSED'; then
  printf '  PASS  T27 an unparseable link-shaped construct is counted, not dropped\n'
else printf '  FAIL  T27 — a link the parser cannot read vanished silently\n'; FAIL=1; fi

# N7's live successor must survive the strikethrough on the same line.
if printf '%s' "$OUT" | grep -q "old_thing.py.*asserted-absent"; then
  printf '  PASS  N7 struck path skipped, successor kept\n'
else printf '  FAIL  N7 strikethrough handling\n'; FAIL=1; fi

# N13 cannot be a needle test: T14 legitimately emits the same string, so
# "absent" is unassertable. Count instead. TWO ineffective markers are seeded and
# both are meant to be reported — T14, a marker with no path at all, and N21, a
# marker whose only neighbour is a token the extractor deliberately drops — so a
# marker MENTIONED inside backticks (any doc explaining the convention, including
# the shipped step itself) must not make it three.
N_INEFFECTIVE="$(printf '%s' "$FINDINGS" | grep -c 'COVERS NO PATH' || true)"
if [ "$N_INEFFECTIVE" -eq 2 ]; then
  printf '  PASS  N13 a mentioned marker is not a used one (2 ineffective markers, not 3)\n'
else
  printf '  FAIL  N13 expected exactly 2 COVERS NO PATH findings, got %s — a marker inside backticks is being read as a marker in use\n' "$N_INEFFECTIVE"; FAIL=1
fi

# N21 — #70's phantom returns in a new costume for the population most likely to
# have marked `process.env` to silence it: the marker now covers nothing, and the
# message lists four causes, none of them the real one. Naming the cause is the
# whole value of an ineffective-marker report; without it the reader hunts a
# whitelist gap that is not there.
if printf '%s' "$FINDINGS" | grep -F 'COVERS NO PATH' | grep -qi 'identifier'; then
  printf '  PASS  N21 the ineffective-marker message names the identifier cause\n'
else
  printf '  FAIL  N21 no COVERS NO PATH finding mentions an identifier — the reader is sent to hunt a whitelist gap that is not there\n'; FAIL=1
fi

# N19 — two neighbours hold the same path, so "which one" has no answer. Rung 4
# already reports a COLLISION when ONE neighbour holds two matches; two holding
# one each is the same ambiguity. Assert the shape of the wrong answer rather
# than the right one, so this survives a rewording of the ambiguous case.
for wrong in "sibling sibling-repo -> shared/ambiguous_note.md" \
             "sibling docs -> shared/ambiguous_note.md"; do
  if printf '%s' "$FINDINGS" | grep -qF -- "$wrong"; then
    printf '  FAIL  N19 a two-neighbour match resolved to a single provenance: %s\n' "$wrong"; FAIL=1
  fi
done
if printf '%s' "$FINDINGS" | grep -qF -- "shared/ambiguous_note.md"; then
  printf '  PASS  N19 ambiguous cross-repo marker is reported without asserting one neighbour\n'
else
  printf '  FAIL  N19 shared/ambiguous_note.md is not reported at all — an ambiguity that vanishes is worse than one resolved wrongly\n'; FAIL=1
fi

# T22 — N20's control, and the reason N20 cannot pass by never being extracted:
# the SAME path unmarked must still be explained as this repo's runtime state.
if printf '%s' "$OUT" | grep -q 'data/pipeline_state.json.*runtime state'; then
  printf '  PASS  T22 unmarked runtime state still resolves at rung 3\n'
else
  printf '  FAIL  T22 data/pipeline_state.json unmarked is no longer explained as runtime state\n'; FAIL=1
fi

# The negatives above only prove a path is not a FINDING. A path that was never
# extracted also is not a finding — which is the silent-skip failure this whole
# step is built against. Assert the counted section names them.
PLACEHELD="$(printf '%s' "$OUT" | sed -n '/== SKIPPED as declared-placeholder/,/^  total:/p')"
for want in "docs/RUNBOOK.md" "config/absent.env" "src/aggregators/never_anywhere.py" "orphan_note.md" \
            "src/aggregators/my_new_aggregator.py" "docs/work-items/<slug>.md" \
            "filters/<name>/<version>/config.yaml" "<slug>.md" "<root>/memory/MEMORY.md" \
            "review-prompt.md"; do
  if printf '%s' "$PLACEHELD" | grep -qF -- "$want"; then
    printf '  PASS  counted as declared-placeholder: %s\n' "$want"
  else
    printf '  FAIL  %s is not in the counted skip section — skipped and never-extracted are indistinguishable\n' "$want"; FAIL=1
  fi
done

# T28's discriminator. The needle alone cannot distinguish "the self-marking
# gate held" from "the target file is not there" — the oracle prints
# `UNRESOLVED` for both, so no reason string separates them (measured: deleting
# the target leaves the needle satisfied). The row is only a test of the gate if
# the file it points at exists, so assert that directly. This is #116's lesson
# arriving in a form a better needle could not have fixed.
for t in remedy_unqualified remedy_backticked; do
  if [ -f "$WORK/sibling-repo/scripts/$t.sh" ]; then
    printf '  PASS  discriminator: %s.sh exists, so its UNRESOLVED means the gate held\n' "$t"
  else
    printf '  FAIL  %s.sh is missing — its UNRESOLVED proves nothing about the gate\n' "$t"; FAIL=1
  fi
done

# #102's positive half. N32 above asserts only that the corrected remedy is not
# a FINDING, and a path that was never extracted is also not a finding — the
# silent-skip failure this fixture exists to refuse. Assert the enumeration too,
# WITH what it resolved to, so "the remedy works" is a measurement and not an
# absence. ⚠️ NO ablation guards this block and none can: `ablate()` scores
# through `xrun`, which iterates XCASES against exitcodes/repo only, so no
# ablation in this harness reaches a main-fixture row. A draft of this comment
# cited an "A13" that does not exist — a described mutant presented as a
# committed one, which is the thing this file exists to refuse. Verified by hand
# instead: disabling the unmarked rung-4 arm turns both halves red.
RESOLVED_SEC="$(printf '%s' "$OUT" | sed -n '/== RESOLVED BELOW RUNG 1/,/^  total:/p')"
if printf '%s' "$RESOLVED_SEC" | grep -qF -- "sibling-repo/scripts/remedy_qualified.sh"; then
  if printf '%s' "$RESOLVED_SEC" | grep -F -- "remedy_qualified.sh" | grep -qF -- "sibling sibling-repo -> scripts/remedy_qualified.sh"; then
    printf '  PASS  N32 the corrected remedy resolves AND names what it resolved to\n'
  else
    printf '  FAIL  N32 is enumerated without naming its resolution — the reader cannot tell which neighbour claimed it\n'; FAIL=1
  fi
else
  printf '  FAIL  N32 the qualified+prose form is in no counted section — the remedy the step prints cannot be shown to work\n'; FAIL=1
fi

# N20's other half, and deliberately decision-NEUTRAL: whether a marked runtime
# state path belongs in the placeholder skip or in the rung-3 enumeration is a
# call this harness should not make. What it must not be is absent from both,
# which is the silent-skip failure and the only way N20 could pass vacuously.
COUNTED="$(printf '%s' "$OUT" | sed -n '/== RESOLVED BELOW RUNG 1/,/^  total:/p;/== SKIPPED as declared-placeholder/,/^  total:/p')"
if printf '%s' "$COUNTED" | grep -qE "data/marked_state\.json .*(declared-placeholder|runtime state)"; then
  printf '  PASS  N20 marked runtime state is counted, not silently dropped\n'
else
  printf '  FAIL  N20 data/marked_state.json is in no counted section — excused and never-extracted are indistinguishable\n'; FAIL=1
fi

# D1 — the listing cache is keyed on the neighbour's NAME, so two reachable
# siblings sharing a basename collapse to one, and the survivor is decided by
# set-iteration order, i.e. by the per-process string hash seed. An oracle whose
# findings list changes between two runs of the same command is worse than the
# bug it fixes, and this is not exotic: run.sh's own fixture root sits two levels
# under the system temp dir, so a fixture left behind by an interrupted run — the
# before/after comparison this harness's header prescribes — supplies the
# collision. Measured: T19 failed on 1 seed in 8 with a stray fixture present.
#
# Assert INVARIANCE, not a verdict. A single run cannot see this at all.
D1_REF="$(PYTHONHASHSEED=1 python3 refcheck.py --sibling-root "$WORK/dupname" --sibling-root "$WORK/dupname/mid" "$WORK/dupname/mid/repo" CLAUDE.md 2>&1 || true)"
D1_OK=1
for seed in 2 3 4 5 6 7 8; do
  if [ "$(PYTHONHASHSEED=$seed python3 refcheck.py --sibling-root "$WORK/dupname" --sibling-root "$WORK/dupname/mid" "$WORK/dupname/mid/repo" CLAUDE.md 2>&1 || true)" != "$D1_REF" ]; then
    D1_OK=0; break
  fi
done
if [ "$D1_OK" -eq 1 ]; then
  printf '  PASS  D1 same-named neighbours give the same verdict on every run\n'
else
  printf '  FAIL  D1 the verdict changed with the hash seed — the sibling listing cache is keyed on the name, so same-named neighbours collapse nondeterministically\n'; FAIL=1
fi

# The extractor's own contract, table-driven. Cheap insurance against someone
# "tidying" the leading-dot clause (which no realistic shape reaches) and taking
# `config/live.env` down with it.
if bash -c 'python3 envshapes.py'; then
  printf '  PASS  E1 .env extraction/drop table matches the documented contract\n'
else
  printf '  FAIL  E1 .env extraction/drop table changed — see envshapes.py\n'; FAIL=1
fi

# X1-X9 — the exit-status truth table (#93). Everything above asserts what the
# report SAYS; nothing asserted what the run RETURNS, and `OUT=` at the top of
# this file discards the status with `|| true`, so the gate was untested here.
#
# Read the table as a whole, because no row can carry it alone. Exit 2 means
# "this run could not decide", and it is wrong in two opposite directions: fold
# it into 1 and a correct repo fails wherever its neighbours are not checked out
# (the defect #93 was filed for); fold it into 0 and a genuine break passes in
# exactly that environment. X4 and X9 are the rows only the right answer
# satisfies. The others forbid the cheap routes to them: X3 forbids "every
# unresolved reference is undecidable", X5/X6 forbid "no neighbour means nothing
# is decidable" for a collision ruled inside this repo, X7 keeps an unreadable
# document a failure of the run, and X1/X2 forbid a constant.
#
# X8/X9 are the pair a review found missing. A `<!-- placeholder -->` on a
# cross-repo path is rung-4 traffic too: with the neighbour on disk it is a STALE
# MARKER finding, and without one the stale test cannot run — so excusing it
# silently exited 0 on a repo a reachable neighbour would have reported. Same
# repo, same bytes, and in the direction the step itself calls the worse one.
#
# Each row asserts the exit STATUS and the VERDICT LABEL. The status alone is not
# enough: swapping all three labels while leaving every `rc` untouched kept every
# row of the then-7-row table green, which is this fixture's own T19 lesson — a
# positive that cannot distinguish why it fired is not a test.
#
# X11/X12 are round 3's control. An angle-bracket segment is decided by a regex
# over the fragment and nothing on disk, so its verdict does not depend on a
# neighbour at all; round 2 called it undecided anyway and moved a repo whose only
# references are placeholders of that shape from exit 0 to exit 2 in a fresh
# clone — this repo, measured.
declare -a XCASES=(
  "X1 clean, neighbours reachable|clean.md|neighbours|0|VERDICT: CLEAN — no findings"
  "X2 clean, no neighbour reachable|clean.md|empty|0|VERDICT: CLEAN — no findings"
  "X3 unresolved, neighbours reachable — rung 4 RAN and declined it|unresolved.md|neighbours|1|VERDICT: DEFECTS — 1 finding(s)"
  "X4 unresolved, no neighbour — undecided, and still non-zero|unresolved.md|empty|2|VERDICT: COVERAGE INCOMPLETE — rung 4 did not run"
  "X5 local collision, neighbours reachable|collision.md|neighbours|1|VERDICT: DEFECTS — 1 finding(s)"
  "X6 local collision, no neighbour — a rung that ran still ruled|collision.md|empty|1|VERDICT: DEFECTS — 1 finding(s)"
  "X7 a document that cannot be read is a failure of the run|absent.md|empty|1|VERDICT: DEFECTS — 1 unreadable document(s)"
  "X8 marked cross-repo path, neighbour on disk — STALE MARKER|marked.md|neighbours|1|VERDICT: DEFECTS — 1 finding(s)"
  "X9 marked cross-repo path, no neighbour — undecided, not excused|marked.md|empty|2|VERDICT: COVERAGE INCOMPLETE — rung 4 did not run"
  "X11 angle-bracket placeholder, neighbours reachable|angle.md|neighbours|0|VERDICT: CLEAN — no findings"
  "X12 angle-bracket placeholder, no neighbour — still decided|angle.md|empty|0|VERDICT: CLEAN — no findings"
  "X13 BOTH marker forms on one path, neighbours reachable|both.md|neighbours|0|VERDICT: CLEAN — no findings"
  "X14 BOTH marker forms, no neighbour — the shape still decides|both.md|empty|0|VERDICT: CLEAN — no findings"
  "X15 a confirmed defect AND an undecided reference in one run|mixed.md|empty|1|VERDICT: DEFECTS — 1 finding(s), 2 left undecided"
  "X17 marked path the LOCAL tree answers, neighbours reachable|localmark.md|neighbours|0|VERDICT: CLEAN — no findings"
  "X18 marked path the LOCAL tree answers, no neighbour — a rung that RAN decided it|localmark.md|empty|0|VERDICT: CLEAN — no findings"
  "X19 marked path resolving doc-relative is MISLABELLED, neighbours reachable|docs/docrel.md|neighbours|1|VERDICT: DEFECTS — 2 finding(s)"
  "X20 marked path resolving doc-relative is MISLABELLED, no neighbour|docs/docrel.md|empty|1|VERDICT: DEFECTS — 2 finding(s)"
)

# Runs the table against an arbitrary oracle and prints the names of the failing
# rows, one per line. Used twice: once against the real file, then once per
# ablation below. `$1` is the oracle to run.
xrun() {
  local oracle="$1" x xname xdoc xroot xwant xlabel xgot XOUT
  for x in "${XCASES[@]}"; do
    IFS='|' read -r xname xdoc xroot xwant xlabel <<<"$x"
    # `set -e` would abort on the non-zero statuses this table is built to
    # assert, so run inside `if`, which is exempt.
    if XOUT="$(python3 "$oracle" --sibling-root "$WORK/exitcodes/$xroot" \
                                 "$WORK/exitcodes/repo" "$xdoc" 2>&1)"; then xgot=0; else xgot=$?; fi
    # Here-strings rather than `printf | grep -q`: with `pipefail` a `-q` that
    # matches early can SIGPIPE the writer and score 141 as a miss. Harmless on a
    # 1 KB report, loud and wrong on a large one.
    if [ "$xgot" -ne "$xwant" ]; then printf '%s\n' "$xname"
    elif ! grep -qF -- "(exit $xwant) ==" <<<"$XOUT"; then printf '%s\n' "$xname"
    elif ! grep -qF -- "$xlabel" <<<"$XOUT"; then printf '%s\n' "$xname"
    fi
  done
}

XBAD="$(xrun refcheck.py)"
for x in "${XCASES[@]}"; do
  xname="${x%%|*}"
  if grep -qxF -- "$xname" <<<"$XBAD"; then
    printf '  FAIL  %s (wrong exit status or wrong verdict label)\n' "$xname"; FAIL=1
  else printf '  PASS  %s\n' "$xname"; fi
done

# X17c — every EXCUSING arm in this oracle needs the N20 guard, and round 6 found
# the rung-2 marked arm shipped without it. Measured: replacing the arm's
# `placeheld.append(...)` with a bare `continue` dropped both of localmark.md's
# paths from ALL SIX counted sections and the whole suite stayed green — X17/X18
# assert `VERDICT: CLEAN`, which a silent drop satisfies perfectly. The identical
# mutation one arm down (rung 3) is killed instantly by N20. A verdict row cannot
# guard an excusing arm; only an enumeration can.
XP="$( { python3 refcheck.py --sibling-root "$WORK/exitcodes/empty" \
           "$WORK/exitcodes/repo" localmark.md 2>&1 || true; } \
       | sed -n '/== SKIPPED as declared-placeholder/,/^  total:/p')"
XP_OK=1
for want in "present.py" "helpers.py"; do
  grep -qF -- "$want" <<<"$XP" || { XP_OK=0; printf '  FAIL  X17c %s was excused at rung 2 but appears in NO counted section — excused and never-extracted are indistinguishable\n' "$want"; FAIL=1; }
done
grep -qF -- "  total: 2" <<<"$XP" || { XP_OK=0; printf '  FAIL  X17c the skip section does not carry a total of 2\n'; FAIL=1; }
# The reason, not just the path — this fixture's own T19 rule. A row that says
# only `declared-placeholder` cannot distinguish WHICH arm excused it, and the
# collision count inside the message is a measurement that has to be true.
grep -qF -- "decided at rung 2 (1 local match)"  <<<"$XP" || { XP_OK=0; printf '  FAIL  X17c present.py is excused without naming rung 2 and its single match\n'; FAIL=1; }
grep -qF -- "decided at rung 2 (2 local matches)" <<<"$XP" || { XP_OK=0; printf '  FAIL  X17c helpers.py is excused without naming rung 2 and its TWO matches — a count inside a message is a measurement\n'; FAIL=1; }
[ "$XP_OK" -eq 1 ] && printf '  PASS  X17c rung-2 excusals are enumerated, counted, and name the rung that decided them\n'

# X19c — the REASON, not just that a finding fired. `docs/docrel.md` holds exactly
# one reference, so `VERDICT: DEFECTS — 1 finding(s)` is satisfied by ANY finding:
# three mutants of the rung-1b message survived the suite green — reporting it as
# `UNRESOLVED`, reporting it as `resolves at rung 1, as written`, and printing the
# raw fragment instead of the resolved path. The middle one is the substantive
# one: it writes a FALSE PROVENANCE into the finding and sends the author to the
# repo root, which is the same argument this file makes twice for ordering rung 3
# before rung 4. This fixture's own T19 rule: a positive that cannot distinguish
# why it fired is not a test.
XD="$( { python3 refcheck.py --sibling-root "$WORK/exitcodes/empty" \
           "$WORK/exitcodes/repo" docs/docrel.md 2>&1 || true; } \
       | sed -n '/== FINDINGS/,/^  total:/p')"
XD_OK=1
grep -qF -- "STALE PLACEHOLDER MARKER (resolves at rung 1b, doc-relative: docs/next_door.md)" <<<"$XD" \
  || { XD_OK=0; printf '  FAIL  X19c the rung-1b finding does not name its rung and resolved path — its provenance is unasserted\n'; FAIL=1; }
# The markerless twin. Both are findings and both resolve at rung 1b; only the
# WORD separates them, and a shared constant would be wrong for one of the two.
grep -qF -- "PLACEHOLDER SHAPE THAT RESOLVES (resolves at rung 1b, doc-relative: docs/<shape>.md)" <<<"$XD" \
  || { XD_OK=0; printf '  FAIL  X19c an angle-bracket path with no marker is reported as a STALE MARKER — the remedy names something not in the document\n'; FAIL=1; }
[ "$XD_OK" -eq 1 ] && printf '  PASS  X19c both rung-1b findings name their rung, their resolved path, and the right form\n' 

# X21 — the USAGE gate (#96). An unrecognised `--` argument used to be consumed as
# <repo-root>, so `--sibling-roots` (note the s) made the real root a source doc and
# returned `DEFECTS (exit 1)` — a verdict, from a typo. `grep -nE '\b64\b|usage'`
# over this file returned NOTHING before this row: the module docstring claimed a
# mistyped flag cannot be read as either verdict and nothing had ever checked it.
X21_OK=1
if python3 refcheck.py --sibling-roots /tmp . CLAUDE.md >/dev/null 2>&1; then xg=0; else xg=$?; fi
[ "$xg" -eq 64 ] || { X21_OK=0; printf '  FAIL  X21 an unrecognised flag returned %s, not 64 (EX_USAGE) — a typo is being read as a verdict\n' "$xg"; FAIL=1; }
if python3 refcheck.py >/dev/null 2>&1; then xg=0; else xg=$?; fi
[ "$xg" -eq 64 ] || { X21_OK=0; printf '  FAIL  X21 no arguments returned %s, not 64\n' "$xg"; FAIL=1; }
[ "$X21_OK" -eq 1 ] && printf '  PASS  X21 a usage error is 64, distinct from both verdicts\n'

# X22 — the angle arm labels by the reason that EXCUSED the row (#98). `both.md`
# carries both marker forms; it is excused by SHAPE, and printing
# `declared-placeholder` pointed its reader at the rung-4 coverage sentence, which
# is false for a row no rung decided.
XL="$( { python3 refcheck.py --sibling-root "$WORK/exitcodes/empty" \
           "$WORK/exitcodes/repo" both.md 2>&1 || true; } | sed -n '/== SKIPPED as declared-placeholder/,/^  total:/p')"
if grep -qE 'docs/work-items/<slug>\.md +angle-bracket segment' <<<"$XL"; then
  printf '  PASS  X22 a both-forms path is labelled by the shape that excused it\n'
else
  printf '  FAIL  X22 a both-forms path is not labelled `angle-bracket segment` — its label names a reason that did not excuse it\n'; FAIL=1
fi

# X23 — the FINDINGS section on a NO-NEIGHBOUR run (#95). run.sh line ~16 pins the
# main run to 3 siblings, so its UNCONFIRMED total is 0 BY CONSTRUCTION and no
# assertion had ever read the findings body without a neighbour. Two mutants
# survived green: an UNCONFIRMED row printing inside FINDINGS, and the total
# counting undecided rows. Both are caught here.
XF="$( { python3 refcheck.py --sibling-root "$WORK/exitcodes/empty" \
           "$WORK/exitcodes/repo" mixed.md 2>&1 || true; } | sed -n '/== FINDINGS/,/^  total:/p')"
X23_OK=1
grep -qF -- "  total: 1" <<<"$XF" || { X23_OK=0; printf '  FAIL  X23 the FINDINGS total is not 1 — undecided rows are being counted as findings\n'; FAIL=1; }
grep -qi -- "unconfirmed" <<<"$XF" && { X23_OK=0; printf '  FAIL  X23 an UNCONFIRMED row is printed inside the FINDINGS section\n'; FAIL=1; }
grep -qF -- "helpers.py" <<<"$XF" || { X23_OK=0; printf '  FAIL  X23 the one real finding (the collision) is not in the FINDINGS section\n'; FAIL=1; }
[ "$X23_OK" -eq 1 ] && printf '  PASS  X23 with no neighbour, FINDINGS holds the ruled-on reference and only that\n'

# X24 — "one section or the other, never both", which Step 4 states as a design rule
# and which nothing checked. Dropping a `continue` after a finding put one reference
# in FINDINGS and in the skip section at once, suite green.
XA="$( { python3 refcheck.py --sibling-root "$WORK/exitcodes/empty" \
           "$WORK/exitcodes/repo" docs/docrel.md mixed.md both.md localmark.md 2>&1 || true; } )"
# Keyed on DOC+PATH, not path alone: two different documents may legitimately
# reference the same fragment and land in different sections — `helpers.py` is a
# collision in mixed.md and an excused rung-2 marker in localmark.md, which is
# correct. The first draft keyed on the path and reported that as a violation,
# along with `0` and `3` picked out of the `total:` lines it failed to exclude.
dup="$(awk '/^== /{sec=$0; next} /^  total:/{next} /^  [^ ]/ && sec ~ /FINDINGS|RESOLVED BELOW|SKIPPED|UNCONFIRMED/ {print $1"\t"$2}' <<<"$XA" | sort | uniq -d)"
if [ -z "$dup" ]; then
  printf '  PASS  X24 no reference appears in two counted sections\n'
else
  printf '  FAIL  X24 these references are in more than one counted section: %s\n' "$(tr '\n' ' ' <<<"$dup")"; FAIL=1
fi

# X16 — the undecided must be ENUMERATED, not merely counted in a verdict. The X
# rows above assert the exit status and the verdict label; deleting the whole
# UNCONFIRMED print block left all of them green while 33 references on a
# NO-NEIGHBOUR run of the main
# fixture appeared in NO counted section at all — the silent-skip failure this
# fixture exists to prevent, one section newer than the loop that guards it.
# `|| true` because mixed.md exits 1 by design and `pipefail` would otherwise
# abort the harness here under `set -e` — silently skipping every later
# assertion, which is the failure this block is itself about. X15 above is what
# asserts that status; this block only reads the section.
XU="$( { python3 refcheck.py --sibling-root "$WORK/exitcodes/empty" \
           "$WORK/exitcodes/repo" mixed.md 2>&1 || true; } | sed -n '/== UNCONFIRMED/,/^  total:/p')"
XU_OK=1
for want in "src/absent_for_sure.py" "scripts/over_there.sh"; do
  grep -qF -- "$want" <<<"$XU" || { XU_OK=0; printf '  FAIL  X16 %s is undecided but is not enumerated in the UNCONFIRMED section\n' "$want"; FAIL=1; }
done
grep -qF -- "  total: 2" <<<"$XU" || { XU_OK=0; printf '  FAIL  X16 the UNCONFIRMED section does not carry a total of 2\n'; FAIL=1; }
[ "$XU_OK" -eq 1 ] && printf '  PASS  X16 the undecided are enumerated and counted, not just totalled in the verdict\n'

# X10 — the isolation guard, and it is here because this change broke it once.
# `exitcodes/repo` sits at `*/*` from $WORK, which is the MAIN run's sibling
# root, so a `.git` in it made the main fixture scan a fourth neighbour named
# `repo` — a token that appears in 13 lines of this fixture's prose, since a
# hyphen is a token boundary and every mention of `sibling-repo` contains it.
# It sorted first and the rung-4 loop breaks on the first hit. Nothing failed;
# a probe document flipped from a reported break to a clean rung-4 resolution.
# Assert the count so the next tree added here cannot leak silently.
N_SIB="$(sed -n 's/^== RUNG 4 COVERAGE: scanned \([0-9]*\) sibling.*/\1/p' <<<"$OUT")"
if [ "$N_SIB" = "3" ]; then
  printf '  PASS  X10 the exit-code tree does not leak into the main fixture (3 neighbours)\n'
else
  printf '  FAIL  X10 the main run scanned %s neighbours, not 3 — a fixture tree is leaking into the rung-4 search\n' "$N_SIB"; FAIL=1
fi

# --- #119 / #120 — rung 4 provenance, in an ISOLATED estate. -----------------
# Isolated because both cases need two siblings whose names share a
# hyphen-delimited component, and adding those to $WORK would change the main
# run's neighbour count and trip X10.
#
# X10's own comment already recorded both bugs from the other side: `repo` was
# marked by all 13 prose mentions of `sibling-repo` because a hyphen was a token
# boundary (#119), and "it sorted first and the rung-4 loop breaks on the first
# hit" (#120). These rows are what would have caught them.
P="$WORK/prov"
mkdir -p "$P/repo" "$P/alpharepo/scripts" "$P/beta-alpharepo/scripts"
for d in "$P/repo" "$P/alpharepo" "$P/beta-alpharepo"; do mkdir -p "$d/.git"; done
: > "$P/alpharepo/scripts/only_in_alpha.py"
: > "$P/alpharepo/scripts/twin.py"
: > "$P/beta-alpharepo/scripts/twin.py"

# T30 — prose names ONLY beta-alpharepo; the file exists only in alpharepo.
printf 'The beta-alpharepo checkout owns this:\n`scripts/only_in_alpha.py`\n' \
  > "$P/repo/h1.md"
# T31 — both siblings hold the same file and prose names both.
printf 'Both beta-alpharepo and alpharepo hold it:\n`scripts/twin.py`\n' \
  > "$P/repo/h2.md"

PROV="$(python3 refcheck.py --sibling-root "$P" "$P/repo" h1.md h2.md 2>&1 || true)"

if printf '%s' "$PROV" | grep -qF -- 'sibling alpharepo -> scripts/only_in_alpha.py'; then
  printf '  FAIL  T30 a hyphen-separated component still marks a different sibling (#119)\n'; FAIL=1
else
  printf '  PASS  T30 prose naming beta-alpharepo does not mark the sibling alpharepo (#119)\n'
fi

if printf '%s' "$PROV" | grep -qF -- 'AMBIGUOUS (2 siblings match'; then
  printf '  PASS  T31 the UNMARKED arm reports cross-sibling ambiguity (#120)\n'
else
  printf '  FAIL  T31 the unmarked arm picked a single provenance instead of reporting ambiguity (#120)\n'; FAIL=1
fi

# N33 — the fix must not cost the ordinary case: a sibling named in bare prose,
# whole word, still marks. Without this, "never mark anything" scores 2/2 above.
printf 'The alpharepo repo owns this:\n`scripts/only_in_alpha.py`\n' > "$P/repo/h3.md"
PROV3="$(python3 refcheck.py --sibling-root "$P" "$P/repo" h3.md 2>&1 || true)"
if printf '%s' "$PROV3" | grep -qF -- 'sibling alpharepo -> scripts/only_in_alpha.py'; then
  printf '  PASS  N33 a whole-word sibling name in bare prose still resolves\n'
else
  printf '  FAIL  N33 the #119 fix broke ordinary rung-4 resolution\n'; FAIL=1
fi

# --- Ablations. Committed rather than described, because the prose form of this
# claim was refuted twice by reviewers who reconstructed the mutants and got a
# different row count under an equally natural reading. A mutant's exact text is
# the measurement; prose about it is not.
#
# Each row: label | python replacement applied to a COPY of the oracle | the rows
# that must fail. A mutation that changes nothing is itself a failure — a no-op
# ablation certifies whatever the suite already did.
ABL_DIR="$WORK/ablate"; mkdir -p "$ABL_DIR"
ablate() {
  local label="$1" old="$2" new="$3" want="$4" got
  cp refcheck.py "$ABL_DIR/refcheck.py"
  if ! OLD="$old" NEW="$new" python3 - "$ABL_DIR/refcheck.py" <<'EOF'
import os, sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
old, new = os.environ['OLD'], os.environ['NEW']
if s.count(old) != 1:
    sys.exit('mutation site occurs %d times, not once' % s.count(old))
p.write_text(s.replace(old, new))
EOF
  then printf '  FAIL  ablation %s could not be applied — its site has moved\n' "$label"; FAIL=1; return; fi
  # LC_ALL=C: a bare `sort` collates by locale, so two case names differing only
  # by a suffix ("X28 …" vs "X28b …") order differently under en_US than under C
  # and the kill set silently reorders on someone else's machine. DEFENSIVE, not
  # currently load-bearing — no kill set in the table today contains a pair that
  # reorders (measured on en_US.utf8 and C: identical output). It becomes load-
  # bearing the moment a letter-suffixed case name joins one, which is how it was
  # found. Same reason the README already pins awk behaviour rather than trusting
  # the runner's environment.
  got="$(cd "$ABL_DIR" && xrun refcheck.py | LC_ALL=C sort | paste -sd, -)"
  if [ "$got" = "$want" ]; then
    printf '  PASS  ablation %s fails exactly [%s]\n' "$label" "$want"
  else
    printf '  FAIL  ablation %s should fail [%s], failed [%s]\n' "$label" "$want" "$got"; FAIL=1
  fi
}
# `xrun` prints row NAMES; these are the leading tokens, so compare on the whole
# name. Written out rather than derived, so a renamed row fails loudly here.
X3N="X3 unresolved, neighbours reachable — rung 4 RAN and declined it"
X4N="X4 unresolved, no neighbour — undecided, and still non-zero"
X6N="X6 local collision, no neighbour — a rung that ran still ruled"
X9N_="X9 marked cross-repo path, no neighbour — undecided, not excused"
X7N="X7 a document that cannot be read is a failure of the run"
X9N="X9 marked cross-repo path, no neighbour — undecided, not excused"
X2N="X2 clean, no neighbour reachable"
X12N="X12 angle-bracket placeholder, no neighbour — still decided"
X14N="X14 BOTH marker forms, no neighbour — the shape still decides"
X15N="X15 a confirmed defect AND an undecided reference in one run"
X18N="X18 marked path the LOCAL tree answers, no neighbour — a rung that RAN decided it"
X19N="X19 marked path resolving doc-relative is MISLABELLED, neighbours reachable"
X20N="X20 marked path resolving doc-relative is MISLABELLED, no neighbour"

# A1 kills X4 alone, not X4+X9: an untested marker never enters `findings`,
# so reverting the split there cannot reach it. Measured — the first draft of
# this row predicted both and was wrong, which is the argument for committing
# the mutants instead of describing them.
ablate "A1 revert the split"        "if confirmed or missing:" "if findings or missing:"      "$X4N"
ablate "A2 exit 0 when unconfirmed" "rc, verdict = 2, ('COVERAGE" "rc, verdict = 0, ('COVERAGE" "$X4N,$X9N"
ablate "A3 everything unconfirmed"  "'UNRESOLVED' if rung4_runnable else UNCONFIRMED" "UNCONFIRMED" "$X3N"
ablate "A4 drop the unread arm"     "if confirmed or missing:" "if confirmed:"                "$X7N"
# A5, A6 and A7 each widened when a row was added below them, and A5 and A6
# widened AGAIN when round 5 added X17-X20 (A5 gains X20, A6 gains X18). Recorded rather
# than trimmed: an ablation's kill set is a measurement of the mutant, not a
# property of the row it was written for, and three of these expectations have
# now been corrected by running them rather than by reasoning about them.
ablate "A5 no neighbour, nothing decidable" \
       "confirmed = [f for f in findings if f[2] != UNCONFIRMED]" \
       "confirmed = [] if n_siblings == 0 else list(findings)"                        "$X15N,$X20N,$X6N"
# A6 kills both clean-with-no-neighbour rows, which is the point of it: the
# mutation is "the RUN is indeterminate", so every row where nothing was found
# and no neighbour was reachable must go red. Adding X12 changed this set, and
# the ablation is what noticed — a prose claim would not have.
ablate "A6 whole RUN indeterminate" "elif unconfirmed:" "elif unconfirmed or n_siblings == 0:" "$X12N,$X14N,$X18N,$X2N"
ablate "A7 excuse an untested marker" "elif rung4_runnable:" "elif True:"                      "$X15N,$X9N_"
# A8 is X12's guard, and X12 exists because round 2 shipped this mutation as the
# real thing: sending an angle-bracket segment to the undecided bucket moved a
# repo whose only references are placeholders of that shape — this one — from
# exit 0 to exit 2 in a fresh clone. Deciding `<slug>` takes a regex over the
# fragment and nothing on disk, so it is decidable with no neighbour at all.
ablate "A8 angle brackets undecided too" "elif ANGLE_SEG_RE.search(frag):" "elif False:"      "$X12N,$X14N"
# A9 is X14's own guard: round 3 tested the marker BEFORE the shape, so a path
# carrying both forms took the marker branch and went 0 -> 2 on where it ran.
# Restoring that order must go red, and X12 must stay green while it does —
# otherwise the two rows are one test wearing two names.
ablate "A9 marker wins over the shape" \
       "elif ANGLE_SEG_RE.search(frag):" "elif frag in placeheld_frags and False or ANGLE_SEG_RE.search(frag) and frag not in placeheld_frags:" \
       "$X14N"
# A10 is X15's guard. The mixed verdict clause is the only thing that reports an
# undecided reference on an exit-1 run, and no other row produces both kinds at
# once — so without X15 this deletion is invisible.
ablate "A10 drop the mixed-verdict clause" \
       "        if unconfirmed:" "        if False:"                                              "$X15N"
# A11/A12 are round 5's, and they hold the two halves of the same fix apart. The
# marked arm ran rungs 1, 3, 4 and skipped 1b and 2, so a marked reference the
# LOCAL tree answers fell through to the undecided bucket — #93's own defect a
# third time, and the one direction no row covered. A11 reverts the decidability
# half, A12 the adjudication half. Kill sets MEASURED by running the mutants.
ablate "A11 marked path skips the local suffix rung" \
       "                    if mhits:" "                    if False:"                            "$X18N"
ablate "A12 marked path skips the doc-relative rung" \
       "if mdocrel.exists() and mdocrel.is_file():" "if False:"                                    "$X19N,$X20N"
# ⚠️ X1, X5, X8, X11, X13 and X17 are killed by none of the twelve. Re-measured
# 2026-08-27 by running every mutant, not by reading the rows — round 4 found
# five of ten kill sets wrong when written, so this comment is a MEASUREMENT. They are shape coverage, not
# guards: each pins the neighbours-reachable half of a pair so that its twin's
# PASS cannot be read as environment-independent by accident.

echo
[ "$FAIL" -eq 0 ] && echo "All seeded cases behaved correctly." || echo "SENSITIVITY REGRESSION — do not ship."
exit "$FAIL"
