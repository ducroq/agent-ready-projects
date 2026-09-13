# Cost and record discipline

## What & Why

The framework's running cost is dominated by two things that are not the product: **review rounds spent proofreading the record** (memory, changelog, ledgers, registries, baselines) and **an auto-loaded surface that exceeds the budget the framework itself sets**. The 2026-09-12 session measured both and found one recurring, mechanizable defect class behind most of it.

Goal: make the framework cheaper to run without cutting the review of the shipped surface, which is measurably earning its keep. Framed by #126 (review cost unpriced), #127 (promotion path, shipped v1.41.0), #109/#143 (auto-loaded set), H-025 (most findings are on the record, not the change).

**Not in scope**: reducing lens count or round count on `templates/` and `.claude/skills/`. H-020 measured every axis there and found each buys something; the 2026-09-12 round found 5 blockers in a prose-only change.

## Current Status

**Savepoint 2026-09-12, second block.** v1.41.0 is tagged and pushed. A later `/update-drift` + `/audit-context` pass committed `76d6581` (**not pushed, no release**) and filed #170-#174.

**Last action**: swept v1.40.0 re-scoping residue; replaced lint rule 1's hardcoded never-exempt list with derivation from `.gitignore` negations (fixture T14 + ablation A13 seed the rot case a literal cannot pass).

**Next action — DECIDED 2026-09-12, run in this order.** Nothing below is blocked on a call any more; reasons are on the issues.

