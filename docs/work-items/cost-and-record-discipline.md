# Cost and record discipline

**Status**: in progress (opened 2026-09-12)

History and measurements: docs/work-items/archive/cost-and-record-discipline-history.md

## What & Why

Running the framework costs too much, and most of that cost is not the product. Two things drive it: review rounds that end up proofreading the record (memory, changelog, ledgers, baselines), and an auto-loaded surface bigger than the budget the framework itself sets. Framed by #126 (review cost unpriced), #109/#143 (auto-loaded set), H-025 (most findings are on the record, not the change).

Goal: make the framework cheaper to run without cutting review of the shipped surface (`templates/`, `.claude/skills/`), which measurably earns its keep (H-020).

**What works**: find a duplicate, name the authority, diff the two (the copy is sometimes the right one), then delete the copy. **What fails**: tightening prose. Skill bodies are a real per-invocation cost, because the harness injects the whole body; most other big files are only grepped, so their size costs little.

## Current Status

**Savepoint — 2026-11-13 (wrap): `continue` starts at step 1 below. Retire or mechanize before thinning (H-035).** The engineer wants pruning, thinning, mechanizing and retiring; a big read surface is the to-do. The five installed skills total 81k bytes (`wc -c .claude/skills/*/SKILL.md`); rank by bytes × load frequency, adopter skills first.

1. **`audit-context` (17.1k) and `review-changes` (19.0k): measure what a script could take over**, as was done for `curate` Step 0 on 11-13: per-step bytes, then which parts restate what a shipped script already decides. That pass found ~2.9k in `curate`, and the runner-legend move (-1.7k) was the best yield of the day.
2. **`memory/hypothesis-log.md` (25k)**: `curate` sub-step 5 reads it whole every run. H-031 closes when #201's author replies (message sent 11-13); H-026 is at 4 of 5. The gotcha log needs no thinning now that `curate` reads only its headers (`scripts/gotcha-headers.sh`).
3. **#303**: put the rationale pointer in each `SKILL.md` body for `review-changes`, `release` and `curate` (it adds bytes, so pay for it from step 1).
4. Blocked: `curate` "Before Step 0" (1.7k) and #296. Cut both when #201's author replies.
5. Open issues: triage the 10 for any a prune or a check can close.

**Done 11-13** (#312 to #315, merged): `release` and `curate` bash-comment reasoning moved to the rationale; `verify-runner.sh` now prints what to do with each disposition, so `curate` lost its table; `curate` sub-step 2 is `scripts/gotcha-headers.sh`, with a fixture. About -3k adopter bytes in total. **Lesson: run old and new over the real corpus (`find ~/repos -maxdepth 4 -name 'gotcha-log*.md'`) before review.** Two lenses passed `gotcha-headers.sh`, and the corpus then showed it dropping every Promoted row adopters keep inside the template's comment (H-026).

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

