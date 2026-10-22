# Repositioning: describe the repo in harness-engineering terms

## What & Why

Nobody outside the maintainer's own projects has adopted the framework. The 2026-04-14 pivot
(`memory/project_framework_pivot.md`) stopped promoting it for the same reason. Since then the
field has settled on a vocabulary ("harness engineering", with context engineering as one of
its pillars) that the README does not use. This item drafts a description that fits that
vocabulary and checks it against the October 2026 landscape. **Whether to re-promote is still
the maintainer's call.** Nothing here touches an adopter-facing surface yet.

## Current Status

Savepoint 2026-10-21. Done: the six-discipline mapping, the landscape scan, the drafts, the
decisions below, and EXP-001/EXP-002 (13.2% of searches repeat an earlier session; 29% of
the checkable repeats were already in memory; `experiments/`).

- [ ] **Next session, after the pruning**: hand-check 20 covered repeats from EXP-002 (lab folder,
  memory-maintenance searches excluded). For each: would the note alone have answered the search?
  Yes / no (it needed locations or every use) / unclear. 72% of covered repeats had the term in the
  always-loaded `CLAUDE.md`, so "covered" may mostly mean "named", not "answered". If yes is rare,
  drop the "notes get ignored" claim from the pitch and say why here. Aggregates only.
- [ ] **On or after 2026-11-18**: run `experiments/check_pins.sh`, then EXP-003 (same parser, new
  transcripts). Same decision branch as EXP-002 confirms it.
- [x] **Rescope EXP-004 (decided 2026-10-22; done as EXP-005, pinned).** Five adopters asked to slim the same day
  (R1, R2, R3, R5, R6; mapping in H-032), each measuring process churn at or
  above code churn. Each slimmed repo leaves EXP-004's controls. The maintainer chose to make them
  subjects instead. Each was asked to record its switch commit and to archive its old material
  rather than delete it. Switch commits are recorded in H-032.
  Their overlapping asks (a load ceiling, checks over prose, a short project file) wait for its result.
