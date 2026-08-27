---
stack: [e.g., Python 3.12, FastAPI, PostgreSQL]
status: [Production | MVP | Prototype]
repo: [e.g., github.com/org/project]
framework: agent-ready-projects v1.36.1   # a NUMBER, not a status — never write "current" here; the framework's release cadence falsifies the adjective, not the pin
---

# [Project Name]

<!-- SAVE AS: CLAUDE.md (Claude Code), AGENTS.md (Codex), .windsurfrules (Windsurf),
     .github/copilot-instructions.md (Copilot), .cursor/rules/*.mdc (Cursor),
     or .aider.conf.yml (Aider). See templates/README.md for details. -->

<!-- 3-5 lines: what this is, who it's for, what it does -->

[One-line description of the project.]

## Before You Start

<!-- Task-triggered pointers — not just "this exists" but "when doing X, read Y" -->

| When | Read |
|------|------|
<!-- The skill rows below name the five shipped skills. `/name` is the Claude Code
     form; other tools have their own, and every one of them also works as
     "paste the framework's template for it as a prompt". Delete any row whose
     skill you did not adopt rather than leaving a pointer to nothing.

     The template paths below carry a `placeholder` marker because they live in
     the FRAMEWORK repo, not in yours: unmarked, this file's own reference check
     reports five permanent broken references in the one artifact that is loaded
     every session. (The marker is named in backticks here on purpose — written
     bare, this sentence would itself be read as a marker in use and reported as
     covering no path. Measured on this very comment.) -->

| Picking up where the last session left off | `memory/MEMORY.md` — **the index itself, not the topic files it lists**; those stay on demand, or Layer 3 collapses back into always-loaded context. Nothing loads this file on its own: since ADR-001 it sits below the cliff, so if this row is missing it is simply never read. Keep it near the top — an open handoff is worthless one session late. |
| Starting any session (framework drift) | Compare the `framework: agent-ready-projects vX.Y.Z` line in this file's header against https://github.com/ducroq/agent-ready-projects/blob/master/CHANGELOG.md (or local clone if present). If the project is behind the latest released version, briefly surface the drift to the user before starting work. `/update-drift`, or `templates/update-drift.md` <!-- placeholder --> pasted as a prompt, does this triage. Don't auto-update — adopting changes is the engineer's call. |
| Making architectural decisions | `docs/adr/README.md` — decision index |
| Changing deployment or infra | `docs/RUNBOOK.md` — operational how-to |
| Stuck or debugging something weird | `memory/gotcha-log.md` — problem-fix archive |
| **Before committing** | Diff-driven review, lenses chosen by what changed — `/review-changes` where your tool has skills, otherwise paste `templates/review-changes.md` <!-- placeholder --> as a prompt. This row is what fires it: nothing else prompts either party mid-flow. |
| Ending a session | `memory/gotcha-log.md` — review, promote patterns, retire stale entries. Then `/curate`, or paste `templates/curate.md` <!-- placeholder -->. |
| Periodic — monthly, after restructuring, and when cutting a release | `/audit-context` (structural health across the layers) and `/release` (bump classification, preconditions, changelog draft; stops before tagging), or paste `templates/audit-context.md` <!-- placeholder --> / `templates/release.md` <!-- placeholder --> |
<!-- Optional: add if you're using the workflow checklists from templates/checklists/
| Finishing architecture/design | `docs/checklists/architect-checklist.md` — definition-of-done |
| Writing or reviewing tests | `docs/checklists/test-checklist.md` — definition-of-done |
| Completing implementation | `docs/checklists/implement-checklist.md` — definition-of-done |
| Reviewing before merge | `docs/checklists/qa-checklist.md` — definition-of-done |
-->
<!-- Optional: add for multi-contributor projects (see templates/coordination.md)
| Starting work as a contributor | `COORDINATION.md` — team agreements, WIP, conventions |
-->

## Active work

<!-- One line per work item that is IN PROGRESS. This is the same list the memory
     index's "Current State" section carries — it lives here instead when your
     tool has no auto-memory, because then the project file is the only
     always-loaded artifact you have. If your tool DOES have auto-memory
     (currently Claude Code), delete this section: keeping both is how the two
     copies start disagreeing.

     Bounded on purpose. A completed item loses its pointer — its Outcome
     section in the work-item file is the durable residue, and that file is
     reached from the pointer while the work is live. Only in-progress items
     belong here, so this section stays two or three lines and does not become
     the session narrative that blows the project file's size budget.

     Format — keep the example in here, not below, or every fresh adoption
     ships a pointer to a file that does not exist and the audit's
     reference check reports it, correctly, as broken:
       - [Short description] → docs/work-items/slug.md [in progress] -->

## Hard Constraints

<!-- The non-negotiables. Things that must always be true. -->

- [ constraint 1 ]
- [ constraint 2 ]

## Architecture

<!-- How the pieces fit together. Doesn't need to be exhaustive — just enough
     for an agent to know where to look and what depends on what. -->

```
[ simple diagram or directory tree ]
```

## Key Paths

<!-- The 10-15 files an agent is most likely to need -->

| Path | What it is |
|------|-----------|
| `src/main.py` | Entry point |
| `config/` | All configuration |
| `tests/` | Test suite |

## How to Work Here

<!-- The commands an agent needs to develop, test, and deploy -->

```bash
# Run tests
[ test command ]

# Run locally
[ dev server command ]

# Deploy
[ deploy command ]
```

## Commit Conventions

<!-- Optional: if you have specific commit message formats -->

[ e.g., conventional commits, imperative mood, etc. ]
