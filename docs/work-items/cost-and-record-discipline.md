# Cost and record discipline

**Status**: in progress (opened 2026-09-12)

History and measurements: docs/work-items/archive/cost-and-record-discipline-history.md

## What & Why

Running the framework costs too much, and most of that cost is not the product. Two things drive it: review rounds that end up proofreading the record (memory, changelog, ledgers, baselines), and an auto-loaded surface bigger than the budget the framework itself sets. Framed by #126 (review cost unpriced), #109/#143 (auto-loaded set), H-025 (most findings are on the record, not the change).

Goal: make the framework cheaper to run without cutting review of the shipped surface (`templates/`, `.claude/skills/`), which measurably earns its keep (H-020).

**What works**: find a duplicate, name the authority, diff the two (the copy is sometimes the right one), then delete the copy. **What fails**: tightening prose. Skill bodies are a real per-invocation cost, because the harness injects the whole body; most other big files are only grepped, so their size costs little.

## Current Status

**Savepoint — 2026-11-16: the engineer decided four things (11-16). Order: (a) `/release` v1.53.0 today, the engineer invokes it; (b) #309, fix as proposed (~+100 bytes accepted); (c) #318 via a script check: before committing `memory/`, list files this session did not change and refuse them; (d) #268, then #333 (step 3). `continue` takes the first of these not done. Prune, thin, mechanize, retire (the engineer, 11-14 and again 11-15: "Large Read surface ?? that means we need to start pruning, thinning, mechanizing, retiring!").** Rank every cut by bytes × how often it loads. `curate` is ~19.9k against ≤18.9k.

**Measured 11-15: thinning `curate` is exhausted, and scripting is now mostly exhausted too.** Rationale pointers are dead on adopter installs; only prose a shipped script prints can leave a skill body, and only if no step needs it before the script runs (gotcha 2026-11-15). Scripting sub-steps 3 and 6 bought −463 bytes, not 3k. `curate` is ~21.3k bytes against ≤18.9k: what remains needs judgement, so **retiring** (step 4) is the next lever.

