---
status: Accepted
date: 2026-04-11
deciders: ducroq
superseded_by:
---

# ADR-002: Multiplayer Coordination Layer

## Context

The framework's four-layer model (project file, runbook, memory, gotcha log) assumes a single developer working with a single agent across sessions. The COMPARISON.md states this explicitly: "The guide doesn't address multi-agent scenarios at all — it's written for a single agent working with a single human."

Three friction points emerge when a second contributor joins a project. These were observed directly in the [RenkumSpot](https://github.com/ducroq/RenkumSpot) project, where contributor Robert (csourcenl) began working alongside the project owner.

### 1. Constraint visibility

Robert's agent submitted PR #5, which changed the `mogelijkheden` data format from objects to strings and removed `slug` fields from event files. Both changes broke the rendering code. The "three-source-of-truth" constraint (Keystatic schema, JSON files, and rendering code must stay in sync) existed in the project file — but there was no mechanism to distinguish "constraints the project owner learned" from "constraints all contributors have agreed to." Robert's agent treated the project file as ducroq's document, not a shared contract.

### 2. Convention divergence

Robert proposed enterprise-grade coding standards in a `constitution-robert.md` file — Domain-Driven Design, full TDD, contract testing, observability. These didn't fit the volunteer project's scope (Principle VII: Simplicity). The mismatch required negotiation and produced ADR-015 in RenkumSpot. Without a staging area for convention proposals, the first signal of divergence was a fully-formed proposal that needed significant rework.

### 3. Work overlap

With 102 commits from ducroq and 2 from Robert, the project's memory, gotcha log, and project file were entirely shaped by one person's workflow. A second contributor's agent inherits this context without knowing which parts are personal preference and which are project truth. There is no visibility into "who is working on what" — two contributors' agents can work on the same area simultaneously, producing conflicting changes that surface only at merge time.

### Landscape context

Research (April 2026) confirms this is a genuine gap. All existing multi-agent frameworks (CrewAI, LangGraph, AutoGen, OpenAI Agents SDK, Semantic Kernel) solve single-user-multi-agent orchestration — one person coordinating multiple AI agents. As of April 2026, no surveyed framework addresses multi-user-multi-agent coordination — different people, each with their own agent, working in the same codebase.

Security and runtime governance are being addressed by OWASP (Top 10 for Agentic Applications, December 2025) and Microsoft (Agent Governance Toolkit, April 2026). But coordination patterns for small teams — who can change shared context, how conventions are proposed and agreed, how work is partitioned — remain uncharted.

## Options Considered

### Option A: Extend existing layers (no new layer)

Add contributor awareness to the project file (Layer 1) and memory index (Layer 3) without introducing a new layer.

| Pros | Cons |
|------|------|
| No new concepts to learn | Overloads project file with coordination concerns |
| Minimal change to framework | Mixes "what is this project" (stable) with "who's working on what" (volatile) |
| Single-user workflow unchanged | No clear place for convention proposals or contributor-specific context |

### Option B: New Layer 5 — Coordination (opt-in)

Add a coordination layer as an opt-in `COORDINATION.md` file, accessed via a task-triggered pointer in the project file.

| Pros | Cons |
|------|------|
| Maintains architectural parallelism (each concern = one layer) | One more file to maintain |
| Opt-in: single-user projects ignore it completely | New concept to explain in the guide |
| Clear boundary: Layers 1–4 = project knowledge, Layer 5 = team coordination | Risk of scope creep toward enterprise governance |
| Natural home for WIP visibility, shared constraints, convention proposals | |

### Option C: Personal overlay files only

Each contributor maintains their own context file (e.g., `constitution-robert.md`). This is what happened organically in RenkumSpot.

| Pros | Cons |
|------|------|
| Each contributor customizes their own experience | No shared coordination — the core problem remains unsolved |
| Already happening organically | Divergence becomes structural rather than prevented |
| Zero overhead for the project owner | Constraints live in per-person files, not in the project |

## Decision

**We chose Option B: a new Layer 5 (Coordination) implemented as an opt-in `COORDINATION.md` template.**

The RenkumSpot case shows that coordination problems are distinct from knowledge problems. The constraint visibility issue (PR #5) is not about missing documentation — the constraint existed — but about missing agreement mechanisms. Convention divergence (Robert's DDD proposal) is not about memory but about negotiation. These are team-level concerns that don't belong in any of the four knowledge-focused layers.

Layer 5 is NOT auto-loaded. It sits below the auto-loading cliff, accessed via a task-triggered pointer in the project file: "When starting work as a contributor → read `COORDINATION.md`." This keeps the auto-loading budget unchanged for single-user projects and for experienced contributors who have already internalized the coordination context.

The self-learning loop gains a deduplication check at the Surface step: when curating at end-of-session in a multi-contributor project, check the gotcha log for entries that duplicate or conflict with other contributors' entries. This is a lightweight check, not a formal merge protocol.

## Consequences

### Positive

- Contributors' agents get explicit orientation about team coordination from session one.
- Convention proposals have a documented path (propose in COORDINATION.md → decide via ADR) instead of surfacing as surprising PRs.
- Work-in-progress visibility reduces merge conflicts and redundant work.
- Single-user workflow is completely unaffected — Layer 5 is opt-in.
- Shared constraints are distinguished from project-owner constraints, making them legible as team agreements.

### Negative

- One more template to maintain in the framework.
- The line between "project constraints" (Layer 1) and "team agreements" (Layer 5) requires judgment.
- Guide and adopt.md grow slightly.

### Risks

- Scope creep: COORDINATION.md becomes a project management tool. Mitigation: template explicitly scopes out task assignment, sprint planning, and access control.
- Overengineering: small teams don't need formal protocols. Mitigation: template targets 2–5 contributors, not enterprise teams. Every section is 5–10 lines.
- Token budget: if placed in auto-loaded position, adds cost to every session. Mitigation: Layer 5 is triggered, not auto-loaded.

## Revisit If

- Agent tools gain native collaboration features (shared memory, real-time presence, built-in coordination).
- A project with 10+ contributors tries to use this and finds it insufficient — that signals enterprise governance is needed, which is out of scope.
- The auto-loading cliff disappears (tools load all project docs by default) — Layer 5's triggered-access design depends on the cliff existing.

## Implementation

1. Create `templates/coordination.md` with five sections: Contributors, Shared Constraints, Convention Proposals, Work in Progress, Memory Conventions.
2. Add a commented-out task-triggered pointer to `templates/project-file.md`.
3. Add a shared-vs-personal memory convention comment to `templates/memory-index.md`.
4. Add a "Multi-Contributor Projects" section to `docs/GUIDE.md`.
5. Update `adopt.md` with multiplayer readiness assessment and coordination setup step.
6. Update `README.md` layered model table and version.
7. Add changelog entry for v1.8.0.

## Related Decisions

- [ADR-001](ADR-001-in-repo-memory-over-auto-memory.md) — In-repo memory over auto-memory. Layer 5 follows the same principle: coordination context belongs in the repo, visible and version-controlled.

## References

- [RenkumSpot PR #5](https://github.com/ducroq/RenkumSpot/pull/5) — field mismatch bugfix that broke rendering due to constraint visibility gap
- [OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) — security framework for agentic systems
- [Microsoft Agent Governance Toolkit](https://github.com/microsoft/agent-governance-toolkit) — runtime security for AI agents (April 2026)
- [Cooperative AI: Multi-Agent Risks from Advanced AI](https://www.cooperativeai.com/post/new-report-multi-agent-risks-from-advanced-ai) — research on multi-agent coordination risks
