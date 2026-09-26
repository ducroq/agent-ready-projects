# Agent-Ready Projects

The source framework that teaches the layered memory method for AI coding agents. Tool-agnostic guide + templates + adopt prompts. Adopters consume `templates/`, `docs/`, and `adopt.md`; the rest is maintainer infrastructure.

- **Type**: Public methodology repo (guide + templates + skills)
- **License**: MIT
- **agent-ready-projects** (this repo): **v1.49.0 is the highest release (2026-09-26).** Next bump **undetermined** — classify it from the diff at release time, per `templates/release.md` Step 2. Record no predicted bump and no size for this file here; both go stale on the next edit.
- **State and lessons**: `memory/MEMORY.md` Current State holds the session narrative and, as its first block, the lessons this repo keeps re-deriving. Per-release detail is in `CHANGELOG.md`.
- **How to shrink this file**: delete duplication and name the authority. Never compress prose, and never re-inline reference material to make it handy.

## Before You Start

| When | Read |
|------|------|
| Starting any session (self drift) | Compare this file's version line against `CHANGELOG.md`. If a newer version has shipped since you last worked here, surface the drift before starting. |
| Installing, moving, or removing a skill | `docs/GUIDE.md` § "Where a skill lives". Verify with `bash scripts/install-global-skills.sh --check ~/repos`. Refresh globals only after the release tag is pushed and verified (`templates/release.md` Step 7); `--force` overrides the installer's refusal, knowingly. |
| Editing a skill — either `templates/<name>.md` or `.claude/skills/<name>/SKILL.md` | **Edit both.** One edited alone is drift. Lint rule 6 catches it; `install-global-skills.sh --check` does not. |
| Closing an issue that was filed against a **skill** | Name the adopter-installed file that changed because of it before writing `Closes #N`. If `git diff -- templates/<skill>.md \| grep -c '<the concept>'` returns 0, it did not ship. |
| Before committing structural changes (CLAUDE.md, `memory/`, `templates/`) | Run `bash tests/lint/run.sh` (catalog and blind spots: `tests/lint/README.md`), then `/review-changes` (tiers from `.claude/review-profile.md`). A green CI tick (`.github/workflows/checks.yml`) is not a review, and the local lint run is stronger: rules 2, 12, 15, 18 and 19 SKIP in CI, and 21 does too while the top CHANGELOG block is a candidate. |
| Picking up where the last session left off — **including a bare "continue", "carry on" or "pick up where we left off"** | `memory/MEMORY.md`. **Read it before doing anything else, and before asking what to work on: the answer is in there.** Nothing else loads it. |
| Editing templates | `templates/README.md` for the tool-agnostic naming map. Changes ripple to every downstream consumer. |
| Editing the guide | `docs/GUIDE.md` is the full reference; `README.md` is the on-ramp. When you change one, check whether the other needs the same change. |
| Working with the verification rationale | `docs/verification-rationale.md`. Cite it rather than re-deriving. Its one external citation supports the premise only, not the principles. |
| Considering reviving landscape / positioning docs | `memory/project_framework_pivot.md`. Don't re-promote without explicit user signal. |
| Considering the dead-end log pattern | `memory/project_dead_end_pattern_rollout.md` — closed. Reopen only when a real session reaches for a seeded entry and acts on it. |
| Cutting a release | Run `/release` if installed locally, per `templates/release.md`; it stops before tagging. Tag-and-push protocol is in the `CHANGELOG.md` header. |
| Starting multi-session work (feature, migration, refactor, investigation) | Create `docs/work-items/<slug>.md` from `templates/work-item.md`. Add a one-line pointer in `memory/MEMORY.md` Current State: `- [Short description] → docs/work-items/slug.md [in progress]`. |
| Resuming work on an existing initiative | Read the work-item file in `docs/work-items/` — the Current Status section is the savepoint. |
| Ending a session | Update any active work-item file's Current Status section (the savepoint). Then run `/curate` if installed locally, per `templates/curate.md`. |
| Monthly or after major restructuring | Run `/audit-context` if installed locally, per `templates/audit-context.md`. |

## Hard Constraints

