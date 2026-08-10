---
name: curate
description: End-of-session curation — review gotcha log, promote patterns, update memory index, update work-item savepoints
disable-model-invocation: false
---

End-of-session curation for the agent-ready-projects framework.

Review the session's work and update the layered memory system:

## Step 0 — Freshness check

Check for context rot from *previous* sessions. This catches what the session-focused steps below miss.

1. **Dead references**: Read the memory index and project file. For every file path mentioned, verify it still exists. List any broken paths.
2. **Stale memory**: Check modification dates of memory files. Flag any not modified in 30+ days — they may be outdated. Read dates from the **filesystem**, e.g. `ls -l --time-style=+%Y-%m-%d memory/` or `stat -c '%y %n' memory/*.md`.

   Do not use `git log -1 --format=%ci -- <file>` as the primary check. When the memory directory is gitignored — the recommended setup, and this framework's own — `git log` returns **empty with exit 0** for every file, so the check reports nothing stale while having examined nothing. Empty `git log` output here means "the check did not run", not "no files are stale".

   If your memory files *are* tracked in git, `git log -1 --format=%ci -- <file>` is the better signal, since it reflects real edits rather than incidental touches (checkouts, formatters, syncs). Verify which case you're in first: `git check-ignore -q memory/ && echo "gitignored — use filesystem mtime" || echo "tracked — git log is fine"`.
3. **Lingering gotchas**: Read the gotcha log. Flag any unresolved entries older than 14 days — they're either fixed (mark `[RESOLVED]`) or stuck (surface to the user).
4. **Ground truth drift**: If the project file has a "Ground Truth Designations" table, verify each listed file exists and has been modified more recently than the artifacts that defer to it. Flag any where a downstream artifact is newer than its source of truth.
5. **Unverified state claims**: Scan memory files for state claims ("shipped," "deployed," "live," "running," "working in production"). For each claim found:
   Take these in order — the first match wins, and the order matters because the same command can satisfy more than one:
   - **Has `<!-- verify: manual — ... -->` comment**: Flag as **MANUAL CHECK NEEDED** with the noted reason. Surface to the engineer. No command is run.
   - **Output begins with `CANNOT VERIFY:`**: Flag as **CANNOT VERIFY** with the reason given. The check could not reach what it needed — a powered-off machine, an absent credential. This is neither a pass nor a failure and must not be reported as either. **This test comes before the exit-status tests below**, and a guard must therefore exit 0; a guard that also exits non-zero would otherwise be scored ERROR, and the two dispositions mean different things.
   - **Has `<!-- verify: ... -->` comment**: Run the command. Report **PASS** or **FAIL**. If FAIL, flag the entry for correction or removal — the claimed state is no longer true. If the command errors (non-zero exit, command not found, no output), report **ERROR** and flag for investigation — the verify command itself may be stale.
   - **No verification comment**: Flag as **UNVERIFIED**. These claims decay immediately after the session that wrote them. Suggest adding a `<!-- verify: -->` comment or requalifying the claim as a session observation.

   **Writing a verify command — it has to survive two syntaxes it is not written in.** The body sits inside an HTML comment, inside markdown, and shell is hostile to both. Check each command against the three rules below, then **run it once, at the moment you write it**. A verify command that fails on day one is worthless; one that cannot be *extracted* is worse than none, because it reports nothing while looking like it ran.

   - **Avoid `--`, and never let `-->` appear.** The hard rule is narrow: an HTML comment ends at the first `-->`, so a command containing that sequence truncates the comment and spills the remainder onto the page. Bare `--` is conforming HTML and renders fine — but it breaks two things that matter here. XML and XHTML pipelines reject it outright, and, the failure actually observed, a naive extraction regex over comment bodies stops early and returns **zero** commands, so the step examines nothing and completes cleanly. Long flags are the commonest construct in shell, so this is near-certain rather than an edge case: `--user`, `--no-pager`, `--json`, `--quiet`. In order of preference: **check the artifact instead of asking the tool** (`test -L ~/.config/systemd/user/UNIT` rather than `systemctl --user is-enabled`); **set an environment variable instead of passing a flag** (`SYSTEMD_PAGER=cat systemctl list-timers`); **use the short flag**.
   - **No unescaped `|` if the claim lives in a table cell.** GFM splits a row into cells before it parses inline content, so the idiomatic `&& echo PASS || echo FAIL` adds two cells; GFM then discards everything past the table's width, taking the rest of the row with it. Escape as `\|`, or keep verified claims out of tables.
   - **Guard anything host-dependent** so an unreachable target yields CANNOT VERIFY rather than a false PASS or a misleading FAIL. Without a guard, a machine that is merely powered off reports FAIL every run, and the noise trains the reader to ignore the step. Write the guard as an explicit `if`, not as `guard && check || echo ...`:

     ```
     if ping -c1 -W1 hostname >/dev/null 2>&1; then <real check>; else echo "CANNOT VERIFY: host unreachable"; fi
     ```

     **`A && B || C` is the wrong shape here and it fails in the direction that hides bugs**: `C` runs when *either* `A` or `B` is false, so a reachable host whose check genuinely FAILS is reported as un-checkable. That converts a real defect into a shrug. Emit the reason too — "CANNOT VERIFY" with no cause is indistinguishable from a broken guard.


