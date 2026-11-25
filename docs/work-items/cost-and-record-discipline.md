# Cost and record discipline

**Status**: in progress (opened 2026-09-12)

History and measurements: docs/work-items/archive/cost-and-record-discipline-history.md

## What & Why

Running the framework costs too much, and most of that cost is not the product. Two things drive it: review rounds that end up proofreading the record (memory, changelog, ledgers, baselines), and an auto-loaded surface bigger than the budget the framework itself sets. Framed by #126 (review cost unpriced), #109/#143 (auto-loaded set), H-025 (most findings are on the record, not the change).

Goal: make the framework cheaper to run without cutting review of the shipped surface (`templates/`, `.claude/skills/`), which measurably earns its keep (H-020).

**What works**: find a duplicate, name the authority, diff the two (the copy is sometimes the right one), then delete the copy. **What fails**: tightening prose. Skill bodies are a real per-invocation cost, because the harness injects the whole body; most other big files are only grepped, so their size costs little.

## Current Status

**Savepoint — 2026-11-25.** The record prune ran (`memory/` and this folder). Next on this item: step 1.

Rank every cut by bytes × how often it loads. Thinning and scripting `curate` are mostly exhausted. Rationale pointers are dead on adopter installs. Only prose a shipped script prints can leave a skill body, and only if no step needs it before the script runs. A clause the agent needs on every run must stay in the skill. Retiring is the next lever.

1. **#309**: treat a future `Last audit:` date as malformed in `curate`, and write it from the system clock in `audit-context` (~+100 bytes, accepted by the engineer 2026-11-16).
2. **#318**: a script check before committing `memory/`: list files this session did not change and refuse them. First settle per file or per hunk; a per-file check misses two sessions' lines in one file.
3. **#268**, then **#333** (`review-changes` Step 1 into a script; engineer's call).
4. **#303** (rationale pointer in each `SKILL.md` body) and **#241**: both add bytes and need a retire to pay.
5. **Adopter side, the bigger recurring cost**: skill templates are 7–20 KB each. The route is `docs/work-items/skill-delivery-lessons-from-orca.md`.

Every thinning gets a fresh lens **before** the commit, `memory/` included, comparing the new text against the code. Lock the ratchets **last**, after review. Branch each PR from master; never stack (`CLAUDE.md`).

**Before each cut**, check it still holds:
- Account for every `<!-- verify: -->` probe by name, before and after the cut. A probe may move but must not vanish.
- Run `bash tests/lint/run.sh` after each move. Rule 1 catches dead `CLAUDE.md` paths, rule 2 orphaned topic files.
- A structural section with a prescribed size (e.g. `## Key Paths`) is a slot. Do not delete it or grow it.

## Open items

- **Measure v1.44.0's re-tiering plus round cap** on total spend per release. Does it reduce spend or only move it? The cap removes the ledger's recall instrument (H-020).
- **Stale-number check**: the predicate is equality, not presence. Consider reusing `<!-- verify: -->` probes rather than writing a new lint rule.
- **Unfiled**: Step 1.5 cannot see gitignored `memory/`. MEDIUM is unreachable in `.claude/review-profile.md`. `tests/fixtures/block-parses/` has no ablations.
- **Two budgets, two units (moved verbatim from CLAUDE.md's header, 2026-09-25)**: ⚠️ **No size is recorded here** — a size claim about CLAUDE.md goes stale on the next edit to CLAUDE.md. Re-derive: `{ wc -m CLAUDE.md; wc -m "$HOME/.claude/projects/<slug>/memory/MEMORY.md"; }`. **Two budgets, and they are measured in different units:** `templates/audit-context.md` Step 1 flags *this file* over 35,000 / 40,000 in **bytes**; the cap that bit here is 40,000 on the **auto-loaded set**, in characters, which this file alone was always under. `wc -c` reads ~2% high against `wc -m`. Two instruments for one number, and that is **not settled** — file it, do not resolve it in passing.

## Outcome

