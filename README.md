# Working With AI Agents: A Practical Guide

**Version 1.0.0** | [Changelog](CHANGELOG.md) | [MIT License](LICENSE)

Your AI agent starts every session cold. It doesn't remember yesterday's bugs, your architectural decisions, or what it tried and failed last week. You end up repeating yourself, undoing its mistakes, and wondering why it's not getting better.

**This guide fixes that.** It gives your project a layered memory system — a project file, a memory index, a gotcha log — that agents auto-load and self-navigate. Lessons get captured during work, promoted as they prove their value, and retired when they're stale. Your agent gets smarter with every session, not just every prompt.

Works with any AI coding agent: Claude Code, Codex, Cursor, Windsurf, GitHub Copilot, Aider, and others.

### Ready to try it?

**Option 1 — Let your agent do it.** Open your terminal in any repo and paste one of the prompts from [`adopt.md`](adopt.md):
- **Assess**: Have your agent analyze the repo and tell you where this method would help most
- **Adopt**: Have your agent read this guide and scaffold everything, tailored to your project
- **Update**: Already adopted? Check if you're behind and apply relevant changes

**Option 2 — Do it manually.** Grab a template from [`templates/`](templates/), rename for your tool (see [`templates/README.md`](templates/README.md)), and fill in your specifics.

---

<details>
<summary><strong>Table of contents</strong></summary>

