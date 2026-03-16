# Changelog

All notable changes to the agent-ready-projects framework. Adopters can check their project file's `agent-ready-projects` version against this log to see what's changed.

## v1.1.0 (2026-03-16)

Framework generalization, worked example, Cursor support, and adoption feedback from [driven-pendulum](https://github.com/ducroq/driven-pendulum).

### Framework
- Generalized all guidance to be tool-agnostic — "project file" and "memory index" as primary terms, with tool-specific names as examples
- Agent-assisted framing throughout — retirement, course-correction, and monthly audits are agent-driven with human review
- Replaced domain-specific examples (GPU, calibration, scp/rsync) with universal scenarios (database migrations, auth patterns, debugging)

### Guide (README.md)
- Added "Works best for" qualifying section and "Minimum Viable Setup" guidance
- Added troubleshooting table (symptom → cause → fix) in Measuring Success
- Added parallel specialized review as a validation technique
- Added Cursor `.mdc` example with YAML frontmatter
- Added Layer 3 skip-ahead link for projects that don't need memory yet
- Added sections for multi-agent workflows, zero-doc projects, and feature branches
- Condensed processor cache analogy and reduced Documentation Rhythm / Self-Learning Loop redundancy

### Templates
- `memory-index.md` — "Recently Promoted" now says to retire entries immediately once they land in their destination, not at next audit
- `memory-index.md` — "Active Decisions" nudges toward creating an ADR if a decision survives more than one session
- `project-file.md` — "Before You Start" table gains an "Ending a session" row for end-of-session curation
- `gotcha-log.md` — defined `[PROMOTED]` and `[RESOLVED]` status tags
- `RUNBOOK.md` — added ~150-line document size heuristic (split and link when docs grow too large)

### Documentation
- Added `docs/EXAMPLE.md` — worked example showing populated files for a REST API project (Task Tracker)
- `METHODOLOGY.md` — added parallel specialized review as a validation technique; anonymized project references
- `templates/README.md` — points to adopt prompt for agent-assisted scaffolding

### Adoption
- `adopt.md` — review step reframed as "adjust what needs context only you have" rather than manual fill-in

## v1.0.0 (2026-03-13)

First stable release.

### Framework
- Layered model: project file (L1), runbook (L2), memory index + topic files (L3), gotcha log (L4)
- Auto-loading cliff concept with task-triggered pointers
- Self-learning loop: Capture > Surface > Promote > Retire
- Processor memory hierarchy analogy (miss cost asymmetry, eviction discipline, locality of reference)
- Promotion and retirement patterns for knowledge lifecycle
- Decision records (ADRs) as companion practice
- Session hooks and session strategy guidance
- Documentation rhythm (capture during work, curate at end-of-session)

### Templates (tool-agnostic)
- `project-file.md` — project identity, constraints, "Before You Start" table
- `memory-index.md` — auto-loaded index with topic file pointers, recently promoted section
- `gotcha-log.md` — structured problem/solution journal with promotion tracking
- `RUNBOOK.md` — operational principles and how-to

### Adoption
- `adopt.md` — agent-facing prompts for assess, adopt, and update workflows
- `templates/README.md` — tool-naming map (Claude Code, Codex, Cursor, Windsurf, Copilot, Aider)

### Documentation
- Tool-specific setup and concept mapping table
- Measuring success signals (working / failing)
- What doesn't work (anti-patterns)
- Landscape analysis, BMAD/spec-kit comparison, methodology docs
