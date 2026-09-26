# Review profile — agent-ready-projects

Read by `review-changes` Step 1. **This file is the project's half of that skill**: the
skill is the machinery and ships identically everywhere; everything below is specific to
this repo and never travels.

## Risk tiers

| Tier | File patterns | Depth |
|------|-------------|-------|
| **HIGH** | `templates/**`, `adopt.md`, `/README.md`, `docs/GUIDE.md`, `docs/verification-rationale.md`, `tests/**`, `scripts/**`, `.claude/skills/**`, `.gitignore` | **One adversarial lens, scoped by subject**, plus the guarantee lens whenever the diff touches a guarantee surface below, and **shell-correctness whenever a shell file or executable changes** |
| **MEDIUM** | `docs/GUIDE.md`, `templates/checklists/**`, `templates/test-fixtures/**` | Two lenses (adversarial + doc-accuracy) |
| **LOW** | `CLAUDE.md`, `CHANGELOG.md`, `memory/**`, `docs/work-items/**`, `docs/rationale/**`, `docs/**` | One lens (adversarial) |

⚠️ **HIGH dropped from a 3–4 lens battery to one adversarial lens on 2026-09-14 (v1.45.0), and this line
is the profile catching up with practice rather than authorising something new.** v1.44.0 and v1.45.0 were
both reviewed with one lens while this table still said battery — the drift class this repo files issues
about, found by asking what the cap had actually saved.

**What the two one-lens runs bought**: 3 blockers on v1.44.0 and 4 on v1.45.0, each at roughly a fifth of a
battery's cost, on changes that had already passed lint, both fixture suites and the author's own read. One
of them had silently zeroed a check. **The ledger's figure went from ~840k to ~107k** — per release against per run, and neither is spend: see Run budget.

⚠️ **What it gives up, stated because the ledger says so plainly**: on a four-lens round, *two* lenses each
found a blocker no other lens found. One lens will miss that class, and the two runs above cannot show
otherwise — same author, same day, same reviewer model, and both changes were small — one a deletion, one a
small addition — with a narrow and predictable blast radius. **This is a cost decision taken on cost, not a finding that breadth
was worthless.** Re-open it if a defect ships that a second lens would plausibly have caught.

🔴 **The guarantee lens is NOT part of this cut, and the reason is mechanical.** Guarantees are HIGH-gated:
a guarantee on a path tiered below HIGH can never fire, and the report renders that as a clean pass. Had
HIGH simply become "one adversarial lens", every guarantee below would have stopped being checked with
nothing saying so — the exact failure v1.45.0's retirement pass made in `curate` Step 5 and needed a lens
to catch. **Whenever a diff touches a surface in "Guarantee surfaces" below, the guarantee lens runs too.**