- **Project state goes in in-repo `memory/`, not in user-level Claude Code auto-memory.** Versions, session narratives and pending threads for this repo belong in `memory/`; `~/.claude/projects/<slug>/memory/` is only for cross-project **user**, **feedback** and **reference** memory. Never duplicate project state into both.
- **Templates and adopter-facing surfaces are normative.** Edits to `templates/`, `adopt.md`, `README.md`, `docs/GUIDE.md` or `docs/verification-rationale.md` are API changes: document them in `CHANGELOG.md` and choose the right semver bump.
- **Respect the v1.10.1 patch-vs-minor precedent.** Documentation-only changes go to PATCH. New templates, patterns or behaviors go to MINOR. Breaking changes that require adopter action go to MAJOR.
- **Don't re-promote the framework wrapper.** The 2026-04-14 positioning decision stands (`memory/project_framework_pivot.md`); maintenance continues, and re-promotion requires explicit user signal.
- **Don't self-certify a procedural artifact.** When you author or edit a multi-step procedure that ships (`templates/release.md`, `templates/curate.md`, `templates/audit-context.md`, `templates/review-changes.md`, `scripts/install-global-skills.sh`, `tests/lint/run.sh`, `tests/lint/skill-sync.sh`), you may not report it ready on your own read. **44 occurrences at last count** <!-- verify: r=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "CANNOT VERIFY: not inside a git repo"; exit 0; }; cd "$r" || { echo "CANNOT VERIFY: cannot enter $r"; exit 0; }; row=$(grep -m1 '^| 2026-08-03 | Author green-lights own procedural artifact' memory/gotcha-log.md); n=$(printf '%s' "$row" | grep -o '\*\*[0-9]\+\*\*' | head -1 | tr -cd '0-9'); m=$(grep -o '[0-9]\+ occurrences at last count' CLAUDE.md | grep -o '^[0-9]\+'); { [ -n "$n" ] && [ -n "$m" ]; } || { echo "CANNOT VERIFY: count not found (log='$n' claude='$m')"; exit 0; }; [ "$n" = "$m" ] && echo "self-certification count agrees at $n" || { echo "CLAUDE.md says $m, gotcha-log Promoted table says $n"; exit 1; } --> — the argument and the running total are the "Author green-lights own procedural artifact" row of the Promoted table in `memory/gotcha-log.md`; re-count against it rather than incrementing here; read it before green-lighting anything on this list. **(1) Cross-step and cross-file contract:** after editing a step, re-read the steps that consume its output and the other files carrying the same construct. **(2) Hostile-repo test:** run a command meant for other people's repos against one that will punish it (a committed lockfile, a vendored directory, hundreds of docs). **(3) Seeded true positives:** when a change makes a check more permissive, show on a fixture that it still catches what it must. Then run `/review-changes`.
- **State the check before the claim, on any negative.** Report "0 rows", "nothing reads it" or "all clean" with the command that produced it and what a non-empty result would have looked like; if you cannot state the shape of a positive, the claim is not ready. Framework-scoped versions are in `templates/audit-context.md` and `templates/review-changes.md`.
- **An absolute in an instruction is a decision; an absolute in a description is a measurement, and it needs one.** *Every*, *all*, *none*, *cannot* or *guaranteed* about how a tool, spec or codebase behaves needs a measurement with its command and scope, a spec citation, or a hedge. Seeds drawn from cases the implementation already handles are not a measurement; the account is in `docs/rationale/review-changes.md`.
- **A user-global skill shadows a project-local one of the same name — in Claude Code** (the local copy is silently never loaded) (other tools differ; see `docs/GUIDE.md` § "Where a skill lives"). So `release` and `test-verify-memory` stay project-local while `curate`, `audit-context`, `update-drift` and `review-changes` ship global, and a global install is always derived from tracked `.claude/skills/` via `scripts/install-global-skills.sh`, never authored in `~/.claude/`.
- **Lead with the point; one or two lines.** The answer first, then stop. Side findings go in a short list or get dropped; no recaps, no restated decisions, no numbers nothing reads — in files as much as in replies.
- **Tool-agnostic in adopter-facing content.** `README.md`, `adopt.md`, `templates/` and `docs/GUIDE.md` must not assume Claude Code. Maintainer infrastructure (this file, `memory/`, `.claude/`) can be Claude-specific.

## Architecture

Orientation only: each file's own header, README or runner comment is the authority on what it does.

