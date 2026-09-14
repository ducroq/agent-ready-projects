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
  # #165/#176 — the coverage the compound-extension denylist must NOT cost.
  # These three are not decoration: `.meta.json` and `.key.json` are silenced by
  # the shape rule that was proposed and declined, and both are real filenames
  # in the 33-repo estate that issue scanned. They are what makes the denylist a
  # measurement rather than a preference, and they go red the moment someone
  # replaces it with the "obvious" leading-dot shape test.
  # ⚠️ MEASURED, both directions, 2026-09-14. Denylist removed: N47 fails alone.
  # Shape rule substituted for the denylist: T52 and T53 fail and **T54 PASSES**.
  # #165 offered `.pa11yci.json` as the counter-example to seed; seeding only
  # that one would have certified the rejected fix GREEN. The sample has to
  # contain the cases the author did NOT already have in mind, which is this
  # repo's own seeded-true-positives rule turned on the issue's own suggestion.
  "T52 a broken .meta.json is still reported|.meta.json"
  "T53 a broken .key.json is still reported|.key.json"
  "T54 a broken .pa11yci.json is still reported|.pa11yci.json"
  # #175 — the same class as T11/T16 at the module extensions. One case per
  # extension, deliberately: `EXT` is an alternation, so a case for `.mts` proves
  # nothing about `.cts` and a misspelt alternative would hide behind its
  # neighbours. Found live on an adopter whose project file references
  # `vitest.config.mts`; the audit reported CLEAN, correct only by luck.
  "T48 fabricated .mts is caught|cfg/missing_vitest.mts"
  "T49 fabricated .mjs is caught|cfg/missing_eslint.mjs"
  "T50 fabricated .cjs is caught|cfg/missing_jest.cjs"
  "T51 fabricated .cts is caught|cfg/missing_tsnode.cts"
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
  # #174 — a NEGATIVE CONTROL on a marker shape this checker does not
  # implement. `review-changes` Step 3.1 prescribed a leading U+2298 for a
  # whole release; refcheck.py has zero occurrences of the character, so the
  # rows carrying it were standing false findings and their author believed
  # them suppressed. The remedy chosen was to change the PRESCRIPTION to the
  # marker that works, not to teach the checker a second glyph (#177: "a
  # third form to get wrong"). ⚠️ **The mutants for T46 and T47 are RUN BY
  # HAND, not committed** — nothing in this harness can reach a main-fixture
  # CASES row (see the N32 block below, which says the same of itself). Two
  # were run: teaching PLACEHOLDER_RE the glyph turns T46 red, and moving
  # T47's marker into the correct cell turns T47 red.
  # ⚠️ A first draft seeded the glyph in the LEADING position and claimed it
  # caught "anyone who implements the glyph". MEASURED FALSE: adding the
  # glyph to PLACEHOLDER_RE left T46 GREEN, because the shipped marker is
  # BACKWARD-scoping and a leading glyph covers nothing either way; an
  # unrelated row went red with a wrong diagnosis instead. The glyph now
  # sits where the working marker sits, and that ablation turns T46 red.
  "T46 a U+2298 in the marker position is not a marker and confers nothing|src/checks/never_built.sh"
  # #174 — the marker INSIDE a table cell. The skills now prescribe that
  # placement, and NOTHING seeded it: the fixture had 23 markers and zero on a
  # table row. A draft of the changelog claimed "14 of them inside table rows"
  # by grepping the RUNNER and counting this file's own `name|needle`
  # delimiters — wrong instrument and wrong population in one number.
  # T47 is the placement the prescription warns against: a marker parked at the
  # END of a row covers the nearest path BEFORE it, so it lands on the row's
  # last path and the path the author meant to excuse stays a finding. ⚠️ The
  # first draft of this case asserted the wrong consequence — it expected a
  # STALE PLACEHOLDER MARKER on the accused path. MEASURED instead: the accused
  # path resolves at rung 2, where a marked path SKIPS the local rung (A11), so
  # the marker is silently consumed and NOTHING reports the misplacement. That
  # is worse than the drafted story, not better: the author sees one unexplained
  # finding and no hint that their marker landed elsewhere. Needle is the
  # intended path, which no other document references.
  "T47 a marker at the end of a row does not excuse the path in an earlier cell|src/checks/cell_unmarked.sh"
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
  # #174 — the PRESCRIBED placement: marker immediately after the path, inside
  # the same table cell. The positive control T47 is its twin.
  "N42 marker inside a table cell, immediately after the path|src/checks/cell_marked.sh"
  # The other half of #102, and the row that makes the corrected remedy a
  # measurement rather than a claim: qualified path AND the repo named in the
  # prose around it must RESOLVE. If this starts reporting, the remedy the step
  # prints has become wrong again.
  "N32 qualified path WITH the repo named in prose resolves|sibling-repo/scripts/remedy_qualified.sh"
  # The failure #69's widening newly permits: every real .qmd becoming a
  # phantom. Adding an extension must buy coverage, not noise.
  "N14 a resolving .qmd stays silent|analysis/index.qmd"
  # #175, the other direction — N14's rule per extension. Widening the whitelist
  # must buy coverage, not turn every real config file into a phantom.
  # ⚠️ DELIBERATELY INERT against this change, measured, not assumed: with the
  # four extensions reverted these four still PASS, because an unextracted path
  # is silent for the wrong reason. Like T24, they are CONTROLS — they go red if
  # extraction ever outruns resolution for these extensions. T48-T51 are the
  # cases that carry the sensitivity: all four fail on the revert, and nothing
  # else in the suite moves.
  "N43 a resolving .mts stays silent|cfg/live_vitest.mts"
  "N44 a resolving .mjs stays silent|cfg/live_eslint.mjs"
  "N45 a resolving .cjs stays silent|cfg/live_jest.cjs"
  "N46 a resolving .cts stays silent|cfg/live_tsnode.cts"
  # #70 — the phantom itself. No rung can resolve `process.env`; it is not a file.
  "N15 process.env is an identifier, not a path|process.env"
  # #165/#176 — the phantom itself, and the only token in the denylist. Every
  # TypeScript project's prose contains it; on one adopter it was a permanent
  # finding that no marker could legally clear, because the marker means "a path
  # that was never meant to resolve" and this is not a path at all.
  "N47 .d.ts is an extension named as a term, not a path|.d.ts"
  # N51/N52 — #165's member of T18's class. An adversarial lens found it missing:
  # the new filter joined a class that had exactly one seeded case, for the
  # other member.
  "N51 a marker beside .d.ts does not bind to it|.d.ts"
  # The other half, and it mirrors N16 exactly: the marker must reach PAST the
  # ineligible token to the real path, which is then EXCUSED — so the correct
  # result is no finding, not a finding. A first draft asserted this as a
  # T-case and it failed, because binding to the real path is the behaviour
  # being asked for, not the defect.
  "N52 the marker reaches past .d.ts to the real path|src/checks/absent_typedef.ts"
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
# ⚠️ N19's SECOND HALF WAS RE-SCOPED 2026-09-05, deliberately, and the reasoning
# matters more than the change. It asserted the row appears in FINDINGS. #107
# showed that made every state a finding for a MARKED ambiguous path — marked
# reports, unmarked reports a collision, and the prescribed "qualify it instead"
# is impossible against six candidates. The author had no legal move, so the row
# was re-triaged and re-dismissed on every audit: the exact recurring cost the
# placeholder skip exists to remove.
#
# The principle N19 defends — an ambiguity must not VANISH — is untouched, and is
# what this assertion still enforces: the row must appear in the enumerated
# declared-placeholder section. What changed is which section counts as "reported".
# Rung 2 already decides without adjudicating (#56); rung 4 now does the same for
# a marked path with no single provenance.
#
# The first half above is UNCHANGED and is the one that must never loosen: it
# still forbids asserting a single neighbour.
# Computed locally: $PLACEHELD is defined further down, and using it here read
# as an empty string — the check then reported "not reported at all" for a row
# that was present. A negative produced by an unset variable is exactly the
# broken-instrument shape this repo files issues about.
N19_PH="$(printf '%s' "$OUT" | sed -n '/== SKIPPED as declared-placeholder/,/^  total:/p')"
if printf '%s' "$N19_PH" | grep -qF -- "shared/ambiguous_note.md"; then
  printf '  PASS  N19 an ambiguous cross-repo MARKER is enumerated as a declared placeholder, not adjudicated (#107)\n'
