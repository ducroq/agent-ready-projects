# Memory

<!-- NOT loaded automatically. This file sits below the auto-loading cliff.
     A task-triggered pointer in your project file is what brings it into a
     session; if that pointer is missing or vague, nothing here is ever read,
     and the failure is silent, because an index that was never loaded looks
     exactly like one with nothing to say.

     (Claude Code notes: the MEMORY.md the tool auto-loads is the USER-LEVEL
     one at ~/.claude/projects/<slug>/memory/ — same name, different file,
     different behaviour. A CLAUDE.md `@memory/MEMORY.md` import will load
     this file at launch if you want it genuinely auto-loaded; that is a
     deliberate trade of context budget for reliability, not the default.)

     Keep it lean — it is read in full whenever it is reached.
     Use this as an index — deep knowledge goes in topic files.

     END-OF-SESSION CURATION:
     This file is the hub of the self-learning loop. At end-of-session (~5 min):
     1. Review gotcha-log for recurring patterns — promote them here or to topic files
     2. Check if any entries below are stale (fixed, refactored, encoded in code) — retire them
     3. Update "Current State" to reflect what shipped or changed
     Monthly: audit everything. Prune as much as you add. -->

## Topic Files

<!-- Task-triggered pointers to deeper knowledge -->

| File | When to load | Key insight |
|------|-------------|-------------|
| `memory/gotcha-log.md` | Stuck or debugging | Problem-fix archive |
<!-- MULTI-CONTRIBUTOR PROJECTS:
     Add a pointer for coordination:
     | `COORDINATION.md` | Starting work or proposing conventions | Team agreements, WIP |

     Memory convention: all topic files are committed (shared by default).
     Personal scratch notes go in auto-memory or a gitignored personal/ directory.
     Gotcha log entries should include your name/handle so the team knows who
     found what. At end-of-session curation, check for entries that duplicate
     what other contributors logged — deduplicate rather than accumulate. -->

## Current State

<!-- What's shipped, what's in progress, what's blocked.
     For multi-session work items, use one-line pointers here:
       "- [Short description] → docs/work-items/slug.md [in progress]"
     Update status when the work lands or is abandoned.
     If a pointer and its work-item file disagree, the index wins —
     it is curated at end-of-session; the file is written during work. -->

- [ current status ]

## Recently Promoted

<!-- Gotchas that proved their value and were promoted from the gotcha log.
     These are lessons that recurred enough to earn always-loaded or topic-level visibility.
     Retire entries from this section as soon as they appear in their destination
     (project file or topic file). Don't wait for the next audit.

     Format: "if [situation], then [what to do] — promoted from gotcha-log YYYY-MM-DD" -->

## Key File Paths

<!-- The files an agent needs most often — supplement the project file's list
     with paths discovered during work -->

## Active Decisions

<!-- One-liners about recent architectural choices, pointing to ADRs if they exist.
     If a decision lives here for more than one session without a formal ADR,
     create one — decisions that seem "too small for an ADR" are often the ones
     that bite hardest when context is lost. -->
