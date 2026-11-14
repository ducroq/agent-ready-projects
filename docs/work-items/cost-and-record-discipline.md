# Cost and record discipline

**Status**: in progress (opened 2026-09-12)

History and measurements: docs/work-items/archive/cost-and-record-discipline-history.md

## What & Why

Running the framework costs too much, and most of that cost is not the product. Two things drive it: review rounds that end up proofreading the record (memory, changelog, ledgers, baselines), and an auto-loaded surface bigger than the budget the framework itself sets. Framed by #126 (review cost unpriced), #109/#143 (auto-loaded set), H-025 (most findings are on the record, not the change).

Goal: make the framework cheaper to run without cutting review of the shipped surface (`templates/`, `.claude/skills/`), which measurably earns its keep (H-020).

**What works**: find a duplicate, name the authority, diff the two (the copy is sometimes the right one), then delete the copy. **What fails**: tightening prose. Skill bodies are a real per-invocation cost, because the harness injects the whole body; most other big files are only grepped, so their size costs little.

## Current Status

**Savepoint — 2026-11-14 (wrap): `continue` starts at step 1 below and does not start anything else. Prune, thin, mechanize, retire (the engineer, again, 11-14).** The read surface GREW this session: the five installed skills went 81k → 83.3k (`wc -c .claude/skills/*/SKILL.md`), `templates/` +2.2k in the unreleased v1.53.0 candidate. Pay that back first. Rank every cut by bytes × how often it loads; mechanize a decision a script can make before thinning prose.

1. **`curate` Step 0, 11.7k of 21.1k, paid every session end.** Measure per sub-step what a shipped script already decides (`scripts/verify-runner.sh`, `gotcha-headers.sh`, `hypothesis-due.sh`) and cut the prose that restates it, as 11-13 did for sub-step 2. Target: return `curate` to ≤18.9k (its size before 11-14; 21.1k now).
2. **`CLAUDE.md`, 14.9k, loaded every session.** Over the ~15k flag in all but name. Cut with `curate` Step 0.6's new rules: delete, don't reword; pointer where the text lives; a fresh reader compares old and new (#256).
3. **#306**: refcheck summary-by-default output, a token cut on every audit. Then the decisions #332 (Step 4's section prose into refcheck output) and #333 (`review-changes` Step 1 into a script, after #268), both the engineer's call.
4. **Release v1.53.0** (`/release`, the engineer's to invoke) once steps 1-2 have shrunk it: #327, #329, #330 and 11-13's #312-#316 are unreleased.
5. **#303**: the rationale pointer in each `SKILL.md` body for `review-changes`, `release` and `curate`; it adds bytes, so pay for it from step 1. H-026 is at 4 of 5 (run old and new over the real corpus before review).
6. Triage the 29 open issues for any a prune or a check can close; #306, #276, #238 and #237 looked cheapest on 11-14.
7. Blocked: `curate` "Before Step 0" (1.7k), #296 and H-031's cut wait on a reply from #201's author (a closed PR; message sent 11-13). EXP-010 (#328, draft) waits on its remaining scripts and a spend total.

**Done 11-14** (merged #327, #329, #330; draft #328): `curate` gained the read-text rule (#324), delete-don't-reword with pointers and a fresh-reader comparison (#322, #256), the correction sweep (#320); `refcheck.py` checks itself alive every run, rung 4 included, so `audit-context` Step 4 lost its manual seed; `curate` sub-step 5 reads `scripts/hypothesis-due.sh` (26.3k → 5.1k per run here). Follow-ups filed: #331 (source per promoted rule), #332, #333.

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

