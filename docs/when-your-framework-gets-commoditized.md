---
title: "When Your Framework Gets Commoditized"
subtitle: "I built a context engineering framework for AI agents. The ecosystem absorbed it. Here's what that taught me."
author: Jeroen Veen
date: 2026-04-14
status: draft
---

# When Your Framework Gets Commoditized

## The framework

In late 2025, I started structuring my projects so AI coding agents could self-navigate across sessions. The agent starts cold every time — no memory of yesterday's bugs, no awareness of your architectural decisions. So I built a layered documentation system: a project file as a routing table, task-triggered pointers to deeper docs, a gotcha log for recurring problems, a curation loop that promotes lessons over time.

I called it "agent-ready projects." I wrote a guide, a landscape analysis, a comparison against competing frameworks, a methodology document explaining how the patterns were discovered. I versioned it. v1.8.0 added multiplayer coordination. v1.9.0 added self-verifying memory. I tracked where it was ahead of the ecosystem and where it was behind. I maintained positioning statements.

28 projects. One primary user. Me.

## The ecosystem

In April 2026, I did a landscape refresh. I expected to find a few new entrants. I found a transformed field.

**The basics were commoditized.** Every major tool now has an auto-loaded project file — CLAUDE.md, AGENTS.md, .agent.md, .cursorrules, .mdc. The "auto-loading cliff" I named? It's common knowledge. "Keep the project file short" is standard advice. Task-triggered pointers show up in blog posts without attribution (which is fine — that's how ideas spread).

**Tooling overtook manual patterns.** Context linters (ctxlint, AgentLinter, cclint) validate your files automatically — replacing the manual `/audit-context` skill I maintained. Rule sync tools (rulesync, vibe-cli, Rule-Porter) solve multi-tool fragmentation without a guide. Five new memory systems (MemMachine, MemOS, OMEGA, SimpleMem, Memori) benchmark far beyond anything manual markdown files can do.

**Heavyweights got heavier.** BMAD-METHOD at 38K stars. Superpowers at 151K. GitHub spec-kit at 73K. AGENTS.md backed by the Linux Foundation, AWS, Google, Microsoft, OpenAI. The ecosystem voted with adoption, and it didn't pick a 28-project practitioner framework.

## The honest question

After cataloging all of this, I asked myself: is this framework still useful?

The answer was split.

**For my own projects — yes.** Nothing else covers exactly the same ground. BMAD prescribes your entire dev process. Superpowers is workflow discipline. Neither gives you the layered files, the gotcha log, the curate skill, or self-verifying memory. Switching would mean adopting a heavier system that covers different ground while losing the parts that actually work.

**As a public framework competing for adoption — no.** The core insights have been absorbed. The unique contributions (self-verifying memory, multiplayer coordination) are real but narrow — two features, not a framework. The maintenance overhead of landscape analysis, versioning, comparison docs, and positioning statements was framework-author work for an audience that hadn't shown up.

## What I did

I archived the framework wrapper — the landscape, the comparison doc, the methodology, the positioning. I kept the templates, the skills, and the curation loop. I still use them daily.

Then I extracted the three ideas that are genuinely mine and haven't been absorbed yet:

1. **The auto-loading cliff** — the hard line between what agents see automatically and what's invisible. Not the observation (everyone knows this now) but the structural consequence: your project file is a routing table, not a README.

2. **Self-verifying memory** — agents embed verification commands in state claims at write time, execute them at read time. Born from a real incident where a "shipped" memory entry was wrong and 230 articles were affected. No memory system does this — they all optimize recall, not truth.

3. **Task-triggered pointers** — "when doing X, read Y" instead of "see Y." One word changes whether agents load your docs or ignore them.

Each became a standalone blog post. No framework dependency. No "read the guide first." Just the idea, the evidence, and a practical example.

## What this taught me

**Ideas travel. Frameworks don't.** A blog post about the auto-loading cliff will reach more practitioners than a 173-line landscape analysis ever did. The packaging was wrong — I was wrapping ideas in infrastructure they didn't need.

**Commoditization is validation.** When your insight becomes common knowledge, that's success. The auto-loading cliff is now ambient understanding across the ecosystem. That's better than being cited — it means the idea was right.

**Maintain the patterns, not the wrapper.** The templates and skills work. The curation loop works. Self-verifying memory works. I don't need a versioned framework to use them. I need markdown files in my projects and the discipline to curate them.

**The "behind" section was the honest part.** In my landscape analysis, I wrote both what was ahead and what was behind. Most framework authors skip the "behind" section. Writing it forced me to see clearly: one practitioner, 28 projects, no institutional backing. That honesty made the archiving decision easy when the time came.

**Know when you're the user, not the author.** I was maintaining a framework for an audience. I should have been maintaining templates for myself. The difference is the overhead — landscape analysis, positioning, and versioning serve the audience. If the audience is 28 projects and one user, that overhead isn't justified.

## The uncomfortable truth about practitioner frameworks

The context engineering space has a glut of frameworks and a shortage of practitioners. There are more guides about structuring projects for AI agents than there are well-structured projects. I contributed to the glut.

The ideas that matter — the cliff, the triggers, the verification loop — didn't need a framework to carry them. They needed clear writing and a specific problem they solve. A blog post is a better vehicle than a versioned guide for ideas that fit in a few hundred words.

If you're maintaining a practitioner framework and the ecosystem has caught up: check whether you're the author or the user. If you're the user, keep the patterns, drop the packaging. Your time goes further on your actual projects than on maintaining a framework *about* projects.
