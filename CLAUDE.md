# Agent-Ready Projects

The source framework that teaches the layered memory method for AI coding agents. Tool-agnostic guide + templates + adopt prompts. Adopters consume `templates/`, `docs/`, and `adopt.md`; the rest is maintainer infrastructure.

- **Type**: Public methodology repo (guide + templates + skills)
- **License**: MIT
- **agent-ready-projects** (this repo): **v1.44.0 is the highest release (2026-09-14), tagged and pushed.** Next bump **undetermined** — classify it from the diff at release time, per `templates/release.md` Step 2. ⚠️ This line said *proposed next bump MINOR* through the release that shipped one: a standing prediction about the next release is stale from the moment the current one ships, and nothing re-reads it. Session narrative lives in `memory/MEMORY.md` Current State; per-release detail in `CHANGELOG.md`. **The eight measured lessons this repo keeps re-deriving — the through-line — are the first block of `memory/MEMORY.md` Current State**, which the Before You Start table routes you to on pickup. ⚠️ **No size is recorded here** — a size claim about this file goes stale on the next edit *to this file*. Re-derive: `{ wc -m CLAUDE.md; wc -m "$HOME/.claude/projects/<slug>/memory/MEMORY.md"; }`. **Two budgets, and they are measured in different units:** `templates/audit-context.md` Step 1 flags *this file* over 35,000 / 40,000 in **bytes**; the cap that bit here is 40,000 on the **auto-loaded set**, in characters, which this file alone was always under. `wc -c` reads ~2% high against `wc -m`. Two instruments for one number, and that is **not settled** — file it, do not resolve it in passing. **The method is deleting duplication, never compressing prose**: three blocks of this file were reclaimed on 2026-09-13 and 2026-09-14 by finding the copy and naming the authority instead. Every one of those duplicates had rotted — the copy of `reference-integrity`'s T/N commands kept here returned 38/35 against a true 40/37, and the copy of rule 11's span in this file was right while `tests/lint/README.md` was wrong. **Do not re-inline reference material to make it handy; that is how this file got here.**

> Live project state (current threads, deferred items, surfaced patterns) lives in `memory/MEMORY.md` (maintainer-local — see *What is intentionally not shipped* below). Release notes live in `CHANGELOG.md`.

## Before You Start

