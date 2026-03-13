# Landscape: Context Engineering for AI Coding Agents

Where this guide sits relative to existing work. Last updated March 2026.

## State of the Art

The field of structuring projects for AI coding agents is young and fragmented. Most work falls into one of four categories:

### 1. Feature documentation (tool vendors)

Tool vendors document their own context features without prescribing how to use them effectively.

- **[Anthropic — Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)** documents CLAUDE.md, rules, skills, hooks, and MCP. Tells you the features exist and how to configure them. Doesn't address when to split files, how to structure memory, or why some configurations work better than others.
- **[VS Code — Context Engineering Guide](https://code.visualstudio.com/docs/copilot/guides/context-engineering-guide)** covers Copilot's context flow in VS Code. Tool-specific, focuses on IDE integration.
- **[Claude Code Memory docs](https://code.claude.com/docs/en/memory)** explain the memory hierarchy (global → project → directory → rules). Documents the mechanism without the principles.

These are reference material, not guides. They answer "what can I configure?" not "what should I configure?"

### 2. Tactical advice (practitioners)

Blog posts and guides sharing practical tips from experience.

- **[Addy Osmani — "My LLM Coding Workflow"](https://addyosmani.com/blog/ai-coding-workflow/)** — iterative workflow advice: plan before executing, review every change, keep context focused. Good habits, but stays at the workflow level without addressing project structure.
- **[SFEIR — Claude Code Best Practices](https://institute.sfeir.com/en/claude-code/claude-code-resources/best-practices/)** — "use /init", "keep CLAUDE.md under 200 lines", "use plan mode." Actionable but shallow — tells you what to do, not why it works.
- **[eesel.ai — "7 Essential Claude Code Best Practices"](https://www.eesel.ai/blog/claude-code-best-practices)** — similar: practical tips without a unifying model.

These are valuable for getting started. They don't explain the underlying dynamics (why 200 lines? what happens when you exceed it? where does the overflow go?).

### 3. Frameworks and methodologies (systems)

Complete systems that prescribe how to work with AI agents.

- **[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)** (38K+ stars) — a full AI-driven agile development methodology with 12+ agent personas, 34+ workflows, module system, and installer. Addresses context management through agent-specific sidecar memory and manifests. Comprehensive but heavyweight — prescribes your entire development process. See [COMPARISON.md](COMPARISON.md) for a detailed mapping.
- **[GitHub spec-kit](https://github.com/github/spec-kit)** (73K+ stars) — Spec-Driven Development where specifications generate code. Addresses context through constitutions and template-driven LLM constraint. Covers the pre-implementation phase (what to build, how to design it) but not the implementation phase (session context, memory, progressive disclosure). The two are complementary — spec-kit produces the specification artifacts, this guide ensures agents find and use them effectively. See [COMPARISON.md](COMPARISON.md) for how to use them together.
- **[AGENTS.md](https://agents.md/)** (60K+ projects) — an open format for agent instructions. "A README for agents." Standardizes *where* to put instructions but doesn't address *how* to structure them, when to split, or how to handle progressive disclosure. A format spec, not a guide.

### 4. Analytical frameworks (researchers)

Deeper analysis of context engineering as a discipline.

- **[Martin Fowler / Birgitta Böckeler — "Context Engineering for Coding Agents"](https://martinfowler.com/articles/exploring-gen-ai/context-engineering-coding-agents.html)** — the most rigorous existing analysis. Proposes a framework with two dimensions: who triggers context loading (LLM / human / agent software) and quantity management. Catalogs Claude Code's features along these dimensions. Descriptive and well-structured, but maps the features rather than prescribing how to use them. Doesn't address memory persistence, cross-session knowledge, or the dynamics of auto-loaded vs. on-demand context.
- **[Anthropic — "Effective Context Engineering"](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)** — official guide aimed at agent *builders* (API-level context: system prompts, tool definitions, retrieval). Different audience than agent *users* structuring their projects.
- **[HumanLayer — "Advanced Context Engineering for Coding Agents"](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents)** — focuses on session-level context management: keep the window at 40-60% capacity, use subagents for research, prioritize correctness over completeness over size. Good tactical framework. Explicitly doesn't cover memory persistence, layered documentation, or cross-session knowledge.
- **[Packmind — "Keeping context files accurate"](https://packmind.com/evaluate-context-ai-coding-agent/)** — identifies the drift problem (CLAUDE.md goes stale as codebases evolve). Proposes audits and automated detection. Addresses one symptom without the underlying structural model.

### 5. Concept-specific writing

Individual concepts explored in isolation.

- **[Progressive Disclosure for AI Agents](https://aipositive.substack.com/p/progressive-disclosure-matters)** and **[Marta Fernández García on progressive disclosure](https://medium.com/@martia_es/progressive-disclosure-the-technique-that-helps-control-context-and-tokens-in-ai-agents-8d6108b09289)** — apply the UX concept of progressive disclosure to agent context. Treat it as a single technique rather than part of a larger system.
- **[Claude-mem](https://docs.claude-mem.ai/progressive-disclosure)** — a third-party tool adding memory persistence to Claude Code. Solves the mechanical problem without addressing the structural question of what to persist and how to organize it.

## Gap Analysis

Across all existing work, several things are well-covered:

- **What features exist** in each tool (Fowler, vendor docs)
- **Tactical tips** for getting started (blog posts)
- **Complete methodologies** for AI-driven development (BMAD, spec-kit)
- **Session-level optimization** of context windows (HumanLayer)

What's missing:

| Gap | What it means |
|-----|--------------|
| **The auto-loading cliff** | No existing work names or analyzes the hard boundary between auto-loaded and on-demand context, or its structural consequences for documentation design |
| **Task-triggered navigation** | No guide distinguishes between descriptive pointers ("see X") and task-triggered pointers ("when doing Y, read X") — the difference between a dead link and one agents actually follow |
| **Layered documentation model** | Existing advice is either "put everything in one file" or "use a framework with 30+ files." No work proposes a scale-dependent layered model with clear criteria for when to split |
| **Memory as index** | Advice about memory files is either "keep them short" or "dump everything in." No work addresses the index-not-dump pattern or the consequences of truncation limits |
| **Cross-session knowledge management** | Gotcha logs, promotion/retirement patterns, the distinction between operational problems and design dead ends — none of this appears in existing guides |
| **Agent behavior validation** | Pressure testing, honesty constraints, sunk-cost bias — existing work trusts that good context produces good behavior without addressing validation |
| **Session strategy** | No existing guide addresses when to use fresh sessions, why reviewing in the building session is problematic, or cross-model validation |
| **Development practices** | Course-correction, documentation rhythm, the feedback loop between guide and project — treated as project management concerns, not agent effectiveness concerns |

## Where This Guide Fits

This guide occupies a specific position in the landscape:

```
                    Scope
                    ↑
     Full SDLC      │  BMAD-METHOD    spec-kit
     methodology    │
                    │
     Project        │  ┌─────────────────────┐
     infrastructure │  │  This guide          │
                    │  └─────────────────────┘
                    │
     Session-level  │  HumanLayer     Fowler/Böckeler
     optimization   │
                    │
     Feature        │  Vendor docs    AGENTS.md
     reference      │
                    ├──────────────────────────────→
                   Prescriptive              Descriptive
```

- **More prescriptive than Fowler** (who maps features without recommending structure) but **less prescriptive than BMAD** (which prescribes your entire workflow)
- **Broader than HumanLayer** (which optimizes single sessions) but **narrower than spec-kit** (which addresses the full build process)
- **Principled rather than tactical** — explains *why* patterns work, not just *what* to do
- **Tool-agnostic** — principles apply across Claude Code, Codex, Cursor, Windsurf, Copilot, and others

The closest existing work is Fowler/Böckeler's analysis, which shares the analytical rigor but stays descriptive. This guide takes the next step: from "here are the features and dimensions" to "here's how to structure your project so agents self-navigate effectively."

## Methodology

This guide was not written from theory. It was developed through iterative testing:

1. Initial model drafted from patterns observed across 100+ agent sessions
2. Applied to a real project — failures surfaced (the auto-loading cliff discovery)
3. Revised based on concrete breakdowns (task-triggered pointers replaced descriptive labels)
4. Multi-agent audit: three independent agents audited three different projects against the guide
5. Consolidated feedback applied (duplication nuance, context budgets, retirement patterns)
6. Cross-referenced against BMAD-METHOD and spec-kit for completeness
7. Conductor (a predecessor framework by the same author) mined for additional patterns

Each major concept in the guide traces to a specific failure or discovery during this process. See [METHODOLOGY.md](METHODOLOGY.md) for the full development story.

The guide continues to evolve through the feedback loop it describes: insights from applying it to active projects feed back into the guide, and updates to the guide are checked against active projects.

---

*Since this landscape was written, the guide has added: the **self-learning loop** (Capture → Surface → Promote → Retire) as a named first-class concept, a **processor memory hierarchy analogy** grounding the layered model in cache design principles, an **agent-driven adoption workflow** ([adopt.md](../adopt.md)) with assess/adopt/update prompts, and **versioning** ([CHANGELOG.md](../CHANGELOG.md)) for tracking framework evolution across adopted projects. None of the existing tools in the landscape offer this combination.*
