# Audit Context

<!-- SAVE AS: ~/.claude/skills/audit-context/SKILL.md (Claude Code, USER-GLOBAL — see docs/GUIDE.md
     "Where a skill lives"; do not copy this file verbatim, its frontmatter is
     inside this comment. Prefer .claude/skills/audit-context/SKILL.md from this repo.)
     For other tools, run this as an ad-hoc prompt when needed.

     This is a skill (/audit-context) that audits the structural health
     of the layered memory system. Run monthly or after major restructuring.
     Complements /curate (session-level) with framework-level checks.

     Claude Code skills require SKILL.md as the entry point inside a
     named directory under .claude/skills/. Add frontmatter:
     ---
     name: audit-context
     description: Periodic structural audit of the layered memory system — checks for duplication, wrong-layer placement, bloat, and broken references
     disable-model-invocation: false
     --- -->

Structural audit of the agent-ready-projects layered memory system. Run monthly or after major restructuring. Complements `/curate` (session-level cleanup) with framework-level health checks.

## Step 1 — Document size

Check the auto-loaded files (project file and memory index). For each:
- Count lines
- Flag if over ~100 lines (project file) or ~60 lines (memory index) — these are heuristics, not hard limits
- If too long, identify sections that are reference material (looked up on demand, not needed every session) and propose moving them to topic files behind "Before You Start" pointers

## Step 2 — Cross-layer duplication

