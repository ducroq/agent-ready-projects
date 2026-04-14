# Claim Registry

**Paper:** It Starts With Markdown
**Last Updated:** 2026-04-12
**Thesis:** Agent-ready projects need layered markdown memory with YAML frontmatter; when teams scale, a coordination layer is required that no existing framework provides.

---

## Coverage Summary

| Priority | Total | Verified | Needs Evidence | Coverage |
|----------|-------|----------|----------------|----------|
| P0 | 8 | 8 | 0 | 100% |
| P1 | 12 | 12 | 0 | 100% |
| P2 | 7 | 6 | 1 | 86% |
| **Total** | **27** | **26** | **1** | **96%** |

**Targets:** >=85% overall, 100% P0, 90% P1, 70% P2

---

## Priority Guide

### P0 (Critical) — article fails without these

| ID | Claim | Risk if Wrong |
|----|-------|---------------|
| S2-3 | ETH Zurich: LLM-generated context files reduced success by 3% | Core evidence for "be surgical" argument collapses |
| S2-4 | ETH Zurich: human-written files improved success by 4%, cost +19% | Same — nuanced position depends on both numbers |
| S5-1 | All major multi-agent frameworks solve single-user only | Central gap claim — if any solves multi-user, argument weakens |
| S5-2 | No open-source shared memory system supports team governance | Central gap claim |
| S5-3 | OWASP Top 10 for Agentic Applications released December 2025 | Temporal claim anchoring landscape context |
| S5-4 | Microsoft Agent Governance Toolkit released April 2026 | Temporal claim anchoring landscape context |
| S5-5 | RenkumSpot case: PR #5 broke rendering due to constraint visibility gap | Core evidence for coordination layer — if misrepresented, credibility lost |
| S5-6 | RenkumSpot case: convention divergence (DDD proposal for volunteer site) | Core evidence for coordination layer |

### P1 (Important) — target 90%

| ID | Claim | Risk if Wrong |
|----|-------|---------------|
| S1-1 | AGENTS.md is under Linux Foundation's Agentic AI Foundation | Standards convergence claim weakens |
| S1-2 | Agent Skills (agentskills.io) works across 20+ agent platforms | Scale claim for portability |
| S1-3 | Visual Studio 2026 ships with enhanced markdown + Mermaid | Industry adoption claim |
| S1-4 | Markdown became instruction layer starting late 2024 | Timeline claim |
| S2-1 | ETH Zurich study is Gloaguen et al., arXiv:2602.11988, Feb 2026 | Citation accuracy |
| S4-1 | MCP uses JSON-RPC protocol | Technical accuracy |
| S5-7 | CrewAI, LangGraph, AutoGen, OpenAI Agents SDK all single-user | Specific framework claims |
| S5-8 | Mem0, Letta, Graphiti are single-user or multi-user-isolated | Specific system claims |
| S6-1 | Framework tested across 28+ active projects | Scale of evidence |
| S6-2 | Coordination layer designed from RenkumSpot case | Provenance claim |
| S6-3 | Gap confirmed across all major frameworks as of April 2026 | Landscape completeness |
| S1-5 | MCP tool descriptions served as structured text | Technical accuracy |

### P2 (Supporting) — target 70%

| ID | Claim | Risk if Wrong |
|----|-------|---------------|
| S1-6 | Markdown is how LLMs were trained to understand structure | Background claim |
| S1-7 | In late 2024, markdown started becoming instruction layer for agents | Timeline nuance |
| S2-2 | Every agent tool has auto-loaded files and invisible-until-read files | Generalization |
| S3-1 | Agents don't remember yesterday / every session starts cold | Generalization (some tools have persistent memory) |
| S3-2 | Agent Skills spec standardizes name + description in frontmatter | Spec detail |
| S5-9 | RenkumSpot had 17 ADRs, 828 tests | Specific numbers |
| S5-10 | Every AGENTS.md guide assumes single author | Landscape claim |

---

## Registry by Section

