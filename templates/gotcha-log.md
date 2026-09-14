# Gotcha Log

<!-- Structured problem/solution journal. Append-only.
     Part of the self-learning loop: Capture → Surface → Promote → Retire.

     PROMOTION LIFECYCLE:
     - New entries start here (Capture phase)
     - At end-of-session, review for patterns (Surface phase)
     - When an entry recurs 2-3 times, promote it to the relevant topic file
       as an "if X, then Y" pattern (Promote phase)
     - When a gotcha's root cause is fixed, mark it [RESOLVED] IN THE HEADING
       (Retire phase) — `### Title (2026-08-12) [RESOLVED]`. Curation reads
       headings and the Promoted table, not bodies, so a status written in a
       body is invisible to it. Such an entry is flagged as lingering once it
       is older than 14 days, and keeps being flagged until either the heading
       is marked or the entry is recorded in the Promoted table.
     - Track what you've promoted in the "Promoted" section below

     When the root cause is fixed, mark it resolved here (don't delete).

     GIVE THIS FILE A HISTORY -- tracked, or `git init` in an ignored dir
     with no remote. What you ask of it later is about CHANGE, which a
     working tree cannot answer. Why, and the trap in the obvious remedy:
     https://github.com/ducroq/agent-ready-projects/blob/master/docs/GUIDE.md
     -- "The retirement pattern". -->

<!-- Template for new entries:

### [Short description] (YYYY-MM-DD)
**Problem**: What went wrong or was confusing.
**Root cause**: Why it happened.
**Fix**: What solved it.

     Write the lesson and the action, not the narrative of the session
     that found it — having just lived through it, you will overweight
     the detail.

     Measured across three logs and 277 entries, a real entry runs
     ~700-1,200 characters and that is fine: SO LONG AS YOUR PROCESS
     READS HEADINGS FIRST, a body costs nothing until someone opens it.
     If you read this log whole, that does not hold and shorter is
     better. ABOVE ~3,000 CHARACTERS is the signal worth
     acting on (2-5% of entries in every log measured) — that is a page,
     and a page belongs in a topic file or an ADR.

     This said "keep it to 2-3 lines" until v1.43.0. That rule was
     unenforceable — a markdown line has no length limit, so every log
     passed it while running 3-6x the size it intended.
-->

<!-- WORKED EXAMPLE — delete or keep as a reference for entry style -->

### Tests pass locally but fail in deployment (2026-04-04)
**Problem**: All tests green (`pytest`, manual `python3 scripts/...`), but the service fails when triggered by its actual execution context (systemd, Docker, CI). Failure was silent — discovered hours later.
**Root cause**: Sandboxed execution contexts impose constraints that manual/local runs bypass. Examples: systemd `ProtectHome=read-only` blocks cache writes; Docker read-only layers drop capabilities; CI uses a different user with restricted network and ephemeral filesystem. Unit tests and manual runs never exercise these constraints.
**Fix**: Always verify through the actual execution context after deploying — `systemctl start`, `docker run`, or CI trigger — not just `python3 script.py`. Add a post-deploy smoke test that runs _inside_ the sandbox.

### Memory claimed "shipped" but feature only existed in running process (2026-04-13)
**Problem**: Agent memory stated an ML classifier endpoint was "shipped and working." The endpoint returned 404 after a service restart. 230 articles (10%) were affected before a human noticed.
**Root cause**: The endpoint was added to a running process during a dev session but never persisted to the deployed codebase. Memory recorded "shipped" based on a point-in-time test. Future sessions trusted the memory and never re-verified.
**Fix**: Never write "shipped" or "deployed" in memory based on a session observation alone. Qualify: *"responded correctly during session — verify persistence after restart."* Include a verification command (e.g., `curl https://endpoint | grep expected`) so future sessions can check before trusting the claim.

## Promoted

<!-- Track gotchas that have been promoted to topic files or the memory index.
     This helps you avoid re-promoting and shows the loop is working.

     STATUS TAGS:
     - [PROMOTED] — lesson was moved up the stack (to a topic file, memory index, or project file)
     - [RESOLVED] — root cause was fixed; entry stays as history. Put it in
       the heading. Same for a recurrence count: `[x3]` in the heading, so the
       promotion step can see it without opening the entry.

     OCCURRENCES is the column that survives compression, and it is why this
     table has four columns rather than three. Two mechanisms above compress
     the record, both correctly: the 2-3 line cap folds each recurrence into
     one lesson, and promotion folds N recurrences into one row. Together they
     drop the rate — after promotion, "five times this week" and "twice since
     April" render identically. An agent reading a promoted pattern learns
     *what* to avoid; the count is what tells it how often this has actually
     been missed here, which is the part a general lesson cannot supply.

     Keep incrementing AFTER promotion. A promoted pattern that recurs means
     the promotion did not take — the lesson is already written somewhere the
     agent reads, and is being missed anyway — which is exactly what a bare
     [PROMOTED] tag hides. Date each recurrence briefly, so a rising rate is
     visible and not just a bigger number.

| Date | Gotcha | Occurrences | Promoted to |
|------|--------|-------------|-------------|
| YYYY-MM-DD | [short description] | 1 | `topic-file.md` |
| YYYY-MM-DD | [a pattern that kept recurring] | **3** — YYYY-MM-DD first; YYYY-MM-DD again; YYYY-MM-DD after promotion | project file, [rule name] |

-->

## Mechanized

<!-- Review findings promoted to a deterministic check. The destination for
     `review-changes` Step 3.1. Separate from Promoted above because the
     destinations differ: a gotcha becomes PROSE an agent reads, a review
     finding becomes a CHECK that runs.

     ⚠️ OCCURRENCES here does NOT mean what it means in Promoted above.
     There it counts sightings from the first, including those before
     promotion. Here it counts only sightings AFTER the row went `live`,
     because before that there is no check to have failed. A `proposed`
     row therefore reads `—`, and its sightings belong in prose beside
     the table. The two columns share a name and not a definition.

     STATUS:
     - `proposed` — the shape is named, no check exists yet
     - `live` — the check exists AND a seeded positive has made it go red.
       Nothing becomes `live` on the author's read of it. A check that has
       never caught anything is indistinguishable from one that does not
       work, which is the whole reason the seeded case is required.
     - `rejected` — triaged and judged NOT mechanizable; the Check cell
       carries the reason (`needs intent`, `one-off`). Kept, not deleted:
       a shape rejected twice is a shape to look at again
     - `retired` — the class can no longer occur; say what removed it

     OCCURRENCES counts sightings AFTER the row went `live` — the signal
     this table exists to make visible. A lens finding a class its own
     live check covers means the check does not fire on the real shape,
     is scoped to the wrong population, or was never wired into the run.
     Investigate the check, not the finding.

     A `proposed` row's Check cell names the path the check WILL live at and
     marks it, so a reference audit does not report it every run. Markers go
     on `proposed` rows only: a marker on a path that already resolves is
     itself a finding. The example below is outside this comment because the
     marker ends in the comment terminator and would close it here.
-->

**Example rows** — the marker is shown literally; copy the shape, not the paths:

```markdown
| Date | Finding shape | Check | Status | Occurrences |
|------|---------------|-------|--------|-------------|
| YYYY-MM-DD | [the shape, one sentence] | `tests/lint/foo.sh` | live | 0 |
| YYYY-MM-DD | [a shape named but not yet built] | `tests/lint/bar.sh` <!-- placeholder --> | proposed | — |
```

⚠️ Put the marker **immediately after the path, in that path's own cell** — it covers the nearest path *before* it, so a later cell holding a path would capture it instead.
