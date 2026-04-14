---
title: "It Starts With Markdown"
subtitle: "What your AI agents actually need — and what breaks when your team scales"
author: Jeroen Veen
date: 2026-04-12
status: draft
---

# It Starts With Markdown

## Your agent reads markdown. Everything else follows from that.

Your AI coding agent doesn't read your Jira tickets, your Confluence pages, or your Notion docs. It reads markdown. Every agent — Claude Code, Codex, Cursor, Copilot, Windsurf, Aider — parses the same format: headings for hierarchy, lists for enumeration, code blocks for "run this," tables for comparison.

This convergence isn't a coincidence. Markdown is one of the primary formats LLMs learned to parse for structure during pretraining. When you write a CLAUDE.md or AGENTS.md file, you're not writing documentation. You're programming your agent's behavior in the one language it reads natively.

The industry caught on fast. In late 2024, markdown started becoming the instruction layer for AI agents. By 2026, it's infrastructure:

- **AGENTS.md** is an open standard under the Linux Foundation's Agentic AI Foundation, donated by OpenAI alongside Anthropic's MCP and Block's Goose.
- **Agent Skills** (agentskills.io) defines portable markdown-with-YAML-frontmatter skill files adopted by 26+ agent platforms — Claude Code, Codex, Cursor, Copilot, Gemini CLI, and others.
- **MCP** (Model Context Protocol) handles tool connections via JSON-RPC — the plumbing that lets agents reach databases, APIs, and file systems. It works alongside markdown context, not instead of it.
- **Visual Studio 2026** ships with enhanced markdown previews and Mermaid rendering, treating markdown as a first-class AI working surface.

But knowing markdown is the format is table stakes. What matters is what you put in it — and how you structure it so your agent actually benefits.

## A project file is a navigation system

When your agent starts a session, it loads a project file — CLAUDE.md, AGENTS.md, .cursorrules, or whatever your tool calls it. Auto-injected into the context window. Read before anything else.

Most teams treat this like a README: project description plus some rules. That works until it doesn't.

The architectural insight: a project file is a **navigation system**, not a description. The most important thing in it isn't what it says — it's what it *points to*.

### The auto-loading cliff

Every agent tool has files it auto-loads and everything else might as well not exist. The divide is binary — we call it the auto-loading cliff. Below the cliff, your documentation is invisible. The agent won't read it unless directed, and "directed" means a specific, task-triggered pointer: not "see docs/RUNBOOK.md" but "**when** changing deployment config, read docs/RUNBOOK.md."

This is the single most practical insight in context engineering: auto-loaded files should be indexes that route agents to the right context at the right time.

### Be surgical — or pay the cost

The ETH Zurich study (Gloaguen et al., arXiv:2602.11988, February 2026) tested whether AGENTS.md files actually help across multiple coding agents and benchmarks. The findings are sobering:

- **LLM-generated context files reduced task success rates by an average of 3%.** Agents followed unnecessary instructions — running extra tests, performing quality checks that weren't needed — making tasks harder, not easier.
- **Human-written files improved success by 4% on average** — but increased inference costs by over 19%, because agents spent more tokens processing the additional context.

The lesson: more context is not better context. Only include what the agent cannot infer from the code itself. Hard constraints ("never modify migration files after staging"), non-obvious conventions ("the CMS strips slug fields from JSON on save — all loaders must derive slugs from filenames"), and task-triggered pointers to deeper docs. Everything else burns tokens and can actively mislead the agent.

## Beyond one session: layered memory

A project file gets you through one session. But agents start every session cold — no memory of yesterday's bugs, decisions, or failed approaches.

The solution is layered memory. Each layer has a different lifecycle and serves a different purpose:

| Layer | What | Auto-loaded? | When to add |
|-------|------|-------------|-------------|
| **1. Project file** | Identity, constraints, navigation pointers | Yes | Always (start here) |
| **2. Runbook** | Operational how-to, development principles | No | When the project file gets crowded |
| **3. Memory** | Index + topic files of learned knowledge | Index: yes | When complexity grows |
| **4. Gotcha log** | Problem, root cause, fix — structured journal | No | First bug worth remembering |

The project file is stable — it changes when the architecture changes. The gotcha log is append-only — new entries surface every session. The memory index is curated — entries get promoted upward when they prove their value and retired when they're stale.

### The self-learning loop

The layers connect through a four-phase loop:

**Capture** (during work) &rarr; **Surface** (end-of-session curation) &rarr; **Promote** (recurring lessons move up) &rarr; **Retire** (fixed issues get removed)

Concretely: a CMS gotcha logged in session 4 gets promoted to a topic file by session 8, reaches the memory index by session 15, and gets retired when the root cause is fixed in session 22. Total effort: about 2 minutes spread across 6 sessions. Your agent gets smarter with every session, not just every prompt.

### YAML frontmatter: metadata that machines can parse

Markdown gives agents structure. YAML frontmatter gives them metadata they can act on without reading the whole document.

