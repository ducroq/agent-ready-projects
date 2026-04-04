# Gotcha Log

<!-- Structured problem/solution journal. Append-only.
     Part of the self-learning loop: Capture → Surface → Promote → Retire.

     PROMOTION LIFECYCLE:
     - New entries start here (Capture phase)
     - At end-of-session, review for patterns (Surface phase)
     - When an entry recurs 2-3 times, promote it to the relevant topic file
       as an "if X, then Y" pattern (Promote phase)
     - When a gotcha's root cause is fixed, mark it [RESOLVED] (Retire phase)
     - Track what you've promoted in the "Promoted" section below

     When the root cause is fixed, mark it resolved here (don't delete). -->

<!-- Template for new entries:

### [Short description] (YYYY-MM-DD)
**Problem**: What went wrong or was confusing.
**Root cause**: Why it happened.
**Fix**: What solved it.

-->

<!-- WORKED EXAMPLE — delete or keep as a reference for entry style -->

### Tests pass locally but fail in deployment (2026-04-04)
**Problem**: All tests green (`pytest`, manual `python3 scripts/...`), but the service fails when triggered by its actual execution context (systemd, Docker, CI). Failure was silent — discovered hours later.
**Root cause**: Sandboxed execution contexts impose constraints that manual/local runs bypass. Examples: systemd `ProtectHome=read-only` blocks cache writes; Docker read-only layers drop capabilities; CI uses a different user with restricted network and ephemeral filesystem. Unit tests and manual runs never exercise these constraints.
**Fix**: Always verify through the actual execution context after deploying — `systemctl start`, `docker run`, or CI trigger — not just `python3 script.py`. Add a post-deploy smoke test that runs _inside_ the sandbox.

## Promoted

<!-- Track gotchas that have been promoted to topic files or the memory index.
     This helps you avoid re-promoting and shows the loop is working.

     STATUS TAGS:
     - [PROMOTED] — lesson was moved up the stack (to a topic file, memory index, or project file)
     - [RESOLVED] — root cause was fixed; entry stays as history

| Entry | Promoted to | Date |
|-------|------------|------|
| [short description] | `topic-file.md` | YYYY-MM-DD |

-->
