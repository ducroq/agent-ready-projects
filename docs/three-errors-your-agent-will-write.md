---
title: "Three Errors Your Agent Will Write For You"
subtitle: "AI-assisted writing produces confident-sounding mistakes that humans approve because they read well"
author: Jeroen Veen
date: 2026-04-12
status: draft
---

# Three Errors Your Agent Will Write For You

## The problem isn't hallucination. It's plausibility.

Everyone knows AI agents fabricate citations. That's old news — you check, the paper doesn't exist, you delete it. Easy to catch because the failure is binary: real or fake.

The harder problem is the claim that's *almost* right. The number that sounds specific enough to be true. The technical statement that's directionally correct but imprecise enough to be wrong. The simplification that makes complex reality sound tidier than it is.

These aren't hallucinations. They're plausible errors — and they survive review because they read well.

We found three types while verifying a technical article about AI agent infrastructure. Each represents a pattern that shows up anywhere agents help produce written content.

## Error type 1: The stale number

**What we wrote:** "820 schema validation tests"

**What was true:** 820.

Except the first draft said 828. An agent had explored the codebase earlier in the session and reported that number. By the time it appeared in the article, eight tests had been consolidated in a refactoring. The number was stale — accurate at some prior point, wrong now.

**Why it survived:** 828 is specific. Specific numbers signal rigor. Nobody questions a number like 828 because it doesn't look made up — round numbers feel estimated, odd numbers feel counted. The agent didn't invent it; it reported what it found at an earlier point. The human approved it because it read like a fact.

**The pattern:** Agents carry forward numbers from earlier in a conversation or from cached context. If the source data changes — tests consolidated, records added, a count recalculated — the agent's number becomes stale without any signal that it's wrong. The more specific the number, the more trustworthy it looks, and the less likely anyone is to re-check it.

**How to catch it:** A second agent ran the test suite — `npx vitest run` — and got 820. Three seconds. The writing agent introduced the stale number; the verification agent caught it by checking the live source. Not "does this number sound right?" but "does this number come back when I run the command right now?"

## Error type 2: The rhetorical stretch

**What we wrote:** "even MCP tool descriptions are served as structured text that agents parse like markdown"

**What was true:** MCP uses JSON-RPC 2.0. Tool descriptions are plain text strings inside a JSON schema. Agents parse them, yes — but they're not markdown, not markdown-like, and not served in a way that's meaningfully similar to markdown context files.

**Why it survived:** The article was arguing that "everything is converging on markdown." MCP tool descriptions being text-that-agents-parse fit the narrative. The claim was technically defensible in a loose sense — agents do parse the text — but it conflated "text that an agent reads" with "markdown," which is a specific format with specific structural semantics. The stretch served the rhetoric.

**The pattern:** When an agent helps build an argument, it optimizes for coherence. If the surrounding text says "everything is markdown," the agent will find ways to make adjacent facts support that claim — even when the connection is tenuous. Humans approve it because a coherent argument feels like a correct one.

**How to catch it:** The verification agent checked the claim against the MCP specification at modelcontextprotocol.io. The spec says JSON-RPC 2.0 with text descriptions — not markdown. The agent flagged the mismatch: "NEEDS REVISION — tool descriptions are text strings in JSON, not markdown." It could do this because the claim registry had typed it as P1/EMERGING, which triggered source verification rather than just a plausibility check.

Revised to: "MCP handles tool connections via JSON-RPC — a structured protocol that works alongside markdown-based context files." Accurate. Doesn't stretch.

## Error type 3: The tidy simplification

**What we wrote:** "Markdown is how LLMs were trained to understand structure."

**What was true:** LLMs are trained on HTML, code, plain text, books, PDFs, structured data, and many other formats. Markdown is one significant input — CommonCrawl pipelines increasingly convert HTML to markdown for cleaner extraction — but it's not "how" LLMs were trained. It's one of several formats in a multi-petabyte pretraining mixture.

