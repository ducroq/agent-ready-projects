# Model fit: deterministic checks, gated fan-out, capability-aware reporting

## What & Why

The framework's skills were written when the model under them was the limiting factor. Opus 5 changed the shape of the problem in both directions: it over-verifies and over-delegates where the skills tell it to, and adopters on weaker models silently under-execute the same prose with no way to tell from the output.

The fix is not per-model variants (which would break the tool-agnostic constraint). It is to move checks off model judgment where possible, and make the remaining judgment report evidence instead of adjectives. Cost and portability turn out to be the same problem: a check the model executes is both expensive and capability-dependent; a check it merely interprets is neither.

Diagnosis, four-lens review battery, and the discarded alternatives are in this file's Decisions and Open Questions.

## Current Status

- [x] Diagnosed — 8 defects from model-agnostic assumptions (2026-08-08)
- [x] First plan drafted and reviewed by a 4-lens battery; **6 blockers, plan substantially rewritten**
- [x] Magnitude gate added to `review-changes` Step 1 — carve-outs authored first; single pass runs in a fresh context, not inline. **Ready.**
- [x] `refcheck.py` bug fixes — `BARE_STATE` removed, `OSError`/`UnicodeDecodeError` handling, exit non-zero when documents go unread, rung-4 coverage disclosed as a fact. File stays in `tests/fixtures/` as the oracle. **Ready.**
- [x] Cross-vendor review (DeepSeek) run on the diff — 1 genuine catch my Claude battery missed, 2 verifiably false claims. Recorded in `memory/project_multi_vendor_review_battery.md`.
- [ ] **SHELVED — promoting `refcheck.py` to the Step 4 runtime.** Attempted, reviewed twice, unwound. Two unresolved blockers, both about packaging rather than the idea:
  - `scripts/install-global-skills.sh` copies only `SKILL.md`, so the script never reaches an adopter repo. A user-global skill cannot depend on a repo-relative file.
  - The manual fallback written to cover that case carried the resolution rungs but *not* the report-shape split, the "don't call fragments written-stale" rule, or the extension whitelist — so it silently reproduced the v1.15.0 defect the runtime was meant to remove.
  - Prerequisite before re-attempting: solve distribution first (installer ships the script, or `adopt.md` scaffolds it), then extend `tests/fixtures/reference-integrity/run.sh` to cover the three new behaviours — today `build.sh` always creates siblings, so none of them is exercised.
  - Full patch of the attempt is not in the repo; the design record is this file's Decisions section, which is sufficient to redo it.
- [ ] **Next action**: baseline token cost. Grep `~/.claude/projects/*/*.jsonl` for `usage` on past `/audit-context` and `/review-changes` runs. Deferred once already — do it before the next skill edit or the before-number is gone for good.
- [ ] Extend `tests/fixtures/reference-integrity/run.sh` — `build.sh` always creates siblings, so the new rung-4-coverage, unread-document, and exit-contract paths are all untested. This is now the prerequisite for re-attempting the promotion.
- [ ] Fix the `refuted=true` contradiction in the adversarial lens (strict stance) — issue #30
- [ ] Fix `curate` Step 0.6's hypothesis-log path — issue #31
- [ ] Add counts-not-adjectives to every skill's Report step
- [x] Global install needs no refresh — `review-changes` is project-local-never-global and `audit-context` is now unmodified.
- [x] `/review-changes` full battery run — **5 blockers, 6 warnings, 2 notes**. All fixed; see Decisions.
- [ ] Not blocked. What remains uncommitted is the gate plus the script bug fixes; both passed two review batteries, and the parts that did not are shelved.

