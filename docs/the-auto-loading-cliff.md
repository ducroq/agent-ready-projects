---
title: "The Auto-Loading Cliff"
subtitle: "The invisible line that determines whether your agent reads your docs or ignores them"
author: Jeroen Veen
date: 2026-04-14
status: draft
---

# The Auto-Loading Cliff

## Your docs are invisible

You wrote a beautiful RUNBOOK.md. Deployment steps, common errors, environment quirks — all documented. Your agent ignores it. Every session, it reinvents the deployment process from scratch and gets the same things wrong.

This isn't a bug. It's architecture.

Every AI coding agent has a hard line between files it reads automatically and files that might as well not exist. Claude Code auto-loads CLAUDE.md. Cursor reads .cursorrules. Copilot reads .agent.md. Gemini CLI reads AGENTS.md. Everything else — your runbook, your ADRs, your gotcha log — is below the cliff. Invisible until something explicitly tells the agent to read it.

"Linked prominently" is not a trigger. The agent skims past links the way you skim past sidebar ads.

## What crosses the cliff

The difference between a dead link and one agents actually follow is the trigger condition.

**This doesn't work:**

> See docs/RUNBOOK.md for deployment details.

The agent reads this, registers that a file exists, and moves on. There's no reason to load it *right now*.

**This works:**

> When changing deployment config, read docs/RUNBOOK.md first.

The agent matches the trigger to the current task. If it's touching deployment config, it loads the file. If not, it skips it — which is correct.

The pattern is **task-triggered pointers**: "when doing X, read Y." The trigger is a situation the agent recognizes, not a topic it might find interesting.

## The structural consequence

This means your project file (CLAUDE.md, AGENTS.md, whatever your tool calls it) is not a README. It's a **routing table**. Its job isn't to contain information — it's to route agents to the right information at the right time.

The implication for documentation design:

1. **Keep the project file short.** Every line competes for attention. ~100 lines is a practical ceiling. If you're over 200, the agent is skimming, not reading.
2. **Push detail below the cliff.** Operational procedures, historical context, architectural decisions — all belong in separate files. The project file points to them.
3. **Use task-triggered pointers, not descriptive links.** The "Before You Start" table in your project file should map tasks to docs, not topics to docs.

A project file that tries to contain everything becomes the thing the ETH Zurich study warned about: context that makes agents worse, not better (Gloaguen et al., arXiv:2602.11988). They found that LLM-generated context files *reduced* task success rates by 3% — agents followed unnecessary instructions and ran extra checks that made tasks harder.

The fix isn't less documentation. It's documentation in the right place, loaded at the right time.

## A practical example

A "Before You Start" table in a project file:

| When you're... | First read... |
|---|---|
| Changing deployment config | docs/RUNBOOK.md |
| Debugging API 422 errors | memory/api-quirks.md |
| Adding a new endpoint | docs/decisions/ADR-003-api-conventions.md |
| Seeing flaky tests | memory/gotcha-log.md |

Four lines. Four task-triggered pointers. The agent hits one of these situations, loads the right file, and has the context it needs. Everything else stays out of the way.

## The bigger picture

The auto-loading cliff is a consequence of how LLM context windows work: limited space, automatic injection of some files, manual loading of everything else. Every tool handles it slightly differently, but the cliff exists in all of them.

Once you see it, you stop writing documentation and start writing navigation. The question changes from "what should I document?" to "what does my agent need to find, and what trigger will make it look?"

That's a better question.
