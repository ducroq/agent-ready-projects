# Review profile — agent-ready-projects

Read by `review-changes` Step 1. **This file is the project's half of that skill**: the
skill is the machinery and ships identically everywhere; everything below is specific to
this repo and never travels.

## Risk tiers

| Tier | File patterns | Depth |
|------|-------------|-------|
| **HIGH** | `templates/**`, `adopt.md`, `/README.md`, `docs/GUIDE.md`, `docs/verification-rationale.md`, `tests/**`, `scripts/**`, `.claude/skills/**`, `.gitignore` | Full battery (3-4 lenses) |
| **MEDIUM** | `CLAUDE.md`, `docs/**`, `templates/checklists/**`, `templates/test-fixtures/**` | Two lenses (adversarial + doc-accuracy) |
| **LOW** | `CHANGELOG.md`, `memory/**`, `docs/work-items/**` | One lens (adversarial) |

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
- `templates/audit-context.md`: Steps 1-8 in order, work-item reachability in Step 5,
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

## Test baseline

```bash
bash tests/lint/run.sh && bash tests/run-fixtures.sh
```

⚠️ **Both halves.** `tests/lint/run.sh` alone is a partial baseline — the fixture suite is
where the seeded-defect and sensitivity guards live.

## Always-full-depth carve-outs (project additions)

None beyond the skill's own list.