elif printf '%s' "$FINDINGS" | grep -qF -- "shared/ambiguous_note.md"; then
  printf '  FAIL  N19 an ambiguous marked path is still an unactionable FINDING — #107 regressed\n'; FAIL=1
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

# ---- #122: shapes the extractor never took must be NAMED, not silently dropped.
DROPPED="$(printf '%s' "$OUT" | sed -n '/== PATH SHAPES NOT EXTRACTED/,/^  total:/p')"
# ⚠️ `total:` is an indented line too. Counting it made an empty-but-present
# section read as one entry, so the vacuity FAIL below could never fire — the
# same off-by-one that let T56's first draft pass on a section header.
DROP_ROWS="$(printf '%s' "$DROPPED" | grep '^  ' | grep -v '^  total:' || true)"
N_DROPPED="$(printf '%s' "$DROP_ROWS" | grep -c '[^[:space:]]' || true)"
if [ "$N_DROPPED" -eq 0 ]; then
  printf '  FAIL  T57-T61 measured nothing: the PATH SHAPES NOT EXTRACTED section is empty or absent\n'; FAIL=1
else
  while IFS='|' read -r label frag; do
    [ -z "$label" ] && continue
    if ! printf '%s' "$DROPPED" | grep -Fq "$frag"; then
      printf '  FAIL  %s (not named as unextracted: %s)\n' "$label" "$frag"; FAIL=1
    elif printf '%s' "$FINDINGS" | grep -Fq "$frag"; then
      printf '  FAIL  %s (named AND reported as a finding: %s — it is unchecked, not broken)\n' "$label" "$frag"; FAIL=1
    else
      printf '  PASS  %s\n' "$label"
    fi
  done <<'SHAPES'
