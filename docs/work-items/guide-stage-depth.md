# GUIDE: layer depth by project stage

## What & Why

`docs/GUIDE.md` presents Layers 1–5 as a numbered stack with *trigger*-based "when to add" guidance ("when the project file gets crowded"). It never says the other half: a layer adopted before its stage is not neutral overhead — it actively costs you. A runbook written during exploration goes stale faster than it gets updated, and a stale operational doc is worse than none because the agent runs the documented command instead of asking.

This work item adds a **project-maturity axis** the guide currently lacks: Explore → Consolidate → Cooperate → Deploy, with an explicit "premature" column.

Adapted from [raoulg/codestyle](https://github.com/raoulg/codestyle) (evaluated 2026-08-03), which applies the same four stages to Python coding standards and marks each standard 🐌 / 💡 / 🏅 per stage. The idea carried over is that **the mark can be negative, not merely absent**. Note the axis is orthogonal to `templates/checklists/`, which is per-*workflow*-stage (architect/test/implement/qa), not per-project-maturity.

## Current Status

**State:** drafted, not landed

- [x] Source evaluated — codestyle has zero content overlap with this repo (universal Python standards vs. project-specific memory); the stage framework is the only transferable part
- [x] Draft section written (full text in Proposed Section below)
- [ ] Engineer review of wording — not yet read
- [ ] Land in `docs/GUIDE.md` under `## The Layered Model`, replacing the one-line intro ("The model scales with project complexity. Not every project needs every layer.") immediately before `### Layer 1`
- [ ] Decide whether a per-stage column also goes in `templates/README.md` — that would change the bump from PATCH to MINOR

## Decisions

- [2026-08-03] Chose to add a *stage* axis rather than revise the existing per-layer triggers. The triggers describe when a layer starts paying off; the stage table describes when it starts costing. Both are useful and neither subsumes the other.
- [2026-08-03] Rejected adopting codestyle's MCP *delivery* model (guidelines as a queryable server). Our content is per-project by definition, and file-based memory in git is what makes it reviewable. Recorded so this isn't re-litigated.
- [2026-08-03] Kept the gotcha log out of the premature column at every stage — it costs nothing until it has entries, and its first entry is always unplanned.

## Open Questions

- Does the four-stage vocabulary (Explore / Consolidate / Cooperate / Deploy) need renaming for a tool-agnostic audience, or does it read cleanly outside a Python/DS context?
- Should `templates/README.md` carry a per-stage column? Adds adopter value; costs a MINOR bump and widens the normative surface.

## Proposed Section

<!-- Full draft text, preserved here so it survives a context reset.
     Replaces the current one-line intro under "## The Layered Model". -->

> The model scales with project complexity. Not every project needs every layer.
>
> Read that as a genuine claim, not a disclaimer. The layers are numbered, so the stack reads like a ladder to climb — and the per-layer "when to add" triggers later in this guide describe the moment a layer *starts paying off*. Neither says the other half: a layer adopted before its moment doesn't sit there neutrally. It costs you.
>
> ### How deep to go: layer depth by project stage
>
> Documentation practices are stage-dependent. The same file that saves a mature project a week of rediscovery is dead weight on a three-day exploration — and worse than dead weight, because every stale line in an auto-loaded file is a line the agent will confidently act on.
>
> Four stages, by what the work actually looks like:
>
> | Stage | What you're doing | Essential | Recommended | Premature |
> |-------|-------------------|-----------|-------------|-----------|
> | **Explore** | Notebooks, single scripts, testing whether the idea works at all | Layer 1 (short — 20–40 lines) | — | Layers 2, 3, 5 |
> | **Consolidate** | Splitting into modules, structure emerging, decisions worth remembering | Layers 1, 4 | Layer 3 (index only) | Layers 2, 5 |
> | **Cooperate** | Someone else reads the code; conventions need stating | Layers 1, 2, 4 | Layer 3 (index + topic files) | Layer 5 (until contributor #2) |
> | **Deploy** | Production, on-call, real users, real consequences | Layers 1, 2, 3, 4 | Layer 5 (if multi-contributor) | — |
>
> "Premature" is the load-bearing column. Three ways an early layer actively hurts:
>
> 1. **A runbook written before the operations stabilize is a runbook that's wrong.** During Explore, the commands change daily. A Layer 2 doc becomes stale faster than you'll update it, and a stale operational doc is worse than none — the agent runs the documented command instead of asking.
>
> 2. **Memory topic files before there's anything to remember produce padding.** Layer 3 earns its keep when the index points at knowledge that took real effort to acquire. Created early, it fills with restatements of what the code already says, and the agent pays that cost every session while learning nothing the codebase wouldn't have told it.
>
> 3. **Coordination structure with one contributor is pure ceremony.** Layer 5 exists to distinguish team truth from personal preference. With a team of one there is no distinction to draw, and the file's upkeep is a tax on every change.
>
> The gotcha log is the exception worth calling out: it costs nothing until it has entries, and its first entry is always unplanned. Start it at Consolidate and let it stay empty.
>
> **Moving between stages.** Projects move up and occasionally back down. The signal to add a layer is the friction the layer relieves — not the calendar, and not this table. If the project file has grown crowded enough that constraints are getting buried, that's Layer 2 regardless of stage. If you keep re-deriving the same conclusion across sessions, that's Layer 3. Stage tells you what to *expect*; friction tells you what to *do*.
>
> ---
>
> *The four-stage framing is adapted from [raoulg/codestyle](https://github.com/raoulg/codestyle), which applies the same Explore → Consolidate → Cooperate → Deploy axis to Python coding standards — marking each standard as slowing you down, recommended, or essential at each stage. The insight carried over is that the mark can be negative, not merely absent.*

## Outcome

**Status**: [pending]
**Date**: —

**What happened**: —

**What remains**: —

**Related**: Source evaluation 2026-08-03; sibling change in the same session added the pre-commit and per-release rows to the guide's Documentation Rhythm table.
