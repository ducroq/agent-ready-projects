# The Auto-Loading Cliff

The single most important concept: **there is a hard line between what your agent sees automatically and what's invisible.**

```mermaid
graph TB
    subgraph above["🟢 Auto-loaded (always visible)"]
        PF["Project file<br/><code>CLAUDE.md / AGENTS.md</code>"]
        MI["Memory index<br/><code>MEMORY.md</code>"]
    end

    subgraph below["🔴 Below the cliff (invisible until triggered)"]
        RB["Runbook<br/><code>docs/RUNBOOK.md</code>"]
        TF["Topic files<br/><code>memory/*.md</code>"]
        GL["Gotcha log<br/><code>memory/gotcha-log.md</code>"]
        ADR["ADRs<br/><code>docs/decisions/</code>"]
    end

    PF -. "task-triggered pointer" .-> RB
    PF -. "task-triggered pointer" .-> GL
    MI -. "task-triggered pointer" .-> TF
    MI -. "task-triggered pointer" .-> ADR

    style above fill:#f0fdf4,stroke:#16803c,stroke-width:2px
    style below fill:#fef2f2,stroke:#dc2626,stroke-width:2px
```

## What this means

Content above the cliff is **always available** — your agent acts on it from the first message. Content below is **invisible** until something triggers the agent to read it.

"Linked prominently" is not a trigger. The agent skims past links.

## What crosses the cliff

**Task-triggered pointers** cross it. The difference:

```mermaid
graph LR
    subgraph fails["Does NOT work"]
        A["See docs/api-quirks.md"] --> B["Agent skims past"]
    end

    subgraph works["Works"]
        C["API returns 422 →<br/>read docs/api-quirks.md"] --> D["Agent matches situation,<br/>loads the file"]
    end

    style fails fill:#fef2f2,stroke:#dc2626
    style works fill:#f0fdf4,stroke:#16803c
```

| Doesn't cross the cliff | Crosses the cliff |
|--------------------------|-------------------|
| `See docs/RUNBOOK.md` | `Before changing the pipeline, read docs/RUNBOOK.md` |
| `API troubleshooting` | `API returns 422` |
| `Architecture docs` | `Making an architectural decision` |

The first column uses **categories** the agent has to interpret. The second uses **situations** the agent recognizes it's in. Categories require judgment. Situations are match conditions.

## Where to put pointers

Two places, both auto-loaded:

1. **Project file** — "Before You Start" table:
   ```markdown
   | When | Read |
   |------|------|
   | Debugging or investigating failures | `memory/gotcha-log.md` — problem-fix archive |
   | Making architectural decisions | `docs/adr/README.md` — index of ADRs |
   | Touching PII or sensitive data | `memory/privacy-protocol.md` — never-do list |
   ```

2. **Memory index** — Topic file table:
   ```markdown
   | File | When to load | Key insight |
   |------|-------------|-------------|
   | `memory/api-quirks.md` | API returns unexpected errors | Pagination limits, auth token expiry |
   | `memory/infrastructure.md` | Deployment or staging issues | Timeout workarounds, env differences |
   ```

Both tables use the same principle: **when** (situation), **what** (file), **why** (one-line hint so the agent knows if it's worth loading).

---

Next: [The Layers →](02-the-layers.md)