- [ ] **Open questions from the same feedback, outside EXP-004; decide later**:
  a frozen/lite profile where not following every release is not drift (all five, in effect);
  "never hand-maintain a number a script can derive" (R5); curate/audit-context on a trigger,
  not every session (R5); a meta-vs-code touch ratio as a per-release weight metric
  (R1); whether ADR-001 should still hold now that harness auto-memory has
  matured (four of five wanted one index, three of them in auto-memory; R1's two have diverged).
  The replies sent 2026-10-22 gave facts only and held all policy.
  Two defects R6 found, both real whatever the profile decision:
  - curate Step 0 sub-step 6 sums files only, so context injected by a SessionStart hook goes
    uncounted and the check passes.
  - audit-context Step 6's reconciled case only covers a *reviewed* decline. A wholesale freeze
    ("later releases not reviewed") is unnamed, and may be reported as drift.
- [ ] **Then**: the EXP-004 switch, the slim setup in R7 (the mapping is in H-032), for 20 sessions or
  6 weeks. The engineer logs one guard line per session there.
- [ ] **If EXP-004 holds**: draft the slim front door, build the demo, write the post. First, a
  deeper search for any context checker that tests its own checks (sentence B depends on it).
- [ ] **Only after outside uptake**: README/GUIDE edits, which are a CHANGELOG-noted release.

## Where the repo sits

A harness runs the agent loop. This repo runs nothing. It is the part of harness engineering
that **lasts across sessions and across harnesses**.

| Discipline | In this repo | Strength |
|---|---|---|
| Context engineering | Layered memory, task-triggered pointers, curate pruning, session-start token ratchet | Core |
| Evaluation engineering | Seeded-defect fixtures, review-bench scoring, `docs/seeded-defects-and-ablations.md`, lint | Strong |
| Observability | Gotcha, hypothesis and dead-end logs; CHANGELOG. They record lessons, not traces | Partial |
| Tool engineering | Skills and scripts the agent runs (curate, review-changes, `verify-runner.sh`, `refcheck.py`) | Partial |
| Loop engineering | Work items and savepoints run the cross-session loop; the model↔tool loop is the harness's | Light |
| Safety engineering | Hard constraints and review tiers; permissions and sandboxing are the harness's | Light |

## Landscape, 2026-10-21

What changed since the April pivot, and what it means for the pitch:

1. **"Harness engineering" is the 2026 frame.** It sits after prompt and context engineering,
   and covers context, tools, guardrails, feedback loops and observability ([Faros][faros],
   [Noqta][noqta], [Lyzr][lyzr]). These are vendor and blog sources, not primary ones.
2. **Context files are now measured, and the result is unflattering.** The ETH Zurich /
   LogicStar study (ICLR 2026, [arXiv 2602.11988][eth]) found repository context files give
   little or no gain in task success and raise inference cost by over 20%. Human-written,
   minimal files did best. This *supports* the repo's lean-context and token-reduction stance,
   and the pitch should cite it rather than ignore it.
3. **"Memory must be checked against the code" is no longer a unique idea.** A 2026-10-03 survey
   ([Dell, dev.to][dell]) lists several approaches: a commit-vs-spec drift hook, Sentry's
   SOURCES.md, a refresh command in Every's compound-engineering plugin, `rulesync generate
   --check`, and okl's executable lessons. It also reports that Copilot Memory validates facts
   before use; that is second-hand and not checked here. The April memo counted
   self-verifying memory as unique. **It is now a crowded idea.**
4. **Structural linters for context files exist**: ctxlint, agents-doctor, AgentLint, ailint
   ([survey of results][lint]). These overlap with lint rules and `refcheck.py`.
5. **Memory products** (Cognee, Mem0, Zep) sell retrieval over MCP ([Cognee guide][cognee],
   vendor-written). That is a different layer: they store and fetch, they do not curate or
   verify.

**What still looks unclaimed:** testing the checks themselves. Every tool above checks the
context; none of the ones found shows that its checks catch seeded failures. That is the
argument of `docs/seeded-defects-and-ablations.md`: "a check that finds nothing has told you
nothing." The other gap is the **whole lifecycle** (capture, promote, verify, retire) in plain
files any harness can read, instead of a single linter or a hosted store.

## Drafts

### Problem sentence (pick one)

- A. *Your agent's project notes go stale, and it keeps acting on things that stopped being true.*
- B. *Every agent tool can load your project notes. None of them tells you when the notes are wrong.*
- C. *Context files cost tokens on every task and, measured, barely help. Keep only what earns
  its place, and prove it is still true.*

### One-line description

> **Agent-Ready Projects: persistent context engineering for any coding agent.** Project memory
> loaded by task, kept true by self-checks, improved session over session, and evaluated with
> seeded defects.

### Proof paragraph

> Most tools that check agent context have never been shown to catch anything. This one has.
> In its own repository, a structural rule matched 0 of the 4 references it existed to
> validate, for its whole life, and stayed green. A rule comparing a template to its installed
> copy passed for eight releases while both copies held the same syntax error. Neither was
> found by reading. Both were found by running the check against failures planted on purpose.
> Every check here ships with such a fixture, so "all clean" means something.

(Examples from `docs/seeded-defects-and-ablations.md`; keep them in step with that page.)

### Demo outline (about one minute of reading)

1. A small repo whose project file says "run tests with `make test`", backed by a verify probe.
2. The Makefile is replaced by `just`. Nothing else changes.
3. Next session: the probe fails and names the stale line before the agent acts on it.
4. The agent fixes the line; the probe passes.
5. Second beat: remove the probe's teeth (make it always pass). The seeded-defect fixture goes
   red. The check is itself checked.

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

**Related**: `memory/project_framework_pivot.md`, `docs/seeded-defects-and-ablations.md`

[faros]: https://www.faros.ai/blog/harness-engineering
[noqta]: https://noqta.tn/en/blog/harness-engineering-ai-agents-production-ready-2026
[lyzr]: https://lyzr.ai/blog/harness-engineering-for-ai-agents/
[eth]: https://arxiv.org/abs/2602.11988
[dell]: https://dev.to/emeraldleaf/what-keeps-an-agent-setup-true-2ggp
[lint]: https://forum.cursor.com/t/built-a-small-cli-to-detect-agents-md-drift-missing-commands-dead-paths-conflicting-nested-files/159582
[cognee]: https://www.cognee.ai/blog/guides/memory-tooling-ai-coding-agents
