# Cost and record discipline

## What & Why

The framework's running cost is dominated by two things that are not the product: **review rounds spent proofreading the record** (memory, changelog, ledgers, registries, baselines) and **an auto-loaded surface that exceeds the budget the framework itself sets**. The 2026-09-12 session measured both and found one recurring, mechanizable defect class behind most of it.

Goal: make the framework cheaper to run without cutting the review of the shipped surface, which is measurably earning its keep. Framed by #126 (review cost unpriced), #127 (promotion path, shipped v1.41.0), #109/#143 (auto-loaded set), H-025 (most findings are on the record, not the change).

**Not in scope**: reducing lens count or round count on `templates/` and `.claude/skills/`. H-020 measured every axis there and found each buys something; the 2026-09-12 round found 5 blockers in a prose-only change.

## Current Status

**Savepoint 2026-09-12, second block.** v1.41.0 is tagged and pushed. A later `/update-drift` + `/audit-context` pass committed `76d6581` (**not pushed, no release**) and filed #170-#174.

**Last action**: swept v1.40.0 re-scoping residue; replaced lint rule 1's hardcoded never-exempt list with derivation from `.gitignore` negations (fixture T14 + ablation A13 seed the rot case a literal cannot pass).

**Next action**: two engineer decisions are blocking, both recorded on their issues — **#171** (does v1.41.1 carry the template stamp fix, or does v1.42.0?) and **#172** (`--raise-budget` on `templates/project-file.md`, or leave adopters a row that fires a refusing skill). Neither is startable without a call.

**Blocker on Step 2 below**: `CLAUDE.md` now has ~120 characters of headroom against the 40,000 hard cap, so #173's inventory fixes cannot land until the reclamation pass does. The cap is now the binding constraint on that file, not judgement about what belongs in it.

