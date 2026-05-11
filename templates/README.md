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
| `hypothesis-log.md` | `docs/hypothesis-log.md` | `docs/hypothesis-log.md` | `docs/hypothesis-log.md` | `docs/hypothesis-log.md` | `docs/hypothesis-log.md` | `docs/hypothesis-log.md` |
| `RUNBOOK.md` | `docs/RUNBOOK.md` | `docs/RUNBOOK.md` | `docs/RUNBOOK.md` | `docs/RUNBOOK.md` | `docs/RUNBOOK.md` | `docs/RUNBOOK.md` |
| `curate.md` | `.claude/skills/curate/SKILL.md` | End-of-session prompt | End-of-session prompt | End-of-session prompt | End-of-session prompt | End-of-session prompt |
| `audit-context.md` | `.claude/skills/audit-context/SKILL.md` | Ad-hoc prompt | Ad-hoc prompt | Ad-hoc prompt | Ad-hoc prompt | Ad-hoc prompt |
| `review-agent.md` | `docs/reviews/[domain]-review.md` | `docs/reviews/[domain]-review.md` | `docs/reviews/[domain]-review.md` | `docs/reviews/[domain]-review.md` | `docs/reviews/[domain]-review.md` | `docs/reviews/[domain]-review.md` |
| `adr.md` | `docs/decisions/ADR-NNN-slug.md` | `docs/decisions/ADR-NNN-slug.md` | `docs/decisions/ADR-NNN-slug.md` | `docs/decisions/ADR-NNN-slug.md` | `docs/decisions/ADR-NNN-slug.md` | `docs/decisions/ADR-NNN-slug.md` |
| `checklists/` | `docs/checklists/` | `docs/checklists/` | `docs/checklists/` | `docs/checklists/` | `docs/checklists/` | `docs/checklists/` |

**Tools without auto-memory**: The project file carries more weight — it's your only auto-loaded file. Keep it lean, use it as an index with task-triggered pointers to the runbook, gotcha log, and ADRs. The self-learning loop still works; promotion just targets the project file directly instead of passing through a memory index.

**Multi-tool teams**: Maintain one canonical project file, symlink or copy to tool-specific locations. The content is the same — only the filename differs.

## The files

- **[`project-file.md`](project-file.md)** — Project identity, constraints, architecture, and "Before You Start" table
- **[`memory-index.md`](memory-index.md)** — Auto-loaded index + current state (for tools with auto-memory)
- **[`gotcha-log.md`](gotcha-log.md)** — Structured problem/solution journal with promotion tracking
- **[`hypothesis-log.md`](hypothesis-log.md)** — Provisional positions under observation. Each entry pins the falsification criterion (Method) and revisit deadline (Review by) *before* the data lands. Lifecycle: open → resolved (close or promote to ADR). Complements gotcha log (problems already solved) and ADRs (decisions accepted) by giving a home to bets whose evidence is still in the future
- **[`RUNBOOK.md`](RUNBOOK.md)** — Operational principles and how-to
- **[`review-agent.md`](review-agent.md)** — Reusable skeleton for domain review agents (code review, rubric design, assessment audit, etc.) with self-learning capability
- **[`curate.md`](curate.md)** — End-of-session curation skill that automates the self-learning loop (gotcha review, pattern promotion, memory index update). For Claude Code, save as `.claude/skills/curate/SKILL.md` with frontmatter (see template comments) to get a `/curate` skill; for other tools, use as an end-of-session prompt
- **[`audit-context.md`](audit-context.md)** — Periodic structural audit of the layered memory system (duplication, wrong-layer placement, bloat, broken references, gitignore correctness). For Claude Code, save as `.claude/skills/audit-context/SKILL.md` for a `/audit-context` skill; for other tools, run as an ad-hoc prompt monthly or after major restructuring
- **[`adr.md`](adr.md)** — Architecture Decision Record template with options matrix, consequences, and "Revisit If" triggers. Save each decision as `docs/decisions/ADR-NNN-short-slug.md` and keep an index in `docs/decisions/README.md`
- **[`checklists/`](checklists/)** — Validation checklists for each workflow stage: [architect](checklists/architect-checklist.md), [test](checklists/test-checklist.md), [implement](checklists/implement-checklist.md), [qa](checklists/qa-checklist.md). Lightweight definition-of-done gates (10-15 items each)
- **[`test-verify-memory.md`](test-verify-memory.md)** — Skill that tests the self-verifying memory protocol (curate Step 0.5) against fixture files with known expected outcomes. For Claude Code, save as `.claude/skills/test-verify-memory/SKILL.md`; for other tools, use as an ad-hoc prompt
- **[`test-fixtures/memory/`](test-fixtures/memory/)** — Ten fixture files for testing claim-type detection and verification: passing verify, failing verify, erroring verify, manual verify, unverified state claims (covering "deployed"/"running", "live", and "working in production" triggers), decision, observation, and pattern. Used by `test-verify-memory.md`
- **[`physics-tests/`](physics-tests/)** — Specialized test-scaffolding family for physics simulation code. Targets failure modes ordinary unit tests miss: integrator drift, wrong order of accuracy, conservation violations, force-asymptotic bugs. Includes energy/integrator skeleton, MMS convergence template, intercomparison template (highest leverage — catches shared-misconception bugs), and conservation-log template. See the family's own [`README`](physics-tests/README.md) for the verification-tier hierarchy