```yaml
---
stack: Python 3.12, FastAPI, PostgreSQL
status: Production
framework: agent-ready-projects v1.8.0
---
```

An agent can read `status: Production` and adjust its behavior — more careful, never skip tests — before processing a single line of the markdown body. The Agent Skills spec (agentskills.io) standardizes this pattern: `name` and `description` in frontmatter for routing, behavioral instructions in the markdown body.

The full pattern: **YAML for machines, markdown for reasoning, task-triggered pointers for navigation.**

## Where MCP fits — and where it doesn't

MCP (Model Context Protocol) is often mentioned alongside markdown context files. They solve different problems entirely:

| | MCP | Markdown context |
|---|---|---|
| **Purpose** | Connect agents to external tools and data | Orient agents to the project |
| **Format** | JSON-RPC 2.0 protocol, client-server | Plain markdown + YAML frontmatter |
| **Analogy** | USB — a universal plug for peripherals | Employee handbook — read on day one |
| **Scope** | Runtime: "call this API, query this database" | Session: "here's how we work here" |

They're complementary, not competing. An agent connected to your CRM via MCP still doesn't know that your team never modifies customer records directly — that's a project file constraint. A perfectly documented project file doesn't help an agent that can't reach the deployment API.

**MCP for reach. Markdown for understanding. Task-triggered pointers for navigation.**

## The problem nobody's talking about: multiplayer

Everything above works for one developer with one agent. And that's where the discourse stops. The AGENTS.md guides, the CLAUDE.md tutorials, the context engineering posts — all assume a single author writing instructions for their own agent.

Real projects have teams. And when a second contributor's agent enters a codebase that was set up for one, things break in ways that better documentation can't fix.

### What actually broke