T57 a brace expansion is named as unextracted|scripts/{a,b}.json
T58 a bracket placeholder is named as unextracted|docs/work-items/[slug].md
T59 a root-absolute path is named as unextracted|/opt/otherhost/config.json
T60 a Windows path is named as unextracted|C:\projects\app\notes.md
T61 a UNC path is named as unextracted|\\fileserver\share\spec.md
SHAPES
  # ⚠️ The other direction, and BOTH the gap and the controls were measured
  # rather than guessed. An over-broad detector (drop the separator requirement)
  # swept four more tokens in and NOT ONE case failed, so this section could
  # have become a noise dump silently — noise is cheap to add here precisely
  # because these are not findings.
  #
  # The first controls drafted for it were `process.env` and `.d.ts`, and they
  # PASSED under that mutant: both are MATCHED by PATH_RE, so the detector skips
  # them on the extracted-already test and the regex never sees them. Diffing
  # the section between the two variants named the real leak — bare
  # single-segment extension NOUNS, which PATH_RE cannot match because they have
  # no name segment. Those are the controls, and they fail under the mutant.
  # ⚠️ The first control set here was `.ts`/`.md`/`.qmd`, and an adversarial lens
  # refuted it: those are bare extension NOUNS, which PATH_RE never matches, so
  # they discriminated nothing about the shape rules. The tokens below are the
  # ones a MEASUREMENT produced — a generic `[/\{[]` class reported 61 entries
  # over this repo's own markdown and most were not paths. Each of these is
  # reported by the rule that was written first and by none of the six named
  # shapes, so they go red if anyone reaches for the generic form again.
  #
  # ⚠️ MEASURED 2026-09-14, and the two halves kill DIFFERENT wrong rules — which
  # is why both are kept. Restore the generic `[/\\{[]`-plus-any-tail rule and
  # the SEVEN measurement-derived tokens fail while the three bare nouns pass.
  # Drop the separator requirement instead and only the three bare nouns fail.
  # Either set alone certifies one of the two wrong directions as green.
  for _tok in 'rows[0].value' 'cfg["db"].host' 'df.loc[0].name' \
              'Optional[Path].name' 'X\.Y\.Z' '@types/node/index.d.ts' \
              '.cursor/rules/*.mdc' '.ts' '.md' '.qmd'; do
    # ⚠️ FIELD, not line-end. The first draft anchored on `$`, which works only
    # while the fragment is the last column — add a reason column to the report
    # and N50 passes forever while the detector it guards leaks freely. That is
    # T29's lesson ("a needle keyed on column padding") one section over.
    if printf '%s' "$DROP_ROWS" | awk '{print $2}' | grep -qxF "$_tok"; then
      printf '  FAIL  N50 %s is listed as an unextracted path shape — the detector is over-broad\n' "$_tok"; FAIL=1
    else
      printf '  PASS  N50 %s is not reported as an unextracted path shape\n' "$_tok"
    fi
  done
fi


