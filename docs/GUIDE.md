# The Complete Reference Guide

**Version 1.9.0** | [Back to README](../README.md) | [Changelog](../CHANGELOG.md)

This is the full reference for the agent-ready projects method. For a quick overview and getting started, see the [README](../README.md).

**A note on terminology.** This guide uses Claude Code conventions (CLAUDE.md, MEMORY.md) as concrete examples because that's where the patterns were developed and tested. The principles apply to any AI coding agent — see [Tool-Specific Setup](#tool-specific-setup) for how to map the concepts to your tool. To see what populated files look like in practice, see the [Worked Example](EXAMPLE.md).

---

<details>
<summary><strong>Table of contents</strong></summary>

- [The Core Problem](#the-core-problem)
- [The Foundation: Agent Empathy](#the-foundation-agent-empathy)
- [The Auto-Loading Cliff](#the-auto-loading-cliff)
- [The Layered Model](#the-layered-model)
  - [Layer 1: Identity + Operations (the project file)](#layer-1-identity--operations-the-project-file--always-present)
  - [Layer 2: Runbook](#layer-2-runbook-runbookmd--most-real-projects-need-this)
  - [Layer 3: Memory](#layer-3-memory-memory-index--topic-files--when-complexity-grows)
  - [Layer 4: History (gotcha log)](#layer-4-history-gotcha-logmd--always-present)
- [How Agents Self-Navigate](#how-agents-self-navigate)
- [Decision Records (ADRs)](#decision-records-adrs)
- [Session Hooks](#session-hooks)
- [The Documentation Rhythm](#the-documentation-rhythm)
- [The Self-Learning Loop](#the-self-learning-loop)
  - [Why this isn't "keep a log"](#why-this-isnt-keep-a-log)
  - [Why a hierarchy works](#why-a-hierarchy-works)
- [What Doesn't Work](#what-doesnt-work)
- [Measuring Success](#measuring-success)
- [Tool-Specific Setup](#tool-specific-setup)
  - [Multi-contributor projects](#multi-contributor-projects)
- [Contributing](#contributing-to-this-guide)

</details>

## The Core Problem

Agents can read code, but code doesn't capture *why* you made decisions, what you tried and abandoned, or what's fragile and shouldn't be touched. Without persistent context, every session starts from zero — agents re-investigate solved problems, undo intentional decisions, and build on stale assumptions.

The fix isn't more documentation. It's the **right** documentation, in the **right** place, with the **right** tone.

**What success looks like:** Agents find the right context without being told, avoid repeating past mistakes, and produce work that needs less rework each session. You stop explaining the same things. The system gets better over time, not just per-prompt. (Full metrics: [Measuring Success](#measuring-success).)

## The Foundation: Agent Empathy

Before the framework, the mindset. Every document you write for agents is a message to a capable colleague arriving on a Monday morning — smart, willing, but without your context. They can read code, but they can't read your mind.

This means:
- Write for orientation, not compliance. "Here's where things are" beats "follow these rules"
- Be honest about what's hard. "This looks wrong but it's intentional because X" saves more time than any style guide
- Frame gotchas as "if you see X, it's because Y" — actionable, not historical
- Treat agents as collaborators, not employees. The same values you bring to your product, extend to them

This isn't sentimentality. It's engineering pragmatism. An agent that understands *why* makes better autonomous decisions than one that only knows *what*.

## The Auto-Loading Cliff

Before the framework, the most important thing to understand: **there is a hard line between auto-loaded files and everything else.**

Every agent tool has files it auto-loads into context — for example, Claude Code injects CLAUDE.md and MEMORY.md into every conversation automatically. The agent sees them without doing anything. Every other file — no matter how prominently linked, no matter how useful — is invisible until the agent actively reads it.

This changes everything about how you structure documentation:

- **Content in auto-loaded files is always available.** Agents act on it from the first message.
- **Content below the cliff requires a trigger.** The agent must know *when* to read it and *what it contains* — before it's read it.
- **"Linked prominently" is not a trigger.** A pointer that says "see docs/RUNBOOK.md" gets skimmed past. A pointer that says "before changing the data pipeline, read docs/RUNBOOK.md for the validation gate" tells the agent *when* and *why*.

The bridge across the cliff is **task-triggered pointers** in auto-loaded files. Not just "this exists" but "when doing X, read Y first." The agent matches its current task against these triggers and self-navigates to the right file.

This is the single most practical insight in this guide: **auto-loaded files are indexes that help agents find what they need, exactly when they need it.** The self-learning loop (covered later) is the mechanism that moves lessons from session history into always-loaded context — the cliff determines *where* knowledge lives; the loop determines *how it gets there*.

**The asymmetry of wrong-layer placement.** When you're unsure which layer something belongs in, err toward keeping it in auto-loaded files. Content placed too high wastes context — agents see information they don't need, performance degrades gradually. Content placed too low is invisible — the agent doesn't know what it doesn't know, and fails silently. Ten extra lines in CLAUDE.md cost less than a missed constraint that was in a file the agent never loaded.

## The Layered Model

The model scales with project complexity. Not every project needs every layer.

### Layer 1: Identity + Operations (the project file) — always present

**Purpose**: "What is this project, what are the rules, and how do I work here?"
**Voice**: Welcoming — "here's what you need to know"
**Location**: Project root (checked into repo)
**Auto-loaded**: Yes
**Tool-specific names**: CLAUDE.md (Claude Code), AGENTS.md (Codex), `.cursor/rules/*.mdc` (Cursor), `.windsurfrules` (Windsurf) — see [Tool-Specific Setup](#tool-specific-setup)

This is the project's home base. It's the only file guaranteed to be read every session, so it carries the most weight. For small-to-medium projects, it contains *everything* an agent needs to start working — identity, constraints, architecture, and operational how-to.

**Always include:**
- Project overview (3-5 lines: what this is, who it's for, what it does)
- Hard constraints and principles (the non-negotiables). Negative constraints ("never remove output fields that downstream apps depend on", "never use external APIs for PII (personally identifiable information)") often land harder than positive ones — they draw a bright line agents won't cross, while positive guidance leaves room for interpretation. Include honesty constraints too — agents confabulate. "Never claim tests pass without running them" and "never claim a file exists without reading it" prevent the most common form of agent failure: confidently asserting something that isn't true.
- Decision framework — how agents should evaluate their own output (e.g., a simple PASS/REVIEW/FAIL rubric: what meets the bar, what needs a second look, what blocks progress). Without this, agents optimize for whatever seems reasonable. With it, they self-assess against your standards.
- Architecture sketch (how the pieces fit together)
- **"Before You Start"** table with task-triggered pointers to deeper docs
- Key directories and file paths
- How to make changes (test commands, deployment steps, commit conventions)

**Brand-forward projects.** If your project generates user-facing content — a platform, a consumer product, an educational tool — brand identity belongs in Layer 1 alongside technical identity. Tone guidelines, anti-patterns ("never use clickbait phrasing"), and what success feels like to the end user are not decoration. They prevent agents from producing technically correct output that violates the product's character. If agents write text users will read, brand guardrails must be auto-loaded.

**The "Before You Start" table** is the bridge across the auto-loading cliff. It maps task types to files:

```markdown
## Before You Start

| When | Read |
|------|------|
| Making architectural decisions | `docs/adr/README.md` — index of 17 ADRs |
| Debugging or investigating failures | `memory/investigation-log.md` — dead ends, what worked |
| Touching PII or sensitive data | `memory/privacy-protocol.md` — never-do list |
| Stuck on infra or tooling | `memory/gotcha-log.md` — problem-fix archive |
```

The trigger column matters. "ADR index" is a label — an agent skims past it. "Making architectural decisions" is a task the agent recognizes itself doing. If the table exceeds ~8 rows, group related docs into task categories: "Adding or changing sources → CONFIGURATION.md, SOURCE_QUALITY.md" as a single row.

**Context budget, not line count.** The goal isn't "keep files under N lines" — it's to maximize orientation quality while minimizing what agents pay for every session. Auto-loaded content is loaded whether the agent needs it or not. A 80-line file full of task-triggered pointers can outperform a 200-line file packed with details that apply 10% of the time. But a well-structured 200-line file that's the single authoritative source is better than a 100-line file that punts essentials below the cliff. The signal to split isn't hitting a line count — it's agents missing important constraints because they're buried in operational detail. Projects that adopted progressive disclosure — loading context on demand via task-triggered pointers rather than front-loading everything — measured 60-80% reduction in session-start token usage.

When making trade-offs about what to include, prioritize **correctness over completeness over size**. Wrong context (outdated facts, stale paths) is worse than missing context — agents will confidently act on incorrect information. Missing context is worse than noisy context — agents can filter noise, but they can't find what isn't there. All three matter, but in that order.

### Layer 2: Runbook (RUNBOOK.md) — most real projects need this

**Purpose**: "How do we operate here?"
**Voice**: Normative but warm — "we do X because Y"
**Location**: `docs/` directory (checked into repo)
**Auto-loaded**: No — triggered via "Before You Start" in the project file

Any project with deployment infrastructure, multiple subsystems, and operational principles will outgrow a single project file. That's normal, not a failure. When it happens, extract the operational how-to into `docs/RUNBOOK.md` — but keep the most critical commands (test suite, deploy) in the project file as a summary so agents can act without a second read.

Simple projects with a single test command and no deployment can skip this. But most real projects need it.

The runbook combines two things that are weaker apart:

**Hard constraints** stay in the project file (auto-loaded, always visible). **Operational principles** go in the runbook — guidelines that expand on *how* to apply those constraints:
- Opinionated: "Pipeline reliability matters more than feature richness"
- Actionable: "When in doubt, let articles through — the model handles nuance"
- Non-obvious: "Adding output fields is safe. Removing them breaks downstream apps"

Bad principles are vague ("write good code"), redundant with what's obvious ("test your code"), or aspirational without being actionable ("we value quality").

**Operational how-to**:
- How to run things locally
- How to deploy
- How to add a new [whatever your project's main extension point is]
- How to debug common problems
- Documentation practices (what goes where, when to update)

Why combine principles and how-to? Because principles without a runbook are too abstract — agents nod and then ignore them. A runbook without principles is mechanical — agents follow steps but make bad judgment calls when they hit something unexpected. Together, they tell the agent both *what matters* and *what to do*.

*On naming: "runbook" implies operational how-to, but this file also carries principles. Some teams prefer CONTRIBUTING.md, WAY-OF-WORKING.md, or OPERATIONS.md. The name matters less than the structure — pick what fits your culture.*

### Layer 3: Memory (memory index → topic files) — when complexity grows

**Purpose**: "What have we learned working on this?"
**Voice**: Declarative — "X works like Y", "if you see A, it's because B"
**Location**: In-repo `memory/` directory (see [ADR-001](decisions/ADR-001-in-repo-memory-over-auto-memory.md) for rationale)
**Auto-loaded**: The memory index is auto-loaded if your tool supports it. Topic files are not — they're loaded on demand via task-triggered pointers.

**Important**: Some tools enforce hard limits on auto-loaded files (e.g., Claude Code truncates MEMORY.md after ~200 lines — content past the limit silently vanishes). Check your tool's limits. Regardless of the specific threshold, the index-not-dump pattern isn't just good practice — keeping auto-loaded files lean is forced by context economics. Beyond a certain project size, topic files are non-optional.

This is institutional memory — the hard-won operational knowledge that isn't obvious from reading the code.

**The critical evolution: memory index as index, not dump.**

A flat memory index works for simple projects. Once you have 5+ subsystems, it becomes a wall of text that agents skim past. The fix:

```
memory/
├── MEMORY.md           # 60-80 line index + current state
├── api-quirks.md       # API patterns, third-party behaviors
├── infrastructure.md   # Servers, deployment, environments
├── auth-patterns.md    # Subsystem-specific knowledge
└── gotcha-log.md       # Structured problem/solution archive
```

**The memory index** contains:
- A brief orientation ("Loaded every session. Topic files loaded on demand.")
- A **topic index table** — the second bridge across the auto-loading cliff:

```markdown
| File | When to load | Key insight |
|------|-------------|-------------|
| `memory/investigation-log.md` | Debugging or investigating failures | Dead ends, what worked and why |
| `memory/privacy-protocol.md` | Touching PII or sensitive data | Never-do list, script design pattern |
| `memory/gotcha-log.md` | Stuck on infra or tooling | Problem-fix archive |
```

- Current project state (what's shipped, what's blocked)
- Key file paths (the top 10-15 files an agent needs to know about)
- Active architecture decisions (one-liners pointing to ADRs)

The topic index works the same way as the project file's "Before You Start" — task-triggered pointers that tell agents *when* to load each file. An agent debugging an infra issue sees "stuck on infra or tooling → gotcha-log.md" and loads it. No prompting needed.

**Topic files** contain deep subsystem knowledge. Agents load the relevant one when working on that subsystem. An agent fixing a frontend bug doesn't need to know about the database migration strategy.

This is **progressive disclosure** — start broad, go deep only where needed. It keeps the always-loaded context lean while making deep knowledge one `Read` away.

**Feature-level context.** For complex features that span multiple sessions, consider a context file per feature — implementation knowledge, test strategy, patterns discovered, approaches tried and abandoned. This is progressive disclosure applied at the feature level: the project-level docs tell agents *about* the project, the feature-level doc tells them *about this specific piece of work*. Not every feature needs one, but any feature that takes more than two sessions will benefit.

**What goes in memory files**:
- Current-state facts ("the pipeline processes 3 filters independently")
- Patterns ("this API silently truncates responses over 4MB — paginate instead of increasing limits")
- Gotchas framed as "if X, then Y" ("if file uploads fail silently, check the auth token hasn't expired")
- API signatures and parameter quirks
- Server/deployment facts

#### Self-verifying memory

A session observation ("I called the endpoint and it returned 200") is not the same as deployed state ("this endpoint is in the persisted codebase and survives restarts"). Memory entries that say "shipped," "deployed," or "working in production" carry implicit trust — future agents will skip verification and build on that claim. The cost of a false "shipped" memory is high: it silently suppresses investigation for as long as the memory persists. In one case ([issue #8](https://github.com/ducroq/agent-ready-projects/issues/8)), an agent recorded "ML classifier shipped" after a session test. The endpoint only existed in the running process — after a restart it returned 404, silently failing for 230 articles until a human noticed.

The fix is **self-verifying memory** — verification commands that travel with the claim, executed by the agent, invisible to the user. Three touchpoints:

1. **On write**: When recording a state claim, embed a verification command as an HTML comment:
   ```markdown
   The ML classifier endpoint is deployed on gpu-server.
   <!-- verify: curl -s https://api.example.com/classify/logo -d '{"url":"test"}' | grep -q '"label"' && echo PASS || echo FAIL -->
   ```
2. **On read**: Before trusting a memory entry with a verify comment, run the command. If it fails, treat the entry as stale — flag it, don't build on it.
3. **On curate**: The `/curate` skill scans for state claims, runs embedded verify commands, and reports pass/fail. Entries without a verify comment are flagged as unverified.

Not every memory entry needs this. Agents can infer the claim type from language:

| Claim type | Trigger words | Agent action |
|---|---|---|
| **State** | "shipped," "deployed," "live," "running" | Embed `<!-- verify: command -->` |
| **Observation** | "during session," "tested," "responded" | Qualify with session context, no verify needed |
| **Decision** | "chose," "decided," "because" | Stable unless reversed — no verify needed |
| **Pattern** | "always," "never," "when X do Y" | Include repro command if useful, no verify needed |

If a verification command cannot be written (e.g., requires credentials the agent doesn't have), note that explicitly: `<!-- verify: manual — requires production SSH access -->`. The curate skill will flag these for human attention.

This is lightweight by design. No frontmatter schema, no mandatory fields. The verification comment is a convention that agents follow because the guide tells them to. The user never sees the ceremony — the agent handles it on write, read, and curate.

**What stays out**:
- Instructions ("run X to do Y") — that's CLAUDE.md or the runbook
- Chronological narrative ("on Feb 13 we changed X") — that's the gotcha log
- Principles — that's CLAUDE.md or the runbook

**In-repo memory vs auto-memory.** Memory files should live in-repo by default — in a `memory/` directory that is visible in your editor, version-controlled with git, and reviewable by humans and agents alike. This was a deliberate decision after experiencing the problems with hidden auto-memory across 28 projects (see [ADR-001](decisions/ADR-001-in-repo-memory-over-auto-memory.md)).

| In-repo memory (default) | Auto-memory (exception) |
|--------------------------|------------------------|
| Gotcha logs, topic files, project state | Content you would never commit (personal notes, credential hints) |
| Visible in editor, searchable, reviewable | Hidden, user-specific, not version controlled |
| Survives repo moves and renames | Tied to filesystem path at creation time |
| Supports the self-learning loop (you see what's there) | Easy to forget, hard to curate |

The dividing line: **commit by default**. Use auto-memory only for content you would never put in a repository. In practice, this is rare — nearly all memory benefits from human review.

**Cross-project knowledge.** For related projects (a pipeline feeding a downstream app, a monorepo with shared services), cross-project facts need a home. Project-level memory topic files handle cross-project facts *this* project's agent needs — e.g., "the upstream API repo uses branch `main` not `master`" in the downstream consumer's memory file. The principle: store the fact where it's *needed*, not where it *originates*. Each repo's project file names the relationship and owns its side; neither duplicates the other's internals.

**The global file cliff.** Most tools support a global instructions file (e.g., `~/.claude/CLAUDE.md` in Claude Code) that loads in every project. This file has its own auto-loading cliff — content placed here burns context tokens in every session across every repo. Keep it lean: user preferences, cross-project infrastructure (shared server access), universal behavioral instructions. Project-specific content — even if used by several projects — belongs in those projects' files. Loading a 30-row voice library table in a hardware verification project is the global version of the 500-line README that nobody reads. Duplication across two repos is cheaper than irrelevant context in thirty.

### Layer 4: History (gotcha-log.md) — always present

**Purpose**: "What went wrong before and how was it fixed?"
**Voice**: Narrative — "Problem → Root cause → Fix"
**Location**: `memory/` directory (in-repo, alongside other memory files)
**Auto-loaded**: No (loaded when stuck, via the project file's or memory index's trigger)
**Growth**: Unlimited (append-only)

Pure session logs — "today we did X, then Y" — are useless. But a **structured problem/solution journal** is invaluable:

```markdown
### Deploy fails silently above asset threshold (2026-02-27)
**Problem**: CI passed but deploy produced no errors and no output.
**Root cause**: Each record generates 3 static files. At 7K records the total exceeded the hosting platform's file limit.
**Fix**: Implemented hot/cold archiving (ADR-022). Build step now validates asset count before deploy.
```

This isn't daily reading. It's a searchable archive. When an agent (or you) hits something weird, searching the gotcha log often reveals it's been solved before.

**Dead ends belong here too.** The gotcha log captures operational problems, but also document *design approaches you tried and rejected* — "we tried a comprehensive 34-test suite, it was over-engineered for the goal, pivoted to 5 focused tests." Without this, agents will re-propose solutions you've already explored and abandoned. ADRs capture what you *chose*; the gotcha log captures what you *tried and walked away from*.

**The promotion pattern**: When a gotcha keeps coming up, promote it:
- From gotcha log → relevant topic file (as an "if X, then Y" pattern)
- From topic file → memory index or project file (if it's truly universal)

A concrete example: "staging migration fails with timeout" appears in the gotcha log. After it comes up in three sessions, it gets promoted to `infrastructure.md` as "if staging migrations time out, run them with `--lock-timeout=60s` — the shared database has long-running queries." After it affects deployments, data backfills, and test setup, it gets promoted to the memory index as a universal gotcha.

**The retirement pattern**: Promotion moves lessons upward. Retirement moves them out. At end-of-session curation, the agent flags candidates for retirement — you review and confirm:
- Gotchas whose root cause is fixed → mark resolved in the log (don't delete — it's history)
- Topic file entries describing behavior that was refactored away → remove
- Memory index entries fully encoded in the project file or in the code itself → remove from memory, they've reached their permanent home
- Monthly: the agent audits all memory files and proposes a batch of retirements. Pruning should keep pace with growth.

This keeps the gotcha log as a complete record while surfacing the most important lessons into always-loaded context.

## How Agents Self-Navigate

The auto-loaded files work together as a navigation system. Here's how it looks in Claude Code (other tools have equivalent structures — see [Tool-Specific Setup](#tool-specific-setup)):

```
Project file (auto-loaded)
├── "Before You Start" table → task-triggered pointers to repo docs
│   ├── docs/RUNBOOK.md (when needed)
│   ├── docs/adr/README.md → individual ADRs
│   └── other deep docs
│
Memory index (auto-loaded, if tool supports it)
├── Topic index table → task-triggered pointers to memory files
│   ├── gotcha-log.md
│   ├── investigation-log.md
│   └── other topic files
└── Current state, file paths, active decisions
```

The agent reads both auto-loaded files at session start. When it begins a task, it matches the task against the trigger descriptions and loads the relevant on-demand files. No human intervention required.

This is why the trigger descriptions matter so much. "Investigation log" is vague. "Debugging or investigating failures → dead ends, what worked and why" tells the agent exactly when this file is relevant and what it contains.

**The documentation vector**: Every time you update docs — whether adding content, reorganizing, or trimming — the question isn't "is this accurate?" It's "will a future agent find the right context without being told to look?" Accuracy is table stakes. Self-navigation is the goal. If you find yourself saying "go read X first" in a session, that's a signal that your auto-loaded pointers are missing a trigger.

## Decision Records (ADRs)

Architecture Decision Records are a companion practice to the layered model.

When you choose between approaches, write a short ADR:
- **Context**: Why we faced this choice
- **Decision**: What we chose
- **Consequences**: What follows (positive and negative)
- **Alternatives**: What else we considered and why we rejected it

ADRs prevent agents from re-debating settled questions. The most common agent failure isn't writing bad code — it's proposing a redesign of something that was intentionally designed.

**Critical**: Maintain an ADR index (one-line summaries with links). Agents need to scan for relevant precedent quickly. 20+ individual files without an index is a maze. Point to it from the project file's "Before You Start" table.

## Session Hooks

Most agent tools support hooks — commands that run automatically when a session starts. Use them to show the agent the current state:

```
[pipeline] Latest: 2026-02-28 18:01 - SUCCESS, 6524 articles scored
[filters] Active: sustainability_technology v3, uplifting v6, ...
[git] Recent: 10d098f Rewrite README.md
```

This gives immediate orientation without reading files. It's the difference between walking into an office and seeing the dashboards vs. having to dig through reports. (If your project's runtime state lives on a remote server, consider whether the hook latency is worth the orientation benefit. A cached status file updated by CI/CD may be better than a live SSH call on every session start.)

**Session strategy.** Don't review work in the same session that produced it. An agent that just spent 30 minutes building something has sunk-cost bias baked into its context — it's unlikely to catch its own mistakes. Use a fresh session for review, or a different model entirely. The same applies to any validation task: testing, security review, QA. The agent that built it is the worst one to judge it.

The same principle applies to research and exploration. Offload search, grep, and codebase exploration to subagents or separate sessions so your main working context stays focused on the task. Every search result and file read that isn't directly relevant dilutes the context the agent is working in. Keep the building session clean; do the research elsewhere.

## The Documentation Rhythm

The biggest shift in practice: **capture during work, curate at end-of-session.**

| When | Action | Where |
|------|--------|-------|
| **During work** | Hit a gotcha? Log it immediately (2-3 lines) | `gotcha-log.md` |
| **During work** | Learned something non-obvious? Note it | Relevant topic file |
| **After a decision** | Chose between approaches? | ADR + update index |
| **Changed operations** | Process or infrastructure changed? | Project file or RUNBOOK.md |
| **End of session** | Ask the agent to curate: correlate, summarize, prune, promote, doc sync (review its proposals) | Memory index + topic files + project file (1-2 min) |
| **Monthly** | Agent audits all memory files: flags resolved items, stale entries, facts now encoded in code. You review and confirm retirements. | All memory files |

**Course-correcting.** When you realize the direction is wrong mid-session — requirements changed, an assumption broke, the approach isn't working — pause and tell the agent to reassess. Have it evaluate what's affected and propose updates to the project file, ADRs, and task list. Review the proposals, then continue. Agents won't initiate course-correction on their own — they'll keep building on a broken foundation — but they can handle the doc updates once you steer them. The discipline is in recognizing the moment to pause; the agent handles the paperwork.

The key shift: end-of-session time becomes **1-2 minutes of review**, not 20 minutes of writing from recall. The agent does the heavy lifting — reading across files, spotting patterns, drafting consolidations — and you approve or adjust.

**Automating the rhythm.** For Claude Code, install the [`curate.md`](../templates/curate.md) template as `.claude/skills/curate/SKILL.md` (with frontmatter — see template comments) — this gives you a `/curate` skill that automates the end-of-session curation (gotcha review, pattern promotion, memory index update). For other tools, paste the curate template as an end-of-session prompt. Either way, the agent does the heavy lifting and you review its proposals.

**Structural audits.** Install [`audit-context.md`](../templates/audit-context.md) as `.claude/skills/audit-context/SKILL.md` for a `/audit-context` skill that checks framework-level health: document size, cross-layer duplication, wrong-layer placement, reference integrity, topic file reachability, and gitignore correctness. Run monthly or after major restructuring — it catches structural decay that session-level curation misses.

These practices form a single cycle — the **self-learning loop**.

## The Self-Learning Loop

The rhythm above has four phases: **Capture → Surface → Promote → Retire.**

```
    ┌─────────┐
    │ CAPTURE │  During work: gotcha-log, topic files, ADRs
    └────┬────┘
         │
         ▼
    ┌─────────┐
    │ SURFACE │  End-of-session: review, tag patterns, connect dots
    └────┬────┘
         │
         ▼
    ┌─────────┐
    │ PROMOTE │  Recurring lessons move up: gotcha → topic file → memory index → project file
    └────┬────┘
         │
         ▼
    ┌─────────┐
    │ RETIRE  │  Fixed, refactored, or encoded in code? Remove from memory
    └────┬────┘
         │
         └──────→ (back to CAPTURE — the cycle continues)
```

This loop applies to all tools. File names vary (CLAUDE.md vs AGENTS.md vs `.windsurfrules`), but the progression Capture → Surface → Promote → Retire is universal.

**Capture.** During work, you log gotchas as they happen (2-3 lines), note non-obvious learnings in topic files, and write ADRs when choosing between approaches. This is the raw material — cheap to create in the moment, expensive to reconstruct later. (Details: [The Documentation Rhythm](#the-documentation-rhythm), [Layer 4: History](#layer-4-history-gotcha-logmd--always-present).)

**Surface.** At end-of-session, ask the agent to review what was captured. The agent reads across topic files and the gotcha log, then proposes changes. You review and approve — 1-2 minutes, not 5. The agent handles three tasks:

1. **Correlate**: Find entries across different files that stem from the same underlying pattern. A deployment gotcha and an infrastructure gotcha might both be symptoms of the same constraint. The agent links them or merges them into a single entry that captures the real cause.
2. **Summarize**: Consolidate entries that say the same thing into higher-level norms. Five separate gotchas about API timeouts distill to: *"this provider's API is unreliable under load — always use retry with backoff."* The individual entries are evidence; the summary is the lesson.
3. **Prune**: Flag stale entries for removal. Identify lessons that have outgrown their subsystem and are candidates for promotion.

This works because the agent has full session context — it knows what was touched, what failed, and what was learned. Correlation and summarization across files is tedious for humans but natural for agents. The human's role shifts from analyst to reviewer: approve the consolidation, reject a bad summary, add nuance the agent missed.

The goal is to continuously refine raw observations into durable norms — not just accumulate entries. A well-maintained topic file with 10 synthesized patterns is worth more than 40 individual gotchas. (Details: [The Documentation Rhythm](#the-documentation-rhythm).)

**Promote.** When a lesson proves its value through repetition, move it up the stack. A gotcha that recurs in three sessions becomes an "if X, then Y" entry in the relevant topic file. A topic file pattern that affects multiple subsystems moves to the memory index. A memory index entry that's truly universal — a hard constraint every session needs — graduates to the project file. Each promotion moves the lesson closer to always-loaded context, where agents act on it without being told. (Details: [The promotion pattern](#layer-4-history-gotcha-logmd--always-present).)

**Retire.** When a gotcha's root cause is fixed, mark it resolved. When a topic file entry describes behavior that was refactored away, remove it. When a memory index entry is fully encoded in the project file or in the code itself, remove it — it's reached its permanent home. Monthly audits should prune as much as they add. (Details: [The retirement pattern](#layer-4-history-gotcha-logmd--always-present).)

### A gotcha's full lifecycle

Here's a concrete example of one lesson traveling through the entire loop:

1. **Capture** — Session 4: Staging database migrations time out intermittently. Logged in `gotcha-log.md`.
2. **Surface** — End of session 4: Agent reviewed the gotcha log, noted only one occurrence. Left in place.
3. **Surface** — End of session 7: Agent flagged the same gotcha as recurring and proposed promoting it.
4. **Promote** — Session 8 curation: Promoted to `infrastructure.md` as: *"if staging migrations time out, run with `--lock-timeout=60s` — shared database has long-running queries."*
5. **Promote** — Session 15: Pattern affected deployments, data backfills, and test setup. Promoted to the memory index as a universal gotcha.
6. **Retire** — Session 22: Database moved to a dedicated staging instance. Timeout issue resolved. Removed from memory index, marked resolved in gotcha-log.

Total effort: ~2 minutes across 6 sessions. The lesson was available at the right level of visibility for each phase of its life.

### Self-learning agents

The self-learning loop applies to agents themselves, not just project documentation. When you create **review agents** — instruction documents that tell an agent how to systematically review an artifact (code, rubrics, designs, assessments) — you can make the agent surface its own blind spots.

The pattern is simple. A review agent defines **issue categories** (typed findings with severity levels) and a **review procedure** (step-by-step checks). After completing a review, the agent runs a **self-check**:

> "Did I flag any issue that does NOT fit cleanly into one of my defined issue categories? Did I notice a recurring pattern that isn't captured as a named check?"

If so, the agent reports the new pattern and **asks the user** whether to add it to the agent's issue categories. This closes the loop: agents that review artifacts improve their own review capability over time.

```
    Review agent runs          Agent finds issue X
         │                          │
         ▼                          ▼
    Produces report ──────► Self-check: is X in my categories?
                                    │
                           ┌────────┴────────┐
                           │ Yes             │ No
                           │ (normal)        │ (new pattern)
                           ▼                 ▼
                        Report only    Ask user: "Add to my
                                       issue categories?"
                                             │
                                        ┌────┴────┐
                                        │ Yes    │ No
                                        ▼        ▼
                                   Update agent  Note it
                                   definition    for later
```

A reusable template for building review agents is available in [`templates/review-agent.md`](../templates/review-agent.md). It includes the self-check step and works for any domain — code review, rubric design, paper review, assessment audit, or anything else that benefits from structured, repeatable review.

### Negative results are knowledge

Most teams only document what worked. But for agents, knowing what *didn't* work — and why — is equally valuable. Without it, a future agent will retry the same failed approach, waste time, and reach the same dead end.

When an experiment fails, document it in the gotcha log or a topic file with three things: **what you tried**, **quantified results**, and **why it failed**. This turns a dead end into a guardrail.

> *Example: [vmodel.eu](https://github.com/ducroq/vmodel.eu) tried using LLM findings counts to adjust deterministic scores. A 3-hour calibration run across 64 held-out reports showed the adjustment hurt more than it helped (within-1 accuracy dropped from 96% to 92%). Root cause: reports with few LLM findings aren't necessarily good — short text gives the LLM less to criticize, mimicking a "clean bill of health." Documented in `memory/calibration-history.md` with full data. No future agent will retry this approach.*

The self-learning loop already handles this — negative results enter through Capture (gotcha log), get promoted when they prove durable (topic file), and prevent wasted effort in future sessions. The key habit is treating "this doesn't work" as a first-class finding, not a failed experiment to forget.

### Why this isn't "keep a log"

The difference between this and a flat annotation system is the **migration**. Annotation-style approaches (sticky notes on code, inline comments, context-hub-style tagging) keep lessons pinned where they were learned. They're useful but static — a note on file X stays on file X forever, whether it's still relevant or not, whether it applies to file Y too, or whether it's become a project-wide constraint.

The self-learning loop is a **knowledge lifecycle**. Lessons start cheap and local (gotcha log), prove their value through repetition, and migrate toward always-loaded context as they earn it. The most important lessons end up in the project file — loaded every session, acting on every task. The rest stay where they're useful or get retired when they're not. Nothing stays a sticky note forever.

### Why a hierarchy works

The layered model isn't an accident — it mirrors how processor memory hierarchies have solved the same problem for decades. A CPU doesn't store everything in registers. It keeps the hottest data closest (registers, L1 cache), medium-frequency data one step away (L2/L3), and the full record on disk. The same economics apply to agent context:

```
Processor              Agent context             Shared property
─────────              ─────────────             ───────────────
Registers              Project file              Always loaded, tiny, highest cost per bit
L1 cache               Memory index              Auto-loaded, small, fast access
L2/L3 cache            Topic files               Loaded on demand, one read away
RAM                    Gotcha log, ADRs          Searched when needed, larger
Disk                   Git history               Archive, rarely accessed, complete
```

Three principles from processor design that sharpen how we manage agent context:

**Miss cost asymmetry.** A lesson missing from the project file just means the agent checks the memory index — one extra read. But a lesson missing from *all* layers means the agent rediscovers it from scratch: reading code, hitting the bug, debugging it again, at full session cost. This is why promotion matters — frequently-needed knowledge living too deep in the stack has a "miss penalty" every session.

**Eviction discipline.** If an entry hasn't been relevant in the last N sessions, it's a demotion candidate. If a constraint in the project file has never actually prevented a mistake, it's taking space in the hottest layer without earning its keep. The goal isn't a smaller file — it's a file where everything pulls its weight.

**Locality of reference.** If an agent needs one fact about the API layer, it probably needs related API facts too — this is why topic files should be organized by task domain, not by date. And task-triggered pointers are prefetch hints: "you're working in this area, so here's the bundle of context you'll need."

**Is the loop turning?** The clearest signal: gotcha log entries get promoted regularly and the same problem rarely appears three times. If the log only grows but nothing moves up, capture is happening without curation — the loop is stalled. See [Measuring Success](#measuring-success) for the full diagnostic.

## What Doesn't Work

### Flat memory files
A single memory index that grows to hundreds of lines of mixed concerns. An agent looking for "why is my API call failing" has to wade through unrelated subsystem details. Split into topic files and use the memory index as a lean pointer file. (Some tools enforce hard limits — e.g., Claude Code truncates after ~200 lines — but even without a hard limit, bloated auto-loaded files waste context budget every session.)

### Duplicating content across docs
The same fact stated identically in two places will drift — one gets updated, the other doesn't. This applies to code-to-doc copies (API specs pasted into markdown) and doc-to-doc overlap (README, CLAUDE.md, and RUNBOOK.md all describing the same architecture).

However, the same fact **framed differently for different purposes** can be valuable: a constraint ("never use external APIs for PII") in CLAUDE.md and an operational reminder ("when adding a new model provider, verify it's EU-hosted") in the runbook serve different cognitive moments. The test: if you removed one copy, would agents reliably find the other at the moment they need it? If not, the duplication is justified — but one copy should be canonical, and the other should defer to it.

The drift risk of duplicated facts is proportional to how often the fact changes and how similar the framings are. A stable architectural fact (like a pipeline order) referenced in different contexts is low risk. A configuration rule restated with slightly different wording in two docs is high risk — the framings will diverge within a few sessions.

**The ground truth principle.** When multiple artifacts describe the same thing (a spec, a rubric, a schema), designate one as canonical and align the others to it. An educational assessment project found that a Word template, markdown rubric, Excel scoring sheet, and agent prompt all described the same scoring criteria — and had already diverged in three places within weeks. The fix: declare the student-facing template as ground truth, align all instruments to it, and never edit a downstream artifact without checking the source. This generalizes to any domain: API spec vs. generated docs, design system vs. component code, schema vs. migration files.

**The three-document pattern.** For any structured evaluation (scoring, review, assessment), separate the **instructions** (how to evaluate), the **criteria** (how to score), and the **output template** (what the result looks like) into three files. Embedding criteria inside the instructions creates a monolithic document that resists updates — changing one score descriptor requires editing the instruction prompt. Tested on a 651-line assessment prompt that was refactored into three ~150-line files; the criteria immediately stopped drifting from the external rubric because there was only one copy.

### Metadata that duplicates derivable facts
Config-level metadata like `total_sources: 103` / `enabled_sources: 77` in YAML files seems helpful but is never read by code and drifts every time you add or disable a source. If a fact is derivable from the data itself, don't maintain a separate count — it will be wrong within a week.

### Over-documenting
More docs ≠ better agent performance. Every line of context competes for attention. An agent with 150 lines of precise context outperforms one with 2,000 lines of comprehensive-but-noisy context.

### Prominent links without triggers
A "Before You Start" section that lists files without saying when to read them. "See docs/RUNBOOK.md" gets skimmed past. "Before changing prompts, read docs/RUNBOOK.md — it has the calibration gate" gets acted on. The trigger is the difference between a pointer and a dead link.

### Principles without a runbook
A constitution that says "we value simplicity" without showing how to run the dev server or add a feature. Agents acknowledge the principle and then ignore it because they don't have the operational context to apply it.

### Skipping the constitution entirely
It feels like overhead until an agent makes a decision that violates a principle you thought was obvious. "Don't remove output fields that downstream apps depend on" seems obvious to you. It's not obvious to an agent optimizing for clean code.

### Files with implicit runtime semantics
Agents sometimes create documentation files in formats that tooling interprets at runtime. A review agent recommends adding a `wrangler.toml` "for reference" — but Cloudflare Pages reads it at build time, overriding dashboard settings and breaking every deploy. A `docker-compose.override.yml` added "as documentation" gets picked up by `docker compose up`. A `.npmrc` created to "document registry settings" changes where packages install from.

The pattern: agents see a knowledge gap (infrastructure settings aren't documented) and fill it with a file whose format matches the domain — a reasonable instinct that ignores how build tools discover config files. The fix isn't "don't create files" but "document infrastructure in plain markdown, not in config formats that tools auto-discover." Hard constraints like "never add a wrangler.toml to this repo" belong in the project file.

### Pure session logs
"Today we did X, then Y, then Z" grows without bound and buries signal. But don't go to the other extreme — a structured gotcha log (Problem → Root cause → Fix) is genuinely useful. The distinction: journals of activity are noise; journals of problems and solutions are knowledge.

## Measuring Success

You know the system is working when:
- New sessions start productive within the first exchange
- Agents don't re-investigate solved problems or undo intentional decisions
- Agents load the right on-demand files without being told
- Gotcha log entries get promoted regularly — the self-learning loop is turning

You know it's failing when:
- You're explaining the same thing every session
- You keep saying "go read X first"
- Your project file or memory index is over 150 lines of mixed concerns
- Same problem appears 3+ times without being promoted

**Common fixes:**

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Agent ignores a constraint | Constraint is buried in a non-auto-loaded file, or phrased too softly | Move it to the project file. Use "never" / "always" language with a concrete example |
| Agent doesn't load the right file | Missing or vague trigger in the "Before You Start" table | Add a task-triggered pointer: "when doing X, read Y" — not just "see Y" |
| Agent re-investigates solved problems | No gotcha log, or gotcha log isn't referenced from auto-loaded files | Create the log and add a trigger: "stuck or debugging → gotcha-log.md" |
| Context feels stale | End-of-session curation is being skipped | Ask the agent to curate before wrapping up. 1-2 minutes, not optional |
| Project file is a wall of text | Everything was put in Layer 1 instead of using progressive disclosure | Extract operational detail to a runbook, split memory into topic files |

**Validating, not just trusting.** Good documentation doesn't guarantee good behavior. Agents can read your constraints and still cut corners when they're confident, ignore warnings when they've invested effort in an approach, or defer to your suggestions even when those suggestions violate the project's own principles. Occasionally test this: ask the agent to do something that should trigger a constraint, or apply time pressure and see if quality holds. If your docs say "never skip tests" but the agent skips them when the task feels urgent, the constraint isn't landing — it may need stronger framing or a concrete example of what "never" means.

**Parallel specialized review.** After adopting the framework or making significant changes, run multiple agents in parallel — each focused on a different concern (doc quality, consistency, traceability, completeness). In practice, 5-6 parallel reviewers surface cross-cutting issues in minutes that single-pass review misses: broken cross-references, stale metadata, traceability gaps. See [METHODOLOGY.md](METHODOLOGY.md) for details.

## Tool-Specific Setup

This guide's concepts map to every major AI coding agent. The file names and mechanisms differ, but the principles — auto-loaded context, task-triggered pointers, layered documentation — are universal.

### Concept mapping

| This guide says | Claude Code | Codex (OpenAI) | Cursor | Windsurf | GitHub Copilot | Aider |
|----------------|------------|----------------|--------|----------|----------------|-------|
| "Project file" (Layer 1) | `CLAUDE.md` | `AGENTS.md` | `.cursor/rules/*.mdc` | `.windsurfrules` | `.github/copilot-instructions.md` | `.aider.conf.yml` + convention files |
| "Memory" (Layer 3) | `MEMORY.md` + topic files | — | — | — | — | — |
| "Curate command" | `.claude/skills/curate/SKILL.md` (`/curate`) | End-of-session prompt | End-of-session prompt | End-of-session prompt | End-of-session prompt | End-of-session prompt |
| "Audit command" | `.claude/skills/audit-context/SKILL.md` (`/audit-context`) | Ad-hoc prompt | Ad-hoc prompt | Ad-hoc prompt | Ad-hoc prompt | Ad-hoc prompt |
| "Session hooks" | `.claude/hooks/` | — | — | — | — | — |
| Nested/directory rules | `CLAUDE.md` in subdirs | `AGENTS.md` in subdirs | `.mdc` files with globs | — | — | — |

### What this means in practice

**If your tool has auto-memory** (currently only Claude Code): Use the full layered model. MEMORY.md as index, topic files for depth, gotcha log for history.

**If your tool doesn't have auto-memory**: Everything goes into the project file. This makes the "keep it lean" advice even more critical — you have one auto-loaded file, not two. Use it as an index with task-triggered pointers to on-demand docs. The runbook, ADRs, and gotcha log still live in the repo and still get loaded on demand — the agent just needs to be pointed there from the project file.

**If your tool supports directory-level rules** (Claude Code, Codex, Cursor): Use them for subsystem-specific constraints. A `src/api/CLAUDE.md` (or `src/api/AGENTS.md`) can carry API-specific rules without cluttering the root project file. This is progressive disclosure at the file system level.

**If your tool supports glob-based rules** (Cursor `.mdc` files): You can target rules to specific file patterns — e.g., a rule that only activates when editing `*.test.ts` files. This is a more granular form of task-triggered loading.

**Cursor `.mdc` example.** Cursor rule files use markdown with a YAML frontmatter block. Here's what a project rule looks like:

```markdown
---
description: Project conventions and constraints for Task Tracker API
globs:
alwaysApply: true
---

# Task Tracker API

A REST API with React frontend and PostgreSQL backend.

## Before You Start

| When | Read |
|------|------|
| Making architectural decisions | `docs/adr/README.md` — decision index |
| Stuck or debugging something weird | `docs/gotcha-log.md` — problem-fix archive |

## Hard Constraints

- Never modify migration files after they've been deployed to staging
- Never skip tests. If tests fail, fix them or explain why they should change.
```

Save this as `.cursor/rules/project.mdc`. For subsystem-specific rules, create additional `.mdc` files with `globs` targeting specific file patterns (e.g., `globs: ["src/api/**"]` for API-only constraints).

### Multi-tool projects

If your team uses different agents (one person on Claude Code, another on Cursor), maintain one canonical project file and symlink or copy to tool-specific locations. The content is the same — only the filename differs. Avoid maintaining parallel files with the same content; they will drift.

### Multi-agent workflows

If you use different agents for different tasks (e.g., one for architecture, another for implementation, a third for code review), the project file becomes even more important — it's the shared orientation document all agents load. Keep universal truths there. Per-agent context (e.g., "the review agent should enforce these style rules") belongs in agent-specific topic files or directory-level rules.

### Multi-contributor projects

The sections above address tool heterogeneity (different agents, same person) and role heterogeneity (different agents, different tasks). Multi-contributor projects face a different challenge: **contributor heterogeneity** — different people, each with their own agent, working in the same codebase.

Layer 5 lives here under Tool-Specific Setup rather than alongside Layers 1–4 by design. Layers 1–4 are the baseline architecture that every project builds on. Layer 5 is genuinely optional in a way the others are not — most projects never need it, and adding it when you don't have multiple contributors adds overhead with no benefit. It is opt-in infrastructure, not a progression step.

If you're working alone, skip this section entirely.

#### What breaks when contributor #2 joins

Three friction points emerge that Layers 1–4 don't address. These were observed in a real project ([RenkumSpot](https://github.com/ducroq/RenkumSpot)) where a second contributor joined an agent-ready codebase:

1. **Constraint visibility.** A contributor's agent submitted a PR that broke a documented constraint. The constraint existed in the project file — but the contributor's agent treated it as the project owner's context, not a shared contract. There was no mechanism to distinguish "what the owner learned" from "what the team agreed to."

2. **Convention divergence.** The new contributor proposed enterprise-grade coding standards (DDD, full TDD) that didn't fit the project's scope. Without a staging area for convention proposals, the first signal of misalignment was a fully-formed document that needed significant rework.

3. **Work overlap.** No visibility into who was working on what. The project's memory, gotcha log, and project file were shaped entirely by one person's workflow. A second contributor's agent inherited this context without knowing which parts were team truth and which were personal preference.

These are coordination problems, not knowledge problems. The documentation was good — the agreement mechanisms were missing.

#### Layer 5: Coordination

For multi-contributor projects, add a `COORDINATION.md` file (from [`templates/coordination.md`](../templates/coordination.md)). This is Layer 5 in the layered model:

| Layer | What | Auto-loaded? | When to add |
|-------|------|-------------|-------------|
| **1. Project file** | Identity, constraints, "Before You Start" table | Yes | Always |
| **2. Runbook** | Operational how-to, principles | No | When the project file gets crowded |
| **3. Memory** | Index + topic files of learned knowledge | Index: yes | When complexity grows |
| **4. Gotcha log** | Problem → Root cause → Fix journal | No | When you hit your first weird bug |
| **5. Coordination** | Contributors, shared constraints, WIP, conventions | No | When the project has multiple contributors |

Layer 5 is **not auto-loaded**. It sits below the auto-loading cliff, accessed via a task-triggered pointer in the project file:

```
| Starting work as a contributor | COORDINATION.md — team agreements, WIP, conventions |
```

This keeps the auto-loading budget unchanged. Contributors read it once at session start; experienced contributors who have internalized the coordination context skip it.

Five sections:

- **Contributors** — who's active, their focus areas, how they work. Not permissions — a "who to talk to about what" index.
- **Shared Constraints** — constraints all contributors agreed to (promoted from the project file when they carry team-agreement weight).
- **Convention Proposals** — lightweight staging for proposed changes. Propose first, then PR — no surprise conventions.
- **Work in Progress** — collision-avoidance signals. Before starting work in an area, check if someone else is there.
- **Memory Conventions** — shared vs personal memory, gotcha log tagging with contributor names.

#### What coordination does NOT solve

Layer 5 is for small teams (2–5 contributors). It explicitly does not cover:

- **Task assignment or sprint planning** — use your existing project management tools.
- **Access control or permissions** — see [OWASP Top 10 for Agentic Applications](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) and [Microsoft Agent Governance Toolkit](https://github.com/microsoft/agent-governance-toolkit) for runtime security.
- **Agent personas** — if you need personas, see BMAD-METHOD's approach described in [COMPARISON.md](COMPARISON.md).
- **Enterprise governance** — if you have 10+ contributors, you need organizational infrastructure beyond what a markdown file provides.

#### The self-learning loop in multiplayer

The [self-learning loop](#the-self-learning-loop) (Capture → Surface → Promote → Retire) works the same way with one addition: **deduplication at the Surface step**.

When curating at end-of-session in a multi-contributor project:

1. Review your session's gotchas as usual.
2. **Check the gotcha log for entries that duplicate or conflict with what other contributors logged.** If someone already captured the same lesson, merge rather than accumulate. If your entry conflicts with theirs, flag it — that's a sign an ADR is needed.
3. Promote as usual, with one adjusted criterion: a gotcha that appears in two different contributors' sessions is as strong a signal as one that recurs three times in your own sessions.

Tag every gotcha log entry with your name or handle. This isn't about blame — it's about provenance. When reviewing a gotcha, knowing who found it tells you who to ask for context.

#### Setting it up

1. Copy [`templates/coordination.md`](../templates/coordination.md), save as `COORDINATION.md` in the project root.
2. Add the task-triggered pointer to your project file's "Before You Start" table.
3. Fill in the Contributors table and agree on memory conventions with your team.

That's it. Convention proposals and WIP entries accumulate organically as people work. Review and prune during end-of-session curation, just like the gotcha log.

See [ADR-002](decisions/ADR-002-multiplayer-coordination-layer.md) for the full design rationale.

### Projects with zero documentation

If you're adding an agent to a codebase with no existing docs, the [adopt prompt](../adopt.md) is the fastest path — the agent derives what it can from code structure, dependencies, and tests. You then review and add what the code doesn't say. This is faster than writing from scratch because the agent handles the mechanical parts (file paths, architecture skeleton, test commands) while you focus on constraints, decisions, and gotchas.

### Long-lived feature branches

For feature branches that span weeks, consider a feature-level context file (see [Feature-level context](#layer-3-memory-memory-index--topic-files--when-complexity-grows)) that lives on the branch. It captures implementation decisions, patterns discovered, and approaches tried and abandoned — context that would clutter the main project file but is essential for the branch's lifetime. Merge or retire it when the branch lands.

## Contributing to This Guide

This guide and your project docs should sharpen each other. When you update a project's docs, check whether the insight applies broadly — if so, consider updating this guide. When you update this guide, check whether your active projects reflect the latest thinking.

- **Project → guide**: After a doc change that solved a real problem (agent kept missing context, doc was in the wrong layer), ask whether the pattern generalizes. If it does, open an issue or PR.
- **Guide → project**: After updating the guide, scan your project files. Are your pointers task-triggered? Are you following your own advice?

Advice that hasn't survived contact with a real codebase is theory. The feedback loop turns local fixes into durable practice.
