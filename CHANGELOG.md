# Changelog

All notable changes to the agent-ready-projects framework. Adopters can check their project file's `agent-ready-projects` version against this log to see what's changed.

<!-- Maintainer release process (issue #14):
     When promoting a `vX.Y.Z (candidate, unreleased)` block to a dated release,
     also tag the release commit:

         git tag vX.Y.Z <commit>
         git push --tags

     Tags let adopters `git checkout vX.Y.Z` to inspect a pinned version and
     `git diff vX.Y.Z..vX.Y+1.0 -- templates/` to preview an upgrade. -->

## v1.14.0 (candidate, unreleased)

New **Verification Hooks** section in `docs/GUIDE.md` — the deterministic counterpart to session hooks, closing the edit → check → fix loop without a human relaying the error. Plus a release-skill fix for the class of staleness that let two templates sit three minors behind.

### Docs
- **`docs/GUIDE.md`** — New `## Verification Hooks` section, placed after Session Hooks (orientation at session start; verification at edit end). Covers what the mechanism buys (the agent carries its own error message, correcting while the reasoning that produced the bug is still in context), a fast/diagnostic/actionable test for what's worth wiring, three failure modes — the silent hook, the green-at-any-cost loop where the agent weakens the check rather than the code, and the tightened leash — and the rule that hook output feeds the gotcha log only when it surprised you or recurred. Tool-support table states the honest limit: most tools have no native mechanism, and an instruction is a request where a hook is a guarantee. Added to the TOC and to the concept-mapping table.

### Templates
- **`templates/project-file.md`, `templates/coordination.md`** — Framework stamp corrected from `v1.10.0` to the current version. Both had been stuck since v1.10.0 while the repo moved three minors ahead. The consequence was adopter-facing and self-inflicted: `project-file.md`'s own "Before You Start" table tells the agent to compare that stamp against this changelog and surface drift. An adopter scaffolding from the template got current template *content* carrying a three-minor-old *stamp*, so their first session reported drift against files that were in fact up to date.
- **`templates/release.md`** — Step 3, check 5 now runs **version-agnostic** greps after the current-version grep. The step already warned in prose that a file stuck at an older version wouldn't appear; it gave no command that would find one. Two targeted patterns are used — the project's own stamp string, and version-labelled lines — rather than a bare version-shaped match, which returns hundreds of dependency pins in any repo with a committed lockfile and gets skipped for that reason (git grep's gitignore-awareness doesn't help: lockfiles are committed). Caveats added for untracked files (invisible to `git grep`), for deliberately dated snapshots, and for the fact that these greps have no pass/fail state to stop on. **Step 5 amended in the same pass** — it said "update every file found in Step 3, check 5," which combined with the new greps would have instructed bulk-rewriting of historical citations, and its "confirm no stale references remain" exit criterion was unreachable by construction. Step 5 now scopes to files meant to track the current version, names template stamps explicitly as the category releases habitually miss, and re-runs only the current-version grep.

- **`templates/physics-tests/`** (all five files) — Removed the named triggering project and its experimental citation throughout. The worked examples are unchanged in substance and now read as generic scenarios ("a bare-pendulum simulation," "a fixed-step RK4 pendulum integrator") rather than a case study of a specific repo; the Tier 6 source entry now points the reader at *their own* primary experimental reference, which is the more useful instruction anyway. No test logic, tier mapping, or tolerance changed. Same de-naming applied to `docs/archive/METHODOLOGY.md`, `docs/archive/COMPARISON.md`, and the historical v1.1.0 changelog entry, which now credit "an early adopter project."

### De-identification

This repo is public. It named several private repositories and one third-party contributor, in files that had been published for months. All of it is now removed; the evidence it supported is unchanged.

- **A named contributor** appeared in `docs/decisions/ADR-002`, `docs/it-starts-with-markdown.md`, `docs/vv/verification-log.md`, and a v1.8.0 changelog entry — by first name and GitHub handle, in connection with a PR that broke rendering and a standards proposal that had to be negotiated down. Now "the second contributor" / "the contributor's agent" throughout, with the personal constitution file referred to generically.
- **Private repositories** (a community platform, a report-scoring project, a simulation project) were named and hyperlinked from a public repo — links that 404 for readers while still disclosing that the projects exist and what they do. Replaced with descriptors: "a community-platform project," "a report-scoring project." The `docs/vv/` claim registry, which catalogued private-repo internals as verification evidence, now cites "Case-study repo (private)."
- **A dead link** to a repository that no longer resolves was de-linked.

Retained: links to `agent-ready-papers`, `augur`, and `podcast-generator`, all public.

The case-study evidence keeps its specificity — 102 commits versus 2, 17 ADRs, 820 tests, the 64-report calibration run, the exact failure mechanisms. Only the identifiers are gone, and they were unverifiable to a reader anyway, since the repos are private.

### Tests
- **`tests/lint/README.md`** — The "deliberately does not check" list stated that template version stamps "are allowed to lag the current repo version intentionally — bumping every template on every release would be noise." That position is retired: it's what let two stamps sit three minors behind. The bullet now explains why lint still can't check it (distinguishing a tracking stamp from a dated snapshot needs judgment) and routes ownership to `release.md` Step 5.

### Adopter notes

New adopters: nothing to do — you get the corrected stamps and the new guide section by default.

Existing adopters: **re-install your `release` skill** if you installed it from v1.13.0 — the old Step 3 could not detect a file stuck at an older version, which is exactly the bug this release fixes in its own templates. The Verification Hooks section is new guidance, not a change to anything you already have; if you adopt it, add the "tests are not modified to make them pass" Hard Constraint at the same time, not after.

### Versioning rationale

MINOR, provisionally. Rule 1 does not fire — nothing breaks. Rule 2 is the judgment call: the v1.13.1 precedent made a new GUIDE section alone a PATCH ("no new artifact, only a new section in an existing document"), which taken alone would put this at PATCH too. What tips it to MINOR is the `release.md` procedure change — new steps and an amended Step 5 in a shipped skill are new behavior under the v1.10.1 rule — combined with Verification Hooks introducing a named concept adopters are meant to act on rather than a clarification of an existing one. Reclassify at release time if that reads as overreach.

### Review notes

The first draft of this change shipped three defects that a pre-commit review caught, all worth recording because they are the same *kind* of error: **a fix that recreates its own bug class one level up.** (1) The `release.md` sweep was a bare version-shaped grep — 601 hits against a 300-dependency lockfile, i.e. a check no agent would run. (2) Step 5 was left un-amended and directly contradicted the Step 3 it depends on. (3) The GUIDE's Verification Hooks section told readers to use a Claude Code `PostToolUse` command hook for the edit → error → fix loop; on exit 0 that hook's output goes to a debug log the agent never reads, making the recommended configuration an instance of the section's own "silent hook" failure mode. Corrected to name the exit-2 / `continueOnBlock` / `Stop`-hook mechanisms that actually deliver feedback.

---

## v1.13.1 (2026-08-03)

Documentation: new **"How deep to go: layer depth by project stage"** section in `docs/GUIDE.md`, plus two naming-map omissions fixed in `templates/README.md`. PATCH — no new template, no behavior change, no adopter action required.

### Docs
- **`docs/GUIDE.md`** — New subsection under "The Layered Model", before Layer 1. The guide's per-layer "when to add" triggers describe when a layer *starts paying off*; nothing said when adopting one early *costs* you. Adds a four-stage table (Explore / Consolidate / Cooperate / Deploy) whose load-bearing column is **Premature**, with three concrete failure modes: a runbook written before operations stabilize goes stale faster than it gets fixed (and the agent then runs the documented command instead of asking); memory topic files created before there's anything to remember fill with restatements of the code and charge for it every session; coordination structure with one contributor has no team-truth-versus-personal-preference distinction to draw. Closes with a "friction, not calendar" rule — stage tells you what to expect, friction tells you what to do.
- **`README.md`** — One-paragraph cross-reference under the layered-model table, per the CLAUDE.md requirement that guide and on-ramp stay in sync.

### Templates
- **`templates/README.md`** — Two long-standing omissions in the naming map: **`coordination.md`** was absent from the file entirely (both map and descriptions) despite being referenced in `README.md` and `adopt.md`, and **`test-verify-memory.md`** appeared in the descriptions but had no naming-map row. Both added. No content change to either template.

### Adopter notes

No action required. The guide section is new guidance for deciding *when not* to adopt a layer; nothing existing changed meaning. If you previously looked for `coordination.md` in the naming map and didn't find it, it's there now — save as `COORDINATION.md` at the project root.

### Versioning rationale

PATCH per the v1.10.1 precedent. Rule 1 does not fire — nothing existing breaks. Rule 2 resolves to PATCH: no new artifact, only a new section in an existing document and corrections to an existing map. A per-stage column in `templates/README.md` was considered and **declined** — it would have made this MINOR and widened the normative surface for a benefit no adopter has requested.

### Provenance

Adapted from [raoulg/codestyle](https://github.com/raoulg/codestyle), evaluated 2026-08-03, which applies the same four-stage axis to Python coding standards with per-stage 🐌 / 💡 / 🏅 marks. Zero content overlap with this repo — universal language standards versus project-specific memory — but it supplies the project-maturity axis the guide lacked, and specifically the idea that **the mark can be negative, not merely absent**. Its MCP delivery model (guidelines as a queryable server) was evaluated and declined: this framework's content is per-project by definition, and file-based memory in git is what makes it reviewable. Full working notes at `docs/work-items/guide-stage-depth.md`.

---

## v1.13.0 (2026-08-03)

New **release** skill for cutting versioned releases, completing the skill set's cadence coverage. Plus the guide's Documentation Rhythm table gains the two cadences it was missing. New template = MINOR bump. Closes #22.

### Templates
- **`templates/release.md`** (new) — Release skill. Classifies the semver bump, verifies preconditions (clean tree, correct branch, tag free locally *and* on the remote, tests actually run, version references located), drafts the changelog entry, syncs version strings, commits — then **stops before tagging or pushing**. Ships `disable-model-invocation: true`: the first template deliberately user-invoked only, since an agent deciding on its own that it's time to cut a release is a failure the stop-gate cannot catch. For Claude Code, install as `/release`; for other tools, run as a deliberate release-time prompt.
- **`templates/curate.md`** — **Step 0.2 fix.** The staleness check told the agent to read memory-file dates with `git log -1 --format=%ci -- <file>`. When the memory directory is gitignored — the setup the v1.10.2 Hard Constraint recommends — that returns empty with exit 0 for every file, so the check reported nothing stale having examined nothing. Now reads filesystem mtime by default, names the empty-output failure mode explicitly, and keeps `git log` for the tracked case behind a `git check-ignore` probe.
- **`templates/README.md`** — Added `release.md` to the naming map and file descriptions.

### Docs
- **`docs/GUIDE.md`** — Documentation Rhythm table gained two rows: **Before committing** (never added when `review-changes` shipped in v1.12.0) and **Cutting a release**. Added "Pre-commit review" and "Releases" paragraphs matching the existing `curate` / `audit-context` ones, plus a **"Why these four and not more"** note stating the cadence rule — skills attach to recurring moments with a real decision in them; single writes with no branching don't earn a slot, because skill names and descriptions occupy context every session.
- **`README.md`** — `release.md` added to the progressive-adoption list and the template catalogue.
- **`CLAUDE.md`** — `release.md` in the architecture diagram and Key Paths; the "Cutting a release" row now routes to `/release`. Also listed the previously-missing `templates/adr.md` in the diagram.
- **`CHANGELOG.md`** — Corrected three false issue references: v1.12.0 claimed "Closes #22" (which did not exist at the time) and both v1.11.0 and v1.11.1 claimed "Closes #21" (open, and about unrelated ovr.news memory-audit patterns). Restored the missing `## v1.11.0` and `## v1.11.1` version headings — both were tagged but appeared only as untitled blocks after a `---`.

### Adopter notes

New adopters: `release.md` is available in `templates/`. Install as `/release` (Claude Code) or use as a release-time prompt.

Existing adopters: **re-install your `curate` skill** from the updated template if your memory directory is gitignored — the old Step 0.2 staleness check silently passed without checking anything. `release.md` itself is additive and optional.

### Versioning rationale

MINOR. Rule 1 does not fire — nothing existing breaks and no adopter must act to stay working. Rule 2 does: `release.md` is a new artifact adopters install. The `curate` fix would have been PATCH on its own (refinement of an existing template) and rides along here.

### Provenance

The stage framework that prompted this session's guide work came from evaluating [raoulg/codestyle](https://github.com/raoulg/codestyle), which has zero content overlap with this repo but supplies a project-maturity axis the guide lacks. That change is **not** in this release — it is drafted at `docs/work-items/guide-stage-depth.md` pending review.

A 3-lens `/review-changes` battery found 6 blockers in the first `release.md` draft, two of them self-contradictions between steps: the Step 3 discovery grep was restricted to `*.md` and so could not find the manifests Step 5 tells you to update, and its `| grep -v CHANGELOG` filtered on line *content* rather than filename — silently dropping `README.md:3` and `docs/GUIDE.md:3`, both version badges written as `**Version X** | [Changelog](CHANGELOG.md)`. Recorded in the gotcha log as a recurrence of the 2026-07-09 "author green-lights own artifact, battery finds it holed" entry.

---

## v1.12.0 (2026-07-28)

New **review-changes** skill for diff-driven pre-commit review. Picks review lenses based on what changed — templates touched → full 3-4 lens battery, docs-only → two lenses, CHANGELOG-only → single adversarial pass. New template = MINOR bump.

### Templates
- **`templates/review-changes.md`** (new) — Diff-driven pre-commit review skill. Four lenses (guarantee-preservation, adversarial, doc-accuracy, shell-correctness), risk-based scoping (HIGH/MEDIUM/LOW), concurrent subagent execution. For Claude Code, install as `/review-changes`; for other tools, run as a pre-commit prompt.
- **`templates/README.md`** — Added `review-changes.md` to naming map and file descriptions.

### Docs
- **`CLAUDE.md`** — Updated "Before committing structural changes" row to include `/review-changes` as the complementary LLM review step after `tests/lint/run.sh`.

### Adopter notes

New adopters: `review-changes.md` is available in `templates/`. Install as `/review-changes` (Claude Code) or use as a pre-commit prompt (other tools). Run before committing structural changes — it complements `tests/lint/run.sh` (deterministic) with judgment-based review.

Existing adopters: no action required. The skill is additive and optional.

### Versioning rationale

MINOR per the v1.10.1 precedent. New template (`review-changes.md`) is a reusable artifact adopters install.

---

## v1.11.1 (2026-07-28)

Template refinement: **curate** and **audit-context** skills updated to cover the work-item pattern introduced in v1.11.0. PATCH — no new template, existing templates refined.

### Templates
- **`templates/curate.md`** — Two updates:
  - **Step 3** (Memory index update): New "Active work items" bullet — agent updates work-item Current Status savepoints at end-of-session, fills Outcome for completed items, creates work-item files for new multi-session initiatives.
  - **Step 4.4**: Replaced vague "Backlog / active work tracking" with explicit work-item check — scans `docs/work-items/` for incomplete files, flags abandoned items (14+ days stale), checks MEMORY.md pointer consistency.
- **`templates/audit-context.md`** — **Step 5** extended from "Topic file reachability" to "Topic file and work-item reachability" — catches orphaned work-item files (no MEMORY.md pointer) and stale pointers (target file missing).

### Adopter notes

Existing adopters who adopted v1.11.0: update your installed `curate` and `audit-context` skills from the updated templates. The v1.11.0 work-item template works without these skill updates — the refinements automate the savepoint convention at end-of-session and catch orphaned files at audit time.

### Versioning rationale

PATCH per the v1.10.1 precedent. Template refinement only — no new template, pattern, or behavior. The work-item pattern itself shipped in v1.11.0; these changes wire existing skills to support it.

---

## v1.11.0 (2026-07-28)

New **work-item template** for tracking multi-session work, adopted from patterns observed in [Plastic](https://github.com/zalom/plastic) (zalom/plastic, MIT). Plus two new principles in the guide: "memory as residue" framing and "index wins" canonical-source rule. New template = MINOR bump.

### Templates
- **`templates/work-item.md`** (new) — Lightweight savepoint for multi-session work (features, migrations, refactors, investigations). Five sections: What & Why, Current Status (the savepoint), Decisions, Open Questions, and Outcome. Not a lifecycle state machine — just enough structure to resume after a context reset. Save as `docs/work-items/[slug].md` and add a one-line pointer in the memory index's Current State section.
- **`templates/README.md`** — Added `work-item.md` to naming map and file descriptions.
- **`templates/memory-index.md`** — Updated Current State section comment to show work-item pointer format and "index wins" convention.

### Docs
- **`docs/GUIDE.md`** — Three additions + one update:
  - Expanded the one-paragraph "Feature-level context" mention into a full **"Work items (feature-level context)"** subsection within Layer 3. Covers the savepoint convention, the five-section structure, memory-index integration, and when to create one (more than two sessions).
  - New **"memory as residue, not choreography"** framing in the Self-Learning Loop section — names the goal the loop already implements. After multi-session work, what persists beyond code: ADRs/gotchas, the work-item Outcome, and the memory index.
  - New **"The index is canonical"** principle in Layer 3 — the memory index wins when it disagrees with a topic file. Index is curated at end-of-session; topic files are written during work and can go stale.
  - Updated "Long-lived feature branches" to cross-reference the work-item template.
- **`templates/README.md`** — Added `work-item.md` to the naming map (all tools: `docs/work-items/[slug].md`) and file descriptions.

### Adopter notes

New adopters: `work-item.md` is available in `templates/`. Create one when work spans more than two sessions — it replaces the ad-hoc todo file you're probably using now. Save as `docs/work-items/[slug].md` and add a one-line pointer in the memory index's Current State section.

Existing adopters: no action required. The new template and guide prose are additive. To adopt, copy `templates/work-item.md` and create your first work-item file for your next multi-session initiative.

### Origin

Analysis of [Plastic](https://github.com/zalom/plastic) (zalom/plastic, MIT) — an intent-driven development tool with a "memory as residue" philosophy and a four-stage pipeline (What → Why → How → Exec). Three patterns identified as adoptable; all three shipped here:
1. **Work-item savepoints** — Plastic's intent files inspired the five-section structure. Plastic's full intent lifecycle state machine (brainstorming → speccing → grilling → locking, 14 skills) was deliberately NOT adopted — it would make the framework into a development methodology, which is BMAD-METHOD and Superpowers territory.
2. **"Memory as residue, not choreography"** — Plastic's core philosophical framing, adopted as a named principle in the Self-Learning Loop.
3. **"Index wins"** — Plastic's rule that `INDEX.md` is the single-writer status authority, adapted here as the memory index being canonical over topic files.

### Versioning rationale

MINOR per the v1.10.1 precedent. New template (`work-item.md`) is a reusable artifact adopters install — same category as the coordination template (v1.5.0) and hypothesis-log (v1.7.0). The two new guide principles alone would be PATCH; the template makes this MINOR.

---

## v1.10.6 (2026-07-09)

Documentation: new **"The agent-write boundary"** principle in `docs/GUIDE.md`, adopted from BDS's `ai-wiki` (an independently-built instance of this framework) via #19. States crisply what the framework previously only gestured at: agents may write the derived/memory layer autonomously (gotchas, index, lint, session notes) but must not edit human-authored knowledge surfaces (project file, guide, templates, runbook, ADRs) or commit without in-session human approval. No template or behavior change; no adopter action required. Closes #19.

### Docs
- **`docs/GUIDE.md`** — New "The agent-write boundary" paragraph after the in-repo-memory / commit-by-default block. Maps `ai-wiki`'s `raw/ → wiki/ → CLAUDE.md` layering onto this framework's layers: the memory layer is the agent's regenerable working notes (cheap to correct, reviewed at curate time); the project file is the contract every future session inherits (a wrong edit propagates silently). Decision rule: "could a human reasonably need to disagree with this edit?" — if yes, it's human-authored, ask first. Version badge bumped to 1.10.6.

### Adopter notes

No action required. Templates and `adopt.md` are unchanged. Pinned consumers do not need to bump their adopted version line.

### Origin

Filed as #19 (2026-07-08) from a learn-from-BDS pass (`veen-systems/brainstorm/.../LEARN-FROM-BDS.md`, capability #1). BDS's `ai-wiki` proposed two transferable rules; **only the content-write boundary was adopted.** The other — quantified note decay (`confidence × exp(−days/τ)` frontmatter) — was **declined on principle**: it reintroduces the frontmatter schema this guide deliberately rejected ("lightweight by design. No frontmatter schema, no mandatory fields") and its `confidence` score is unsourced precision of the kind removed in v1.10.5/#18; the framework's existing `<!-- verify: -->` comment checks ground truth (PASS/FAIL) rather than time-since-touch, a stronger staleness signal. A third folded-in note (esm.sh single-file demo shape) was declined as out of scope for a tool-agnostic layered-memory methodology.

### Versioning rationale

PATCH per the v1.10.1 precedent. Explanatory reference prose articulating a boundary the framework already implied (commit-by-default, normative templates) — no new template, skill, `adopt.md` step, or adopter action. Same category as v1.10.4's "Two Kinds of Context" section. In this framework's vocabulary a *pattern* is a reusable artifact adopters install; this is a principle, so PATCH not MINOR.

---

## v1.10.5 (2026-07-09)

Documentation: removed the unattributed "60–80% reduction in session-start token usage" figure from `docs/GUIDE.md`. The number appeared in two places with no source, method, or n anywhere in the repo, and its restatement in the v1.10.4 "Two Kinds of Context" section risked a future reader mistaking text-convergence for evidence-convergence. No template or behavior change; no adopter action required. Closes #18.

### Docs
- **`docs/GUIDE.md`** — Two edits, both dropping the fabricated figure:
  - "Two Kinds of Context" intro — the anchor link "60–80% session-start reduction" becomes "session-start reduction" (keeps the pointer, drops the number).
  - "Context budget, not line count" — "measured 60-80% reduction in session-start token usage" becomes a qualitative claim grounded in the mechanism ("can substantially cut what an agent pays at session start, since the bulk of deep detail moves below the cliff and is read only when a task calls for it").
  - The two locations no longer read as two independent measurements. Version badge bumped to 1.10.5.

### Adopter notes

No action required. Templates and `adopt.md` are unchanged. Pinned consumers do not need to bump their adopted version line.

### Origin

Filed as #18 by the adversarial reviewer during the v1.10.4 review battery: restating the same unsourced number in a second location was flagged as a provenance risk, but the pre-existing gap was out of scope for the v1.10.4 doc-only PATCH. Resolved here after a repo-wide grep confirmed the figure has no attribution, method, or n anywhere — so it was hedged rather than cited (per the issue's resolution options, "downshift the language if no measurement exists").

### Versioning rationale

PATCH per the v1.10.1 precedent. Documentation-only correction: no new template, skill, `adopt.md` step, or adopter action. Removing an unsupported claim tightens the guide's evidentiary discipline without changing what adopters install or do.

---

## v1.10.4 (2026-06-24)

Documentation: new "Two Kinds of Context" section in `docs/GUIDE.md` distinguishing persistent (curated) from ephemeral (per-turn) context and naming mechanical context-compression tools as a complementary layer, plus a fourth "Prefix stability" principle folded into the existing cache-hierarchy section. No template or behavior change; no adopter action required.

### Docs
- **`docs/GUIDE.md`** — New section "Two Kinds of Context (and What This Method Reduces)", placed after "The Auto-Loading Cliff": names the boundary between what curation reduces (persistent/auto-loaded context) and what it does not (ephemeral per-turn context — tool output, large reads, inline images/PDFs), and positions mechanical context-compression tools as a complementary layer with two cautions — profile your actual bloat before adopting (savings depend on matching the tool to your bloat category), and keep compression off auto-loaded files (the faithful-read premise). New **"Prefix stability"** principle added to "Why a hierarchy works" — the provider-side version of that section's existing eviction discipline: churn at the top of an auto-loaded file can invalidate a cached prompt prefix, so keep the head stable. Caching is framed provider-agnostically (some providers cache automatically, others require marking the span; magnitude is provider-dependent). Version badge bumped to 1.10.4; TOC updated.

### Adopter notes

No action required. Templates and `adopt.md` are unchanged. Pinned consumers do not need to bump their adopted version line.

### Origin

Prompted by a maintainer question (2026-06-24) about adopting Headroom (an open-source context-compression tool) to reduce Claude cost. Adopting the tool was declined for the maintainer's own use — same category as `lean-ctx`, already rejected: the maintainer's session bloat is inline images/PDFs, not the tool output these compressors target (maintainer-local memory). But mining Headroom's design surfaced a real gap: the guide only ever addressed persistent context and never named the ephemeral layer or its different economics. Headroom's prefix-alignment feature motivated the prefix-stability principle. Tool-agnostic: no compression tool is named or depended on in the adopter-facing text — the section names the *category* with a functional definition. Draft was pressure-tested by a four-lens review battery (framework fidelity, tool-agnosticism, adversarial claims, voice/structure) before landing; the battery caught a false cross-reference, an over-stated caching claim, and an "estimated"-vs-"measured" evidence slip, all corrected here.

### Versioning rationale

PATCH per the v1.10.1 precedent. The change is documentation-only: a new conceptual section and a new principle in the reference guide, with no new template, skill, `adopt.md` step, or adopter action. The "is a named concept a new pattern?" question resolves to **no** — in this framework's vocabulary a *pattern* is a reusable artifact adopters install (hypothesis-log, coordination, curate), whereas this is explanatory reference prose. New templates/patterns/behaviors would be MINOR; this is neither.

---

## v1.10.3 (2026-06-09)

Maintainer infrastructure: structural-lint self-tests at `tests/lint/`. Four deterministic checks (no LLM) for drift between `CLAUDE.md`, `memory/MEMORY.md`, templates, and disk state. No template, guide, or adopter-facing surface changed. No adopter action required.

### Maintainer-only additions
- **`tests/lint/run.sh`** — Four-rule structural lint, exits non-zero on drift:
  1. Every path referenced in `CLAUDE.md` (Before You Start, Key Paths, backticked refs) resolves on disk
  2. `memory/MEMORY.md` index integrity — no orphans (project file without index entry), no stale links (index entry without project file)
  3. Skill-shape templates (`curate.md`, `audit-context.md`, `test-verify-memory.md`) retain their embedded `name:`/`description:` lines inside the `SAVE AS: .claude/skills/...` HTML comment
  4. Templates that open with `---` close it within first 30 lines
- **`tests/lint/README.md`** — Rule catalog with what each rule catches and what is deliberately *not* checked (semantic pairing between Hard Constraints and Before You Start, version-pin coherence, content correctness, LLM-driven behavioral testing).
- **`CLAUDE.md`** — New row in Before You Start: "Before committing structural changes → run `bash tests/lint/run.sh`". Architecture diagram updated to surface `tests/` and the existing `templates/test-verify-memory.md` + `templates/test-fixtures/` (now visible as the Phase B/C behavioral-test precedent).
- **`.gitignore`** — Added `.pytest_cache/`.

### Adopter notes

No action required. Templates, guide, and `adopt.md` are unchanged. Pinned consumers do not need to bump their adopted version line.

### Origin

Same 2026-06-09 session as v1.10.2. After dog-fooding the in-repo memory adoption, the question surfaced: how do we *test* the methodology this repo teaches? Initial design discussion landed on a hybrid plan — structural lint (deterministic, cheap) plus eventual multi-vendor behavioral fixtures (LLM-in-the-loop, expensive, validates the tool-agnostic claim via cross-vendor independence). The reviewer-battery idea (extending "fire up a battery of multi-model reviewers" to Gemini and Copilot CLIs) and the methodology-test idea converged on the same harness: a script that fans out a fixture + prompt to multiple vendors and compares results. v1.10.3 ships the deterministic Phase A only. Phase B/C (behavioral fixtures + cross-vendor harness for the four load-bearing tricks: `curate`, `audit-context`, memory recall, `hypothesis-log`) is deferred — Phase A earns its keep standalone and Phase C has unresolved design choices best made after seeing Phase A drift get caught in real session use.

The existing `templates/test-verify-memory.md` is the Phase B/C precedent — single-trick behavioral fixture with 10 expected-outcome fixtures under `templates/test-fixtures/memory/`. Generalizing that pattern to the other three load-bearing tricks + adding a cross-vendor wrapper is the Phase C scope.

### Versioning rationale

PATCH per the v1.10.2 precedent: no template, pattern, or behavior change for adopters. Maintainer infrastructure only. The new `tests/lint/` is repo-specific (not templatized) and the new Before You Start row is in the maintainer's own `CLAUDE.md`, not in `templates/project-file.md`. If Phase C templatizes a per-trick behavioral-test pattern that adopters can copy, *that* would be MINOR.

---

## v1.10.2 (2026-06-09)

Maintainer infrastructure: the framework that teaches the layered memory method finally applies it to itself. Root `CLAUDE.md` + in-repo `memory/` directory + `.gitignore` entry. No template, guide, or adopter-facing surface changed. No adopter action required. Closes #17.

### Maintainer-only additions
- **`CLAUDE.md`** — New file at repo root. Header pin (`agent-ready-projects: v1.10.2`), Hard Constraints (in-repo memory rule + templates-are-normative + patch-vs-minor precedent + don't-re-promote + tool-agnostic adopter content), Before You Start table with task-triggered pointers to `memory/`, `templates/`, `docs/`, etc., Architecture section, "What is intentionally not shipped" honesty note, Key Paths, How to Work Here.
- **`memory/`** — New directory (gitignored). Holds maintainer's project-typed state: `MEMORY.md` index plus three topic files migrated from user-level Claude Code auto-memory at `~/.claude/projects/C--local-dev-agent-ready-projects/memory/`:
  - `project_framework_pivot.md` — April 2026 wrapper-archive decision
  - `project_session_bloat_profile.md` — token-bloat measurements; basis for rejecting `lean-ctx`
  - `project_dead_end_pattern_rollout.md` — PAUSED 2026-06-05 pending #16 gate 4
- **`.gitignore`** — Added `memory/` line. Consistent with the framework's own guidance in `adopt.md` STEP 7 ("If the memory/ directory is user-specific, add it to .gitignore").

### Adopter notes

No action required. Templates, guide, and `adopt.md` are unchanged. Pinned consumers do not need to bump their adopted version line.

### Origin

Surfaced 2026-06-08 evening during the agent-ready-papers v1.5.0–v1.6.3 session, where the same structural failure mode prompted the downstream Hard Constraint at agent-ready-papers v1.6.2. Without root `CLAUDE.md` routing to in-repo `memory/`, the global Claude Code instruction ("you have a memory system at `~/.claude/projects/<slug>/memory/`") wins by default — same precedence default that bit agent-ready-papers and was codified there. The source framework had the same gap; the downstream repo fixed it first.

Filed as #17 with the proposed ~30-minute fix (CLAUDE.md + memory/ + 3-file migration + .gitignore + user-level cleanup). Executed 2026-06-09. The user-level files at `~/.claude/projects/C--local-dev-agent-ready-projects/memory/` are preserved as historical record but the user-level `MEMORY.md` index now marks them as migrated, pointing at the in-repo canonical copies.

### Versioning rationale

PATCH per the v1.10.1 precedent: no template, pattern, or behavior change for adopters. The change is bounded to maintainer infrastructure (one new committed file `CLAUDE.md`, one new gitignored directory `memory/`, one `.gitignore` line). Framework *teaching* unchanged.

---

## v1.10.1 (2026-05-30)

Documentation: verification rationale doc names the three principles organizing the framework's verification patterns. Adopts the category-theory framing landed upstream in `agent-ready-papers#12` and `#13`. No template or slash-command content changed; no adopter action required. First patch-version release.

### Docs
- **`docs/verification-rationale.md`** — New design-rationale doc. Three structural principles, each with an explicit decision rule:
  1. *Multi-pass verification is a limit of functors.* Each verification layer preserves invariants the others do not; the battery's strength is invariant coverage, not redundancy. Makes adding, skipping, or retiring a layer decidable.
  2. *Citation drift is tier-monotonicity failure.* Manuscript language must sit at or below the registered confidence tier. Subsumes the separate rules of thumb in the writing-guide and anti-hallucination templates.
  3. *Validation is compositional, not monolithic.* Verification of a complex artifact factors as composition of verifications of its parts. Organizes the layered memory system (`docs/decisions/ADR-001` + `docs/self-verifying-memory.md`).

  Plus an explicit out-of-scope section (task-triggered pointers, Before-You-Start tables, versioning/CHANGELOG discipline). Category-theory vocabulary stays in the rationale doc; templates and slash commands are untouched. Closes #15.

### Pointers
- **`templates/checklists/qa-checklist.md`** — Rationale pointer in the header, principle 1.
- **`docs/vv/anti-hallucination.md`** — Rationale pointer in the intro, principle 2.
- **`templates/review-agent.md`** — Rationale pointer in the template guidance, principle 1 applied to batteries of review agents.

### Origin

Upstream sibling issues `agent-ready-papers#12` (writing-guide tier-monotonicity) and `#13` (DR-011 functorial-composition rationale) opened 2026-05-28 and closed 2026-05-29 via commits `a294361` and `74d7976`. The anchor doc `agent-ready-papers/docs/category-theory-as-design-lens.md` (commit `f79b6f0`) was already in place. The framework's verification rationale was implicit before this: adopters wanting to reason about whether to add a fourth review agent, or why three checklist sections rather than one, had to reconstruct it from examples. The new doc lets downstream consumers cite a single principle.

### Versioning precedent

This is the framework's first patch-version release. Going forward, documentation-only changes (new rationale docs, clarifications, cross-reference adds) go to patch versions; new templates, patterns, or behaviors continue to get minor bumps. The maintainer release-tagging process (`git tag v1.10.1 <commit>; git push --tags`) in the CHANGELOG header applies unchanged.

---

## v1.10.0 (2026-05-11)

Three additions: hypothesis log (first-class home for provisional positions), session-start framework-drift check, and project-file size budget enforcement.

### Templates
- **`templates/hypothesis-log.md`** — New template. Format: Position / Alternative / Method / Revisit trigger / Review by / Domain / Status. `open` → resolved (close or promote to ADR). Distinguished from gotcha log (problems solved), ADRs (decisions accepted), and TODO (tasks ready to execute) by the future-evidence frame.
- **`templates/project-file.md`** — "Before You Start" gains a new top row: **Starting any session** → compare the `framework: agent-ready-projects vX.Y.Z` header line against `CHANGELOG.md` (GitHub URL or local clone). If behind, surface the drift before starting work. Don't auto-update — adopting changes is the engineer's call. Closes the gap where adopted projects could fall multiple versions behind without anyone noticing (e.g., ovr.news ran on v1.7.0 from adoption through 2026-05-09, never flagged).
- **`templates/curate.md`** — Two extensions to Step 0 freshness check:
  - Sub-step 6 ("Hypothesis log surface"): `/curate` flags entries past their `Review by:` date and entries whose `Revisit trigger:` has fired. The skill surfaces — it does not resolve — to keep the hypothesis-log discipline (engineer applies Method, agent doesn't shortcut it).
  - Sub-step 7 ("Project file size budget"): `/curate` checks the project file against the 40k Claude Code perf threshold. The most common cause of bloat is session-narrative footers (`_Last updated: ..._` / `_Earlier ..._`) accreting across sessions while the same content already lives in `memory/project_session_*.md` and is indexed in `MEMORY.md` — pure duplication. Rule: keep at most one footer block, drop older `_Earlier_` blocks. Step 3 gets a paired discipline note: don't accrete narrative onto the project file footer in the first place; it belongs in session-memory files.

### Guide (`docs/guide/04-the-rhythm.md`)
- "During work" diagram + prose updated: provisional positions get a fourth capture path alongside gotchas, topic-file learnings, and ADRs. Explicit contrast with ADRs ("decision frozen") to prevent confusion.
- End-of-session flowchart: new step "3.5 Hypothesis log surface" between memory-index update and doc sync.

### Origin

**Hypothesis log** emerged on the ovr.news project (`docs/hypothesis-log.md`, first commit 2026-04-19) where Claude was scheduling cron-style reminders for predictions that needed to be tested. The cron approach checked *that* you remembered, not *whether the prediction was right*. The Method field — written before the data — turns each entry into a small pre-registered experiment. After several months of use it became clear the pattern wasn't project-specific. The augur EXP-009 milestone-3 review battery surfaced multiple "we'll see how this performs in 14 days" cases that were good fits, prompting promotion here.

Compared to existing tools:
- ADRs freeze rationale at decision time. Hypothesis entries are the *bet* before the rationale fully settles.
- Gotcha log captures problems with known root causes. Hypothesis entries capture predictions whose root cause is *what we're trying to learn*.
- TODO captures tasks. Hypothesis entries capture *expectations*, with the trigger that brings them back.

**Session-start drift check** emerged when ovr.news's CLAUDE.md hit Claude Code's 40k perf warning on 2026-05-09 and inspection showed the project still pinned to `agent-ready-projects: v1.7.0` — two minor versions behind, undetected for months. The intent that adopters track framework drift had no enforcement: the "Update" prompt in `adopt.md` requires the user to manually paste it into a session, while the version line in the header was inert metadata that no instruction told the agent to act on. The fix is the cheapest possible mechanism: a task-triggered pointer in "Before You Start" that uses the same idiom as every other row in the table. Tool-agnostic; works for Claude Code, Cursor, Codex, Aider, Copilot.

**Project-file size budget** emerged in the same session: the bloat that triggered the 40k warning was 7 accreted `_Last updated_` / `_Earlier_` session-narrative blocks, each duplicating a `memory/project_session_*.md` file already indexed in `MEMORY.md`. The trim was straightforward (keep one, drop six) but the question that surfaced was structural: nothing in `/curate` told the agent *not* to keep adding these, and nothing told it to detect the bloat. Step 0 sub-step 7 closes the detection side; Step 3's discipline note closes the prevention side.

---

## v1.9.0 (2026-04-14)

Self-verifying memory — agents embed verification commands in state claims on write, run them on read, and audit them on curate. No user-facing ceremony.

### Guide (`docs/GUIDE.md`)
- New subsection "Self-verifying memory" under Layer 3. Covers the write/read/curate protocol, claim-type detection table (State/Observation/Decision/Pattern), worked example, and lightweight design rationale.
- Version bumped to 1.9.0.

### Templates
- **`templates/curate.md`** — Step 0 sub-step 5 (Unverified state claims) extended with three-outcome protocol: PASS/FAIL for embedded verify commands, MANUAL CHECK NEEDED for manual-only claims, UNVERIFIED for claims without verification. Step 6 report template updated with verification summary row.
- **`templates/test-verify-memory.md`** — New skill that tests the self-verifying memory protocol against fixture files with known expected outcomes. Validates claim-type detection, verify command execution, and three-outcome classification.
- **`templates/test-fixtures/memory/`** — Ten fixture files exercising all curate verification branches: passing verify, failing verify, manual verify, erroring verify, unverified state claim (×3 — covering "deployed"/"running", "live", and "working in production" trigger words), decision, observation, and pattern.

### Landscape (`docs/LANDSCAPE.md`)
- Added "Self-verifying memory" to the gap analysis table — no other framework embeds verification in memory entries.
- Added to "Ahead" positioning section with reference to the ovr.news incident and ETH Zurich finding.
- Added Superpowers (151K+ stars) to Category 3 and positioning diagram.

### README
- Version bumped to 1.9.0.

### Origin

Issue #10, building on issue #8. The v1.8.1 fix (distinguish observations from deployed state) was guidance-only — it told agents what to do but provided no mechanism. Self-verifying memory closes the loop: verification commands travel with the claim, are executed when the claim is consumed, and are audited during curation. The ovr.news incident (230 articles affected by a false "shipped" memory) demonstrated that guidance alone is insufficient when future sessions trust memory entries unconditionally.

---

## v1.8.1 (2026-04-14)

Memory hallucination prevention — distinguishing session observations from deployed state, plus landscape update.

### Guide (`docs/GUIDE.md`)
- New paragraph "Distinguish observations from deployed state" in Layer 3 memory guidance. Explains the observation-vs-state conflation, advises qualifying claims with verification commands, warns against unqualified "shipped" entries.
- Version bumped to 1.8.1.

### Templates
- **`templates/gotcha-log.md`** — New worked example: memory claimed "shipped" but feature only existed in a running process (based on ovr.news incident, 230 articles affected). Shows the pattern and the fix.
- **`templates/curate.md`** — Added freshness check step 5: "Unverified state claims." The `/curate` skill now scans memory for "shipped"/"deployed"/"live", flags entries without verification commands, and runs existing verification commands to check for failures.

### Landscape (`docs/LANDSCAPE.md`)
- Added [Superpowers](https://github.com/obra/superpowers) (151K+ stars) under Category 3 (Frameworks and methodologies). Workflow-discipline framework complementary to this guide's knowledge-structure approach.
- Updated positioning diagram and narrative to reflect the orthogonal relationship.

### README
- Version bumped to 1.8.1.

### Origin

Issue #8: ovr.news ML logo classifier endpoint was tested during a dev session and memory recorded "shipped." The endpoint only existed in the running process — after restart it returned 404, silently failing for 230 articles (10%) until a human noticed. The memory system had no mechanism to distinguish a session observation from verified deployed state.

---

## v1.8.0 (2026-04-11)

Multi-contributor coordination — Layer 5 for projects where multiple developers use AI agents on the same codebase.

### Templates
- **`templates/coordination.md`** — New coordination template for multi-contributor projects. Five sections: Contributors (who's active and how they work), Shared Constraints (team-agreed rules promoted from project file), Convention Proposals (lightweight staging for proposed changes), Work in Progress (collision-avoidance signals), Memory Conventions (shared vs personal memory, gotcha log tagging). Layer 5: opt-in, not auto-loaded, accessed via task-triggered pointer.
- **`templates/project-file.md`** — Added commented-out "Before You Start" row for `COORDINATION.md` (opt-in for multi-contributor projects).
- **`templates/memory-index.md`** — Added comment block for multi-contributor memory conventions (shared vs personal memory, gotcha log tagging).

### Guide (`docs/GUIDE.md`)
- New subsection: "Multi-contributor projects" under Tool-Specific Setup — Layer 5 explanation, three friction points grounded in the multi-contributor case study, self-learning loop deduplication phase, scope boundaries, setup guide.
- Table of contents updated with multi-contributor projects entry.
- Version bumped to 1.8.0.

### Adoption (`adopt.md`)
- Assess prompt: added question 6 — multiplayer readiness (multiple contributors? coordination infrastructure?).
- Adopt prompt: added STEP 6.5 — if multiple contributors detected, create `COORDINATION.md` from template and add pointer to project file.
- Template URL list updated with `coordination.md`.

### Decisions
- **ADR-002** — [Multiplayer coordination layer](docs/decisions/ADR-002-multiplayer-coordination-layer.md). Design stance: opt-in Layer 5 over extending existing layers or personal overlay files. Grounded in three observed friction points from the multi-contributor case study.
- **`docs/decisions/README.md`** — Decision index created, listing ADR-001 and ADR-002.

### README
- Layered model table extended with Layer 5 row.
- Growing-from-there list includes coordination template.
- Version bumped to 1.8.0.

### Origin

Observed in a community-platform project: a second contributor joined a well-documented agent-ready project and still hit coordination friction — a PR broke a documented constraint because there was no agreement mechanism, a convention proposal required negotiation that had no staging area, and work overlap had no visibility. Research (April 2026) confirmed the gap: all existing multi-agent frameworks solve single-user orchestration; no framework addresses multi-user-multi-agent coordination for small teams.

### References

- [OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) — security framework for agentic systems (complementary, not overlapping)
- [Microsoft Agent Governance Toolkit](https://github.com/microsoft/agent-governance-toolkit) — runtime security for AI agents (April 2026)
- [Cooperative AI: Multi-Agent Risks from Advanced AI](https://www.cooperativeai.com/post/new-report-multi-agent-risks-from-advanced-ai) — research on multi-agent coordination risks

---

## v1.7.2 (2026-04-11)

YAML frontmatter for project file and review agent templates — machine-parseable metadata for any AI tool.

### Templates
- **`templates/project-file.md`** — Project metadata (`stack`, `status`, `repo`, `framework`) moved from inline bold list items to YAML frontmatter. Any tool or script can now parse project identity without markdown interpretation. Version bumped to 1.7.2.
- **`templates/review-agent.md`** — Added YAML frontmatter (`domain`, `artifact_type`, `tags`) so tools can discover and select review agents programmatically. Added to tool-naming table in `templates/README.md`.
- **`templates/adr.md`** — Fixed `[ trigger ]` placeholders that rendered as GitHub checkboxes (removed interior spaces).

### Guide (README.md)
- Step 8 in the adoption ladder renamed from "ADR index" to "Decision index" for consistency with the template's own terminology.
- Version bumped to 1.7.2.

### Guide (docs/GUIDE.md)
- Version badge bumped to 1.7.2.

### Motivation
The ADR template (v1.7.1) introduced YAML frontmatter for machine-readable lifecycle state. Reviewing the remaining templates through an AI-agnostic lens revealed that project-file and review-agent metadata was locked in markdown formatting only humans (or LLMs) could parse. Frontmatter makes this structured data accessible to any tool — Obsidian, static site generators, linters, CI scripts — not just the AI reading the document.

## v1.7.1 (2026-04-11)

ADR template — codifies the decision record pattern that was previously demonstrated by example only.

### Templates
- **`templates/adr.md`** — New Architecture Decision Record template with YAML frontmatter (`status`, `date`, `deciders`, `superseded_by`), options comparison tables, consequences (positive/negative/risks), "Revisit If" triggers with concrete conditions, implementation steps, and an embedded decision index template. Synthesized from ADR patterns across three adopter projects.

### Guide (README.md)
- Step 8 in the adoption ladder now links to `templates/adr.md` instead of being a bare mention.
- Version bumped to 1.7.1.

### Templates README
- `templates/README.md` — Added `adr.md` to the tool-naming table and the file descriptions list.
- `templates/project-file.md` — Version bumped to 1.7.1.

### Origin
Investigated ADR/DR practices across three adopter repositories. One adopter contributed the "Revisit If" pattern with concrete trigger conditions. A community-platform adopter contributed status badges, decision matrices, and a battle-tested template across 17 decisions. `agent-ready-papers` contributed YAML frontmatter with `superseded_by` tracking. The framework had ADRs at step 8 of adoption and one example (ADR-001) but no reusable template — this closes that gap.

## v1.7.0 (2026-04-08)

Structural health audit — `/audit-context` skill catches framework-level issues that version drift checks and session-level curation miss.

### Templates
- **`templates/audit-context.md`** — New skill template for periodic structural audits. Seven-step check: document size, cross-layer duplication, wrong-layer placement, reference integrity, topic file reachability, gitignore correctness, and severity-grouped report. Complements `/curate` (session-level) with framework-level health checks. Install as `.claude/skills/audit-context/SKILL.md`.

### Adopt prompt (adopt.md)
- STEP 6 now installs both `/curate` and `/audit-context` skills. "Before You Start" table instruction includes both: "Ending a session → Run /curate" and "Monthly or after major restructuring → Run /audit-context".
- Template URL list updated with `templates/audit-context.md`.
- Update prompt PART 2 (Structural Health) now references the `/audit-context` skill instead of inlining duplicate checks — single source of truth for audit logic.

### Guide (README.md)
- Version bumped to 1.7.0.

### Templates
- `templates/project-file.md` — Version bumped to 1.7.0.

### Motivation
Observed across multiple adoptions: version drift checks catch framework updates, and `/curate` catches session-level staleness, but neither catches structural decay — bloated auto-loaded files, duplicated facts across layers, content in the wrong layer, orphaned topic files, or gitignore mismatches. These issues accumulate silently between sessions. A periodic structural audit closes this gap.

## v1.6.0 (2026-04-04)

Doc sync step — `/curate` now catches documentation drift from code changes, not just memory staleness.

### Templates
- **`templates/curate.md`** — Added Step 4 (Doc sync check) between memory index update and reference verification. Checks project file architecture section, key commands, runbook operational details, and backlog against current repo state. Steps 4-5 renumbered to 5-6. Report template updated to include doc sync findings.

### Guide
- **`docs/guide/03-the-loop.md`** — Surface phase now lists "Doc sync" as the fifth agent action during end-of-session curation.
- **`docs/guide/04-the-rhythm.md`** — `/curate` flowchart updated with Step 4 (Doc sync check) between memory index and report. Full-picture diagram updated to show doc sync in end-of-session subgraph.

### Guide (README.md)
- Documentation Rhythm table updated: end-of-session action now includes "doc sync."
- Version bumped to 1.6.0.

### Templates
- `templates/project-file.md` — Version bumped to 1.6.0.

### Motivation
Observed in [podcast-generator](https://github.com/ducroq/podcast-generator): a large session with 18 file changes, new modules, renamed CLI flags, and changed defaults left CLAUDE.md and RUNBOOK stale. The existing curate steps (gotcha log, memory index, references) didn't catch documentation drift because they focus on the memory layer, not the project documentation layer. Adding a doc sync step closes this gap — inline updates prevent drift, curate catches what slips through.

---

## v1.5.0 (2026-04-06)

Validation checklists, adversarial QA, git-reality validation, and deployment context gotcha.

### Templates
- **`templates/checklists/`** — New directory with definition-of-done checklists for each workflow stage: `architect-checklist.md` (context, design decisions, handoff), `test-checklist.md` (coverage, quality, execution), `implement-checklist.md` (completeness, architecture compliance, cleanup), `qa-checklist.md` (git-reality validation, minimum findings, deployment readiness). Each is 10-15 items — lightweight gates, not enterprise compliance. Closes #3.
- **`templates/checklists/qa-checklist.md`** — Includes **Git Reality Check**: cross-reference `git diff --stat` against claimed changes, flag discrepancies (files changed but undocumented, or documented but unchanged), verify each acceptance criterion has corresponding code. Closes #4.
- **`templates/checklists/qa-checklist.md`** — Includes **Minimum Findings Requirement**: review must surface at least 3 observations with severity classification (CRITICAL/HIGH/MEDIUM/LOW). If fewer than 3, reviewer must document what was verified and why. No "looks good" without evidence. Closes #5.
- **`templates/gotcha-log.md`** — Added worked example: "Tests pass locally but fail in deployment" — sandboxed execution contexts (systemd, Docker, CI) impose constraints that manual/local runs bypass. Closes #6.
- **`templates/RUNBOOK.md`** — Strengthened post-deploy verification: explicit guidance to test through the actual execution context (`systemctl start`, `docker run`, CI trigger), not manual invocation. Includes comment block listing common sandbox constraints.

### Guide (README.md)
- Templates section updated with checklists directory link and description.
- "Growing from there" list updated with checklists as step 10.
- Version bumped to 1.5.0.

### Templates README
- `templates/README.md` — Added checklists entry to "The files" list and `checklists/` row to the tool-naming table.
- `templates/project-file.md` — Added commented-out "Before You Start" rows for checklists (opt-in). Version bumped to 1.5.0.

### Origin
Issues #3–#6 filed after analysis of the BMAD framework's code review workflow (validation checklists, git-reality validation, adversarial review) and a real-world incident where systemd sandbox constraints broke a service that passed all local tests.

## v1.4.0 (2026-04-03)

Freshness check — `/curate` now catches context rot from previous sessions, not just current-session work.

### Templates
- **`templates/curate.md`** — Added Step 0 (Freshness check) before existing steps. Checks four types of staleness: dead references (paths that no longer exist), stale memory (files untouched 30+ days), lingering gotchas (unresolved entries older than 14 days), and ground truth drift (downstream artifacts newer than their canonical source). Step 0 reports only — the engineer decides what to fix. Step 4 (Verify references) now skips when Step 0 already ran. Report template restructured to surface freshness findings.

### Guide
- **`docs/guide/03-the-loop.md`** — Surface phase now lists "Freshness check" as the first of four agent actions. Monthly audit repositioned as "deep audit" since basic staleness is caught every session.
- **`docs/guide/04-the-rhythm.md`** — `/curate` flowchart updated with Step 0 before Step 1. Monthly section renamed "deep audit" with clarification that per-session freshness checks handle basic staleness. Added warning sign: "References point to files that no longer exist." Full-picture diagram updated to show freshness check in end-of-session subgraph.

### Motivation
Inspired by community discussion around automated overnight context maintenance ("dreaming" loops). The core insight — that context structures rot between sessions and manual maintenance doesn't scale — is valid. Our adoption: human-triggered staleness detection built into the existing `/curate` skill, not autonomous overnight loops. Fits the framework's design: the agent surfaces problems, the engineer decides.

## v1.3.4 (2026-03-29)

Fix curate command path for Claude Code — skills, not commands.

### Templates
- Updated `templates/curate.md` — changed Claude Code install path from `.claude/commands/curate.md` to `.claude/skills/curate/SKILL.md` with frontmatter example. The legacy `.claude/commands/` location is no longer discovered by Claude Code; skills require `SKILL.md` inside a named directory under `.claude/skills/`.

### Guide (README.md)
- Fixed three remaining references from `.claude/commands/curate.md` to `.claude/skills/curate/SKILL.md`: concept mapping table, "Automating the rhythm" paragraph, and "Growing from there" list.

### Adoption evidence
- [augur](https://github.com/ducroq/augur) hit the bug: `/curate` returned "Unknown skill" when installed at `.claude/commands/`. Confirmed working after moving to `.claude/skills/curate/SKILL.md` with frontmatter.

## v1.3.3 (2026-03-28)

Curate command template — automates the end-of-session self-learning loop.

### Templates
- Added `templates/curate.md` — end-of-session curation skill that automates gotcha review, pattern promotion, memory index update, and reference verification. For Claude Code, installs as `.claude/skills/curate/SKILL.md` giving a `/curate` skill. For other tools, use as an end-of-session prompt.

### Adopt prompt (adopt.md)
- Added Step 6: install the curate command during project scaffolding.
- Added curate template URL to the template list.

### Guide (README.md)
- Added curate command to the concept mapping table (Tool-Specific Setup).
- Updated "Automating the rhythm" paragraph to reference `/curate` instead of generic "please curate" phrasing.
- Added curate command to the "Growing from there" incremental adoption list.

## v1.3.2 (2026-03-27)

New anti-pattern: files with implicit runtime semantics.

### Guide (README.md)
- Added "Files with implicit runtime semantics" to What Doesn't Work — agents create config-format files "for documentation" that tooling auto-discovers and interprets at runtime (wrangler.toml, docker-compose overrides, .npmrc). Real incident: a review agent added wrangler.toml to document Cloudflare Pages settings; Cloudflare interpreted it at build time, breaking 7+ consecutive deploys.

## v1.3.1 (2026-03-27)

Negative results pattern, adoption evidence from a report-scoring adopter.

### Guide (README.md)
- Added "Negative results are knowledge" subsection under The Self-Learning Loop — documents the pattern of treating failed experiments as first-class findings that prevent future agents from retrying dead ends.

### Adoption evidence
- A report-scoring project adopted v1.3.0. Key evidence: LLM-assisted score adjustment calibrated on 64 held-out reports, proved harmful, documented as negative result in `memory/calibration-history.md`. INCOSE rule checker (Agent 6) calibrated on 186 reports — detectors tuned from 28 findings/report to 1 using corpus data.

## v1.3.0 (2026-03-26)

Self-learning review agents, non-code domain example, and three new patterns from adopting the framework for educational assessment.

### Framework
- **Self-learning agents** — New section in the self-learning loop: agents can surface their own blind spots. After completing a review, agents run a self-check against their issue categories and ask the user whether to promote new patterns. Closes the loop without requiring the user to notice patterns themselves.
- **Review agent pattern** — Formalized as a reusable skeleton. A review agent is an instruction document with: role + principles, typed issue categories, step-by-step procedure, structured output format, self-check step. Works for any domain (code review, rubric design, assessment audit, paper review).
- **Ground truth principle** — When multiple artifacts describe the same thing, designate one as canonical. Everything else aligns to it. Prevents drift when specs, rubrics, templates, and prompts all describe the same criteria.
- **Three-document pattern** — For structured evaluations, separate instructions (how to evaluate), criteria (how to score), and output template (what the result looks like) into three files. Prevents monolithic prompts that resist updates and drift from external criteria.

### Templates
- Added `templates/review-agent.md` — Reusable skeleton for domain review agents with operating principles, issue categories, review procedure, output format, self-check step, and rules. Includes comments explaining each section.

### Docs
- Added `docs/EXAMPLE-ASSESSMENT.md` — Second worked example: educational assessment system (non-code project). Demonstrates the layered model applied to university assessment with review agents, three-document pattern, ground truth principle, and self-learning loop in practice.

### Guide (README.md)
- Added "Self-learning agents" subsection under The Self-Learning Loop with flow diagram
- Added "Ground truth principle" and "Three-document pattern" under What Doesn't Work > Duplicating content
- Updated Templates section and Further Reading with new files
- Version bumped to 1.3.0

### Adoption evidence
- Framework adopted for an educational-assessment project: educational assessment system with 3 course modules (EVML ML/DL, EML), 4 review agents, and full self-learning loop. Non-code domain validates that the layered model works beyond software projects.

## v1.2.0 (2026-03-19)

In-repo memory by default, global file cliff guidance, and first ADR.

### Framework
- **In-repo memory over auto-memory** — Layer 3 location changed from "auto-memory directory (not in repo)" to in-repo `memory/` directory. Based on evidence from 28 projects where hidden auto-memory led to uncurated, orphaned, and invisible knowledge files.
- **Global file cliff** — new guidance on keeping the global instructions file lean and project-agnostic. Project-specific content belongs in project files, not the global file.
- **Commit by default** — replaced the "human benefit" heuristic for routing content. New guidance: commit memory to the repo by default; use auto-memory only for content you would never put in a repository.

### Guide (README.md)
- Layer 3 location updated to reference in-repo `memory/` with link to ADR-001
- Replaced auto-memory vs committed docs table with in-repo vs auto-memory table
- Added "The global file cliff" subsection under Cross-project knowledge
- Layer 4 location simplified to "in-repo `memory/`"
- Removed Claude Code-only note that directed non-Claude users to skip Layer 3

### Decisions
- Added `docs/decisions/` directory
- Added ADR-001: In-Repo Memory Over Auto-Memory — documents the decision, the three problems that motivated it, consequences, and migration guide

## v1.1.0 (2026-03-16)

Framework generalization, worked example, Cursor support, and adoption feedback from an early adopter project.

### Framework
- Generalized all guidance to be tool-agnostic — "project file" and "memory index" as primary terms, with tool-specific names as examples
- Agent-assisted framing throughout — retirement, course-correction, and monthly audits are agent-driven with human review
- Replaced domain-specific examples (GPU, calibration, scp/rsync) with universal scenarios (database migrations, auth patterns, debugging)

### Guide (README.md)
- Added "Works best for" qualifying section and "Minimum Viable Setup" guidance
- Added troubleshooting table (symptom → cause → fix) in Measuring Success
- Added parallel specialized review as a validation technique
- Added Cursor `.mdc` example with YAML frontmatter
- Added Layer 3 skip-ahead link for projects that don't need memory yet
- Added sections for multi-agent workflows, zero-doc projects, and feature branches
- Condensed processor cache analogy and reduced Documentation Rhythm / Self-Learning Loop redundancy

### Templates
- `memory-index.md` — "Recently Promoted" now says to retire entries immediately once they land in their destination, not at next audit
- `memory-index.md` — "Active Decisions" nudges toward creating an ADR if a decision survives more than one session
- `project-file.md` — "Before You Start" table gains an "Ending a session" row for end-of-session curation
- `gotcha-log.md` — defined `[PROMOTED]` and `[RESOLVED]` status tags
- `RUNBOOK.md` — added ~150-line document size heuristic (split and link when docs grow too large)

### Documentation
- Added `docs/EXAMPLE.md` — worked example showing populated files for a REST API project (Task Tracker)
- `METHODOLOGY.md` — added parallel specialized review as a validation technique; anonymized project references
- `templates/README.md` — points to adopt prompt for agent-assisted scaffolding

### Adoption
- `adopt.md` — review step reframed as "adjust what needs context only you have" rather than manual fill-in

## v1.0.0 (2026-03-13)

First stable release.

### Framework
- Layered model: project file (L1), runbook (L2), memory index + topic files (L3), gotcha log (L4)
- Auto-loading cliff concept with task-triggered pointers
- Self-learning loop: Capture > Surface > Promote > Retire
- Processor memory hierarchy analogy (miss cost asymmetry, eviction discipline, locality of reference)
- Promotion and retirement patterns for knowledge lifecycle
- Decision records (ADRs) as companion practice
- Session hooks and session strategy guidance
- Documentation rhythm (capture during work, curate at end-of-session)

### Templates (tool-agnostic)
- `project-file.md` — project identity, constraints, "Before You Start" table
- `memory-index.md` — auto-loaded index with topic file pointers, recently promoted section
- `gotcha-log.md` — structured problem/solution journal with promotion tracking
- `RUNBOOK.md` — operational principles and how-to

### Adoption
- `adopt.md` — agent-facing prompts for assess, adopt, and update workflows
- `templates/README.md` — tool-naming map (Claude Code, Codex, Cursor, Windsurf, Copilot, Aider)

### Documentation
- Tool-specific setup and concept mapping table
- Measuring success signals (working / failing)
- What doesn't work (anti-patterns)
- Landscape analysis, BMAD/spec-kit comparison, methodology docs
