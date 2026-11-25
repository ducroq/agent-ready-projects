# Delegated context: main session decides, workers do

## What & Why

In large adopter repos, sessions run out of context. The idea: the session the user talks to stays lean and handles only decisions and results. The exploring and implementing go to worker sessions, each started with a narrow, task-specific brief. The goal is a smaller context and, we hope, better results. The framework already routes reads by task ("Before You Start" table, work items). This would extend that routing into the brief a worker receives. It ships as a tool-agnostic pattern, not a mechanism. Subagents are one way to implement it.

Evidence (2026-11-03, three adopters): docs/work-items/archive/delegated-context-evidence.md

## Current Status

- [x] Measured three adopters (above)
- [x] Guide section, reviewed and merged (#275); shipped in v1.52.0 (2026-11-04)
- [x] EXP-007 scored 2026-11-04 (`experiments/artifacts/exp007-lead-judgement.json`): H1 fails, H2 fails. A lead approves only after an independent review; the peak claim stays "being trialled"
- [ ] Working runs restarted 2026-11-04 in R1, R2, R3 and R6, no new pre-registration. Read each run's report, add it to the private run log (pointer in `memory/MEMORY.md`), and later record defects found after the run
- [ ] Decide whether any template changes (project-file "Before You Start" rows as brief sources; work-item as the worker's savepoint)

**Next action**: the owner flips each eligible task; relay each peer's landing line into the private run log. Decided 2026-11-06: a randomised arm, with fresh review on both sides, read at 10 complete pairs, with its decision rule fixed in that log. Pair 1: the workers half landed 2026-11-06, the single half waits for the next eligible FS prune. The blind reader is a fresh agent. The natural comparison stays separate, at 2 of 10 pairs.

## Decisions

- [2026-11-03] Pattern in the guide over a mechanism, because adopter-facing content must stay tool-agnostic.
- [2026-11-03] Delegation over module splitting, because the measured bloat is reading done during the work, not repo size.

## Open Questions

- **Quality is a hypothesis, not a finding.** A lean context should help, but handoffs drop detail, and a worker's errors come back sounding as confident as its findings. What would show the gain? For example, compare rework rate or review catches between delegated and in-session runs.
- How much does the main session need to read to judge a proposal rather than rubber-stamp it?
- Token cost: each worker re-reads its own context. Below what task size does delegation cost more than it saves?
- Cheap habits that may get most of the gain without the pattern: a fresh session per task, and image reads delegated to a worker. Does the guide already say these?

## Outcome

**Status**: [in progress]
**Date**:

**What happened**:

**What remains**:

**Related**:
