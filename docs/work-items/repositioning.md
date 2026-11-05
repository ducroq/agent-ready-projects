# Repositioning: describe the repo in harness-engineering terms

## What & Why

Nobody outside the maintainer's own projects has adopted the framework. The 2026-04-14 pivot
(`memory/project_framework_pivot.md`) stopped promoting it for the same reason. Since then the
field has settled on a vocabulary ("harness engineering", with context engineering as one of
its pillars) that the README does not use. This item drafts a description that fits that
vocabulary and checks it against the October 2026 landscape. **Whether to re-promote is still
the maintainer's call.** Nothing here touches an adopter-facing surface yet.

## Current Status

Savepoint 2026-10-22. Done: the six-discipline mapping, the landscape scan, the drafts, the
decisions below, EXP-001/EXP-002 (13.2% of searches repeat an earlier session; 29% of the
checkable repeats were already in memory), and EXP-005/006, pinned (#252): five adopters' own
slim-downs (R1, R2, R3, R5, R6) as subjects, with EXP-004's controls narrowed to the other 11.
Switch commits are in H-032; R5's is still missing.

- [x] **Hand-check of 20 covered repeats, 2026-11-05**: yes 0, no 20, unclear 0. One rater, not blind.
  13 were pipe filters, such as `grep -v` on another command's output, which no note could answer.
  The other 7 needed live values or every use. So "covered" means named, not answered, and the
  "notes get ignored" claim stays out of the pitch. Details: lab folder, `hand-check-2026-11-05.tsv`.
- [x] **EXP-003 decided 2026-11-05 (owner): run it frozen, report both.** The parser counts pipe
  filters as searches. Dropping them moves EXP-002's M1 from 13.2% to 10.3%; also dropping searches
  of memory files (a rough path match) gives 7.0%, below the 10% bar that skips phase 2. Both are
  after the fact. EXP-003's frozen result stays the official one. Beside it, report M1 and M2 with
  `<stdin>` events removed, then with memory-file paths removed too, using the same match as
  `hand-check-sample.py` in the lab folder.
- [ ] **On or after 2026-11-18**: run `experiments/check_pins.sh`, then EXP-003 (same parser, new
  transcripts). Same decision branch as EXP-002 confirms it.
- [ ] **Open policy questions from the 2026-10-22 feedback; decide with EXP-005's result, not before**:
  a frozen/lite profile where not following every release is not drift; "never hand-maintain a
  number a script can derive"; curate/audit-context on a trigger, not every session; a
  meta-vs-code touch ratio per release; whether ADR-001 still holds (four of five wanted one index,
  three in auto-memory). Replies to adopters gave facts only. Defects found: #253 to #256.
- [ ] **Then**: the EXP-004 switch, the slim setup in R7 (the mapping is in H-032), for 20 sessions or
  6 weeks. The engineer logs one guard line per session there.
- [ ] **If EXP-004 holds**: draft the slim front door, build the demo, write the post. First, a
  deeper search for any context checker that tests its own checks (sentence B depends on it).
- [ ] **Only after outside uptake**: README/GUIDE edits, which are a CHANGELOG-noted release.

## Reference

The six-discipline mapping, the 2026-10-21 landscape scan and the drafts (problem sentences,
one-line description, proof paragraph, demo outline) are in
`docs/work-items/archive/repositioning-reference.md`. Read it when drafting the front door,
demo or post.

## Decisions

- [2026-10-21] Position as a layer *under* any harness, not as an "uber-harness". A harness
  runs the loop; this repo supplies durable context and its checks, so competing with Claude
  Code or Cursor would misdescribe it.
- [2026-10-21] Lead the pitch with seeded-defect evaluation, not self-verifying memory. The
  landscape scan shows the second has become common.
- [2026-10-21] Test before re-promoting: one post built on the demo, then watch for adopters
  outside the maintainer's projects. The README stays as it is until then.
- [2026-10-21] Problem sentence B. It avoids arguing over whether context files help at all.
- [2026-10-21] Answer the ETH Zurich study by using it: it measured one-off issue fixes, not
  memory across sessions or verified context. Its own advice (minimal, non-standard practices,
  evaluate before deploying) matches this framework's.

## Open Questions

- `templates/project-file.md` has `## Architecture` and `## Key Paths`: the repository overviews
  ETH found do not help, and grep can find. EXP-004 tests a project file without them; decide after it.
- Where to post: the augmented-engineering site, dev.to, or Hacker News?

## Outcome

**Status**: in progress
**Date**:

**What happened**:

**What remains**:

**Related**: `memory/project_framework_pivot.md`, `docs/seeded-defects-and-ablations.md`, `docs/work-items/archive/repositioning-reference.md`
