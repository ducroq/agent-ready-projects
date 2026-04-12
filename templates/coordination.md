---
contributors: [names or handles]
updated: YYYY-MM-DD
framework: agent-ready-projects v1.8.0
---

# Coordination

<!-- SAVE AS: COORDINATION.md in the project root.
     NOT auto-loaded. Accessed via a task-triggered pointer in the project file:
     "When starting work as a contributor → read COORDINATION.md"

     This file is Layer 5: team coordination for multi-contributor projects.
     Skip entirely for single-developer projects.

     NOT IN SCOPE: task assignment, sprint planning, backlog management,
     access control, permissions, agent personas, security policies,
     CI/CD ownership, or meeting notes. This is coordination, not management.

     See ADR-002 for design rationale. -->

## Contributors

<!-- Who is working on this project? Not a permissions table — a "who to talk to
     about what" index. Update when contributors join or leave.

     Focus areas help agents avoid stepping on active work. "How they work"
     captures conventions their agent follows — useful when reviewing their PRs
     or continuing their work. -->

| Who | Focus areas | How they work |
|-----|------------|---------------|
| [name/handle] | [e.g., frontend, data pipeline] | [e.g., uses Claude Code, prefers small PRs] |

## Shared Constraints

<!-- Constraints that all contributors and their agents must honor.
     Promoted from the project file's Hard Constraints section when they
     carry team-agreement weight — meaning all contributors discussed and
     agreed, not just the project owner decided.

     The distinction: project file constraints are "how this project works."
     Shared constraints are "what we all agreed to."

     When adding a constraint, note the date and who agreed.
     When a constraint needs an ADR, create one and link it here. -->

- [constraint] — agreed [date], see [ADR if applicable]

## Convention Proposals

<!-- Lightweight staging area for proposed convention changes.
     This is where convention ideas live before they become PRs or ADRs.

     When accepted: move to an ADR, update project file if needed.
     When rejected: keep the entry with status — it's a record of why.

     The point: no surprise PRs that introduce conventions nobody discussed. -->

| Proposed by | Date | Proposal | Status |
|-------------|------|----------|--------|
| [who] | [date] | [what they're proposing, 1-2 sentences] | discussing / accepted → ADR-NNN / rejected |

## Work in Progress

<!-- What each contributor is currently working on.
     Not a task tracker — a collision-avoidance signal.

     Before starting work in an area, check if someone else is already there.
     Clear entries when work is merged.

     Keep this current: stale WIP entries are worse than none,
     because they signal false occupation. -->

| Who | Area / branch | What | Started |
|-----|--------------|------|---------|
| [name] | [area or branch name] | [brief description] | [date] |

## Memory Conventions

<!-- How shared vs personal memory works in this project.

     Shared memory (committed, everyone reads):
     - memory/MEMORY.md — index
     - memory/gotcha-log.md — problem-fix archive
     - memory/[topic files] — subsystem knowledge

     Personal memory (gitignored or in auto-memory):
     - Personal preferences, scratch notes, learning journal

     Gotcha log convention: all contributors log to the same gotcha-log.md.
     Tag each entry with your name/handle so reviewers know who found what.
     At end-of-session curation, check for entries that duplicate or conflict
     with what others logged — deduplicate rather than accumulate.

     Convention changes: propose above in Convention Proposals, don't just
     change the memory structure unilaterally. -->

- Shared: `memory/` directory (committed)
- Personal: [auto-memory or gitignored `memory/personal/`]
- Gotcha log entries tagged with contributor name
