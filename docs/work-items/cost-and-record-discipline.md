# Cost and record discipline

**Status**: in progress (opened 2026-09-12)

History and measurements: docs/work-items/archive/cost-and-record-discipline-history.md

## What & Why

Running the framework costs too much, and most of that cost is not the product. Two things drive it: review rounds that end up proofreading the record (memory, changelog, ledgers, baselines), and an auto-loaded surface bigger than the budget the framework itself sets. Framed by #126 (review cost unpriced), #109/#143 (auto-loaded set), H-025 (most findings are on the record, not the change).

Goal: make the framework cheaper to run without cutting review of the shipped surface (`templates/`, `.claude/skills/`), which measurably earns its keep (H-020).

**What works**: find a duplicate, name the authority, diff the two (the copy is sometimes the right one), then delete the copy. **What fails**: tightening prose. Skill bodies are a real per-invocation cost, because the harness injects the whole body; most other big files are only grepped, so their size costs little.

## Current Status

**Savepoint — 2026-11-06 (wrap): next session starts with a prune.** The engineer wants pruning, thinning, mechanizing and retiring; a big read surface is the to-do. Read surface is about 79k characters. Rank by bytes × load frequency, adopter skills first, since adopters pay every run:

1. ~~`release` bash-block reasoning~~: done 2026-11-13, -1.0k on the template, reasons in `docs/rationale/release.md`, ratchet locked. `curate`'s ~0.5k of the same is still open; `audit-context` and `update-drift` are under 0.2k, so skip.
2. `curate` "Before Step 0", 1.7k: owner decided 2026-11-06: cut it, once #201's author has replied.
3. `curate` Step 0's length: two adopters read it and applied a part, because their scripts wrap it. Measure what could move into a script before cutting prose.
4. `memory/gotcha-log.md` and `memory/hypothesis-log.md`, about 25k each. Most gotchas exist only there, so a cut needs a home for the lesson; prefer a check that retires one. "Running it is the only thing" and "Retiring a check" stay until a check holds them.
5. Open issues: triage the 18 for any a prune or a check can close.

Done 11-05/06: both logs thinned, `repositioning.md` reference archived, `curate` -2.0k, `review-changes` -2.4k, H-012 closed. Every thinning gets a fresh lens **before** the commit, `memory/` included. Make that lens new-text-against-the-code: on one FS prune, old-vs-new found nothing and new-vs-code found eight older defects, and fixing them grew the doc, so size alone is not the score.

Lock the ratchets last, after any review. v1.52.2 shipped #295 on 2026-11-06, ahead of this list; the next candidate is empty, so the prune items ship together in one release; `/release` is the engineer's to invoke. Older savepoints: `docs/work-items/archive/cost-and-record-discipline-history.md`.

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

