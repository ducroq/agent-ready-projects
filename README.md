# Working With AI Agents: A Practical Guide

**Version 1.10.0** | [Changelog](CHANGELOG.md) | [MIT License](LICENSE)

Your AI agent starts every session cold. It doesn't remember yesterday's bugs, your architectural decisions, or what it tried and failed last week. You end up repeating yourself, undoing its mistakes, and wondering why it's not getting better.

**This guide fixes that.** It gives your project a layered memory system — a project file, a memory index, a gotcha log — that agents auto-load and self-navigate. Lessons get captured during work, promoted as they prove their value, and retired when they're stale. Your agent gets smarter with every session, not just every prompt.

Works with any AI coding agent: Claude Code, Codex, Cursor, Windsurf, GitHub Copilot, Aider, and others.

## TL;DR

- Agents lose context between sessions. This method gives them **persistent, layered memory**.
- A **project file** (CLAUDE.md, AGENTS.md, etc.) is auto-loaded every session — it's your agent's home base.
- **Task-triggered pointers** ("when doing X, read Y") bridge the gap between auto-loaded and on-demand docs.
- A **self-learning loop** (Capture → Surface → Promote → Retire) moves lessons from session notes into always-loaded context.
- Start with one file. Add layers only as your project needs them.

## Quick Start

### Option 1: Let your agent do it (~5 min)

Paste the [adopt prompt](adopt.md) into your agent. It reads this guide, analyzes your repo, and scaffolds everything tailored to your project. You review and adjust.

### Option 2: Do it yourself (~10 min)

You need exactly **one file** to start: a project file with a "Before You Start" table.

1. Copy [`templates/project-file.md`](templates/project-file.md), rename for your tool (see [`templates/README.md`](templates/README.md))
2. Fill in: project overview (3-5 lines), hard constraints, and the "Before You Start" table with task-triggered pointers
3. That's it. Your agent now has orientation and self-navigation from session one.

### Growing from there

Add layers as your project needs them — not before:

4. **Gotcha log** — [`templates/gotcha-log.md`](templates/gotcha-log.md) when you hit your first weird bug worth remembering
5. **Hypothesis log** — [`templates/hypothesis-log.md`](templates/hypothesis-log.md) when you place a bet whose evidence lives in the future ("we'll see how this performs in 14 days")
6. **Curate skill** — [`templates/curate.md`](templates/curate.md) to automate end-of-session curation
7. **Memory index** — [`templates/memory-index.md`](templates/memory-index.md) when your project file is getting long
8. **Runbook** — [`templates/RUNBOOK.md`](templates/RUNBOOK.md) when operational detail crowds out identity
9. **Decision index** — [`templates/adr.md`](templates/adr.md) when you start making architectural decisions worth recording
   - **Coordination** — [`templates/coordination.md`](templates/coordination.md) when a second contributor joins
10. **Topic files** — When the memory index gets too long, split into per-subsystem files
11. **Checklists** — [`templates/checklists/`](templates/checklists/) for definition-of-done gates
12. **Structural audit** — [`templates/audit-context.md`](templates/audit-context.md) to catch framework-level decay monthly

### Already have docs?

Don't reorganize everything at once. Start by adding a "Before You Start" table to your project file — highest ROI, 10 minutes. The incremental path matters because wholesale reorganization is the thing most likely to get deferred forever.

## Visual Walkthrough

New here? Start with the four-page visual guide — diagrams and flowcharts, no wall of text.

1. **[The Cliff](docs/guide/01-the-cliff.md)** — Why your agent ignores your docs (and how to fix it)
2. **[The Layers](docs/guide/02-the-layers.md)** — Where to put what (and which layers you actually need)
3. **[The Loop](docs/guide/03-the-loop.md)** — How context stays fresh across sessions
4. **[The Rhythm](docs/guide/04-the-rhythm.md)** — When to do what (during work, end of session, monthly)

## How It Works

Three core ideas power the method. The [full reference guide](docs/GUIDE.md) covers each in depth.

### The auto-loading cliff

Every agent tool has files it auto-loads (CLAUDE.md, AGENTS.md, etc.) and everything else is invisible until actively read. The bridge across this cliff is **task-triggered pointers** — not "see file Y" but "when doing X, read Y first." This is the single most practical insight: auto-loaded files are indexes that help agents find what they need, exactly when they need it.