We hit this on [RenkumSpot](https://github.com/ducroq/RenkumSpot), a community platform for the gemeente Renkum in the Netherlands. The project was thoroughly agent-ready: layered memory, 17 architecture decision records, 820 schema validation tests, a gotcha log with a working promotion lifecycle. By any measure, a well-documented codebase.

Then Robert joined. His agent read the project file, loaded the memory, and got to work.

**Problem 1: Constraint visibility.** Robert's agent submitted [PR #5](https://github.com/ducroq/RenkumSpot/pull/5), which changed the `mogelijkheden` data structure from objects to strings and removed `slug` fields from event files. Both changes broke the rendering code. The project file had a hard constraint — "never modify content structure without updating both the Keystatic schema and the rendering code" — but Robert's agent treated it as the project owner's note. There was no distinction between "what I learned through experience" and "what the team has agreed to."

**Problem 2: Convention divergence.** Robert proposed a `constitution-robert.md` with enterprise-grade coding standards: Domain-Driven Design, full test-driven development, contract testing, observability. Professionally sound practices — for a volunteer-maintained static site with no server runtime. The mismatch required negotiation that produced ADR-015 in the project. Without a staging area for convention proposals, the first signal of misalignment was a fully-formed document that didn't fit.

**Problem 3: Work overlap.** 102 commits from the project owner, 2 from Robert. The memory, gotcha log, and project file were shaped entirely by one person's workflow. Robert's agent inherited context without knowing which parts were project truth and which were personal preference. No visibility into who was working on what, or what areas to avoid.

These aren't documentation problems — the documentation was excellent. They're **coordination problems**, and the project file, memory index, and gotcha log aren't designed to solve them.

### The landscape gap

We surveyed the field (April 2026) and found a consistent pattern:

- **Multi-agent frameworks** (CrewAI, LangGraph, AutoGen/AG2, OpenAI Agents SDK, Semantic Kernel) all solve single-user-multi-agent orchestration — one person coordinating multiple AI agents. None address what happens when different people's agents work in the same codebase.
- **Memory systems** (Mem0, Letta, Graphiti) are either single-user or multi-user-isolated. No open-source system supports shared team memory with write governance and attribution.
- **The guides we surveyed** (Augment Code, Builder.io, HumanLayer, GitHub's analysis of 2,500+ AGENTS.md files) all assume a single author.
- **Security** is being addressed — the OWASP Top 10 for Agentic Applications (December 2025) covers runtime risks like tool misuse, memory poisoning, and rogue agents. Microsoft's Agent Governance Toolkit (open-sourced April 2, 2026) enforces runtime policy. But coordination patterns for teams sharing a codebase? Uncharted.

### Layer 5: Coordination

The fix is a fifth layer — opt-in, not auto-loaded, designed for projects with 2-5 contributors:

| Layer | What | Auto-loaded? | When to add |
|-------|------|-------------|-------------|
| **1. Project file** | Identity, constraints, navigation | Yes | Always |
| **2. Runbook** | Operational how-to | No | When the project file gets crowded |
| **3. Memory** | Learned knowledge | Index: yes | When complexity grows |
| **4. Gotcha log** | Problem-fix journal | No | First bug worth remembering |
| **5. Coordination** | Contributors, shared constraints, WIP, conventions | No | When contributor #2 joins |

A COORDINATION.md with five sections:

- **Contributors** — who's active, their focus areas, how they work. Not permissions — a "who to ask about what" index.
- **Shared Constraints** — constraints the team has explicitly agreed to. Distinct from project file constraints, which are "how this project works." Shared constraints are "what we all committed to."
- **Convention Proposals** — a staging area. Robert's DDD proposal would have gone here first, been discussed, and either adopted (via ADR) or rejected (with a record of why) — instead of surfacing as a surprise document.
- **Work in Progress** — collision-avoidance signals. Before starting work in an area, check if someone else is already there.
- **Memory Conventions** — shared vs personal memory, how gotcha log entries are tagged with contributor names, how deduplication works when two agents log the same lesson.

This is not project management. It's not enterprise governance. It's the minimum viable coordination that prevents your second contributor's agent from breaking what your first contributor's agent built.

## Three levels of agent readiness

Most teams are at level 1. Some reach level 2. Almost nobody has thought about level 3.

**Level 1: Connection.** Your agent can reach tools and systems. MCP servers configured, API keys set, file system access working. The plumbing is in place.

**Level 2: Orientation.** Your agent understands the project. A project file with hard constraints and task-triggered pointers. Layered memory that persists across sessions. A self-learning loop that captures lessons and promotes them as they prove their value. YAML frontmatter for machine-parseable metadata.

**Level 3: Coordination.** Your team's agents work together without stepping on each other. Shared constraints that represent team agreements, not one person's notes. Convention proposals that happen before PRs. Work-in-progress visibility that prevents collisions. Memory governance that handles deduplication when multiple agents log the same lesson.

It all starts with markdown. But it doesn't end there.

## Try this Monday

1. **No project file yet?** Create a CLAUDE.md or AGENTS.md with 3 hard constraints and a "Before You Start" table of task-triggered pointers. Ten minutes, highest ROI change you can make.

2. **Project file but no memory?** Add a gotcha log. Next time your agent makes a mistake, log the problem, root cause, and fix in three lines. After three sessions you'll have enough entries to see patterns worth promoting.

3. **Multiple contributors?** Create a COORDINATION.md. List who's working on what. Move your most critical project file constraints into a "Shared Constraints" section and get explicit agreement from the team. Fifteen minutes, and it prevents the PR that breaks everything.

4. **Generating your context file with an LLM?** Stop. The ETH Zurich study shows LLM-generated context files reduce success rates. Write it yourself — only what the agent can't infer from the code.

## Where this comes from

The layered model, self-learning loop, and auto-loading cliff were developed and tested across 28+ active projects using Claude Code, Cursor, and other agents over several months. They are documented in the open-source [agent-ready-projects](https://github.com/ducroq/agent-ready-projects) framework (v1.8.0).

The coordination layer (Layer 5) was designed from the friction observed in RenkumSpot — the specific incidents described above, not theoretical concerns. The landscape survey was conducted in April 2026 across the major multi-agent frameworks, memory systems, and published guides.

## Honest limitations

- **Tool dependency.** The layered model was developed primarily with Claude Code. The principles transfer, but auto-loading behavior varies across tools.
- **Sample size.** The coordination layer is designed from one multi-contributor case study. Broader adoption will surface edge cases we haven't seen.
- **Benchmark vs reality.** The ETH Zurich findings apply to benchmark tasks (SWE-bench, AGENTbench). Real-world projects with non-obvious constraints — deployment quirks, CMS gotchas, privacy requirements — may benefit more from context files than benchmarks suggest.
- **Scale limit.** Layer 5 targets small teams (2-5 contributors). Organizations with 10+ contributors need governance infrastructure beyond what a markdown file provides. See the OWASP Agentic Top 10 and Microsoft's Agent Governance Toolkit for enterprise-scale approaches.
- **Shelf life.** This space moves fast. Standards, tools, and best practices described here reflect April 2026. Revisit in six months.

## References

- Gloaguen, T. et al., "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?", arXiv:2602.11988, February 2026
- OWASP Top 10 for Agentic Applications, December 2025 — https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/
- Microsoft Agent Governance Toolkit, April 2026 — https://github.com/microsoft/agent-governance-toolkit
- Agent Skills Open Standard — https://agentskills.io/specification
- AGENTS.md Standard (Agentic AI Foundation / Linux Foundation) — https://agents.md/
- Model Context Protocol — https://modelcontextprotocol.io/
- Cooperative AI Foundation, "Multi-Agent Risks from Advanced AI", arXiv:2502.14143, February 2025
- Visual Studio Magazine, "In Agentic AI, It's All About the Markdown", February 2026 — https://visualstudiomagazine.com/articles/2026/02/24/in-agentic-ai-its-all-about-the-markdown.aspx
- GitHub Blog, "How to write a great agents.md: Lessons from over 2,500 repositories" — https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/
- agent-ready-projects framework (v1.8.0) — https://github.com/ducroq/agent-ready-projects
