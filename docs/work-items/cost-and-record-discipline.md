# Cost and record discipline

## What & Why

The framework's running cost is dominated by two things that are not the product: **review rounds spent proofreading the record** (memory, changelog, ledgers, registries, baselines) and **an auto-loaded surface that exceeds the budget the framework itself sets**. The 2026-09-12 session measured both and found one recurring, mechanizable defect class behind most of it.

Goal: make the framework cheaper to run without cutting the review of the shipped surface, which is measurably earning its keep. Framed by #126 (review cost unpriced), #127 (promotion path, shipped v1.41.0), #109/#143 (auto-loaded set), H-025 (most findings are on the record, not the change).

**Not in scope**: reducing lens count or round count on `templates/` and `.claude/skills/`. H-020 measured every axis there and found each buys something; the 2026-09-12 round found 5 blockers in a prose-only change.

## Session plan — TOKEN REDUCTION (maintainer directive, 2026-09-14)

✅ **Done.** `CLAUDE.md` and `memory/MEMORY.md` both cut; `CLAUDE.md` clears the soft flag in
`templates/audit-context.md` Step 1. The auto-loaded set is still over the cap and **no further
cut is scheduled** — the named candidates are spent, and what remains is current session state.

**The method that worked**: find a duplicate, name the authority, delete the copy. **The method
that has failed here**: tightening prose.

⭐ **Add to the method — every duplicate deleted this pass had rotted, and twice the copy being
deleted held the right answer.** Diff a duplicate against its authority and write back whichever
is right *before* deleting.

⚠️ **And a structural section is a slot with a prescribed size.** `## Key Paths` was deleted
outright on a correct duplication finding; `templates/curate.md` forbids trimming it and lint saw
nothing. Growing such a section past its prescribed size is the same defect as deleting it.

**Verification each time**, which caught defects on every pass — do not skip it:
- Account for every `<!-- verify: -->` probe **by name** before and after. A probe may move
  between memory files but must not vanish, and one that hardcodes its own host file must be
  repointed when the claim moves.
- Run `bash tests/lint/run.sh` after each move: rule 1 catches a `CLAUDE.md` path that stops
  resolving, rule 2 a topic file orphaned by removing what referenced it.

## Current Status

**SAVEPOINT — 2026-09-24, cloud session (no `memory/` here, so no `/curate`; run it locally).**

