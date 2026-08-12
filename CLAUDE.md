# Agent-Ready Projects

The source framework that teaches the layered memory method for AI coding agents. Tool-agnostic guide + templates + adopt prompts. Adopters consume `templates/`, `docs/`, and `adopt.md`; the rest is maintainer infrastructure.

- **Type**: Public methodology repo (guide + templates + skills)
- **License**: MIT
- **agent-ready-projects** (this repo): v1.24.0 (`curate` Step 0 reads metadata rather than documents — #46: an ordinary session reads a median of 3 memory files, measured across 2,264 transcripts, and Step 0 was the only thing reading the whole corpus. 64/60/92% less read surface. Heading status and recurrence counts now live in the heading.)

> Live project state (current threads, deferred items, surfaced patterns) lives in `memory/MEMORY.md` (maintainer-local — see *What is intentionally not shipped* below). Release notes live in `CHANGELOG.md`.

## Before You Start

| When | Read |
|------|------|
| Starting any session (self drift) | Compare the `agent-ready-projects: vX.Y.Z` line in this file's header against `CHANGELOG.md`. If a newer version has shipped since you last worked here, surface the drift before starting. |
| Installing, moving, or removing a skill | `docs/GUIDE.md` § "Where a skill lives" — global shadows local, so scope is exclusive. Run `bash scripts/install-global-skills.sh --check ~/repos` to verify the global install matches the tracked source and no inert local copies remain. **The install path refuses when the bytes it would copy are not what the highest release tag reachable from HEAD holds** (#33): refresh globals after the tag is pushed *and verified*, per `templates/release.md` Step 7 — a local tag satisfies the guard, so tagging alone is not the safe point. `--force` overrides it and is the right call only when you mean to run an unreleased skill knowingly. |
| Editing a skill — either `templates/<name>.md` or `.claude/skills/<name>/SKILL.md` | **Edit both.** They are one artifact in two files; an edit to one is drift until the other matches. `install-global-skills.sh --check` cannot see this — it compares the global install to the tracked one, so both read as current while diverging from the template. `bash tests/lint/run.sh` rule 6 is what catches it. |
| Before committing structural changes (CLAUDE.md, `memory/`, `templates/`) | Run `bash tests/lint/run.sh` — deterministic structural check, eight rules. Catches stale `CLAUDE.md` path references, `memory/MEMORY.md` orphans, broken skill-template frontmatter, a reference install that cannot register, unclosed YAML frontmatter, template↔install drift, a skill that provisions a canonical row without quoting it, and adopter-facing templates growing unmeasured. See `tests/lint/README.md` for the rule catalog. Then run `/review-changes` for diff-driven LLM review — picks review lenses from what changed *and* how big it is (templates touched → full battery, unless the diff is small and hits no carve-out; docs-only → adversarial + doc-accuracy). |
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
- **Don't self-certify a procedural artifact.** When you author or edit a multi-step procedure that ships (`templates/release.md`, `templates/curate.md`, `templates/audit-context.md`, `templates/review-changes.md`, `scripts/install-global-skills.sh`, `tests/lint/run.sh`, `tests/lint/skill-sync.sh`), you may not report it ready on your own read. **Fifteen occurrences at last count** — this line has twice lagged `memory/gotcha-log.md`, so re-count against that table rather than incrementing this one — the Promoted table in `memory/gotcha-log.md` carries the running total, and the count is the argument; three of the first seven are 2026-08-10, where batteries refuted 5, 6, and then a further set of assertions in one session — the seventh being lint rule 6, where the anti-self-certification guard was written into the test harness and not into the command that gates commits. The ninth is #33 (2026-08-11), where **four** batteries ran and the first three each refuted the core predicate, not its edges: the author had verified the guard against the states he had thought of, which is the whole shape restated. The eleventh through fifteenth are all 2026-08-11 (#34, #43, #42, #32, #45) — the fifteenth being the sharpest of them: the new skip was **line-scoped**, which the same step forbids two paragraphs later *with measured evidence from the last time it happened*, so it relabelled a co-located genuine break as intentional. The prose specified the defect. Earlier in that same batch (#34, #43, #42, #32) and were found by four separate review rounds in one session, three of which refuted the round before them — #34's round 2 found two defects that round 1's *fixes* had created. The tenth is #41 (2026-08-11) and is the sharpest yet: the author fixed a wrong-remedy defect in the installer and, in the same commit, wrote the identical wrong remedy into the adopter-facing template — then the correction was itself refuted for excluding the commonest form of the state it described. Fixing a defect does not immunise you against it one file over. Same shape every time: the artifact passes every check its author thought to run, because the author picked the checks and the artifact from one mental model. Two specific rules fall out. **(1) Cross-step contract:** after editing step N, re-read the steps that consume its output — every defect so far lived in the *relationship between* steps, not in any step read alone. **(2) Hostile-repo test:** a command written for other people's repos must be run against a repo that will punish it — one with a committed lockfile, a vendored directory, hundreds of docs. Verifying against this clean repo is a sample of one and has twice certified a command nobody would run. **(3) Seeded true positives, whenever a change makes a check more permissive:** the fourth occurrence (2026-08-06, `audit-context` Step 4) was a loosening justified by 9-of-9 false positives — a sample with *zero* true positives in it, which measures specificity and cannot measure sensitivity at all. A run that finds nothing cannot distinguish a fixed check from a disabled one. Build a fixture containing the failures the check must still catch, and show it still fires. Then run `/review-changes`.
- **State the check before the claim, on any negative.** "0 rows", "not called anywhere", "nothing reads it", "all clean" — a negative cannot distinguish a real absence from a broken instrument, an empty sample, or a mismatched population. Report the claim, the command that produced it, and **what a non-empty result would have looked like**; if you cannot state the shape of a positive, the claim is not ready. This framework had already derived the same rule four times, each scoped to one of its own instruments — *"a rung you cannot run is not a pass"* and *"report what the extractor dropped"* in `templates/audit-context.md`, *"a run that finds nothing cannot distinguish a fixed check from a disabled one"* in the constraint above, and *"report NOT REFUTED only after a thorough attempt"* in `templates/review-changes.md`. Those are this rule applied to the framework; this is the general case, and it bites hardest on the *adopter's* codebase, where the instrument is unfamiliar. Origin: five instances in one adopter session (#35), every one a negative, every one cheap to refute, every refutation run only after the claim was asserted. The mechanism is not carelessness — a partial view is usually sufficient to form an answer, and forming one is cheaper than checking it.

- **An absolute in an instruction is a decision; an absolute in a description is a measurement, and it needs one.** `never edit in place`, `always full depth regardless of size` — prescriptions, fine as absolutes. But *every*, *all*, *none*, *zero*, *cannot*, *not permitted*, *guaranteed* in a claim about how a tool, spec or codebase **behaves** is a measurement, and it ships unmeasured by default. Each such claim needs one of: a measurement with the command and the scope it ran over, a spec citation, or a hedge ("in the cases measured", "for well-formed tables"). Four of the five confident-but-wrong assertions in the 2026-08-10 sweep were universally quantified, and a hedged version of any of them would have been true and cost nothing (#39). The sharpest was *"zero false positives on escaped `\|`, on pipes inside fenced blocks, and on adjacent tables of differing widths"* — it looks like evidence and is not: the three seeded classes were the three the implementation already handled, so the sample contained no case the author had not coded for. That is the mirror image of the seeded-true-positives rule above. **Promoted to `templates/review-changes.md` in v1.25.0, on the evidence its own gate asked for.** It was maintainer-local until 2026-08-12, when this repo shipped `"breaks on prettier 2 and survives prettier 3"` into a normative surface — an absolute in a description, generalised from two isolated one-line tests — **eighteen hours after this constraint was written**. An adopter refuted it by measuring on 3.8.1, a version never tested here. The rule's own subject matter, refuted from outside, on the surface the rule governs. It ships merged with the negatives rule, since they are one failure seen from two sides.

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
│   ├── update-drift.md        <- Drift skill: triage the releases a project is behind; user-global
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
│       ├── provisioning-quote/  <- Seeded drift for lint rule 7 (9 positives, 4 negatives)
│       ├── size-ratchet/       <- Seeded growth for lint rule 8 (4 positives, 4 negatives)
│       ├── verify-runner/       <- Seeded claims + prose for curate's verify runner
│       │                           (32 positives, 10 negatives, 4 malformed, 7 structural,
│       │                            4 timing, 29 ablations)
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
| `tests/lint/size-ratchet.sh` | Lint rule 8 — a ratchet on adopter-facing template sizes; baseline in `size-baseline.tsv`, fixture at `tests/fixtures/size-ratchet/`. **Measures the smaller of the two costs**: a skill body is paid once per invocation and is prompt-cached, while the *read surface* a run consumes is fresh tokens every time and is 4–25× larger. See #46 |
| `tests/lint/provision-quote.sh` | Lint rule 7 — the #42 class: a file that *provisions* a canonical row must quote it, not describe it by category. Rule 6 cannot see it, because the two `audit-context` copies agree with each other while contradicting `templates/project-file.md`. Fixture at `tests/fixtures/provisioning-quote/` |
| `tests/fixtures/installer-release-guard/` | Seeded git states for the installer's release guard (#33). Its README carries the two rejected predicates and why — read before changing the comparison |
| `tests/fixtures/verify-runner/` | Seeded claims and prose for `curate` Step 0 sub-step 5's runner (#34). It extracts the runner from `templates/curate.md` rather than copying it, so it cannot drift. ~90s — the slowest check here, and the only one with timing cases. Its README carries the rejected `\|` predicate and the three review rounds that produced the rest — read before touching the extraction |
| `memory/MEMORY.md` | This repo's in-repo memory index (maintainer-local) |

## How to Work Here

```bash
# Cut a release (per CHANGELOG.md header, issue #14)
git tag vX.Y.Z <commit>
git push --tags

# Check what changed for a downstream adopter pinned at an older version
git diff vX.Y.Z..vX.Y+1.0 -- templates/

# Self-tests, before committing structural changes
bash tests/lint/run.sh                              # eight structural rules
bash tests/fixtures/skill-template-sync/run.sh      # sensitivity of lint rule 6
bash tests/fixtures/reference-integrity/run.sh      # sensitivity of audit-context Step 4
bash tests/fixtures/installer-release-guard/run.sh  # sensitivity of the installer's release guard
bash tests/fixtures/verify-runner/run.sh            # sensitivity of curate's verify runner
bash tests/fixtures/provisioning-quote/run.sh       # sensitivity of lint rule 7
bash tests/fixtures/size-ratchet/run.sh             # sensitivity of lint rule 8

# End a session
/curate     # if installed locally from templates/curate.md

# Monthly check
/audit-context     # if installed locally from templates/audit-context.md
```

## Cross-Repo Evidence

- **Downstream consumer**: [agent-ready-papers](https://github.com/ducroq/agent-ready-papers) (v1.6.3+) — applies this method to academic and structured non-fiction writing. Forward-feedback evidence (audits, DRs, version-impact decisions) lands there first and informs this repo's evolution. agent-ready-papers v1.6.2's in-repo-memory Hard Constraint is the immediate origin of the v1.10.2 dog-food fix here.
- **Adopter projects**: 28+ at last count (see `memory/project_framework_pivot.md` for the 2026-04-14 inventory). Touch templates/ with the awareness that each downstream consumer pins to a specific version and reads `CHANGELOG.md` to decide whether to upgrade.