# T56 — #177 point 3. A marker is only checkable if the reader can see WHAT IT
# WAS WEIGHED AGAINST. Rung 2 already printed its reason; rungs 3 and 4 excused a
# marked path with a bare `declared-placeholder` and no rung named, so a marker
# that is simply WRONG was excused in silence. One adopter had exactly one wrong
# marker — on a live, tracked source file — and it was found by a review lens,
# not by this checker.
#
# ⚠️ Adjudicating below rung 1 is NOT the fix, and that is why this is a report
# change rather than a findings change: reporting STALE at rung 2 is precisely
# what #56 removed, and N25 is the case that guards it. A repo shipping a
# template AND instances of it then has no correct move — marked reports STALE,
# unmarked reports COLLISION. So: name the rung, decide nothing differently.
#
# Structural, not per-case: any FUTURE fall-through that forgets to name its rung
# fails this, which a needle on one path would not.
#
# ⚠️ That sentence was FALSE when first written, and two review lenses caught it
# independently. The predicate read only rows containing `declared-placeholder`,
# and the section also carries `angle-bracket segment` rows — one of which the
# shipped oracle ALREADY emitted bare, with no rung, whenever rung 4 was not
# runnable (a fresh clone with no neighbour: the environment clone-lint exists
# for). So the check was scoped to one of two labels while claiming to cover
# every fall-through, and the live counter-example sat in the same file. The
# predicate is now EVERY entry row, and that arm names its reason.
#
# ⚠️ THE NON-VACUITY LINE IS NOT DECORATION. The first draft of this check sat
# ABOVE the line that assigns PLACEHELD, so it ran against an unbound variable:
# grep over empty input returns 0, the `|| true` swallowed the error, and it
# reported PASS having measured NOTHING. That is #161's class exactly — a guard
# whose green is indistinguishable from a real one — written into this fixture by
# the change that was fixing #177. An empty section must FAIL here, not pass.
# ⚠️ The predicate is ENTRY LINES, not the word. A first attempt grepped for
# `declared-placeholder` anywhere in the section and counted the SECTION HEADER,
# which carries the word and no rung — so it reported a phantom failure, and the
# non-vacuity line above it could never have fired either, the header alone
# satisfying it. Entries are indented two spaces; `total:` closes the section.
PH_ROWS="$(printf '%s' "$PLACEHELD" | grep '^  ' | grep -v '^  total:' || true)"
N_PH="$(printf '%s' "$PH_ROWS" | grep -c '[^[:space:]]' || true)"
PH_EMPTY=0
if [ "$N_PH" -eq 0 ]; then
  printf '  FAIL  T56 measured nothing: no declared-placeholder entries in the report\n'
  FAIL=1; PH_EMPTY=1
fi
BARE_PH="$(printf '%s' "$PH_ROWS" | grep -vc '—' || true)"
if [ "$PH_EMPTY" -eq 1 ]; then
  :   # already reported; a bare-count of 0 over an empty set is not a pass
elif [ "$BARE_PH" -eq 0 ]; then
  printf '  PASS  T56 every entry in the skipped section names the rung that excused it\n'
else
  printf '  FAIL  T56 %s declared-placeholder entr(y/ies) name no rung — a marker excused with no reason printed is not checkable\n' "$BARE_PH"; FAIL=1
fi

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

# --- #118 — the UNRESOLVED row must say WHICH situation it is. ----------------
# #102's reporter met four bare `UNRESOLVED` rows on qualified cross-repo paths,
# could not tell which of several situations they were in, inferred a matching
# bug and filed against the matcher. The matcher was fine; the message was empty.
U="$WORK/unres"; mkdir -p "$U/repo/.git" "$U/neighbour/scripts"
mkdir -p "$U/neighbour/.git"
: > "$U/neighbour/scripts/contract_check.py"
# T33 — the sibling IS on disk; the prose never names it in bare text.
printf 'See `neighbour/scripts/contract_check.py` for the check.\n' > "$U/repo/u1.md"
# N36 — nothing of that name is reachable. This gets the BARE word, because the
# state is indistinguishable from a plain local break (`docs/gone.md` in a repo
# with no docs/). A draft diagnosed it anyway; N35 caught that and the branch was
# removed. Kept as a NEGATIVE so the branch cannot come back.
printf 'See `absentrepo/scripts/gone.py` for the check.\n' > "$U/repo/u2.md"
UOUT="$(python3 refcheck.py --sibling-root "$U" "$U/repo" u1.md u2.md 2>&1 || true)"