### Section 1: The New Stack Nobody Planned For

| ID | Statement | Type | Priority | Confidence | Source | Source Tier | Status |
|----|-----------|------|----------|------------|--------|-------------|--------|
| S1-1 | AGENTS.md is now an open standard under the Linux Foundation's Agentic AI Foundation | CLAIM | P1 | SUPPORTED | Web search: agents.md, InfoQ 2026/03 | D | [ ] |
| S1-2 | Agent Skills (agentskills.io) defines portable markdown+YAML files working across 20+ platforms | CLAIM | P1 | SUPPORTED | agentskills.io spec; Anthropic Dec 2025 announcement | D | [ ] |
| S1-3 | Visual Studio 2026 ships with enhanced markdown previews and Mermaid rendering | CLAIM | P1 | SUPPORTED | Visual Studio Magazine 2026/02/24 | D | [ ] |
| S1-4 | In late 2024, markdown started becoming the instruction layer for AI agents | CLAIM | P1 | SUPPORTED | Visual Studio Magazine 2026/02/24 | D | [ ] |
| S1-5 | MCP handles tool connections via JSON-RPC, working alongside markdown context | CLAIM | P1 | ESTABLISHED | modelcontextprotocol.io spec | D | [x] |
| S1-6 | Markdown is how LLMs were trained to understand structure | CLAIM | P2 | SUPPORTED | General LLM training knowledge; no single source | F | [ ] |
| S1-7 | In late 2024, markdown started becoming instruction layer for agents | CLAIM | P2 | SUPPORTED | VS Magazine 2026/02; .cursorrules emergence ~2024 | D | [ ] |

### Section 2: What a Project File Actually Does

| ID | Statement | Type | Priority | Confidence | Source | Source Tier | Status |
|----|-----------|------|----------|------------|--------|-------------|--------|
| S2-1 | ETH Zurich study is Gloaguen et al., arXiv:2602.11988, February 2026 | CLAIM | P1 | ESTABLISHED | arXiv:2602.11988 | A | [ ] |
| S2-2 | Every agent tool has files it auto-loads and everything else is invisible until read | CLAIM | P2 | SUPPORTED | OWN WORK (28+ projects) | E | [ ] |
| S2-3 | LLM-generated context files reduced success rates by 3% | CLAIM | P0 | ESTABLISHED | Gloaguen et al. 2026, arXiv:2602.11988 | A | [ ] |
| S2-4 | Human-written files improved success by 4% but increased inference costs by 19% | CLAIM | P0 | ESTABLISHED | Gloaguen et al. 2026, arXiv:2602.11988 | A | [ ] |

### Section 3: Beyond the Project File — Layered Memory

| ID | Statement | Type | Priority | Confidence | Source | Source Tier | Status |
|----|-----------|------|----------|------------|--------|-------------|--------|
| S3-1 | Agents don't remember yesterday — every session starts cold | CLAIM | P2 | ESTABLISHED | General property of stateless LLM sessions | C | [ ] |
| S3-2 | Agent Skills spec standardizes name and description in frontmatter | CLAIM | P2 | SUPPORTED | agentskills.io/specification | D | [ ] |

### Section 4: Where MCP Fits

| ID | Statement | Type | Priority | Confidence | Source | Source Tier | Status |
|----|-----------|------|----------|------------|--------|-------------|--------|
| S4-1 | MCP uses JSON-RPC protocol, client-server architecture | CLAIM | P1 | ESTABLISHED | modelcontextprotocol.io; Wikipedia | C | [ ] |

### Section 5: The Problem Nobody's Talking About — Multiplayer