Check whether the same fact appears in multiple places across the layers:
- Project file (CLAUDE.md / AGENTS.md / etc.)
- Memory index (MEMORY.md)
- Topic files (memory/*.md)
- Tool-specific auto-memory (e.g. ~/.claude/projects/ for Claude Code)

For each duplicate found, recommend which layer should be the single source of truth based on:
- Is it needed every session? → project file
- Is it navigational? → memory index
- Is it reference material loaded on demand? → topic file
- Is it user-specific (preferences, positions, local machine quirks)? → tool auto-memory

## Step 3 — Wrong-layer placement

Check for content that's in the wrong layer:
- **User-specific data in project files**: personal preferences, positions, local machine limitations → should be in tool auto-memory
- **Session navigation in the project file**: "Current State", task progress → should be in the memory index
- **Always-needed constraints buried in topic files**: hard rules, thresholds, non-negotiables → should be in the project file
- **Derivable-from-code content in any memory file**: things `git log`, `grep`, or reading the source would tell you → shouldn't be persisted at all

## Step 4 — Reference integrity

For every file path mentioned in the project file, memory index, and gotcha log:
- Verify the file exists
- Flag any broken references

**First, skip negated existence assertions entirely.** A path inside `! test -f <path>` in a `<!-- verify: -->` comment asserts the file is GONE — its absence is the passing condition. This is about the reference's *intent*, not about whether the path resolves, so it has to be decided before the resolution order below and not inside it.

**For every other path, try to resolve it before reporting it broken** — in this order:

1. **As written**, relative to the repo root.
2. **As a path suffix of a file in the working tree.** Most prose names a file by fragment, not full path: `models/temporal.py` resolves to `src/models/temporal.py`. Two constraints, both load-bearing. Match the **whole fragment**, not the bare basename — a lone `utils.py` landing on some unrelated `utils.py` is a collision, not a resolution, and a collision gets **reported**. And search the **working tree, not the git index** — `git ls-files` omits every gitignored-but-present file, which under this framework's own recommended setup means all of `memory/`.
3. **In a sibling repo — only when the reference is *marked* as cross-repo**, by carrying a sibling repo's name in the path or in the sentence around it. A bare path that happens to also exist next door is a coincidence, not a resolution; without the marker this rung will quietly absorb any common path (`.claude/README.md`, `docs/ARCHITECTURE.md`) that every repo happens to have.
4. **As runtime state.** A file the running system writes (`data/source_states.json`, `circuit_breakers.json`) is *correctly* absent from a development checkout. **Gitignored is necessary but not sufficient** — it means "not committed", which is not the same as "written by the running system". Require a positive signal too: the path sits in a state directory (`data/`, `state/`, `cache/`, `logs/`, `run/`, `var/`, `artifacts/`) or carries a state-file shape (`*_state.json`, `*_health.json`, `.pid`, `.sock`). And runtime state is **data** — a *source file* whose name merely contains "cache" or "state" is still source, and its absence is still a real break. Reaching the deployment host is confirmation if you can, not a requirement.

**A rung you cannot run is not a pass.** Report the reference as broken only when a rung you actually executed rules it out. If you have no sibling repos, no filesystem access above the repo root, or no way to reach a deployment host, report it as *unresolved* and name which rungs you could not run — never silently suppress it, and never upgrade it to a confirmed break.

Carry two things into the report that a bare "resolved" would hide: a path that resolved at rung 2 is still **written stale** and worth correcting, and any resolution weaker than rung 1 should say which rung it came from.

A check keyed to fully-qualified paths reports almost every prose reference as missing, because almost no prose reference is fully qualified. **Measured**, across 1877 real references in 26 repos: 54% resolve as written, 25% resolve only as a fragment (real references, previously all reported broken), and 21% are reported — while 311 of 311 seeded genuine breaks were still caught, including every basename-collision trap. The three constraints above are not stylistic; each was added because dropping it cost real detections in that run. Gitignored-is-sufficient alone silently resolved *every* fabricated path under a gitignored `.claude/`, and an unmarked rung 3 absorbed bare paths that existed only by coincidence in a neighbouring repo.

If a check re-derives the same non-finding on consecutive runs, fix the check. A probe that cries wolf is the failure mode this framework exists to catch.

For every "Before You Start" pointer:
- Verify the target file exists
- Check that the trigger language is task-based ("when doing X, read Y") not passive ("see Y")

## Step 5 — Topic file and work-item reachability

Check that every topic file in memory/ has a task-triggered pointer in the "Before You Start" table. Flag orphaned topic files — they exist but no pointer leads to them, so an agent will never know to load them.

Check that every work-item file in `docs/work-items/` (other than `README.md`) has a corresponding pointer in the memory index's Current State section. Flag orphaned work-item files — they exist but no pointer tracks them. Also flag pointers in MEMORY.md whose target files no longer exist (stale pointer cleanup).

## Step 6 — Framework version drift

Find this project's adopted framework version and compare it against the latest in `agent-ready-projects/CHANGELOG.md`.

**Do not assume a single stamp format.** Adopters write it at least four ways — `agent-ready-projects: v1.14.0`, `framework: agent-ready-projects v1.14.0` in YAML frontmatter, `- **agent-ready-projects**: v1.12.0` as a bullet, and prose inside a status paragraph. Search case-insensitively for `agent-ready-projects` followed by a version-shaped token anywhere in the project file, and read the surrounding line. A check that matches one format reports an *unstamped* project when the stamp is simply written differently — which is worse than no check, because it prompts work that has already been done.

- **No stamp found**: flag it. Without one there is nothing to compare, and drift accumulates unnoticed. Propose adding one.
- **Behind the latest**: list the intervening versions and, for each, whether it applies here. Do not auto-update — adopting is the engineer's call.
- **Behind, but with a recorded reason**: a stamp that says a version was *reviewed and declined* is current, not stale. Report it as reconciled and move on.

The most useful stamp is not a bare number but a short reconciliation record: what was adopted, what was declined, and why. Prefer that shape when proposing one.

## Step 7 — Gitignore correctness

Check what's tracked vs untracked:
- Project-level context (project file, memory index, gotcha log, topic files) should be tracked in git
- User-specific data (tool auto-memory, personal notes, local credentials) should be gitignored
- Flag any mismatches

## Step 8 — Report

Summarize findings by severity:
- **Fix now**: broken references, misplaced secrets/credentials, orphaned files
- **Fix soon**: duplication, bloated auto-loaded files, passive pointer language
- **Consider**: minor size optimizations, optional restructuring

For each finding, state what's wrong, where, and propose a specific fix. Don't make changes without showing the plan first.
