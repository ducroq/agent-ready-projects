# Description length: test a prune on questions it was not made for

## What & Why

The framework's token-reduction goal is a minimum-description-length problem: the shortest
project file that still lets an agent act correctly. Today `curate` and `audit-context` prune on
judgement, and nothing measures what a cut loses. Recent work (arXiv 2610.27301) found that
compaction tuned to known questions was not detectably better than random deletion on later ones. This work
item tests whether that holds for our pruning, and whether a probe check should become a step.

## Current Status

- [x] 2026-11-10: research done (sources under Decisions); EXP-008 drafted in `experiments/backlog.md`, not pinned
- [x] 2026-11-10: round 1 review (adversarial + doc-accuracy): 3 blockers, revised in the draft
- [x] 2026-11-10: round 2 (adversarial): the reader-sees-original blocker recurred. Resolved by going closed-book (see Decisions)
- [x] 2026-11-10: `experiments/exp008/` written: `exp008.py`, `prompts.md`, `fixture.py` (53 checks, seeded negatives included)
- [x] 2026-11-10: round 3 (adversarial, draft + scripts): 3 blockers (pruner got a cheaper budget than random; closed book not enforced at launch; one probe could leak another's answer), 5 warnings; all fixed. Round cap reached, so **the round-3 fixes are unreviewed**
- [x] 2026-11-11: round 4 (adversarial, round-3 fixes, user-approved past the cap): no blocker; empty-fence false reject and an over-strict leak rule fixed; fixture 56 checks
- [x] 2026-11-11: models, launch command (with a pre-freeze control) and script hashes written into the section; pinned
- [x] 2026-11-11: EXP-008 run stopped by its own rule (report-only pruner broke the blank-line rule twice); re-registered and pinned as EXP-009
- [x] 2026-11-11: EXP-009 ran. Artifact: `experiments/artifacts/exp009-description-length.json`
- [ ] Record H2's result where `curate`'s pruning guidance lives, if anywhere should cite it; optional probe check stays optional
- [ ] Then run: number, probe writer, split, variants, pruners + check, readers, pool, grader, score

## Decisions

- [2026-11-10] Recursive Language Models (arXiv 2512.24601) are not adopted: they are runtime
  machinery adopters don't control. The transferable idea is MDL's two-part cost: size plus the
  cost of what the gaps lose.
- [2026-11-10] Readers are closed-book (text only, no tools). Open-book needed a sandbox and leak scans after two review rounds found the original reachable; deferred until a closed-book result justifies it.
- [2026-11-10] EXP-008 runs before the prune list in `cost-and-record-discipline.md`: its result decides whether those cuts need a probe check.
- [2026-11-10] H2 is decided on a probe-blind judge, since that is what `curate` does; the probe-aware judge is reported only.
- [2026-11-10] Subject is `CLAUDE.md`, not `memory/MEMORY.md`: it is public, so probes can be published.

Sources: arXiv 2610.27301 (compaction vs. later questions), 2602.11988 (AGENTS.md lowers task
success), 2512.24601 (RLM), 2310.19791 (LILO, MDL library compression).

## Open Questions

- Do probe scores predict task success? 2602.11988 measured tasks, 2610.27301 measured questions. Needs its own experiment.
- Is 60% the right budget, or should a second budget run once H1 holds?

## Outcome

**Status**: EXP-009 concluded 2026-11-11. **H1 holds, H2 holds.**

Held-out correct of 15 (mean of 3 reader runs) at about 59% of `CLAUDE.md`'s bytes: judged-blind
12.0 and 13.0 (mean 12.5); random 9.0, 10.0, 11.3; full 14.7; empty 0. Probe-aware pruning:
15/15 known against 13/15 held-out, the gap 2610.27301 predicts. Per the decision rule: judgement
pruning continues; a probe check is optional, not required.

**Limits**: one file, 15 held-out probes, closed book, margin over the best random cut of
1.2 probes. A signal, not proof. Task success was not measured.
