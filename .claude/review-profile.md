# Review profile — agent-ready-projects

Read by `review-changes` Step 1. **This file is the project's half of that skill**: the
skill is the machinery and ships identically everywhere; everything below is specific to
this repo and never travels.

## Risk tiers

| Tier | File patterns | Depth |
|------|-------------|-------|
| **HIGH** | `templates/**`, `adopt.md`, `/README.md`, `docs/GUIDE.md`, `docs/verification-rationale.md`, `tests/**`, `scripts/**`, `.claude/skills/**`, `.gitignore` | Full battery (3-4 lenses) |
| **MEDIUM** | `docs/GUIDE.md`, `templates/checklists/**`, `templates/test-fixtures/**` | Two lenses (adversarial + doc-accuracy) |
| **LOW** | `CLAUDE.md`, `CHANGELOG.md`, `memory/**`, `docs/work-items/**`, `docs/rationale/**`, `docs/**` | One lens (adversarial) |

⚠️ **`docs/rationale/**` and the rest of `docs/**` were MEDIUM until 2026-09-14 and are now LOW,
deliberately.** Measured over two full batteries that day: of ~18 findings, **8 were shipped
behaviour** an adopter would hit and **9 were about the record** — our own numbers and prose
describing our own past work (a release window off by one, an ablation described wrongly, a
headline count that disagreed with the table under it). Every blocker in both batteries was in
`templates/` or `.claude/skills/`. The doc-accuracy lens over prose about our own history cost
roughly half the review spend and produced nothing an adopter runs.

**This is a deliberate trade, so state what it gives up**: a wrong number in `docs/rationale/`
will now survive longer. That is acceptable because the rationale files are read when someone
re-opens a settled decision, not when anyone executes something — and it is not acceptable in
`templates/`, which is why the tiering splits there and not on "is it documentation".

⚠️ **`CLAUDE.md` moved MEDIUM → LOW on 2026-09-14**, on the same argument that moved `docs/**`:
nobody installs it, so a wrong line costs one session rather than every adopter. It is still
reviewed — one adversarial lens — and it is still the file the tier table itself is read from.

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