1. ✅ **#306** merged (#338): skip, shape and URL sections count by default, `--verbose` lists them; SPEC records the wrong-marker trade (the engineer's call). **#332** merged (#339): legends print only when their section has members, Step 4 −2475 bytes. A fresh reader caught four losses in the cut, all fixed. **Lesson: a conditional legend is the cheap form of moving prose to a script — paid only on runs that need it — but a clause the agent needs on every run (the gate idiom) must stay in the skill.**
2. ✅ **`curate` Step 0 mechanized, partly**: `scripts/autoload-size.sh` carries sub-step 6's measurement and over-budget order; verify-runner notes two probe shapes. `curate` −463 bytes, not the 3k hoped: a fresh reader showed sub-step 3's examples are needed before the runner runs, and the trim rules serve Step 3 under budget. `curate` is ~21.3k against ≤18.9k; what remains needs intent, so the next cut is retiring (step 4), not scripting.
3. **#333**: `review-changes` Step 1 into a script, after #268. Engineer's call.
4. ✅ **Retired** H-031's "Before Step 0" from `curate` (−1751 bytes; engineer's go 11-15 without #201's reply). A fresh reader found no dangling refs; it noted the section's commit/push/watcher rules now survive nowhere in `curate` (GUIDE.md covers "don't commit unless asked").
5. **Release v1.53.0** (`/release`, the engineer's to invoke): #312-#316, #327, #329, #330, #335, #336, #343-#345, #347, #350, #352, #353 are unreleased. The candidate's size line in `CHANGELOG.md` is the measurement; do not copy it here.
6. **#303** (rationale pointer in each `SKILL.md` body; adds bytes, pay for it from step 2). H-026 at 4 of 5.
7. ✅ Cheap issues: #238 (#344), #276 (#345), #237 (#347) merged and closed 11-15; #296 closed as obsolete (its section was cut in #343).
8. ✅ The four rules the H-031 cut dropped stay out (engineer, 11-15).
9. ✅ H-021 resolved, supported for this repo with the fixer as classifier (engineer, 11-15); 10 hypotheses open.
10. ✅ Retire candidates found and preregistered (engineer, 11-15): `curate` Step 0.4 index self-consistency (H-036, 1241 bytes) and Step 4 doc sync (H-037, 1128 bytes) had no recorded catch here. Each is kept at 2 of 8 curate runs, else cut. **Every curate run from now: tally both in the session file.** Together they would put `curate` under 18.9k.
11. ✅ #345 fresh-read: one false free (no `origin` remote + a `./origin` dir) and invalid ref names, fixed in #350 (merged 11-15, seeded, no second reader). Release blocker cleared.
12. **Triage, in progress**: #341 (#352, refcheck example row stable, T76) and #279 (#353, SPEC fourth UNRESOLVED cause) merged 11-16. **Next: #309** (future `Last audit:` date: treat as malformed in `curate`, write it from the system clock in `audit-context`; ~+100 bytes). Then #241 (adds bytes; needs a retire to pay).

**Done 11-15** (merged #335, #336): `curate` Step 0 −364 bytes (only what the runner prints, a duplicate pointer, three anecdotes to the rationale); `CLAUDE.md` 14.9k → 14.1k (deleted what duplicates a named authority; the release snippet it dropped contradicted the CHANGELOG header). Both trims had a fresh-reader comparison; each caught losses the author missed (H-035 note). `/review-changes` was not run on either; the fresh readers were the review.

Every thinning gets a fresh lens **before** the commit, `memory/` included, comparing the new text against the code. Lock the ratchets **last**, after review (gotcha x8). Branch each PR from master; never stack (`CLAUDE.md`). The 11-13 work is unreleased; `/release` is the engineer's to invoke. Older savepoints: `docs/work-items/archive/cost-and-record-discipline-history.md`.

**Before each cut**, check it still holds:
- Account for every `<!-- verify: -->` probe by name, before and after the cut. A probe may move but must not vanish.
- Run `bash tests/lint/run.sh` after each move. Rule 1 catches dead `CLAUDE.md` paths, rule 2 orphaned topic files.
- A structural section with a prescribed size (e.g. `## Key Paths`) is a slot. Do not delete it or grow it.

## Open items

Issues still open on this work item's thread:
- **#160**: rule 20 parses `tests/**/*.sh` and rule 17 covers welded comments on the other builtins. Open only for a backtick pair in double quotes, which parses as a command substitution.
- **#191**: AACR-Bench as external evidence. Parked.

Also still to do (detail in the history file):
- **Measure v1.44.0's re-tiering plus round cap** on total spend per release. Does it reduce spend or only move it? The cap removes the ledger's recall instrument (H-020).
- **Record shape (#178/#179/#180)**: the retirement destination is decided (an `archive/` folder beside each source log, #274). This repo's own gotcha log needs a `[RESOLVED]` marking pass before it can be split.
- **Stale-number check**: the predicate is equality, not presence. Consider reusing `<!-- verify: -->` probes rather than writing a new lint rule.
- **Unfiled**: Step 1.5 cannot see gitignored `memory/`. MEDIUM is unreachable in `.claude/review-profile.md`. `tests/fixtures/block-parses/` has no ablations.
- **Maintainer's call**: how big should the record be? Keep and mechanize, or prune hard.
- **Two budgets, two units (moved verbatim from CLAUDE.md's header, 2026-09-25)**: ⚠️ **No size is recorded here** — a size claim about CLAUDE.md goes stale on the next edit to CLAUDE.md. Re-derive: `{ wc -m CLAUDE.md; wc -m "$HOME/.claude/projects/<slug>/memory/MEMORY.md"; }`. **Two budgets, and they are measured in different units:** `templates/audit-context.md` Step 1 flags *this file* over 35,000 / 40,000 in **bytes**; the cap that bit here is 40,000 on the **auto-loaded set**, in characters, which this file alone was always under. `wc -c` reads ~2% high against `wc -m`. Two instruments for one number, and that is **not settled** — file it, do not resolve it in passing.

## Outcome

