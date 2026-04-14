---
title: "Verifying What We Write"
subtitle: "We ran a claim verification framework on an article about AI agent readiness. It caught three errors."
author: Jeroen Veen
date: 2026-04-12
status: draft
---

# Verifying What We Write

## The setup

We wrote an article called "It Starts With Markdown" about what AI coding agents need from your project documentation — layered memory, YAML frontmatter, task-triggered pointers, and a coordination layer for teams. The article cites an ETH Zurich study, references OWASP and Microsoft releases, describes an open-source framework tested across 28+ projects, and draws on a real case study where a second contributor's agent broke things in a well-documented codebase.

Before publishing, we ran it through a verification framework originally built for academic papers. The framework types every verifiable statement (CLAIM, ARGUMENT, or PROPOSITION), assigns a priority (P0 = article fails without it, P1 = strengthens it, P2 = background), checks sources against a 6-step anti-hallucination checklist, and calibrates language to evidence strength.

The article describes this framework. And the framework caught errors in the article.

## What we found: 27 claims, 3 corrections

The claim registry extracted 27 verifiable statements from a ~2,400-word article. That's roughly one claim per 90 words — denser than typical blog posts because the article is evidence-heavy by design.

### The breakdown

| Priority | Count | What's at stake |
|----------|-------|-----------------|
| P0 (critical) | 8 | Core argument collapses if wrong |
| P1 (important) | 12 | Credibility weakens |
| P2 (supporting) | 7 | Background color, not load-bearing |

Three claims were typed as ARGUMENTs rather than CLAIMs — meaning they needed Toulmin verification (warrant, grounds, qualifier, rebuttal) rather than simple source-checking. These were the landscape gap claims: "no framework solves multi-user coordination," "no memory system supports team governance," and "the gap was confirmed across all surveyed frameworks." Each got a full Toulmin breakdown with explicit rebuttals (Fetch.ai's blockchain-tied approach, Zep's commercial-only governance).

### The three errors caught

**Error 1: Wrong test count.**

The article said the case study project had "828 schema validation tests." We ran the actual test suite: 820 passed. Off by 8 — probably a count from an earlier session before some tests were consolidated. Small number, but exactly the kind of specific-sounding-but-wrong detail that erodes trust if someone checks.

*How it got in:* An agent explored the repository earlier in the conversation and reported "828 tests" based on a cached or interpolated number. The claim passed through the article draft without re-verification against the live codebase.

*How it was caught:* The anti-hallucination checklist flags "own work" claims for verification against repo artifacts. Running `npx vitest run` returned 820.

**Error 2: Imprecise MCP claim.**

The article originally said: "even MCP tool descriptions are served as structured text that agents parse like markdown." This implies MCP tool descriptions are in markdown format. They're not — they're plain text strings within a JSON-RPC schema. MCP uses JSON-RPC 2.0; the descriptions are text, but calling them "markdown-like" is misleading.

*How it got in:* The article was making a rhetorical point — "everything is converging on markdown" — and stretched the MCP connection to support it. The claim was technically defensible in a loose sense (agents do parse the text) but imprecise enough to be wrong in a strict sense.

*How it was caught:* The claim was typed as P1/EMERGING in the registry, flagging it for source verification. Checking the MCP specification at modelcontextprotocol.io confirmed JSON-RPC with text descriptions, not markdown.

*Revised to:* "MCP handles tool connections via JSON-RPC — a structured protocol that works alongside markdown-based context files."

**Error 3: Oversimplified training claim.**

The article originally said: "Markdown is how LLMs were trained to understand structure." This implies markdown was *the* format, when in reality LLMs are trained on HTML, code, plain text, PDFs, books, and many other formats. Markdown is one significant input — CommonCrawl pipelines convert HTML to markdown for cleaner extraction — but it's not the sole or even primary training format.

*How it got in:* The opening section wanted a strong claim to explain *why* agents read markdown natively. The statement was directionally correct but overstated.

*How it was caught:* The registry typed it as P2/SUPPORTED with a note: "General knowledge claim; no single citable source. Oversimplification." That flag triggered a web search for LLM pretraining data composition, which confirmed markdown is one of several formats — not "how" LLMs were trained.

*Revised to:* "Markdown is one of the primary formats LLMs learned to parse for structure during pretraining."

## What the framework looks like in practice

### The claim registry

Every verifiable statement gets a row:

| ID | Statement | Type | Priority | Confidence | Source | Status |
|----|-----------|------|----------|------------|--------|--------|
| S2-3 | LLM-generated context files reduced success rates by 3% | CLAIM | P0 | ESTABLISHED | Gloaguen et al. 2026, arXiv:2602.11988 | [x] |
| S5-1 | No surveyed multi-agent framework addresses multi-user coordination | ARGUMENT | P0 | SUPPORTED | Web research April 2026 | [x] |
| S5-9 | RenkumSpot had 17 ADRs and 820 tests | CLAIM | P2 | ESTABLISHED | Repo inspection | [x] |

The "Type" column matters. S5-1 is an ARGUMENT, not a CLAIM — it synthesizes evidence from multiple framework reviews into a conclusion. That means it needs Toulmin verification: is the warrant valid? Are the grounds verified? What's the strongest counter-argument?

The Toulmin breakdown for S5-1:

