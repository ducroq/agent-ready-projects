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
- [x] **EXP-003 run 2026-11-25: confirms EXP-002** (branch 4 in both). Pins passed, the instrument
  check passed, and the parser was identical to `b77b45e`. 512 pooled main sessions; no event shared
  with EXP-002. The parser only selects files before a cutoff, so it read a symlinked view of later files.
  The frozen text sets no upper bound; files changed after the run began (19:15 that day) were skipped.
  Artifact: `experiments/artifacts/exp003-grep-vs-memory.json` (its `experiment` field is hardcoded EXP-001).

  | Count | M1, EXP-002 | M1, EXP-003 | M2, EXP-003 |
  |---|---|---|---|
  | Frozen (official) | 13.2% | 13.4% | 28.5% |
  | No `<stdin>` (after the fact) | 10.3% | 9.96% | 29.8% |
  | Nor memory files (after the fact) | 7.0% | 7.2% | 33.6% |
  | Frozen parser, blob lines removed (after the fact) | not run | 13.6% | 29.2% |

  Branch 4 means repeats are mostly absent from memory; it does not say a note would have helped (the
  hand-check found 0 of 20). Without `<stdin>`, M1 sits on the 10% bar (9.96%; 10.3% with blob lines also
  removed). Without memory files too, it is below the bar (7.2%; 7.5%). The blob-free rerun read 2,606
  files against 2,611, because sessions still being written had passed the upper bound.
- [x] **Parser defect found in the run**: newer transcripts hold `api-request-blob` entries that repeat
  a tool call without a `cwd`. When one comes first, the parser keeps it and drops the real call (4,404
  pooled main events lost). It does not change the branch. EXP-004 pins the same parser. Across all
  repos, 72 of 911 main transcripts from before the cutoff hold such entries, against 559 of 564 after
  it (`blob-count.sh` in the lab folder). R7 alone was not measured. Pooled, the defect lowers M1 by 0.3 points, so it may lean toward "holds".
  Decided 2026-11-25 (owner): EXP-004 keeps its pinned parser. Report a second count with the blob
  lines removed beside it. The frozen count decides.
- [ ] **Open policy questions from the 2026-10-22 feedback; decide with EXP-005's result, not before**:
  a frozen/lite profile where not following every release is not drift; "never hand-maintain a
  number a script can derive"; curate/audit-context on a trigger, not every session; a
  meta-vs-code touch ratio per release; whether ADR-001 still holds (four of five wanted one index,
  three in auto-memory). Replies to adopters gave facts only. Defects found: #253 to #256.
- [ ] **Then, on the engineer's go**: the EXP-004 switch, the slim setup in R7 (the mapping is in H-032), for 20 sessions or
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
