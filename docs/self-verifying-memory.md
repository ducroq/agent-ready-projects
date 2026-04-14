---
title: "Self-Verifying Memory"
subtitle: "Your agent remembers things that are no longer true. Here's how to fix that."
author: Jeroen Veen
date: 2026-04-14
status: draft
---

# Self-Verifying Memory

## The incident

A news aggregation site — ovr.news — was publishing articles with a broken processing pipeline. 230 articles were affected before anyone noticed. The root cause wasn't a code bug. It was a memory entry.

An agent had written "article processing pipeline: shipped and deployed" in its memory weeks earlier. Every subsequent session read that entry, trusted it, and moved on. The pipeline had been partially deployed — a staging artifact that never made it to production. But the memory said "shipped," so the agent treated it as shipped.

The memory was correct when written. It became false later. Nobody checked.

## The problem: recall is not truth

2026 brought a wave of memory systems for AI agents. MemMachine scores 0.9169 on LoCoMo. OMEGA hits 95.4% on LongMemEval. MemOS claims 72% token reduction through "skill memory." SimpleMem, Memori, Mem0, Letta — the field is crowded and the benchmarks are impressive.

They all measure the same thing: can the system retrieve what it stored? Recall accuracy.

None of them ask: is what was stored still true?

This is the gap. An agent writes "deployed to production" in memory. A month later, the deployment has been rolled back. The memory system faithfully retrieves "deployed to production" with high recall accuracy. The benchmark is satisfied. The fact is wrong.

Memory systems solve storage and retrieval. They don't solve trust.

## The fix: embed verification at write time

The idea is simple: when an agent writes a state claim in memory, it also writes the command that can verify it.

```markdown
### Article processing pipeline
Status: deployed to production
<!-- verify: curl -s https://ovr.news/api/health | jq '.pipeline_status' -->

Last checked: 2026-03-15
```

Three components:

1. **Write-time embedding.** When the agent records a state claim ("deployed," "migrated," "feature-flagged off"), it also records a verification command — a curl, a git check, a database query, whatever can prove the claim true or false.

2. **Read-time execution.** When the agent loads a memory entry that contains a verification command, it runs it. If the result contradicts the claim, the agent flags the discrepancy instead of trusting the stale entry.

3. **Curate-time audit.** During periodic curation (end of session, end of week), the agent runs all verification commands in memory. Entries that fail get flagged for update or retirement.

## What counts as a state claim

Not every memory entry needs verification. The distinction:

**Observations** are true by definition at the time they're written. "The API returns 422 when the slug field is empty" — this was observed, and the observation doesn't go stale in the same way. If the behavior changes, the gotcha log entry is still a valid historical record.

**State claims** assert something about the current state of the world. "Deployed to production." "Feature flag enabled." "Migration complete." These go stale. These need verification.

The heuristic: if the claim uses a past participle describing current state (shipped, deployed, migrated, configured, enabled, disabled), it's a state claim. Embed a verification command.

## The cost

Low. A `curl` to a health endpoint takes milliseconds. A `git log --oneline -1` is instant. The overhead is one command per state claim, executed on read.

The cost of *not* verifying is the ovr.news incident: 230 articles processed through a pipeline that wasn't actually running in production, caught only when a human happened to check.

## Why benchmarks miss this

LoCoMo and LongMemEval measure whether a memory system can retrieve what was stored. They don't test whether what was stored is still accurate. A system that perfectly retrieves a false memory scores as well as one that retrieves a true one.

This isn't a flaw in the benchmarks — they measure what they set out to measure. But it means high recall scores don't imply trustworthy memory. Recall accuracy and truth accuracy are different problems.

## The broader pattern

The "Externalization in LLM Agents" paper (Li et al., arXiv:2604.08224, April 2026) argues that agent capability is moving from model weights to externalized memory, skills, and protocols. As more capability lives in external state, the question "is this state still true?" becomes load-bearing.

Self-verifying memory is one answer to that question. Not the only possible answer — but the only one currently implemented anywhere, as far as we can tell.