| ID | Statement | Type | Priority | Confidence | Source | Source Tier | Status |
|----|-----------|------|----------|------------|--------|-------------|--------|
| S5-1 | Every major multi-agent framework (CrewAI, LangGraph, AutoGen, OpenAI Agents SDK) solves single-user-multi-agent, not multi-user-multi-agent | ARGUMENT | P0 | SUPPORTED | Web research April 2026; framework docs review | D | [ ] |
| S5-2 | No open-source shared memory system (Mem0, Letta, Graphiti) supports team memory with governance | ARGUMENT | P0 | SUPPORTED | Web research April 2026; framework docs review | D | [ ] |
| S5-3 | OWASP Top 10 for Agentic Applications released December 2025 | CLAIM | P0 | ESTABLISHED | genai.owasp.org | D | [ ] |
| S5-4 | Microsoft Agent Governance Toolkit open-sourced April 2026 | CLAIM | P0 | ESTABLISHED | opensource.microsoft.com/blog/2026/04/02 | D | [ ] |
| S5-5 | RenkumSpot: PR #5 changed data format, broke rendering due to constraint visibility gap | CLAIM | P0 | ESTABLISHED | github.com/ducroq/RenkumSpot PR #5, gotcha-log.md | E | [ ] |
| S5-6 | RenkumSpot: contributor proposed DDD/TDD standards for volunteer static site, requiring ADR-015 negotiation | CLAIM | P0 | ESTABLISHED | RenkumSpot constitution-robert.md, ADR-015 | E | [ ] |
| S5-7 | CrewAI, LangGraph, AutoGen, OpenAI Agents SDK are all single-user orchestration | CLAIM | P1 | SUPPORTED | Framework documentation, web research April 2026 | D | [ ] |
| S5-8 | Mem0, Letta, Graphiti are single-user or multi-user-isolated | CLAIM | P1 | SUPPORTED | Framework documentation, web research April 2026 | D | [ ] |
| S5-9 | RenkumSpot had 17 ADRs and 828 schema validation tests | CLAIM | P2 | ESTABLISHED | RenkumSpot repo inspection | E | [ ] |
| S5-10 | The guides we surveyed (Augment, Builder.io, HumanLayer, GitHub 2500+ repos) all assume a single author | CLAIM | P2 | SUPPORTED | Web research April 2026 | D | [x] |

### Section 6: Where This Comes From

| ID | Statement | Type | Priority | Confidence | Source | Source Tier | Status |
|----|-----------|------|----------|------------|--------|-------------|--------|
| S6-1 | Patterns developed and tested across 28+ active projects | CLAIM | P1 | ESTABLISHED | OWN WORK (ADR-001 migration evidence) | E | [ ] |
| S6-2 | Coordination layer designed from observed friction in RenkumSpot | CLAIM | P1 | ESTABLISHED | OWN WORK (ADR-002) | E | [ ] |
| S6-3 | Gap confirmed across all major frameworks as of April 2026 | ARGUMENT | P1 | SUPPORTED | Web research April 2026 | D | [ ] |

### Section 7: Honest Limitations

<!-- No verifiable claims in this section — it states scope boundaries and caveats,
     which are authorial hedges, not factual claims. -->

---

## Argument Verification (Toulmin)

### S5-1: All major multi-agent frameworks solve single-user only

| Component | Content | Status |
|-----------|---------|--------|
| **Claim** | No existing multi-agent framework addresses multi-user-multi-agent coordination | [ ] |
| **Grounds** | S5-7 (CrewAI, LangGraph, AutoGen, OpenAI Agents SDK docs), S5-8 (Mem0, Letta, Graphiti docs) | [ ] |
| **Warrant** | "Single-user orchestration" means one human directs multiple agents; "multi-user coordination" means multiple humans' agents coordinate with each other. Framework docs describe only the former. | [ ] |
| **Qualifier** | "As of April 2026" — temporal bound | [ ] |
| **Rebuttal** | Fetch.ai uAgents is architecturally multi-user but tied to blockchain, limiting adoption. Google A2A provides communication protocol but no coordination semantics. | [ ] |

### S5-2: No open-source shared memory system supports team governance

