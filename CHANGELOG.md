# Changelog

All notable changes to the agent-ready-projects framework. Adopters can check their project file's `agent-ready-projects` version against this log to see what's changed.

<!-- Maintainer release process (issue #14):
     When promoting a `vX.Y.Z (candidate, unreleased)` block to a dated release,
     also tag the release commit:

         git tag vX.Y.Z <commit>
         git push --tags

     Tags let adopters `git checkout vX.Y.Z` to inspect a pinned version and
     `git diff vX.Y.Z..vX.Y+1.0 -- templates/` to preview an upgrade. -->

## v1.19.0 (candidate, unreleased)

MINOR — issue sweep of the oldest open items, closing #24–#29 (#23, older still, is triaged and deliberately left open — see *Not done*). One new deterministic step in `review-changes`, one new verification disposition in `curate`, and three corrections. **Adopter action: reinstall the global skills** (`scripts/install-global-skills.sh`) if you use `curate`; re-copy `review-changes` into your repo. Nothing breaks if you don't.

### Templates

- **`templates/review-changes.md` — new Step 1.5, structural pre-check** (closes #28). Every lens in this skill reads *content*; none asked whether the file is still valid markdown after the edit. A `|` added inside a table cell — a regex like `'recordfail|initrdfail'`, an `||` in a shell fragment — pushes the rest of the row into phantom columns. It reads fine as prose in the diff and is wrong only when rendered, so both a human reviewer and the adversarial lens pass it. Deterministic, runs at **every tier and every magnitude**, and it is a step rather than a lens because no model is needed to evaluate it.

  **The first draft of this check was wrong and the review battery refuted it by measurement.** It compared each row's pipe count against the row that opened the block and declared every mismatch corruption. GFM does not agree: a row with *fewer* cells than the header is spec-legal — empty cells are inserted, and the `| **PART ONE** |` divider row inside a wide table is idiomatic — while only a row with *more* cells loses anything, because the excess is discarded. **39% of the first draft's hits were that legal-and-short class.** A further 15% were files with no delimiter row at all (a scikit-learn tree dump is not a table). The claim "every hit is real" was mine, it was asserted without measuring the direction, and it was false.

  Rebuilt to anchor on the **delimiter row** and report only the lossy direction. Re-measured over the same scope (`find ~/repos -name '*.md'`, excluding `.git` and `node_modules`, 4381 files): **168 hits → 68**, every removed hit in a class the lenses had identified as legal, and each surviving class spot-checked as genuine data loss. Ten fixture cases now pin the behaviour — including 4-backtick fences, `~~~`-versus-``` fences, indented code blocks, tables without leading pipes, and the header/delimiter mismatch that the first draft could not see at all. One real defect it finds sits in *this repo's* gitignored `memory/`: a `<!-- verify: … || echo FAIL -->` comment inside a table cell.

- **`templates/review-changes.md` — the `Unclassified` report slot** (closes #26). Step 1 has instructed since v1.15.0 that a file matching no tier row be named in the report under "Unclassified". The Step 4 report block had no such section; the word appeared exactly once in the template, in the rule, never in the output. A rule whose output has nowhere to go is silently dropped, which is the failure class the rule was written to prevent. The section now carries **never omit** — an empty one is evidence the check ran, a missing one is indistinguishable from a check that was skipped. Same reasoning added a `Structural pre-check` count line to the summary, so the new step could not repeat the defect.

- **`templates/review-changes.md` — the guarantee-lens invariant** (closes #27). Every file named in the guarantee lens must sit in the HIGH row. The lens is HIGH-gated, so a file it defines a guarantee for that tiers below HIGH has a guarantee that can **never** be checked — and the report renders "no HIGH files changed" as a clean pass. This bites on adoption: the skill is project-local precisely because both the tier table and the guarantee lens name files in your tree, so you rewrite both, independently. In the version shipped here the invariant holds, so the template never demonstrated the constraint it depends on.

- **`templates/curate.md` — writing a verify command** (closes #29). Three rules and a new disposition, at the point where verify comments are introduced.
  - **Avoid `--`; never emit `-->`.** The first draft of this rule, and issue #29 itself, said bare `--` is "not permitted in an HTML comment body". **That is false** — the HTML Standard forbids `<!--`, `-->` and `--!>` inside a comment, not `--`, and CommonMark imposes nothing; the adversarial lens refuted it against both specs. The hazards that *are* real: `-->` truncates the comment, XML/XHTML pipelines reject `--` outright, and — the failure #29 actually observed — a naive extraction regex stops early and returns *zero* commands, so the step examines nothing and completes cleanly. Long flags being the commonest construct in shell, that last one is near-certain. Workarounds in preference order: check the artifact instead of asking the tool, set an env var instead of passing a flag, use the short flag.
  - **No unescaped `|` in a table cell** — GFM splits a row on `|` before parsing inline content, so the idiomatic `&& echo PASS || echo FAIL` truncates the row. This is the same defect the new Step 1.5 detects, and it is currently present in this repo's own memory: two framework patterns that collide.
  - **Guard host-dependent checks** so an unreachable target emits `CANNOT VERIFY: <reason>` rather than a false PASS or a misleading FAIL. Without it, a machine that is merely powered off produces a FAIL every run, and the noise trains the reader to ignore the step. **The guard ships as an explicit `if`, because the first draft shipped `guard && check || echo "CANNOT VERIFY"` and that is inverted**: `C` runs when *either* operand fails, so a reachable host whose check genuinely FAILS was reported as un-checkable — a real defect converted into a shrug, two lines under a rule forbidding exactly that. Found by the adversarial lens; the new fixture could not have found it, since its guard and its CANNOT VERIFY branch are the same condition.
  - **New disposition: CANNOT VERIFY**, added to Step 0 sub-step 5 and to the Step 6 report. The dispositions are now explicitly **ordered**, with the prefix test ahead of the exit-status tests and a stated requirement that a guard exit 0 — otherwise `CANNOT VERIFY` and `ERROR` both match and nothing says which wins. The Step 6 line said "all six numbers" while listing five: `ERROR` had never been in that summary, and this change made the omission load-bearing. Both lenses that read it caught the same defect.

- **`templates/test-fixtures/memory/verified-cannot-verify.md`** (new) and **`templates/test-verify-memory.md`** — the new disposition ships with the fixture that exercises it; 10 fixtures → 11. The guarded command exits 0 and its output contains no `FAIL`, so anything keying on exit status alone scores it as a **pass** — an unreachable check reported as a satisfied one. That is the specific failure the fixture exists to catch, and it is named in the diagnose list. The prefix is `CANNOT VERIFY:`, not `SKIP:` as first drafted: `SKIP` already means "not a state claim, correctly ignored" in this same fixture suite, and shipping two meanings for one token in one protocol is how a disposition gets misread.

- **`templates/README.md`, `templates/physics-tests/README.md`** — **`physics-tests/` is now disclosed as unproven scaffolding** (closes #25, carried forward from the closed #13). Every other template here has been exercised by this repo or a downstream consumer; this family has never been run against a live simulator. The risk was real but recorded only in gitignored `memory/`, i.e. invisible to the adopters it concerns. Disclosed in both places, because an adopter who copies the directory never sees `templates/README.md`. Same category as the Hard Constraint on self-certification: an unexercised artifact passes every check its author thought to run.

### Tooling

- **`scripts/install-global-skills.sh`** — a **relative scan root now resolves against the caller's directory** (closes #24). `cd "$(dirname "$SELF")/.."` runs at line 19, argument parsing at line 28, so `readlink -f` resolved a relative root against the repo root. It usually failed loudly; but where a same-named directory existed under the repo root it scanned the wrong tree and printed `OK — global skills match the tracked source`, indistinguishable from a genuinely clean estate. That is exactly the "a clean estate and an unscanned one are byte-identical output" defect the v1.15.0 review fixed for the non-existent and symlink cases. **Reproduced against a decoy directory before and after**: the pre-fix script reports `scanned 0 … OK` and exits 0; the fixed script scans the caller's tree, finds the seeded inert copy, and exits 1.

- **`.gitignore`** — `memory/` → **`/memory/`**, anchored to the repo root. Unanchored it also matched `templates/test-fixtures/memory/`, so any **new** fixture added there was silently unaddable and showed nothing in `git status`. The ten existing fixtures predate the rule and were unaffected, which is why it went unnoticed for as long as fixtures were not added. Found by dogfooding the new Step 1.5, which reported the new fixture as out of scope. Verified in both directions: the maintainer's root `memory/` is still ignored, and anchoring exposes exactly one file.

- **`templates/review-changes.md` Step 1.5 covers untracked and non-ASCII paths.** The first draft used `git diff` alone, which never lists a file git has not seen — so a brand-new document, where fresh corruption is likeliest, was skipped; found by running the step on this very change. Three lenses then independently found the second half: git renders a non-ASCII path as `"caf\303\251.md"`, which fails `grep '\.md$'`, so the file vanished from **both** the check and the count that exists to detect exactly that. Fixed with `core.quotePath=false`. The count is now also documented as *files in scope*, not files edited.

- **`scripts/install-global-skills.sh` — an empty scan-root argument is now a loud error.** Caught by the adversarial lens as a regression introduced by the #24 fix itself: `--check "$ROOT"` with `ROOT` unset previously skipped the scan block visibly, but after the fix it resolved to `$INVOKED_FROM/` and printed `Scanning …` / `scanned 0` / `OK`, exit 0 — a confident report about a tree nobody asked to scan. The same defect class the fix was closing, re-created one line away from it.

### Not done

- **#23** (nothing detects `templates/*.md` ↔ `.claude/skills/*/SKILL.md` drift) stays open, per its own gate in `memory/hypothesis-log.md` H-002. This release edited both files for every template it touched, but *deliberately*, having read the issue first — that is not a sample of whether they stay in sync unattended, and closing on it would be scoring a test whose answer was known in advance. For whoever builds it: the normalization is to strip the template's H1 **and its `<!-- SAVE AS: … -->` block** (14–27 lines, holding the frontmatter that `SKILL.md` carries as real YAML), after which four of five skills are byte-identical and `audit-context` differs only in `→` versus `->`.

- **Two pre-existing defects in `scripts/install-global-skills.sh`** were found by the shell lens and are filed rather than fixed here, to keep this change to its issues: `find`'s stderr is discarded, so an unreadable subtree reports `scanned 0 … OK` instead of an error; and the newline-delimited `find` loop splits a path containing a newline into two bogus FAIL lines that also defeat the self-exclusion check.

### Corrections to earlier entries

- **v1.15.0's `install-global-skills.sh` note claimed the relative scan-root case was fixed. It was not** — the symlink and non-existent cases were, but argument-parsing order was never changed. Corrected in place below; the real fix is in this release.

## v1.18.0 (2026-08-08)

MINOR — new **`update-drift`** skill: the framework-drift check, promoted from a copy-paste prompt to an installable skill. **Adopter action: install it** (`scripts/install-global-skills.sh`) — user-global, like `curate` and `audit-context`. Nothing breaks if you don't; `adopt.md` §3 still works as a prompt.

### Templates

- **`templates/update-drift.md`** (new) — Promotes `adopt.md` §3 *"Update — am I behind?"* into a skill. Of adopt.md's three prompts, §3 is the only one that fires **repeatedly** — assess and adopt fire once per project — which is what earns it a slot under the cadence rule in `docs/GUIDE.md`.

  Four things the prompt left out, each drawn from a real failure observed while running the workflow by hand across nine releases:

  - **Stamp-shape tolerance.** The prompt says "check the project file for the version line." Six shapes are in the wild, and a matcher keyed to one reports an *unstamped project* when the stamp is merely written differently — indistinguishable from "no framework adopted here." Step 0 ships a wide separator class and requires reporting stamps by file and line. It also handles projects pinning **more than one** framework, which the prompt assumed away.
  - **A four-way triage that forces a recorded reason.** *Adopt / decline-with-reason / not-applicable / already-in-force.* The prompt asked only "does this apply?", which invites a yes/no and loses the reasoning — and a decline without a recorded reason is re-derived next session, possibly differently. **"Already in force" is the outcome people forget**: a user-global skill updated outside the repo is current without anything in the repo changing, while the project file may still describe it wrongly. That case produced a real documentation correction in an adopter this week.
  - **The surfaces `git diff` cannot see.** `.claude/skills/`, `memory/`, `docs/work-items/` are gitignored in adopter repos, so a drift check driven by `git status` reports them unchanged because they are *invisible*, not because they are current.
  - **Verify by execution, not by reading.** A release's claims about behaviour are claims, and adopting one is adopting whatever is wrong with it. Prose describing a check is routinely wrong in ways that survive several readings by its own author.

  Stops before editing normative surfaces, and refuses to bump a stamp until the changes it describes have landed — a stamp running ahead of its content silences the check that would have caught the gap.

- **`templates/README.md`** — Naming map row and description, both carrying **user-global, never project-local**.

### Docs

- **`adopt.md`** — §3 now points at the skill and states why it exists, keeping the prompt as the portable fallback for tools with no skill mechanism.

### Tooling

- **`templates/update-drift.md`, `.claude/skills/update-drift/SKILL.md`** — Step 0's six stamp-shape examples now use `<framework>` / `vX.Y.Z` placeholders instead of real versions. Found by this release's own version sweep, which returned them as six hits to re-triage: what the examples illustrate is the **separator** — emphasis before or after the colon, a parenthetical, the word `framework` — not the number, so real versions there buy nothing and cost a triage pass every release. Same defect class as the hardcoded version the v1.14.0 `release.md` fix removed.
- **`scripts/install-global-skills.sh`** — `update-drift` added to `GLOBAL_SKILLS`. Worth stating plainly: that list is a **hardcoded discovery surface**, and a new global skill absent from it is invisible to both the installer and the inert-copy estate scan — the script would have reported a clean estate while ignoring the skill entirely. Verified by running `--check` before the change (correctly FAILs: specified but not installed) and after installing (clean).

### Verification

Written per the skill's own Step 4 — claims executed, not read. Lint suite passes including rule 4 (installed skills loadable). Step 0's grep was run against a real two-stamp project file and returns both stamps by line number. Every path the skill names resolves on disk.

### Versioning rationale

MINOR. Rule 1 does not fire — nothing breaks and no adopter must act to keep working. Rule 2 fires: a new template adopters install. Direct precedent: v1.13.0 (`release.md`) and v1.12.0 (`review-changes.md`), both MINOR for the same reason.

### Provenance

Prompted by external feedback (Raoul Grouls, [raoulg/codestyle](https://github.com/raoulg/codestyle)) asking whether the framework could be delivered as a skill with planning state in a `.yml`. Two parts of that were checked and declined. codestyle delivers via an **MCP server** plus markdown, not skills, and its only YAML is `.lefthook.yml` (pre-commit hooks), not planning state — so there was no planning-yml pattern to copy. The MCP delivery model had already been evaluated and declined in v1.13.1 (content is per-project by definition; file-based memory in git is what makes it reviewable), and that still holds. The **skill** half was the good idea, and it had a spec sitting unbuilt in `adopt.md` §3.

---

## v1.17.0 (2026-08-08)

MINOR — gotcha log entries get a length rule: **2-3 lines, the lesson and the action, not the narrative of the session that found it.** If an entry needs a page, that is the signal it belongs in a topic file or an ADR. **Existing adopters: re-install `curate` to pick this up.** Nothing breaks if you don't; entries just keep growing.

### Normative surfaces

- `templates/gotcha-log.md` — the rule added to the entry template comment. Worked examples unchanged.
- `templates/curate.md` Step 1, and the tracked reference install at `.claude/skills/curate/SKILL.md` — the same rule where entries are actually written, plus an explicit "new entries only; retrofitting the existing log is a separate, engineer-approved decision."

### Why this exists

An agent writing a gotcha log defaults to far more detail than is useful. Measured on this repo: median 255 words per entry against the 104- and 185-word worked examples the template ships — so entries drift longer than the template's own examples teach. The cost recurs, because a log is re-read in full on every load, and the surplus detail is disproportionately the specifics that don't generalise.

### Attempted and reverted: a longer version of the same rule

The first draft added a cut-list — "cut how you found it, **what you ruled out**, **who noticed**" — and shortened both worked examples. A three-lens review battery refuted it and it was reverted rather than patched. Four separate defects, each worth recording because each is a way this kind of edit fails:

- **"who noticed" contradicted `templates/coordination.md`**, which *mandates* tagging entries with a contributor handle, and `docs/GUIDE.md`, which uses those handles for a promotion rule ("a gotcha in two contributors' sessions is as strong a signal as three recurrences"). Stripping the handle would have silently disabled that rule.
- **"what you ruled out" contradicted `docs/GUIDE.md`'s dead-ends guidance** — "the gotcha log captures what you *tried and walked away from*" — which is the same content under a different name.
- **The shortened examples lost their only concrete commands** (`ProtectHome=read-only`, `systemctl start` / `docker run` / CI trigger) and replaced a working verify command with an empty `<!-- verify: -->`, which `curate` Step 0.5 runs and reports as **ERROR**. The template would have shipped a permanent false positive.
- **It ran 329 words to enforce a 100-word cap**, on surfaces loaded every session.

The shipped rule is three lines and adds no cut-list. Its line budget is 2-3 lines to match `docs/GUIDE.md`, which already said so in two places — the first draft said "three or four" and contradicted it.

### Versioning rationale

Rule 1 does not fire — no consumer must act. Rule 2 gives MINOR: a new documented convention that changes agent behaviour, which the bump table lists under MINOR. Follows v1.11.0, also MINOR for new documented principles. Not the v1.16.1 PATCH precedent — that covered *defect fixes* inside shipped skill prompts, not a new rule.

## v1.16.2 (2026-08-08)

PATCH — three of the maintainer's private repositories were named in shipped files. Removed and replaced with neutral placeholders. **No action required**: nothing changed except example text, and an adopter who never re-installs keeps working behaviour identical.

### Normative surfaces

- `templates/audit-context.md` and the tracked reference install at `.claude/skills/audit-context/SKILL.md` — Step 4's rung-4 worked example used a real private repository name. Renamed to the placeholder `SiblingRepo`. The rule, the rungs and the matching behaviour are unchanged; only the name in the example differs.

### Documentation

- `docs/decisions/ADR-001-in-repo-memory-over-auto-memory.md` — the auto-memory path example now reads `C--local-dev-<project>/memory/`.
- `CHANGELOG.md` — the v1.11.0 origin note no longer gives a private repository path.

Public siblings (`agent-ready-papers`, `augur`, `podcast-generator`) are deliberately retained; that decision is recorded under v1.14.0.

### Why a release for an example rename

The names entered *after* the v1.14.0 de-identification pass, while writing the v1.15.x Step 4 examples — real repositories are the examples nearest to hand. A one-off sweep cleans; it does not prevent. No check currently guards this boundary, so the same thing can happen again on the next release that adds an example.

### Versioning rationale

Rule 1 does not fire — no consumer must act. Rule 2 gives PATCH: no new artifact, changes confined to existing ones. Follows the v1.10.1 doc-only precedent and v1.16.1, also a PATCH for edits inside shipped skill prompts.

## v1.16.1 (2026-08-08)

PATCH — two skill-prompt defects fixed, both found by running the framework's own review battery on itself. **Existing adopters: re-install `curate` and `review-changes` to pick these up.** Nothing breaks if you don't; you keep the old behavior.

### `review-changes` — the adversarial lens contradicted itself (#30)

The lens prompt said `Default stance: refuted=true` and, in the same breath, `Only mark as REFUTED if you find a concrete problem`. Those set opposite defaults. A capable model resolves the ambiguity sensibly; a weaker one may not, and this framework is tool-agnostic by constraint — ambiguity in a shipped procedure is a portability defect, not a style issue.

Now one stance, stated once: go in assuming the change is refutable, report REFUTED with a concrete failure, report NOT REFUTED only after a thorough attempt fails to produce one.

**The wording matters more than it looks, and two attempts got it wrong.** The first removed the contradiction by deleting *both* halves — which dropped the only concreteness gate on REFUTED and left the surrounding text pushing hard toward refuting. That is a loosening in the false-positive direction: the same failure v1.15.1 had just finished removing from `audit-context` Step 4. The second added a gate phrased as *"name the input that triggers it"* — unachievable for a static contradiction between two prose files, which is the dominant defect class in a framework that ships prose. It would have suppressed every finding the review battery actually produces. The shipped text names contradictions explicitly and says not to withhold one for lacking a repro.

### `curate` — Step 0.6 scanned a path this framework does not use (#31)

Step 0.6 read only `docs/hypothesis-log.md`. Step 1 of the same skill already handled the dual path correctly for the gotcha log; Step 0.6 never got the same treatment. Under this framework's own in-repo-`memory/` Hard Constraint, `memory/hypothesis-log.md` is where the file belongs — so the step looked in the one place it would not be.

Observed here: this repo's hypothesis log has an open entry whose `Review by:` condition fired on 2026-08-08, and `/curate` would never have surfaced it. It was found by hand. That is precisely the failure the step exists to prevent.

Step 0.6 now checks **both** paths unconditionally, which is correct wherever a project actually keeps the file.

### Attempted and reverted: a wider sweep

Issue #31 also asked for a sweep for the same single-path defect elsewhere. The obvious candidate — `audit-context` Step 5's `every topic file in memory/` — was changed to name a `docs/` alternative, and then **reverted**, because `docs/*.md` as the topic-file location is not a thing this framework defines: the naming map has no topic-file row, and `docs/GUIDE.md` states that for a tool without auto-memory everything goes into the project file. Applied to this repo it would have reported all 12 files in `docs/*.md` — the guide, the rationale doc, ten essays — as orphaned topic files.

The real question is now **issue #32**: what should Step 5 do when the project's tool has no Layer 3 at all? Three candidate answers are recorded there; none is obviously right, and guessing produced something worse than the bug.

### Consumer notes

- **New adopters**: nothing to do — the templates carry the fixes.
- **Existing adopters**: re-install `curate` (user-global) and `review-changes` (project-local). No action required to keep working; the old copies behave as before.
- No memory-layout, step-numbering, or naming-map changes. `curate` Steps 0-6 and `audit-context` Steps 1-8 are unchanged in structure.

### Versioning rationale

Rule 1 does not fire — no existing consumer must act to stay working. Rule 2: no new artifact; both changes are refinements confined to existing templates → PATCH. Direct precedent: the v1.13.0 entry records the structurally identical `curate` Step 0.2 fix as *"would have been PATCH on its own (refinement of an existing template)"*.

## v1.16.0 (2026-08-08)

MINOR — a magnitude gate for `review-changes`, so a small diff no longer spawns the full lens battery. **Adopter action: none.** Existing installs keep working; re-install the project-local skill to pick up the gate. No memory-layout or template-structure changes.

### The problem

`review-changes` picked depth from **path** alone. Any diff touching `templates/**` or `.claude/skills/**` got 3–4 concurrent review subagents, each re-establishing context from zero — whether the change was a full template rewrite or a two-line typo fix. Measured against this repo's last 40 commits, **12 were under 20 lines and touched no dangerous path**, and every one of them paid for four reviewers.

### The gate, and why the exceptions come first

Step 1 gains a magnitude gate: under 20 changed lines gets one adversarial pass, 20–200 keeps the path tier, over 200 gets the full battery regardless of tier.

The exceptions are stated **before** the size rule and override it, because the changes most likely to cause harm are the ones smallest by line count:

- `.gitignore` — one line here has exposed private content in a public repo
- Renames, moves, and permission changes — `git diff --stat` reports these as **zero insertions and zero deletions**
- Binary files and submodule pointers — the other two members of the zero-line class
- Any shell script or executable, in `scripts/**` or `tests/**` — code that runs on someone else's machine, and shell breaks in one character
- Any non-frontmatter edit under `.claude/skills/**` — a defect there ships to every install derived from it
- **Any diff that removes or loosens a check** — loosenings are characteristically a handful of lines, and this is the class the seeded-true-positives rule exists for

Step 1 now also runs `git diff --summary`. `--stat` alone cannot see a mode change, a rename, a submodule, or a binary — three of those are carve-outs, and a carve-out you cannot observe is not in force.

Size means the whole change that will land: staged, unstaged, **and local commits not yet pushed**, with a stated fallback for a branch with no upstream. Line count is a weak proxy in these one-sentence-per-line templates, so the gate says plainly that when the count and your read of the change disagree, the count is wrong.

The trimmed pass still runs in a **fresh context**. Reviewing your own edit in the context that produced it is the self-certification failure the skill exists to prevent; the saving comes from one independent reviewer instead of four, not from dropping independence.

### Measured

Against this repo's last 40 commits: **12 trimmed** from four lenses to one, **6 small commits correctly held at full depth** by a carve-out, 7 at or over 200 lines unaffected. The carve-outs catch a third of all small commits, so they are load-bearing rather than decorative. That ratio reflects this repo's commit pattern; a project that works in larger chunks will see less.

### Also in this release

- `templates/README.md`, `CLAUDE.md`, and `docs/GUIDE.md` each described review depth as path-driven only. All three now mention the gate — they were describing behavior that no longer matched the skill.
- `tests/fixtures/reference-integrity/refcheck.py` (maintainer-only, not templatized) — four defects fixed in the Step 4 test oracle: a rule classifying any lowercase top-level `.json` as runtime state, so `package.json`, `tsconfig.json` and `package-lock.json` read as correctly-absent; unhandled `PermissionError` / `UnicodeDecodeError` / `NotADirectoryError` killing a run mid-audit; exit 0 when zero documents were read, indistinguishable from a clean audit; and rung-4 coverage now disclosed as a fact (`scanned N sibling repositories`) rather than left implicit. A wrong oracle certifies wrong prose, so these harden the sensitivity harness that gates Step 4 changes.

### Attempted and shelved: `refcheck.py` as the Step 4 runtime

Promoting the reference-integrity script from test oracle to the actual runtime for `audit-context` Step 4 was built, reviewed twice, and unwound. Recorded here so it is not rediscovered cold.

The idea holds — the model walking ~70 references through four resolution rungs, including a traversal of every sibling repository, is the most expensive step in the framework, and a script gives every model the same answer. It failed on **distribution**, not design:

- `scripts/install-global-skills.sh` copies only `SKILL.md`. A user-global skill cannot depend on a repo-relative script, so Step 4 would have been un-runnable in every adopter repo while the prose that made it portable was deleted.
- The manual fallback written to cover that case carried the resolution rungs but omitted the report-shape split — silently reproducing the v1.15.0 defect that v1.15.1 had just fixed.

The general lesson: **determinism is a portability win only for code that travels.** Nothing deterministic currently ships to adopters at all — `scripts/` holds one Claude-Code-specific installer and `adopt.md` scaffolds nothing executable. That gap is the prerequisite for any future attempt. Design record in `docs/work-items/model-fit.md`; a note in the script's own docstring points there.

### Versioning rationale

Rule 1 does not fire — no existing consumer must act. Rule 2 does: the magnitude gate is a new documented behavior in a normative template. MINOR, following the `v1.12.0` precedent that shipped `review-changes.md` itself, and above the `v1.10.1` doc-only-is-PATCH line.

## v1.15.1 (2026-08-06)

PATCH — `audit-context` Step 4, plus the first committed test fixture for it. Adopter action: re-install the global skill (`scripts/install-global-skills.sh`). No template or memory-layout changes.

### The failure this fixes

Step 4 put **139 items** in front of a human on one adopter repo — 47 reports plus 92 references labelled "written stale" — and **none of the 47 was real**. It was the second consecutive audit of that repo to find nothing, which is the signal that the check, not the repo, is broken. After this release the same documents yield **12 findings**, with 129 references enumerated as resolved-below-rung-1 and 1 asserted-absent.

Both numbers come from `tests/fixtures/reference-integrity/refcheck.py`, which implements the old rules under `--legacy`, so the "before" is re-derivable rather than remembered. That matters here: the first attempt at this fix quoted a before-number that no committed instrument could reproduce.

### The central defect was a sentence, not a mechanism

*"A path that resolved at rung 2 is still written stale and worth correcting."* Two populations resolve at rung 2 — a file that **moved** (decay), and prose naming a file by its meaningful suffix under an established base (**house style**). Nothing about a single reference separates them.

A first attempt classified each *document* by the share of its references resolving at rung 1 and suppressed fragments below a cut-off. **That was withdrawn before release**, because an adversarial fixture showed it was worse than the problem: on the repo it was calibrated against no document crossed the cut-off, so the "list the outliers" branch was dead code and the rule was 100% suppression; it created a blind band where a 4-reference document with one stale fragment can never cross; and it hid **deletions**, because where a same-suffix twin survives in another package, deleting one file *reduced* the report by downgrading a collision to a silent resolution.

The shipped fix suppresses nothing. Output splits into **findings** (unresolved and collisions), **resolved below rung 1** (every weak resolution, enumerated with what it matched, so a wrong-twin match is visible), and **skipped as asserted-absent**. No constant, no blind band, nothing hidden.

### Six mechanical defects

- **Rung 3 joined exactly instead of suffix-matching inside the sibling** — "SiblingRepo's `deploy_filters.sh`" is `SiblingRepo/scripts/deploy_filters.sh`.
- **Rung 3 did not carry rung 2's collision rule** across with its matching, so two sibling files matching one fragment came back as a clean hit.
- **Rung 3 outranked rung 4**, letting a neighbour claim a file the audited repo's own runtime writes — a provenance that is simply false.
- **The cross-repo marker was a substring, and a path could mark itself** — "infrastructure" marked a repo called `infra`, and `docs/DEPLOY.md` marked a sibling repo named `docs`, after which any broken `docs/X.md` resolved next door.
- **No extension whitelist** — every dotted identifier (`re.sub`, `json.dumps`), bare domain (`storm.mg`) and version number (`3.1`) became a phantom reference. 20 of them on the measured repo.
- **Sibling discovery globbed one nesting depth**, missing repos at `~/repos/<repo>` when the audited repo sits at `~/repos/<org>/<repo>`.

Deletion markers (`> **Deleted**:`, `~~struck~~`) now join `! test -f` as assertions of absence — but **scoped to the marked span, not the line**. Line-scoping was itself a regression: it silently dropped 4 references on 2 lines of the measured repo, 3 of them load-bearing files, because session logs use `~~done~~` as their completion convention and so carry strikethrough on their densest reference lines.

### Guardrails

Because this makes the step **more permissive**, and the evidence for that is a run that found nothing — which measures specificity and cannot measure sensitivity — the release ships a fixture instead of a claim:

- `tests/fixtures/reference-integrity/run.sh` seeds **11 genuine breaks** and **5 cases that must stay silent**, and asserts all 16. Crucially it seeds the failures the change newly *permits* (a deletion with a surviving twin, a path that supplies its own marker, an unlisted extension, an ambiguous cross-repo match), not just the ones it was designed to preserve. The first attempt's fixture tested only the latter and passed 7/7 while carrying six defects.
- Step 4 now requires reporting **what the extractor dropped** — extensions present in the tree but absent from the whitelist — because a skip is the one outcome with no rung to name.
- **Zero is not the target.** Instructional placeholders and files a runbook tells you to create are meant not to resolve; a change driving the count to zero has disabled the check.

## v1.15.0 (2026-08-06)

Skill **scope** becomes a framework decision rather than an adopter guess: `curate` and `audit-context` install user-globally, `review-changes` and `release` stay project-local, and the reference installs in `.claude/skills/` become tracked so a global install can be derived from something versioned. Plus the `audit-context` step that closes the loop `adopt.md` §3 opened. MINOR — new artifact (`scripts/install-global-skills.sh`), new lint rule, new skill step; nothing existing breaks, but adopters have real work to do.

### The failure this fixes

A user-global skill **shadows** a project-local one of the same name — it wins, silently, with no merge and no warning. That fact appeared nowhere in this framework, while `docs/GUIDE.md`, `adopt.md`, and `templates/README.md` all instructed adopters to install every skill *project-locally*. The result across one adopter estate: **45 shadowed local copies in 23 repos**, each reading as the authoritative version while never being loaded, and each free to drift from the copy actually in use. Three of them had diverged in three different directions before anyone noticed. Separately, the only frontmatter-correct copies of these skills lived in this repo's **gitignored** `.claude/`, so the canonical artifact was invisible to git since the initial commit, and had drifted from `templates/` without anything able to detect it.

### Docs
- **`docs/GUIDE.md`** — New `### Where a skill lives: user-global or project-local` under The Documentation Rhythm. States the shadowing rule and the consequence that follows from it: installing globally *forecloses* per-repo variants, so the question is not "is this generic today?" but "will any repo ever need its own version?" Ships the per-skill scope table, the two safety rules (derive globals from a tracked source; never leave an inert local copy), and a measurable generic-vs-specific test — count references to paths that exist in only one repo. The four install paragraphs above it were rescoped to match; they had all said project-local. TOC updated.
- **`adopt.md`** — STEP 6 rewritten. Installs `curate`/`audit-context` to `~/.claude/skills/`, and explicitly forbids copying `templates/*.md` into a `SKILL.md` path: those carry their frontmatter *inside* a `<!-- SAVE AS: -->` comment, so a verbatim copy has no frontmatter and never registers. One adopter shipped three skills that way and none had ever loaded. Also: if a global install already exists, do not create a local copy.
- **`templates/README.md`** — Naming map and descriptions carry the scope for **all five** skills, including "project-local, never global" for `review-changes`. This took two passes: the first gave three of the five a scope marker and left `release.md` and `test-verify-memory.md` reading "save as `.claude/skills/…`" with no scope — the exact guess this release exists to remove — and the naming *map* row for `test-verify-memory` kept the bare path even after its prose bullet was fixed. The table is the surface adopters copy from; a scope stated only in the prose below it is not stated.
- **`CLAUDE.md`** — New Hard Constraint stating the shadowing rule and the two normative consequences; new Before You Start row routing skill moves through the new script. The architecture diagram still labelled `.claude/` "gitignored — not shipped", contradicting both the new Hard Constraint and the not-shipped table in the very next section; `scripts/` was absent from the diagram and from Key Paths entirely. Both fixed — a new shipped directory has to appear in the map an agent orients from, or it does not exist.
- **`docs/GUIDE.md`** — The `audit-context` capability list had gone stale against this same unreleased version: it omitted Step 6 (framework version drift) and still said "topic file reachability" for what is now topic-file *and work-item* reachability. The scope table gained a `test-verify-memory` row — `scripts/install-global-skills.sh` had been treating it as project-local while the table that is supposed to be normative did not list it at all.

### Templates
- **`templates/audit-context.md`** — Two additions. **Step 4** gains three false-positive exclusion classes (cross-repo paths; negated `! test -f` assertions inside `<!-- verify: -->` comments; runtime state absent from a dev checkout), which existed only in this repo's live skill and had never been promoted upstream — so every adopter installing from `templates/` got the version that cries wolf. **New Step 6, Framework version drift**, closing the loop `adopt.md` §3 opens: it compares the project's stamp against this changelog. It explicitly refuses to assume one stamp format — at least four are in use in the wild (`agent-ready-projects: v…`, `framework: agent-ready-projects v…`, a bullet, and prose; two further shapes were found after that count was written) and a matcher keyed to one reports an *unstamped* project when the stamp is merely written differently. It also treats "reviewed and declined" as current rather than stale. Steps renumbered 6→7, 7→8; `review-changes`' guarantee lens updated to match.

  **Step 4 was then rewritten again**, after running the new version against a real adopter repo. The per-class exclusions were the wrong shape: every class keyed on a *fully-qualified* path, and almost no reference in prose is fully qualified. The audit flagged 9 broken references and **all 9 were false** — 4 cross-repo paths written as bare basenames (no repo prefix for class 1 to check), 2 runtime-state files written bare (class 3 matched only `data/<name>.json`), and 3 path *fragments* of files that exist (`models/temporal.py` for `src/models/temporal.py`), a shape no class covered at all. Pattern matching is replaced by a **resolution order**: try the path as written, then as a path *suffix* of a file in this repo, then in a sibling repo, then as runtime state (gitignored **and** generated at runtime is sufficient — reaching the deployment host is confirmation, not a requirement). Negated `! test -f` assertions are decided *first*, before the order runs, because they turn on the reference's intent rather than on whether the path resolves — an earlier draft placed them last and justified it with "they fail all four resolutions by design", which is simply false: `! test -f docs/OLD.md` resolves at rung 2 the moment any `archive/OLD.md` exists. Two rules keep the loosening honest: **a rung you cannot run is not a pass** (no sibling repos, a sandboxed agent, an unreachable host → report *unresolved* and name the rung, never suppress and never confirm), and a path that resolved below rung 1 is still written stale and gets reported as such. The trade is stated plainly in the step itself — this is a strictly *more permissive* check that buys specificity with sensitivity, which is right for a check nobody trusts but is not a free improvement. Also fixes the grammar bug the third class introduced ("three classes … **both** recurred").

- **`templates/review-changes.md`** — Risk tiers had no row for `.claude/skills/*` or `scripts/*`, both of which this release turns into shipped content, and no defined behaviour when a changed file matched no row at all — so new shipped surfaces were reviewed at whatever tier something else in the diff happened to trigger. The HIGH row is now stated as *the normative surface* and carries `adopt.md` and `/README.md` (which `CLAUDE.md` names normative but no tier listed), plus `scripts/**`, `.claude/skills/**`, and `.gitignore` — that last one because a single line there decides what is published at all, and in this very release a `.gitignore` change published private repo names into a public repo. The glob semantics are now stated rather than assumed: `**` crosses directory levels, a leading `/` anchors, and the most specific pattern wins. The first draft wrote `.claude/skills/*`, which under the table's own semantics matches the *directory* and not the `SKILL.md` inside it — the row was decorative, and the two skill files in this diff were only reviewed at HIGH because a template happened to change alongside them. Unmatched files default to MEDIUM, are named under "Unclassified" even when a HIGH file makes the tier moot, and escalate to HIGH if they are executable or copied into an adopter's tree. The guarantee lens gains entries for `adopt.md` and `scripts/*.sh`.

### Tooling
- **`scripts/install-global-skills.sh`** (new) — Installs the global skills *from* the tracked `.claude/skills/`, verifies they match, asserts no project-local-only skill has been installed globally, and with a root argument scans an estate for inert local copies. Hostile-repo tested against 20+ repos including ones with lockfiles and vendored trees: found 45 real issues, now returns clean. `_archive/` is excluded by design and is **not** scanned; copies there are left alone deliberately.
- **`tests/lint/run.sh`** — New rule `[4/5] installed skills are loadable`: every `.claude/skills/*/` has a `SKILL.md`, opens with frontmatter, and its `name:` matches the directory. Rule 3 checks that a *template* carries installable frontmatter; nothing checked that an *install* converted it. Verified against all three real defect shapes (missing `SKILL.md`, template copied verbatim, `name:` mismatch) rather than only against a passing tree.
- **`.gitignore`** — `.claude/` → `.claude/*` + `!.claude/skills/`. The reference installs are the framework's own dogfooding and the copy adopters install from, not maintainer-local state; `memory/` and `settings.local.json` stay ignored.

### Adopter notes

**Existing adopters, act on this:** if you installed `curate` or `audit-context` project-locally *and* have a global copy, the local one is inert — delete it, don't reconcile it. Verify with `scripts/install-global-skills.sh --check <your repo root>`. If you have no global copy, install one from `.claude/skills/` rather than converting the template by hand. If you customized a local `curate`, that customization has not been in effect; move the content to your project file instead.

**`review-changes` must not be installed globally.** Its risk tiers and guarantee lens name files in a specific tree; one global copy would silently disable every repo's own.

### Versioning rationale

MINOR. Rule 1 does not fire — nothing breaks and no adopter *must* act to keep working, though many should. Rule 2 fires three times over: a new shipped script, a new lint rule, and a new step in a shipped skill are each new artifacts or new behavior under the v1.10.1 precedent. The `.gitignore` change is packaging, not content, and would not have justified a bump alone.

### Review notes

A full 4-lens `/review-changes` battery **was** run on the first draft of this change, and found the change shipping the very failures it describes. All fixed here; the numbers are recorded because the pattern is the point.

- **The commit re-introduced private repo names into a public repo.** `.claude/skills/audit-context/SKILL.md` named three sibling projects; the *template* version of the same passage had been correctly de-identified in v1.14.0. Tracking a previously-gitignored file published content that had never been reviewed as public. Fixed by de-identifying the tracked skill and amending rather than following up — a later commit does not remove names from history.
- **The tracked `release` skill was committed already stale** — pre-v1.14.0 content, missing the version-agnostic sweep. The premise of the change is that tracking makes drift visible; it committed a drifted artifact and no check could see it. Resynced.
- **`adopt.md` STEP 6 was unexecutable as written**: it named a bare relative path with no URL while forbidding the only previously-available route. The adopt prompt reaches agents over GitHub URLs with no clone step, so an agent following it literally could install nothing. Raw URLs added.
- **Three surfaces still stated the old policy**: `docs/GUIDE.md`'s tool-specific concept map, both skill templates' `SAVE AS:` headers, and `CLAUDE.md`'s "what is intentionally not shipped" table — the last actively contradicting the Hard Constraint two sections above it. A policy change lands in more places than the paragraph that states it.
- **`install-global-skills.sh` reproduced its own target failure**: `--check` exited 0 on a scan root that did not exist or was a symlink — a clean estate and an unscanned one were byte-identical output. A symlinked global install compared byte-identical to itself, making drift structurally undetectable, which is the exact configuration the script exists to replace. Both fixed, plus `pwd -P` (a symlinked invocation flagged the framework's own tracked skills as inert and told you to delete them).

  **Correction (v1.19.0):** this entry originally also claimed the *relative* scan-root case was fixed. It was not. The `cd` still preceded argument parsing, so a relative root kept resolving against the repo root; see issue #24 and the v1.19.0 entry. The claim stood for four releases because nothing re-ran the case it described — the same shape as the defect it was describing.
- **Lint rule 4 passed unclosed frontmatter** — the fields were harvested from the body, so a file that cannot register scored green — and false-failed on `name: "quoted"`, a trailing space, and CRLF checkouts. A Windows adopter would have seen every skill fail with a message naming the wrong cause.

The lens findings that produced this list were each verified by reproduction before being accepted, and each fix was re-tested against the reproduction rather than against a clean tree. Two lens claims were **not** accepted: that the `${hit%…}` expansion and the process-substitution `ISSUES` counter were buggy — both were traced and found correct.

A **second** battery was then run on the Step 4 rewrite and the tier-table change, and found the same shape a third time: the fix for a cries-wolf check had itself become a check that could never fire. Basename matching would have silently resolved a deleted `.claude/skills/curate/SKILL.md` against any other `SKILL.md` in the tree — the precise defect this release exists to make visible. An unrunnable rung had no defined disposition, so the step could read as either "report everything as before" or "never report anything", with nothing in the text choosing. `.gitignore` matched no tier row at all. And the changelog's own justification for the negation rule was false. All fixed above. Two findings were **not** accepted: that `README.md` and `scripts/` are wrong to put at HIGH in an adopter-facing template — anchoring `/README.md` addresses the real ambiguity, and an adopter whose `scripts/` is ordinary build tooling can retier it, which is why the skill is project-local by design.

**That gap is now closed, and closing it changed the artifact.** The Step 4 rewrite was executed verbatim over **1877 real path references in 26 repos**, against **311 seeded genuine breaks** chosen to be adversarial — paths that do not exist but whose basename does exist elsewhere in the same tree. The first run **refuted** it at 96.6%: 10 real breaks slipped through, and none was noise. Eight came from rung 4 treating *gitignored* as sufficient — one repo gitignores `.claude/`, so every fabricated path under it resolved, including a literal `ZZ-DEFINITELY-GONE.md`; the text said "gitignored **and** generated at runtime" but gave no way to establish the second half, so the checkable half won. Two came from rung 3 having no cross-repo marker, letting a bare `.claude/README.md` resolve against a neighbouring repo by coincidence. A third defect surfaced from ground-truthing the reported breaks: rung 2 searching the git *index* rather than the working tree made four live references in this very repo report broken, because `memory/` is gitignored — this framework's own recommended setup.

All three are fixed in the shipped text, each re-validated by re-running: **311/311 seeded breaks caught**, with 54.3% of real references resolving as written, 24.7% resolving only as a fragment (reported as *written stale* rather than broken — these are the references the old check called broken one hundred percent of the time), and 20.9% reported. What remains unmeasured is precision on that 20.9%; spot-checking found every sampled break genuine once the index bug was fixed, but no exhaustive audit was done. That is a smaller claim than the one that was open.

Worth recording for the versioning rationale, because it is the reusable part: two full review batteries read this text closely and found neither the gitignore hole nor the index bug. **Running the artifact found all three defects in one pass.** For a procedural artifact, execution is not a nice-to-have on top of review — it is a different instrument that sees a different class of defect.

Also corrected in this pass: GUIDE.md now records that directory-scoped skills are *namespaced* (`apps/web:curate`), not shadowed, so the blanket "a local copy is inert" claim does not hold in monorepos.

---

## v1.14.0 (2026-08-03)

New **Verification Hooks** section in `docs/GUIDE.md` — the deterministic counterpart to session hooks, closing the edit → check → fix loop without a human relaying the error. Plus a release-skill fix for the class of staleness that let two templates sit three minors behind, and a full de-identification pass over this public repo. MINOR — new concept and new skill behavior, nothing breaks.

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
- **`CHANGELOG.md`** — Corrected three false issue references: v1.12.0 claimed "Closes #22" (which did not exist at the time) and both v1.11.0 and v1.11.1 claimed "Closes #21" (open, and about unrelated news-aggregator memory-audit patterns). Restored the missing `## v1.11.0` and `## v1.11.1` version headings — both were tagged but appeared only as untitled blocks after a `---`.

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

Filed as #19 (2026-07-08) from a learn-from-BDS pass (a private sibling repo's `LEARN-FROM-BDS.md`, capability #1). BDS's `ai-wiki` proposed two transferable rules; **only the content-write boundary was adopted.** The other — quantified note decay (`confidence × exp(−days/τ)` frontmatter) — was **declined on principle**: it reintroduces the frontmatter schema this guide deliberately rejected ("lightweight by design. No frontmatter schema, no mandatory fields") and its `confidence` score is unsourced precision of the kind removed in v1.10.5/#18; the framework's existing `<!-- verify: -->` comment checks ground truth (PASS/FAIL) rather than time-since-touch, a stronger staleness signal. A third folded-in note (esm.sh single-file demo shape) was declined as out of scope for a tool-agnostic layered-memory methodology.

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
- **`templates/project-file.md`** — "Before You Start" gains a new top row: **Starting any session** → compare the `framework: agent-ready-projects vX.Y.Z` header line against `CHANGELOG.md` (GitHub URL or local clone). If behind, surface the drift before starting work. Don't auto-update — adopting changes is the engineer's call. Closes the gap where adopted projects could fall multiple versions behind without anyone noticing (e.g., the news-aggregator project ran on v1.7.0 from adoption through 2026-05-09, never flagged).
- **`templates/curate.md`** — Two extensions to Step 0 freshness check:
  - Sub-step 6 ("Hypothesis log surface"): `/curate` flags entries past their `Review by:` date and entries whose `Revisit trigger:` has fired. The skill surfaces — it does not resolve — to keep the hypothesis-log discipline (engineer applies Method, agent doesn't shortcut it).
  - Sub-step 7 ("Project file size budget"): `/curate` checks the project file against the 40k Claude Code perf threshold. The most common cause of bloat is session-narrative footers (`_Last updated: ..._` / `_Earlier ..._`) accreting across sessions while the same content already lives in `memory/project_session_*.md` and is indexed in `MEMORY.md` — pure duplication. Rule: keep at most one footer block, drop older `_Earlier_` blocks. Step 3 gets a paired discipline note: don't accrete narrative onto the project file footer in the first place; it belongs in session-memory files.

### Guide (`docs/guide/04-the-rhythm.md`)
- "During work" diagram + prose updated: provisional positions get a fourth capture path alongside gotchas, topic-file learnings, and ADRs. Explicit contrast with ADRs ("decision frozen") to prevent confusion.
- End-of-session flowchart: new step "3.5 Hypothesis log surface" between memory-index update and doc sync.

### Origin

**Hypothesis log** emerged on a news-aggregator project (`docs/hypothesis-log.md`, first commit 2026-04-19) where Claude was scheduling cron-style reminders for predictions that needed to be tested. The cron approach checked *that* you remembered, not *whether the prediction was right*. The Method field — written before the data — turns each entry into a small pre-registered experiment. After several months of use it became clear the pattern wasn't project-specific. The augur EXP-009 milestone-3 review battery surfaced multiple "we'll see how this performs in 14 days" cases that were good fits, prompting promotion here.

Compared to existing tools:
- ADRs freeze rationale at decision time. Hypothesis entries are the *bet* before the rationale fully settles.
- Gotcha log captures problems with known root causes. Hypothesis entries capture predictions whose root cause is *what we're trying to learn*.
- TODO captures tasks. Hypothesis entries capture *expectations*, with the trigger that brings them back.

**Session-start drift check** emerged when one adopter's CLAUDE.md hit Claude Code's 40k perf warning on 2026-05-09 and inspection showed the project still pinned to `agent-ready-projects: v1.7.0` — two minor versions behind, undetected for months. The intent that adopters track framework drift had no enforcement: the "Update" prompt in `adopt.md` requires the user to manually paste it into a session, while the version line in the header was inert metadata that no instruction told the agent to act on. The fix is the cheapest possible mechanism: a task-triggered pointer in "Before You Start" that uses the same idiom as every other row in the table. Tool-agnostic; works for Claude Code, Cursor, Codex, Aider, Copilot.

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
- Added to "Ahead" positioning section with reference to the news-aggregator incident and ETH Zurich finding.
- Added Superpowers (151K+ stars) to Category 3 and positioning diagram.

### README
- Version bumped to 1.9.0.

### Origin

Issue #10, building on issue #8. The v1.8.1 fix (distinguish observations from deployed state) was guidance-only — it told agents what to do but provided no mechanism. Self-verifying memory closes the loop: verification commands travel with the claim, are executed when the claim is consumed, and are audited during curation. The news-aggregator incident (230 articles affected by a false "shipped" memory) demonstrated that guidance alone is insufficient when future sessions trust memory entries unconditionally.

---

## v1.8.1 (2026-04-14)

Memory hallucination prevention — distinguishing session observations from deployed state, plus landscape update.

### Guide (`docs/GUIDE.md`)
- New paragraph "Distinguish observations from deployed state" in Layer 3 memory guidance. Explains the observation-vs-state conflation, advises qualifying claims with verification commands, warns against unqualified "shipped" entries.
- Version bumped to 1.8.1.

### Templates
- **`templates/gotcha-log.md`** — New worked example: memory claimed "shipped" but feature only existed in a running process (based on news-aggregator incident, 230 articles affected). Shows the pattern and the fix.
- **`templates/curate.md`** — Added freshness check step 5: "Unverified state claims." The `/curate` skill now scans memory for "shipped"/"deployed"/"live", flags entries without verification commands, and runs existing verification commands to check for failures.

### Landscape (`docs/LANDSCAPE.md`)
- Added [Superpowers](https://github.com/obra/superpowers) (151K+ stars) under Category 3 (Frameworks and methodologies). Workflow-discipline framework complementary to this guide's knowledge-structure approach.
- Updated positioning diagram and narrative to reflect the orthogonal relationship.

### README
- Version bumped to 1.8.1.

### Origin

Issue #8: A news aggregator's ML logo classifier endpoint was tested during a dev session and memory recorded "shipped." The endpoint only existed in the running process — after restart it returned 404, silently failing for 230 articles (10%) until a human noticed. The memory system had no mechanism to distinguish a session observation from verified deployed state.

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