- **Open PR**: [ducroq/agent-ready-projects#202](https://github.com/ducroq/agent-ready-projects/pull/202), branch
  `claude/fervent-brahmagupta-t17yf0`. Fixes #200 #198 #199 #197 #196 #194 #186 #187 #155 #157 #138, candidate
  block `v1.45.2` (bump provisional; #199 adds `--ext`, so probably MINOR). No `Closes` lines yet.
- **Closed with evidence, already shipped**: #190 #188 #185 #176 #175 #166 #165 #164 #153 #135 #122.
- **Triage, still open**: PARTLY #178 #177 #150 #145 #126; NOT #180 #162 #155→fixed #154 #123 #113 #76.
  #136, #134 and #128 have follow-ups in their threads, so they were deliberately left open.
- **Later on the same PR (2026-09-25)**: #152 fixed (Closes); #134 hyphen names + stamp attribution and #177 points
  1–2 landed **without** Closes — #134 keeps its multi-line-stamp residual, #177 its point 3 (all-rung marker check);
  #161 fixed for step15-tables only.
- **Reviewer model**: Sonnet lenses by default (`.claude/review-profile.md`); review-bench is saturated.
- **For the gotcha log, locally**: an ablation whose `sed` crashed "passed" (empty mutant); a `grep` with no file
  read its loop's stdin; the 250k/release review budget was far exceeded this session (~1.5M before Sonnet).

**SAVEPOINT — end of session 2026-09-14. v1.45.1 released, pushed, globals refreshed, estate migrated.**

**What shipped**: `templates/review-changes.md` −5,760 bytes (−11%) of maintainer provenance, moved
behind a URL; `templates/review-profile.md` gains a cheaper-HIGH note as an **option** with its
counter-evidence. Lint rules 14–17 added (Step 1.5 over the tree, the auto-loaded ratchet, and the
first two Mechanized rows ever to reach `live`). Three declared-exemption mechanisms now validate or
expire; a fourth attempt was reverted. Auto-loaded set 49,172 → ~37,100 and ratcheted.

**Estate**: ten repos migrated off inert project-local `review-changes` copies — 10 tier tables, 78
guarantee entries and **5 project lenses** recovered into `.claude/review-profile.md` before any
deletion. Three also needed a `.gitignore` negation, without which the file the skill refuses to run
without could not be committed. `--check ~/repos` is clean. #193/#169/#184 closed; #195/#196 filed.

**Next action**: nothing is blocked. Take #195 or #196, or measure item 1 at the next release.

⚠️ **Method notes earned today, all by being caught:**
- **Lock a ratchet once, after the round** — twice I locked mid-change and then paid review-mandated
  fixes against a ceiling my own unfinished work had set. The tell is shaving single bytes.
- **A check written from the instance catches the instance**; only a seeded sibling catches the class.
- **A marker can be policed only where it asserts something the checker can re-derive** (H-029), and
  **where it is not policed it must not be honoured** (H-030).
- **An instrument that cannot distinguish is not evidence** — a 107-file corpus "proving" an awk
  program unchanged passes an ablated copy identically.

**Savepoint 2026-09-14, final — the pre-release sweep. Items 2-5 of "what's left" closed; 2 and 3
closed by DECLINING, with the reason.**

🔶 **5 — two exemption mechanisms tightened; the third attempt REVERTED.** A round refuted the
first build of all three:

- `lint-skip: maintainer-path` grants the skip only when **every** occurrence of the path on that
  line sits inside an `https://` run. ⚠️ The first build tested for `https://` anywhere on the line,
  and `grep -F` yields one hit per line — so one unrelated URL laundered a genuinely dead reference
  beside it (`Background at https://example.com/ — details in docs/rationale/x.md <marker>` scored
  rc 0). Seeded as `t6_urlbeside.md`, ablation A4.
- `lint-skip: opt-comment` (rule 17) reports a marker on a line with no defect, **and is honoured
  only where it is policed**. ⚠️ The first build honoured it everywhere while policing only shell,
  so a marker in a markdown fenced block was never checked **and still suppressed the real defect on
  its line** — in `templates/*.md`, the surface adopters copy. One predicate now governs both.
  Seeded as T10, ablation A4.
- 🔴 **`lint-skip: not-executable` (rule 11): added and REVERTED.** The marker means *do not run
  this*, not *this fails to parse* — a destructive illustration, a fill-in template and a block
  demonstrating rule 17's own defect all parse cleanly and all legitimately carry it, the third by
  construction. **A marker can be policed only where it asserts something the checker can
  re-derive.**
- ⚠️ **`tests/fixtures/block-parses/` has no ablations** (`grep -c ablat` → 0) while the catalog
  claimed two until today. Corrected in the catalog; the missing ablations are not written.

🔴 **4 — Step 8 was run against `audit-context`, `update-drift` and `release` and CANNOT DECIDE.
The per-step numbers a draft of this entry published are WITHDRAWN.** The instrument was
`grep -rnoE '<skill>.{0,25}Step [0-9]'` over `memory/` and `CHANGELOG.md`, and it fails three ways,
two found by review rather than by me: it counts prose *about* a step as readily as a catch *by*
one; its window crosses skill-name boundaries, so it credited `audit-context` with a **Step 0 that
does not exist** (`grep -c 'Step 0' templates/audit-context.md` → 0; the hits are a heading reading
*"`audit-context` Step 5 and `curate` Step 0.2"*); and every `Step 8` hit records Step 8 being
*authored*, today, never run. **No step of any of the three is established as dead or as live.**
Nothing retires on absent evidence — the same safe direction the `review-changes` audit took. The
fix is Step 8's own last clause, already shipped: record the finding *and the step that found it*.
⚠️ **This run also produced evidence against Step 8's headline** — *"the tell is available on day
one and costs one grep"* — and `templates/audit-context.md` has not been changed to say so.

✅ **3 — the three remaining skill bodies decline the provenance trim, measured.** The class that
yielded 5,760 bytes in `review-changes` (refuted drafts, "until v1.4x", "a first draft said")
appears **0 / 1 / 2 times** across `audit-context`, `update-drift` and `release` — with the command,
because a recount using a different one is indistinguishable from a surface change:
`grep -ciE 'first draft|earlier draft|a draft|refuted|superseded' templates/<name>.md`. There is no
equivalent fat; trimming further means cutting rules or the field evidence a rule rests on, which
the `review-changes` round demonstrated costs seven warnings their teeth.

✅ **2 — `curate`'s two structural options are DECLINED for now, and blocked on the same thing.**
Shipping the 10KB verify runner as a sibling file adds a second install artifact and a tool-agnostic
surface for a skill that must travel self-contained; and *"does all of Step 0 need to run every
session"* is exactly the question Step 8 cannot yet decide, for exactly the reason above. **Revisit
both once two or three audits have logged findings with attribution.**

**Savepoint 2026-09-14, later still — the big-file lever is REFUTED, measured.**

⭐ **File size is not a token cost in this repo, because nothing reads these files whole.**
Across 21 session transcripts and 123 subagent transcripts: `CHANGELOG.md` (543,155 bytes, ~135k
tokens if read) has **0 full-file Reads**, 1 bounded Read, and **205 bash accesses** — grep and sed,
which cost the size of their output. `memory/gotcha-log.md` 0 and 151; `memory/hypothesis-log.md`
0 and 92. Subagents read **extracted diffs from scratchpad**, never the source files: 0 full Reads
of any `templates/*.md`.

⚠️ **Instrument stated, because these are all negatives**: `grep -ho '"name":"Read","input":{"file_path":"…"}'`
over `~/.claude/projects/<slug>/**.jsonl`. A positive looks like
`"name":"Read","input":{"file_path":"…/scratchpad/full.diff"}` — 95 such calls exist in the
subagent transcripts, which is what makes the zeros mean absence rather than a broken pattern.

🔴 **EXCEPTION, measured 2026-09-14 and load-bearing: a SKILL BODY is not in that population.**
Invoking `/curate` injects the whole body as a user message — **74,178 characters, ~18.5k tokens,
in one record** (session `0d6c9762`, when `curate.md` was 75,534 bytes). The census above covered
files read through *tools*; the harness injects a skill body directly, so it never appears as a
`Read`. **Skill-body bytes are a direct per-invocation token cost for every adopter, and rule 8's
ratchet on `templates/` is measuring exactly the right thing.** Do not quote the finding below to
argue against trimming a skill body.

**So: archiving the changelog tail would save approximately nothing**, and I recommended it as the
single biggest lever, ~120k per release, without checking. The corroborated claim is the opposite
one, and the run budget in `.claude/review-profile.md` already rests on it: **the cost is the
reviewing agent's own exploration, not what it reads.** Two instruments now agree — the ledger's
flat per-run cost across scopes, and this transcript census.

**What this leaves for release spend**: run count, and nothing else that has been measured. The
budget is one lens-run per release, ≤120k.

⚠️ **And it re-opens Cluster B's question rather than answering it.** Retirement of old log entries
is still worth doing — a 107-entry gotcha log with 3 resolved markers is unreadable by a human and
`curate` Step 1.3 flags ~67 of them every run — but **the reason is not tokens**, and any proposal
that argues from file size is arguing from this refuted premise.

**Savepoint 2026-09-14, later — `templates/review-changes.md` audited, per the step-2 entry in the
previous savepoint's ordered list. VERDICT: nothing in it retires** — but **on three of seven
components having an attested catch, not on all seven**. The other four are unfired, unattributable
or days old, and undercounted evidence argues *against* retirement, which is the safe direction.
⚠️ A draft of this line read *"every component has a catch"* with this table directly beneath it
saying otherwise four times — the headline-disagrees-with-its-own-table class the profile cites,
committed in the pass that cites it.

| Component | What it has caught here | Verdict |
|---|---|---|
| Step 1 baseline block | #64: a whole pushed branch reviewed as empty — the class that created the step. ⚠️ Its two printed guards fire in CI on every run (`tests/fixtures/baseline-fallback/run.sh` asserts both, and the CHANGELOG re-measurement recording that
the same guard now prints — grep it by phrase, not by line number: the file grows from the top); what they have never done is fire on **organic content here**, because this repo always resolves `origin/HEAD` | keep; the population is other people's repos |
| Step 1.5 structural pre-check | **Measured today, not recalled**: 106 markdown files, 3 hits, **2 true positives** — a 17-cell row in `memory/MEMORY.md` (the hypothesis-log probe's pipes) and the two-glob bold shape in `.claude/review-profile.md`. Both fixed in this pass | keep — it has a subject |
| ↳ emphasis sub-check (#50) | **Its first true positive on organic content here, today.** It has had a seeded true positive in CI since #50 (`tests/fixtures/step15-tables/run.sh` t6, ablations A4/A5), so it was never a check with no subject — but on real files its only local appearances were its own false positives (#159) | keep; the skill's *"a BACKSTOP, not coverage"* now has an organic catch to point at |
| Step 2, all four lenses | Each has a *unique* catch in `memory/review-ledger.tsv`: guarantee — row 57's survival audit, the one no other lens ran; adversarial — rows 55/58/66, most findings per round; doc-accuracy — the H-022 direction error against the hypothesis' own decision rule (row 54, *"ONLY lens"*); shell-correctness — `set -u#` (row 56, *"no other lens reached it first"*) and the `set -eo pipefail` abort (row 45). ⚠️ A draft credited `set -u#` to adversarial and the install-source defect to doc-accuracy alone; the ledger says shell-correctness and *"2 of 3 lenses did"* | keep all four |
| Step 3.1 mechanization triage | 4 `proposed`, 1 `rejected`, **0 `live`** — its own bar (a seeded positive making the check go red) has never been met. Two days old (#127, v1.41.0, 2026-09-12) | too young to retire; **due date, not a verdict** |
| Step 4 `### Unclassified` slot | **No record of it ever naming a file**, since v1.15.0 (#26) — and the record *cannot* answer, because review reports live in transcripts and are never archived | unattributable; Step 8's last clause failing one level up |
| Step 5 round cap + budget | Shipped today (v1.44.0, 2026-09-14) — zero days; that is open item 1 | measure at next release |

🔴 **ONE of the four shipped lenses no longer runs here** — doc-accuracy. ⚠️ **This said TWO until
the adopter-facing cut was reviewed**: shell-correctness had been dropped from the HIGH cell by the
same omission, here and in the template, and a guarantee lens caught it — it is HIGH-gated exactly
like the guarantee lens, the skill says losing it "is the reason those paths are HIGH at all", and
ledger row 56 has it finding a round's blocker no other lens reached. Restored in both, conditional
on a shell file changing, so it costs nothing on a prose diff. The
guarantee lens is explicitly **not** part of the v1.45.0 cut: the HIGH row runs it whenever a diff
touches a guarantee surface, and it ran today (ledger row 60). Their catch record cannot grow in
the only repo that keeps one, so at the next audit their honest entry is *"no catch since
2026-09-14, because they were not run"* — indistinguishable from *"no subject"* unless written
down now. Written down here; that is the whole remedy available.
⚠️ **And MEDIUM is unreachable in this profile**, which is why doc-accuracy really never runs:
`docs/GUIDE.md` sits in both the HIGH and MEDIUM rows, and `templates/checklists/**` and
`templates/test-fixtures/**` are subsets of HIGH's `templates/**`. The profile states a
most-specific-wins rule; nothing states precedence between a row and a superset row it duplicates.
Pre-existing, load-bearing for the claim above, **not yet filed**.

🔴 **The sharpest finding of the audit, and it is not the one the first draft wrote down: Step 1.5
cannot see `memory/` at all here.** All four terms of its file list are git-sourced, `memory/` is
gitignored (`git check-ignore -v memory/MEMORY.md` → `.gitignore:17:/memory/`; `git ls-files
memory/ | wc -l` → 0; a non-empty result would have listed tracked memory files), so **14 of the
106 markdown files are invisible to it** — including the memory layer whose *"predominantly wide
tables"* is the step's own stated motivation. The 17-cell row found today could never have been
reached by running the skill as shipped. **Not yet filed.**

⭐ **What actually made this audit decidable — and it is a harder lesson than "run the check".**
The profile defect survived **four** diff-scoped chances: `.claude/review-profile.md` is in the
changed-file set of `eea6530`, `616efa7`, `b3af55d` and `1c443eb`, and the shape was present in
all four, while Step 1.5 claims to run *"at every tier and every magnitude"* on every changed
markdown file. So the finding is **Step 1.5 is not being run, or its output is not being acted
on** — not that the record failed to point at the file. The whole-tree run is what exposed that;
a shipped-skill addition on the strength of it would be the wrong lesson from the right
measurement. **Nothing proposed for `templates/audit-context.md` yet.**

⚠️ **Not retirable, and the reason is worth keeping**: 65 of the 125 lines of Step 1.5's awk are
comments, and 115 of 346 code-block lines across the file. That is the biggest single block of
reading cost in the skill — and the record shows three attempts to widen the fence rule, each
buying a worse class (#150). **Deleting those comments is the loosening they exist to prevent.**

**Savepoint 2026-09-14, end of session. v1.44.0 and v1.45.0 both released**, tagged, pushed,
globals refreshed after each.

**Verdict on the goal**: the stock came down, the flow did not. Auto-loaded set ~80k → ~46k chars;
`curate.md` 75,534 → 54,941. But this session also added ~4KB back across two deliberate budget
raises, both for good reasons — which is precisely the pattern that caused the bloat. `audit-context`
Step 8 is the first counterweight and **has never run**.

**Next, in order:**
1. **Does the v1.44.0 re-tiering plus round cap reduce spend, or move it?** ⚠️ Measure on total
   spend per release — the cap removes the ledger's recall instrument (H-020).
2. **Audit `templates/review-changes.md`** the way `curate` was audited: for each lens and each
   step, what has it ever caught? It is the largest remaining read surface (~49KB) and has never
   had the question asked of it.
3. **#192** ship H-015 · **#184** install-source class has no check · **#193** ten inert
   `review-changes` copies, diff before deleting · **#194** rule 8 and rule 13 contradict each
   other about `docs/rationale/` · **#191** AACR-Bench, parked.

⚠️ **Method, as it now stands** — all three earned this session:
- Find the duplicate, name the authority, delete the copy. **Diff against the authority first**:
  twice a deleted copy held the right answer.
- **Ask what a check has ever caught before asking how to fix it.** A record consisting only of a
  check's own false positives is the finding.
- **A retirement is an edit to every step that cited the retired thing.** Grep for the number as
  well as the name; renumbering is the half reading misses.

**Previous savepoint — 2026-09-12, second block.** v1.41.0 is tagged and pushed. A later `/update-drift` + `/audit-context` pass committed `76d6581` (**not pushed, no release**) and filed #170-#174.

**Last action**: swept v1.40.0 re-scoping residue; replaced lint rule 1's hardcoded never-exempt list with derivation from `.gitignore` negations (fixture T14 + ablation A13 seed the rot case a literal cannot pass).

**Next action — DECIDED 2026-09-12, run in this order.** Nothing below is blocked on a call any more; reasons are on the issues.

1. ✅ **DONE 2026-09-13 — `CLAUDE.md` reclamation pass** (`dac4ad2` + review fixes). 38,750 → ~35,400 chars after the review corrections were written back in. ⚠️ **It does NOT clear the soft flag, and the first draft of this line claimed it did.** `templates/audit-context.md` Step 1 owns the 35,000 threshold and budgets in **bytes**, so `/audit-context` still flags this file; `CLAUDE.md`'s own header prescribes `wc -m`. **Two instruments for one number — file it, do not settle it in passing.** No digit for headroom here: it moved 4,145 → 4,123 → 3,456 inside one day as both files were edited. Re-derive: `{ wc -m CLAUDE.md; wc -m "$HOME/.claude/projects/<slug>/memory/MEMORY.md"; }` against the 40,000 hard cap. **Steps 2–4 are unblocked.** Method: deleted a duplicate, did not compress prose. The `tests/` block restated each fixture's rationale, which already lives in the fixture's `README.md` or runner header. ⚠️ **The duplicate had rotted, which is the reusable finding**: the copy of `reference-integrity`'s T/N commands kept in `CLAUDE.md` used `\bT[0-9]+\b` and returned **38/35** against the fixture README's `\bT[0-9]+[a-z]?\b` and a true **40/37**. Two surfaces, two commands, and the wrong one was the always-loaded one. Three fixtures held their count commands *only* in `CLAUDE.md` (`dead-reference`, `step15-tables`, `size-ratchet`) — **moved into the runner headers, commands only, no digits**.
2. ✅ **DONE 2026-09-13 — #172** (`6568306`). Row names the profile; budget +379 as ONE record, amended in place across three review rounds. Four-lens battery: **4 blockers, 6 majors, 1 false positive**, 474,367 tokens, recorded in `memory/review-ledger.tsv`. ⚠️ **Most findings were defects the change itself introduced, including one from a previous round's fix** — the H-021 shape again. Three carry forward:
   - ⭐ **`set -u# <orphan>` in two fixture runners**, from `dac4ad2`'s header edit — `nounset` never applied, and **`bash -n` passes on it**, so #160's proposed sweep does not cover this class. Both complementary; attach the measurement to #160. Proposed check in the Mechanized table.
   - **A lens flagged the `.claude/` path as a tool-agnostic violation and was WRONG** — `templates/README.md` gives that path for all six tool columns and `templates/review-changes.md` hardcodes it in four places, so the hedge would have caused the exact STOP the row prevents. Refuted by a second lens. **Do not re-open it**; the raise note carries the reasoning.
   - **A ratio was copied from one lens's report into `CLAUDE.md` without re-deriving** and a later lens refuted it. Same shape as the 2026-09-07 correction already in `memory/MEMORY.md`.
3. 🔄 **#173 — DONE, uncommitted, four review rounds.** Started as "add a row to `docs/GUIDE.md`"; ended at **nine files**, because every round found the same class one surface further out. ⭐ **THE FINDING, and it is a number: the install-source defect was in SIX skill templates and it took three rounds to stop finding more.** `docs/GUIDE.md` told adopters to install skills from `templates/<name>.md`, whose frontmatter sits inside a `SAVE AS` comment — a literal copy **never registers, silently**, which `tests/lint/run.sh`'s own comment records an adopter hitting for months. Round 1 found the instance being written; round 2 found the third *in the same list the first two were fixed in*; round 3 found the fourth, which by then **contradicted a line round 2 had just written**. **Each round fixed what it was shown and none asked how many there were.** The ending command is one line — `for f in templates/*.md; do sed -n '3p' "$f"; done | grep 'SAVE AS'`, then count the do-not-copy clauses: it was **four of six**, now six of six. ⚠️ **No lint rule can see this class**: rule 3 checks only that `name:`/`description:` exist, and rule 6 excludes the `SAVE AS` block from its comparison by construction — so both copies agree while contradicting five other surfaces. **That is the mechanizable finding of this batch, filed as #184** — which stays OPEN after v1.42.0 ships, because the batch fixed the six instances and did not write the check.
   - **Scope grew past the issue, deliberately and on the repo's own rules**: `README.md` and `adopt.md` omitted `update-drift` too (CLAUDE.md: *keep them in sync*), and the `review-changes` install paragraph carried the identical defect (*fixing a defect does not immunise you one file over*). Whether that ships as one release or splits is the maintainer's call.
   - **Budget: net −31** (241,524 → 241,493) across four payments and one raise. The raise was **49 bytes of 285**, the rest paid by deleting paragraphs that restated the `description:` field beneath them — two of which were also **stale**. ⭐ **H-022 gets its first genuinely mixed datum**: hatch declined twice, taken once, in one change.
   - ⚠️ **Round 2 published a verification command that returns 0** — escaped backticks inside a code span, so grep read `` \` `` as a start-of-buffer anchor — in the paragraph arguing from that command. And a release count was copied from `update-drift`'s subject onto `review-changes`'s (28 for 37) in the entry whose subject is numbers that stop matching what they count.
4. ✅ **#174 — DONE 2026-09-14, and the remedy is the REVERSE of the one filed.** A scratch repo with three Mechanized rows, run through `refcheck.py`: `⊘ \`path\`` → **UNRESOLVED, a finding**; `` `path` <!-- placeholder --> `` → correctly bucketed as `declared-placeholder`; no marker → UNRESOLVED. **Rows a and c are indistinguishable, so the `⊘` is decorative exactly as filed.** But the cheaper fix is the reverse of the issue's: `<!-- placeholder -->` is already implemented, already in `SPEC.md`, already used in this log, and **works inside a table cell** — so change what `templates/review-changes.md` prescribes rather than teaching the checker a second glyph, which is what #177 warns is "a third form to get wrong". That lands in the adopter-installed file, satisfying #174's own #92-trap condition. **Shipped**: both `review-changes` copies prescribe `<!-- placeholder -->`; both `audit-context` copies name a marker syntax for the first time (Step 4 said *mark them* and never said how, so an adopter running it as prose had no rule); all four `proposed` rows in the log converted, re-audited to **zero** standing false findings; `T46` seeded as a **negative control** — a glyph-marked path must still be reported — and ablated to prove it can fail. ⭐ **The design question was put and answered by measurement.** The obvious simplification — the Mechanized table's `Status` column already says `proposed`, so skip that row's unresolved paths and delete the marker entirely — is a **loosening**, and one row refutes it: `proposed` rows here carry 1, 3, 1 and **7** paths, and six of that last row's seven are real files. A row-wide skip silences all six. **Span-scoping is the feature, and the placement rule is its price.** ⚠️ **The prior art agrees with the shape and not the token**: `# noqa`, `// eslint-disable`, `# type: ignore` and `# shellcheck disable` all do inline suppression *with* unused-suppression detection (which `STALE PLACEHOLDER MARKER` and `COVERS NO PATH` independently reinvent) — but every one is a **line comment in the host language**, so none can terminate the construct it sits inside. Ours can, and did. **If this is ever revisited, that is the axis: the token, not the mechanism.** Budget across the two rounds: six raises, four payments, net +1,707.

5. **Then cut v1.42.0**, which carries #171's stamp correction automatically. **No v1.41.1** — decided; see #171.

⚠️ **A second batch arrived after this plan was written — #175–#180, folded in 2026-09-13, section below.** #175 is small and independent of steps 1–5. #176/#177 attach to #165/#154. **Cluster B (#178/#179/#180) is UNBLOCKED** — destination decided 2026-09-13, see Decisions. It edits the same two templates as step 1, so it sequences there: **6. marking pass over our own log (#180 headings + `[RESOLVED` markers, one read) → 7. split and measure it here → 8. only then ship the pattern to `templates/`.** Steps 6–8 are a MINOR of their own; whether they ride in v1.42.0 or follow it is still open.

⚠️ **#171's durable half is the check, not the release**: a lint rule asserting the stamp equals the highest reachable release tag (or is exactly one ahead, mid-release). Needs a seeded fixture — the live tree is clean for this class. Fix `memory/MEMORY.md`'s `STAMP AGREES` probe in the same change: it reads the working tree and was **green on the run that found the divergence** (H-023, fourth instance).

- [x] #127 shipped — `review-changes` Step 3.1, Mechanized table, `curate` reads it, `curate`'s Promoted extractor bounded
- [x] Landscape doc re-verified and rewritten (2nd edition)
- [x] ETH paper (arXiv:2602.11988) re-verified against **primary text of both versions**; v1 figures superseded by v2 across 7 files
- [x] Review round recorded in `memory/review-ledger.tsv` (3 rows, 2026-09-12)
- [x] **v1.41.0 committed, merged, tagged, pushed; globals refreshed and verified carrying the fixes**
- [x] Version badges unstuck: `README.md` and `docs/GUIDE.md` were at **1.28.0**, thirteen releases stale; template stamps and `CLAUDE.md` bumped to v1.41.0
- [x] `docs/GUIDE.md:506` self-contradiction fixed — it said install `review-changes` user-globally *and* "Never install it user-globally" in adjacent sentences. v1.40.0 residue: the "never" rationale (risk tiers name one tree) stopped being true when the tiers moved to the profile
- [x] #127 closed naming the adopter-installed files; #126 given the measured round; H-027 and H-028 registered
- [ ] **Estate cleanup (#169)** — ⚠️ **re-measured 2026-09-14 after the v1.42.0 refresh: THREE inert copies, not 13** (names deliberately not written here — lint rule 12 FAILED on a draft of this line that did, which is the rule working), and the bare `--check` tail reports 12 issues total, which is NOT the same number. Check each for local modifications before deleting; keep every `.claude/review-profile.md`.
- [ ] ~~Estate cleanup (original note)~~ — inert project-local `review-changes` copies, shadowed since v1.40.0. The count is a COMMAND, not a digit — it moved 13→12 mid-session on 2026-09-12 while remediation ran in a sibling repo: `bash scripts/install-global-skills.sh --check ~/repos | grep -c 'inert local copy'` — the bare `--check` tail counts ALL issues, not just these. ⚠️ Check each for local modifications *before* deleting; keep every `.claude/review-profile.md`
- [x] ✅ **v1.42.0 RELEASED 2026-09-14** — `ab999f2`, tagged `v1.42.0` (annotated), pushed, verified live with an exact-ref check. Globals refreshed **after** verification: `audit-context` and `review-changes` reinstalled, `curate` and `update-drift` already current (the installer derives the install, so `update-drift`'s SAVE AS edit changed no installed byte). Preconditions: 13/13 lint, 15 of 16 fixture suites with 1 declared not-a-gate, 0 failed. **#171 fixed by construction** — stamps bumped in the tagged commit, verified via `git show <tag>:<path>` rather than the tree. ⚠️ The release was larger than the changelog described: the 2026-09-12 residue sweep had landed after the v1.41.0 tag with no entry, and was folded in at Step 4 rather than shipped undocumented.
- [ ] **Step 1 — stale-number check.** See Decisions for the design turn; read it before building
- [x] **Step 2 — bring `CLAUDE.md` under its own cap.** DONE 2026-09-13, `dac4ad2`. 34,753 chars. ⚠️ **Do not re-inline reference material to make it handy** — that is how the file got to 38,750, and the inlined copy was wrong.
- [x] ✅ **Step 3 (first half) — DONE 2026-09-14: the auto-loaded set cut 32%, 116,501 → 79,138 chars.**
  Everything from 2026-09-06 and earlier moved to `memory/project_history_to_2026_09_06.md` (39,684 chars):
  the index was carrying a second narrative beside the `project_session_*.md` files that already held the
  first. Precedent: the identical move on 2026-08-27. **All 17 verify probes accounted for by name before
  and after** — `curate` Step 0 sub-step 5 scans memory *files*, plural, so none left scope. Lint rule 2
  caught two topic files orphaned by the move; both now routed from the Topic Files table.
  `CLAUDE.md` 37,987 → 36,162 by collapsing five Key Paths rows that restated `tests/lint/README.md`,
  a duplication the file itself had flagged and not acted on.
  ⚠️ **STILL ~2× THE 40,000 CAP.** `CLAUDE.md` is now the larger half at 36,162 and the cap is on the
  SET. Getting under it means roughly halving the project file, which is an orientation decision, not a
  deletion one — do not do it by shaving prose.
- [x] ✅ **Review scope narrowed 2026-09-14 (`.claude/review-profile.md`).** `docs/**` and
  `docs/rationale/**` dropped MEDIUM → LOW, so the doc-accuracy lens no longer runs over prose about our
  own history. **Measured basis**: across two batteries that day, of ~18 findings **8 were shipped
  behaviour and 9 were about the record**, and every blocker in both was in `templates/` or
  `.claude/skills/`. The trade is stated in the profile: a wrong number in `docs/rationale/` now survives
  longer, which is acceptable where nothing executes it.
  ⚠️ **Unmeasured until the next release**: whether this actually reduces spend, or only moves it.
- [ ] **Step 3 (second half) — add headings to the 5 opaque memory files**
- [ ] **Step 4 — rating-floor check (#168).** A claim whose verification log records PARTIAL/NEEDS WORK may not be rated ESTABLISHED. Seed with the Gloaguen block as it stood before 2026-09-12 — a known true positive the current arrangement passed
- [ ] **Step 5 — one narrow round, recorded.** The missing half of #126's comparison. Costs nothing extra: record what happens
- [ ] **Decide: how big should the record be?** User's call, see Open Questions

### Second batch — #175–#180, filed after this savepoint (folded in 2026-09-13)

⚠️ **Tracker is 50 open, not the 40 recorded in `memory/MEMORY.md`** — `gh issue list --state open --limit 200 --json number --jq 'length'`. Six new issues, one adopter (a downstream adopter at v1.41.0), all measured.

**Cluster A — `refcheck.py` / `audit-context` Step 4.** Independent of the ordered plan above; ships with #174 or alone.

| # | Claim | Disposition |
|---|---|---|
| #175 | `EXT` omits `mjs`/`mts`/`cjs`/`cts`, so a broken reference to `vitest.config.mts` reports CLEAN. Ships a `.ts` control on the identical sentence | **Take.** Cheapest item open. One seeded case per extension — a `.mts` case does not prove `.cts` |
| #176 | a bare `` `.d.ts` `` is reported UNRESOLVED | **Merge into #165** — same class, and #165 holds the stronger evidence (33 repos / 5,357 files, refuting the obvious leading-dot fix). Not a duplicate: #176 supplies the predicate that survives that scan. `.env.example` and `.pa11yci.json` have 7-character name segments, so a `{1,4}` bound on the name segment excludes both counter-examples and still catches `.d.ts` |
| #177 | no marker form for a **quoted** path | **Take point 3 only.** A `<!-- quoted -->` marker is a third form to get wrong, and the quoted/referenced split may not be mechanically decidable. The teeth are elsewhere: four markers landing on #154's symptom pin its findings-delta at zero — *a marker on a known bug's symptom removes that bug's detector, and each marker is locally correct* — and placeholder-skips are checked at rung 1 only, so the adopter's one genuinely wrong marker (on a live tracked file) was structurally invisible to the checker and was caught by a review lens instead |

**Cluster B — the record itself (#178 retirement, #179 verbosity, #180 heading convention).** One batch: all three edit `templates/curate.md` and `templates/gotcha-log.md`.

⭐ **Corroborated from a second source.** The maintainer reached two of the same conclusions in an unrelated session (reported 2026-09-13): internal docs — `CLAUDE.md`, memory, gotcha log — are too verbose, and the retirement process "is not working properly all the time", with the destination question raised unprompted ("to what do we retire? a home for very old thoughts"). The adopter measured it downstream; the maintainer hit it here. Two independent arrivals, not one report.

**Measured here 2026-09-13 — retirement is working *less* well in this repo than in the adopter that filed #178.**

| | this repo | adopter (#178) |
|---|---|---|
| entries | 97 | **88** |
| heading carries `[RESOLVED` | **0** | 52 (**59.1%**) |
| size | 126,144 chars | 178,616 |
| dated before the current month | 72 | 55 |

⚠️ **The denominator is 88, not the 89 #178 reports** — corrected at source 2026-09-13 by the reporter, who reconciled two ways (`grep -cE '^### '` = 88 and `grep -c '^\*\*Problem\*\*'` = 88; 90 headings less 2 section headings). So 59.1%, not 58%. **There is no split script**: the split was done inline and never committed, and the reporter declined to reconstruct one — *a reconstruction would be a different instrument wearing the name of the one that produced the number*. What exists is the predicate, re-derived and exact against the archive: over `^### ` headings, take the `(YYYY-MM-DD)`, move if the date precedes the cutoff **and** the heading matches neither `\[OPEN` nor `\[PARKED` → moves 52, keeps 36.

Commands: `grep -c '^### ' memory/gotcha-log.md`, `grep -cE '^### .*\[RESOLVED'`, `wc -m`. **A positive would be a heading of the form `### … (2026-08-12) [RESOLVED]`**, which is what `templates/gotcha-log.md:11` prescribes. The convention actually in use here is `[PROMOTED]` (2 headings) and `[xN — date]` (12); status is written into `**Fix**` bodies instead — the exact placement the template calls invisible to curation. `memory/gotcha-log.md:233` carries "✅ RESOLVED 2026-08-25" in a body.

**Consequence, from the skill's own rule.** `curate` Step 1.3 flags *any unresolved entry older than 14 days*, excusing only what the Promoted table records. Promoted holds 5 data rows, **and not one of them is a `###` entry in this log** — they are promoted *patterns*, while `templates/gotcha-log.md:14` scopes the excuse to *the entry* being recorded there (`for s in <the five>; do grep -c "^### .*$s" memory/gotcha-log.md; done` → all zero). So the figure is **72, not the ~67 first written here**: nothing is excused. The error made the case weaker than the truth — and Step 1.3 already documents that failure mode against a *different* log ("in one measured log 11 entries are recorded resolved in the table and carry no marker in their header, so a header-only pass reports every one of them as lingering on every run, forever") while this repo runs it at six times that scale. We shipped the diagnosis and did not apply it to ourselves.

**"To what do we retire?" — the framework never says, and its shipped prose gives three answers.**

`grep -rniE 'archiv|retire' templates/ docs/GUIDE.md README.md` returns ~40 hits and **not one names a destination path for retired material**. A positive would read like *"move it to `memory/archive/<name>.md`"*; the only target-naming hits are this repo's own `docs/archive/*` links in README's reading list, which are artifacts, not a prescription. What the surfaces do say disagrees:

- `README.md:90` — Retire = "fixed issues get **removed**"
- `docs/GUIDE.md:378` — "Retirement moves them **out**", then at :379 "mark resolved in the log (**don't delete** — it's history)"
- `templates/gotcha-log.md:11,20` — mark `[RESOLVED]` **in the heading**, "don't delete", append-only

So one word covers deletion (topic files, memory index) and mark-in-place (gotcha log), and "moves them out" names nowhere to move them to.

**The destination has been invented three times and shipped zero times.** `docs/archive/` here (2026-04-14 pivot docs; `physics-tests/` added 2026-09-04 with its measurement in `templates/README.md:59`), `memory/project_hypotheses_closed.md` here (2026-09-06; `wc -l` → 310 archived against 833 live, re-derived 2026-09-13 — the 302/837 first written here was already stale), `docs/gotcha-log-archive.md` downstream (#178). Three independent arrivals at the same missing pattern is this repo's own promotion threshold, and none of them reached `templates/`.

**Where Cluster B lands.** It is a `templates/` change — MINOR, HIGH tier, full battery — on the *same surface* as step 1's reclamation pass, and #179 §3 is the direct precedent for how to land it (guidance about concision is itself reference material and belongs behind a pointer, not inline). Sequencing is an open question below; nothing is decided.

### Measurements already taken — do NOT re-derive

| What | Value | How |
|---|---|---|
| Review round, 3 lenses | **359,568 tok / 45 findings / 5 blockers** | `memory/review-ledger.tsv`, rows dated 2026-09-12 |
| Per-round range, real work | **121k–485k tok**; max 485,021 (4 lenses) | ledger, re-derived 2026-09-12 |
| ⚠️ The quoted **557,442** | **NOT ours** — an adopter's round, from a comment on #126 | `grep -c 557442 memory/review-ledger.tsv` → 0 |
| `CLAUDE.md` | run the command | `wc -m CLAUDE.md` |
| `memory/MEMORY.md` | 68,351 chars, **5 headings**; Current State = 245 lines / 58,680 chars = **86% of the file** | `grep -c '^#\{1,4\} '` |
| memory corpus | ~477 KB / 160 headings | `wc -m memory/*.md` |
| templates surface | 241,145 b budget after the 11th raise | `bash tests/lint/size-ratchet.sh .` |

**Files with no usable heading structure** (heading-first reading cannot work on these):

```
project_session_2026_08_27.md     47,549 chars /  1 heading
project_session_2026_08_early.md  28,460 chars /  1 heading
project_dead_end_pattern_rollout   5,127 chars /  0 headings
project_session_bloat_profile      2,675 chars /  0 headings
project_framework_pivot            1,789 chars /  0 headings
```

### The stale-number class — the enumeration, sent with the count (#65)

Every one of these was a number that no longer matched the thing it counted, and they span six different artifact types — which is why this is the target:

1. `tests/fixtures/reference-integrity/README.md` — claimed 27 T / 28 N, actual **40 / 37**; fixed 2026-09-12
2. `tests/fixtures/dead-reference/` — "40 rows, 16 ablations" vs 35 / 15 (CLAUDE.md: *"#93, fourth instance"*)
3. `tests/fixtures/step15-tables/` — wrong before #144 added cases (*"third fixture to hit it"*)
4. `tests/lint/size-baseline.tsv` — this session shipped "TENTH raise" against `grep -c '^# RAISED'` = **11**
5. `memory/review-ledger.tsv` — #162, shipped statistic stale for a release and a half
6. `CLAUDE.md` self-certification count — lagged 3× before its probe existed, then again within a minute
7. `docs/` ETH figures — 3%/4%/19% correct for v1, superseded by v2, propagated to **7 files**
8. `docs/the-context-engineering-landscape.md` — every star count stale 2–3×, 4 dead links, 3 invented author names

## Priority order — by SILENCE, not by surface (2026-09-14)

**Surface tells you how to batch; this tells you what to do first.** The axis is this repo's own top value: a check that passes when it should not is worse than one that is noisy, because everything downstream of it is unreliable and nothing says so.

⚠️ **This is a JUDGMENT pass, not a measurement, and an automated one was tried and thrown away.** Keyword-matching issue bodies for *silently / blind to / indistinguishable / never fires* put **31 of 50** in tier 1 — because that is the vocabulary every issue here is written in. The instrument matched the prose style, not the defect class. Same failure as the "14 table rows" that were case-definition delimiters, same day. **Re-tier by reading, or not at all.**

**TIER 1 — a shipped check returns a wrong answer and nothing signals it.** Fix these first regardless of which cluster they sit in.

| # | what stays broken | cluster |
|---|---|---|
| #175 | a broken reference to `.mts`/`.mjs`/`.cjs`/`.cts` reports **CLEAN** | refcheck |
| #154 | a gitignored build tree resolves a path that should not, so a dead ref reads as live | refcheck |
| #122 | four reference shapes sit outside Step 4's population — never checked, never reported as unchecked | refcheck |
| #134 | `update-drift` is blind to the idiomatic `commit <hash>` pin, so a behind project reads as current | update-drift |
| #135 | Step 3 checks for marker strings, not that the block parses — an adopter's broken copy passes | update-drift |
| #136 | a probe that hardcodes its version expires exactly when it has something to report | update-drift |
| #145 | `review-changes` Step 1 cannot observe untracked files; a new file reviews as nothing | review-changes |
| #153 | no check that HEAD is ahead of `$BASE`, so a moved checkout yields "nothing to review" | review-changes |
| #166 | the v1.40.0 profile split silently drops an adopter's own lenses | review-changes |
| #164 | the BOM strip does not fire under one-true-awk, and the comment reads as if it does | review-changes |
| #138 | an ablation that fails to apply is silent; its green is indistinguishable from a real one | fixtures |
| #161 | `ablate()` scores PASS when its kill-set is already failing — a broken guard certifies itself | fixtures |
| #157 | `--update` erases the moved-bytes warning `--raise-budget` is guarded against erasing | fixtures |
| #114 | `curate` compresses the project file with nothing asserting the load-bearing facts survived | curate |
| #184 | **the check for the class that just shipped six instances is not written** | estate |

**TIER 2 — following the shipped docs produces a broken result.** #169 (13 inert skill copies across the estate — a script run, not a code change), #171 (the v1.41.0 tag ships templates stamped v1.40.0; **rides v1.42.0 automatically**).

**TIER 3 — noise, precision and record-keeping.** The remaining ~33. Each is individually legitimate; together they are why the tracker does not reach zero by working it in **arrival** order. ⛔ **These clear by DECISION, not by queue position** — defer with a stated reason, or close; either one clears the issue. What they must not get is an open-ended queue slot. The Mechanized table has a `rejected` status and the rationale for keeping rejects (*"a shape rejected twice is a shape to look at again"*); **the tracker has no equivalent, and that is the gap that makes this feel like chasing.**

**Arrival rate, measured 2026-09-14** — 75 filed against 30 closed over the two full weeks to 09-13; 153 filed total since 07-27. It arrives in bursts (one adopter running `/update-drift` across a release gap files ~20 in an afternoon). ⭐ **CORRECTED 2026-09-14 by the maintainer: clearing the tracker IS the goal — the arrival rate sets the ORDER, not the goal.** This line previously read *"clear them all is not a goal that can be met"*, which turned a measurement of rate into a judgement about the goal, and contradicted the Backlog triage section four lines below that says *clear the tracker over several sessions*. What the rate actually argues is narrower: **working in arrival order does not clear it**, because one adopter afternoon files ~20. Tier 1 + tier 2 is ~17 and is reachable now; tier 3 clears by **decision** — deferred with a stated reason, or closed — which counts as cleared.

⚠️ **Who is generating this: not us.** Of the 50 open, **1** is pure self-audit; 26 name an adopter source and 19 name both. The backlog is real downstream work, not the review apparatus eating itself. (Keyword instrument, so crude — "adopter" appears both where one reported it and where one is merely affected.)

## Backlog triage — 50 open, batched by surface (2026-09-14)

**Goal: clear the tracker over several sessions.** Batching is by *surface*, because one review round covers a whole batch — that is the only real lever on cost here. Work largest-first; the big clusters have the most internal merging.

⚠️ **Read the cluster's issues before starting one.** #181 was re-derived from this file's Open Questions and analysed twice, because the session read the work item and never checked the tracker. That is the first move of every batch session, not an optional one.

| cluster | issues | n | notes |
|---|---|---|---|
| **refcheck / audit-context Step 4** | 76, 117, 122, 141, 154, 155, 165, 175, 176, 177 | 10 | Start here. #176 merges into #165; #177 partly into #154. #175 is the cheapest item open. ⚠️ **CORRECTED 2026-09-14 (#185): `refcheck.py` is NOT an oracle any more** — since v1.40.0 Step 4 tells the adopter to run it, so a fix there does reach them and closes the issue on its own. This row said the opposite, which is the disposition rule all ten were triaged under. A skill edit is still needed when the STEP's own words change (the report sections, the verdict) |
| **review-changes / Step 1.5** | 126, 145, 150, 153, 158, 159, 163, 164, 166 | 9 | #158/#159 are both emphasis-guard precision. #150 part 2 is REVERTED by decision — do not re-open on the repro alone (H-026) |
| **curate + the record's shape** | 114, 152, 178, 179, 180, 182, 183 | 7 | #178/#179/#180 are Cluster B below and share a destination decision. #180 is settled to ONE surviving claim — read the issue before re-litigating |
| **update-drift** | 134, 135, 136, 137, 147, 148, 156 | 7 | Self-contained; the skill is user-global so adopter action is one reinstall |
| **fixtures / lint / ablations** | 113, 138, 157, 160, 161 | 5 | #138 and #161 are the same shape: an ablation whose green result is indistinguishable from a real one. Fix together |
| **the record itself (meta)** | 111, 123, 146, 162, 167, 168 | 6 | Mostly maintainer-local. #168 is work-item Step 4 |
| **estate / infra** | 128, 132, 143, 169, 171, 184 | 6 | #171 rides v1.42.0 automatically. #169 is a cleanup script run, not a code change. **#184 is the batch that just shipped and stays open: six instances fixed, the CHECK not written** |

**Not on this list and still open: 25 hypotheses, one past its review date.** `/curate` Step 0 sub-step 7 reviews those; they are not tracker items and should not become any.

⛔ **The release does not depend on any of this.** v1.42.0 ships #172/#173/#174/#181 and carries #171's stamp fix. Holding it until the tracker empties leaves adopters being told to install skills in a way that silently does not work.

## Decisions

- 🔴 **[2026-09-13] OUR OWN POPULATION UNDER v2 STRICT: 6 of 12 symptom — so "the convention problem is total" does NOT generalise.** Population: the 12 `###` headings carrying `[xN` in `memory/gotcha-log.md` (`grep -nE '^### .*\[x[0-9]'`). ⚠️ **Not a blind classification** — I had already read their four verdicts. Declared, not hidden.

  | verdict | heading (abbrev) | deciding rule |
  |---|---|---|
  | MECHANISM | A seeded negative that cannot fail proves nothing | 2 — property → consequence |
  | MECHANISM | An apostrophe inside a single-quoted `awk` program | 1 — ⚠️ CLOSE |
  | MECHANISM | The obvious fix for a substituted token contains the token | 2 — ⚠️ CLOSE |
  | MECHANISM | Prose about a checker is input to that checker | 2 — clearest in the set |
  | MECHANISM | A negative measured with a mismatched instrument reads as a real absence | 2 — the *X is indistinguishable from Y* form exactly |
  | MECHANISM | A `set -e` abort silently skips every later assertion | 1 — clearest rule-1 pass; `set -e` is greppable and is what malfunctioned |
  | SYMPTOM | Private repo names re-entered the public repo after the sweep | 3 — event narration |
  | SYMPTOM | A new negative was satisfied by an existing positive's output | 3 — event |
  | SYMPTOM | A string index matched the heading's own prose mention | 3 — ⚠️ and this IS the self-reference class, whose own heading does not name it as a property |
  | SYMPTOM | A correction ships and the superseded sentence stays | 3 — ⚠️ CLOSE, general present reads as a rule; tie-breaker took it |
  | SYMPTOM | A working-tree `grep` was used to claim what an adopter can get | 3 — ⚠️ CLOSE, past-tense event; tie-breaker took it |
  | SYMPTOM | Ablation rows went stale inside the change that grew the fixture | 3 — event |

  **50% here against 100% there.** The claim *"the convention problem is total"* holds in their population and **fails in ours** — do not ship #180's convention on the totality claim. ⚠️ **4 of 12 are CLOSE CALLS decided by the tie-breaker or one word of rule 1** — a third of the population, which is the same free-parameter sensitivity they found, reproduced independently at a larger n. **That is the finding worth publishing: the classifier is unstable at roughly a third of any population, in both repos.**

  🔴 **THE INSTRUMENT-VS-APPLICATION HYPOTHESIS IS REFUTED — measured 2026-09-13, same day it was registered, by the reporter's proposed command.** It predicted this log would be identifier-**rich**. Measured: `grep -E '^### ' memory/gotcha-log.md | grep -c '\`'` → **8 of 97 = 8%**, against the adopter's **27 of 96 = 28%**. Ours is **three and a half times poorer** in named constructs — the opposite of the prediction, at the magnitude that decides it. Registered and killed inside one session; the entry is kept because *it was cheap to refute and was asserted before anyone spent the one command*.

  ⭐ **What replaces it is the reporter's, and it is better: TENSE, not domain.** Rule 1 fired only **2 of 12** here (17%), *below* their 28% ceiling — four of our six mechanisms came through **rule 2**, the *X causes Y* / *X is indistinguishable from Y* form. So this log does not score by naming things; it scores by writing **timeless propositions**. ⚠️ **BOTH SIDES OF THIS COMPARISON WERE FIRST STATED WRONG, AND THE INSTRUMENT MISMATCH WAS MINE.**

  - **My 75% was a verb-list proxy** (`grep -cE '\b(was|were|went|shipped|…)\b'` → 24 of 97 carry a past-tense verb). The reporter's 39% is **hand classification**. Comparing the two was the mismatched-instrument error this repo has a Hard Constraint about, and I made it while quoting their number.
  - **Their "throughout" was an assertion, not a measurement** — self-corrected when measured: **37 proposition / 58 incident / 1 unclassifiable = 39%**.

  **Hand-classified all 97 of ours under their definition** (proposition = timeless claim; incident = narrated occasion): **53 proposition / 44 incident = 55%**, with **~23 borderline (24%)**.

  | | proposition | instrument |
  |---|---|---|
  | here | **55%** | hand, all 97 |
  | adopter | **39%** | hand, all 96 |
  | ~~here~~ | ~~75%~~ | ~~verb-list proxy — withdrawn~~ |

  **The direction survives and the magnitude does not: 16 points, not the 36 the proxy implied.** My proxy overstated our proposition rate by 20 points and I fed it into the shared record before anyone hand-counted. The tense mechanism is still the live explanation; it is a weaker effect than either of us published.

  🔴 **THE TEMPORAL EVIDENCE IS DEAD — the two logs trend in OPPOSITE directions, and the adopter's trend has a confound its own author found.**

  Their split looked like independent support: archive (pre-2026-09) **46%** proposition, live log **30%** — a log becoming more incident-shaped as sessions got busier, which is what a mechanism costing *a second act of thought at write time* predicts. ⚠️ **But their archive was SELECTED, not sampled**: the split moved entries that were pre-September **and resolved**. If a retire pass rewrites headings into propositions on the way to closing them — which is what a retire pass *does*, and what they did to two headings in the #180 commit — then 46 vs 30 measures **curation, not writing conditions**, and the reading inverts: curation *raises* proposition rate by ~16 points. That is evidence for the *when* answer by a different route and **no evidence at all for load at write time**. Their finding, on their own trend, and they left the settling command unrun with a December date on it rather than run it in the session that wanted the answer.

  ⭐ **Ours is the unconfounded instrument and it points the other way.** This log has **never been split**, so an entry-date trend here carries no archive boundary. Splitting the hand classification **made before this question was posed**, so it cannot be motivated:

  | | pre-2026-09 | 2026-09 on |
  |---|---|---|
  | here (one unsplit file, n=72 / 25) | 51% | **64%** |
  | adopter (archive vs live, n=52 / 44) | 46% | **30%** |

  **+13 here against −16 there.** The write-time-load mechanism has support from neither log once the confound is named.

  ⚠️ **Our own confound, stated rather than waited for:** this repo's September work *is* measurement discipline, so recent entries are about instruments and rules — subject-matter drift, not writing conditions, would produce the same rise. n=25 for the later bucket. **Neither trend is clean; they merely fail in different directions.**

  **What survives:** the cross-sectional difference (55% here vs 39% there, both hand-counted) and the claim that the convention should ask for a proposition. **What does not:** any temporal claim about load, and any use of 46→30 as evidence in #180.

  ⚠️ **Consequence for the convention, and it is the reporter's:** a rule asking for a proposition asks for the thing that is dropped first under load. So *"ask for a proposition, not a name"* settles **what** to ask for and says nothing about **when**. A convention applied at write time will decay; applied at **curate** time — when someone is already rereading headings with the body in front of them — it might not. Explicitly a guess.

  ⚠️ **THE "ONE-THIRD INSTABILITY" IS NOT SUPPORTED BY THREE MEASUREMENTS, AND ONE OF THEM CONTRADICTS IT.** Rubric close calls here 4 of 12 (33%); this hand classification ~23 of 97 (24%); the reporter's hand classification **8 of 96 (8%)**, which they reported as *"the same one-third instability"* — it is not, by their own numbers. Three classifiers give 33%, 24%, 8%. **The instability is real and its magnitude is unmeasured.** Do not publish a fraction.

  **Consequence, and it is the actionable one:** the convention is expensive for adopters not because their subject matter lacks names, but because **a log written at the moment of the incident comes out in the past tense, and turning an incident into a proposition is a second act of thought the writer does not feel they have time for.** So #180's convention should ask for a **PROPOSITION, not a NAME**. That is a claim about writing rather than about domain, and it is testable on any log.

  ⚠️ **METHODOLOGICAL CORRECTION, owed back to the reporter before they publish their 28%: the code-span proxy is NOT an upper bound on rule 1.** It misses unbackticked names — our `awk` apostrophe heading fires rule 1 with no code span — and it counts backticked tokens that are not the malfunctioning artefact (our `` `grep` `` heading is a code span and classifies SYMPTOM). In our recurrence-12 it gives **1 code span against 2 rule-1 firings**, so it errs in *both* directions at small n. It is a correlate, not a bound, and should not be published as one — in the issue that exists because that same proxy produced a wrong 27%.

- ⭐ **[2026-09-13] #180 heading-classification rubric — PUBLISHED BEFORE THE POPULATION WAS READ.** Written blind, on purpose: the reporter's own "3 of 4" cannot be reproduced (they re-classify their four as 2 of 4), and the disagreement is a judgement call with no recorded rubric. Sent to them for **blind classification of their four** against this text, so the result is two independent classifications of one population rather than one instrument run twice.

  A heading **NAMES A MECHANISM** if it identifies the causal element — the construct, rule or property that produced the behaviour — well enough that a reader could recognise a recurrence *from the heading alone, without opening the body*. Apply in order, stop at the first that decides:

  1. Does the heading contain a **named artefact** — a code construct, flag, function, file type, tool or API — and is that artefact **the thing that malfunctioned**, not merely where it was observed? → MECHANISM.
  2. Does the heading state a **general rule** of the form *X causes Y* or *X is indistinguishable from Y*, where X is a **property** rather than an event? → MECHANISM.
  3. Otherwise it describes what was observed — a wrong output, a count, a failure, a surprise — without saying what produced it. → SYMPTOM.

  ⚠️ **Tie-breaker: disagreement resolves to SYMPTOM.** The claim under test is that the heading is matchable by a header-only read; a heading needing argument to be called a mechanism will not be matched under time pressure. This makes the instrument conservative, which biases *against* #180's thesis — deliberately, since this repo would be adopting it.

  ⚠️ **v1 was unmeasured. It now has one cross-classification and the result is below.**

- ⭐ **[2026-09-13] RUBRIC v2 — "named" is PINNED STRICT: an identifier a reader could grep for.** `next/dynamic`, `isUnscored()`, `$0`, `[^>]*` qualify. A construct *category* does not: *"a deploy-detector"*, *"predicate"*, *"a path"* are categories and fall to rule 3. Worked example each side, per the reporter's v2 request.

  **Why strict, and this is their argument not mine:** a header-only read under time pressure matches on **tokens**, not on whether a phrase can be argued into naming a cause. And a loose "named" quietly undoes the tie-breaker's bias — the rubric would read as conservative while classifying leniently.

- 🔴 **[2026-09-13] #180's RATIO IS NOT PUBLISHABLE; #180's CLAIM SURVIVES AND GOT STRONGER.** Three methods over one closed population of four (4 recurrence-marked entries in 41):

  | method | result |
  |---|---|
  | published 2026-09-12, method unrecorded | 3 of 4 symptom |
  | reporter's intuitive re-read, no rubric | 2 of 4 |
  | rubric v1, strict reading of "named" | **4 of 4** |

  **The entire 2-to-4 spread rides on one undefined word in the rule that decides first.** Relax "named" to admit construct categories and headings 3 and 4 both flip, reproducing the intuitive 2 of 4 exactly. ⚠️ **That is why the original measurement was irreproducible** — *"names a mechanism"* has a free parameter and each classifier silently chose a different value. The finding is one level up from the ratio.

  ⚠️ **Direction matters and cuts toward #180**: 4 of 4 under a rubric deliberately biased *against* it means the convention problem is **total** in that population. Publish the irreproducibility of the ratio; do **not** weaken the claim on it. One of the four verdicts is flagged CONTAMINATED by the reporter — I had leaked a worked example — and is excluded from any blind count.

- ⭐ **[2026-09-13] Retirement destination: an archive file beside each source.** `gotcha-log-archive.md` next to the log, `hypothesis-log-archive.md` next to the hypothesis log. Maintainer's call. Rationale: two local precedents already do this — `memory/project_hypotheses_closed.md` (2026-09-06) and the adopter's own split (#178) — so it ships as a *described* pattern, not a new invention. Rejected: one `memory/archive/` for every layer (no precedent, a new pattern to get right) and delete-and-rely-on-git (loses grep, and the log's whole value is being greppable when stuck). Selection is **dated before the cutoff AND `[RESOLVED` prefix**; never `[OPEN]`/`[PARKED]`; tables stay in the live file; **the split moves, it does not summarise**, verified by #178's check with a seeded control.
- 🔴 **[2026-09-13] Consequence: this repo cannot run that split yet.** The predicate selects on `[RESOLVED`, and **this log has 97 entries and zero of them carry it** (`grep -cE '^### .*\[RESOLVED' memory/gotcha-log.md` → 0). So archiving here is blocked behind a marking pass that has never happened — which is the same pass #180 wants (headings rewritten to name the mechanism). **Do both in one read of the log, not two.** ⚠️ And do not ship the pattern to `templates/` on a dry run: applied to our own log today it would move **zero entries**, which is indistinguishable from a broken selector. Mark first, then measure the split, then ship.
- **[2026-09-13] `Retire` currently means two different things and the guide contradicts itself in adjacent lines** (`docs/GUIDE.md:378` "moves them out" / :379 "don't delete"). Fixing the word is part of this change, not a separate one: deletion for topic-file and memory-index entries, **move to the archive** for the gotcha and hypothesis logs.

- **[2026-09-12] Split the treatment by surface, not by cost.** Keep the full battery on `templates/` and `.claude/skills/` — it found 5 blockers today. Stop using lenses to proofread the record; mechanize or prune it instead. Rationale: H-025 plus today's round, where the large majority of findings were on the record.
- **[2026-09-12] The stale-number predicate is EQUALITY, not PRESENCE.** The first draft proposed *"counts must be expressed as a command, not a digit."* Refuted against its own live instance: `reference-integrity/README.md` already printed the re-deriving command **beside** the stale digits, under a sentence saying any number there is dated. The remedy was applied and the number was still wrong for nine days. The check must **run the command and compare**.
- **[2026-09-12] Rejected as a check: #65's general form** (*a count that travels without its enumeration*). Population is all prose; false-positive rate unusable. Recorded `rejected` in the Mechanized table rather than deleted.
- **[2026-09-12] Do not cut review on the shipped surface to save cost.** Every axis has measured evidence it buys something (H-020). The saving comes from mechanizing recurring shapes (#127), not from cutting lenses.

## Open Questions

- 🔴 **[2026-09-13] THIS REPO CANNOT MEASURE ITS OWN LAYER-4 HISTORY, AND THAT IS A PLACEMENT DECISION WE MADE.** The adopter proposed an arithmetic gate that kills the curation-raises-proposition-rate finding without any classification: a 16-point swing over 52 entries needs ~8 headings rewritten by retire passes, and they can point to **two**. `git log` counts it; no judgement, no motivated-reasoning exposure. **It is unrunnable here.** `git ls-files memory/` → **0**; `git check-ignore -v memory/gotcha-log.md` → `.gitignore:17:/memory/`; `git log --oneline -- memory/gotcha-log.md` → **0 commits**. A positive would be one line per commit, with heading rewrites visible as `-### / +###` pairs in `git log -p`.

  **So every question of the form *how did this log change over time* is unanswerable in the framework's own reference implementation.** The adopter put their log in `docs/` (tracked); we put ours in `memory/` (gitignored, maintainer-local). Their instrument exists and ours was destroyed by our own placement choice, which this repo has never examined — `templates/gotcha-log.md` prescribes the file and says nothing about whether it should be under version control.

  ⚠️ **This bears directly on #178**, which is about moving entries between files: the split's own verification (*every heading present before appears in exactly one file after*) is checkable here only against the working tree, never against history. **Worth an issue in its own right**, and it is not one I should file without the maintainer, because the remedy — tracking `memory/` — reverses a Hard Constraint.

- ⭐ **Does this need a new lint rule at all?** The repo already has `<!-- verify: cmd -->` probes, a runner in `curate` Step 0 sub-step 5, and a 34-positive fixture (`tests/fixtures/verify-runner/`). A stale-number check may be **probes attached to the numbers that matter** plus a rule asserting that numbers in designated files carry one — reusing a tested runner instead of building rule 14 from scratch. **Settle this before writing any new checker.** Cheaper, and it fails in a direction the repo has already measured.
- **What is the population?** Fixture headers/READMEs are enumerable and where the class is densest. `CLAUDE.md`, the ledger and the baseline are higher-stakes but unenumerable. Start narrow and widen on evidence — a narrow check that fires beats a broad one that gets ignored.
- **How big should the record be?** 477 KB memory + ledger + hypothesis log + claim registry + verification log + 11 raise notes. Each was justified; together they are what review now spends most of its money on. Keep-and-mechanize, or prune hard. **This is the maintainer's call, not the agent's.**
- ~~What is the retirement destination?~~ **ANSWERED 2026-09-13** — archive file beside each source; see Decisions.
- **Does Cluster B (#178/#179/#180) ride in v1.42.0 or follow it?** It is the same surface as the step-1 reclamation pass, so doing them separately means two full batteries on `templates/curate.md`. Doing them together makes v1.42.0 a much larger MINOR.
- 🔴 **#180's "3 of 4" DOES NOT REPRODUCE, and the experiment needs a published rubric before it is run.** Established 2026-09-13 with the reporter. Two independent problems. **(1) No record**: the population, the intervention and the claim landed in one commit — a fourth recurrence marker was added, two of the four headings were rewritten to name mechanisms, and the "3 of 4" sentence was written, all together. So the claim describes pre-rewrite text and is false against its own file afterwards; it is an internal-consistency argument, not a measurement. **(2) The reporter re-classified their own four pre-rewrite headings and got 2 of 4, not 3.** The swing entry is a judgement call — whether *"writing about a path makes a reference to it"* names a mechanism or states the observation. **That disagreement IS the finding**: n=4 with a subjective classifier and no recorded rubric is much softer than "3 of 4" sounds. ⚠️ **Publish the rubric before classifying anything**, or the two repos produce two instruments and no way to compose them. The reporter has offered to classify their four **blind** against our rubric, which turns one instrument run twice into two independent classifications of one population — take that offer.
- **Should `docs/archive/LANDSCAPE.md` carry a supersession marker?** Left untouched 2026-09-12 — archived under the 2026-04-14 pivot, and rewriting archived material may be worse than leaving it.
- **Is "ask two or three claims per release" worth formalising?** On 2026-09-12 the maintainer caught two errors three lenses missed, by asking *"is that true?"* of one sentence. The lenses verified citations **resolved**; the question was whether they **said what was claimed**. Different question, much cheaper, better hit rate. Unclear whether it survives being turned into a step.

## Outcome

**Status**: In progress
**Date**: opened 2026-09-12
