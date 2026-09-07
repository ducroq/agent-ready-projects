# Agent-Ready Projects

The source framework that teaches the layered memory method for AI coding agents. Tool-agnostic guide + templates + adopt prompts. Adopters consume `templates/`, `docs/`, and `adopt.md`; the rest is maintainer infrastructure.

- **Type**: Public methodology repo (guide + templates + skills)
- **License**: MIT
- **agent-ready-projects** (this repo): **v1.39.0 is the highest release (2026-09-07), tagged and pushed.** Proposed next bump **MINOR**. Session narrative lives in `memory/MEMORY.md` Current State; per-release detail in `CHANGELOG.md`. **The eight measured lessons this repo keeps re-deriving — the through-line — are the first block of `memory/MEMORY.md` Current State**, which the Before You Start table already routes you to on pickup. They were inlined here until 2026-09-06. List-ifying it reclaimed 771 characters and the **set was still 41,048 against a 40,000 hard cap**, so it moved out entirely. ⚠️ **No current size is recorded here** — a size claim about this file goes stale on the next edit *to this file* (bullet 7 of the list being relocated). Measure, in characters — `wc -c` is bytes and reads ~2% high: `{ wc -m CLAUDE.md; wc -m "$HOME/.claude/projects/<slug>/memory/MEMORY.md"; }`. **Two budgets:** `templates/audit-context.md` flags *this file* over 35,000 (soft) / 40,000 (hard); the cap that bit here is 40,000 on the **auto-loaded set**, which this file alone was under the whole time. ⚠️ This file is over the 35,000 soft flag — known debt, and `/audit-context` will say so.

> Live project state (current threads, deferred items, surfaced patterns) lives in `memory/MEMORY.md` (maintainer-local — see *What is intentionally not shipped* below). Release notes live in `CHANGELOG.md`.

## Before You Start

