# Landscape: Context Engineering for AI Coding Agents

Where this guide sits relative to existing work. Last updated April 2026.

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
- **[AGENTS.md](https://agents.md/)** (60K+ projects) — an open format for agent instructions, donated to the Agentic AI Foundation under the Linux Foundation (December 2025) alongside Anthropic's MCP and Block's Goose. Platinum members: AWS, Anthropic, Block, Bloomberg, Cloudflare, Google, Microsoft, OpenAI. Standardizes *where* to put instructions but doesn't address *how* to structure them, when to split, or how to handle progressive disclosure. A format spec, not a guide. GitHub's analysis of 2,500+ AGENTS.md files (March 2026) shows adoption is broad but quality varies — most files lack the structural patterns this guide provides.
- **[Agent Skills](https://agentskills.io/)** (agentskills.io) — open standard for portable agent skills. YAML frontmatter (`name`, `description`) + markdown body. Adopted by 26+ platforms including Claude Code, Codex, Cursor, Copilot, Gemini CLI. Released by Anthropic (December 2025), now community-maintained. Defines the format for skills; doesn't address how skills compose into a layered memory system or how teams coordinate shared skills.

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

### 6. Empirical research on context files

- **[Gloaguen et al. — "Evaluating AGENTS.md"](https://arxiv.org/abs/2602.11988)** (ETH Zurich, February 2026) — the first rigorous evaluation of whether context files help coding agents. Key findings: LLM-generated context files *reduced* task success rates by an average of 3%. Human-written files improved success by 4% but increased inference costs by over 19%. Agents followed unnecessary instructions, running extra tests and checks that made tasks harder. Implication: context files need to be surgical — only what the agent cannot infer from the code. Validates the "be surgical" principle and the layered approach (don't dump everything in one auto-loaded file).

### 7. Multi-agent coordination and security

Frameworks and standards addressing what happens when multiple agents (or multiple users' agents) interact.

- **[OWASP Top 10 for Agentic Applications](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/)** (December 2025) — security framework covering goal hijacking, tool misuse, identity abuse, memory poisoning, insecure inter-agent communication, cascading failures, rogue agents. 100+ expert contributors. Addresses runtime security risks, not team coordination.
- **[Microsoft Agent Governance Toolkit](https://github.com/microsoft/agent-governance-toolkit)** (April 2026) — open-source runtime security for AI agents. Policy enforcement at sub-millisecond latency, covers all 10 OWASP risks. Integrates with LangChain, CrewAI, Google ADK. Python, Rust, TypeScript, Go, .NET. Addresses runtime governance, not project-level coordination.
- **[Google A2A Protocol](https://github.com/google/A2A)** (v1.0.0, March 2026) — agent-to-agent interoperability via JSON-RPC. Agents publish "Agent Cards" describing capabilities. Enables cross-boundary agent communication but provides no coordination semantics (who goes first, conflict resolution, shared state).
- **[Cooperative AI — "Multi-Agent Risks from Advanced AI"](https://www.cooperativeai.com/post/new-report-multi-agent-risks-from-advanced-ai)** (February 2025) — taxonomy of multi-agent risks: miscoordination, conflict, collusion. 50+ researchers from DeepMind, Anthropic, CMU, Harvard. Analyzes risks at the system level, not at the project/team level.

**Multi-agent orchestration frameworks** (CrewAI, LangGraph, AutoGen/AG2, OpenAI Agents SDK, Semantic Kernel, MetaGPT) — all solve single-user-multi-agent orchestration. One person coordinating multiple AI agents for different tasks. None address multi-user-multi-agent coordination — different people, each with their own agent, working in the same codebase. As of April 2026, this remains an unoccupied gap.

**Memory systems** (Mem0, Letta/MemGPT, Graphiti/Zep) — single-user or multi-user-isolated. No open-source system supports shared team memory with write governance and attribution. Zep's commercial platform claims governance features but is not open-source.

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
| **Multi-contributor coordination** | No framework addresses what happens when multiple users' agents work in the same codebase — constraint visibility, convention divergence, work overlap. Every guide assumes a single author. Security is being addressed (OWASP, Microsoft AGT), but team coordination patterns remain uncharted. This guide addresses this gap with Layer 5 (v1.8.0). |
| **Context file effectiveness** | The ETH Zurich study (February 2026) shows that naive context files can hurt agent performance. No guide except this one integrates the finding that context must be surgical — only non-inferable constraints and task-triggered pointers, not exhaustive documentation. |

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

## Positioning: ahead, at parity, and behind

### Ahead

- **Multiplayer coordination** (Layer 5, v1.8.0) — the only practical pattern for multi-user-multi-agent coordination. No competing framework, standard, or guide addresses this. Validated through the RenkumSpot case study.
- **The self-learning loop** — Capture/Surface/Promote/Retire with `/curate` and `/audit-context` skills. More sophisticated than static context file approaches. The ETH Zurich finding (static files can hurt) implicitly validates dynamic, curated context.
- **The auto-loading cliff** — named and formalized as an architectural concept. No other framework identifies this boundary or its consequences for documentation design.
- **Verification infrastructure** — the companion [agent-ready-papers](https://github.com/ducroq/agent-ready-papers) framework provides typed claim verification (CLAIM/ARGUMENT/PROPOSITION with Toulmin/Whetten checklists) that catches real errors in AI-assisted writing.

### At parity

- **Project file conventions** — aligned with AGENTS.md standard and agentskills.io spec (markdown + YAML frontmatter). Standard format, not proprietary.
- **Skills format** — follows agentskills.io spec. Portable across 26+ platforms.
- **ADR patterns** — solid but common across many frameworks.

### Behind

- **Standards authority** — AGENTS.md has the Linux Foundation, AWS, Google, Microsoft, OpenAI behind it. This framework has one practitioner and 28 projects. The patterns may be better, but the institutional backing is not comparable.
- **Runtime governance** — Microsoft's Agent Governance Toolkit does sub-millisecond policy enforcement covering all 10 OWASP risks. Our Layer 5 is a coordination file, not a runtime security system. Different scope, and that's by design.
- **Tooling and distribution** — no CLI, no VS Code extension, no registry. Adoption is "read the guide, paste the prompt." The ecosystem is moving toward discoverable, composable components with SDK support.
- **Scale of evidence** — deep but narrow. 28 projects, one primary user, one multiplayer case study. The ETH Zurich study tested across SWE-bench with multiple agents and configurations.

### Strategic positioning

This is a **practitioner framework**, not a platform or standard. The value is in the patterns (cliff, layers, loop, coordination) and the discipline (curate, audit, typed verification). The path forward is contributing these patterns *into* the standards ecosystem — not competing with AGENTS.md or agentskills.io, but complementing them with the structural and coordination patterns they lack.