**Every edit lands in both `templates/` and `.claude/skills/`, then `scripts/install-global-skills.sh --check ~/repos`.** A templates-only edit ships nothing (issue #23, H-002).

## Decisions

- [2026-08-08] **Determinism over adaptation.** Every check moved from "the model judges" to "the model interprets a script's output" becomes model-independent — same result on Claude, Gemini, DeepSeek, Copilot. This is the portability strategy; per-model branching is rejected (detection unreliable, combinatorial, rots, and self-assessment is self-certification).
- [2026-08-08] **`refcheck.py` as the Step 4 runtime — right idea, ATTEMPTED AND SHELVED.** It removes both the ~2500-token prompt and the model-executed walk across ~276k sibling files, and was chosen over rewriting Step 4's prose (~100–1000× disproportionate for ~15k tokens/year, and worse on weaker models). It failed on distribution, not on design — see the SHELVED entry in Current Status. The script keeps its bug fixes and stays the oracle.
- [2026-08-08] **Prescription in Step 4 is a ceiling for strong models and a floor for weak ones.** Earlier instinct to de-prescribe it was reversed — it would have helped Opus 5 marginally and hurt every other adopter.
- [2026-08-08] **Magnitude gate carve-outs are authored before the rule.** `.gitignore`, renames, mode changes, frontmatter edits, new executables, and any diff that removes or loosens a check keep full depth regardless of size. Sum staged and unstaged. Rationale: the battery found ~6 bypasses, and `.gitignore` is HIGH tier precisely *because* a one-line change once exposed private content.
- [2026-08-08] **Rejected: instrument-everything-first.** Gating the work behind three runs of each skill would have cost an estimated 3–7M tokens to license cuts that need no measurement. Baseline comes free from transcripts instead.
- [2026-08-08] **Rejected: deleting `curate` Step 5.** Step 0 runs before any mutation and says "don't fix anything"; Steps 3–4 write; Step 5 is the only post-write check. Deleting it is self-certification of the skill's own output.
- [2026-08-08] **Determinism is a portability win only for code that travels.** The strongest lesson of the attempt, and it inverts what I argued for several turns. A script gives every model the same answer — but `install-global-skills.sh` copies only `SKILL.md`, so the script reached exactly one repo while the prose that had worked everywhere was deleted. A two-mode Step 4 was written to fix that and the manual mode turned out to omit the report-shape split, i.e. it silently restored the v1.15.0 defect. **Distribution is the prerequisite, not an afterthought.** Nothing deterministic currently ships to adopters at all — that is the framework-level gap this work uncovered.
- [2026-08-08] **Semver for what ships is MINOR** by `release.md` rule 2 — the magnitude gate is a new documented behavior. Rule 1 is the negative check and only rules MAJOR out; citing it as the reason was a non-sequitur.
- [2026-08-08] **Rejected: amending GUIDE's global-scope test to exempt "optional accelerators".** Written to let `audit-context` keep its script reference and stay global; reverted after review showed it was a loophole — applied to `review-changes`, which GUIDE says must *never* be global, the count of paths-it-cannot-run-without is also zero. It also converted a deliberately measurable test into a judgment call. If the promotion is re-attempted, the scope question needs a real answer, not a softened criterion.
- [2026-08-08] **Three rules the prose stated and the script did not implement**, all found by execution after review missed them: (1) "a rung you cannot run is not a pass" — the script had two states, so an unreachable sibling made every cross-repo reference a *confirmed* defect. A per-reference `UNVERIFIABLE` heuristic was tried and was wrong both ways (it excluded bare filenames, which rung 4 does resolve, and downgraded unmarked paths rung 4 could never have helped). Replaced by disclosing the fact — `RUNG 4 COVERAGE: scanned N sibling repositories` — since which references a sibling would have rescued is not knowable without the repo names. (2) `BARE_STATE` classified any lowercase top-level `.json` as runtime state — `package.json`, `tsconfig.json`, `package-lock.json` all silently absent-by-design; removed, since the documented test is a state directory or a state-file shape. (3) A missing optional doc raised an uncaught `FileNotFoundError`; now a loud `DOCUMENTS NOT READ` section, because silence there reads as "clean".
- [2026-08-08] **The script is the runtime; it is not yet proven equivalent to the prose.** The first draft of the docstring claimed "this file is normative, the prose is stale if they disagree." An external reviewer flagged that as unearned, correctly: the 16/16 fixture proves the script catches the *seeded* cases, not that it implements every rule the prose states. Those are different claims and only the first is measured. Docstring softened to say so; closing the gap is a tracked next step. Precedent: this repo's own lesson that execution and review are different instruments cuts both ways — passing a fixture is not the same as satisfying a specification.
- [2026-08-08] **Rejected: deleting the "re-read the steps that consume its output" Hard Constraint.** Incident-backed (CHANGELOG 68, 154, 212), and it specifies blast radius rather than self-verification. The first draft of this plan committed that exact defect while proposing the deletion.

## Open Questions

- How should the check reach an adopter repo at all? The installer copies one file; `adopt.md` scaffolds nothing executable. This is the blocker that shelved the promotion, and it is a framework-wide question, not a Step 4 one — nothing deterministic currently ships to adopters.
- Should `UNVERIFIABLE`/unresolved drive a non-zero exit? A correct repo in a single-repo checkout (CI, fresh clone, container) has no reachable sibling, so exit code becomes environment-dependent. Currently exits non-zero; defensible as "needs a human", but it makes the exit code a poor gate.
- Runtime capability canary — parked as H-003 in the hypothesis log, not in this work item's scope.

## Outcome

**Status**: [in progress]
**Date**: —

**What happened**: —

**What remains**: —

**Related**: issue #23 (template↔install drift), H-002, H-003, `memory/hypothesis-log.md`