- [x] #127 shipped — `review-changes` Step 3.1, Mechanized table, `curate` reads it, `curate`'s Promoted extractor bounded
- [x] Landscape doc re-verified and rewritten (2nd edition)
- [x] ETH paper (arXiv:2602.11988) re-verified against **primary text of both versions**; v1 figures superseded by v2 across 7 files
- [x] Review round recorded in `memory/review-ledger.tsv` (3 rows, 2026-09-12)
- [x] **v1.41.0 committed, merged, tagged, pushed; globals refreshed and verified carrying the fixes**
- [x] Version badges unstuck: `README.md` and `docs/GUIDE.md` were at **1.28.0**, thirteen releases stale; template stamps and `CLAUDE.md` bumped to v1.41.0
- [x] `docs/GUIDE.md:506` self-contradiction fixed — it said install `review-changes` user-globally *and* "Never install it user-globally" in adjacent sentences. v1.40.0 residue: the "never" rationale (risk tiers name one tree) stopped being true when the tiers moved to the profile
- [x] #127 closed naming the adopter-installed files; #126 given the measured round; H-027 and H-028 registered
- [ ] **Estate cleanup (#169)** — inert project-local `review-changes` copies, shadowed since v1.40.0. The count is a COMMAND, not a digit — it moved 13→12 mid-session on 2026-09-12 while remediation ran in a sibling repo: `bash scripts/install-global-skills.sh --check ~/repos | grep -c 'inert local copy'` — the bare `--check` tail counts ALL issues, not just these. ⚠️ Check each for local modifications *before* deleting; keep every `.claude/review-profile.md`
- [ ] **COMMIT v1.41.0** — 13/13 lint, 16/16 fixtures green. Then tag per `templates/release.md`, then refresh globals (`scripts/install-global-skills.sh`) since the guard requires a pushed+verified tag
- [ ] **Step 1 — stale-number check.** See Decisions for the design turn; read it before building
- [ ] **Step 2 — bring `CLAUDE.md` under its own cap.** Soft flag 35,000; measure with `wc -m CLAUDE.md` (a digit here goes stale on the next edit to that file — it did, same day). We are the main violator of our own Layer 1 rule
- [ ] **Step 3 — make `memory/` navigable.** Add headings to the 5 opaque files; split `MEMORY.md` Current State
- [ ] **Step 4 — rating-floor check (#168).** A claim whose verification log records PARTIAL/NEEDS WORK may not be rated ESTABLISHED. Seed with the Gloaguen block as it stood before 2026-09-12 — a known true positive the current arrangement passed
- [ ] **Step 5 — one narrow round, recorded.** The missing half of #126's comparison. Costs nothing extra: record what happens
- [ ] **Decide: how big should the record be?** User's call, see Open Questions

### Measurements already taken — do NOT re-derive

| What | Value | How |
|---|---|---|
| Review round, 3 lenses | **359,568 tok / 45 findings / 5 blockers** | `memory/review-ledger.tsv`, rows dated 2026-09-12 |
| Per-round range, real work | **121k–485k tok**; max 485,021 (4 lenses) | ledger, re-derived 2026-09-12 |
| ⚠️ The quoted **557,442** | **NOT ours** — an adopter's round, from a comment on #126 | `grep -c 557442 memory/review-ledger.tsv` → 0 |
| `CLAUDE.md` | run the command | `wc -m CLAUDE.md` |
| `memory/MEMORY.md` | 68,351 chars, **5 headings**; Current State = 245 lines / 58,680 chars = **86% of the file** | `grep -c '^#\{1,4\} '` |
| memory corpus | ~477 KB / 160 headings | `wc -m memory/*.md` |
| templates surface | 241,145 b budget after the 11th raise | `bash tests/lint/size-ratchet.sh .` |

**Files with no usable heading structure** (heading-first reading cannot work on these):

```
project_session_2026_08_27.md     47,549 chars /  1 heading
project_session_2026_08_early.md  28,460 chars /  1 heading
project_dead_end_pattern_rollout   5,127 chars /  0 headings
project_session_bloat_profile      2,675 chars /  0 headings
project_framework_pivot            1,789 chars /  0 headings
```

### The stale-number class — the enumeration, sent with the count (#65)

Every one of these was a number that no longer matched the thing it counted, and they span six different artifact types — which is why this is the target:

1. `tests/fixtures/reference-integrity/README.md` — claimed 27 T / 28 N, actual **40 / 37**; fixed 2026-09-12
2. `tests/fixtures/dead-reference/` — "40 rows, 16 ablations" vs 35 / 15 (CLAUDE.md: *"#93, fourth instance"*)
3. `tests/fixtures/step15-tables/` — wrong before #144 added cases (*"third fixture to hit it"*)
4. `tests/lint/size-baseline.tsv` — this session shipped "TENTH raise" against `grep -c '^# RAISED'` = **11**
5. `memory/review-ledger.tsv` — #162, shipped statistic stale for a release and a half
6. `CLAUDE.md` self-certification count — lagged 3× before its probe existed, then again within a minute
7. `docs/` ETH figures — 3%/4%/19% correct for v1, superseded by v2, propagated to **7 files**
8. `docs/the-context-engineering-landscape.md` — every star count stale 2–3×, 4 dead links, 3 invented author names

## Decisions

- **[2026-09-12] Split the treatment by surface, not by cost.** Keep the full battery on `templates/` and `.claude/skills/` — it found 5 blockers today. Stop using lenses to proofread the record; mechanize or prune it instead. Rationale: H-025 plus today's round, where the large majority of findings were on the record.
- **[2026-09-12] The stale-number predicate is EQUALITY, not PRESENCE.** The first draft proposed *"counts must be expressed as a command, not a digit."* Refuted against its own live instance: `reference-integrity/README.md` already printed the re-deriving command **beside** the stale digits, under a sentence saying any number there is dated. The remedy was applied and the number was still wrong for nine days. The check must **run the command and compare**.
- **[2026-09-12] Rejected as a check: #65's general form** (*a count that travels without its enumeration*). Population is all prose; false-positive rate unusable. Recorded `rejected` in the Mechanized table rather than deleted.
- **[2026-09-12] Do not cut review on the shipped surface to save cost.** Every axis has measured evidence it buys something (H-020). The saving comes from mechanizing recurring shapes (#127), not from cutting lenses.

## Open Questions

- ⭐ **Does this need a new lint rule at all?** The repo already has `<!-- verify: cmd -->` probes, a runner in `curate` Step 0 sub-step 5, and a 34-positive fixture (`tests/fixtures/verify-runner/`). A stale-number check may be **probes attached to the numbers that matter** plus a rule asserting that numbers in designated files carry one — reusing a tested runner instead of building rule 14 from scratch. **Settle this before writing any new checker.** Cheaper, and it fails in a direction the repo has already measured.
- **What is the population?** Fixture headers/READMEs are enumerable and where the class is densest. `CLAUDE.md`, the ledger and the baseline are higher-stakes but unenumerable. Start narrow and widen on evidence — a narrow check that fires beats a broad one that gets ignored.
- **How big should the record be?** 477 KB memory + ledger + hypothesis log + claim registry + verification log + 11 raise notes. Each was justified; together they are what review now spends most of its money on. Keep-and-mechanize, or prune hard. **This is the maintainer's call, not the agent's.**
- **Should `docs/archive/LANDSCAPE.md` carry a supersession marker?** Left untouched 2026-09-12 — archived under the 2026-04-14 pivot, and rewriting archived material may be worse than leaving it.
- **Is "ask two or three claims per release" worth formalising?** On 2026-09-12 the maintainer caught two errors three lenses missed, by asking *"is that true?"* of one sentence. The lenses verified citations **resolved**; the question was whether they **said what was claimed**. Different question, much cheaper, better hit rate. Unclear whether it survives being turned into a step.

## Outcome

**Status**: In progress
**Date**: opened 2026-09-12