if printf '%s' "$UOUT" | grep -q 'is on disk but the prose never names it'; then
  printf '  PASS  T33 UNRESOLVED names the declined-gate case and its remedy (#118)\n'
else
  printf '  FAIL  T33 the UNRESOLVED row still carries no remedy for a reachable sibling (#118)\n'; FAIL=1
fi
if printf '%s' "$UOUT" | grep -F 'absentrepo/scripts/gone.py' | grep -qE 'UNRESOLVED$'; then
  printf '  PASS  N36 an unreachable head keeps the bare word — undiagnosable, so unremedied\n'
else
  printf '  FAIL  N36 an unreachable head was diagnosed; it cannot be told from a local break (#118)\n'; FAIL=1
fi

# N35 — the CONTROL. A plain local break must keep the BARE word: a remedy
# invented for a situation not actually diagnosed is worse than silence, and this
# step already has a scar from a printed remedy that failed when followed (#102).
printf 'A local file: `docs/definitely_absent.md`\n' > "$U/repo/u3.md"
UOUT3="$(python3 refcheck.py --sibling-root "$U" "$U/repo" u3.md 2>&1 || true)"
if printf '%s' "$UOUT3" | grep -F 'definitely_absent.md' | grep -qE 'UNRESOLVED$'; then
  printf '  PASS  N35 a plain local break still reports a bare UNRESOLVED\n'
else
  printf '  FAIL  N35 a local break was given a cross-repo remedy it cannot use\n'; FAIL=1
fi

# --- #133 / #140 / #154 — the cross-repo remedy and the three UNRESOLVED causes.
# The remedy string is PRESCRIPTIVE, so it is wrong in two directions and both
# have been shipped: draft 1 scoped it by the remedy line's CONTENT ("a line that
# carries no unqualified reference"), which an adopter can satisfy exactly and
# still break the neighbour; draft 2 scoped it by DISTANCE FROM ANY reference,
# which puts the name outside the ±1 window that rescues its own reference, so
# the remedy stopped working at all. T42 and T43 pin those two. Rung 4's window
# is `lines[i-1:i+2]`, so the rule with both halves is: on or beside THIS
# reference, and two lines clear of any OTHER unqualified one.
BR="$WORK/blastradius"
mkdir -p "$BR/repo/.git" "$BR/alpha/.git" "$BR/gamma/.git" "$BR/alpha/scripts" \
         "$BR/alpha/target" "$BR/alpha/real"
: > "$BR/alpha/CHANGELOG.md"; : > "$BR/gamma/CHANGELOG.md"
: > "$BR/alpha/scripts/present.py"; : > "$BR/alpha/target/pruned.md"
: > "$BR/alpha/real/deep.md"; ln -sfn real "$BR/alpha/linked"

# `bref <file>` runs the oracle over one seeded doc and prints its FINDINGS rows.
# `|| true`: the oracle exits 1 when it has findings, and `set -e` is on, so a
# bare capture aborts the harness the moment a seeded row does its job. House
# style, same as $UOUT above. Output is CAPTURED, then asserted with a single
# grep -- a `grep | grep -q` chain under `pipefail` can return 141 on SIGPIPE and
# turn a real match into a FAIL.
bref() { python3 refcheck.py --sibling-root "$BR" "$BR/repo" "$1" 2>&1 || true; }
has() { printf '%s' "$1" | grep -qF "$2"; }
b_say() { if [ "$1" = 1 ]; then printf '  PASS  %s\n' "$2"
          else printf '  FAIL  %s\n' "$3"; FAIL=1; fi; }

# T39 — the remedy names BOTH halves of the distance rule. A grep, so it holds
# the wording down; T42/T43 are what make the wording mean something.
printf 'See `gamma/CHANGELOG.md` for theirs.\n' > "$BR/repo/r0.md"
R0="$(bref r0.md)"
b_say "$(has "$R0" 'on or beside THIS reference, and at least two lines from any OTHER unqualified reference' && echo 1 || echo 0)" \
  "T39 the remedy states both halves of the distance rule (#133)" \
  "T39 the remedy lost a half of the distance rule — one half alone is wrong in a measured direction (#133)"

