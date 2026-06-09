# Agent-Ready Projects

The source framework that teaches the layered memory method for AI coding agents. Tool-agnostic guide + templates + adopt prompts. Adopters consume `templates/`, `docs/`, and `adopt.md`; the rest is maintainer infrastructure.

- **Type**: Public methodology repo (guide + templates + skills)
- **License**: MIT
- **agent-ready-projects** (this repo): v1.10.2 (in-repo memory adoption, 2026-06-09)

> Live project state (current threads, deferred items, surfaced patterns) lives in `memory/MEMORY.md` (maintainer-local — see *What is intentionally not shipped* below). Release notes live in `CHANGELOG.md`.

## Before You Start

| When | Read |
|------|------|
| Starting any session (self drift) | Compare the `agent-ready-projects: vX.Y.Z` line in this file's header against `CHANGELOG.md`. If a newer version has shipped since you last worked here, surface the drift before starting. |
| Picking up project state | `memory/MEMORY.md` for the index; topic files in `memory/` for depth. |
| Editing templates | `templates/README.md` for the tool-agnostic naming map. Templates are the adopter-facing surface; changes ripple to every downstream consumer. |
| Editing the guide | `docs/GUIDE.md` is the full reference; `README.md` is the on-ramp. Keep them in sync — when you change one, ask whether the other needs the same change. |
| Working with the verification rationale | `docs/verification-rationale.md` (v1.10.1) — the three structural principles, each with a decision rule. Cite the rationale doc rather than re-deriving. |
| Considering reviving landscape / positioning docs | `memory/project_framework_pivot.md` — 2026-04-14 wrapper-archive decision still stands for positioning. Don't re-promote without explicit user signal. |
| Considering the dead-end log pattern | `memory/project_dead_end_pattern_rollout.md` — PAUSED 2026-06-05; #16 is the canonical tracker. No new sibling adoptions, no templatization, until gate 4 (Referenced-by-session ≥1 from an unrelated future session) clears. |
| Cutting a release | `CHANGELOG.md` header — maintainer release process (#14) + tag-and-push protocol. v1.10.1 set the precedent that doc-only changes are PATCH; new templates/patterns/behaviors are MINOR. |
| Ending a session | Run `/curate` if installed locally — the framework's own skill, per `templates/curate.md`. |
| Monthly or after major restructuring | Run `/audit-context` if installed locally — structural health check per `templates/audit-context.md`. |

## Hard Constraints

- **Project state goes in in-repo `memory/`, not in user-level Claude Code auto-memory.** Versions, session narratives, pending threads, paused patterns, and anything tied to *this* repo's work belong in this repo's `memory/`. The user-level path at `~/.claude/projects/<slug>/memory/` is reserved for cross-project memory types: **user**, **feedback**, **reference**. The Before You Start table above routes to in-repo memory; that's the canonical pickup path. Don't duplicate project state into both — drift starts as soon as you do. (Origin: agent-ready-papers v1.6.2, 2026-06-08; same rule applied here in v1.10.2, 2026-06-09 — closes #17.)
- **Templates and adopter-facing surfaces are normative.** Changes to `templates/`, `adopt.md`, `README.md`, `docs/GUIDE.md`, or `docs/verification-rationale.md` affect every downstream consumer. Treat edits there with the gravity of an API change: document in `CHANGELOG.md` and choose the right semver bump.
- **Respect the v1.10.1 patch-vs-minor precedent.** Documentation-only changes (rationale docs, clarifications, cross-references) go to PATCH. New templates, new patterns, new behaviors go to MINOR. Breaking changes that require adopter action go to MAJOR.
- **Don't re-promote the framework wrapper.** The 2026-04-14 pivot decision (see `memory/project_framework_pivot.md`) still stands for *positioning*. Maintenance and incremental evolution continue (v1.9.0, v1.10.0, v1.10.1, v1.10.2 all postdate the pivot). Re-promotion is a different decision and requires explicit user signal.
- **Tool-agnostic in adopter-facing content.** This repo serves Claude Code, Codex, Cursor, Windsurf, GitHub Copilot, Aider, and others. Public-facing material (`README.md`, `adopt.md`, `templates/`, `docs/GUIDE.md`) must not assume Claude Code. Maintainer infrastructure (this file, `memory/`, `.claude/`) can be Claude-specific.

## Architecture

```
agent-ready-projects/
├── .claude/                   <- Maintainer Claude Code config (gitignored — not shipped)
├── README.md                  <- The guide (public-facing on-ramp)
├── adopt.md                   <- Three agent-facing prompts: assess / adopt / update
├── CHANGELOG.md               <- Versioned release notes; maintainer release process at top
├── CLAUDE.md                  <- This file (agent orientation, maintainer-local but committed)
├── LICENSE                    <- MIT
├── docs/                      <- Full reference guide + rationale + worked examples + archive
│   ├── GUIDE.md
│   ├── verification-rationale.md
│   ├── guide/                 <- Four-page visual walkthrough
│   ├── archive/               <- LANDSCAPE.md, COMPARISON.md, METHODOLOGY.md (per 2026-04-14 pivot)
│   └── ...
├── templates/                 <- Tool-agnostic starter files adopters consume
│   ├── project-file.md        <- Layer 1
│   ├── memory-index.md        <- Layer 3 index (Claude Code auto-memory tools)
│   ├── gotcha-log.md          <- Layer 4
│   ├── hypothesis-log.md      <- Future-evidence provisional positions
│   ├── RUNBOOK.md             <- Layer 2 operational doc
│   ├── curate.md              <- End-of-session curation skill
│   ├── audit-context.md       <- Periodic structural audit skill
│   ├── coordination.md        <- Layer 5 (multi-contributor)
│   ├── review-agent.md        <- Reusable review-agent skeleton
│   ├── checklists/            <- Per-stage validation checklists
│   ├── physics-tests/         <- Specialized scaffolding (physics simulation)
│   └── README.md              <- Tool-agnostic naming map
└── memory/                    <- Session memory (gitignored — maintainer-local)
    ├── MEMORY.md              <- Index + current state
    └── project_*.md           <- Topic files (migrated 2026-06-09 from user-level)
```

## What is intentionally not shipped

These paths exist in the maintainer's local clone but are gitignored — they are *not* in the public repo:

| Path | What it holds | For adopters |
|------|---------------|--------------|
| `.claude/` | Maintainer Claude Code settings + any locally-installed skills | Not needed — `templates/curate.md` and `templates/audit-context.md` are the shareable form |
| `memory/MEMORY.md` | Maintainer's index of current project state | Not needed — your own adoption builds its own per the templates |
| `memory/project_*.md` | Maintainer's topic files | Build your own as your project accumulates them |

The public framework — `README.md`, `adopt.md`, `docs/`, `templates/`, `CHANGELOG.md`, `LICENSE` — is fully consumable without any of the above. The point of in-repo `memory/` for the maintainer is the same as the point of in-repo `memory/` for any adopter: project state co-located with the code it describes.

Listed here so the architecture diagram above is honest about what an adopter sees on `git clone` versus what the maintainer has on disk.

## Key Paths

| Path | What it is |
|------|-----------|
| `README.md` | Public-facing guide |
| `adopt.md` | Three agent-facing prompts |
| `CHANGELOG.md` | Release notes with maintainer release process at top |
| `docs/GUIDE.md` | Full reference |
| `docs/verification-rationale.md` | Three structural principles + decision rules (v1.10.1) |
| `templates/project-file.md` | Layer-1 project file template |
| `templates/curate.md` | End-of-session curation skill |
| `templates/audit-context.md` | Periodic structural audit skill |
| `memory/MEMORY.md` | This repo's in-repo memory index (maintainer-local) |

## How to Work Here

```bash
# Cut a release (per CHANGELOG.md header, issue #14)
git tag vX.Y.Z <commit>
git push --tags

# Check what changed for a downstream adopter pinned at an older version
git diff vX.Y.Z..vX.Y+1.0 -- templates/

# End a session
/curate     # if installed locally from templates/curate.md

# Monthly check
/audit-context     # if installed locally from templates/audit-context.md
```

## Cross-Repo Evidence

- **Downstream consumer**: [agent-ready-papers](https://github.com/ducroq/agent-ready-papers) (v1.6.3+) — applies this method to academic and structured non-fiction writing. Forward-feedback evidence (audits, DRs, version-impact decisions) lands there first and informs this repo's evolution. agent-ready-papers v1.6.2's in-repo-memory Hard Constraint is the immediate origin of the v1.10.2 dog-food fix here.
- **Adopter projects**: 28+ at last count (see `memory/project_framework_pivot.md` for the 2026-04-14 inventory). Touch templates/ with the awareness that each downstream consumer pins to a specific version and reads `CHANGELOG.md` to decide whether to upgrade.
