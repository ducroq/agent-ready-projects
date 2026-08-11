# Agent-Ready Projects

The source framework that teaches the layered memory method for AI coding agents. Tool-agnostic guide + templates + adopt prompts. Adopters consume `templates/`, `docs/`, and `adopt.md`; the rest is maintainer infrastructure.

- **Type**: Public methodology repo (guide + templates + skills)
- **License**: MIT
- **agent-ready-projects** (this repo): v1.21.0 (the global-skill installer refuses to install content no release contains — #33; `templates/release.md` Step 1 selects its baseline with the same three filters the guard uses — #41. New behaviour = MINOR; the case for MAJOR is on the record in `CHANGELOG.md`.)

> Live project state (current threads, deferred items, surfaced patterns) lives in `memory/MEMORY.md` (maintainer-local — see *What is intentionally not shipped* below). Release notes live in `CHANGELOG.md`.

## Before You Start

| When | Read |
|------|------|
| Starting any session (self drift) | Compare the `agent-ready-projects: vX.Y.Z` line in this file's header against `CHANGELOG.md`. If a newer version has shipped since you last worked here, surface the drift before starting. |
| Installing, moving, or removing a skill | `docs/GUIDE.md` § "Where a skill lives" — global shadows local, so scope is exclusive. Run `bash scripts/install-global-skills.sh --check ~/repos` to verify the global install matches the tracked source and no inert local copies remain. **The install path refuses when the bytes it would copy are not what the highest release tag reachable from HEAD holds** (#33): refresh globals after the tag is pushed *and verified*, per `templates/release.md` Step 7 — a local tag satisfies the guard, so tagging alone is not the safe point. `--force` overrides it and is the right call only when you mean to run an unreleased skill knowingly. |
| Editing a skill — either `templates/<name>.md` or `.claude/skills/<name>/SKILL.md` | **Edit both.** They are one artifact in two files; an edit to one is drift until the other matches. `install-global-skills.sh --check` cannot see this — it compares the global install to the tracked one, so both read as current while diverging from the template. `bash tests/lint/run.sh` rule 6 is what catches it. |
| Before committing structural changes (CLAUDE.md, `memory/`, `templates/`) | Run `bash tests/lint/run.sh` — deterministic structural check, six rules. Catches stale `CLAUDE.md` path references, `memory/MEMORY.md` orphans, broken skill-template frontmatter, a reference install that cannot register, unclosed YAML frontmatter, and template↔install drift. See `tests/lint/README.md` for the rule catalog. Then run `/review-changes` for diff-driven LLM review — picks review lenses from what changed *and* how big it is (templates touched → full battery, unless the diff is small and hits no carve-out; docs-only → adversarial + doc-accuracy). |
| Picking up where the last session left off | `memory/MEMORY.md` — the index itself. Nothing loads it automatically; this row is what reaches it. Topic files in `memory/` stay on demand, per the index's own table. |
| Editing templates | `templates/README.md` for the tool-agnostic naming map. Templates are the adopter-facing surface; changes ripple to every downstream consumer. |
| Editing the guide | `docs/GUIDE.md` is the full reference; `README.md` is the on-ramp. Keep them in sync — when you change one, ask whether the other needs the same change. |
| Working with the verification rationale | `docs/verification-rationale.md` (v1.10.1) — the three structural principles, each with a decision rule. Cite the rationale doc rather than re-deriving. |
| Considering reviving landscape / positioning docs | `memory/project_framework_pivot.md` — 2026-04-14 wrapper-archive decision still stands for positioning. Don't re-promote without explicit user signal. |
| Considering the dead-end log pattern | `memory/project_dead_end_pattern_rollout.md` — **CLOSED 2026-08-03** as silent-abandonment-confirmed (#16). Gate 4 stayed at 0/2 for two months: no unrelated session ever reached for a seeded entry. The idea isn't refuted, the validation evidence was. Don't re-open on enthusiasm — only on an actual session reaching for an entry and acting on it. |
| Cutting a release | Run `/release` if installed locally, per `templates/release.md` — it classifies the bump, runs the preconditions, drafts the changelog entry, and stops before tagging. Background: `CHANGELOG.md` header — maintainer release process (#14) + tag-and-push protocol. v1.10.1 set the precedent that doc-only changes are PATCH; new templates/patterns/behaviors are MINOR. |
| Starting multi-session work (feature, migration, refactor, investigation) | Create `docs/work-items/<slug>.md` from `templates/work-item.md`. Add a one-line pointer in `memory/MEMORY.md` Current State: `- [Short description] → docs/work-items/slug.md [in progress]`. |
| Resuming work on an existing initiative | Read the work-item file in `docs/work-items/` — the Current Status section is the savepoint. |
| Ending a session | Update any active work-item file's Current Status section (the savepoint). Then run `/curate` if installed locally — the framework's own skill, per `templates/curate.md`. |
| Monthly or after major restructuring | Run `/audit-context` if installed locally — structural health check per `templates/audit-context.md`. |

## Hard Constraints

- **Project state goes in in-repo `memory/`, not in user-level Claude Code auto-memory.** Versions, session narratives, pending threads, paused patterns, and anything tied to *this* repo's work belong in this repo's `memory/`. The user-level path at `~/.claude/projects/<slug>/memory/` is reserved for cross-project memory types: **user**, **feedback**, **reference**. The Before You Start table above routes to in-repo memory; that's the canonical pickup path. Don't duplicate project state into both — drift starts as soon as you do. (Origin: agent-ready-papers v1.6.2, 2026-06-08; same rule applied here in v1.10.2, 2026-06-09 — closes #17.)
- **Templates and adopter-facing surfaces are normative.** Changes to `templates/`, `adopt.md`, `README.md`, `docs/GUIDE.md`, or `docs/verification-rationale.md` affect every downstream consumer. Treat edits there with the gravity of an API change: document in `CHANGELOG.md` and choose the right semver bump.
- **Respect the v1.10.1 patch-vs-minor precedent.** Documentation-only changes (rationale docs, clarifications, cross-references) go to PATCH. New templates, new patterns, new behaviors go to MINOR. Breaking changes that require adopter action go to MAJOR.
- **Don't re-promote the framework wrapper.** The 2026-04-14 pivot decision (see `memory/project_framework_pivot.md`) still stands for *positioning*. Maintenance and incremental evolution continue (v1.9.0, v1.10.0, v1.10.1, v1.10.2 all postdate the pivot). Re-promotion is a different decision and requires explicit user signal.
- **Don't self-certify a procedural artifact.** When you author or edit a multi-step procedure that ships (`templates/release.md`, `templates/curate.md`, `templates/audit-context.md`, `templates/review-changes.md`, `scripts/install-global-skills.sh`, `tests/lint/run.sh`, `tests/lint/skill-sync.sh`), you may not report it ready on your own read. **Ten occurrences at last count** — this line has twice lagged `memory/gotcha-log.md`, so re-count against that table rather than incrementing this one — the Promoted table in `memory/gotcha-log.md` carries the running total, and the count is the argument; three of the first seven are 2026-08-10, where batteries refuted 5, 6, and then a further set of assertions in one session — the seventh being lint rule 6, where the anti-self-certification guard was written into the test harness and not into the command that gates commits. The ninth is #33 (2026-08-11), where **four** batteries ran and the first three each refuted the core predicate, not its edges: the author had verified the guard against the states he had thought of, which is the whole shape restated. The tenth is #41 (2026-08-11) and is the sharpest yet: the author fixed a wrong-remedy defect in the installer and, in the same commit, wrote the identical wrong remedy into the adopter-facing template — then the correction was itself refuted for excluding the commonest form of the state it described. Fixing a defect does not immunise you against it one file over. Same shape every time: the artifact passes every check its author thought to run, because the author picked the checks and the artifact from one mental model. Two specific rules fall out. **(1) Cross-step contract:** after editing step N, re-read the steps that consume its output — every defect so far lived in the *relationship between* steps, not in any step read alone. **(2) Hostile-repo test:** a command written for other people's repos must be run against a repo that will punish it — one with a committed lockfile, a vendored directory, hundreds of docs. Verifying against this clean repo is a sample of one and has twice certified a command nobody would run. **(3) Seeded true positives, whenever a change makes a check more permissive:** the fourth occurrence (2026-08-06, `audit-context` Step 4) was a loosening justified by 9-of-9 false positives — a sample with *zero* true positives in it, which measures specificity and cannot measure sensitivity at all. A run that finds nothing cannot distinguish a fixed check from a disabled one. Build a fixture containing the failures the check must still catch, and show it still fires. Then run `/review-changes`.
- **A user-global skill shadows a project-local one of the same name.** In Claude Code, `~/.claude/skills/<name>/` wins; the project-local file is never loaded, never merged, never warned about. Two consequences are normative here. **(1)** Installing a skill globally forecloses per-repo variants of that name — so `review-changes` and `release` stay project-local, while `curate`, `audit-context` and `update-drift` ship global. **(2)** A global install must be *derived* from this repo's tracked `.claude/skills/`, never authored in `~/.claude/` — that directory is not a repository, so a skill living only there has no history, no review, and no restore path. Run `scripts/install-global-skills.sh` to install or verify; `--check <root>` also finds inert project-local copies. (Origin: 2026-08-06 — one untracked global copy had drifted from `templates/` unnoticed for four months, and 45 shadowed local copies across 23 repos read as authoritative while never being loaded.)
- **Tool-agnostic in adopter-facing content.** This repo serves Claude Code, Codex, Cursor, Windsurf, GitHub Copilot, Aider, and others. Public-facing material (`README.md`, `adopt.md`, `templates/`, `docs/GUIDE.md`) must not assume Claude Code. Maintainer infrastructure (this file, `memory/`, `.claude/`) can be Claude-specific.

## Architecture

```
agent-ready-projects/
├── .claude/                   <- All gitignored EXCEPT skills/ (`.claude/*` + `!.claude/skills/`)
│   └── skills/                <- Reference installs — the source a global install derives from
├── README.md                  <- The guide (public-facing on-ramp)
├── adopt.md                   <- Three agent-facing prompts: assess / adopt / update
├── CHANGELOG.md               <- Versioned release notes; maintainer release process at top
├── CLAUDE.md                  <- This file (agent orientation, maintainer-local but committed)
├── LICENSE                    <- MIT
├── docs/                      <- Full reference guide + rationale + worked examples + archive
│   ├── GUIDE.md
│   ├── verification-rationale.md
│   ├── guide/                 <- Four-page visual walkthrough
│   ├── work-items/            <- Per-work-item context files (v1.11.0)
│   ├── archive/               <- LANDSCAPE.md, COMPARISON.md, METHODOLOGY.md (per 2026-04-14 pivot)
│   └── ...
├── templates/                 <- Tool-agnostic starter files adopters consume
│   ├── project-file.md        <- Layer 1
│   ├── memory-index.md        <- Layer 3 index (Claude Code auto-memory tools)
│   ├── gotcha-log.md          <- Layer 4
│   ├── hypothesis-log.md      <- Future-evidence provisional positions
│   ├── RUNBOOK.md             <- Layer 2 operational doc
│   ├── work-item.md           <- Multi-session work tracking with savepoint (v1.11.0)
│   ├── curate.md              <- End-of-session curation skill
│   ├── audit-context.md       <- Periodic structural audit skill
│   ├── review-changes.md      <- Diff-driven pre-commit review skill (v1.12.0)
│   ├── release.md             <- Release skill: bump classification + preconditions, stops before publishing
│   ├── adr.md                 <- Architecture Decision Record template
│   ├── coordination.md        <- Layer 5 (multi-contributor)
│   ├── review-agent.md        <- Reusable review-agent skeleton
│   ├── test-verify-memory.md  <- Behavioral-test pattern (Phase B/C precedent)
│   ├── test-fixtures/         <- Fixtures for behavioral tests
│   ├── checklists/            <- Per-stage validation checklists
│   ├── physics-tests/         <- Specialized scaffolding (physics simulation)
│   └── README.md              <- Tool-agnostic naming map
├── scripts/                   <- Shipped maintainer/adopter tooling
│   └── install-global-skills.sh
│                              <- Install + verify user-global skills; scan an estate for inert copies.
│                                 Refuses to install from a tree that is not at a release tag (#33)
├── tests/                     <- Self-tests for this repo (Phase A: structural lint)
│   ├── lint/                  <- Deterministic structural checks (no LLM)
│   │   └── skill-sync.sh      <- Rule 6: templates/<name>.md vs .claude/skills/<name>/SKILL.md
│   └── fixtures/              <- Seeded-defect fixtures: a check that finds nothing here is failing
│       ├── reference-integrity/  <- Seeded breaks for audit-context Step 4; refcheck.py is its oracle
│       ├── skill-template-sync/  <- Seeded drift for lint rule 6 (17 positives, 7 negatives)
│       └── installer-release-guard/
│                              <- Seeded git states for the installer's release guard
│                                 (17 positives, 15 negatives, 32 ablation rows)
└── memory/                    <- Session memory (gitignored — maintainer-local)
    ├── MEMORY.md              <- Index + current state
    └── project_*.md           <- Topic files (migrated 2026-06-09 from user-level)
```

## What is intentionally not shipped

These paths exist in the maintainer's local clone but are gitignored — they are *not* in the public repo:

| Path | What it holds | For adopters |
|------|---------------|--------------|
| `.claude/settings*.json` | Maintainer Claude Code config | Not needed. **`.claude/skills/` IS shipped and tracked** — it is the source a user-global install derives from (see Hard Constraints) |
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
| `templates/work-item.md` | Multi-session work tracking with built-in savepoint |
| `templates/review-changes.md` | Diff-driven pre-commit review skill |
| `templates/release.md` | Release skill — bump classification, preconditions, changelog entry; stops before tagging |
| `templates/curate.md` | End-of-session curation skill |
| `templates/audit-context.md` | Periodic structural audit skill |
| `scripts/install-global-skills.sh` | Installs the user-global skills from tracked `.claude/skills/`, verifies they match, and with a root argument scans an estate for inert project-local copies. Refuses to install when the bytes it would copy are not what the highest release tag reachable from HEAD holds; fixture at `tests/fixtures/installer-release-guard/` |
| `.claude/skills/` | Reference installs (tracked) — the frontmatter-correct source a global install is derived from |
| `tests/lint/skill-sync.sh` | Lint rule 6 — template↔reference-install drift; fixture at `tests/fixtures/skill-template-sync/` |
| `tests/fixtures/installer-release-guard/` | Seeded git states for the installer's release guard (#33). Its README carries the two rejected predicates and why — read before changing the comparison |
| `memory/MEMORY.md` | This repo's in-repo memory index (maintainer-local) |

## How to Work Here

```bash
# Cut a release (per CHANGELOG.md header, issue #14)
git tag vX.Y.Z <commit>
git push --tags

# Check what changed for a downstream adopter pinned at an older version
git diff vX.Y.Z..vX.Y+1.0 -- templates/

# Self-tests, before committing structural changes
bash tests/lint/run.sh                              # six structural rules
bash tests/fixtures/skill-template-sync/run.sh      # sensitivity of lint rule 6
bash tests/fixtures/reference-integrity/run.sh      # sensitivity of audit-context Step 4
bash tests/fixtures/installer-release-guard/run.sh  # sensitivity of the installer's release guard

# End a session
/curate     # if installed locally from templates/curate.md

# Monthly check
/audit-context     # if installed locally from templates/audit-context.md
```

## Cross-Repo Evidence

- **Downstream consumer**: [agent-ready-papers](https://github.com/ducroq/agent-ready-papers) (v1.6.3+) — applies this method to academic and structured non-fiction writing. Forward-feedback evidence (audits, DRs, version-impact decisions) lands there first and informs this repo's evolution. agent-ready-papers v1.6.2's in-repo-memory Hard Constraint is the immediate origin of the v1.10.2 dog-food fix here.
- **Adopter projects**: 28+ at last count (see `memory/project_framework_pivot.md` for the 2026-04-14 inventory). Touch templates/ with the awareness that each downstream consumer pins to a specific version and reads `CHANGELOG.md` to decide whether to upgrade.