- [The Core Problem](#the-core-problem)
- [The Foundation: Agent Empathy](#the-foundation-agent-empathy)
- [The Auto-Loading Cliff](#the-auto-loading-cliff)
- [The Layered Model](#the-layered-model)
  - [Layer 1: Identity + Operations (project file)](#layer-1-identity--operations-claudemd--always-present)
  - [Layer 2: Runbook](#layer-2-runbook-runbookmd--most-real-projects-need-this)
  - [Layer 3: Memory](#layer-3-memory-memorymd--topic-files--always-present)
  - [Layer 4: History (gotcha log)](#layer-4-history-gotcha-logmd--always-present)
- [How Agents Self-Navigate](#how-agents-self-navigate)
- [Decision Records (ADRs)](#decision-records-adrs)
- [Session Hooks](#session-hooks)
- [The Documentation Rhythm](#the-documentation-rhythm)
- [The Self-Learning Loop](#the-self-learning-loop)
  - [Why this isn't "keep a log"](#why-this-isnt-keep-a-log)
  - [Why a hierarchy works](#why-a-hierarchy-works)
- [Guide-Project Feedback](#guide-project-feedback)
- [What Doesn't Work](#what-doesnt-work)
- [Measuring Success](#measuring-success)
- [Tool-Specific Setup](#tool-specific-setup)
- [Quick Start](#quick-start)
- [Templates](#templates)
- [Further Reading](#further-reading)

</details>

**A note on terminology.** This guide uses Claude Code conventions (CLAUDE.md, MEMORY.md) as concrete examples because that's where the patterns were developed and tested. The principles apply to any AI coding agent — see [Tool-Specific Setup](#tool-specific-setup) for how to map the concepts to your tool.

## The Core Problem

Agents can read code, but code doesn't capture *why* you made decisions, what you tried and abandoned, or what's fragile and shouldn't be touched. Without persistent context, every session starts from zero — agents re-investigate solved problems, undo intentional decisions, and build on stale assumptions.

The fix isn't more documentation. It's the **right** documentation, in the **right** place, with the **right** tone.

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

CLAUDE.md and MEMORY.md are injected into every conversation automatically. The agent sees them without doing anything. Every other file — no matter how prominently linked, no matter how useful — is invisible until the agent actively reads it.

This changes everything about how you structure documentation:

- **Content in auto-loaded files is always available.** Agents act on it from the first message.
- **Content below the cliff requires a trigger.** The agent must know *when* to read it and *what it contains* — before it's read it.
- **"Linked prominently" is not a trigger.** A pointer that says "see docs/RUNBOOK.md" gets skimmed past. A pointer that says "before changing prompts, read docs/RUNBOOK.md for the calibration gate" tells the agent *when* and *why*.

The bridge across the cliff is **task-triggered pointers** in auto-loaded files. Not just "this exists" but "when doing X, read Y first." The agent matches its current task against these triggers and self-navigates to the right file.

This is the single most practical insight in this guide: **auto-loaded files are indexes that help agents find what they need, exactly when they need it.** The self-learning loop (covered later) is the mechanism that moves lessons from session history into always-loaded context — the cliff determines *where* knowledge lives; the loop determines *how it gets there*.

**The asymmetry of wrong-layer placement.** When you're unsure which layer something belongs in, err toward keeping it in auto-loaded files. Content placed too high wastes context — agents see information they don't need, performance degrades gradually. Content placed too low is invisible — the agent doesn't know what it doesn't know, and fails silently. Ten extra lines in CLAUDE.md cost less than a missed constraint that was in a file the agent never loaded.

## The Layered Model

The model scales with project complexity. Not every project needs every layer.

### Layer 1: Identity + Operations (CLAUDE.md) — always present

**Purpose**: "What is this project, what are the rules, and how do I work here?"
**Voice**: Welcoming — "here's what you need to know"
**Location**: Project root (checked into repo)
**Auto-loaded**: Yes

This is the project's home base. It's the only file guaranteed to be read every session, so it carries the most weight. For small-to-medium projects, it contains *everything* an agent needs to start working — identity, constraints, architecture, and operational how-to.

**Always include:**
- Project overview (3-5 lines: what this is, who it's for, what it does)
- Hard constraints and principles (the non-negotiables). Negative constraints ("never remove output fields that downstream apps depend on", "never use external APIs for student data") often land harder than positive ones — they draw a bright line agents won't cross, while positive guidance leaves room for interpretation. Include honesty constraints too — agents confabulate. "Never claim tests pass without running them" and "never claim a file exists without reading it" prevent the most common form of agent failure: confidently asserting something that isn't true.
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
| Calibration or scoring work | `memory/calibration-history.md` — dead ends, results |
| Touching PII or student data | `memory/privacy-protocol.md` — never-do list |
| Stuck on infra or tooling | `memory/gotcha-log.md` — problem-fix archive |
```

The trigger column matters. "ADR index" is a label — an agent skims past it. "Making architectural decisions" is a task the agent recognizes itself doing. If the table exceeds ~8 rows, group related docs into task categories: "Adding or changing sources → CONFIGURATION.md, SOURCE_QUALITY.md" as a single row.

**Context budget, not line count.** The goal isn't "keep files under N lines" — it's to maximize orientation quality while minimizing what agents pay for every session. Auto-loaded content is loaded whether the agent needs it or not. A 80-line file full of task-triggered pointers can outperform a 200-line file packed with details that apply 10% of the time. But a well-structured 200-line file that's the single authoritative source is better than a 100-line file that punts essentials below the cliff. The signal to split isn't hitting a line count — it's agents missing important constraints because they're buried in operational detail. Projects that adopted progressive disclosure — loading context on demand via task-triggered pointers rather than front-loading everything — measured 60-80% reduction in session-start token usage.

When making trade-offs about what to include, prioritize **correctness over completeness over size**. Wrong context (outdated facts, stale paths) is worse than missing context — agents will confidently act on incorrect information. Missing context is worse than noisy context — agents can filter noise, but they can't find what isn't there. All three matter, but in that order.

### Layer 2: Runbook (RUNBOOK.md) — most real projects need this

**Purpose**: "How do we operate here?"
**Voice**: Normative but warm — "we do X because Y"
**Location**: `docs/` directory (checked into repo)
**Auto-loaded**: No — triggered via "Before You Start" in CLAUDE.md

Any project with deployment infrastructure, multiple subsystems, and operational principles will outgrow a single CLAUDE.md. That's normal, not a failure. When it happens, extract the operational how-to into `docs/RUNBOOK.md` — but keep the most critical commands (test suite, deploy) in CLAUDE.md as a summary so agents can act without a second read.

Simple projects with a single test command and no deployment can skip this. But most real projects need it.

The runbook combines two things that are weaker apart:

**Hard constraints** stay in CLAUDE.md (auto-loaded, always visible). **Operational principles** go in the runbook — guidelines that expand on *how* to apply those constraints:
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

### Layer 3: Memory (MEMORY.md → topic files) — always present

**Purpose**: "What have we learned working on this?"
**Voice**: Declarative — "X works like Y", "if you see A, it's because B"
**Location**: Auto-memory directory (not in repo — user-specific)
**Auto-loaded**: MEMORY.md is. Topic files are not.

**Important**: Claude Code truncates MEMORY.md after ~200 lines. Content past the limit silently vanishes from context. The index-not-dump pattern isn't just good practice — it's forced by the tooling. Beyond a certain project size, topic files are non-optional.

This is institutional memory — the hard-won operational knowledge that isn't obvious from reading the code.

**The critical evolution: MEMORY.md as index, not dump.**

A flat MEMORY.md works for simple projects. Once you have 5+ subsystems, it becomes a wall of text that agents skim past. The fix:

```
memory/
├── MEMORY.md           # 60-80 line index + current state
├── llm-quirks.md       # API patterns, model behaviors
├── infrastructure.md   # Servers, deployment, pipeline
├── image-pipeline.md   # Subsystem-specific knowledge
└── gotcha-log.md       # Structured problem/solution archive
```

**MEMORY.md** contains:
- A brief orientation ("Loaded every session. Topic files loaded on demand.")
- A **topic index table** — the second bridge across the auto-loading cliff:

```markdown
| File | When to load | Key insight |
|------|-------------|-------------|
| `calibration-history.md` | Calibration or scoring work | Dead ends, model shootout results |
| `privacy-protocol.md` | Touching PII or student data | Never-do list, script design pattern |
| `gotcha-log.md` | Stuck on infra or tooling | Problem-fix archive |
```

- Current project state (what's shipped, what's blocked)
- Key file paths (the top 10-15 files an agent needs to know about)
- Active architecture decisions (one-liners pointing to ADRs)

The topic index works the same way as CLAUDE.md's "Before You Start" — task-triggered pointers that tell agents *when* to load each file. An agent debugging an infra issue sees "stuck on infra or tooling → gotcha-log.md" and loads it. No prompting needed.

**Topic files** contain deep subsystem knowledge. Agents load the relevant one when working on that subsystem. An agent fixing a frontend bug doesn't need to know about GPU memory management.

This is **progressive disclosure** — start broad, go deep only where needed. It keeps the always-loaded context lean while making deep knowledge one `Read` away.

**Feature-level context.** For complex features that span multiple sessions, consider a context file per feature — implementation knowledge, test strategy, patterns discovered, approaches tried and abandoned. This is progressive disclosure applied at the feature level: the project-level docs tell agents *about* the project, the feature-level doc tells them *about this specific piece of work*. Not every feature needs one, but any feature that takes more than two sessions will benefit.

**What goes in memory files**:
- Current-state facts ("the pipeline processes 3 filters independently")
- Patterns ("Gemini ignores word count targets — don't try to fix this with prompts")
- Gotchas framed as "if X, then Y" ("if R2 uploads fail silently, check you're using the EU endpoint")
- API signatures and parameter quirks
- Server/deployment facts

**What stays out**:
- Instructions ("run X to do Y") — that's CLAUDE.md or the runbook
- Chronological narrative ("on Feb 13 we changed X") — that's the gotcha log
- Principles — that's CLAUDE.md or the runbook

**Auto-memory vs committed documentation.** Some systems (like Claude Code) have auto-memory that persists across sessions but isn't committed to the repo. Use this split intentionally:

| Auto-memory | Committed docs |
|-------------|----------------|
| Agent-specific gotchas (API quirks, model behaviors) | Process and principles (how we work) |
| Debug patterns from past sessions | Architecture decisions (ADRs) |
| Codebase navigation shortcuts | Infrastructure documentation |
| Session-learned patterns | Runbooks and how-to guides |

The dividing line: would a human engineer benefit from reading this? If yes, it belongs in committed docs. If it's primarily saving an agent from repeating past mistakes, auto-memory is the right home.

**Cross-project knowledge.** For related projects (a pipeline feeding a downstream app, a monorepo with shared services), cross-project facts need a home. Global CLAUDE.md (`~/.claude/CLAUDE.md`) handles universal preferences. Project-level memory topic files handle cross-project facts *this* project's agent needs — e.g., "NexusMind uses branch `main` not `master`" in a FluxusSource memory file. The principle: store the fact where it's *needed*, not where it *originates*. Each repo's CLAUDE.md names the relationship and owns its side; neither duplicates the other's internals.

### Layer 4: History (gotcha-log.md) — always present

**Purpose**: "What went wrong before and how was it fixed?"
**Voice**: Narrative — "Problem → Root cause → Fix"
**Location**: Auto-memory directory
**Auto-loaded**: No (loaded when stuck, via MEMORY.md trigger)
**Growth**: Unlimited (append-only)

Pure session logs — "today we did X, then Y" — are useless. But a **structured problem/solution journal** is invaluable:

```markdown
### Cloudflare Pages 20K file limit (2026-02-27)
**Problem**: Deploy broke silently.
**Root cause**: Each article generates 3 files. 7K articles × 3 = 21K files > 20K limit.
**Fix**: Hot/cold archiving (ADR-022) + both route files must check summaries exist.
```

This isn't daily reading. It's a searchable archive. When an agent (or you) hits something weird, searching the gotcha log often reveals it's been solved before.

**Dead ends belong here too.** The gotcha log captures operational problems, but also document *design approaches you tried and rejected* — "we tried a comprehensive 34-test suite, it was over-engineered for the goal, pivoted to 5 focused tests." Without this, agents will re-propose solutions you've already explored and abandoned. ADRs capture what you *chose*; the gotcha log captures what you *tried and walked away from*.

**The promotion pattern**: When a gotcha keeps coming up, promote it:
- From gotcha log → relevant topic file (as an "if X, then Y" pattern)
- From topic file → MEMORY.md (if it's truly universal)

A concrete example: "scp not rsync on gpu-server" appears in the gotcha log. After it comes up in three sessions, it gets promoted to `infrastructure.md` as "if file transfers fail, use scp — rsync has dup() errors on this LXC." After it affects work across multiple subsystems, it gets promoted to MEMORY.md as a universal gotcha.

**The retirement pattern**: Promotion moves lessons upward. Retirement moves them out.
- When a gotcha's root cause is fixed, mark it as resolved in the log (don't delete — it's history)
- When a topic file entry describes behavior that was refactored away, remove it
- When a MEMORY.md entry is fully encoded in CLAUDE.md or in the code itself, remove it from memory — it's been promoted to its permanent home
- Monthly audits should prune as much as they add

This keeps the gotcha log as a complete record while surfacing the most important lessons into always-loaded context.

## How Agents Self-Navigate

The two auto-loaded files work together as a navigation system:

```
CLAUDE.md (auto-loaded)
├── "Before You Start" table → task-triggered pointers to repo docs
│   ├── docs/RUNBOOK.md (when needed)
│   ├── docs/adr/README.md → individual ADRs
│   └── other deep docs
│
MEMORY.md (auto-loaded)
├── Topic index table → task-triggered pointers to memory files
│   ├── gotcha-log.md
│   ├── calibration-history.md
│   └── other topic files
└── Current state, file paths, active decisions
```

The agent reads both auto-loaded files at session start. When it begins a task, it matches the task against the trigger descriptions and loads the relevant on-demand files. No human intervention required.

This is why the trigger descriptions matter so much. "Calibration history" is vague. "Calibration or scoring work → dead ends, model shootout results" tells the agent exactly when this file is relevant and what it contains.

**The documentation vector**: Every time you update docs — whether adding content, reorganizing, or trimming — the question isn't "is this accurate?" It's "will a future agent find the right context without being told to look?" Accuracy is table stakes. Self-navigation is the goal. If you find yourself saying "go read X first" in a session, that's a signal that your auto-loaded pointers are missing a trigger.

## Decision Records (ADRs)

Architecture Decision Records are a companion practice to the layered model.

When you choose between approaches, write a short ADR:
- **Context**: Why we faced this choice
- **Decision**: What we chose
- **Consequences**: What follows (positive and negative)
- **Alternatives**: What else we considered and why we rejected it

ADRs prevent agents from re-debating settled questions. The most common agent failure isn't writing bad code — it's proposing a redesign of something that was intentionally designed.

**Critical**: Maintain an ADR index (one-line summaries with links). Agents need to scan for relevant precedent quickly. 20+ individual files without an index is a maze. Point to it from CLAUDE.md's "Before You Start" table.

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
| **Changed operations** | Process or infrastructure changed? | CLAUDE.md or RUNBOOK.md |
| **End of session** | Review & curate: trim stale entries, promote recurring gotchas | MEMORY.md + topic files (5 min) |
| **Monthly** | Audit: anything resolved? Anything moved to code? Retire stale entries | Prune all memory files |

**Course-correcting.** When you realize the direction is wrong mid-session — requirements changed, an assumption broke, the approach isn't working — stop building and update the plan first. Assess what's affected, update the relevant docs (project file, ADRs, task list), then continue. Agents won't do this on their own; they'll keep building on a broken foundation. The discipline of stopping to course-correct before continuing is a development practice, not a documentation one, but it's what keeps the documentation honest.

The key shift: end-of-session time becomes **5 minutes of curation**, not 20 minutes of writing from recall. Context captured in the moment is more accurate and takes less effort than context reconstructed afterward.

**Automating the rhythm.** If your agent tool supports hooks (commands triggered by events), parts of this rhythm can be automated — updating component docs when code changes, suggesting an ADR when a design decision is detected, prompting end-of-session curation when a session runs long. Manual capture is the baseline; event-driven updates are the upgrade.

## The Self-Learning Loop

The documentation rhythm, promotion pattern, retirement pattern, and end-of-session curation described above aren't separate practices — they're phases of a single cycle. Naming it makes it visible: **Capture → Surface → Promote → Retire.**

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

**Capture.** During work, you log gotchas as they happen (2-3 lines), note non-obvious learnings in topic files, and write ADRs when choosing between approaches. This is the raw material — cheap to create in the moment, expensive to reconstruct later. (Details: [The Documentation Rhythm](#the-documentation-rhythm), [Layer 4: History](#layer-4-history-gotcha-logmd--always-present).)

**Surface.** At end-of-session, spend 5 minutes reviewing what was captured. Which gotchas appeared before? Which topic file entries are stale? Which lessons apply beyond the subsystem they were learned in? This is curation, not creation — you're connecting dots, not writing from recall. (Details: [The Documentation Rhythm](#the-documentation-rhythm).)

**Promote.** When a lesson proves its value through repetition, move it up the stack. A gotcha that recurs in three sessions becomes an "if X, then Y" entry in the relevant topic file. A topic file pattern that affects multiple subsystems moves to the memory index. A memory index entry that's truly universal — a hard constraint every session needs — graduates to the project file. Each promotion moves the lesson closer to always-loaded context, where agents act on it without being told. (Details: [The promotion pattern](#layer-4-history-gotcha-logmd--always-present).)

**Retire.** When a gotcha's root cause is fixed, mark it resolved. When a topic file entry describes behavior that was refactored away, remove it. When a memory index entry is fully encoded in the project file or in the code itself, remove it — it's reached its permanent home. Monthly audits should prune as much as they add. (Details: [The retirement pattern](#layer-4-history-gotcha-logmd--always-present).)

### A gotcha's full lifecycle

Here's a concrete example of one lesson traveling through the entire loop:

1. **Capture** — Session 4: `scp` works for file transfers to gpu-server but `rsync` fails with dup() errors. Logged in `gotcha-log.md`.
2. **Surface** — End of session 4: Noted during curation, but only one occurrence. Left in place.
3. **Surface** — End of session 7: Same gotcha appeared again. Tagged it as recurring.
4. **Promote** — Session 8 curation: Promoted to `infrastructure.md` as: *"if file transfers to gpu-server fail, use scp — rsync has dup() errors on this LXC container."*
5. **Promote** — Session 15: Pattern affected image pipeline, TTS workflow, and deployment scripts. Promoted to the memory index as a universal gotcha.
6. **Retire** — Session 22: LXC container was rebuilt with proper kernel support. rsync works now. Removed from memory index, marked resolved in gotcha-log.

Total effort: ~2 minutes across 6 sessions. The lesson was available at the right level of visibility for each phase of its life.

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

**Miss cost asymmetry.** When a processor misses L1, it checks L2 — cheap. When it misses every cache level, it goes to disk — orders of magnitude slower. Agent context works the same way. A lesson missing from the project file just means the agent checks the memory index — one extra read. But a lesson missing from *all* layers means the agent rediscovers it from scratch: reading code, hitting the bug, debugging it again, at full session cost. This is why promotion matters. Frequently-needed knowledge living too deep in the stack has a "miss penalty" every session — the agent pays for it in wasted time whether you notice or not.

**Eviction discipline.** Caches don't grow forever — they evict entries using principled policies like LRU (least recently used) and LFU (least frequently used). "Monthly audits" is the right instinct, but processors teach us to be specific about *what* to evict. Apply LRU to your memory: if an entry hasn't been relevant in the last N sessions, it's a demotion or retirement candidate. Apply LFU to your project file: if a constraint has never actually prevented a mistake, it's taking up space in the hottest layer without earning its keep. The goal isn't a smaller file — it's a file where everything pulls its weight.

**Locality of reference.** Processors exploit two patterns: *temporal locality* (recently accessed data is likely needed again soon) and *spatial locality* (data near recently accessed data is likely needed too). Both apply to agent context. Temporal: recent gotchas are more relevant than old ones — weight them higher during curation. Spatial: if an agent needs one fact about the API layer, it probably needs related API facts — this is why topic files should be organized by task domain, not by date. A topic file is a cache line: load it once, get everything related.

One more borrowed insight: the guide's task-triggered pointers are **prefetch hints**. Processors predict what data will be needed and load it before it's requested. "When doing calibration work, read `calibration-history.md`" is exactly this — telling the agent to prefetch context before it discovers it needs it. Organizing pointers by task (not by file location) is spatial prefetching: "you're working in this area, so here's the bundle of context you'll need."

### Signals the loop is working

- Gotcha log entries get promoted regularly — the log isn't just growing, it's feeding the system
- Topic files contain lessons that started as gotchas — you can trace the lineage
- Memory index entries are things agents *need* every session, not things they *might* need someday
- Monthly audits remove roughly as much as they keep — the system breathes
- The same problem rarely appears three times without being promoted

### Signals the loop is failing

- Gotcha log grows but nothing ever moves up — it's a write-only archive
- Same problem appears 3+ times in different sessions without promotion
- Memory index is bloated with entries that applied once and were never revisited
- Topic files have stale entries describing behavior that was refactored away months ago
- End-of-session curation isn't happening — capture without curation is just journaling

## Guide-Project Feedback

This guide and your project docs should sharpen each other. When you update a project's docs, check whether the insight applies broadly — if so, update this guide. When you update this guide, check whether your active projects reflect the latest thinking — if not, apply it.

In practice:
- **Guide → project**: After updating the guide, scan your project's CLAUDE.md and MEMORY.md. Are your pointers task-triggered or just descriptive? Are you following your own advice?
- **Project → guide**: After a doc change that solved a real problem (agent kept missing context, doc was in the wrong layer), ask whether the pattern generalizes. If it does, capture it here.

This is how the guide stays honest. Advice that hasn't survived contact with a real codebase is theory. Advice that worked once but was never generalized is a local fix. The feedback loop turns both into durable practice.

## What Doesn't Work

### Flat memory files
A single MEMORY.md that grows to 200 lines of mixed concerns. An agent looking for "why is my API call failing" has to wade through curated image library details and frontend rendering patterns. Split into topic files and use MEMORY.md as an index. (And remember: Claude Code hard-truncates MEMORY.md at ~200 lines, so anything past the limit is silently invisible.)

### Duplicating content across docs
The same fact stated identically in two places will drift — one gets updated, the other doesn't. This applies to code-to-doc copies (API specs pasted into markdown) and doc-to-doc overlap (README, CLAUDE.md, and RUNBOOK.md all describing the same architecture).

However, the same fact **framed differently for different purposes** can be valuable: a constraint ("never use external APIs for student data") in CLAUDE.md and an operational reminder ("when adding a new model provider, verify it's EU-hosted") in the runbook serve different cognitive moments. The test: if you removed one copy, would agents reliably find the other at the moment they need it? If not, the duplication is justified — but one copy should be canonical, and the other should defer to it.

The drift risk of duplicated facts is proportional to how often the fact changes and how similar the framings are. A stable architectural fact (like a pipeline order) referenced in different contexts is low risk. A configuration rule restated with slightly different wording in two docs is high risk — the framings will diverge within a few sessions.

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

### Pure session logs
"Today we did X, then Y, then Z" grows without bound and buries signal. But don't go to the other extreme — a structured gotcha log (Problem → Root cause → Fix) is genuinely useful. The distinction: journals of activity are noise; journals of problems and solutions are knowledge.

## Measuring Success

You know the system is working when:
- New sessions start productive within the first exchange
- Agents don't re-investigate solved problems
- Agents don't undo intentional decisions
- You rarely say "no, we tried that and it doesn't work"
- The agent's first instinct aligns with your preferences
- Agents load the right on-demand files without being told
- End-of-session documentation takes 5 minutes, not 20
- Gotcha log entries get promoted regularly — the self-learning loop is turning

You know it's failing when:
- You're explaining the same thing every session
- Agents produce work you have to significantly rework
- You keep saying "go read X first"
- Docs are always out of date
- MEMORY.md is over 150 lines and you're not sure what's still relevant
- You feel like the agent "doesn't get" the project
- Same problem appears 3+ times without being promoted — the self-learning loop is stalled

**Validating, not just trusting.** Good documentation doesn't guarantee good behavior. Agents can read your constraints and still cut corners when they're confident, ignore warnings when they've invested effort in an approach, or defer to your suggestions even when those suggestions violate the project's own principles. Occasionally test this: ask the agent to do something that should trigger a constraint, or apply time pressure and see if quality holds. If your docs say "never skip tests" but the agent skips them when the task feels urgent, the constraint isn't landing — it may need stronger framing or a concrete example of what "never" means.

## Tool-Specific Setup

This guide's concepts map to every major AI coding agent. The file names and mechanisms differ, but the principles — auto-loaded context, task-triggered pointers, layered documentation — are universal.

### Concept mapping

| This guide says | Claude Code | Codex (OpenAI) | Cursor | Windsurf | GitHub Copilot | Aider |
|----------------|------------|----------------|--------|----------|----------------|-------|
| "Project file" (Layer 1) | `CLAUDE.md` | `AGENTS.md` | `.cursor/rules/*.mdc` | `.windsurfrules` | `.github/copilot-instructions.md` | `.aider.conf.yml` + convention files |
| "Memory" (Layer 3) | `MEMORY.md` + topic files | — | — | — | — | — |
| "Session hooks" | `.claude/hooks/` | — | — | — | — | — |
| Nested/directory rules | `CLAUDE.md` in subdirs | `AGENTS.md` in subdirs | `.mdc` files with globs | — | — | — |

### What this means in practice

**If your tool has auto-memory** (currently only Claude Code): Use the full layered model. MEMORY.md as index, topic files for depth, gotcha log for history.

**If your tool doesn't have auto-memory**: Everything goes into the project file. This makes the "keep it lean" advice even more critical — you have one auto-loaded file, not two. Use it as an index with task-triggered pointers to on-demand docs. The runbook, ADRs, and gotcha log still live in the repo and still get loaded on demand — the agent just needs to be pointed there from the project file.

**If your tool supports directory-level rules** (Claude Code, Codex, Cursor): Use them for subsystem-specific constraints. A `src/api/CLAUDE.md` (or `src/api/AGENTS.md`) can carry API-specific rules without cluttering the root project file. This is progressive disclosure at the file system level.

**If your tool supports glob-based rules** (Cursor `.mdc` files): You can target rules to specific file patterns — e.g., a rule that only activates when editing `*.test.ts` files. This is a more granular form of task-triggered loading.

### Multi-tool projects

If your team uses different agents (one person on Claude Code, another on Cursor), maintain one canonical project file and symlink or copy to tool-specific locations. The content is the same — only the filename differs. Avoid maintaining parallel files with the same content; they will drift.

## Quick Start

For a new project:

1. Copy [`templates/project-file.md`](templates/project-file.md), rename for your tool (see [`templates/README.md`](templates/README.md)): fill in identity, constraints, architecture, how-to, "Before You Start" pointers with task triggers
2. If your tool has auto-memory: copy [`templates/memory-index.md`](templates/memory-index.md) — current state, key paths, topic file index
3. Copy [`templates/gotcha-log.md`](templates/gotcha-log.md): first entry will come naturally
4. Add a session hook showing system status (if your tool supports hooks)

The self-learning loop starts working from session one — log gotchas as you hit them, curate at end-of-session, and the Capture → Surface → Promote → Retire cycle builds momentum on its own.

For a growing project:

5. When the project file's operational detail is crowding out identity content, extract to `docs/RUNBOOK.md` (most real projects reach this point)
6. If using auto-memory: split a bloated memory index into index + topic files (non-optional once it gets too long for your tool's auto-load limit)
7. If you have ADRs, create an index. If you don't, start writing them

For a project with existing doc debt:

Don't reorganize everything at once. Start by adding a "Before You Start" table to your project file — highest ROI, 10 minutes. Create a gotcha log on the next session where you hit something weird. Split the memory index only when it's clearly too long. The incremental path matters because wholesale reorganization is the thing most likely to get deferred forever.

For any project:

Document as you go (during work), curate at end-of-session (not create). The best documentation is written when context is fresh and takes 2-3 lines, not reconstructed from memory in a 20-minute session-end dump.

## Templates

Ready-to-use starter files in [`templates/`](templates/). Tool-agnostic — rename for your agent (see [`templates/README.md`](templates/README.md) for the naming map).

- **[`project-file.md`](templates/project-file.md)** — Project identity, constraints, and "Before You Start" table
- **[`memory-index.md`](templates/memory-index.md)** — Index + current state (for tools with auto-memory)
- **[`gotcha-log.md`](templates/gotcha-log.md)** — Structured problem/solution journal with promotion tracking
- **[`RUNBOOK.md`](templates/RUNBOOK.md)** — Operational principles and how-to

Copy, rename for your tool, delete the comments, fill in your specifics.

## Further Reading

- **[`docs/LANDSCAPE.md`](docs/LANDSCAPE.md)** — State of the art in context engineering for coding agents, gap analysis, and where this guide fits relative to existing work (Fowler, BMAD, spec-kit, HumanLayer, AGENTS.md, and others)
- **[`docs/COMPARISON.md`](docs/COMPARISON.md)** — Detailed mapping against BMAD-METHOD and spec-kit: where they validate these principles, what they add, and what you probably don't need
- **[`docs/METHODOLOGY.md`](docs/METHODOLOGY.md)** — How this guide was iteratively developed and tested, including the concrete failures that shaped it and the multi-agent audit that pressure-tested it against three real projects

