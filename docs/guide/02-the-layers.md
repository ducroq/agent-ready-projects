# The Layers

Four layers, each added when the previous one gets crowded. Not every project needs all four.

```mermaid
block-beta
    columns 3

    space label1["Auto-loaded?"] label2["Growth"]

    L1["Layer 1: Project File<br/>Identity, constraints, pointers"]:1 auto1["✅ Yes"]:1 g1["Bounded ~100 lines"]:1
    L2["Layer 2: Runbook<br/>Operational detail, procedures"]:1 auto2["❌ Triggered"]:1 g2["Grows with operations"]:1
    L3["Layer 3: Memory<br/>Index + topic files"]:1 auto3["📋 Index only"]:1 g3["Grows with complexity"]:1
    L4["Layer 4: Gotcha Log<br/>Problem → Root Cause → Fix"]:1 auto4["❌ Triggered"]:1 g4["Append-only"]:1

    style L1 fill:#f0fdf4,stroke:#16803c
    style L2 fill:#fefce8,stroke:#a16207
    style L3 fill:#fefce8,stroke:#a16207
    style L4 fill:#fefce8,stroke:#a16207
    style auto1 fill:#f0fdf4,stroke:#16803c
    style auto3 fill:#eff6ff,stroke:#1d6fa5
```

## Layer 1: Project File — always present

**What it is:** The only file guaranteed to be read every session. Your agent's first impression.

**What goes in:**
- Project identity (3-5 lines: what, who, why)
- Hard constraints ("never remove output fields", "never skip tests")
- "Before You Start" table with task-triggered pointers
- Architecture sketch (directory tree)
- Key file paths (10-15 most needed)
- How to work here (test, build, deploy commands)

**Keep it under ~100 lines.** Every line competes for attention.

```mermaid
graph LR
    Agent["Agent starts session"] --> Reads["Reads project file"]
    Reads --> Orient["Orients: what is this?"]
    Reads --> Constraints["Learns: what must I never do?"]
    Reads --> Navigate["Navigates: where do I look for X?"]
```

## Layer 2: Runbook — most projects need this

**What it is:** Operational detail that would clutter the project file.

**What goes in:**
- Local development setup (prerequisites, commands)
- Deployment steps and gates
- How to add new [extension point]
- Common problems (symptom → cause → fix)

**Skip if:** Your project has one test command and no deployment.

## Layer 3: Memory — when complexity grows

**What it is:** An auto-loaded index pointing to on-demand topic files.

```mermaid
graph TD
    MI["Memory Index<br/>(auto-loaded, ~60-80 lines)"]
    MI --> TF1["api-quirks.md<br/>(loaded when API errors)"]
    MI --> TF2["infrastructure.md<br/>(loaded when deploying)"]
    MI --> TF3["auth-patterns.md<br/>(loaded when touching auth)"]
    MI --> GL["gotcha-log.md<br/>(loaded when stuck)"]

    style MI fill:#f0fdf4,stroke:#16803c
    style TF1 fill:#fefce8,stroke:#a16207
    style TF2 fill:#fefce8,stroke:#a16207
    style TF3 fill:#fefce8,stroke:#a16207
    style GL fill:#fefce8,stroke:#a16207
```

The index carries:
- Topic file routing table (file | when to load | key insight)
- Current project state
- Recently promoted patterns
- Key file paths
- Active decisions

Topic files carry deep knowledge about one subsystem. **The index is the bridge across the cliff for everything in Layer 3.**

## Layer 4: Gotcha Log — always present

**What it is:** Structured problem/solution journal. Append-only.

```markdown
### Staging migrations time out (2026-01-15)
**Problem**: Migrations hang after ~30 seconds on staging.
**Root cause**: Shared database has long-running queries holding locks.
**Fix**: Run with `--lock-timeout=60s`.
```

**Not a daily journal.** "Today we did X, Y, Z" is noise. "Problem → Root Cause → Fix" is knowledge.

## Which layers does your project need?

```mermaid
graph TD
    Start["Your project"] --> Q1{"Multiple sessions?"}
    Q1 -- No --> Skip["Skip all this.<br/>It's overkill."]
    Q1 -- Yes --> L1["Layer 1: Project File ✅"]
    L1 --> L4["Layer 4: Gotcha Log ✅"]
    L4 --> Q2{"Deployment or<br/>operational complexity?"}
    Q2 -- Yes --> L2["Layer 2: Runbook ✅"]
    Q2 -- No --> Q3{"Multiple subsystems<br/>or growing knowledge?"}
    L2 --> Q3
    Q3 -- Yes --> L3["Layer 3: Memory ✅"]
    Q3 -- No --> Done["Done. Start working."]
    L3 --> Done

    style Skip fill:#fef2f2,stroke:#dc2626
    style Done fill:#f0fdf4,stroke:#16803c
    style L1 fill:#f0fdf4,stroke:#16803c
    style L2 fill:#eff6ff,stroke:#1d6fa5
    style L3 fill:#eff6ff,stroke:#1d6fa5
    style L4 fill:#f0fdf4,stroke:#16803c
```

## Tool mapping

The layers are the same everywhere. Only the filenames change.

| Layer | Claude Code | Codex | Cursor | Windsurf | Copilot |
|-------|-----------|-------|--------|----------|---------|
| 1. Project file | `CLAUDE.md` | `AGENTS.md` | `.cursor/rules/*.mdc` | `.windsurfrules` | `.github/copilot-instructions.md` |
| 2. Runbook | `docs/RUNBOOK.md` | same | same | same | same |
| 3. Memory index | `MEMORY.md` | — | — | — | — |
| 3. Topic files | `memory/*.md` | same | same | same | same |
| 4. Gotcha log | `memory/gotcha-log.md` | same | same | same | same |

Tools without auto-memory (everything except Claude Code): put everything Layer 3 would carry into the project file. It becomes your only auto-loaded file, so make it a lean index.

---

[← The Cliff](01-the-cliff.md) | Next: [The Loop →](03-the-loop.md)
