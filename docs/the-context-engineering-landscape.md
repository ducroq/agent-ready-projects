---
title: "The Context Engineering Landscape"
subtitle: "Who's building what for AI coding agents — and what nobody's building yet"
author: Jeroen Veen
date: 2026-04-14
status: draft
---

# The Context Engineering Landscape

## April 2026: the field exists now

A year ago, "context engineering for AI coding agents" wasn't a category. You had vendor docs telling you features existed, a few blog posts saying "keep your CLAUDE.md short," and one rigorous analysis from Martin Fowler's site. That was it.

Now there are frameworks with six-figure GitHub stars, an open standard under the Linux Foundation, memory systems competing on benchmarks, linters that validate your context files, sync tools that distribute them across agents, and a growing body of empirical research measuring whether any of it works.

Here's who's doing what — and where the gaps are.

## The frameworks

The big three by adoption:

**[Superpowers](https://github.com/obra/superpowers)** (151K+ stars) enforces workflow discipline: Socratic brainstorming, git worktree isolation, plan decomposition, two-stage code review, mandatory TDD. Installable as skills across Claude Code, Cursor, Codex, Copilot, Gemini CLI. It prescribes *how the agent works* — not what it knows between sessions. No cross-session memory, no layered documentation.

**[OpenCode](https://github.com/anomalyco/opencode)** (95K+ stars) is a Go terminal agent with dynamic rule injection via `.md`/`.mdc` files. Fast, open-source, and a sign that context file patterns are converging across tools.

**[GitHub spec-kit](https://github.com/github/spec-kit)** (73K+ stars) does Spec-Driven Development — specifications generate code. Covers the pre-implementation phase (what to build, how to design it) but stops at the implementation phase (session context, memory, progressive disclosure).

**[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)** (38K+ stars) is the maximalist approach: a full AI-driven agile methodology. v6.3.0 (April 2026) merged 4 agents into a single "Amelia" persona and added a marketplace ecosystem. Comprehensive if you want it to prescribe your entire development process. Heavyweight if you don't.

**[Context Hub](https://github.com/andrewyng/context-hub)** (Andrew Ng, 10K+ stars) curates API docs with agent annotations and a learning loop. Narrower scope — API documentation specifically.

## The standards

**[AGENTS.md](https://agents.md/)** is the de facto standard for agent instruction files. Donated to the Linux Foundation's Agentic AI Foundation (December 2025) alongside Anthropic's MCP and Block's Goose. Platinum members: AWS, Anthropic, Block, Bloomberg, Cloudflare, Google, Microsoft, OpenAI. Also adopted by Sourcegraph, Cursor, and Factory. 60K+ projects use it.

GitHub's analysis of 2,500+ AGENTS.md files (March 2026) shows adoption is broad but quality varies. The standard says *where* to put instructions. It doesn't say *what* to put in them.

**[Agent Skills](https://agentskills.io/)** standardizes portable agent skills: YAML frontmatter plus markdown body. Adopted by 26+ platforms. The format for skills, not a guide for composing them.

**The tools are converging.** Claude Code reads CLAUDE.md. Cursor reads .cursorrules and .mdc. GitHub Copilot added .agent.md and MCP governance (March 2026). Gemini CLI (Google, Apache 2.0) reads AGENTS.md natively with a free tier of 1K requests/day and a 1M token context window. The format differences are cosmetic — everyone is auto-loading markdown.

## The memory systems

The busiest corner of the landscape. Five significant new entrants in early 2026, all benchmarking against each other:

| System | Key metric | Approach |
|---|---|---|
| **[MemMachine](https://github.com/MemMachine/MemMachine)** | 0.9169 LoCoMo | Graph + SQL + working memory |
| **[OMEGA](https://github.com/cso1z/OMEGA)** | 95.4% LongMemEval | MCP server with 25 tools |
| **[MemOS](https://github.com/MemTensor/MemOS)** | 72% token reduction | "Skill memory" — crystallizes successful executions |
| **[SimpleMem](https://github.com/aiming-lab/SimpleMem)** | 64% over Claude-Mem | Simpler architectures, better recall |
| **[Memori](https://github.com/MemoriLabs/Memori)** | — | SQL-native, LLM-agnostic, MCP |

Plus the established players: Mem0, Letta/MemGPT, Graphiti/Zep.

All of them optimize for the same thing: **recall** — can the system retrieve what it stored? LoCoMo and LongMemEval are the benchmarks everyone targets. MemOS is the most interesting outlier: its "skill memory" crystallizes successful agent executions into reusable guides, which is the closest any system comes to a learning loop.

What none of them measure: **truth** — is what was stored still accurate? A system that perfectly retrieves a stale memory scores as well as one that retrieves a current one. More on this below.

## The context tooling

A new category that emerged in early 2026. Three sub-groups:

**Linters** validate your context files:
- **[ctxlint](https://github.com/YawLabs/ctxlint)** checks context files against the actual codebase — catches stale references and dead paths
- **[AgentEval](https://github.com/AgentEval/AgentEval)** does static analysis on CLAUDE.md, .cursorrules, SKILL.md
- **[cclint](https://github.com/carlrannaberg/cclint)** is a Claude Code project linter
- **[AgentLinter](https://agentlinter.com/)** bills itself as "ESLint for agent instructions"

**Rule sync tools** solve multi-tool fragmentation — same project, different agents, different instruction formats:
- **[rulesync](https://github.com/dyoshikawa/rulesync)** syncs `.rulesync/*.md` to Claude Code, Cursor, Gemini CLI, Copilot
- **[vibe-cli](https://github.com/Jinjos/vibe-cli)** does similar cross-platform sync
- **[Rule-Porter](https://github.com/Rule-Porter/Rule-Porter)** converts between Cursor, Claude Code, Copilot formats

**Context optimizers** reduce context size:
- **[context-mode](https://github.com/mksglu/context-mode)** claims 98% context reduction through MCP sandboxing (315KB to 5.4KB)
- **[Tokalator](https://arxiv.org/abs/2604.08290)** is a token budget toolkit with a VS Code extension

The positioning of this entire category is interesting: they all assume context files exist and handle the format, validation, and distribution. None address what should be in the files or why.

## The research

The empirical evidence is growing. Two studies that practitioners should know:

**[Gloaguen et al. — "Evaluating AGENTS.md"](https://arxiv.org/abs/2602.11988)** (ETH Zurich, February 2026) tested whether context files help coding agents across SWE-bench. LLM-generated context files *reduced* task success by 3% — agents followed unnecessary instructions and ran extra checks that made tasks harder. Human-written files improved success by 4% but increased inference costs by 19%. The takeaway: more context is not better context. Only include what the agent cannot infer from the code.

**[Rombaut et al. — "Impact of AGENTS.md"](https://arxiv.org/abs/2601.20404)** found that across 124 pull requests, AGENTS.md reduced agent runtime by 28.6% and token usage by 16.6%. The two studies aren't contradictory — the first says quality matters more than presence; the second shows that when quality is good, the gains are significant.

On the theoretical side:

**[Li et al. — "Externalization in LLM Agents"](https://arxiv.org/abs/2604.08224)** (21 authors, SJTU/CMU, April 2026) argues that agent capability is moving from model weights to externalized memory, skills, and protocols. If you're spending time on context files, this paper is the theoretical justification: the context *is* the capability.

**[Zhang et al. — "Memory for Autonomous LLM Agents"](https://arxiv.org/abs/2603.07670)** is the comprehensive survey of memory systems 2022-2026. Good entry point if you want to understand where memory research stands.

For aggregated resources: **[Awesome Agent Memory](https://github.com/TeleAI-UAGI/Awesome-Agent-Memory)** collects papers, systems, and benchmarks. **[awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)** collects skills, hooks, and patterns for Claude Code.

## The gaps

With all this activity, what's nobody building?

**Content guidance.** The entire context tooling category (linters, sync tools, optimizers) handles format and distribution. Nobody addresses what should be in the files. AgentLinter tells you your CLAUDE.md has structural issues — it doesn't tell you what to write instead. The ETH Zurich study shows this matters: bad content actively hurts. But "what to write in your AGENTS.md" remains unaddressed by any tool.

**Memory verification.** Every memory system optimizes recall. None verify truth. A memory entry that says "deployed to production" will be faithfully retrieved months after the deployment was rolled back. LoCoMo and LongMemEval don't test for this — they measure retrieval accuracy, not factual accuracy. As agents rely more on externalized memory (the "Externalization" thesis), this becomes a real problem.

**Multi-user coordination.** Multi-agent orchestration (CrewAI, LangGraph, AutoGen, OpenAI Agents SDK) solves one person coordinating multiple AI agents. Nobody addresses multiple people, each with their own agent, working in the same codebase. Security is covered (OWASP Top 10, Microsoft Agent Governance Toolkit). Team coordination is not.

**Session strategy.** When to start a fresh session. Why reviewing in the building session is a bad idea. How to use cross-model validation. No guide, framework, or tool addresses this.

## What it means for practitioners

If you're structuring projects for AI agents today:

1. **Pick a standard format.** AGENTS.md is the safe bet — broadest adoption, institutional backing, read natively by Gemini CLI and supported by most tools. The format doesn't matter much; the content does.

2. **Be surgical with content.** The ETH Zurich study is the most important finding in this space: naive context files make agents worse. Only write what the agent can't infer from the code — hard constraints, non-obvious conventions, and pointers to deeper docs.

3. **Use task-triggered pointers.** "When doing X, read Y" beats "see Y." The difference between docs your agent loads and docs it ignores.

4. **Don't trust memory.** If you're using any memory system, remember that high recall scores don't mean accurate memories. State claims go stale. Verify them.

5. **Watch the tooling.** Context linters and rule sync tools are young but useful. ctxlint catching stale references automatically is worth more than a quarterly manual audit.

The field is maturing fast. A year ago, the question was "should I create a CLAUDE.md?" Now the question is "what should I put in it and how do I keep it accurate?" That's progress.