| Component | Content |
|-----------|---------|
| **Claim** | No surveyed framework addresses multi-user-multi-agent coordination |
| **Grounds** | CrewAI, LangGraph, AutoGen, OpenAI Agents SDK docs — all single-user |
| **Warrant** | "Single-user" means one human directs multiple agents; "multi-user" means different humans' agents coordinate. Framework docs describe only the former. |
| **Qualifier** | "As of April 2026" — temporal bound. "Surveyed" — not exhaustive. |
| **Rebuttal** | Fetch.ai uAgents is architecturally multi-user but tied to blockchain. Google A2A provides communication but no coordination semantics. |

Without typing S5-1 as an ARGUMENT, it would have been checked like a CLAIM — "does a source say this?" — which misses the real verification question: "is the reasoning valid?"

### The anti-hallucination checklist

Eight sources, six steps each. Step 0 (quick web search + DOI resolution) catches fabrications in seconds. The full checklist takes about 2 minutes per source.

| # | Source | Step 0 | Steps 1-6 | Status |
|---|--------|--------|-----------|--------|
| 1 | Gloaguen et al. 2026 | PASS | 5/6 (exact % from secondary sources) | Verified with caveat |
| 2 | OWASP Agentic Top 10 | PASS | 6/6 | Verified |
| 3 | Microsoft Agent Governance Toolkit | PASS | 6/6 | Verified |
| 4 | VS Magazine article | PASS | 6/6 | Verified |
| 5 | agentskills.io | PASS | 6/6 | Verified |
| 6 | agents.md / AAIF | PASS | 6/6 | Verified |
| 7 | modelcontextprotocol.io | PASS | 6/6 | Verified (triggered article revision) |
| 8 | Cooperative AI report | PASS | 6/6 | Verified |

Source 1 (ETH Zurich) has a caveat: the specific percentages (-3%, +4%, +19%) are reported consistently across five secondary sources (MarkTechPost, InfoQ, i-scoop, ClawSouls, Medium) but ideally should be confirmed against the paper's results tables for exact context — which benchmark, which agent configuration, aggregate vs per-model. The article added "on average" and "across tested configurations" qualifiers to reflect this.

Source 7 (MCP spec) passed all six steps but triggered the imprecise claim correction (Error 2 above). The checklist doesn't just verify sources exist — Step 4 ("does the claim match the paper's scope?") catches cases where a real source is used to support a claim it doesn't actually make.

### Language calibration

The writing guide maps confidence tiers to appropriate language:

| Tier | Language | Example from article |
|------|----------|---------------------|
| ESTABLISHED | "demonstrates", "confirms" | "reduced task success rates by an average of 3%" |
| SUPPORTED | "indicates", "suggests" | "no surveyed framework addresses..." |
| EMERGING | "may", "preliminary" | "designed from observed friction" (Layer 5) |

The framework's own recommendations (Layers 1-5) are OWN WORK at EMERGING confidence — designed from one case study, tested in one framework. The article uses appropriate language: "the fix is" (authorial recommendation, clearly presented as such), not "research demonstrates."

## Why this matters beyond academic papers

This framework was built for scholarly writing — academic papers where a single fabricated citation can invalidate an entire argument. But the errors it caught in this article weren't academic. They were practitioner errors:

- A specific number that sounded right but was stale (820 vs 828)
- A technical claim stretched to serve a rhetorical point (MCP "like markdown")
- An oversimplification that made a complex reality sound tidier than it is (LLM training)

These are the errors that AI-assisted writing produces at scale. An agent that helped draft the article introduced the stale test count. The rhetorical stretch was a human choice amplified by an agent's willingness to support it. The oversimplification was the kind of confident-sounding statement that agents produce naturally and humans approve because it reads well.

The verification framework catches them because it forces you to ask three questions about every statement:

1. **What type is this?** (Fact, reasoning, or recommendation — each verified differently)
2. **How confident should I be?** (Not how confident do I feel — what does the evidence support?)
3. **Does the source actually say this?** (Not "does a source exist" — does it say what I claim it says?)

Fifteen minutes of registry work. Forty minutes of source checking. Three corrections that would have been embarrassing to discover after publication.

## The meta observation

An article about agent readiness, verified by a framework for agent-assisted writing, which caught errors introduced during agent-assisted drafting. The framework works on the content it describes, and the content demonstrates why the framework exists.

This isn't accidental cleverness. It's the natural result of building verification into the writing process rather than bolting it on at the end. The claim registry, the anti-hallucination checklist, the language calibration guide — they're markdown files with structured sections. They follow the same principles the article advocates: layered, task-triggered, self-documenting.

If you're writing about AI with AI, you need infrastructure to verify what you produce. Not because agents are unreliable — but because the combination of human editorial judgment and agent-generated content creates a confidence surface that's smooth where it should be rough.

The numbers sound right. The sources seem real. The logic flows. And sometimes, 8 tests are missing.

## References

- Verification log, claim registry, writing guide, and anti-hallucination checklist: [docs/vv/](https://github.com/ducroq/agent-ready-projects/tree/master/docs/vv)
- "It Starts With Markdown" (the article verified): [docs/it-starts-with-markdown.md](https://github.com/ducroq/agent-ready-projects/blob/master/docs/it-starts-with-markdown.md)
- agent-ready-papers verification framework: https://github.com/ducroq/agent-ready-papers
- Gloaguen, T. et al., "Evaluating AGENTS.md", arXiv:2602.11988, February 2026