# T40 — the collateral: the remedy applied BESIDE another unqualified reference
# hands it a new candidate. Current, correct behaviour, seeded so a change to
# rung 4's windowing cannot alter it silently while the prose claims it.
printf 'The alpha repo keeps one; see `CHANGELOG.md`.\nThe gamma repo also has a qualified `gamma/CHANGELOG.md` reference.\n' > "$BR/repo/b1.md"
B1="$(bref b1.md)"
b_say "$(has "$B1" 'AMBIGUOUS (2 siblings match' && echo 1 || echo 0)" \
  "T40 a name beside another unqualified reference turns it AMBIGUOUS — the blast radius is real (#133)" \
  "T40 the blast radius did not reproduce; the #133 prose now describes behaviour that is gone"

# T42 — DRAFT 1'S FAILURE. The remedy line carries no unqualified reference at
# all, which satisfies draft 1 exactly, and the neighbour still breaks. Without
# this row the old wording reads as correct.
printf 'The alpha repo keeps one; see `CHANGELOG.md`.\nThe gamma repo is next door.\nSee `gamma/CHANGELOG.md` for theirs.\n' > "$BR/repo/b5.md"
B5="$(bref b5.md)"
b_say "$(has "$B5" 'AMBIGUOUS (2 siblings match' && echo 1 || echo 0)" \
  "T42 a remedy line with NO unqualified reference still breaks the neighbour — draft 1 was wrong (#133)" \
  "T42 draft 1's wording is no longer refutable, so the shipped rule may have been loosened back to it"

# T43 — DRAFT 2'S FAILURE, the opposite direction: two lines clear of every
# reference puts the name outside its OWN window, so nothing is rescued.
printf 'The alpha repo keeps one; see `CHANGELOG.md`.\n\nThe gamma repo is next door.\n\nSee `gamma/CHANGELOG.md` for theirs.\n' > "$BR/repo/b6.md"
B6="$(bref b6.md)"
b_say "$(has "$B6" 'gamma/CHANGELOG.md' && has "$B6" 'UNRESOLVED (sibling `gamma`' && echo 1 || echo 0)" \
  "T43 a name two lines from EVERY reference rescues nothing — draft 2 was wrong (#133)" \
  "T43 draft 2's wording now appears to work, so the ±1 window has changed and the prose is stale"

# N39 — the CONTROL, and it measures DISTANCE, which is what the rule is about.
# ⚠️ Its earlier comment credited "the scope clause" and its earlier input
# differed from T40 only by a blank line, so it measured the blank line while
# appearing to measure the clause. Now it seeds the placement the rule actually
# prescribes: beside the reference being fixed, three lines clear of the other.
printf 'The alpha repo keeps one; see `CHANGELOG.md`.\n\n\nThe gamma repo is next door.\nSee `gamma/CHANGELOG.md` for theirs.\n' > "$BR/repo/b2.md"
B2="$(bref b2.md)"
b_say "$(printf '%s' "$B2" | grep -A2 '== FINDINGS' | grep -qF 'total: 0' && echo 1 || echo 0)" \
  "N39 the prescribed placement clears its row and creates no finding (#133)" \
  "N39 the placement the remedy prescribes does not work — the remedy is unfollowable"

# T41 — repo NAMED in prose, target genuinely absent. The reason must be about
# the target, not about the prose.
printf 'The alpha repo holds it: `alpha/scripts/gone_xyz.py` is the check.\n' > "$BR/repo/b3.md"
B3="$(bref b3.md)"
b_say "$(has "$B3" 'is not in it — the target is gone or moved' && echo 1 || echo 0)" \
  "T41 a named sibling with an absent target gets the absent-target reason (#140)" \
  "T41 a named sibling with an absent target is still told the prose never names it (#140)"
b_say "$(has "$B3" 'never names it in bare text' && echo 0 || echo 1)" \
  "T41b the bare-prose reason is not printed when the prose names the repo (#140)" \
  "T41b the false reason is still printed for a repo the prose plainly names (#140)"
b_say "$(has "$B3" 'IF the reference belongs to that repo' && echo 1 || echo 0)" \
  "T41c the absent-target reason is hedged — no rung here checked whose repo it is" \
  "T41c the message asserts the target is gone from that repo without hedging whose repo it is"

# T44 / T45 — #154's population, and the reason "no rung-4 hit" is NOT "absent".
# `_tree` filters PRUNE (which holds `target` and `dist`) and rglob does not
# follow directory symlinks, so both of these files EXIST and were unindexed.
# Telling the reader they are gone is a confident wrong answer about the disk.
printf 'The alpha repo holds it: `alpha/target/pruned.md` is the check.\n' > "$BR/repo/b7.md"
B7="$(bref b7.md)"
b_say "$(has "$B7" 'EXISTS in it, but this scan did not index it' && echo 1 || echo 0)" \
  "T44 a target inside a pruned directory is reported as present-but-unindexed (#154)" \
  "T44 a file that EXISTS in the sibling is reported as gone — a confident wrong answer (#154)"