1. ✅ **DONE 2026-09-13 — `CLAUDE.md` reclamation pass** (`dac4ad2` + review fixes). 38,750 → ~35,400 chars after the review corrections were written back in. ⚠️ **It does NOT clear the soft flag, and the first draft of this line claimed it did.** `templates/audit-context.md` Step 1 owns the 35,000 threshold and budgets in **bytes**, so `/audit-context` still flags this file; `CLAUDE.md`'s own header prescribes `wc -m`. **Two instruments for one number — file it, do not settle it in passing.** No digit for headroom here: it moved 4,145 → 4,123 → 3,456 inside one day as both files were edited. Re-derive: `{ wc -m CLAUDE.md; wc -m "$HOME/.claude/projects/<slug>/memory/MEMORY.md"; }` against the 40,000 hard cap. **Steps 2–4 are unblocked.** Method: deleted a duplicate, did not compress prose. The `tests/` block restated each fixture's rationale, which already lives in the fixture's `README.md` or runner header. ⚠️ **The duplicate had rotted, which is the reusable finding**: the copy of `reference-integrity`'s T/N commands kept in `CLAUDE.md` used `\bT[0-9]+\b` and returned **38/35** against the fixture README's `\bT[0-9]+[a-z]?\b` and a true **40/37**. Two surfaces, two commands, and the wrong one was the always-loaded one. Three fixtures held their count commands *only* in `CLAUDE.md` (`dead-reference`, `step15-tables`, `size-ratchet`) — **moved into the runner headers, commands only, no digits**.
2. **#172** — `--raise-budget` on `templates/project-file.md`, then add the profile requirement to the *Before committing* row. Decided rather than trimmed: the file has no reclaimable padding (measured), and the only ~60 spare bytes are #68's own fix. ⚠️ HIGH tier — full battery, and check #157 (`--update` erases the moved-bytes warning).
3. **#173** — the `docs/GUIDE.md` row for `update-drift` (absent entirely), then the `CLAUDE.md` inventories once step 1 has made room.
4. **#174** — the `⊘` marker: `refcheck.py` **and** `templates/audit-context.md` Step 4, or it is the #92 oracle-only trap. Seed a `⊘` case first; the class is at zero in the fixture.
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
- [ ] **Estate cleanup (#169)** — inert project-local `review-changes` copies, shadowed since v1.40.0. The count is a COMMAND, not a digit — it moved 13→12 mid-session on 2026-09-12 while remediation ran in a sibling repo: `bash scripts/install-global-skills.sh --check ~/repos | grep -c 'inert local copy'` — the bare `--check` tail counts ALL issues, not just these. ⚠️ Check each for local modifications *before* deleting; keep every `.claude/review-profile.md`
- [ ] **COMMIT v1.41.0** — 13/13 lint, 16/16 fixtures green. Then tag per `templates/release.md`, then refresh globals (`scripts/install-global-skills.sh`) since the guard requires a pushed+verified tag
- [ ] **Step 1 — stale-number check.** See Decisions for the design turn; read it before building
- [x] **Step 2 — bring `CLAUDE.md` under its own cap.** DONE 2026-09-13, `dac4ad2`. 34,753 chars. ⚠️ **Do not re-inline reference material to make it handy** — that is how the file got to 38,750, and the inlined copy was wrong.
- [ ] **Step 3 — make `memory/` navigable.** Add headings to the 5 opaque files; split `MEMORY.md` Current State
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
| entries | 97 | 89 |
| heading carries `[RESOLVED` | **0** | 52 (58%) |
| size | 126,144 chars | 178,616 |
| dated before the current month | 72 | 55 |

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

## Decisions

- ⭐ **[2026-09-13] Retirement destination: an archive file beside each source.** `gotcha-log-archive.md` next to the log, `hypothesis-log-archive.md` next to the hypothesis log. Maintainer's call. Rationale: two local precedents already do this — `memory/project_hypotheses_closed.md` (2026-09-06) and the adopter's own split (#178) — so it ships as a *described* pattern, not a new invention. Rejected: one `memory/archive/` for every layer (no precedent, a new pattern to get right) and delete-and-rely-on-git (loses grep, and the log's whole value is being greppable when stuck). Selection is **dated before the cutoff AND `[RESOLVED` prefix**; never `[OPEN]`/`[PARKED]`; tables stay in the live file; **the split moves, it does not summarise**, verified by #178's check with a seeded control.
- 🔴 **[2026-09-13] Consequence: this repo cannot run that split yet.** The predicate selects on `[RESOLVED`, and **this log has 97 entries and zero of them carry it** (`grep -cE '^### .*\[RESOLVED' memory/gotcha-log.md` → 0). So archiving here is blocked behind a marking pass that has never happened — which is the same pass #180 wants (headings rewritten to name the mechanism). **Do both in one read of the log, not two.** ⚠️ And do not ship the pattern to `templates/` on a dry run: applied to our own log today it would move **zero entries**, which is indistinguishable from a broken selector. Mark first, then measure the split, then ship.
- **[2026-09-13] `Retire` currently means two different things and the guide contradicts itself in adjacent lines** (`docs/GUIDE.md:378` "moves them out" / :379 "don't delete"). Fixing the word is part of this change, not a separate one: deletion for topic-file and memory-index entries, **move to the archive** for the gotcha and hypothesis logs.

- **[2026-09-12] Split the treatment by surface, not by cost.** Keep the full battery on `templates/` and `.claude/skills/` — it found 5 blockers today. Stop using lenses to proofread the record; mechanize or prune it instead. Rationale: H-025 plus today's round, where the large majority of findings were on the record.
- **[2026-09-12] The stale-number predicate is EQUALITY, not PRESENCE.** The first draft proposed *"counts must be expressed as a command, not a digit."* Refuted against its own live instance: `reference-integrity/README.md` already printed the re-deriving command **beside** the stale digits, under a sentence saying any number there is dated. The remedy was applied and the number was still wrong for nine days. The check must **run the command and compare**.
- **[2026-09-12] Rejected as a check: #65's general form** (*a count that travels without its enumeration*). Population is all prose; false-positive rate unusable. Recorded `rejected` in the Mechanized table rather than deleted.
- **[2026-09-12] Do not cut review on the shipped surface to save cost.** Every axis has measured evidence it buys something (H-020). The saving comes from mechanizing recurring shapes (#127), not from cutting lenses.

## Open Questions

- ⭐ **Does this need a new lint rule at all?** The repo already has `<!-- verify: cmd -->` probes, a runner in `curate` Step 0 sub-step 5, and a 34-positive fixture (`tests/fixtures/verify-runner/`). A stale-number check may be **probes attached to the numbers that matter** plus a rule asserting that numbers in designated files carry one — reusing a tested runner instead of building rule 14 from scratch. **Settle this before writing any new checker.** Cheaper, and it fails in a direction the repo has already measured.
- **What is the population?** Fixture headers/READMEs are enumerable and where the class is densest. `CLAUDE.md`, the ledger and the baseline are higher-stakes but unenumerable. Start narrow and widen on evidence — a narrow check that fires beats a broad one that gets ignored.
- **How big should the record be?** 477 KB memory + ledger + hypothesis log + claim registry + verification log + 11 raise notes. Each was justified; together they are what review now spends most of its money on. Keep-and-mechanize, or prune hard. **This is the maintainer's call, not the agent's.**
- ~~What is the retirement destination?~~ **ANSWERED 2026-09-13** — archive file beside each source; see Decisions.
- **Does Cluster B (#178/#179/#180) ride in v1.42.0 or follow it?** It is the same surface as the step-1 reclamation pass, so doing them separately means two full batteries on `templates/curate.md`. Doing them together makes v1.42.0 a much larger MINOR.
- **Before adopting #180's heading convention, run the experiment it names.** It costs little and it is the only thing that would settle the claim: rewrite the headings of this repo's three re-implementations of the same bug to name the mechanism, then check whether a header-only read surfaces the match. #180 says explicitly it could not run this from outside.
- **Should `docs/archive/LANDSCAPE.md` carry a supersession marker?** Left untouched 2026-09-12 — archived under the 2026-04-14 pivot, and rewriting archived material may be worse than leaving it.
- **Is "ask two or three claims per release" worth formalising?** On 2026-09-12 the maintainer caught two errors three lenses missed, by asking *"is that true?"* of one sentence. The lenses verified citations **resolved**; the question was whether they **said what was claimed**. Different question, much cheaper, better hit rate. Unclear whether it survives being turned into a step.

## Outcome

**Status**: In progress
**Date**: opened 2026-09-12