**Why it survived:** The opening of the article needed a strong claim to explain why agents read markdown natively. "One of several formats in a multi-petabyte mixture" doesn't hook a reader. "This is how LLMs were trained" does. The simplification made the sentence punch harder, and the agent produced it because it's the kind of confident, clean statement that LLMs generate naturally.

**The pattern:** Agents flatten nuance into clean claims. Complex realities get reduced to single sentences that sound authoritative. The simplification isn't random — it's systematic. Agents produce the version that reads best, which is usually the version that's most simplified. Humans approve it because concise, confident statements feel more professional than hedged ones.

**How to catch it:** The registry had flagged it: "General knowledge claim; no single citable source. Oversimplification." That flag triggered the verification agent to search for "LLM pretraining data formats," which immediately surfaced CommonCrawl pipeline documentation showing markdown as one of several input formats. The agent recommended softening the claim.

Revised to: "Markdown is one of the primary formats LLMs learned to parse for structure during pretraining." Less punchy. More true.

## The common thread

All three errors share a property: **they read better than the truth.**

828 reads better than 820 (more specific-sounding). "Even MCP descriptions are markdown-like" reads better than "MCP uses a different protocol entirely" (supports the narrative). "This is how LLMs were trained" reads better than "this is one of several formats" (stronger claim).

Agents optimize for text that reads well. That's what they're trained to do. When you're writing with an agent, the first draft will be fluent, coherent, and confident. The errors won't be obvious — they'll be woven into prose that flows.

This is why "does it read well?" is the wrong review criterion for AI-assisted writing. Good prose is a *necessary* condition for quality, but it's no longer a *sufficient* one. You need a second pass that asks different questions.

## Use agents to verify agents

None of the corrections above came from manual fact-checking. A writing agent drafted the article. A verification agent — working from a claim registry, an anti-hallucination checklist, and a writing guide — caught the errors. Same underlying technology, different role, different instructions.

The key is structure. The verification agent doesn't just re-read the article and say "looks good." It works through a typed registry where every claim has a priority, a confidence tier, and a source to check. That structure turns "review this article" into a series of specific, falsifiable tasks:

- **For facts:** Run the command, fetch the URL, resolve the DOI. Does the source exist and say what we claim?
- **For arguments:** Check the reasoning. Are the grounds verified? Is the warrant explicit? What's the strongest counter-argument?
- **For recommendations:** Are boundary conditions stated? Does the language match the evidence strength?

Three habits make this work:

**1. Type your claims.** Fact, conclusion, or recommendation — each verified differently. The stale number was a fact that needed source-checking. The rhetorical stretch was a conclusion that needed reasoning-checking. The simplification was a fact that needed complexity-checking.

**2. Let the verification agent run commands.** Not "does this number sound right?" but "run the test suite and tell me the count." Agents checking agents against live systems catch what agents reviewing text cannot.

**3. Flag confidence in the registry.** When a claim is marked EMERGING or has no single source, the verification agent knows to search harder. The MCP claim and the training claim were both flagged this way — the registry's metadata directed the verification, not the agent's judgment.

## The deeper issue

These three error types — stale numbers, rhetorical stretches, tidy simplifications — aren't bugs in AI. They're features of fluent text generation meeting the realities of knowledge decay, argumentative pressure, and complexity reduction.

They'll show up in every AI-assisted blog post, report, proposal, and documentation page. Not because the agent is lying, but because the agent is doing exactly what it's built to do: produce text that reads well and sounds confident.

The fix isn't human vigilance — it's agent infrastructure. A writing agent and a verification agent, working from the same registry but with different objectives. The writer optimizes for clarity and coherence. The verifier optimizes for accuracy and evidence. The tension between them is the quality control.

The question isn't whether your agent-assisted writing contains these errors. It's whether you have a second agent looking for them.

## References

- Gloaguen, T. et al., "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?", arXiv:2602.11988, February 2026
- Model Context Protocol specification — https://modelcontextprotocol.io/
- agent-ready-papers verification framework — https://github.com/ducroq/agent-ready-papers