6. **Hypothesis log surface**: If a hypothesis log exists, scan its `## Open` section. **Check both `memory/hypothesis-log.md` and `docs/hypothesis-log.md`** — projects put it in either, so a single-path check silently scans nothing. For each entry:
   - **Past `Review by:`**: Flag as **DUE FOR REVIEW** — the deadline has arrived. Surface to the engineer with the entry's Position and Method so they can resolve (move to `## Resolved`) or extend the deadline.
   - **`Revisit trigger:` fired**: If the trigger references an evidence threshold ("once 7 days of cycles complete," "after 14 contiguous eval rows"), check whether that threshold is now met. If yes, flag as **TRIGGERED**. The agent shouldn't resolve the hypothesis — only surface it; resolution requires reading the Method and applying it, which is the engineer's call.
   - **Stale (no movement, no trigger)**: Just count how many open entries exist. If more than ~10, flag as memory-cluttering — entries that never resolve should either be promoted to ADRs or marked `dormant` / closed.

7. **Project file size budget**: Check the project file (`CLAUDE.md` for Claude Code, equivalent for other tools). Claude Code warns at 40k chars; the soft target is under 35k to leave headroom. If the file is approaching or over budget:
   - **First, check for formatter table padding — it costs nothing to reclaim, so it comes before any content decision.** If the project runs a markdown formatter (prettier, dprint, some markdownlint configs) the project file's tables are padded with spaces so columns align in an editor. The budget is measured in **characters**, so that padding is charged in full against it — and against the context window every session. Measure the de-padded size before proposing any cut: strip each table cell to `| value |` and compare. In one adopter project with a table-heavy project file, this was **12,685 chars — 35% of a 36.3k file**, taking it to 23.6k with identical content and identical rendering. That project had no session footers left to trim and only structural sections remaining, so this step had already escalated to the engineer as a content decision when the real cause was whitespace.
   - If padding is a material share, the fix is **two** changes and needs both: de-pad the file, **and** exempt it from the formatter (e.g. add it to `.prettierignore`) — otherwise the pre-commit hook re-pads it on the very next commit and the work silently reverts. Verify the exemption is load-bearing rather than assuming it (`prettier --check --ignore-path /dev/null <file>` should report the file as needing changes, while the normal `--check` passes). Losing format-normalization on one markdown file is a smaller cost than a third of the budget; note the trade in the ignore file so the next reader knows it was deliberate.
   - Then the most common *content* cause: **session-narrative footers** (blocks like `_Last updated: ..._` / `_Earlier ..._`) accreting from prior sessions. These duplicate content that already lives in `memory/project_session_*.md` and is indexed in `MEMORY.md`.
   - Rule: keep at most **one** session footer block (the most recent), and only if it adds at-a-glance value the index can't carry. Drop older `_Earlier ..._` blocks — their content is preserved in session-memory files.
   - Don't trim structural sections (Hard Constraints, Before You Start, Architecture, Key Paths). Those are what the project file is *for*.
   - If trimming wouldn't get under budget, surface to the engineer — structural restructuring is their call, not the agent's.