### The layered model

Documentation scales with project complexity across four layers:

| Layer | What | Auto-loaded? | When to add |
|-------|------|-------------|-------------|
| **1. Project file** | Identity, constraints, "Before You Start" table | Yes | Always (start here) |
| **2. Runbook** | Operational how-to, principles | No | When the project file gets crowded |
| **3. Memory** | Index + topic files of learned knowledge | Index: yes | When complexity grows |
| **4. Gotcha log** | Problem → Root cause → Fix journal | No | When you hit your first weird bug |
| **5. Coordination** | Contributors, shared constraints, WIP, conventions | No | When the project has multiple contributors |

### The self-learning loop

Lessons travel upward through the stack as they prove their value:

**Capture** (during work) → **Surface** (end-of-session curation) → **Promote** (recurring lessons move up) → **Retire** (fixed issues get removed)

A gotcha logged in session 4 gets promoted to a topic file by session 8, reaches the memory index by session 15, and gets retired when the root cause is fixed in session 22. Total effort: ~2 minutes across 6 sessions.

## Tool-Specific Setup

| This guide says | Claude Code | Codex | Cursor | Windsurf | GitHub Copilot | Aider |
|----------------|------------|-------|--------|----------|----------------|-------|
| "Project file" | `CLAUDE.md` | `AGENTS.md` | `.cursor/rules/*.mdc` | `.windsurfrules` | `.github/copilot-instructions.md` | `.aider.conf.yml` |
| "Memory" | `MEMORY.md` + topic files | — | — | — | — | — |
| "Curate command" | `/curate` skill | End-of-session prompt | End-of-session prompt | End-of-session prompt | End-of-session prompt | End-of-session prompt |

See the [full reference guide](docs/GUIDE.md#tool-specific-setup) for detailed setup instructions, multi-tool projects, and Cursor `.mdc` examples.

## Templates

Ready-to-use starter files in [`templates/`](templates/). Tool-agnostic — rename for your agent (see [`templates/README.md`](templates/README.md) for the naming map).

- **[`project-file.md`](templates/project-file.md)** — Project identity, constraints, and "Before You Start" table
- **[`memory-index.md`](templates/memory-index.md)** — Index + current state (for tools with auto-memory)
- **[`gotcha-log.md`](templates/gotcha-log.md)** — Structured problem/solution journal with promotion tracking
- **[`hypothesis-log.md`](templates/hypothesis-log.md)** — Provisional positions whose evidence lives in the future (`Position` / `Method` / `Revisit trigger` / `Review by`); resolves to closed or promoted to ADR
- **[`RUNBOOK.md`](templates/RUNBOOK.md)** — Operational principles and how-to
- **[`review-agent.md`](templates/review-agent.md)** — Reusable skeleton for domain review agents with self-learning
- **[`curate.md`](templates/curate.md)** — End-of-session curation skill (automates the self-learning loop)
- **[`audit-context.md`](templates/audit-context.md)** — Periodic structural audit of the layered memory system
- **[`coordination.md`](templates/coordination.md)** — Layer 5: contributors, shared constraints, WIP, conventions (multi-contributor projects only)
- **[`physics-tests/`](templates/physics-tests/)** — Specialized test-scaffolding family for physics simulation code: energy conservation, MMS convergence, intercomparison, conservation logs
- **[`checklists/`](templates/checklists/)** — Validation checklists for each workflow stage

## Further Reading

- **[Full reference guide](docs/GUIDE.md)** — Deep dive into every concept: the cliff, layers, self-learning loop, anti-patterns, measuring success
- **[Worked example: software project](docs/EXAMPLE.md)** — Task Tracker API
- **[Worked example: non-code project](docs/EXAMPLE-ASSESSMENT.md)** — Educational assessment system
- **[Landscape analysis](docs/archive/LANDSCAPE.md)** — State of the art in context engineering (April 2026 snapshot)
- **[Framework comparison](docs/archive/COMPARISON.md)** — Mapping against BMAD-METHOD and spec-kit
- **[Methodology](docs/archive/METHODOLOGY.md)** — How this guide was developed and tested