⚠️ **The rationale tree and the rest of the docs tree were MEDIUM until 2026-09-14 and are now LOW,
deliberately.**
The two patterns moved are `docs/rationale/**` and `docs/**` — two of the six the single LOW row
carries. They sit on a line of their own because **a bolded phrase must never end in a
`**`-suffixed glob** (the shape matrix in `CHANGELOG.md` — `grep -n 'single glob, no later code
span' CHANGELOG.md`; no line number, the file grows from the top): that form breaks under prettier 2 and 3.8.1
too. Step 1.5 reports it when the bold closes on the same line (v1.49.0, #158); a bold phrase
spanning two lines still passes, so the rule above is the thing to follow.
Measured over two full batteries that day: of ~18 findings, **8 were shipped behaviour** an adopter
would hit and **9 were about the record** — our own numbers and prose describing our own past work
(a release window off by one, an ablation described wrongly, a headline count that disagreed with
the table under it). Every blocker in both batteries was in
`templates/` or `.claude/skills/`. The doc-accuracy lens over prose about our own history cost
roughly half the review spend and produced nothing an adopter runs.

**This is a deliberate trade, so state what it gives up**: a wrong number in `docs/rationale/`
will now survive longer. That is acceptable because the rationale files are read when someone
re-opens a settled decision, not when anyone executes something — and it is not acceptable in
`templates/`, which is why the tiering splits there and not on "is it documentation".

⚠️ **`CLAUDE.md` moved MEDIUM → LOW on 2026-09-14**, on the same argument that moved `docs/**`:
nobody installs it, so a wrong line costs one session rather than every adopter. It is still
reviewed — one adversarial lens — and it is still the file the tier table itself is read from.

⚠️ **The skill's magnitude gate says a diff over 200 lines gets a "full battery, whichever tier the paths
fall in". For this repo, the HIGH row above IS the battery** — one adversarial lens, plus the guarantee
lens where a guarantee surface is touched. A >200-line diff does not reinstate three lenses; if it did, the
profile and the gate would prescribe different depths for the same change and nothing would say which wins.
**Magnitude still escalates a LOW or MEDIUM diff up to that set** — the gate's job, unchanged.

`**` crosses directory levels; a leading `/` anchors to the repo root. **The most specific
matching pattern wins** — `templates/checklists/foo.md` is MEDIUM, not HIGH, even though
`templates/**` also matches it. Where no pattern is more specific than another, take the
highest tier.

The HIGH row is the normative surface — everything an adopter consumes or executes. Four
entries are easy to miss, and each is here because it burned someone: `scripts/**` is shell
that runs on another machine; `.claude/skills/**` holds the reference installs adopters
copy, so a defect there ships to every install derived from it; `/README.md` is anchored so
it means *the repo's own* README, not every nested one; and `.gitignore` decides what is
published at all — a one-line change there has exposed private content in a public repo.

## Guarantee surfaces

⚠️ **Every path here must sit in the HIGH row above.** A guarantee on a path tiered below
HIGH can never fire — the lens is HIGH-gated — and the report renders that as a clean pass.
Check it in this direction: read each entry below, then find its tier above.

- `templates/work-item.md`: five-section structure, no frontmatter, no lifecycle state machine
- `templates/curate.md`: Steps 0-6 in order, work-item savepoint updates in Step 3
- `templates/audit-context.md`: Steps 1-9 in order, work-item reachability in Step 5,
  framework-version drift in Step 6
- `templates/review-profile.md`: the profile format the skill reads; a change here invalidates
  every adopter profile written against the old shape
- `docs/GUIDE.md`: all claimed paths resolve, no broken anchors, version badge matches CHANGELOG
- `adopt.md`: every step is executable by an agent that has only URLs and no clone; no step
  instructs a copy that would strip frontmatter; assess/adopt/update stay three separate prompts
- `tests/lint/run.sh`: deterministic checks, no network calls, explicit allowlists not blanket skips
- `scripts/*.sh`: verifying and mutating modes stay distinct; a no-op run and a clean run are
  distinguishable in the output; exits non-zero on the failure it exists to detect
- `templates/README.md`: naming map covers all templates, tool-specific paths correct,
  every skill carries its scope (user-global or project-local)
- `tests/fixtures/reference-integrity/refcheck.py`: **Step 4's runtime since v1.40.0, not an
  oracle** (#185) — a change here reaches every adopter who runs the step. Two invariants that
  live only in the source today and were each violated in one session: it must not contradict
  `SPEC.md`, which is normative and is NOT edited by the same change by default (SPEC's rung-2
  rule — *search the working tree, not the git index* — is the one that bit); and every report
  section it prints must be described in `templates/audit-context.md`, per its own header

## Run budget

**One round per release. Record each run in `memory/review-ledger.tsv`, with its `spend`.**

⚠️ **The ledger's `tokens` column is final context, not spend** (#222). Every figure in this section was measured in it, including the old ≤250,000-token budget, which no round met in spend. Measured: the 15 reviewers on 2026-09-14 before the round cap (v1.42.0; v1.43.0 has none recorded) spent 9.8M input-token equivalents, ~655k each; the 11 after it (v1.44–45) 5.2M, ~476k each; the 14 on 2026-09-25, after the skills were thinned (v1.46.0–46.1), 2.2M, ~157k each (`memory/hypothesis-log.md` H-020). Read `spend` from the subagent transcript: one usage per `message.id` (a turn spans several lines), cache write ×1.25, cache read ×0.1, output ×5.

⚠️ **A ROUND, not a run** — `templates/review-changes.md` Step 5 defines a round as one pass of the
lens set, however many lenses it holds. The first draft of this section said "one lens-run ≤120k"
and immediately contradicted the HIGH row three sections above it, which mandates the guarantee
lens alongside the adversarial one whenever a guarantee surface is touched: two runs, ~220k, over
a budget written in the same file. **The budget and the tier table have to use the same unit.**

⚠️ **Final context varies little with scope; spend does not.** In spend, the 40 reviewers on 2026-09-14 and 2026-09-25 ranged from 66k to 1.07M. What follows is in final-context tokens. Over the **48 cold runs to 2026-09-14 carrying a token count** (`narrow-fork` excluded — the
config is retired — and the one killed run's 0 with it), the range is **40k–162k, mean 107k**; and
within 2026-09-14 alone the narrowest run, one small prose diff, cost 86k against a broadest of 148k.
The spread is real but it does not track how narrow the subject was, because the cost is the
reviewer's own exploration and not the diff. **Cutting runs cuts spend, and so does cutting what each reviewer reads**: thinning the skills a reviewer reads cut spend per reviewer from ~476k to ~157k at a similar run count (H-020).
⚠️ **Not a controlled comparison**: nothing here holds the target constant while varying scope, so
this is an observed range, not a demonstration that scope is irrelevant. Re-derive before quoting:
`awk -F'\t' '$(1)~/^2026-/ && $(1)<="2026-09-14" && $(6)~/^[0-9]+$/ && $(6)>0 && $(2)!="narrow-fork" {print $(6), $(5)}' memory/review-ledger.tsv | sort -n`.

Three consequences, all of them things this repo did in the week before the budget existed:

- **A fix-round is a full run.** The `#173` and `#174` sequences paid 147k, 129k, 122k and 146k for
  rounds *after* the first. Batch the fixes and review the batch once; the round cap in
  `templates/review-changes.md` Step 5 already governs whether a second round runs at all.
- **A new gate costs a run to review and saves the next release nothing.** Lint rules 14 and 15
  cost ~255k in review on 2026-09-14 — more than two releases' worth — and neither reduces release
  spend. Build gates *between* releases, deliberately, not inside one.
- `tests/**` **gets no lens attention.** Fifteen lint rules and sixteen fixture suites cover it for
  zero tokens. A lens there is paying 110k for what a gate already asserts.

⚠️ **This section was written WITHOUT a lens pass, deliberately, and that is a departure from the
magnitude gate** — which prescribes one adversarial pass for any diff, however small. Reviewing it
would have cost ~110k against a budget whose first release saves ~240k, so the gate would have
consumed most of what the rule exists to save in the act of approving it. Bounded: it is this
repo's own profile, not an adopter-facing surface, and nothing executes it. **Not a precedent for
skipping the pass on `templates/` or `.claude/skills/`, where the gate has measurably earned its
cost every time it has run.**

## Reviewer model

**Lenses run on Sonnet by default; the session keeps its own model.** Adopted 2026-09-24 on cost.
Pass the model per lens where the tool allows it (the Agent tool's `model`).

**What the evidence says, and what it cannot say.** `review-bench`, one adversarial lens, 3 runs
per cell, 2026-09-24:

| | seeded (6) | seeded-silent (1) | clean — findings, all unmatched |
|---|---|---|---|
| Sonnet | 6/6, 6/6, 6/6 | 1/1 ×3 | 8, 7, 6 |
| Opus | 6/6, 6/6, 6/6 | 1/1 ×3 | 11, 12, 10 |

~53k–61k tokens a run either way; Opus reported ~1.6× as many unmatched findings. ⚠️ **Recall is
at the ceiling for both, so the bench cannot tell them apart. It is saturated, not a tie.** The
unmatched findings are mostly real flaws in the corpus that no seed covers, so they are not false
positives in any useful sense. Live, same day: a Sonnet lens found #199's `--ext` empty-alternative
bug, and Opus lenses found #200's zsh and `set -e` defects. That is n=1 each, on different diffs.

**Re-open** when a defect ships that a stronger reviewer plausibly would have caught, or once the
bench has seeds that separate the two models. Unmeasured, and the obvious next split to test: keep
the strongest model for shell and procedure changes, where both of today's introduced defects were.

## Test baseline

```bash
bash tests/lint/run.sh && bash tests/run-fixtures.sh
```

⚠️ **Both halves.** `tests/lint/run.sh` alone is a partial baseline — the fixture suite is
where the seeded-defect and sensitivity guards live.

## Always-full-depth carve-outs (project additions)

None beyond the skill's own list.

## Project lenses

None beyond the shipped set. ⚠️ **Present deliberately and empty**: the v1.43.0 template adds
this section, and a profile that simply omits it is indistinguishable from one that lost it in a
port — which is the failure #166 is about. An empty section says the question was asked.

## Project additions to the shipped lens prompts

None.

## Project procedure kept with the profile

None. Procedure for this repo lives in `tests/lint/` and `tests/fixtures/`, which are tracked
and run by CI, so there is nothing that would otherwise be homeless.