printf 'The alpha repo holds it: `alpha/linked/deep.md` is the check.\n' > "$BR/repo/b8.md"
B8="$(bref b8.md)"
b_say "$(has "$B8" 'EXISTS in it, but this scan did not index it' && echo 1 || echo 0)" \
  "T45 a target behind a directory symlink is reported as present-but-unindexed (#154)" \
  "T45 a symlinked target is reported as gone from the sibling"

# N40 — the CONTROL for the split: repo NOT named, target absent. The #118 hint
# must survive, or the fix has simply deleted it.
printf 'See `alpha/scripts/gone_xyz.py` for the check.\n' > "$BR/repo/b4.md"
B4="$(bref b4.md)"
b_say "$(has "$B4" 'never names it in bare text' && echo 1 || echo 0)" \
  "N40 an unnamed sibling still gets the #118 bare-prose hint (#140)" \
  "N40 the #118 hint was lost for the case it was written for (#140)"

# N41 — the second CONTROL: a present target with the repo named must still just
# resolve. Without it, every T-row above is satisfied by an oracle that reports
# something for every cross-repo reference.
printf 'The alpha repo holds it: `alpha/scripts/present.py` is the check.\n' > "$BR/repo/b9.md"
B9="$(bref b9.md)"
b_say "$(printf '%s' "$B9" | grep -A2 '== FINDINGS' | grep -qF 'total: 0' && echo 1 || echo 0)" \
  "N41 a present target with the repo named resolves silently" \
  "N41 a resolving cross-repo reference produced a finding"

# --- ablations for the rows above. The commit that added T39-T41 CLAIMED these
# runs and did not seed them, which is the gap docs/seeded-defects-and-ablations.md
# exists to close. `!` before the pattern means it must STOP appearing.
abl133() {  # label, old, new, doc, [!]pattern
  local label="$1" old="$2" new="$3" doc="$4" pat="$5" neg=0 out
  case "$pat" in !*) neg=1; pat="${pat#!}" ;; esac
  cp refcheck.py "$WORK/m133.py"
  if ! OLD="$old" NEW="$new" python3 - "$WORK/m133.py" <<'PY'
import os, sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
old, new = os.environ['OLD'], os.environ['NEW']
if s.count(old) != 1:
    sys.exit('mutation site occurs %d times, not once' % s.count(old))
p.write_text(s.replace(old, new))
PY
  then printf '  FAIL  ablation %s could not be applied — its site has moved\n' "$label"; FAIL=1; return; fi
  out="$(python3 "$WORK/m133.py" --sibling-root "$BR" "$BR/repo" "$doc" 2>&1 || true)"
  if [ "$neg" = 1 ]; then
    if printf '%s' "$out" | grep -qF "$pat"
      then printf '  FAIL  ablation %s changed NOTHING — the row it guards is not measuring it\n' "$label"; FAIL=1
      else printf '  PASS  ablation %s removes what its row asserts\n' "$label"; fi
  else
    if printf '%s' "$out" | grep -qF "$pat"
      then printf '  PASS  ablation %s produces the failure its row forbids\n' "$label"
      else printf '  FAIL  ablation %s changed NOTHING — the row it guards is not measuring it\n' "$label"; FAIL=1; fi
  fi
}
# A13 — revert the remedy to draft 1. T39's needle must disappear.
abl133 "A13 remedy back to draft 1" \
  "'THIS reference, and at least two lines '" "'A LINE CARRYING NO UNQUALIFIED reference '" r0.md \
  '!on or beside THIS reference'
# A14 — collapse the #140 split. T41's absent-target reason must disappear and
# the false bare-prose reason must come back; assert the latter, which is the
# defect a reader would act on.
abl133 "A14 collapse the #140 split" \
  "if sib in named_siblings():" "if False:" b3.md \
  'never names it in bare text'
# A15 — drop the exists() check. T44's population must go back to being told
# the file is gone.
abl133 "A15 drop the exists() check" \
  "if tail and (sib / tail).exists():" "if False:" b7.md \
  'the target is gone or moved'
