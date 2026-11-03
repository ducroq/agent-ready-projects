# Delegated context: main session decides, workers do

## What & Why

In large adopter repos, sessions run out of context. The idea: the session the user talks to stays lean and handles only decisions and results. The exploring and implementing go to worker sessions, each started with a narrow, task-specific brief. The goal is a smaller context and, we hope, better results. The framework already routes reads by task ("Before You Start" table, work items). This would extend that routing into the brief a worker receives. It ships as a tool-agnostic pattern, not a mechanism. Subagents are one way to implement it.

## Evidence so far (2026-11-03)

Last 25 sessions each in the three largest private adopter repos, read from Claude Code transcripts (names in maintainer memory):
- Peak context per session, median 190k–270k tokens (max 538k–650k). Context at the first turn is 41k–50k, mostly the system prompt and tool definitions. The framework's always-loaded files are 28–49 KB, under 10% of the peak.
- Shell output is roughly a third to a half of the peak (bytes/4 as tokens): about 4,000–7,000 calls per 25 sessions, averaging about 1.6 KB each (about 250–460 KB per session). Calls over 10 KB carry only 13–22% of the bytes. The cause is accumulated exploration (`cat`/`sed`/`grep`), not a few runaway dumps. The rest of the peak is mostly assistant turns and file reads (not broken down).
- One repo's outlier: one session read 3.9 MB of screenshots.
- So splitting repos into modules would likely not cut the peak much (reasoning, not measured). Moving exploration out of the session the user talks to would.
- The user rarely reads session output, so a session that reports only decisions and results costs them nothing.

## Current Status

- [x] Measured three adopters (above)
- [ ] Decide what the main session must hold to judge a worker's proposal (see Open Questions)
- [x] Drafted `docs/GUIDE.md` § "Delegated Sessions" + CHANGELOG v1.52.0 candidate (2026-11-03); not yet reviewed (`/review-changes`)
- [ ] Decide whether any template changes (project-file "Before You Start" rows as brief sources; work-item as the worker's savepoint)
- [ ] Trial starts 2026-11-04 in the adopter that already has a delegation charter: lead/worker brief pasted at session start; its session report adds workers used, handoffs that lost something, rework. After a few sessions, rerun the transcript measurement (peak context before/after).

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
