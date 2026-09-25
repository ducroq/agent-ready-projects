# Cost and record discipline

**Status**: in progress (opened 2026-09-12)

History and measurements: docs/work-items/archive/cost-and-record-discipline-history.md

## What & Why

Running the framework costs too much, and most of that cost is not the product. Two things drive it: review rounds that end up proofreading the record (memory, changelog, ledgers, baselines), and an auto-loaded surface bigger than the budget the framework itself sets. Framed by #126 (review cost unpriced), #109/#143 (auto-loaded set), H-025 (most findings are on the record, not the change).

Goal: make the framework cheaper to run without cutting review of the shipped surface (`templates/`, `.claude/skills/`), which measurably earns its keep (H-020).

**What works**: find a duplicate, name the authority, diff the two (the copy is sometimes the right one), then delete the copy. **What fails**: tightening prose. Skill bodies are a real per-invocation cost, because the harness injects the whole body; most other big files are only grepped, so their size costs little.

## Current Status

**Savepoint — 2026-09-25.**

- **Last action**: v1.46.0 released (tagged and pushed 2026-09-25; global skills refreshed). It carries #202's fixes and token-reduction steps 1–3: the curate read surface went from 658k to 160k chars, curate's skill body from 56.9k to about 25k, review-changes' from 43.5k to about 27k, and the verify runner moved to `scripts/verify-runner.sh`. #201's arc idea is folded into curate as H-031.
- **Next action**:
  1. Decide H-022 (confirmed by its own test on 2026-09-25): recommended fix is a release check that fails until the CHANGELOG states net adopter-facing growth.
  2. Measure whether the cuts hold: total spend per release (H-020), and H-031 over the next 10 curate runs.
  3. Done 2026-09-25 (#205, candidate v1.46.1): `audit-context` 22.4k → 16.8k, `update-drift` 23.6k → 15.3k, `release` 21.2k → 15.2k. Next: `CLAUDE.md` (26k, loaded every session).
- **Blockers**: none.

**Before each cut**, check it still holds:
- Account for every `<!-- verify: -->` probe by name, before and after the cut. A probe may move but must not vanish.
- Run `bash tests/lint/run.sh` after each move. Rule 1 catches dead `CLAUDE.md` paths, rule 2 orphaned topic files.
- A structural section with a prescribed size (e.g. `## Key Paths`) is a slot. Do not delete it or grow it.

## Open items

Issues still open on this work item's thread:
- **#195**: rule 16 binds the template header only, and three surfaces still carry hand-maintained copies of the same scope fact.
- **#160**: rule 11 does not cover `tests/**/*.sh`. Attach the `set -u# <orphan>` class, which `bash -n` passes.
- **#192**: ship H-015 to `templates/`, which means naming the adopter-installed file that changed before writing `Closes #N`.
- **#191**: AACR-Bench as external evidence. Parked.

Also still to do (detail in the history file):
- **Measure v1.44.0's re-tiering plus round cap** on total spend per release. Does it reduce spend or only move it? The cap removes the ledger's recall instrument (H-020).
- **Record shape (#178/#179/#180)**: the retirement destination is decided (an archive file beside each source log). This repo's own gotcha log needs a `[RESOLVED]` marking pass before it can be split.
- **Stale-number check**: the predicate is equality, not presence. Consider reusing `<!-- verify: -->` probes rather than writing a new lint rule.
- **Rating-floor check (#168)**: a claim whose verification log says PARTIAL or NEEDS WORK must not be rated ESTABLISHED.
- **Unfiled**: Step 1.5 cannot see gitignored `memory/`. MEDIUM is unreachable in `.claude/review-profile.md`. `tests/fixtures/block-parses/` has no ablations.
- **Maintainer's call**: how big should the record be? Keep and mechanize, or prune hard.

## Outcome

