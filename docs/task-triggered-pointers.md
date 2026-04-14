---
title: "Task-Triggered Pointers"
subtitle: "The one-line change that makes agents actually read your docs"
author: Jeroen Veen
date: 2026-04-14
status: draft
---

# Task-Triggered Pointers

## The pattern

You have docs your agent should read. You link them in your project file. The agent ignores them.

The fix is one word: **when**.

```diff
- See docs/RUNBOOK.md for deployment details.
+ When deploying, read docs/RUNBOOK.md first.
```

The first is a descriptive pointer — it tells the agent a file exists. The agent registers this the way you register a footnote: noted, not loaded.

The second is a task-triggered pointer — it gives the agent a condition to match against. If the agent is deploying (or about to deploy, or touching deployment config), the trigger fires. If not, the file stays unloaded. Both outcomes are correct.

## Why it works

LLMs are good at matching situations to instructions. "When X, do Y" is a pattern they handle reliably. "See X" is a suggestion they handle inconsistently.

The difference is relevance signaling. A descriptive pointer says "this exists." A task-triggered pointer says "this is relevant *now*, given what you're doing." The agent doesn't need to judge whether a file is worth loading — the trigger makes that judgment for it.

## The format

A "Before You Start" table in your project file:

| When you're... | First read... |
|---|---|
| Changing deployment config | docs/RUNBOOK.md |
| Debugging API errors | memory/api-quirks.md |
| Adding a new endpoint | docs/decisions/ADR-003-api-conventions.md |
| Touching the auth flow | memory/auth-gotchas.md |

Short. Scannable. Each row is a trigger-action pair.

This works because the agent reads the project file at session start, scans the table, and matches rows against the task at hand. It's a routing table, not a reading list.

## What makes a good trigger

Good triggers are **situations the agent recognizes**, not topics it might find interesting.

| Weak trigger | Strong trigger |
|---|---|
| "API documentation" | "When debugging 422 errors" |
| "Database info" | "When writing migrations" |
| "Testing guidelines" | "When tests fail on CI but pass locally" |

Weak triggers describe content. Strong triggers describe moments. The agent doesn't think "I should learn about APIs" — it thinks "I'm getting a 422, what do I do?"

## When to skip them

Not every file needs a task-triggered pointer. Files that are auto-loaded (your project file, your memory index) don't need triggers — they're always present. Files that are only relevant during periodic curation don't need triggers in the project file — the curate skill handles that.

Task-triggered pointers are for the gap: files that live below the auto-loading cliff and contain context the agent needs for specific tasks. If you're not sure whether a file needs a pointer, wait until an agent misses it. Then add the trigger.