| When | Read |
|------|------|
| Starting any session (self drift) | Compare the `agent-ready-projects: vX.Y.Z` line in this file's header against `CHANGELOG.md`. If a newer version has shipped since you last worked here, surface the drift before starting. |
| Installing, moving, or removing a skill | `docs/GUIDE.md` § "Where a skill lives" — global shadows local, so scope is exclusive. Run `bash scripts/install-global-skills.sh --check ~/repos` to verify the global install matches the tracked source and no inert local copies remain. **The install path refuses when the bytes it would copy are not what the highest release tag reachable from HEAD holds** (#33): refresh globals after the tag is pushed *and verified*, per `templates/release.md` Step 7 — a local tag satisfies the guard, so tagging alone is not the safe point. `--force` overrides it and is the right call only when you mean to run an unreleased skill knowingly. |
| Editing a skill — either `templates/<name>.md` or `.claude/skills/<name>/SKILL.md` | **Edit both.** They are one artifact in two files; an edit to one is drift until the other matches. `install-global-skills.sh --check` cannot see this — it compares the global install to the tracked one, so both read as current while diverging from the template. `bash tests/lint/run.sh` rule 6 is what catches it. |
| Closing an issue that was filed against a **skill** | **Name the adopter-installed file that changed because of it**, before writing `Closes #N` anywhere. `git diff -- templates/<skill>.md \| grep -c '<the concept>'` returning 0 is the check, and it is the whole rule. v1.28.0 fixed #54/#55/#56 — three issues filed from adopter runs of `audit-context` — entirely inside `tests/fixtures/reference-integrity/refcheck.py`, which is an *oracle*: not normative, never installed, and its own header says so. Lint rule 6 saw nothing (both skill copies were unchanged, so they agreed perfectly), the fixture suite saw nothing (it points at the oracle, which is where the fix was), nine seeded cases passed, and two review rounds missed it. **Maintainer-local on purpose** — it is a question, not a check, and it has one instance; H-015 tracks the next ten issue-closing changes, after which it ships to `templates/` or gets deleted rather than kept for the look of the thing (#92). |
| Before committing structural changes (CLAUDE.md, `memory/`, `templates/`) | Run `bash tests/lint/run.sh` — deterministic structural check, thirteen rules. **CI runs it and `bash tests/run-fixtures.sh` on every push and PR** (`.github/workflows/checks.yml`, #115), so a green tick is now available to be mistaken for a review: it is not one, `/review-changes` still is. Two rules SKIP in CI and cannot do otherwise — rule 2 has no `memory/` to read and rule 12 has no name list — so **the local run is the stronger one**, and the skips are printed to the run summary rather than folded into the pass. Catches stale `CLAUDE.md` path references, `memory/MEMORY.md` orphans, broken skill-template frontmatter, a reference install that cannot register, unclosed YAML frontmatter, template↔install drift, a skill that provisions a canonical row without quoting it, adopter-facing templates growing unmeasured, and a bare `$0`–`$9` in a skill body (which the argument substituter eats — #77). Rule 11 parses every fenced bash block an adopter might copy: `review-changes` Step 1.5 was a shell syntax error for eight releases and nothing here could see it, because rule 6 compares two copies carrying the same defect and every internal run transcribed the awk rather than copying the block (#105). See `tests/lint/README.md` for the rule catalog. Then run `/review-changes` for diff-driven LLM review — picks review lenses from what changed *and* how big it is (templates touched → full battery, unless the diff is small and hits no carve-out; docs-only → adversarial + doc-accuracy). |
| Picking up where the last session left off — **including a bare "continue", "carry on" or "pick up where we left off", which is the maintainer's normal way to start** | `memory/MEMORY.md` — the index itself. **Read it before doing anything else, and before asking what to work on: the answer is in there.** Nothing loads it automatically; this row is what reaches it. Its Current State section names the open branches, what each review found, and the next steps in order. Topic files in `memory/` stay on demand, per the index's own table. |
| Editing templates | `templates/README.md` for the tool-agnostic naming map. Templates are the adopter-facing surface; changes ripple to every downstream consumer. |
| Editing the guide | `docs/GUIDE.md` is the full reference; `README.md` is the on-ramp. Keep them in sync — when you change one, ask whether the other needs the same change. |
| Working with the verification rationale | `docs/verification-rationale.md` (principles from v1.10.1; external-corroboration section added v1.27.0) — the three structural principles, each with a decision rule. Cite the rationale doc rather than re-deriving. **Its one external citation is scoped to the premise**: it says nothing about whether the principles are right, and the doc says so inline. |
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
- **Don't self-certify a procedural artifact.** When you author or edit a multi-step procedure that ships (`templates/release.md`, `templates/curate.md`, `templates/audit-context.md`, `templates/review-changes.md`, `scripts/install-global-skills.sh`, `tests/lint/run.sh`, `tests/lint/skill-sync.sh`), you may not report it ready on your own read. **28 occurrences at last count** <!-- verify: r=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "CANNOT VERIFY: not inside a git repo"; exit 0; }; cd "$r" || { echo "CANNOT VERIFY: cannot enter $r"; exit 0; }; row=$(grep -m1 'Author green-lights own procedural artifact' memory/gotcha-log.md); n=$(printf '%s' "$row" | grep -o '\*\*[0-9]\+\*\*' | head -1 | tr -cd '0-9'); m=$(grep -o '[0-9]\+ occurrences at last count' CLAUDE.md | grep -o '^[0-9]\+'); { [ -n "$n" ] && [ -n "$m" ]; } || { echo "CANNOT VERIFY: count not found (log='$n' claude='$m')"; exit 0; }; [ "$n" = "$m" ] && echo "self-certification count agrees at $n" || { echo "CLAUDE.md says $m, gotcha-log Promoted table says $n"; exit 1; } --> — the number is a digit so it can be checked, and the probe above is what checks it. It resolves the repo root via `git rev-parse` rather than trusting the caller's cwd; run from outside any repo it reports CANNOT VERIFY naming that cause, which the runner escalates to `NOTHING PRODUCED A VERDICT` and exit 2. It cannot do better, for the reason `templates/curate.md` sub-step 5 gives where it tells you to run the runner from the repo root. This line had lagged `memory/gotcha-log.md` three times before the probe existed, and lagged again within a minute of the 2026-08-17 increment — caught by the probe on the same `/curate` run that made the change, which is the whole argument for the probe. ⚠️ **Every occurrence — the date, the artifact, and what each battery refuted — is the "Author green-lights own procedural artifact" row of the Promoted table in `memory/gotcha-log.md`. That row is the running total and it is the argument; re-count against it rather than incrementing here, and read it before green-lighting anything on this list. The instances used to sit inline; the cap bought that space, so the case for this rule is now one read away instead of in front of you.** Same shape every time: the artifact passes every check its author thought to run, because the author picked the checks and the artifact from one mental model. Three specific rules fall out. **(1) Cross-step and cross-file contract:** after editing step N, re-read the steps that consume its output — most defects so far lived in the *relationship between* steps, not in any step read alone. The same applies across files: #41 fixed a wrong remedy in the installer and wrote the identical wrong remedy into the adopter-facing template in the same commit. **Fixing a defect does not immunise you against it one file over.** **(2) Hostile-repo test:** a command written for other people's repos must be run against a repo that will punish it — one with a committed lockfile, a vendored directory, hundreds of docs. Verifying against this clean repo is a sample of one and has twice certified a command nobody would run. **(3) Seeded true positives, whenever a change makes a check more permissive:** the fourth occurrence (2026-08-06, `audit-context` Step 4) was a loosening justified by 9-of-9 false positives — a sample with *zero* true positives in it, which measures specificity and cannot measure sensitivity at all. A run that finds nothing cannot distinguish a fixed check from a disabled one. Build a fixture containing the failures the check must still catch, and show it still fires. Then run `/review-changes`.
- **State the check before the claim, on any negative.** "0 rows", "not called anywhere", "nothing reads it", "all clean" — a negative cannot distinguish a real absence from a broken instrument, an empty sample, or a mismatched population. Report the claim, the command that produced it, and **what a non-empty result would have looked like**; if you cannot state the shape of a positive, the claim is not ready. This framework had already derived the same rule four times, each scoped to one of its own instruments — two in `templates/audit-context.md` (*"a rung you cannot run is not a pass"*, *"report what the extractor dropped"*), one in the constraint above, one in `templates/review-changes.md` (*"report NOT REFUTED only after a thorough attempt"*). Those are this rule applied to the framework; this is the general case, and it bites hardest on the *adopter's* codebase, where the instrument is unfamiliar. Origin: five instances in one adopter session (#35), every one a negative, every one cheap to refute, every refutation run only after the claim was asserted. The mechanism is not carelessness — a partial view is usually sufficient to form an answer, and forming one is cheaper than checking it.

- **An absolute in an instruction is a decision; an absolute in a description is a measurement, and it needs one.** `never edit in place`, `always full depth regardless of size` — prescriptions, fine as absolutes. But *every*, *all*, *none*, *zero*, *cannot*, *not permitted*, *guaranteed* in a claim about how a tool, spec or codebase **behaves** is a measurement, and it ships unmeasured by default. Each such claim needs one of: a measurement with the command and the scope it ran over, a spec citation, or a hedge ("in the cases measured", "for well-formed tables"). Four of the five confident-but-wrong assertions in the 2026-08-10 sweep were universally quantified, and a hedged version of any of them would have been true and cost nothing (#39). The sharpest was *"zero false positives on escaped `\|`, on pipes inside fenced blocks, and on adjacent tables of differing widths"* — it looks like evidence and is not: the three seeded classes were the three the implementation already handled, so the sample contained no case the author had not coded for. That is the mirror image of the seeded-true-positives rule above. **Promoted to `templates/review-changes.md` in v1.25.0, on the evidence its own gate asked for** — and then refuted on its own subject matter from outside, eighteen hours after being written, when this repo shipped a prettier absolute generalised from two one-line tests and an adopter measured 3.8.1 (the full account is in `CHANGELOG.md` and `docs/rationale/review-changes.md`). It ships merged with the negatives rule, since they are one failure seen from two sides.

- **A user-global skill shadows a project-local one of the same name — in Claude Code.** `~/.claude/skills/<name>/` wins; the project-local file is never loaded, never merged, never warned about. ⚠️ **The mechanism is tool-specific and this line stated it as general until 2026-09-05 (#129).** Cursor *merges* (Team → Project → User; its CLI reads AGENTS.md and CLAUDE.md both — no backticks, they are an adopter's filenames, not paths in this repo) and Copilot *combines* all levels, its own docs saying the choice between conflicting instructions is **non-deterministic**. Both consequences below follow from *exclusivity*, which only Claude Code has — on a merging tool the risk is two live instruction sets, not one dead file. `docs/GUIDE.md` § "Where a skill lives" now carries the per-tool table. Two consequences are normative here. **(1)** Installing a skill globally forecloses per-repo variants of that name — so `review-changes` and `release` stay project-local, while `curate`, `audit-context` and `update-drift` ship global. **(2)** A global install must be *derived* from this repo's tracked `.claude/skills/`, never authored in `~/.claude/` — that directory is not a repository, so a skill living only there has no history, no review, and no restore path. Run `scripts/install-global-skills.sh` to install or verify; `--check <root>` also finds inert project-local copies. (Origin: 2026-08-06 — one untracked global copy had drifted from `templates/` unnoticed for four months, and 45 shadowed local copies across 23 repos read as authoritative while never being loaded.)
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
│   ├── rationale/             <- WHY a skill says what it says: superseded drafts and the
│   │                             measurements that refuted them, moved out of the skill
│   │                             bodies so adopters stop paying for this repo's litigation
│   │                             on every invocation. Nothing is duplicated between the
│   │                             two — if a claim is in both, one of them is wrong
│   ├── GUIDE.md
│   ├── verification-rationale.md
│   ├── seeded-defects-and-ablations.md
│   │                          <- Seeded fixtures + ablations, taught tool-agnostically (#130)
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
│   └── README.md              <- Tool-agnostic naming map
├── scripts/                   <- Shipped maintainer/adopter tooling
│   └── install-global-skills.sh
│                              <- Install + verify user-global skills; scan an estate for inert copies.
│                                 Refuses to install from a tree that is not at a release tag (#33)
├── .github/workflows/checks.yml
│                              <- CI (#115): lint + every fixture on push and PR. No path filters —
│                                 scoping saves 2 min and buys back the selection mechanism the
│                                 workflow exists to remove. Green means the deterministic checks
│                                 passed; it does NOT mean reviewed
├── tests/                     <- Self-tests for this repo (Phase A: structural lint)
│   ├── lint/                  <- Deterministic structural checks (no LLM)
│   │   ├── private-names.sh   <- Rule 12: a private project name in a tracked file.
│   │   │                         The name list is deliberately NOT tracked (it would
│   │   │                         publish what it protects), so an absent list is a
│   │   │                         reported SKIP, never a pass
│   │   ├── maintainer-path.sh <- Rule 13: `docs/rationale/` cited from a surface
│   │   │                         adopters install. Regressed a DAY after the fix that
│   │   │                         cleared it (#139) — a check now, not a review finding
│   │   │                         (#127). Denylist is ONE entry, measured
│   │   ├── vacuous-guard.sh    <- Rule 10: an ablation that cannot kill anything (#79's shape)
│   │   ├── block-parses.sh    <- Rule 11: a fenced bash block an adopter copies must
│   │   │                         parse; exemption is DECLARED, not guessed (#105)
│   ├── skill-sync.sh      <- Rule 6: templates/<name>.md vs .claude/skills/<name>/SKILL.md;
│   │                         fixture at tests/fixtures/skill-template-sync/
│   │   └── dollar-digit.sh    <- Rule 9: a bare $0-$9 in a skill body is an argument word (#77)
│   └── fixtures/              <- Seeded-defect fixtures: a check that finds nothing here is failing
│       ├── reference-integrity/  <- Seeded breaks for audit-context Step 4. refcheck.py is an ORACLE,
│       │                          NOT normative and never installed — fix Step 4 too (#92).
│       │                          Counts are COMMANDS, not numbers — both were stale
│       │                          before #102, a draft of that fix replaced one with a
│       │                          differently-wrong number, and they went stale again
│       │                          in v1.37.0 the moment cases were added:
│       │                            T ids  grep -oE '\bT[0-9]+\b' run.sh | sort -u | wc -l
│       │                            N ids  grep -oE '\bN[0-9]+\b' run.sh | sort -u | wc -l
│       │                            X      grep -cE '^  "X[0-9]+ ' run.sh
│       │                            abl    grep -cE '^ablate ' run.sh
│       │                          (#93, #102). The isolation and enumeration guards are
│       │                          separate from the X rows
│       ├── skill-template-sync/  <- Seeded drift for lint rule 6 (17 positives, 7 negatives)
│       ├── provisioning-quote/  <- Seeded drift for lint rule 7 (9 positives, 4 negatives)
│       ├── size-ratchet/       <- Seeded growth for lint rule 8, plus the #131 spill
│       │                          rows: `grep -cE '^(run_case|spill_case|ablate) '`
│       ├── block-parses/      <- Seeded blocks for lint rule 11 (4 positives, 4 negatives,
│       │                          2 ablations; N4 is the file-ordinal collision control)
│       ├── private-names/      <- Seeded names for lint rule 12 (4 positives, 5 negatives,
│       │                          3 skip-disposition rows, 8 ablations). Its own name list
│       │                          is synthetic — the real one is NEVER tracked
│       ├── dollar-digit/       <- Seeded `$N` forms for lint rule 9 (13 positives,
│       │                          12 negatives, 7 structural, 5 truth-table, 10 ablations;
│       │                          every ablation co-seeds a control the mutant must keep)
│       ├── verify-runner/       <- Seeded claims + prose for curate Step 0 sub-step 5's
│       │ runner (#34; 34 positives, 10 negatives, 4 malformed,
│       │ 7 structural, 4 timing, 29 ablations). EXTRACTS the
│       │ runner from templates/curate.md, so it cannot drift.
│       │ ~90s, the slowest check here and the only one with
│       │ timing cases. Its README carries the rejected `\|`
│       │ predicate and the THREE rounds that produced the
│       │ rest — read before touching the extraction
│       ├── dead-reference/      <- Seeded classes for curate Step 0.1's extractor. Counts
      │                          are COMMANDS — "40 rows, 16 ablations" was stale here
      │                          while the file held 35 and 15 (#93, fourth instance):
      │                            rows  grep -cE '^(want|want_why|resolves) ' run.sh
      │                            abl   grep -cE '^(\[ "\$ABS" = 1 \] && )?ablate ' run.sh
      │                          Most have actually bitten; FIVE are
      │                          constructed and labelled as such. Rationale lives in
      │                          run.sh's header, NOT a README. Read before loosening —
      │                          the cross-repo disposition costs sensitivity knowingly,
      │                          and the brace skip's cost was measured with the wrong
      │                          instrument once already (#121)
      ├── review-bench/        <- Seeded defects for measuring a REVIEW CONFIG, not a
      │                          checker (H-016). 7 historically-real classes, a clean
      │                          control for precision, a mechanical scorer. Its recall
      │                          numbers are a LOWER BOUND — read its threats section:
      │                          its seeds are the classes the AUTHOR thought of
      ├── maintainer-path/    <- Seeded pointers for rule 13. The class is at ZERO here,
      │                          so a real-tree run cannot tell a working rule from a
      │                          disabled one: 3 positives (one UNTRACKED), 4 negatives,
      │                          3 exit-code rows, 2 ablations
      ├── step15-tables/       <- Seeded tables, CRLF, frontmatter and emphasis for
      │                          review-changes Step 1.5 (#50, #52, #103, #144). Its
      │                          emphasis rule took three drafts, each refuted over
      │                          THIS REPO (28 hits, 15, 1) — every draft passed the
      │                          fixture. Read that before loosening bold-nesting.
      │                          Counts are COMMANDS: the
      │                          numbers here were already wrong before #144 added
      │                          cases (#93's class, third fixture to hit it):
      │                            t/n  grep -oE '\b[tn][0-9]+_[a-z0-9_]+\.md\b' run.sh | sort -u | wc -l
      │                            abl  grep -cE '^[a-z_]*ablate[a-z_]* ' run.sh
      │                          (both widened after a review showed the first
      │                          drafts missed a digit in a name and a renamed
      │                          ablation helper, silently)
      │                          The awk is EXTRACTED from the template, not copied,
      │                          so it cannot drift
      ├── baseline-fallback/    <- Seeded git states for review-changes Step 1's baseline
      │                          fallback (#149). The block is EXTRACTED from the template,
      │                          and every row runs in FOUR shell modes — the defect lived
      │                          only in `set -eo pipefail`, and this fixture's own first
      │                          draft ran without `-e`, so it certified what it could not test
      └── installer-release-guard/
│                              <- Seeded git states for the installer's release guard
│                                 (#33; 17 positives, 15 negatives, 32 ablation rows).
│                                 Its README carries the two REJECTED predicates and
│                                 why — read it before changing the comparison
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
| `memory/gotcha-log.md`, `memory/hypothesis-log.md`, `memory/review-ledger.tsv` | Layer-4 journal, provisional positions, review-cost ledger. ⚠️ **Cited by the Hard Constraints above and not in your clone** — the row above does not glob them, and `git ls-files memory/` returns 0 | Build your own from `templates/gotcha-log.md` and `templates/hypothesis-log.md` |

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
| `docs/seeded-defects-and-ablations.md` | **The adopter-facing page for this repo's most-caught-with instruments** (v1.37.0, #130). Seed the failures a check must catch; then break the check and require the fixture to go red. Ships its own limits — recall against seeds is a lower bound, with the external evidence for that. ⚠️ **Linked from `README.md` and `docs/GUIDE.md`, deliberately**: `docs/verification-rationale.md` and `docs/verifying-what-we-write.md` were reachable from nothing, which is the failure #130 is about |
| `templates/release.md` | Release skill — bump classification, preconditions, changelog entry; stops before tagging |
| `scripts/install-global-skills.sh` | Installs the user-global skills from tracked `.claude/skills/`, verifies they match, and with a root argument scans an estate for inert project-local copies. Refuses to install when the bytes it would copy are not what the highest release tag reachable from HEAD holds; fixture at `tests/fixtures/installer-release-guard/` |
| `.claude/skills/` | Reference installs (tracked) — the frontmatter-correct source a global install is derived from |
| `.github/workflows/checks.yml` | CI: `tests/lint/run.sh` + `tests/run-fixtures.sh`, every push and PR (#115). Its own header carries what it does *not* check |
| `tests/run-fixtures.sh` | Runs every suite under `tests/fixtures/`, enumerated not listed. Refuses three silences: an empty population exits 2, an undeclared fixture dir with no runner FAILS, and one red suite never stops the other thirteen |
| `tests/fixtures/clone-lint/` | Sensitivity of lint rules 1–2 **in the environments this repo is not developed in** — a checkout with no `memory/`, and (v1.37.0, N4) a tree that is **not a git work tree** at all, where `check-ignore` fails for a reason unrelated to the path. N4 asserts the skip line **and its count**, because a first draft printed one without the other. It also caught the over-correction: refusing to exempt all of `.claude/` re-created the original false FAIL for `.claude/settings.json`. Rule 1's fresh-clone exemption is a loosening, so T2/T3/T7 are the failures it must still catch; the rules are extracted from `tests/lint/run.sh`, not copied |
| `tests/lint/size-ratchet.sh` | Lint rule 8 — a ratchet on adopter-facing template sizes; baseline in `size-baseline.tsv`, fixture at `tests/fixtures/size-ratchet/`. **Measures the smaller of the two costs**: a skill body is paid once per invocation and is prompt-cached, while the *read surface* a run consumes is fresh tokens every time and is 4–25× larger. See #46 |
| `tests/lint/dollar-digit.sh` | Lint rule 9 — a bare `$0`–`$9` in a skill body. Skill *arguments* are substituted into the skill *body*, so a bare `$0` in an embedded awk program ships as the first argument word (#77). The one class no runtime check here can reach: rule 6 compares two files carrying the same `$0`, and every fixture runs the extracted program with substitution nowhere on the path. **The safe form is context-dependent** — `$(N)` in awk, `${N}` in shell, `\$N` in prose; `${0}` and `\$0` are awk syntax errors and shell `$(1)` fails silently at rc 0, all five measured by the fixture's T-cases. Fixture at `tests/fixtures/dollar-digit/` |
| `tests/lint/private-names.sh` | Lint rule 12 — a private project name in a tracked file. **This repo is public and its author works in an estate of private repos**; names reached shipped `templates/`, released `CHANGELOG.md` entries and four fixtures before this existed, and `memory/gotcha-log.md` had already prescribed the rule one release earlier. ⚠️ **The name list is not tracked** — a tracked denylist publishes exactly what it protects — so it lives at `~/.config/agent-ready/private-names` (or `$AGENT_READY_PRIVATE_NAMES`) and an absent list is a reported SKIP, not a pass. Short and generic names are declared UNCHECKED rather than matched. Population is tracked **plus untracked-not-ignored**, so a new file is covered before it is committed — a tracked-only draft passed clean over this rule's own fixture and then reported it once committed. Fixture at `tests/fixtures/private-names/` |
| `tests/lint/provision-quote.sh` | Lint rule 7 — the #42 class: a file that *provisions* a canonical row must quote it, not describe it by category. Rule 6 cannot see it, because the two `audit-context` copies agree with each other while contradicting `templates/project-file.md`. Fixture at `tests/fixtures/provisioning-quote/` |
| `memory/MEMORY.md` | This repo's in-repo memory index (maintainer-local) |

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