# A16 — drop the hedge. T41c must stop passing.
abl133 "A16 drop the whose-repo hedge" \
  "'reference belongs to that repo at '" "'reference belongs there at '" b3.md \
  '!IF the reference belongs to that repo'


# --- #108 — a source file under a state directory is still source. ------------
# Reported by an adopter running /audit-context with seeded positives: two
# fabricated SOURCE names under data/ were both excused as "runtime state" and
# the run printed VERDICT: CLEAN. The step's own prose already carried the rule.
# Isolated for the same reason as the block below: extra trees would change the
# main run's neighbour count and trip X10.
ST="$WORK/statedir"; mkdir -p "$ST/repo/data" "$ST/repo/.git"
: > "$ST/repo/data/real_state.json"
printf 'Source under data: `data/fabricated_source.py` and `data/nope_not_real.json.py`\n' > "$ST/repo/s1.md"
printf 'Genuine state: `data/absent_cache.json` and `data/run_state.json`\n' > "$ST/repo/s2.md"
STOUT="$(python3 refcheck.py --sibling-root "$ST" "$ST/repo" s1.md s2.md 2>&1 || true)"

for f in fabricated_source.py nope_not_real.json.py; do
  if printf '%s' "$STOUT" | grep -F -- "$f" | grep -q 'runtime state'; then
    printf '  FAIL  T32 %s is still excused as runtime state (#108)\n' "$f"; FAIL=1
  else
    printf '  PASS  T32 %s is not excused by the directory signal (#108)\n' "$f"
  fi
done

# N37 — the CONTROLS review had to supply, because the first SOURCE_EXT list was
# too broad and its comment claimed the residual gap was narrow. It was not:
# these three are ordinary real-world runtime state whose extensions have a
# source meaning in some other ecosystem. All three regressed to bare UNRESOLVED
# rows — the unactionable shape #118 exists to reduce, and #118's hint cannot
# fire for them because their heads exist locally.
printf 'Real state: `var/cache/prod/App_KernelProdContainer.php` `data/segment0001.ts` `cache/bundle.js`\n' > "$ST/repo/s3.md"
STOUT3="$(python3 refcheck.py --sibling-root "$ST" "$ST/repo" s3.md 2>&1 || true)"
for f in App_KernelProdContainer.php segment0001.ts bundle.js; do
  if printf '%s' "$STOUT3" | grep -F -- "$f" | grep -q 'runtime state'; then
    printf '  PASS  N37 %s is still runtime state — an ambiguous extension is not evidence of source\n' "$f"
  else
    printf '  FAIL  N37 %s was reported as a break; SOURCE_EXT is too broad again (#108)\n' "$f"; FAIL=1
  fi
done

# N34 — the CONTROL, and the reason this pair is not just "stop excusing data/".
# Genuine runtime state under the same directory must still resolve; without this
# row, deleting rung 3 outright would score 2/2 above.
for f in absent_cache.json run_state.json; do
  if printf '%s' "$STOUT" | grep -F -- "$f" | grep -q 'runtime state'; then
    printf '  PASS  N34 %s still resolves as runtime state\n' "$f"
  else
    printf '  FAIL  N34 the #108 fix broke genuine rung-3 resolution for %s\n' "$f"; FAIL=1
  fi
done

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

# N38 — markdown emphasis. A first version of the #119 fix treated `_` as a word
# character, so `_alpharepo_` — standard italics around a repo name — stopped
# marking the sibling it names. A repo name containing an underscore is rarer
# than italics around one.
printf 'We integrate with _alpharepo_ for this:\n`scripts/only_in_alpha.py`\n' > "$P/repo/h4.md"
PROV4="$(python3 refcheck.py --sibling-root "$P" "$P/repo" h4.md 2>&1 || true)"
if printf '%s' "$PROV4" | grep -qF -- 'sibling alpharepo -> scripts/only_in_alpha.py'; then
  printf '  PASS  N38 markdown emphasis around a sibling name still marks it (#119)\n'
else
  printf '  FAIL  N38 _alpharepo_ no longer marks — the boundary class ate markdown italics\n'; FAIL=1
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
# #118 moved this site: the ternary now selects between a DIAGNOSED reason
# string and UNCONFIRMED, so the mutant text changed with it. The fixture
# refused to apply the old mutant rather than silently passing — which is
# the whole point of asserting that an ablation could be applied at all.
ablate "A3 everything unconfirmed"  "why if rung4_runnable else UNCONFIRMED" "UNCONFIRMED" "$X3N"
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
