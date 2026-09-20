---
name: backtrack
description: Mid-session — return to the opening ask and complete the arc: take stock from artefacts, land what is still open, report the arc. Runs before curate.
disable-model-invocation: false
---

Mid-session reorientation, invoked as *"let's backtrack and see if we can complete the arc of this
session"*. The session opened with an ask; corrections, side quests and new findings have piled up
since; the current turn is somewhere down a branch. Go back to the opening ask and the threads it
spawned, find what is still unlanded, land it, and write the session up so it reads as one thing
with an end.

Not an undo, and not `curate`: that one tends the project's memory layers at session end. This one
tends the session's own thread, and runs first. **Backtrack, then curate.**

## Step 0 — Take stock from artefacts, not from memory

Memory of what landed is the least reliable thing in the session. Read the state:

1. **Working trees**: `git status --short` and `git log --oneline -6` in every repo touched.
   Separate what is yours from what a **parallel session** is writing — two of three backtracks
   measured so far found one, and in one case the parallel session had written the plan that
   defined the arc.
2. **The documents that name their own gap**: a deliverable's version header (*"v3.0 pending"*), a
   README's outstanding list, a work item's success criteria, the day plan if the project keeps
   one and its *"done when"* lines, the last `SUMMARIES.md` entry.
3. **Any external system the session touched**: what is latched, which pollers or watchers run,
   whether the service is up. A stimulus left on is a wrong baseline for the next reader, and it
   will not announce itself.
4. **The opening ask, in its own words.** If the session was compacted, the summary's request list
   is the index. In Claude Code the raw transcript is
   `~/.claude/projects/<slug>/<session>.jsonl` when the exact wording matters.

## Step 1 — Name the arc

From the opening ask, list the threads it spawned. For each one, say which it is:

- **closed** — landed and verifiable now
- **partially closed** — name the part that is not
- **open** — and whether it was displaced by a detour, declined, or blocked
- **not ours** — needs hardware, a domain owner, or the engineer's decision

**A detour that was interesting is not the arc.** The most common failure of this step is to report
the branch you happen to be standing in as though it were the thing you were asked for — the side
quest is usually more recent, more detailed and more fun to write up. An offer the user declined
(*"No."*) is **closed**, not open.

## Step 2 — Land what can be landed, verifying rather than transcribing

Close the open items in the order the opening ask implies. The rule while doing it: **a number that
goes into a deliverable is recomputed from the data, never copied from a table.** On the first run
of this skill, recomputing caught a 93.2% that was actually 90.6%, and a cited source file that was
the wrong one. A docstring that contradicts a later measurement is a defect to delete, not a
duplicate to keep. A default set on evidence that covered one of three settings needs the other two
measured before it is landed.

Anything that needs an irreversible or outward-facing action is not landed silently: name it in the
report as the engineer's call, with the command ready to run.

## Step 3 — Leave a defined state

- **External systems**: stimulus off, watchers as found or off, state stated. Say what was cleared
  by hand and why nothing else would have cleared it.
- **Repos**: commit what is yours; do not sweep up a parallel session's files. Push if the branch
  is shared.
- **Memory layers**: `SUMMARIES.md` gets an entry if the arc completed something; the arc itself
  goes to `arcs.md` in Step 4; the gotcha log and the rest wait for `curate`.

## Step 4 — Store the arc

If the arc closed something, append it to the project's `arcs.md`, **newest first**. If the session
only reoriented and closed nothing, write nothing — report and stop. Same bar `SUMMARIES.md` uses.

**Store the durable half, and deliberately not the rest.** The report has six parts; four belong in
the file:

| Part of the report | In `arcs.md` |
|---|---|
| The opening ask, in the user's own words | Yes, one line. It is what makes the rest legible a month later |
| The ledger — closed / partial / open, and whose call | Yes. Nothing else in the memory layers reproduces it |
| What the arc turned out to be about | Yes. This paragraph usually has no other home |
| Corrections of mine | One line each, with a pointer to the gotcha-log entry that holds it properly |
| **External and repo state** | **No.** It is true for hours. A stored *"service idle, step 802"* reads three weeks later as though it still holds. State belongs in a file that is meant to be overwritten |
| What I would put next | Only as the open half of the ledger, with whose call. The live version is the project's work list |

🔴 **An arc is a dated record, not a status board.** The open items still travel to the work list
and the hypothesis log through `curate`. `arcs.md` says what was true *at its date* and never
claims to be current. Without that rule there are two sources of truth for one verdict, and this
framework's own constraint says the contradiction will eventually read as reassurance.

Entry shape, newest first, kept to about a screen:

```markdown
## YYYY-MM-DD — <the arc in a few words>

**Asked:** "<the opening ask, verbatim>"

| Thread | State |
|---|---|
| … | Closed / Partial, naming the part that is not / Open, and whose call |

<What the arc turned out to be about — one paragraph, omitted if there is no pattern.>

**Corrected:** <what I had wrong, as the conclusion, and where it is recorded.>
```

## Step 5 — Report the arc

One message, in this shape. It is the thing the engineer continues from.

1. **The list we started from**, as a table with what closed, what is partial, what is still open
   and why. Lead with the ask, not with the detour you were in.
2. **What the arc turned out to be about** — the pattern across the detours, if there is one. One
   measured run found that every step had been *a check answering a narrower question than the one
   asked, and reading clean*. That paragraph is worth more than the list; do not force one if it
   is not there.
3. **Corrections of mine worth remembering** — anything confidently wrong this session, stated as
   the conclusion rather than as a narrative of the error, with where it is recorded.
4. **State left deliberately** — from Step 3, as a short table.
5. **What I would put next, in order**, with whose call each one is.

Then stop. **A backtrack is a request to close, not to open**: no closing offer, no *"happy to draft
that when you say who"*. If the next thing needs the engineer, it is already item 5.
