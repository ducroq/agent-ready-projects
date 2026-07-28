# Review Changes

<!-- SAVE AS: .claude/skills/review-changes/SKILL.md (Claude Code)
     For other tools, run this as a pre-commit prompt manually.

     This is a skill (/review-changes) that reviews staged or unstaged
     changes against the previous commit. It picks review lenses based on
     what changed — not every change needs the full multi-model battery.

     Claude Code skills require SKILL.md as the entry point inside a
     named directory under .claude/skills/. Add frontmatter:
     ---
     name: review-changes
     description: Diff-driven review — picks review lenses based on what changed, from single-pass adversarial to full multi-model battery
     disable-model-invocation: false
     --- -->

Pre-commit review of pending changes. Scope and depth are driven by what changed, not a fixed checklist.

## Step 1 — Diff and classify

Run `git diff --stat` and `git diff --cached --stat` to see pending changes. Classify each changed file into a risk tier:

| Tier | File patterns | Depth |
|------|-------------|-------|
| **HIGH** | `templates/*`, `docs/GUIDE.md`, `tests/lint/*`, `templates/test-verify-memory.md`, `docs/verification-rationale.md` | Full battery (3-4 lenses) |
| **MEDIUM** | `CLAUDE.md`, `*.md` in `docs/`, `templates/checklists/*`, `templates/physics-tests/*`, `test-fixtures/*` | Two lenses (adversarial + doc-accuracy) |
| **LOW** | `CHANGELOG.md`, `memory/*`, `docs/work-items/*` | One lens (adversarial) |

Pick the highest tier that applies. If only LOW files changed, do a single adversarial pass and skip to Step 3.

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
- templates/audit-context.md: Steps 1-7 in order, work-item reachability in Step 5
- docs/GUIDE.md: all claimed paths resolve, no broken anchors, version badge matches CHANGELOG
- tests/lint/run.sh: deterministic checks, no network calls, explicit allowlists not blanket skips
- templates/README.md: naming map covers all templates, tool-specific paths correct

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
