# Cost and record discipline

**Status**: in progress (opened 2026-09-12)

History and measurements: docs/work-items/archive/cost-and-record-discipline-history.md

## What & Why

Running the framework costs too much, and most of that cost is not the product. Two things drive it: review rounds that end up proofreading the record (memory, changelog, ledgers, baselines), and an auto-loaded surface bigger than the budget the framework itself sets. Framed by #126 (review cost unpriced), #109/#143 (auto-loaded set), H-025 (most findings are on the record, not the change).

Goal: make the framework cheaper to run without cutting review of the shipped surface (`templates/`, `.claude/skills/`), which measurably earns its keep (H-020).

**What works**: find a duplicate, name the authority, diff the two (the copy is sometimes the right one), then delete the copy. **What fails**: tightening prose. Skill bodies are a real per-invocation cost, because the harness injects the whole body; most other big files are only grepped, so their size costs little.

## Current Status

**Savepoint — 2026-10-27 (after v1.50.0).**

- **Last action**: v1.50.0 released 2026-10-27 (tagged, pushed, globals refreshed): `review-changes` keeps an all-LOW diff at one pass at any size, and the profile gains an optional `Reviewer model` (#258), after infra reported ~230k tokens on a 278-line docs diff. Before that, v1.49.2 released (tagged and pushed 2026-09-26; global skills refreshed). v1.49.1 carried #228 (`audit-context` Step 2 routing), v1.49.2 carries #233 (`curate` Step 1 places a new gotcha above the Promoted heading and checks for a split). No issues open.
- **Next action** (savepoint 2026-10-27; the engineer asked for pruning):
  1. **Prune.** Run `/audit-context` (last run 2026-09-26), then retire, archive, mechanize and thin. Rank cuts by bytes × load frequency. Measured 2026-10-27, in bytes:
     - **Skill bodies, paid by adopters on every invocation**: `review-changes` 26.6k, `curate` 25.9k, `audit-context` 17.6k, `release` 15.9k, `update-drift` 15.7k.
     - **The `curate` read surface here**: `memory/gotcha-log.md` 65k (56 entries), and `memory/hypothesis-log.md` 53k, with 19 open entries against a clutter line of ~10; H-023 archived as dormant 2026-10-27, and no other entry is past its review date.
     - **`CLAUDE.md`**: 14.7k chars, at curate's 15k flag.
     - **Moves that work**: archive resolved gotchas and dormant hypotheses, de-duplicate against an authority, and turn prose guards into lint rules (rule 21 now checks README/GUIDE version lines, #246). Tightening prose does not work.
  2. **Infra's estate cost practices, received 2026-10-27**: budget visibility, session discipline, model routing, spend estimation. They are input only. Decide what, if anything, becomes framework guidance. Candidates: the probe-first API cost estimate, and "don't trust a tool's own meter".
  3. **The engineer's idea (2026-10-27): steno and a glossary for internal memory** (`memory/` only, never adopter-facing). It cuts against `CLAUDE.md`'s "never compress prose" and #256 (trims drop operative clauses), so trial it on one file before adopting it. Measure tokens (`wc -c` is not tokens) and whether a cold session still acts on every clause.
  4. **H-031** (curate's arc section): 4 of 10 runs, 0 catches. The trigger has fired; it is kept to run 10, with the contributor to be asked (engineer, 2026-10-21).
- **Blockers**: none.

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
- **Record shape (#178/#179/#180)**: the retirement destination is decided (an archive file beside each source log). This repo's own gotcha log needs a `[RESOLVED]` marking pass before it can be split.
- **Stale-number check**: the predicate is equality, not presence. Consider reusing `<!-- verify: -->` probes rather than writing a new lint rule.
- **Unfiled**: Step 1.5 cannot see gitignored `memory/`. MEDIUM is unreachable in `.claude/review-profile.md`. `tests/fixtures/block-parses/` has no ablations.
- **Maintainer's call**: how big should the record be? Keep and mechanize, or prune hard.
- **Two budgets, two units (moved verbatim from CLAUDE.md's header, 2026-09-25)**: ⚠️ **No size is recorded here** — a size claim about CLAUDE.md goes stale on the next edit to CLAUDE.md. Re-derive: `{ wc -m CLAUDE.md; wc -m "$HOME/.claude/projects/<slug>/memory/MEMORY.md"; }`. **Two budgets, and they are measured in different units:** `templates/audit-context.md` Step 1 flags *this file* over 35,000 / 40,000 in **bytes**; the cap that bit here is 40,000 on the **auto-loaded set**, in characters, which this file alone was always under. `wc -c` reads ~2% high against `wc -m`. Two instruments for one number, and that is **not settled** — file it, do not resolve it in passing.

## Outcome

