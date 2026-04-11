# Changelog

All notable changes to the agent-ready-projects framework. Adopters can check their project file's `agent-ready-projects` version against this log to see what's changed.

## v1.7.1 (2026-04-11)

ADR template — codifies the decision record pattern that was previously demonstrated by example only.

### Templates
- **`templates/adr.md`** — New Architecture Decision Record template with YAML frontmatter (`status`, `date`, `deciders`, `superseded_by`), options comparison tables, consequences (positive/negative/risks), "Revisit If" triggers with concrete conditions, implementation steps, and an embedded decision index template. Synthesized from ADR patterns across three adopter projects (agent-ready-papers, RenkumSpot, shared_vault).

### Guide (README.md)
- Step 8 in the adoption ladder now links to `templates/adr.md` instead of being a bare mention.
- Version bumped to 1.7.1.

### Templates README
- `templates/README.md` — Added `adr.md` to the tool-naming table and the file descriptions list.
- `templates/project-file.md` — Version bumped to 1.7.1.

### Origin
Investigated ADR/DR practices across three adopter repositories. `shared_vault` contributed the "Revisit If" pattern with concrete trigger conditions. `RenkumSpot` contributed status badges, decision matrices, and a battle-tested template across 17 decisions. `agent-ready-papers` contributed YAML frontmatter with `superseded_by` tracking. The framework had ADRs at step 8 of adoption and one example (ADR-001) but no reusable template — this closes that gap.

## v1.7.0 (2026-04-08)

Structural health audit — `/audit-context` skill catches framework-level issues that version drift checks and session-level curation miss.

### Templates
- **`templates/audit-context.md`** — New skill template for periodic structural audits. Seven-step check: document size, cross-layer duplication, wrong-layer placement, reference integrity, topic file reachability, gitignore correctness, and severity-grouped report. Complements `/curate` (session-level) with framework-level health checks. Install as `.claude/skills/audit-context/SKILL.md`.

### Adopt prompt (adopt.md)
- STEP 6 now installs both `/curate` and `/audit-context` skills. "Before You Start" table instruction includes both: "Ending a session → Run /curate" and "Monthly or after major restructuring → Run /audit-context".
- Template URL list updated with `templates/audit-context.md`.
- Update prompt PART 2 (Structural Health) now references the `/audit-context` skill instead of inlining duplicate checks — single source of truth for audit logic.

### Guide (README.md)
- Version bumped to 1.7.0.

### Templates
- `templates/project-file.md` — Version bumped to 1.7.0.

### Motivation
Observed across multiple adoptions: version drift checks catch framework updates, and `/curate` catches session-level staleness, but neither catches structural decay — bloated auto-loaded files, duplicated facts across layers, content in the wrong layer, orphaned topic files, or gitignore mismatches. These issues accumulate silently between sessions. A periodic structural audit closes this gap.

## v1.6.0 (2026-04-04)

Doc sync step — `/curate` now catches documentation drift from code changes, not just memory staleness.

### Templates
- **`templates/curate.md`** — Added Step 4 (Doc sync check) between memory index update and reference verification. Checks project file architecture section, key commands, runbook operational details, and backlog against current repo state. Steps 4-5 renumbered to 5-6. Report template updated to include doc sync findings.

### Guide
- **`docs/guide/03-the-loop.md`** — Surface phase now lists "Doc sync" as the fifth agent action during end-of-session curation.
- **`docs/guide/04-the-rhythm.md`** — `/curate` flowchart updated with Step 4 (Doc sync check) between memory index and report. Full-picture diagram updated to show doc sync in end-of-session subgraph.

### Guide (README.md)
- Documentation Rhythm table updated: end-of-session action now includes "doc sync."
- Version bumped to 1.6.0.

### Templates
- `templates/project-file.md` — Version bumped to 1.6.0.