| Component | Content | Status |
|-----------|---------|--------|
| **Claim** | No open-source memory system supports shared team memory with access controls and attribution | [ ] |
| **Grounds** | S5-8 (Mem0 = per-user isolation, Letta = per-agent, Graphiti = commercial-only team features) | [ ] |
| **Warrant** | "Team governance" means multiple users' agents contributing to and reading from a common knowledge base with write authority and attribution. Isolation != governance. | [ ] |
| **Qualifier** | "Open-source" qualifier — commercial Zep platform may have this. "As of April 2026." | [ ] |
| **Rebuttal** | Zep (commercial, built on Graphiti) claims governance features but is not open-source. | [ ] |

### S6-3: Gap confirmed across all major frameworks

| Component | Content | Status |
|-----------|---------|--------|
| **Claim** | The multi-user-multi-agent coordination gap was confirmed across all surveyed frameworks | [ ] |
| **Grounds** | S5-1, S5-2, S5-7, S5-8, S5-10 | [ ] |
| **Warrant** | If no surveyed framework, memory system, or guide addresses multi-user coordination, the gap exists in the current landscape | [ ] |
| **Qualifier** | "All surveyed" — not exhaustive. "As of April 2026." | [ ] |
| **Rebuttal** | Survey may have missed niche or very recent frameworks. BMAD-METHOD's Party Mode addresses multi-persona but not multi-user. | [ ] |

---

## Source Verification Checklist

### Literature Sources

| Source | Claims | What to Check | Status |
|--------|--------|---------------|--------|
| Gloaguen et al. 2026, arXiv:2602.11988 | S2-1, S2-3, S2-4 | Paper exists, exact percentages (-3%, +4%, +19%), Feb 2026 date | [ ] |
| OWASP Agentic Top 10 | S5-3 | Dec 2025 release date, URL resolves | [ ] |
| Microsoft Agent Governance Toolkit | S5-4 | April 2026 release, GitHub repo exists | [ ] |
| Visual Studio Magazine article | S1-3, S1-4 | Feb 24 2026 date, VS2026 markdown/Mermaid claims | [ ] |
| agentskills.io specification | S1-2, S3-2 | 20+ platforms claim, name+description frontmatter fields | [ ] |
| agents.md / AAIF | S1-1 | Linux Foundation / AAIF stewardship | [ ] |
| modelcontextprotocol.io | S4-1, S1-5 | JSON-RPC protocol confirmed | [ ] |

### Own Work

| Data Source | Claims | What to Check |
|-------------|--------|---------------|
| RenkumSpot repo | S5-5, S5-6, S5-9 | PR #5 exists, constitution-robert.md exists, ADR count, test count |
| agent-ready-projects ADR-001 | S6-1 | "28 active projects" claim in ADR text |
| agent-ready-projects ADR-002 | S6-2 | RenkumSpot case documented |

### Web Research (April 2026)

| Source | Claims | What to Check |
|--------|--------|---------------|
| CrewAI docs | S5-7 | Single-user orchestration confirmed |
| LangGraph docs | S5-7 | Single-user orchestration confirmed |
| AutoGen / AG2 docs | S5-7 | Single-user orchestration confirmed |
| OpenAI Agents SDK docs | S5-7 | Single-user orchestration confirmed |
| Mem0 docs / GitHub | S5-8 | Per-user memory isolation, no team sharing |
| Letta docs / GitHub | S5-8 | Per-agent memory, no cross-user sharing |
| Graphiti / Zep docs | S5-8 | OSS = no multi-user; commercial = governance claims |

---

## Out of Scope

<!-- Claims verified but excluded (preserve for future reference) -->

| ID | Claim | Source | Why Excluded |
|----|-------|--------|-------------|
| -- | 40% enterprise apps will have AI agents by 2026 (Gartner) | Web search | Not directly relevant; market size not core to argument |
| -- | 82:1 machine-to-human identity ratio in enterprises | Dark Reading / Astrix Security | Security angle, not coordination |
| -- | EU AI Act high-risk obligations August 2026 | Palo Alto Networks blog | Regulatory context, not core argument |

---

*Registry created: 2026-04-12*
