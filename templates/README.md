# Templates

Starter files for setting up any AI coding agent. Use the [adopt prompt](../adopt.md) to have your agent scaffold these automatically, or grab them manually if you prefer.

## Quick adoption

1. Copy `project-file.md` → rename for your tool (see table below)
2. Have your agent derive project identity, constraints, architecture, and "Before You Start" pointers from your codebase — then review and adjust what only you know
3. Copy `gotcha-log.md` → save in your memory/docs directory
4. First session: let the self-learning loop start naturally — log gotchas as you hit them, agent curates at end-of-session

If your tool has auto-memory (currently Claude Code), also grab `memory-index.md`. If your project has deployment or operational complexity, grab `RUNBOOK.md`.

## What to name each file

| Template | Claude Code | Codex (OpenAI) | Cursor | Windsurf | GitHub Copilot | Aider |
|----------|------------|----------------|--------|----------|----------------|-------|
| `project-file.md` | `CLAUDE.md` | `AGENTS.md` | `.cursor/rules/*.mdc` | `.windsurfrules` | `.github/copilot-instructions.md` | `.aider.conf.yml` |
| `memory-index.md` | `MEMORY.md` | — | — | — | — | — |
| `gotcha-log.md` | `memory/gotcha-log.md` | `docs/gotcha-log.md` | `docs/gotcha-log.md` | `docs/gotcha-log.md` | `docs/gotcha-log.md` | `docs/gotcha-log.md` |
| `RUNBOOK.md` | `docs/RUNBOOK.md` | `docs/RUNBOOK.md` | `docs/RUNBOOK.md` | `docs/RUNBOOK.md` | `docs/RUNBOOK.md` | `docs/RUNBOOK.md` |

**Tools without auto-memory**: The project file carries more weight — it's your only auto-loaded file. Keep it lean, use it as an index with task-triggered pointers to the runbook, gotcha log, and ADRs. The self-learning loop still works; promotion just targets the project file directly instead of passing through a memory index.

**Multi-tool teams**: Maintain one canonical project file, symlink or copy to tool-specific locations. The content is the same — only the filename differs.

## The files

- **[`project-file.md`](project-file.md)** — Project identity, constraints, architecture, and "Before You Start" table
- **[`memory-index.md`](memory-index.md)** — Auto-loaded index + current state (for tools with auto-memory)
- **[`gotcha-log.md`](gotcha-log.md)** — Structured problem/solution journal with promotion tracking
- **[`RUNBOOK.md`](RUNBOOK.md)** — Operational principles and how-to
