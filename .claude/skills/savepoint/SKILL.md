---
name: savepoint
description: Cheap handoff at a task boundary — refuse while work is still open, replace the handoff's top block, commit by the repo's own route, then say it is safe to clear the context. Lighter than curate. Run it only at a boundary the engineer named (task done, wrap up) or when the context nears its limit, never mid-task.
disable-model-invocation: false
---

Write down everything a fresh session needs, commit it, and say whether the context can be cleared. **Clearing is the engineer's action, never this skill's.** This is the cheap step between "task done" and a context reset; `curate` stays the heavier end-of-day pass. If the handoff is a section `curate` also rewrites, run `curate` first and this skill last, so its `Preserve` lines survive.

## Step 0 — Read the declaration

The project file carries a `Savepoint` block. Quote it exactly; the skill holds everything else:

```
## Savepoint
- Handoff: <path> § <heading> (cap <N> bytes)
- Commit route: direct | branch + PR
- Blocking checks: <none | a file pattern or command; open = block>
- Preserve: <none | lines or sections of the block that are standing, not open items>
- Mandatory steps: <none | each step, one per line>
```

**No block: propose one** from what the repo already does (where the last handoff was written, how the last commits landed) **and stop.** The engineer approves it once; do not guess a route on every run.

## Step 1 — Refuse while anything is open

Do not say "safe to clear" while any of these holds. Name each one found, with the command or listing that found it.

1. **Running work** — a background task, subagent, watcher or scheduled job this session started, still running and not written into the handoff block. Finish it, stop it, or write it into the block (what it is, how to check it, how to re-create it).
2. **Uncommitted changes this session made.** List `git status --porcelain`; commit what this session changed by the declared route (Step 4), as a WIP commit if unfinished. **Never a bare `git stash`**: the stash is shared by every worktree and session in the clone. **Files this session did not touch are not yours to commit** — list them in the report and leave them.
3. **A gate passed but its action is not yet taken** (checks green, the deploy or merge it licenses not yet run). No file records this state; only the session knows it.
4. **A declared blocking check is open** (a deploy or gate window, for example). The engineer can override; record the override and who gave it in the block.

A clean result states the checks run and what a positive would have looked like ("`git status --porcelain`: empty; a hit would be a line per file").

## Step 2 — Replace the handoff's top block

**Replace it; never append.** An appended handoff grows past cheap reading. Resolved items leave the block, except what the declaration's `Preserve` line names (standing rulings, for example), which is carried over unchanged; history belongs in a session file or the log, not here. The block lists:

- **Open items**, and every wait with an absolute date and time (never "tomorrow").
- **Rulings and approvals given only in chat**, with the date and who gave them — the transcript will not survive the clear.
- **Questions to other sessions or people, and promises made to them, word for word.**
- **Reports and probe results not yet logged** anywhere durable.
- **Scheduled jobs and watches to re-create**, with their interval — they die with the session.
- **Temporary files worth keeping**, moved first to durable storage: a new session gets a new scratch path.
- **The next step**, quoted from the engineer where they gave one.

Point to an active work item rather than copying it. Measure the block (`wc -c`) against the declared cap; over the cap, cut resolved and duplicated lines, never preserved ones. Still over: report the size and stop — do not compress meaning to fit.

## Step 3 — Run the declared mandatory steps

Run each declared step and report its result. A step that cannot run blocks the savepoint; it is not skipped in silence.

## Step 4 — Commit by the repo's route

- **direct**: commit the handoff (and anything Step 1 resolved) with a message naming the savepoint.
- **branch + PR**: in a separate worktree branched from the default branch — **never by switching the shared checkout**, which other sessions or tools may be reading — commit, push, open the PR. **Never merge it**: merging follows the repo's own rules.

Commit only the paths this session changed, by name, from your own record of edits; where you cannot tell, list the path and ask. Never `git add -A`.

**Cannot complete**: the handoff is untracked or ignored (commit what is tracked, and say the handoff is local only), or the route needs a remote or PR tool the repo lacks. Report what was done and what was not; never "safe to clear" on a commit that did not happen.

## Step 5 — Report

One or two lines: the block's path and size, the commit or PR, and either **"safe to clear"** or what still blocks it. Nothing else.
