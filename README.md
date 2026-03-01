# Working With AI Agents: A Practical Guide

How to set up projects so AI coding agents (Claude Code, Codex, Cursor, Windsurf, Copilot, Aider, etc.) can work effectively across sessions. Lessons learned from 100+ agent sessions across multiple codebases, pressure-tested by multiple agents against real projects.

This is not about prompting. It's about **project infrastructure** — the files, conventions, and habits that make the difference between an agent that spins its wheels and one that ships.

> **Want to get started fast?** Grab a template from [`templates/`](templates/) and adapt it to your project.

**A note on terminology.** This guide uses Claude Code conventions (CLAUDE.md, MEMORY.md) as concrete examples because that's where the patterns were developed and tested. The principles apply to any AI coding agent — see [Tool-Specific Setup](#tool-specific-setup) for how to map the concepts to your tool.

## The Core Problem

AI agents start every session cold. They don't remember yesterday. They can't see your mental model. They'll read your code, but code doesn't capture *why* you made decisions, what you tried and abandoned, or what's fragile and shouldn't be touched.

Without persistent context, you get:
- Agents re-investigating problems you already solved
- Agents undoing intentional decisions they don't understand
- Agents building on assumptions that changed three sessions ago
- You repeating the same explanations every session

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

This is the single most practical insight in this guide: **auto-loaded files are indexes that help agents find what they need, exactly when they need it.**

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
- Hard constraints and principles (the non-negotiables)
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

**Context budget, not line count.** The goal isn't "keep files under N lines" — it's to maximize orientation quality while minimizing what agents pay for every session. Auto-loaded content is loaded whether the agent needs it or not. A 80-line file full of task-triggered pointers can outperform a 200-line file packed with details that apply 10% of the time. But a well-structured 200-line file that's the single authoritative source is better than a 100-line file that punts essentials below the cliff. The signal to split isn't hitting a line count — it's agents missing important constraints because they're buried in operational detail.

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

The key shift: end-of-session time becomes **5 minutes of curation**, not 20 minutes of writing from recall. Context captured in the moment is more accurate and takes less effort than context reconstructed afterward.

## The Feedback Loop

This guide and your project docs should sharpen each other. When you update a project's docs, check whether the insight applies broadly — if so, update this guide. When you update this guide, check whether your active projects reflect the latest thinking — if not, apply it.

In practice:
- **Guide → project**: After updating the guide, scan your project's CLAUDE.md and MEMORY.md. Are your pointers task-triggered or just descriptive? Are you following your own advice?
- **Project → guide**: After a doc change that solved a real problem (agent kept missing context, doc was in the wrong layer), ask whether the pattern generalizes. If it does, capture it here.

This is how the guide stays honest. Advice that hasn't survived contact with a real codebase is theory. Advice that worked once but was never generalized is a local fix. The loop turns both into durable practice.

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

You know it's failing when:
- You're explaining the same thing every session
- Agents produce work you have to significantly rework
- You keep saying "go read X first"
- Docs are always out of date
- MEMORY.md is over 150 lines and you're not sure what's still relevant
- You feel like the agent "doesn't get" the project

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

1. Write your project file (CLAUDE.md / AGENTS.md / `.windsurfrules` / etc.): identity, constraints, architecture, how-to, "Before You Start" pointers with task triggers
2. If your tool has auto-memory: start a MEMORY.md with current state, key paths, topic file index
3. Start a gotcha-log.md: first entry will come naturally
4. Add a session hook showing system status (if your tool supports hooks)

For a growing project:

5. When the project file's operational detail is crowding out identity content, extract to `docs/RUNBOOK.md` (most real projects reach this point)
6. If using auto-memory: split bloated MEMORY.md into index + topic files (non-optional once past ~200 lines due to truncation)
7. If you have ADRs, create an index. If you don't, start writing them

For a project with existing doc debt:

Don't reorganize everything at once. Start by adding a "Before You Start" table to your project file — highest ROI, 10 minutes. Create gotcha-log.md on the next session where you hit something weird. Split MEMORY.md only when it's clearly too long. The incremental path matters because wholesale reorganization is the thing most likely to get deferred forever.

For any project:

Document as you go (during work), curate at end-of-session (not create). The best documentation is written when context is fresh and takes 2-3 lines, not reconstructed from memory in a 20-minute session-end dump.

## Templates

Ready-to-use starter files in [`templates/`](templates/):

- **[`CLAUDE.md`](templates/CLAUDE.md)** — Project identity, constraints, and "Before You Start" table
- **[`MEMORY.md`](templates/MEMORY.md)** — Index + current state (auto-memory)
- **[`gotcha-log.md`](templates/gotcha-log.md)** — Structured problem/solution journal
- **[`RUNBOOK.md`](templates/RUNBOOK.md)** — Operational principles and how-to

Copy what you need, delete the comments, fill in your specifics.

## How This Guide Was Made

Interested in the process? **[`METHODOLOGY.md`](METHODOLOGY.md)** documents how this guide was iteratively developed and tested — including the concrete failures that shaped it, the multi-agent audit that pressure-tested it against three real projects, and what three independent agents agreed was missing.

