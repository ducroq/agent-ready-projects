---
name: review-changes
description: Diff-driven pre-commit review — picks review lenses based on what changed, from single-pass adversarial to full multi-model battery
disable-model-invocation: false
---

Pre-commit review of pending changes. Scope and depth are driven by what changed, not a fixed checklist.

## Step 1 — Diff and classify

Run `git diff --stat` and `git diff --cached --stat` to see pending changes. Classify each changed file into a risk tier:

| Tier | File patterns | Depth |
|------|-------------|-------|
| **HIGH** | `templates/**`, `adopt.md`, `/README.md`, `docs/GUIDE.md`, `docs/verification-rationale.md`, `tests/**`, `scripts/**`, `.claude/skills/**`, `.gitignore` | Full battery (3-4 lenses) |
| **MEDIUM** | `CLAUDE.md`, `docs/**`, `templates/checklists/**`, `templates/physics-tests/**`, `templates/test-fixtures/**` | Two lenses (adversarial + doc-accuracy) |
| **LOW** | `CHANGELOG.md`, `memory/**`, `docs/work-items/**` | One lens (adversarial) |

`**` crosses directory levels; a leading `/` anchors to the repo root. **The most specific matching pattern wins** — `templates/checklists/foo.md` is MEDIUM, not HIGH, even though `templates/**` also matches it. Where no pattern is more specific than another, take the highest tier.

The HIGH row is the normative surface — everything an adopter consumes or executes. Four entries are easy to miss, and each is here because it burned someone: `scripts/**` is shell that runs on another machine; `.claude/skills/**` holds the reference installs adopters copy, so a defect there ships to every install derived from it; `/README.md` is anchored so it means *the repo's own* README, not every nested one; and `.gitignore` decides what is published at all — a one-line change there has exposed private content in a public repo.

If only LOW files changed, do a single adversarial pass and skip to Step 3.

**If a changed file matches no pattern, treat it as MEDIUM, and name it in the report under "Unclassified" even when a HIGH file in the same diff makes the tier moot.** The naming is the point: an unrecognized path is usually new shipped content whose tier nobody has decided yet, and it will keep arriving un-triaged until someone adds a row. Do not silently drop it, and do not default it to LOW. **If it is executable or is copied into an adopter's tree, escalate it to HIGH rather than leaving it at MEDIUM** — MEDIUM omits both the guarantee-preservation and shell-correctness lenses, which are exactly the two that shipped content needs.

If no files changed, report "nothing to review" and stop.

## Step 2 — Execute review lenses

For each lens, spawn a subagent with the specific prompt below. Run lenses concurrently.

### Lens: guarantee-preservation (HIGH only)

```
You are reviewing changes to adopter-facing surfaces. These files carry
guarantees — invariants that must hold for every downstream consumer.

For each changed file, identify what it guarantees:
- templates/work-item.md: five-section structure, no frontmatter, no lifecycle state machine
- templates/curate.md: Steps 0-6 in order, work-item savepoint updates in Step 3
- templates/audit-context.md: Steps 1-8 in order, work-item reachability in Step 5, framework-version drift in Step 6
- docs/GUIDE.md: all claimed paths resolve, no broken anchors, version badge matches CHANGELOG
- adopt.md: every step is executable by an agent that has only URLs and no clone; no step
  instructs a copy that would strip frontmatter; assess/adopt/update stay three separate prompts
- tests/lint/run.sh: deterministic checks, no network calls, explicit allowlists not blanket skips
- scripts/*.sh: verifying and mutating modes stay distinct; a no-op run and a clean run are
  distinguishable in the output; exits non-zero on the failure it exists to detect
- templates/README.md: naming map covers all templates, tool-specific paths correct,
  every skill carries its scope (user-global or project-local)

For each guarantee: does the change preserve it? Flag any weakening.

Then ask: is the change broader than its stated intent? (Example: a change described as
"fixing rule 1 for .claude/" that actually relaxes the check for all gitignored dirs.)

Report: GUARANTEE OK or GUARANTEE WEAKENED for each surface touched.
```

### Lens: adversarial (all tiers)

```
You are an adversarial reviewer. Your job is to refute the changes — find what breaks,
what edge cases fail, what assumptions don't hold.

For each changed file:
1. What is the change trying to accomplish?
2. What could go wrong? Try to find at least one concrete failure scenario.
3. Are there silent failure modes — things that would pass but be wrong?
4. If this is a self-test or lint change: what real failure does the weaker test now pass silently?
5. If this touches templates: what would a downstream adopter break by following the new version?

Default stance: refuted=true. Only mark as REFUTED if you find a concrete problem.
If you can't find anything after thorough attempt, mark as NOT REFUTED.

Report: REFUTED or NOT REFUTED, with failure scenario if refuted.
```

### Lens: doc-accuracy (MEDIUM and HIGH)

```
You are reviewing documentation changes for accuracy against disk state.

For each documentation change:
1. Does every file path mentioned in the changed docs actually exist on disk?
2. Does every command mentioned (bash, git, etc.) use correct flags and syntax?
3. Do version numbers, dates, and references match what's actually shipped?
4. If a new template or pattern is documented, does the referenced file exist?
5. Are there internal inconsistencies — does the doc say one thing in one place
   and something else in another?

Report: ACCURATE or INACCURATE, with specific mismatch if found.
```

### Lens: shell-correctness (HIGH only, and only when shell files changed)

```
You are reviewing shell script changes for correctness and edge cases.

For each shell change:
1. set -u safe? (no unbound variables in changed paths)
2. Quoting correct? (variables in quotes, no word-splitting bugs)
3. Edge cases: empty input, spaces in filenames, missing files, unexpected exit codes
4. Does the change introduce any non-determinism (date, random, network)?
5. Are error exits explicit and loud, not silent?

Report: SHELL OK or SHELL ISSUE, with specific bug if found.
```

## Step 3 — Synthesize

Combine all lens reports. For each finding:
- **Severity**: BLOCKER (must fix before commit) / WARNING (should fix) / NOTE (consider)
- **Lens**: which lens found it
- **File**: where
- **Finding**: what's wrong
- **Fix**: proposed fix

If any BLOCKER: recommend fixing before commit.
If only WARNING/NOTE: recommend the user review and decide.

## Step 4 — Report

```
## Review: [N] files changed, [tier] risk, [M] lenses

### Findings

| # | Severity | Lens | File | Finding |
|---|----------|------|------|---------|
| 1 | BLOCKER | adversarial | ... | ... |

### Summary

- **Lenses run**: [list]
- **Blockers**: [N] (must fix before commit)
- **Warnings**: [N]
- **Notes**: [N]
- **Verdict**: [READY TO COMMIT | FIX BLOCKERS FIRST | REVIEW WARNINGS]
```
