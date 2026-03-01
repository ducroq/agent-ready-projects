# How This Guide Was Made

The process of creating *Working With AI Agents: A Practical Guide* — and what it revealed about writing documentation for AI agents by using AI agents.

## The starting point

The guide began as a synthesis of patterns observed across 100+ agent sessions on multiple projects. The initial draft laid out a four-layer model: Identity (CLAUDE.md) → Operations (WAY-OF-WORKING.md) → Memory (MEMORY.md + topic files) → History (gotcha-log.md). Clean, logical, symmetrical.

It was also wrong in an important way.

## Phase 1: Apply the guide to one project

The first test was vmodel.eu — an AI-powered requirements review tool for engineering students. The project already had a solid CLAUDE.md and structured MEMORY.md, making it a good candidate for adopting the full four-layer model.

We created all the files the guide prescribed:
- `docs/WAY-OF-WORKING.md` — principles + runbook extracted from CLAUDE.md
- `docs/adr/README.md` — scannable index of 17 ADRs
- `memory/gotcha-log.md` — structured problem/fix entries migrated from MEMORY.md
- Refined MEMORY.md with a topic index table
- Slimmed CLAUDE.md to focus on identity

Everything looked right on paper. Then we reflected.

## Phase 2: The auto-loading cliff

The immediate question was: *will agents actually read WAY-OF-WORKING.md?*

The answer was no. CLAUDE.md is auto-loaded — agents see it without doing anything. WAY-OF-WORKING.md is not. It sits in `docs/` waiting for someone to read it. "Linked prominently from CLAUDE.md" sounds good in a guide, but in practice agents skim past links unless they have a reason to follow them *right now*.

We had moved the test commands and deployment steps out of the auto-loaded file into a file that agents would never open unless prompted. We'd added friction to the most common workflow (running tests) in pursuit of cleaner document separation.

**The fix**: We inlined the runbook back into CLAUDE.md and deleted WAY-OF-WORKING.md. The guide's four-layer model became scale-dependent — the split only makes sense when CLAUDE.md grows large enough that the operational detail is crowding out the identity content.

**The insight**: There is a hard cliff between auto-loaded and not-auto-loaded. Content above the cliff is always available. Content below it is effectively invisible unless something triggers the agent to read it. "Linked prominently" is not a trigger.

This was the single biggest revision to the guide. It changed the model from a rigid four-layer prescription to a scale-dependent recommendation, and it introduced the concept of **task-triggered pointers** — not "see X" but "when doing Y, read X because Z."

## Phase 3: The pointer format

With WAY-OF-WORKING gone, CLAUDE.md's "Before You Start" table became the primary bridge across the auto-loading cliff. The first version used descriptive labels:

```markdown
| What | Where |
|------|-------|
| ADR index (17 decisions) | `docs/adr/README.md` |
| Experiment history & dead ends | `memory/calibration-history.md` |
```

This is a table of contents. It tells agents what exists, not when to use it. We replaced it with task triggers:

```markdown
| When | Read |
|------|------|
| Making architectural decisions | `docs/adr/README.md` — index of 17 ADRs |
| Calibration or scoring work | `memory/calibration-history.md` — dead ends, results |
```

The difference is subtle but important. "Experiment history & dead ends" is a label the agent has to interpret. "Calibration or scoring work" is a task the agent recognizes itself doing. The first requires the agent to reason about relevance; the second triggers on task recognition.

We then noticed the guide itself still showed the old descriptive format in its example — while the "What Doesn't Work" section warned against exactly that. The feedback loop caught the guide violating its own advice.

## Phase 4: The documentation vector

A user principle emerged during this work: **when updating docs, the goal is agent self-navigation.** Every change should be measured by "will a future agent find the right context without being told to look?" — not just "is this accurate?"

This reframed documentation maintenance from a content problem (is the information correct?) to a navigation problem (will the right information be found at the right moment?). Accuracy is table stakes. Self-navigation is the goal.

## Phase 5: Multi-agent audit

With the guide revised, we sent a one-line prompt to agents working on three different projects:

> Read the guide and audit this project against it. Show me what's missing, what's in the wrong layer, and what needs task-triggered pointers. Don't change anything yet — just the audit.

