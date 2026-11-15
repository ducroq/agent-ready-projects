# Cost and record discipline

**Status**: in progress (opened 2026-09-12)

History and measurements: docs/work-items/archive/cost-and-record-discipline-history.md

## What & Why

Running the framework costs too much, and most of that cost is not the product. Two things drive it: review rounds that end up proofreading the record (memory, changelog, ledgers, baselines), and an auto-loaded surface bigger than the budget the framework itself sets. Framed by #126 (review cost unpriced), #109/#143 (auto-loaded set), H-025 (most findings are on the record, not the change).

Goal: make the framework cheaper to run without cutting review of the shipped surface (`templates/`, `.claude/skills/`), which measurably earns its keep (H-020).

**What works**: find a duplicate, name the authority, diff the two (the copy is sometimes the right one), then delete the copy. **What fails**: tightening prose. Skill bodies are a real per-invocation cost, because the harness injects the whole body; most other big files are only grepped, so their size costs little.

## Current Status

**Savepoint — 2026-11-15 (wrap): `continue` starts at step 1 below and does not start anything else. Prune, thin, mechanize, retire (the engineer, 11-14 and again 11-15: "Large read surface ?? that means we need to start pruning, thinning, mechanizing, retiring!").** Rank every cut by bytes × how often it loads.

**Measured 11-15: thinning `curate` is exhausted; mechanizing is the route.** A 1.5k cut of Step 0 into rationale pointers was refuted by a fresh reader: the rationale is not on an adopter's install, so operative clauses moved there are lost to the running agent. Only prose a shipped script **prints** can leave a skill body (#332 comment). `curate` is 20.7k against the ≤18.9k target; get there by scripts, not by deleting rules.

1. ✅ **#306** merged (#338): skip, shape and URL sections count by default, `--verbose` lists them; SPEC records the wrong-marker trade (the engineer's call). **#332** on branch `refcheck/section-legends`: legends print only when their section has members, Step 4 −2475 bytes. A fresh reader caught four losses in the cut, all fixed. **Lesson: a conditional legend is the cheap form of moving prose to a script — paid only on runs that need it — but a clause the agent needs on every run (the gate idiom) must stay in the skill.**
2. **Mechanize `curate` Step 0 sub-step 3** (3.9k, every session end): the verify-runner's closing lines already carry the dispositions; move "four ways a probe passes while false" and the negative-claim guard into what the runner prints or into a probe linter. Then sub-step 6 (3.3k): a script that lists and sums the auto-loaded set (it is the same measurement lint rule 15 makes) so the prose stops describing it.
3. **#333**: `review-changes` Step 1 into a script, after #268. Engineer's call.
4. **Retire**: H-031 is at 10 of 10 runs, 0 catches, against a bar of 3; its Method says cut `curate` "Before Step 0" (1.7k). Blocked only on a reply from #201's author (message sent 11-13). If no reply by the next session, ask the engineer whether to proceed without it.
5. **Release v1.53.0** (`/release`, the engineer's to invoke): #312-#316, #327, #329, #330, #335, #336 are unreleased. The candidate's size line is measured (−1223 bytes vs v1.52.2).
6. **#303** (rationale pointer in each `SKILL.md` body; adds bytes, pay for it from step 2). H-026 at 4 of 5.
7. Triage the open issues for any a prune or a check can close; #276, #238 and #237 looked cheapest on 11-14.

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

