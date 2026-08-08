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
     description: Diff-driven pre-commit review — picks review lenses based on what changed, from single-pass adversarial to full multi-model battery
     disable-model-invocation: false
     --- -->

Pre-commit review of pending changes. Scope and depth are driven by what changed, not a fixed checklist.

## Step 1 — Diff and classify

Run `git diff --stat` and `git diff --cached --stat` to see pending changes, and `git diff --summary` alongside them. **`--stat` alone cannot see a mode change, a rename, a submodule, or a binary** — all four render as zero or near-zero lines, and three of them are carve-outs below. A carve-out you cannot observe is not in force. Classify each changed file into a risk tier:

| Tier | File patterns | Depth |
|------|-------------|-------|
| **HIGH** | `templates/**`, `adopt.md`, `/README.md`, `docs/GUIDE.md`, `docs/verification-rationale.md`, `tests/**`, `scripts/**`, `.claude/skills/**`, `.gitignore` | Full battery (3-4 lenses) |
| **MEDIUM** | `CLAUDE.md`, `docs/**`, `templates/checklists/**`, `templates/physics-tests/**`, `templates/test-fixtures/**` | Two lenses (adversarial + doc-accuracy) |
| **LOW** | `CHANGELOG.md`, `memory/**`, `docs/work-items/**` | One lens (adversarial) |

`**` crosses directory levels; a leading `/` anchors to the repo root. **The most specific matching pattern wins** — `templates/checklists/foo.md` is MEDIUM, not HIGH, even though `templates/**` also matches it. Where no pattern is more specific than another, take the highest tier.

The HIGH row is the normative surface — everything an adopter consumes or executes. Four entries are easy to miss, and each is here because it burned someone: `scripts/**` is shell that runs on another machine; `.claude/skills/**` holds the reference installs adopters copy, so a defect there ships to every install derived from it; `/README.md` is anchored so it means *the repo's own* README, not every nested one; and `.gitignore` decides what is published at all — a one-line change there has exposed private content in a public repo.

### Magnitude gate

The tier above is set by *path*. Depth is also set by *size* — but size is the weaker signal, so the exceptions are stated first and override everything below them.

**Always full depth, regardless of size.** Each of these is dangerous *because* it is small, and each would otherwise slip through on line count alone:

- **`.gitignore`** — see the paragraph above; one line has exposed private content in a public repo.
- **Renames and moves** — `git diff --stat` reports `0 insertions(+), 0 deletions(-)` under `-M`, while every reference to the old path breaks.
- **Permission changes** — also zero insertions and deletions, and invisible without `--summary`. A `chmod -x` on a shipped script makes it unrunnable for everyone downstream.
- **Binary files and submodule pointers** — the other two members of the zero-line class. A submodule bump changes one line and can move an arbitrary amount of code.
- **Any change to a shell script or an executable, wherever it lives** — `scripts/**` and `tests/**` are both HIGH because they are code that runs on someone else's machine, and shell breaks in one character. A small edit would otherwise lose the shell-correctness lens, which is the reason those paths are HIGH at all.
- **Any non-frontmatter edit under `.claude/skills/**`** — HIGH because a defect there ships to every install derived from it; that is as true of a three-line body edit as of a frontmatter one.
- **Frontmatter edits under `.claude/skills/**`** — removing one `---` silently unregisters a skill.
- **A new executable, or any new file in a HIGH path** — the tier for new content has not been decided yet.
- **Any diff that removes or loosens a check** — a deleted guard, a weakened assertion, a broadened exclusion. Loosenings are characteristically a handful of lines, and this is the class the seeded-true-positives rule exists for.

**Otherwise size sets the depth.** Size means the whole change that will land, not the slice in front of you — 10 lines committed locally plus 15 staged is a 25-line change, and reviewing each half on its own means nothing ever sees the whole. Sum staged, unstaged, and any local commits not yet pushed:

```bash
git diff --shortstat; git diff --cached --shortstat
git log @{u}.. --shortstat 2>/dev/null || echo 'no upstream — count all commits on this branch'
```

On a branch with no upstream the third command has nothing to compare against; fall back to the whole branch rather than silently dropping the term.

Line count is a proxy, and in these templates a weak one — they are written one sentence per line, so replacing two dense normative paragraphs is four changed lines while a whitespace reflow is a hundred. **When the line count and your read of the change disagree, the line count is wrong.** Escalate.

| Changed lines | Depth |
|---------------|-------|
| **< 20** | One adversarial pass |
| **20–200** | Path tier as above |
| **> 200** | Full battery, whichever tier the paths fall in |

Run that single pass in a **fresh context** — a subagent if your tool provides them, otherwise a separate pass that re-reads the diff from scratch. Reviewing your own edit in the context that produced it is the self-certification failure this skill exists to prevent; the saving comes from running *one* independent reviewer instead of four, not from dropping independence.

The gate changes how many lenses run. It never changes *whether* a change is reviewed — every diff still gets at least one adversarial pass.

If only LOW files changed **and the gate above does not escalate**, do a single adversarial pass and skip to Step 3. The gate wins where the two disagree: a 400-line change to `memory/**` is still a large change, and tier is about blast radius, not size.

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

Go in assuming the change is refutable and try to break it. Report REFUTED with a
**concrete** failure — a triggering input, an edge case, or a contradiction between
two things the change now asserts. Prose contradictions count and often have no
triggering input; do not withhold one for lacking a repro. Report NOT REFUTED only
after a thorough attempt has failed to produce any of those.

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
