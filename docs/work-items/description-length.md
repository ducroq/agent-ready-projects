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
- [ ] Write `experiments/exp008/` scripts (variants, seeding, grading); the prose leaves byte rules to them
- [ ] Round 3 review of draft + scripts together, then pin

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

**Status**: in progress