### Motivation
Observed in [podcast-generator](https://github.com/ducroq/podcast-generator): a large session with 18 file changes, new modules, renamed CLI flags, and changed defaults left CLAUDE.md and RUNBOOK stale. The existing curate steps (gotcha log, memory index, references) didn't catch documentation drift because they focus on the memory layer, not the project documentation layer. Adding a doc sync step closes this gap — inline updates prevent drift, curate catches what slips through.



Validation checklists, adversarial QA, git-reality validation, and deployment context gotcha.

### Templates
- **`templates/checklists/`** — New directory with definition-of-done checklists for each workflow stage: `architect-checklist.md` (context, design decisions, handoff), `test-checklist.md` (coverage, quality, execution), `implement-checklist.md` (completeness, architecture compliance, cleanup), `qa-checklist.md` (git-reality validation, minimum findings, deployment readiness). Each is 10-15 items — lightweight gates, not enterprise compliance. Closes #3.
- **`templates/checklists/qa-checklist.md`** — Includes **Git Reality Check**: cross-reference `git diff --stat` against claimed changes, flag discrepancies (files changed but undocumented, or documented but unchanged), verify each acceptance criterion has corresponding code. Closes #4.
- **`templates/checklists/qa-checklist.md`** — Includes **Minimum Findings Requirement**: review must surface at least 3 observations with severity classification (CRITICAL/HIGH/MEDIUM/LOW). If fewer than 3, reviewer must document what was verified and why. No "looks good" without evidence. Closes #5.
- **`templates/gotcha-log.md`** — Added worked example: "Tests pass locally but fail in deployment" — sandboxed execution contexts (systemd, Docker, CI) impose constraints that manual/local runs bypass. Closes #6.
- **`templates/RUNBOOK.md`** — Strengthened post-deploy verification: explicit guidance to test through the actual execution context (`systemctl start`, `docker run`, CI trigger), not manual invocation. Includes comment block listing common sandbox constraints.

### Guide (README.md)
- Templates section updated with checklists directory link and description.
- "Growing from there" list updated with checklists as step 10.
- Version bumped to 1.5.0.

### Templates README
- `templates/README.md` — Added checklists entry to "The files" list and `checklists/` row to the tool-naming table.
- `templates/project-file.md` — Added commented-out "Before You Start" rows for checklists (opt-in). Version bumped to 1.5.0.

### Origin
Issues #3–#6 filed after analysis of the BMAD framework's code review workflow (validation checklists, git-reality validation, adversarial review) and a real-world incident where systemd sandbox constraints broke a service that passed all local tests.

## v1.4.0 (2026-04-03)

Freshness check — `/curate` now catches context rot from previous sessions, not just current-session work.

### Templates
- **`templates/curate.md`** — Added Step 0 (Freshness check) before existing steps. Checks four types of staleness: dead references (paths that no longer exist), stale memory (files untouched 30+ days), lingering gotchas (unresolved entries older than 14 days), and ground truth drift (downstream artifacts newer than their canonical source). Step 0 reports only — the engineer decides what to fix. Step 4 (Verify references) now skips when Step 0 already ran. Report template restructured to surface freshness findings.

### Guide
- **`docs/guide/03-the-loop.md`** — Surface phase now lists "Freshness check" as the first of four agent actions. Monthly audit repositioned as "deep audit" since basic staleness is caught every session.
- **`docs/guide/04-the-rhythm.md`** — `/curate` flowchart updated with Step 0 before Step 1. Monthly section renamed "deep audit" with clarification that per-session freshness checks handle basic staleness. Added warning sign: "References point to files that no longer exist." Full-picture diagram updated to show freshness check in end-of-session subgraph.

### Motivation
Inspired by community discussion around automated overnight context maintenance ("dreaming" loops). The core insight — that context structures rot between sessions and manual maintenance doesn't scale — is valid. Our adoption: human-triggered staleness detection built into the existing `/curate` skill, not autonomous overnight loops. Fits the framework's design: the agent surfaces problems, the engineer decides.

## v1.3.4 (2026-03-29)

Fix curate command path for Claude Code — skills, not commands.

### Templates
- Updated `templates/curate.md` — changed Claude Code install path from `.claude/commands/curate.md` to `.claude/skills/curate/SKILL.md` with frontmatter example. The legacy `.claude/commands/` location is no longer discovered by Claude Code; skills require `SKILL.md` inside a named directory under `.claude/skills/`.

### Guide (README.md)
- Fixed three remaining references from `.claude/commands/curate.md` to `.claude/skills/curate/SKILL.md`: concept mapping table, "Automating the rhythm" paragraph, and "Growing from there" list.

### Adoption evidence
- [augur](https://github.com/ducroq/augur) hit the bug: `/curate` returned "Unknown skill" when installed at `.claude/commands/`. Confirmed working after moving to `.claude/skills/curate/SKILL.md` with frontmatter.

## v1.3.3 (2026-03-28)

Curate command template — automates the end-of-session self-learning loop.

### Templates
- Added `templates/curate.md` — end-of-session curation skill that automates gotcha review, pattern promotion, memory index update, and reference verification. For Claude Code, installs as `.claude/skills/curate/SKILL.md` giving a `/curate` skill. For other tools, use as an end-of-session prompt.

### Adopt prompt (adopt.md)
- Added Step 6: install the curate command during project scaffolding.
- Added curate template URL to the template list.

### Guide (README.md)
- Added curate command to the concept mapping table (Tool-Specific Setup).
- Updated "Automating the rhythm" paragraph to reference `/curate` instead of generic "please curate" phrasing.
- Added curate command to the "Growing from there" incremental adoption list.

## v1.3.2 (2026-03-27)

New anti-pattern: files with implicit runtime semantics.

### Guide (README.md)
- Added "Files with implicit runtime semantics" to What Doesn't Work — agents create config-format files "for documentation" that tooling auto-discovers and interprets at runtime (wrangler.toml, docker-compose overrides, .npmrc). Real incident: a review agent added wrangler.toml to document Cloudflare Pages settings; Cloudflare interpreted it at build time, breaking 7+ consecutive deploys.

## v1.3.1 (2026-03-27)

Negative results pattern, adoption evidence from vmodel.eu.

### Guide (README.md)
- Added "Negative results are knowledge" subsection under The Self-Learning Loop — documents the pattern of treating failed experiments as first-class findings that prevent future agents from retrying dead ends.

### Adoption evidence
- [vmodel.eu](https://github.com/ducroq/vmodel.eu) adopted v1.3.0. Key evidence: LLM-assisted score adjustment calibrated on 64 held-out reports, proved harmful, documented as negative result in `memory/calibration-history.md`. INCOSE rule checker (Agent 6) calibrated on 186 reports — detectors tuned from 28 findings/report to 1 using corpus data.

## v1.3.0 (2026-03-26)

Self-learning review agents, non-code domain example, and three new patterns from adopting the framework for educational assessment.

### Framework
- **Self-learning agents** — New section in the self-learning loop: agents can surface their own blind spots. After completing a review, agents run a self-check against their issue categories and ask the user whether to promote new patterns. Closes the loop without requiring the user to notice patterns themselves.
- **Review agent pattern** — Formalized as a reusable skeleton. A review agent is an instruction document with: role + principles, typed issue categories, step-by-step procedure, structured output format, self-check step. Works for any domain (code review, rubric design, assessment audit, paper review).
- **Ground truth principle** — When multiple artifacts describe the same thing, designate one as canonical. Everything else aligns to it. Prevents drift when specs, rubrics, templates, and prompts all describe the same criteria.
- **Three-document pattern** — For structured evaluations, separate instructions (how to evaluate), criteria (how to score), and output template (what the result looks like) into three files. Prevents monolithic prompts that resist updates and drift from external criteria.

### Templates
- Added `templates/review-agent.md` — Reusable skeleton for domain review agents with operating principles, issue categories, review procedure, output format, self-check step, and rules. Includes comments explaining each section.

### Docs
- Added `docs/EXAMPLE-ASSESSMENT.md` — Second worked example: educational assessment system (non-code project). Demonstrates the layered model applied to university assessment with review agents, three-document pattern, ground truth principle, and self-learning loop in practice.

### Guide (README.md)
- Added "Self-learning agents" subsection under The Self-Learning Loop with flow diagram
- Added "Ground truth principle" and "Three-document pattern" under What Doesn't Work > Duplicating content
- Updated Templates section and Further Reading with new files
- Version bumped to 1.3.0

### Adoption evidence
- Framework adopted for [agent-ready-assessment](https://github.com/ducroq/agent-ready-assessment): educational assessment system with 3 course modules (EVML ML/DL, EML), 4 review agents, and full self-learning loop. Non-code domain validates that the layered model works beyond software projects.

## v1.2.0 (2026-03-19)

In-repo memory by default, global file cliff guidance, and first ADR.

### Framework
- **In-repo memory over auto-memory** — Layer 3 location changed from "auto-memory directory (not in repo)" to in-repo `memory/` directory. Based on evidence from 28 projects where hidden auto-memory led to uncurated, orphaned, and invisible knowledge files.
- **Global file cliff** — new guidance on keeping the global instructions file lean and project-agnostic. Project-specific content belongs in project files, not the global file.
- **Commit by default** — replaced the "human benefit" heuristic for routing content. New guidance: commit memory to the repo by default; use auto-memory only for content you would never put in a repository.

### Guide (README.md)
- Layer 3 location updated to reference in-repo `memory/` with link to ADR-001
- Replaced auto-memory vs committed docs table with in-repo vs auto-memory table
- Added "The global file cliff" subsection under Cross-project knowledge
- Layer 4 location simplified to "in-repo `memory/`"
- Removed Claude Code-only note that directed non-Claude users to skip Layer 3

### Decisions
- Added `docs/decisions/` directory
- Added ADR-001: In-Repo Memory Over Auto-Memory — documents the decision, the three problems that motivated it, consequences, and migration guide

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
