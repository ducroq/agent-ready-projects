# ADR-001: In-Repo Memory Over Auto-Memory

**Date:** 2026-03-19
**Status:** Accepted

## Context

The framework originally recommended storing Layer 3 (memory index and topic files) in the tool's auto-memory directory — a hidden, user-specific location outside the repository. For Claude Code, this is `~/.claude/projects/<mangled-path>/memory/`. The rationale was a clean split: auto-memory holds agent-facing context, committed docs hold human-facing context.

After applying this recommendation across 28 active projects for several months, three problems emerged.

### 1. Hidden memory is invisible memory

Auto-memory files live in path-mangled directories like `C--local-dev-ovr-news/memory/`. They don't appear in the editor's file tree. They aren't searchable alongside project code. They can't be opened for quick review without navigating to an obscure path. In practice, this means they don't get reviewed. Stale entries persist. Wrong assumptions survive. The self-learning loop's "promote and retire" phases depend on the engineer seeing what's there — and if it's hidden, it doesn't get curated.

Across 28 projects, approximately 75 memory files had accumulated in auto-memory. The project owner was unaware of what most of them contained.

### 2. Auto-memory creates orphans

The auto-memory path is derived from the project's filesystem path at the time of creation. Moving, renaming, or accessing a project from a different mount point creates a new auto-memory directory. The old one becomes an orphan — disconnected from the project, invisible, never loaded. This happened with projects accessed from both `C:\local_dev\` and `G:\Mijn Drive\`, producing duplicate memory directories with divergent content.

### 3. The "human benefit" heuristic fails in practice

The framework drew the line at "would a human engineer benefit from reading this?" — routing human-useful content to committed docs and agent-only content to auto-memory. In practice, this distinction doesn't hold:

- **Gotcha logs** were routed to auto-memory, but they contain problem-fix knowledge that humans absolutely benefit from.
- **Privacy protocols** and **infrastructure notes** were placed in auto-memory, but they are exactly the kind of operational knowledge that should be visible during code review and onboarding.
- **Project state summaries** were agent-facing but also useful as a quick refresher for the human after a break.

The only content that is genuinely agent-only and not human-useful is ephemeral session state — which shouldn't be persisted at all.

### Related discovery: the global file cliff

A separate but related problem surfaced during this migration. The global instructions file (`~/.claude/CLAUDE.md`) had accumulated project-specific content — a 30-voice library table, TTS engine comparisons, and podcast workflow instructions — that was auto-loaded into every project session regardless of relevance. This is the auto-loading cliff applied at the user level: content that belongs in one project's context was burning tokens in all projects.

## Decision

### Primary: in-repo memory by default

Memory files (Layer 3: memory index, topic files, gotcha log) should live **inside the repository** in a `memory/` directory, not in the tool's auto-memory location.

```
project/
├── CLAUDE.md          # Layer 1: auto-loaded project file
├── docs/
│   └── RUNBOOK.md     # Layer 2: operational runbook
├── memory/
│   ├── MEMORY.md      # Layer 3: memory index (auto-loaded if tool supports it)
│   ├── gotcha-log.md  # Layer 4: problem-fix archive
│   └── [topic files]  # Layer 3: topic files loaded on demand
└── ...
```

This makes memory:
- **Visible** in the editor's file tree
- **Searchable** alongside project code
- **Version controlled** with git
- **Portable** — clone the repo, get the memory
- **Reviewable** during code review and onboarding

### Secondary: slim the global file

The global instructions file (`~/.claude/CLAUDE.md` or equivalent) should contain only content that is genuinely useful in every project:
- User identity and preferences
- Cross-project infrastructure (e.g., shared server access)
- Universal behavioral instructions

Project-specific content — even if used by multiple projects — belongs in those projects' files, not in the global file. Duplication across two or three repos is cheaper than loading irrelevant context in thirty repos.

### Exception: truly private content

Content that should never be committed to a repository — personal notes about collaborators, salary-related context, credential hints — can remain in auto-memory. This is the exception, not the default.

## Consequences

### Positive

- Engineers can see, review, and edit memory files in their normal workflow.
- The self-learning loop (capture → surface → promote → retire) actually works because the "surface" step happens naturally when memory is visible.
- Git history provides an audit trail for knowledge evolution — when was a gotcha promoted? When was a constraint added?
- Onboarding improves: new team members (human or agent) get the full context from a clone.
- No more orphaned memory directories from path changes.
- No more stale entries surviving because nobody knew they existed.

### Negative

- Memory files appear in git status and diffs. Teams need to decide whether to commit them (recommended) or gitignore them.
- Sensitive operational notes (if any) need conscious routing to auto-memory or a gitignored location.
- Tools that auto-load from a specific path (Claude Code auto-loads `~/.claude/projects/*/memory/MEMORY.md`) may need configuration to also load from in-repo `memory/MEMORY.md`. In Claude Code, the project file (`CLAUDE.md`) already handles this through task-triggered pointers — the in-repo memory index is referenced there, not auto-loaded by path convention.

### Migration

For existing projects with auto-memory:
1. Create `memory/` in the repo root.
2. Copy all files from the auto-memory location to in-repo `memory/`.
3. Verify content, then remove the auto-memory copies.
4. Update the project file's "Before You Start" table to point to `memory/` paths.

This is a mechanical operation. We migrated 28 projects (~75 files) in one session.

## Impact on the framework

This decision changes the guidance in the main README:

- **Layer 3 location** changes from "auto-memory directory (not in repo)" to "in-repo `memory/` directory"
- **The auto-memory vs committed docs table** should be removed or reframed — the split is now "in-repo memory (default) vs auto-memory (exception for private content)"
- **The "human benefit" heuristic** should be replaced with: "commit by default, auto-memory only for content you would never put in a repo"
- **A new section on the global file cliff** should be added — guidance on keeping the global instructions file lean and project-agnostic

## References

- agent-ready-projects README.md, lines 169 and 225-234 — current (pre-decision) guidance
- Migration session (2026-03-19) — 28 projects, ~75 files moved from auto-memory to in-repo
- ovr.news ADR-026 — precedent for using ADRs to document process decisions in this ecosystem