| When | Read |
|------|------|
| Starting any session (self drift) | Compare the `agent-ready-projects: vX.Y.Z` line in this file's header against `CHANGELOG.md`. If a newer version has shipped since you last worked here, surface the drift before starting. |
| Installing, moving, or removing a skill | `docs/GUIDE.md` § "Where a skill lives" — global shadows local, so scope is exclusive. Run `bash scripts/install-global-skills.sh --check ~/repos` to verify the global install matches the tracked source and no inert local copies remain. **The install path refuses when the bytes it would copy are not what the highest release tag reachable from HEAD holds** (#33): refresh globals after the tag is pushed *and verified*, per `templates/release.md` Step 7 — a local tag satisfies the guard, so tagging alone is not the safe point. `--force` overrides it, knowingly. |
| Editing a skill — either `templates/<name>.md` or `.claude/skills/<name>/SKILL.md` | **Edit both.** One artifact in two files; an edit to one is drift until the other matches. `install-global-skills.sh --check` cannot see it (it compares the global install to the tracked one, so both read as current while diverging from the template). `bash tests/lint/run.sh` rule 6 is what catches it. |
| Closing an issue that was filed against a **skill** | **Name the adopter-installed file that changed because of it**, before writing `Closes #N` anywhere. `git diff -- templates/<skill>.md \| grep -c '<the concept>'` returning 0 is the check, and it is the whole rule. Maintainer-local on purpose — it is a question, not a check. **`memory/hypothesis-log.md` H-015 carries the origin, every instance, and the terms it ships or dies on (#92), and is currently DUE.** |
| Before committing structural changes (CLAUDE.md, `memory/`, `templates/`) | Run `bash tests/lint/run.sh` — thirteen deterministic structural rules; **`tests/lint/README.md` is the catalog and states what each rule cannot see.** **CI runs it and `bash tests/run-fixtures.sh` on every push and PR** (`.github/workflows/checks.yml`, #115), so a green tick is available to be mistaken for a review: it is not one, `/review-changes` still is. Two rules SKIP in CI and cannot do otherwise — rule 2 has no `memory/` to read, rule 12 has no name list — so **the local run is the stronger one**, and the skips print to the run summary rather than folding into the pass. Then run `/review-changes` for diff-driven LLM review: tiers from `.claude/review-profile.md` (v1.40.0), size gate from the skill; with no profile it stops rather than defaulting to LOW. |
| Picking up where the last session left off — **including a bare "continue", "carry on" or "pick up where we left off", which is the maintainer's normal way to start** | `memory/MEMORY.md` — the index itself. **Read it before doing anything else, and before asking what to work on: the answer is in there.** Nothing loads it automatically; this row is what reaches it. Its Current State section names the open branches, what each review found, and the next steps in order. Topic files in `memory/` stay on demand, per the index's own table. |
| Editing templates | `templates/README.md` for the tool-agnostic naming map. Templates are the adopter-facing surface; changes ripple to every downstream consumer. |
| Editing the guide | `docs/GUIDE.md` is the full reference; `README.md` is the on-ramp. Keep them in sync — when you change one, ask whether the other needs the same change. |
| Working with the verification rationale | `docs/verification-rationale.md` (v1.10.1; external-corroboration section v1.27.0) — three structural principles, each with a decision rule. Cite it rather than re-deriving. **Its one external citation is scoped to the premise**, not to whether the principles are right, and the doc says so inline. |
| Considering reviving landscape / positioning docs | `memory/project_framework_pivot.md` — 2026-04-14 wrapper-archive decision still stands for positioning. Don't re-promote without explicit user signal. |
| Considering the dead-end log pattern | `memory/project_dead_end_pattern_rollout.md` — **CLOSED 2026-08-03** as silent-abandonment-confirmed (#16). The idea isn't refuted, the validation evidence was. Don't re-open on enthusiasm — only on an actual session reaching for a seeded entry and acting on it. |
| Cutting a release | Run `/release` if installed locally, per `templates/release.md` — it classifies the bump, runs the preconditions, drafts the changelog entry, and stops before tagging. Tag-and-push protocol and the maintainer process are in the `CHANGELOG.md` header (#14). |
| Starting multi-session work (feature, migration, refactor, investigation) | Create `docs/work-items/<slug>.md` from `templates/work-item.md`. Add a one-line pointer in `memory/MEMORY.md` Current State: `- [Short description] → docs/work-items/slug.md [in progress]`. |
| Resuming work on an existing initiative | Read the work-item file in `docs/work-items/` — the Current Status section is the savepoint. |
| Ending a session | Update any active work-item file's Current Status section (the savepoint). Then run `/curate` if installed locally — the framework's own skill, per `templates/curate.md`. |
| Monthly or after major restructuring | Run `/audit-context` if installed locally — structural health check per `templates/audit-context.md`. |

## Hard Constraints

- **Project state goes in in-repo `memory/`, not in user-level Claude Code auto-memory.** Versions, session narratives, pending threads, paused patterns, and anything tied to *this* repo's work belong in this repo's `memory/`. The user-level path at `~/.claude/projects/<slug>/memory/` is reserved for cross-project memory types: **user**, **feedback**, **reference**. The Before You Start table above routes to in-repo memory; that's the canonical pickup path. Don't duplicate project state into both — drift starts as soon as you do. (Origin: agent-ready-papers v1.6.2, 2026-06-08; same rule applied here in v1.10.2, 2026-06-09 — closes #17.)
- **Templates and adopter-facing surfaces are normative.** Changes to `templates/`, `adopt.md`, `README.md`, `docs/GUIDE.md`, or `docs/verification-rationale.md` affect every downstream consumer. Treat edits there with the gravity of an API change: document in `CHANGELOG.md` and choose the right semver bump.
- **Respect the v1.10.1 patch-vs-minor precedent.** Documentation-only changes (rationale docs, clarifications, cross-references) go to PATCH. New templates, new patterns, new behaviors go to MINOR. Breaking changes that require adopter action go to MAJOR.
- **Don't re-promote the framework wrapper.** The 2026-04-14 pivot decision (see `memory/project_framework_pivot.md`) still stands for *positioning*. Maintenance and incremental evolution continue (v1.9.0, v1.10.0, v1.10.1, v1.10.2 all postdate the pivot). Re-promotion is a different decision and requires explicit user signal.
- **Don't self-certify a procedural artifact.** When you author or edit a multi-step procedure that ships (`templates/release.md`, `templates/curate.md`, `templates/audit-context.md`, `templates/review-changes.md`, `scripts/install-global-skills.sh`, `tests/lint/run.sh`, `tests/lint/skill-sync.sh`), you may not report it ready on your own read. **31 occurrences at last count** <!-- verify: r=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "CANNOT VERIFY: not inside a git repo"; exit 0; }; cd "$r" || { echo "CANNOT VERIFY: cannot enter $r"; exit 0; }; row=$(grep -m1 '^| 2026-08-03 | Author green-lights own procedural artifact' memory/gotcha-log.md); n=$(printf '%s' "$row" | grep -o '\*\*[0-9]\+\*\*' | head -1 | tr -cd '0-9'); m=$(grep -o '[0-9]\+ occurrences at last count' CLAUDE.md | grep -o '^[0-9]\+'); { [ -n "$n" ] && [ -n "$m" ]; } || { echo "CANNOT VERIFY: count not found (log='$n' claude='$m')"; exit 0; }; [ "$n" = "$m" ] && echo "self-certification count agrees at $n" || { echo "CLAUDE.md says $m, gotcha-log Promoted table says $n"; exit 1; } --> — the number is a digit so it can be checked, and the probe above is what checks it. ⚠️ **The running total, every date, and what each battery refuted are the "Author green-lights own procedural artifact" row of the Promoted table in `memory/gotcha-log.md`. That row is the argument: re-count against it rather than incrementing here, and read it before green-lighting anything on this list.** Same shape every time: the artifact passes every check its author thought to run, because the author picked the checks and the artifact from one mental model. Three rules fall out. **(1) Cross-step and cross-file contract:** after editing step N, re-read the steps that consume its output *and* the other files carrying the same construct — most defects here lived in the *relationship between* steps, and **fixing a defect does not immunise you against it one file over** (#41). **(2) Hostile-repo test:** a command written for other people's repos must be run against a repo that will punish it — a committed lockfile, a vendored directory, hundreds of docs. This clean repo is a sample of one and has twice certified a command nobody would run. **(3) Seeded true positives, whenever a change makes a check more permissive:** a run that finds nothing cannot distinguish a fixed check from a disabled one, and a sample of false positives measures specificity and cannot measure sensitivity at all. Build a fixture holding the failures the check must still catch, and show it still fires. Then run `/review-changes`.
- **State the check before the claim, on any negative.** "0 rows", "not called anywhere", "nothing reads it", "all clean" — a negative cannot distinguish a real absence from a broken instrument, an empty sample, or a mismatched population. Report the claim, the command that produced it, and **what a non-empty result would have looked like**; if you cannot state the shape of a positive, the claim is not ready. It bites hardest on the *adopter's* codebase, where the instrument is unfamiliar. The mechanism is not carelessness — a partial view is usually sufficient to form an answer, and forming one is cheaper than checking it. (Origin #35. The framework-scoped versions this generalises are in `templates/audit-context.md` and `templates/review-changes.md`.)

- **An absolute in an instruction is a decision; an absolute in a description is a measurement, and it needs one.** `never edit in place` is a prescription and fine as an absolute. But *every*, *all*, *none*, *zero*, *cannot*, *guaranteed* in a claim about how a tool, spec or codebase **behaves** is a measurement, and it ships unmeasured by default. Each such claim needs one of: a measurement with the command and the scope it ran over, a spec citation, or a hedge ("in the cases measured", "for well-formed tables"). ⚠️ **A seeded sample is not a measurement when the seeds are the cases the implementation already handles** — the mirror image of the seeded-true-positives rule above. Promoted to `templates/review-changes.md` in v1.25.0 on the evidence its own gate asked for, then refuted on its own subject matter from outside eighteen hours later; the account is in `docs/rationale/review-changes.md` (#39). It ships merged with the negatives rule, since they are one failure seen from two sides.

- **A user-global skill shadows a project-local one of the same name — in Claude Code.** `~/.claude/skills/<name>/` wins; the project-local file is never loaded, never merged, never warned about. ⚠️ **The mechanism is tool-specific — Cursor merges and Copilot combines non-deterministically — and this line stated exclusivity as general until 2026-09-05 (#129).** `docs/GUIDE.md` § "Where a skill lives" carries the per-tool table. Two consequences follow from exclusivity and are normative here. **(1)** Installing a skill globally forecloses per-repo variants of that name — so `release` and `test-verify-memory` stay project-local; `curate`, `audit-context`, `update-drift`, and `review-changes` (global since v1.40.0) ship global. **(2)** A global install must be *derived* from this repo's tracked `.claude/skills/`, never authored in `~/.claude/` — that directory is not a repository, so a skill living only there has no history, no review, and no restore path. Run `scripts/install-global-skills.sh` to install or verify; `--check <root>` also finds inert project-local copies. (Origin 2026-08-06, in `memory/gotcha-log.md`.)
- **Tool-agnostic in adopter-facing content.** This repo serves Claude Code, Codex, Cursor, Windsurf, GitHub Copilot, Aider, and others. Public-facing material (`README.md`, `adopt.md`, `templates/`, `docs/GUIDE.md`) must not assume Claude Code. Maintainer infrastructure (this file, `memory/`, `.claude/`) can be Claude-specific.

## Architecture

⚠️ **Orientation only — where things live.** Each file's own header, README or runner
comment is the authority on what it does and why; a second copy here rots (the `tests/`
block once kept `reference-integrity`'s count commands and returned 38/35 against a true
40/37). Do not re-annotate this tree to make something handy.

```
agent-ready-projects/
├── .claude/                   <- Gitignored EXCEPT two tracked children (`git ls-files .claude/`)
│   ├── skills/                <- Reference installs — the source a global install derives from
│   └── review-profile.md      <- THIS repo's review tiers (v1.40.0); every repo writes its own
├── README.md                  <- The guide (public-facing on-ramp)
├── adopt.md                   <- Three agent-facing prompts: assess / adopt / update
├── CHANGELOG.md               <- Versioned release notes; maintainer release process at top
├── CLAUDE.md                  <- This file (agent orientation, maintainer-local but committed)
├── LICENSE                    <- MIT
├── docs/
│   ├── GUIDE.md               <- Full reference
│   ├── verification-rationale.md
│   ├── seeded-defects-and-ablations.md   <- Adopter-facing, linked from README + GUIDE (#130)
│   ├── rationale/             <- WHY a skill says what it says — superseded drafts and the
│   │                             measurements that refuted them, kept OUT of the skill bodies.
│   │                             Nothing is duplicated: a claim in both means one is wrong
│   ├── guide/                 <- Four-page visual walkthrough
│   ├── work-items/            <- Per-work-item context files (v1.11.0)
│   └── archive/               <- LANDSCAPE / COMPARISON / METHODOLOGY (per 2026-04-14 pivot)
├── templates/                 <- Tool-agnostic starter files adopters consume; naming map in
│   │                             templates/README.md, which is the authority on install paths
│   ├── project-file.md        <- Layer 1
│   ├── RUNBOOK.md             <- Layer 2
│   ├── memory-index.md        <- Layer 3 index
│   ├── gotcha-log.md          <- Layer 4
│   ├── coordination.md        <- Layer 5 (multi-contributor)
│   ├── curate.md, audit-context.md, review-changes.md, release.md, update-drift.md
│   │                          <- The five skills. review-profile.md is the per-repo half of
│   │                             review-changes (v1.40.0), installed at .claude/review-profile.md
│   └── hypothesis-log.md, work-item.md, adr.md, review-agent.md, test-verify-memory.md,
│       test-fixtures/, checklists/, README.md
├── scripts/install-global-skills.sh
│                              <- Install + verify user-global skills; scan an estate for inert
│                                 copies. Refuses a tree that is not at a release tag (#33)
├── .github/workflows/checks.yml
│                              <- CI (#115): lint + every fixture, push and PR, no path filters.
│                                 Its own header carries what it does NOT check
├── tests/                     <- Self-tests for this repo
│                                 ⚠️ READ THE FILE BEFORE LOOSENING ANYTHING: rejected predicates,
│                                 constructed-vs-bitten rows and read-before-loosening warnings
│                                 live in each fixture's README.md or its runner's header, never
│                                 here. Per-fixture case digits are deliberately absent (#93)
│   ├── lint/                  <- Thirteen deterministic structural rules, no LLM.
│   │                             ⚠️ tests/lint/README.md is the rule catalog — what each rule
│   │                             catches, AND what it cannot see. Nothing here restates it
│   └── fixtures/              <- Seeded-defect fixtures, one dir per check: a check that finds
│                                 nothing HERE is failing. tests/run-fixtures.sh enumerates them,
│                                 so the directory listing is the current list. Two are special:
│                                 reference-integrity/ (refcheck.py IS audit-context Step 4's
│                                 runtime since v1.40.0, so a fix there reaches adopters — #185)
│                                 and review-bench/ (scores a REVIEW CONFIG, not a checker; no
│                                 pass/fail, recall is a LOWER BOUND — H-016)
└── memory/                    <- Session memory (gitignored — maintainer-local)
    ├── MEMORY.md              <- Index + current state
    └── project_*.md           <- Topic files (migrated 2026-06-09 from user-level)
```

## What is intentionally not shipped

These paths exist in the maintainer's local clone but are gitignored — they are *not* in the public repo:

| Path | What it holds | For adopters |
|------|---------------|--------------|
| `.claude/settings*.json` | Maintainer Claude Code config | Not needed. **Two children of `.claude/` ARE shipped and tracked** (`git ls-files .claude/` is the check): `.claude/skills/`, the source a user-global install derives from, and `.claude/review-profile.md`, THIS repo's review tiers — you write your own, you do not inherit these (see Hard Constraints) |
| `memory/MEMORY.md` | Maintainer's index of current project state | Not needed — your own adoption builds its own per the templates |
| `memory/project_*.md` | Maintainer's topic files | Build your own as your project accumulates them |
| `memory/gotcha-log.md`, `memory/hypothesis-log.md`, `memory/review-ledger.tsv` | Layer-4 journal, provisional positions, review-cost ledger. ⚠️ **Cited by the Hard Constraints above and not in your clone** — the row above does not glob them, and `git ls-files memory/` returns 0 | Build your own from `templates/gotcha-log.md` and `templates/hypothesis-log.md` |

The public framework — `README.md`, `adopt.md`, `docs/`, `templates/`, `CHANGELOG.md`, `LICENSE` — is fully consumable without any of the above. The point of in-repo `memory/` for the maintainer is the same as the point of in-repo `memory/` for any adopter: project state co-located with the code it describes.

Listed here so the architecture diagram above is honest about what an adopter sees on `git clone` versus what the maintainer has on disk.

⚠️ **`memory/` has its own local-only git history** (2026-09-14) — `git -C memory log`, never pushed, no remote. It stays gitignored here: **11 of the 34 names rule 12 checks appear somewhere under it** (the list holds 38; four are UNCHECKED as too short), and lint rule 12 has never scanned any of it, because ignored files are not in its population. The history exists because *how did this log change over time* was unanswerable — which blocked #178's own verification and left unrunnable the arithmetic gate that would have settled #180's temporal half, while the adopter who filed #178 could answer it because theirs is tracked. **Use it before asserting anything about how an entry or a heading got that way.**

## Key Paths

<!-- Per templates/project-file.md: the 10-15 files an agent most often needs, a few
     words each. This table had grown into a second annotated catalog of the
     Architecture tree above and of tests/lint/README.md, and two of its rows had
     rotted (it said run-fixtures.sh refuses THREE silences; the script says four).
     Deleted back to its prescribed form 2026-09-14. Each file's own header is the
     authority on what it does — do not re-annotate here. -->

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
| `tests/lint/run.sh` | The thirteen structural rules; catalog in `tests/lint/README.md` |
| `tests/run-fixtures.sh` | Every sensitivity fixture; its header lists what it refuses to do silently |
| `.claude/review-profile.md` | This repo's review tiers |
| `memory/MEMORY.md` | In-repo memory index (maintainer-local) |

## How to Work Here

```bash
# Cut a release (per CHANGELOG.md header, issue #14)
git tag vX.Y.Z <commit>
git push --tags

# Check what changed for a downstream adopter pinned at an older version
git diff vX.Y.Z..vX.Y+1.0 -- templates/

# Self-tests, before committing structural changes
bash tests/lint/run.sh                              # thirteen structural rules (12 SKIPS without a local name list)
bash tests/run-fixtures.sh                          # EVERY sensitivity fixture, 2m12s measured (112s of it verify-runner).
                                                    # Enumerates tests/fixtures/, so a suite added tomorrow runs
                                                    # tonight; a dir with no run.sh FAILS unless declared not-a-gate
bash tests/fixtures/<name>/run.sh                   # one suite, while iterating on it

# Measure a REVIEW rather than a checker (H-016). Not part of the suite — it has
# no pass/fail; it scores a review config against seeded defects.
bash tests/fixtures/review-bench/build.sh /tmp/rb
bash tests/fixtures/review-bench/score.sh <findings-file> seeded

# End a session
/curate     # if installed locally from templates/curate.md

# Monthly check
/audit-context     # if installed locally from templates/audit-context.md
```

## Cross-Repo Evidence

- **Downstream consumer**: [agent-ready-papers](https://github.com/ducroq/agent-ready-papers) (v1.6.3+) — applies this method to academic and structured non-fiction writing. Forward-feedback evidence (audits, DRs, version-impact decisions) lands there first and informs this repo's evolution. agent-ready-papers v1.6.2's in-repo-memory Hard Constraint is the immediate origin of the v1.10.2 dog-food fix here.
- **Adopter projects**: 28+ at last count (see `memory/project_framework_pivot.md` for the 2026-04-14 inventory). Touch templates/ with the awareness that each downstream consumer pins to a specific version and reads `CHANGELOG.md` to decide whether to upgrade.