The three projects were:
- **ovr.news** — an editorial/news platform (brand-heavy, content-generating)
- **FluxusSource** — a data aggregation pipeline (infrastructure-heavy, multi-service)
- **NexusMind** — a deployment platform (ops-heavy, cross-repo dependencies)

Each agent returned structured feedback: what worked, what was missing from the guide, what was in the wrong layer in their project. The feedback was consolidated and analyzed for patterns.

## Phase 6: What three agents agreed on

Three different projects, three different agents, and they converged on the same friction points:

**1. The duplication stance was too binary.** All three pushed back on "pick one authoritative location per fact." They converged on the same distinction: same fact with same framing drifts and is harmful. Same fact framed differently for different purposes (a constraint in CLAUDE.md, an operational reminder in MEMORY.md) serves different cognitive moments and is often justified — especially for stable facts.

**2. Line counts were the wrong lever.** All three wanted outcome-based guidance instead of specific numbers. The underlying constraint is context cost per session, not line count. A well-structured 200-line CLAUDE.md beats a 100-line one that punts essentials below the cliff.

**3. Cross-project knowledge had no home.** Two of three flagged this independently. When repos have producer/consumer relationships, where does interface documentation live? The answer: store facts where they're needed, not where they originate.

Other convergent feedback:
- The guide's own example violated its own advice (descriptive labels vs. task triggers)
- RUNBOOK splitting was framed as exceptional when it's actually normal for real projects
- The guide had promotion (gotcha → topic file → MEMORY.md) but no retirement pattern
- Brand/editorial identity needed explicit Layer 1 guidance
- Claude Code's ~200-line truncation limit made topic-file splitting non-optional, not just recommended

## Phase 7: Apply feedback to the guide

The consolidated feedback was applied to the guide in a single pass. The major changes:

1. **Added "The asymmetry of wrong-layer placement"** — err toward auto-loading when in doubt. Too high = gradual noise. Too low = silent miss.
2. **Replaced line count targets with context-budget thinking** — outcome-based, not metric-based.
3. **Nuanced the duplication stance** — same-framing duplication drifts; different-context duplication can be justified if one copy is canonical.
4. **Fixed the guide's own example** — task-triggered format matching the advice.
5. **Reframed RUNBOOK as normal** — "most real projects need this" instead of "when needed."
6. **Added retirement pattern** — the opposite of promotion.
7. **Added brand identity guidance** — for content-generating projects.
8. **Added truncation limit** — tooling constraint that makes topic files non-optional.
9. **Added cross-project knowledge** — store where needed, not where originated.
10. **Added doc debt migration path** — incremental, not wholesale.

## What this process demonstrated

### The feedback loop works
The guide improved more from being tested against three real projects than from any amount of abstract thinking. Every major revision came from a concrete failure: agents not reading WAY-OF-WORKING, agents skimming past descriptive labels, the guide's own example contradicting its advice.

### Agents are good auditors of agent-facing documentation
Asking agents to audit projects against the guide produced structured, specific feedback. They caught things a human reviewer might miss — like the asymmetry between wrong-layer directions (too high degrades gradually, too low fails silently). They also caught things a human reviewer would catch immediately — like the guide's example contradicting its own advice.

### The auto-loading cliff is the central insight
Every other piece of advice in the guide is downstream of this. Task-triggered pointers, progressive disclosure, context budgets, the scale-dependent split — they all exist because of the hard line between auto-loaded and not-auto-loaded content. If agents could cheaply load every doc, none of this would matter. They can't, so it does.

### Theory → practice → theory is the right loop
The initial guide was theory informed by experience. Applying it to a project was practice. The failures surfaced during practice led to better theory. Sending that theory to more projects surfaced more failures. Each cycle sharpened the guide.

The guide that emerged from this loop is shorter on prescription and longer on heuristics. It tells you *how to think about* documentation for agents rather than *exactly what to do* — because the right answer depends on your project's size, complexity, and character.

### Documentation is navigation, not content
The deepest shift: documentation quality for agents isn't about accuracy or completeness. It's about whether the right information surfaces at the right moment without human intervention. A perfectly accurate doc that no agent ever reads is worse than an approximate pointer that triggers the right lookup at the right time.

This is the documentation vector: every change should improve self-navigation, not just content quality.
