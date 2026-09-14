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

**Savepoint 2026-09-14.** Token reduction complete for both halves (unpushed, no release).
Review depth cut separately on the maintainer's decision: round cap of two with a
same-defect-in-a-second-file exception, `CLAUDE.md` to LOW, `narrow-fork` retired. The skill's
own warning that a cap ships introduced defects was kept, not deleted to afford the budget.

Filed #191 — Alibaba open-code-review / AACR-Bench, evaluated and parked; nothing started.

**Next**: the one cheap unmeasured item — whether the `docs/**` → LOW re-tiering reduces spend or
only moves it. One release will say.

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