```
agent-ready-projects/
├── .claude/                   <- Gitignored except two tracked children
│   ├── skills/                <- Reference installs; globals derive from here
│   └── review-profile.md      <- This repo's review tiers
├── README.md                  <- Public-facing on-ramp
├── adopt.md                   <- Agent prompts: assess / adopt / update
├── CHANGELOG.md               <- Release notes; release process at top
├── CLAUDE.md                  <- This file
├── LICENSE                    <- MIT
├── docs/
│   ├── GUIDE.md               <- Full reference
│   ├── verification-rationale.md
│   ├── seeded-defects-and-ablations.md   <- Adopter-facing
│   ├── rationale/             <- Why a skill says what it says
│   ├── guide/                 <- Visual walkthrough
│   ├── work-items/            <- Per-work-item context files
│   └── archive/               <- Archived positioning docs
├── templates/                 <- What adopters install; map in templates/README.md
│   ├── project-file.md        <- Layer 1
│   ├── RUNBOOK.md             <- Layer 2
│   ├── memory-index.md        <- Layer 3 index
│   ├── gotcha-log.md          <- Layer 4
│   ├── coordination.md        <- Layer 5 (multi-contributor)
│   ├── curate.md, audit-context.md, review-changes.md, release.md, update-drift.md
│   │                          <- The five skills (plus review-profile.md)
│   └── hypothesis-log.md, work-item.md, adr.md, review-agent.md, test-verify-memory.md,
│       test-fixtures/, checklists/, README.md
├── scripts/install-global-skills.sh  <- Install/verify global skills
├── scripts/verify-runner.sh    <- Claim checker for verify probes
├── .github/workflows/checks.yml      <- CI: lint + fixtures
├── tests/                     <- Self-tests; read a fixture's README before loosening it
│   ├── lint/                  <- Structural rules; catalog in tests/lint/README.md
│   └── fixtures/              <- Seeded-defect fixtures, one dir per check.
│                                 reference-integrity/refcheck.py is what adopters run
│                                 for audit-context Step 4, so a fix there ships to them
└── memory/                    <- Session memory (gitignored)
    ├── MEMORY.md              <- Index + current state
    └── project_*.md           <- Topic files
```

## What is intentionally not shipped

These paths exist in the maintainer's local clone but are gitignored — they are *not* in the public repo:

| Path | What it holds | For adopters |
|------|---------------|--------------|
| `.claude/settings*.json` | Maintainer Claude Code config | Not needed. Two `.claude/` children are tracked: `.claude/skills/` and `.claude/review-profile.md` — write your own profile |
| `memory/MEMORY.md` | Index of current project state | Build your own per the templates |
| `memory/project_*.md` | Topic files | Build your own as needed |
| `memory/gotcha-log.md`, `memory/hypothesis-log.md`, `memory/review-ledger.tsv` | Layer-4 journal, provisional positions, review-cost ledger; cited above but not in your clone | Build your own from `templates/gotcha-log.md` and `templates/hypothesis-log.md` |

The public framework — `README.md`, `adopt.md`, `docs/`, `templates/`, `CHANGELOG.md`, `LICENSE` — is fully consumable without any of the above.

`memory/` stays gitignored: it holds private project names that lint rule 12 never scans, so check what is inside before tracking it. It has its own local-only git history, never pushed. Use `git -C memory log` before asserting how an entry or heading got that way.

## Key Paths

<!-- Per templates/project-file.md: 10-15 files, a few words each. Do not re-annotate. -->

| Path | What it is |
|------|-----------|
| `README.md` | Public-facing on-ramp |
| `adopt.md` | The three agent-facing prompts |
| `docs/GUIDE.md` | Full reference |
| `CHANGELOG.md` | Release notes; maintainer release process at top |
| `templates/` | Everything an adopter installs |
| `templates/README.md` | Tool-agnostic naming map — authority on install paths |
| `docs/rationale/` | Why a skill says what it says |
| `scripts/install-global-skills.sh` | Install, verify, and scan an estate for inert copies |
| `tests/lint/run.sh` | The structural rules; catalog in `tests/lint/README.md` |
| `tests/run-fixtures.sh` | Every sensitivity fixture; its header lists what it refuses to do silently |
| `.claude/review-profile.md` | This repo's review tiers |
| `memory/MEMORY.md` | In-repo memory index (maintainer-local) |

## How to Work Here

```bash
# Cut a release (per CHANGELOG.md header)
git tag vX.Y.Z <commit>
git push --tags

# Check what changed for a downstream adopter pinned at an older version
git diff vX.Y.Z..vX.Y+1.0 -- templates/

# Self-tests, before committing structural changes
bash tests/lint/run.sh                              # structural rules; some SKIP in CI
bash tests/run-fixtures.sh                          # every fixture under tests/fixtures/
bash tests/fixtures/<name>/run.sh                   # one suite, while iterating on it

# Score a review config against seeded defects (no pass/fail; not in the suite)
bash tests/fixtures/review-bench/build.sh /tmp/rb
bash tests/fixtures/review-bench/score.sh <findings-file> seeded

# End a session
/curate     # if installed locally from templates/curate.md

# Monthly check
/audit-context     # if installed locally from templates/audit-context.md
```

## Cross-Repo Evidence

- **Downstream consumer**: [agent-ready-papers](https://github.com/ducroq/agent-ready-papers) (v1.6.3+) — applies this method to academic and structured non-fiction writing. Forward-feedback evidence lands there first and informs this repo's evolution.
- **Adopter projects**: 28+ at last count (`memory/project_framework_pivot.md`). Each pins a version and reads `CHANGELOG.md` to decide whether to upgrade.