Report findings before proceeding. Don't fix anything in this step — just surface what's stale so the engineer can decide.

## Step 1 — Gotcha log review

Read `memory/gotcha-log.md` (or `docs/gotcha-log.md` if not using Claude Code). For each existing entry:
- If the root cause was fixed during this session, mark it `[RESOLVED]`
- If the same issue came up again, note the recurrence

Then check: did anything go wrong or surprise you during this session? For each one, append a new entry:

```
### [Short description] (YYYY-MM-DD)
**Problem**: What went wrong or was confusing.
**Root cause**: Why it happened.
**Fix**: What solved it.
```

**Keep each entry to 2-3 lines** — the lesson and the action, not the narrative of the session that found it. Having just lived through it, you will overweight the detail. If an entry needs a page, that is a signal it belongs in a topic file or an ADR. Apply this to new entries only; retrofitting the existing log is a separate, engineer-approved decision.

## Step 2 — Pattern detection and promotion

Scan the gotcha log for entries that have recurred 2-3 times. For each:
- Propose promoting it as an "if [situation], then [what to do]" pattern
- Suggest where it belongs: the memory index (if broadly relevant) or a topic file (if subsystem-specific)
- If approved, add it to the destination and update the Promoted table in the gotcha log

## Step 3 — Memory index update

Read the memory index (`MEMORY.md` for Claude Code, or the project file for other tools). Update:
- **Current State** — reflect what shipped or changed this session
- **Active work items** — for each active work-item file in `docs/work-items/`, update its Current Status section (the savepoint): mark completed items, update "Last action" and "Next action," note blockers. If a work item completed this session, fill its Outcome section and update the MEMORY.md pointer to `[done]`. If a new multi-session initiative started, create the work-item file from `templates/work-item.md` and add a pointer
- **Key File Paths** — add any important files discovered during work
- **Active Decisions** — add any architectural choices made, with ADR pointers if created
- Remove or correct anything that is now stale

**Don't accrete session narrative onto the project file footer.** Session-level "what happened today" belongs in `memory/project_session_YYYY_MM_DD.md`, with a one-line pointer added to `MEMORY.md`. The project file is structural context (constraints, architecture, key paths) — appending session footers there bloats it past the 40k Claude Code perf threshold within ~7 sessions and duplicates what the index already holds. If a previous workflow left footer blocks behind, Step 0 sub-step 7 catches and trims them.

## Step 4 — Doc sync check

Check whether key docs reflect the current repo state. Code changes during a session can leave docs stale — this step catches drift that inline updates missed.

1. **Project file Architecture section**: Compare listed files/directories against actual repo contents. Flag new files not listed, or listed files that no longer exist.
2. **Project file Key Commands / How to Work Here**: Verify commands still match actual CLI flags and defaults. Flag any mismatches (e.g., a renamed flag, a changed default).
3. **Runbook** (if it exists): Check that operational details (environment setup, deployment steps, common problems) match reality. Flag anything that looks stale.
4. **Work-item check**: Scan `docs/work-items/` for files with an incomplete Outcome section. For each:
   - If the work completed this session, fill the Outcome and suggest updating the MEMORY.md pointer to `[done]`
   - If the Current Status shows no activity for 14+ days, flag as potentially abandoned — surface to the engineer
   - If the file has no corresponding pointer in MEMORY.md, add one (or flag if unclear)

Fix what you can. Flag anything that needs engineer input.

## Step 5 — Verify references

Skip if Step 0 already ran a full freshness check. Otherwise, spot-check that paths mentioned in the memory index and project file still exist. Flag any broken references.

## Step 6 — Report

Summarize what you changed:
- **Freshness**: Dead references, stale memory files, lingering gotchas, ground truth drift (from Step 0)
- **Verification**: State claims checked — N passed, N failed, N unverified, N errored, N manual check needed, N cannot verify (from Step 0). Report all six numbers even when they are zero; a disposition omitted because it was empty is indistinguishable from one that was never checked
- **Gotchas**: New entries added, entries resolved or promoted
- **Memory index**: Updates made
- **Doc sync**: Project file, runbook, backlog updates made or flagged (from Step 4)
- **Action needed**: Anything flagged that requires engineer decision
