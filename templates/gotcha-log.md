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
       headings, not bodies; a status in a body is invisible to it and the
       entry is reported as lingering on every future run.
     - Track what you've promoted in the "Promoted" section below

     When the root cause is fixed, mark it resolved here (don't delete). -->

<!-- Template for new entries:

### [Short description] (YYYY-MM-DD)
**Problem**: What went wrong or was confusing.
**Root cause**: Why it happened.
**Fix**: What solved it.

     Keep it to 2-3 lines. Write the lesson, not the narrative of the
     session that found it. If it needs a page, it belongs in a topic
     file or an ADR, not here.
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
