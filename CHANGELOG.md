# Changelog

All notable changes to the agent-ready-projects framework. Adopters can check their project file's `agent-ready-projects` version against this log to see what's changed.

<!-- Maintainer release process (issue #14):
     When promoting a `vX.Y.Z (candidate, unreleased)` block to a dated release,
     also tag the release commit:

         git tag -a vX.Y.Z <commit> -m "vX.Y.Z"
         git push origin vX.Y.Z

     `-a` because a lightweight tag carries no tagger, date or message, and
     `git describe` and release tooling treat the two differently. Push the
     SINGLE ref, never `git push --tags`: that publishes every local tag,
     including wip-* and private scratch tags, permanently. (This block said
     `git push --tags` until v1.21.0, contradicting `templates/release.md`
     Step 6 — which is the copy adopters follow.)

     Tags let adopters `git checkout vX.Y.Z` to inspect a pinned version and
     `git diff vX.Y.Z..vX.Y+1.0 -- templates/` to preview an upgrade. -->

## v1.25.0 (candidate, unreleased)

### The adversarial lens gets one rule for claims that need measuring, and a place for hypotheses to be born (closes #39)

`#35`'s negatives rule and `#39`'s absolutes rule were the same failure from two sides — #39's own issue says so — and they now ship as one instruction rather than two adjacent paragraphs: **a claim that needs a measurement gets one, gets hedged, or is not ready.** Merging cost less than adding #39 alone.

**#39's gate was met by this repo violating it.** The constraint said the rule stays maintainer-local until it catches something in a repo other than this one. On 2026-08-12 — eighteen hours after that sentence was written — this repo shipped *"breaks on prettier 2 and survives prettier 3"* into `templates/review-changes.md`, generalised from two isolated one-line tests on 3.9.6. An adopter refuted it on 3.8.1, a version never tested here. An absolute in a description, unmeasured, on the surface the rule governs, caught from outside. That is as close to a natural experiment as this gets, and it is a better argument than the convergent-runner evidence offered earlier and correctly declined as off-subject.

**And it closes the cheapest half of a separate gap.** The framework *reads* the hypothesis log — `curate` sub-step 7 surfaces entries due for review — and nothing anywhere says when to write one. Creation was manual and unprompted, which is why four hypotheses covering this session's load-bearing claims were written retrospectively at the end of it, reconstructing refutation criteria that were live hours earlier. The merged rule now ends: **where the measurement cannot be taken yet, the claim becomes a hypothesis with a review date.** That fires at the moment the claim is made, which is the only cheap moment to write one.

The ADR half of that gap is deliberately not addressed: ADRs record decisions rather than claims, so this detector does not reach them, and the evidence is one session, all internal — the same standard #39 was held to before today.

### `review-changes` warns about a prettier-2 rewrite that corrupts its own risk table (adopter report)

An adopter porting the magnitude gate added a second glob to the bolded bullet — `` **… under `.claude/skills/**` or `.claude/agents/**`** `` — and their husky/prettier hook rewrote it to `` `…skills/**`or`…agents/**` ``, eating the spaces, because a glob's trailing `**` is parsed as a bold delimiter. Correct in the diff, wrong only when rendered, on the line that tells adopters skills are HIGH risk.

**That claim was wrong, and the correction is the more useful entry.** The first version of this note said two globs break on prettier 2 and survive prettier 3, and that the single-glob form survives both. It was generalised from two isolated one-line tests on 3.9.6. The reporter re-measured on **3.8.1** and refuted it; re-measured here, the full matrix is:

| shape | prettier 2 | 3.8.1 | 3.9.6 |
|---|---|---|---|
| single glob, no later code span | **breaks** — closing `**` becomes literal | **breaks** | survives |
| single glob, a later code span on the line | survives | survives | survives |
| two globs in one bolded phrase | **breaks** — spaces eaten | **breaks** | survives |

Two things follow. The boundary is **inside the 3 series**, not between 2 and 3. And the protection is **a later code span on the same line** — which is why this repo's bullet survived when tested in the full file and broke when tested alone, and why `templates/review-changes.md` at `ea9ecb3` did in fact ship a line that prettier ≤3.8.1 corrupts. The parenthetical added in `d674dbe` protected it *by accident*, not by design.

**The fix shipped is the shape, not the warning.** Both bullets now put the glob in a parenthetical rather than inside the bold, so the vulnerable construct is gone from this repo rather than annotated. Verified stable under prettier 2, 3.8.1 and 3.9.6.

A second refinement from the same adopter closes the loop: the protection is **exactly one** later code span — *two* reintroduce the failure in the other form, with the spaces between them eaten. So "add a code span to protect it" is the natural reading and is wrong, which is why the durable answer is a shape rule: **never end a bolded phrase with a `**`-suffixed glob.** That survives in a reader's head; a version boundary inside the 3 series and a span-count do not.

Worth recording why this one was hard to see. The previous bullet pair was protected only by a trailing `` `---` `` code span — punctuation that reads as deletable while tidying. A future editor removing it would have silently corrupted the line, with nothing anywhere explaining why it mattered.

Step 1.5 does not catch this: it checks tables and fences, not emphasis spans. Filed separately.

The gotcha log's entry-size rule is restated in the unit that costs, and the check it seemed to need is not built. Closes the rest of #46.

**Adopter action: none.** If you have been ignoring "keep each entry to 2-3 lines", you were right to.

### The rule was unenforceable, and enforcing it would have been wrong

`curate` Step 1 said *"keep each entry to 2-3 lines"*. Measured across three logs and 277 entries, every one of them "passes" by lines — median 5 including the heading — while running 700–1,200 characters. A markdown source line has no length limit, so the unit did not track the cost and the rule could be met and violated at the same time.

Restating it in characters made it worse, not better. At the ~200 characters the rule seemed to intend, **88–92% of entries in all three logs are violations** — a bulk false-positive generator, which is the class v1.15.1 spent a release removing from Step 4. When nine entries in ten breach a rule across three independent populations, the rule is wrong.

| log | entries | median | >1500 | >3000 |
|---|---|---|---|---|
| agent-ready-projects | 34 | 737 | 20% | 2% |
| agent-ready-papers | 40 | 1,108 | 27% | 2% |
| llm-distillery | 203 | 1,200 | 35% | 5% |

### And the reason to police it had already gone

v1.24.0 stopped `curate` reading bodies: Step 0.3 reads headings, and a body is opened only for an entry being acted on. **A long entry now costs nothing per session.** The cost argument that would have justified an entry-size check died with the read-path fix, and what remained was a quality argument — weaker, and per the #16 closure this repo does not ship a pattern on enthusiasm.

So the outcome is a rule removed and replaced with a measured one, and no new check: entries run ~700–1,200 characters and that is fine; **above ~3,000 is the signal worth acting on** — 2–5% in every log measured, and at that size it is a page, which belongs in a topic file or an ADR.

## v1.24.0 (2026-08-12)

`curate` Step 0 stops reading the corpus it maintains. Closes part of #46.

**Adopter action: two, both small.** `[RESOLVED]` and a recurrence count now go in an entry's *heading*, not its body, so curation can see them without opening every entry — `templates/gotcha-log.md`, `docs/EXAMPLE.md` and `docs/guide/03-the-loop.md` all say so now. Existing entries are unaffected and read as open until touched. And if your gotcha log uses `##` headings rather than `###`, nothing breaks: the reader matches both.

### Measured

An ordinary session reads a **median of 3** memory files — from 2,264 real session transcripts, p90 of 6, max 15, against corpora of up to 86 files. The layered design works as designed. `curate` Step 0 was the sole exception, reading everything.

| repo | before | after | saving |
|---|---|---|---|
| agent-ready-projects | 118,141 chars | 41,888 | 64% |
| agent-ready-papers | 244,753 | 95,651 | 60% |
| llm-distillery | 1,035,845 | 77,375 | **92%** |

Method: *before* is the project file plus every `memory/*.md`; *after* is the project file plus the index, both-level headings, and the Promoted table. The project file is on both sides because four sub-steps read it — it is 24–36KB and dominates the "after". The runner's report and the mtime listing are output rather than reads and are excluded from both.

### What changed

- **Headings are ~6–7% of a gotcha log** and carry date, title, status and a line number. Steps 0.3, 1 and 2 read those; a body is opened only for an entry about to change.
- **Both heading levels, and a reconciled count.** `grep -c '^\*\*Problem\*\*'` is the ground truth the heading count is checked against.
- **Step 0.3 reads the Promoted table too**, because resolution is recorded there as well as in headings.
- **Sub-step 5 does not read memory files at all.** The runner extracts and executes the annotations; the agent reads its report.

### The first draft was refuted on ten points; three are worth recording

- **The heading grep was level-blind and missed 105 of 200 entries** in the repo the headline number came from. `llm-distillery` uses `##` for entries and says so in its own file comment. `^### ` returned 94 — a plausible number omitting half the file, including every entry from the preceding two weeks. That is the failure this very sub-step enumerates six times over, committed by the instrument built to avoid it. It also invalidated the evidence: 200 entries not 94, mean entry **1,488** chars not 3,119 (≈7× over spec, not 15×), and 5 headings already carried `[RESOLVED]` where the draft reported none.
- **Step 0.3 without the Promoted table is a bulk false-positive generator** — 11 entries in one measured log are recorded resolved in the table with no marker in their heading, so every run would report them lingering, forever. The v1.15.1 failure class.
- **The convention was written into the skill and none of the artifacts that define it.** An adopter following `templates/gotcha-log.md` or `docs/EXAMPLE.md` would have written body status and been told about it every session.

### An eleventh finding, from running the skill rather than reviewing it

Sub-step 3's reader was fixed to match both heading levels; **Step 1 kept the level-blind `^### `**. A review lens, a targeted repo-wide sweep for that exact string, and the author all missed it. Invoking `/curate` surfaced it in the first minute, because execution reads the whole artifact in order while review reads the diff — and Step 1 was not in the diff that broke it. That is a distinct instrument, and it now precedes release for procedural skills. (+66 bytes, ratcheted deliberately.)

### Rule 8 earned its place twice in one day

The ratchet, added hours earlier, refused both this change and the propagation that followed it. That is the intended workflow: body size and run cost are different currencies, and it forces the trade to be stated rather than assumed. ~2KB of template text, paid once per invocation and prompt-cached, buys 60–92% of a read surface paid in fresh tokens every run.

## v1.23.0 (2026-08-11)

`audit-context` Step 4 gains a skip for paths that were never meant to resolve, so instructional placeholders stop being re-triaged on every audit. Closes #45.

**Adopter action: mark your placeholders.** A path in a "how to add one" recipe, or one a runbook tells the reader to create, can carry `<!-- placeholder -->` immediately after it. Angle-bracket paths (`docs/work-items/<slug>.md`) need no action — they announce themselves and are skipped automatically, so that population changes without you doing anything. Everything else stays in the findings list exactly as before.

### The asymmetry

Step 4 already solved this once, for deletions: `! test -f`, `> **Deleted**:` and `~~strikethrough~~` are skipped, *"or the audit will keep proposing you 'fix' a line whose whole purpose is to record a removal."* It had no equivalent for paths that were never real, and it named that population two paragraphs later while telling the reader to tolerate it.

Both instructions were right, and together they guaranteed a permanent list a human re-reads and re-dismisses forever. Measured on one adopter repo: two audits three hours apart, four commits between them, byte-identical three-line findings — one entry being this step's own worked example. That collided with the step's own alarm (*"if a check re-derives the same non-finding on consecutive runs, fix the check"*), which would have sent an adopter to loosen the extractor — the one edit the step calls most dangerous.

### What ships

- **Two markers.** `<!-- placeholder -->` on the line, mirroring the `<!-- verify: -->` idiom; and an angle-bracket segment (`filters/<name>/<version>/config.yaml`), which announces itself and costs the author nothing.
- **A counted section**, `Skipped as declared-placeholder`, separate from asserted-absent. Skips stay visible: the step's own rule is that a skip is the one outcome with no rung to name.
- **A marker on a path that resolves is a finding**, not a skip — mislabelling is how this change could hide a real break.
- **The marker is span-scoped**, covering the nearest eligible path before it — the way the strikethrough and deletion markers already are. The first draft was line-scoped, and a review lens showed it relabelling a co-located genuine break as intentional: `copy \`template.py\` <!-- placeholder --> and register it in \`wire_up.py\`` silenced `wire_up.py` too. That is the defect this step had already measured once for strikethrough, reintroduced by the new skip and specified in its prose.
- **An ineffective marker is a finding too** — a marker with no extractable path before it. Its message names the possible causes rather than asserting one, because a directory, a glob, a URL and a non-whitelisted extension all reach it and only the last is a whitelist gap.
- **A mentioned marker is not a used one.** Code spans are masked before the marker is searched for, so any document explaining the convention — including this step, and the adopter's own copy of it — does not report itself.
- **The two contradicting paragraphs are reconciled**: prove the check is alive by seeding a break first; a repeat that survives a caught seed is residue, and residue gets *marked*, not loosened away.

### The extractor had to widen, and that is the interesting part

`<slug>` paths were never captured at all — `PATH_RE` did not admit `<` or `>`. So the first fixture run showed the angle-bracket negatives passing, and they were **vacuous**: "not reported" meant "never extracted", which is indistinguishable from a working skip and is counted nowhere.

Widening it once was not enough either. The *leading* character class was still `[A-Za-z0-9_.]`, so the commonest real form — a path that begins with the bracket, `` `<root>/memory/MEMORY.md` `` — remained invisible; across the author's ~30 repos that is 36 of 114 backticked angle-bracket paths. The fixture could not see the gap, because its negatives only asserted "not in findings". It now asserts that each declared placeholder appears in the **counted** section, which is the only form of the assertion that distinguishes skipped from never-seen.

**Measured, no new phantoms**: across every `*.md` in ~30 repos the widened pattern admits zero tokens that are not angle-bracket placeholders.

`tests/fixtures/reference-integrity/` gains T12, T13, T14 (the failures this loosening newly permits) and N8, N9, N10 (the skip working) — 22 seeded cases, all behaving correctly. Per the seeded-true-positives rule, a loosening is licensed by the breaks it still catches, not by a quiet run.

## v1.22.0 (2026-08-11)

`templates/curate.md` Step 0 sub-step 5 ships the verify runner instead of describing it, and Step 0 gains a sub-step that asks whether the memory index agrees with itself. The step executes the `<!-- verify: ... -->` annotations in the memory files, and every hand-written implementation of it observed so far reported *nothing wrong having checked nothing* — a silent, self-certifying pass. Closes #32, #34, #35, #42, #43 and #44.

**Adopter action: run the new runner over your memory files before anything else, and expect it to find things.** In one measured adopter repo every annotation reports ERROR. Read them against the new writing rules — more are affected than you would guess.

> **Clarification added 2026-08-12, after this wording cost an adoption its first triage.** An adopter (ovr.news, 76 annotations, 64 of them in the `… && echo PASS || echo FAIL` shape this framework taught from v1.9.0) drafted a **decline** on the strength of the paragraph above, having concluded that upgrading meant rewriting 64 probes as a precondition. It does not. **All 64 score correctly today** via the deprecated first-line-`FAIL` compatibility rule; nothing breaks, and the rewrite is a recommendation rather than a gate. The decline was reversed only after reading the runner itself rather than this entry.
>
> The 0-pass/8-error repo cited above is the *worst* case — guards that succeed in silence — not the common one. The common one is the shape this framework taught, and it is handled. If you are triaging this release: the compatibility rule is load-bearing for you, and the upgrade is cheap. A command that succeeds in silence is now reported ERROR rather than passing; `\|` is un-escaped only inside table cells, because outside one it is shell's or awk's escape and not GFM's; and `… && echo PASS || echo FAIL` — the shape this guide itself taught from v1.9.0 — exits 0 on its failure branch, so it was never a failure signal. That last one is caught by a deprecated compatibility rule rather than silently rescored, but the commands still want rewriting.

### Versioning rationale

**MINOR — decided 2026-08-11 on the v1.20.0 precedent, with the measurement that argues for MAJOR left on the record.**

The first draft of this entry said "no adopter has to edit anything to keep working." That was written from this repo, whose two annotations both pass. Running the shipped runner against real adopter memory trees refutes it:

| Repo | Result |
|------|--------|
| `disentangled-infrastructure` | **0 pass, 8 error** — every annotation it has. Its guards are silent on success, which the new rules score ERROR |
| `llm-distillery` | 26 ran: 12 pass, 9 fail, 5 error, 3 malformed |

Nothing breaks and no annotation stops working — but until they are rewritten, one measured adopter's Step 0 reports every claim as broken. That is real adopter action, and under `templates/release.md` rule 1 it is an argument for MAJOR.

It ships MINOR on the v1.20.0 precedent, which carried a two-part adopter action including a required structural edit to an artifact adopters already held. Two things make this weaker than that, not stronger: the annotations still run and still report, and every ERROR the runner now emits is a claim that was **already** not proving what it said — a silent guard reported PASS before this release and proved nothing then either. Changing the report is not the same as changing the contract. If an adopter reports being blocked, this table is the argument to re-read.

It is not PATCH because the step gains a shipped artifact and three rules that change what a run reports.

### The defect

Six causes, each sufficient on its own, each producing output indistinguishable from "there are no state claims to check":

1. A verify command containing `exit` ends the runner's own loop mid-iteration. The command in the issue is *good practice* — it distinguishes "cannot verify" from "verify failed", which the step explicitly asks for. The runner is what had to change.
2. `ssh` — or any stdin-reading command — swallows the rest of the command list when the loop reads from stdin.
3. Prose that merely *mentions* the syntax is executed as shell. Of five `verify:` hits in this repo's memory files at the time of filing, **three were prose** — including the gotcha entry documenting a previous extraction bug — and they reported ERROR, the disposition meaning "the verify command may be stale", which invites someone to fix a line of prose.
4. `[^>]*` extraction truncates at the first `>`, mangling every command with a redirect. This repo's `memory/gotcha-log.md` records that bug **three times**, twice in the same file on the same day.
5. A table cell's `\|` escapes run as literal `echo` arguments, so the fallback branch is dead code. Found by measuring this repo's own two annotations; both were in this shape.
6. A command that succeeds in silence has proved nothing, yet exits 0. Inbound from agent-ready-papers/pipeline-atlas, which shipped `ops/run_verifies.sh` for exactly this after finding checks that passed by not running.

Sub-step 2 already warns that an empty `git log` means "the check did not run", not "nothing is stale". Sub-step 5 had the same trap one step over, with no warning.

### What ships

- **The runner itself**, as a four-backtick block in the step: extraction that ignores fenced blocks (indented, `~~~`, and nested inside a longer fence) and code spans (including CommonMark's multi-backtick form), requires a closing `-->`, and un-escapes `\|` inside GFM tables only, detected by their delimiter row; execution in a per-command subshell with stdin closed, its own output file and a timeout; and a summary line reconciling commands run against the annotations present.
- **A disposition table**, plus MALFORMED in four shapes — no closing `-->`, a second opener before the first closes, an odd number of backticks on the line, and an empty command — each loud rather than skipped, because a dropped annotation is a claim nobody checked. The `CANNOT VERIFY` prefix now wins *regardless of exit status* — a guard is free to `exit 2`, which the previous text forbade because without isolation a non-zero guard scored ERROR. The runner also prints each command's first line of output: the rule asks for evidence, so the report has to show it.
- **An exit status.** 2 means the run itself cannot be trusted — no files, an operand that is not a readable file, nothing extracted, or nothing that produced a verdict because every annotation was manual or unreachable. 1 means a claim failed, errored or was malformed. 0 means something was verified and nothing failed. The first draft always exited 0 — carrying its own disposition in words nothing parses, which is exactly what it forbids in the commands it runs.
- **Three new writing rules**, joining the three that were already there, for six: print evidence on success and fail with a non-zero exit rather than a word; keep the annotation on one line; assume nothing about the working directory. The existing pipe rule gains its converse — escape `\|` in table cells and *only* there.
- **"Zero commands extracted is a defect, never a pass"** — and so is a count the reader cannot account for, which is what the reconciliation line is for. Step 6 carries it into the report.

### New fixture — `tests/fixtures/verify-runner/`

Thirty-two positives, ten negatives, four malformed cases, seven structural cases, four timing cases and twenty-nine ablations — most of them added by three rounds of review that refuted the drafts before them. The negatives assert via canary files that the shell never happened, not merely that no row appeared; two of them are the exact strings this repo was executing out of its own gotcha log. The harness **extracts the runner from `templates/curate.md`** rather than copying it, so it cannot drift from what adopters run — the drift trap that cost this repo lint rule 6.

Its README records the rejected predicate: un-escaping `\|` everywhere. That version was refuted by running against agent-ready-papers, whose `awk -F'|' '/^\| P[0-9]+ \|/…'` row-count check is correct, passing, and not in a table — un-escaping it produced an alternation with an empty operand and reported **FAIL on a healthy claim**. Two further defects were found the same way and are stated as writing rules, since no fixture over the runner can see them: a failure branch that exits 0 is a false PASS — `docs/GUIDE.md` has shipped one in its worked example since v1.9.0, four months, and this release fixes it — and `git ls-remote origin` passed from the project root while reporting ERROR one directory over.

### The adversarial lens now requires a negative to carry its own check (closes #35)

The framework had derived this rule four times, each scoped to one of its own instruments: *"a rung you cannot run is not a pass"* and *"report what the extractor dropped"* in `templates/audit-context.md`, *"a run that finds nothing cannot distinguish a fixed check from a disabled one"* in `CLAUDE.md`, and *"report NOT REFUTED only after a thorough attempt"* in `templates/review-changes.md`. A principle re-derived four times in scoped form is one worth stating once in general — and the general case is the one that keeps costing, because it fires on the *adopter's* codebase, where the instrument is unfamiliar.

`templates/review-changes.md`'s adversarial lens now carries it: **state the check before the claim, on any negative.** Report the claim, the command that produced it, and what a non-empty result would have looked like; if you cannot state the shape of a positive, the claim is not ready. It is deliberately a change to the *sentence* rather than a new step — a separate "verify your negatives" step is skippable in exactly the cases where it matters, and this repo already has the evidence that a probe nobody runs is worse than none.

The evidence is from an adopter, not from here: five instances in one session, every one a negative, every one cheap to refute, and in every case the refuting command was run *after* the claim was asserted. `"50 of 50 publishers have a native feed"` was 18/50, because a candidate **generator** was read as a **validator**. `"All rows conform"` had 1,461 violations in the window, because neither violating source emitted during that run. The mechanism is not carelessness: a partial view is usually sufficient to form an answer, and forming one is cheaper than checking it.

**Also added to `CLAUDE.md`, alongside a maintainer-local sibling for #39** — *an absolute in an instruction is a decision; an absolute in a description is a measurement, and it needs one*. That one deliberately does **not** ship to `templates/` yet: its evidence is all from this repo, and per the #16 closure this repo does not ship a pattern on enthusiasm. It gets promoted when it catches something elsewhere. #39 stays open on that basis.

### `templates/project-file.md` gains an "Active work" section (closes #44)

Work items are tool-independent — `docs/work-items/` is a `docs/` path and `templates/work-item.md` is written tool-agnostically — but every artifact that said where the *pointer* goes said the same unconditional thing: the memory index's Current State section. `templates/project-file.md` shipped no such section. An adopter on Codex, Cursor, Windsurf, Copilot or Aider who followed every template therefore had work-item files and, by construction, nowhere a pointer could have gone.

This surfaced as the placeholder in #32's fix: a review lens refuted a first draft that had `audit-context` Step 5 audit the project file for pointers the framework never told anyone to write, which would have flagged every work-item file in a conforming adopter.

- **The project file gains `## Active work`** — one line per *in-progress* item, with the section marked for deletion where the tool has auto-memory, because keeping both copies is how the two start disagreeing.
- **Bounded on purpose.** A completed item loses its pointer; its Outcome section is the durable residue. This is the one section that would otherwise grow every session, and in the project file it is charged against the size budget — so the constraint is stated where the section is defined, not left to `curate` to clean up afterwards.
- **Eight files named the index unconditionally, not the four the issue listed**: `templates/work-item.md` (twice), `templates/README.md`, `docs/GUIDE.md` (twice, 470 lines apart), `docs/work-items/README.md`, `templates/curate.md` Steps 3 and 4, and `adopt.md`, which creates the project file and never mentioned the section at all — so every adoption produced whatever the agent happened to copy. All now name both homes, and `adopt.md` gains a step that decides between them.
- **The example pointer ships inside the comment, not below it.** Left in the body it is a live reference to `docs/work-items/slug.md`, which never exists — a guaranteed false positive in `audit-context` Step 4 and `curate` sub-step 1, planted by the framework into every fresh adoption. The template already keeps its optional checklist rows inside comments for the same reason.
- **`audit-context` Step 2 contradicted the new section outright** and had to gain an exception. Its wrong-layer list says *"Session navigation in the project file: Current State, task progress → should be in the memory index"* — which is exactly what the Active work section puts there. The rule now distinguishes session narrative (still wrong-layer) from the pointer list (right-layer where there is no Layer 3), and flags the section as wrong-layer only when a memory index exists too, since *then* there are two lists and they will disagree.
- **`audit-context` Step 5's work-item half becomes unconditional again**, reporting which artifact it read, and flagging pointers to finished work.

The alternative — declaring work items a Layer 3 feature — was rejected: it removes the pattern from five of the six tools this framework names — Codex, Cursor, Windsurf, GitHub Copilot and Aider — to avoid adding one bounded section.

### `audit-context` Step 5 and `curate` Step 0.2 stop assuming Layer 3 exists (closes #32)

Both steps addressed `memory/` unconditionally, which is Claude Code's location. The obvious fix — naming a `docs/` alternative — is wrong, as issue #32 records: `templates/README.md`'s naming map has no topic-file row, `docs/GUIDE.md` says everything goes into the project file for those tools, and `docs/` is where this framework keeps essays. In this repo that glob matches twelve files, so a Codex or Cursor adopter would have had every essay reported as an orphaned topic file — a bulk false-positive generator in the audit's cheapest step, which is the class v1.15.1 spent a release removing from Step 4.

- **The step looks for Layer 3 rather than guessing the tool**, and does not gate on one hardcoded path: this framework's own naming map says `MEMORY.md`, `adopt.md` writes `memory/MEMORY.md`, and a gate on either reports "no Layer 3" for a project that has a complete one. **Topic files with no index is the finding, not a reason to skip** — gating on the index would silence the step on the most broken Layer 3 state there is.
- **What does not apply is reported not applicable, with the reason.** Skipping is honest; skipping silently is not, because a skipped check and a passing check are indistinguishable unless the step says which happened.
- **The work-item half does not fall back to the project file.** That was the first draft and it was refuted: `templates/work-item.md`, `templates/README.md` and `docs/GUIDE.md` all say the pointer lives in the memory index's Current State section, unconditionally, and `templates/project-file.md` ships no such section. An adopter without Layer 3 who followed every template has work-item files and, by construction, nowhere the pointer could have gone — so checking it would have flagged every one of them, committing the exact error the paragraph above it warns against. **The step now reports that as a gap in the framework rather than a finding about the project**, which is what it was. **Fixed in this same release** — see the #44 section above: the project file now ships an "Active work" section and every artifact names it, so the work-item half is unconditional again.

`curate` Step 0.2 gets the same treatment, and one bug the first draft walked straight past: three lines below the sentence it fixed, `git check-ignore -q memory/ && … || echo "tracked — git log is fine"` takes the *tracked* branch on a project with no `memory/` at all, so a missing directory is answered with advice about how to read its history. Both of that sub-step's example commands — `stat` and `ls` — fail the same silent way there: stderr only, empty stdout, which reads exactly like "nothing is stale".

`docs/GUIDE.md` gains the sentence the issue asked for: it described Layer 3 as absent for these tools without saying what the audit should therefore do.

### The adversarial lens now requires a negative to carry its own check (closes #35)

The framework had derived this rule four times, each scoped to one of its own instruments: *"a rung you cannot run is not a pass"* and *"report what the extractor dropped"* in `templates/audit-context.md`, *"a run that finds nothing cannot distinguish a fixed check from a disabled one"* in `CLAUDE.md`, and *"report NOT REFUTED only after a thorough attempt"* in `templates/review-changes.md`. A principle re-derived four times in scoped form is one worth stating once in general — and the general case is the one that keeps costing, because it fires on the *adopter's* codebase, where the instrument is unfamiliar.

`templates/review-changes.md`'s adversarial lens now carries it: **state the check before the claim, on any negative.** Report the claim, the command that produced it, and what a non-empty result would have looked like; if you cannot state the shape of a positive, the claim is not ready. It is deliberately a change to the *sentence* rather than a new step — a separate "verify your negatives" step is skippable in exactly the cases where it matters, and this repo already has the evidence that a probe nobody runs is worse than none.

The evidence is from an adopter, not from here: five instances in one session, every one a negative, every one cheap to refute, and in every case the refuting command was run *after* the claim was asserted. `"50 of 50 publishers have a native feed"` was 18/50, because a candidate **generator** was read as a **validator**. `"All rows conform"` had 1,461 violations in the window, because neither violating source emitted during that run. The mechanism is not carelessness: a partial view is usually sufficient to form an answer, and forming one is cheaper than checking it.

**Also added to `CLAUDE.md`, alongside a maintainer-local sibling for #39** — *an absolute in an instruction is a decision; an absolute in a description is a measurement, and it needs one*. That one deliberately does **not** ship to `templates/` yet: its evidence is all from this repo, and per the #16 closure this repo does not ship a pattern on enthusiasm. It gets promoted when it catches something elsewhere. #39 stays open on that basis.

### `audit-context` Step 5 and `curate` Step 0.2 stop assuming Layer 3 exists (closes #32)

Both steps addressed `memory/` unconditionally, which is Claude Code's location. The obvious fix — name a `docs/` alternative — was attempted on 2026-08-08 and reverted, correctly: `templates/README.md`'s naming map has no topic-file row, `docs/GUIDE.md` says everything goes into the project file for those tools, and `docs/` is where this framework keeps essays. In this repo that glob matches twelve files, so a Codex or Cursor adopter would have had every essay reported as an orphaned topic file — a bulk false-positive generator in the audit's cheapest step, which is the class v1.15.1 spent a release removing from Step 4.

The issue offered three answers and called none obviously right. What ships combines two of them, because each alone has a hole the other fills:

- **Determine the mode first and report it.** Skipping is honest but a skipped check and a passing check are indistinguishable unless the step says which happened — so both halves that do not apply are reported *not applicable, with the reason*, never silently.
- **The work-item half runs either way**, because `docs/work-items/` is tool-independent. Only its target changes: the memory index's Current State section where Layer 3 exists, the project file's "Active work" section where it does not (#44). Report which one was read, and report it as a finding if *both* exist.
- **The topic-file half and the index-reachability half are Layer 3 only**, and explicitly do not fall back to `docs/*.md`.

`curate` Step 0.2 gets the same treatment for the same reason, and one that is sharper there: `stat` on a `memory/` that does not exist prints to stderr and nothing to stdout, which reads exactly like "nothing is stale" — the failure mode sub-step 2 already warns about for `git log`, one line up.

`docs/GUIDE.md` gains the missing sentence: it described Layer 3 as absent for these tools without saying what the audit should therefore do.

### `audit-context` Step 5 names the row it provisions, and lint gains rule 7 (closes #42)

Step 5 reports a missing memory-index pointer as its finding. An agent then adds a row to satisfy that finding, and the only wording available is the one the finding used — so when Step 5 described the row by *category* ("a row whose trigger fires at session start") it reliably manufactured category-shaped triggers. In a real adopter it produced `| Starting any session (project state) |` directly above that project's existing `| Starting any session (framework drift) |`: two rows with the same trigger prefix separated by a parenthetical, which is the exact collision v1.20.0 identified, argued against, and removed from this framework's own `CLAUDE.md` — **one day earlier**: v1.20.0 was tagged 2026-08-10 and the adopter incident is 2026-08-11. (The issue body says three weeks; `git log` says otherwise, and this entry originally repeated the figure without checking.)

Both halves shipped in **v1.20.0**, in the same range: `templates/project-file.md` renamed the row *to* a situation, and `templates/audit-context.md` added the check that described it as a category. The release whose review battery found the weak-trigger shape simultaneously shipped the checker specifying it.

- Step 5 now **quotes** the canonical row from `templates/project-file.md` and says why a category is not an acceptable substitute.
- **Two rows sharing a trigger prefix are a finding on their own** — the observable form of the collision, and cheap to detect.
- `docs/task-triggered-pointers.md` gains the generalisable rule the issue offers: **presence is not adoption; for a row whose function is to fire on a situation, the wording is the artifact.** It bites hardest where a skill provisions the row, because the skill's description of what it wants is what an agent writes.

**New lint rule 7** covers the class, not just the instance — with a stated boundary. Rule 6 (#23) compares `templates/<name>.md` against `.claude/skills/<name>/SKILL.md`; here those two agreed with each other and contradicted a *third* file. Rule 7 asserts that a section provisioning a canonical row quotes it verbatim, and fails loudly if the row is renamed, deleted, or duplicated rather than silently comparing nothing.

Three of its design decisions were forced by its own review, and each is a defect the first draft shipped:

- **The canonical trigger is derived, not hardcoded** — it is the trigger cell of the row whose target is the memory index. A hardcoded prefix quoted a *decoy* the moment a second situation-shaped row started the same way, which is a shape Step 5's own prose recommends.
- **The check is scoped to the provisioning section, not the file.** A file-wide grep passed while the instruction reverted to a category, because the canonical string survived in an appendix.
- **Sections declare themselves** with `<!-- provisions: memory-index-row -->` rather than being inferred from wording. Inference was tried and refuted by the fixture: a cue of "names the index and mentions a row" fired on four sections that merely discuss reachability. Dropping the marker fails the same way dropping the section does.

**`adopt.md` is covered too** — it is the *primary* provisioning site, since it creates the project file, and the first draft omitted it while claiming to close the class. Three sites are checked; the boundary is that rule 7 knows about the memory-index row only, not every canonical row the framework might grow.

Fixture at `tests/fixtures/provisioning-quote/` — 9 positives, 4 negatives, committed and re-runnable, per `tests/lint/README.md`'s own checklist for adding a rule.

**Adopter note:** if you added a standing caution that `/audit-context` will re-add a category-shaped row on its next run, it can go once you adopt this version.

### `curate` Step 0 gains sub-step 6 — index self-consistency (closes #43)

Every other check in Step 0 compares the index to something *outside* it: paths on disk, file mtimes, gotcha ages, ground truth, a verify probe. None asked whether the index agrees with itself, so two entries could assert opposite things indefinitely while each passed every check individually — both paths resolve, both files are fresh, neither is tagged as a state claim.

The founding instance sat in an adopter's index for five days and several `/curate` runs: two entries 28 lines apart, one asserting that a feature renders to readers and one asserting it does not, the second citing the same issue id and instructing the reader not to re-derive it. A probe against the sibling repo settled it in seconds. **A stale entry is wrong; a self-contradicting index is wrong while also carrying its own correction**, so which version an agent acts on depends on read order rather than on evidence — and the `@memory/MEMORY.md` import that `templates/memory-index.md` offers puts both versions into every session's context.

- **The cheap cluster first**: a `grep -on … | sort -u | cut | uniq -d` pipeline lists every identifier cited by more than one *entry*, and those entries get read *together* rather than in place. Three details are load-bearing and each was wrong in the first draft: counting per line rather than per mention (an entry repeating `#34` four times is not a cluster), keeping a qualified id distinct from a bare one (`llm-distillery#76` and a local `#76` are different trackers), and printing a warning when the index is not at the path given — an empty result from a missing file is otherwise indistinguishable from a clean index, the trap sub-step 2 already warns about for `git log`.
- **Scope, measured honestly.** Across all 31 memory indexes on the author's machine the identifier pass returns 0–21 clusters, not the 3–12 of the four repos first sampled. And it is only the cheap half: clustering by *entity* is a pairwise read of the whole index with no bound but the index's size. The step now says which half to cut short, and at what size.
- **Then by entity** — a repo, a path, a component, a host — asking "can all of these hold at once", not "is each plausible", which is what reading them in place amounts to.
- **The contradicting pair is reported verbatim and left unresolved** unless a probe settles it. The more emphatic entry is not the more likely one: in the founding instance the false entry was the emphatic one *and* the one that told the reader not to check.

Sub-step 5 gains the other half, because it is why the false entry had no probe: **a negative existence claim — or a count — is a state claim**. "There is no reader-facing count", "that endpoint doesn't exist", "nothing references the old path" read as settled fact rather than as claims about a world that moves, so nobody attaches a probe and the decay rule never reaches them — and they are disproportionately claims about *another* repository, where you cannot see the change that falsified them. **An instruction not to re-derive a claim is a reason to probe it, not a licence to skip it.**

Dog-fooded on this repo's own index while writing it: **no contradicting pair**, and the identifier pass returned five clusters that all held. What the reading did surface was `Issue tracker: 4 open` — wrong by two at the moment it was read. That is a finding for sub-step *5*, not this one: a single entry, internally consistent, wrong only against an external tracker, and carrying no probe. It is offered as evidence for the negative-existence-and-count paragraph above, not as evidence that the contradiction check works — which remains untested against anything but the founding instance, and is stated here as such.

The hypothesis-log and size-budget sub-steps renumber from 6 and 7 to 7 and 8.

### What the review battery changed

Four review lenses ran over the first draft and refuted it; the fixture above is roughly twice the size it was as a result, and every case below was added because a lens found the guard missing rather than merely unablated. Three were silent false PASSes — the failure this change exists to eliminate, in the artifact built to eliminate it:

- **Backtick command substitution was deleted from the command.** Stripping code spans could not tell a code span from a command, so `` <!-- verify: [ "`printf x`" = x ] && echo OK --> `` ran as `` [ "" = x ] ``. Code spans are now *masked* at preserved offsets and the command is taken from the original line.
- **Any stderr output defeated the `CANNOT VERIFY` prefix.** stderr was merged into stdout and arrives first, so an `ssh` guard's `Warning: Permanently added …` — the commonest line in exactly this situation — turned an unreachable host into a PASS. The two streams are now captured separately.
- **One unclosed fence blanked every later file.** `fence` was a single toggle across the whole input list, and `memory/*.md` is alphabetical, so an unterminated ``` in an early file silently dropped every claim after it while the run reconciled as prose. Fence state now resets per file.

Also: with no file arguments the runner read stdin and hung forever (the documented `memory/*.md` invocation produces none under `nullglob`); an unreadable file was invisible in the reconciliation line, which is the step's only defence; a forked child held the output pipe open indefinitely; `~~~` fences were executed; and `istable` missed GFM's legal pipe-less table form, leaving the dead-fallback-branch defect live for anyone who followed the escaping rule inside one.

**One deprecated compatibility rule.** A command whose entire first line is `FAIL` and which exits 0 is scored FAIL. This framework's own guide taught `… && echo PASS || echo FAIL` from v1.9.0 until v1.21.0, and that idiom exits 0 on its failure branch; without the rule, every such annotation in every adopter's memory files would read as a pass on upgrade. The measured case: agent-ready-papers carries five annotations in that shape. They pass today — and on the day one of them stops passing, it would print the word FAIL and be scored a pass, which is precisely the failure that motivated self-verifying memory in the first place. It matches the bare word only, and it is documented as deprecated at the point of use.

**`templates/test-verify-memory.md` and its fixtures are updated in the same release, and that is the finding worth keeping.** They are this repo's shipped behavioral test for this exact sub-step, and the first draft left them asserting the old dispositions: `echo FAIL` scored PASS, `echo ERROR && exit 1` scored FAIL, and one fixture modelled the `A && B || C` guard shape the same step forbids. An adopter running the shipped test against the shipped runner would have been invited to "fix" the runner. The cross-step contract in `CLAUDE.md` names this precisely — after editing step N, re-read what consumes its output — and it was not followed.

## v1.21.0 (2026-08-11)

`scripts/install-global-skills.sh` refuses to install when the bytes it would copy into `~/.claude/skills/` are not the bytes the highest release tag reachable from HEAD holds; `templates/release.md` Step 7 now says when the refresh is safe, and Step 1's tag selector answers the same question the guard does instead of contradicting it. Closes #33 and #41.

**Adopter action: if you use the script, refresh your global skills after the release tag is pushed and verified, not before.** `--force` installs from the working tree when you mean to run a draft knowingly.

### Versioning rationale

**MINOR — decided 2026-08-11, with the case for MAJOR left on the record because the bump is genuinely arguable and `templates/release.md` rule 1 says an existing consumer needing to act outranks everything below it.**

For MAJOR: an invocation that succeeded before — running the installer mid-session, from a tree that is ahead of the last tag — now exits 2. Anyone with that in a script or a habit has to add `--force` or reorder their release.

For MINOR: the behaviour that changed is a *refusal to perform an unsafe action*, not a change to an interface. The install still installs from a released tree with the same flags and the same output; the adopter-facing changes here are additive — a new Step 7 sub-step in `templates/release.md` (which renumbers the three below it) and a sentence in `docs/GUIDE.md`; and the reordering the guard forces is one that same step now states. v1.18.0 shipped `update-drift` as MINOR with "Adopter action: install it", and v1.20.0 shipped a changed table shape as MINOR with a two-part adopter action, so "adopter action exists" has not by itself meant MAJOR here.

**Decided on precedent, not on re-deriving the rule** — which is what Step 2 prescribes when the two disagree. v1.20.0 shipped MINOR carrying a two-part adopter action, one part of which was *reorder your existing rows to match* a changed table shape: a required structural edit to an artifact adopters already held. That is more disruptive than anything here, and it set the line. The affected population is also narrower than the MAJOR case implies: the script binds to this repo (`cd "$(dirname "$SELF")/.."`, then refuses if the result is not this tree), `scripts/` is not in `CLAUDE.md`'s list of normative surfaces, and `templates/update-drift.md`'s own worked example records a downstream repo declining to adopt it as "belongs upstream, where the globals live". The discrepancy with rule 1 is flagged here rather than buried, per Step 2's last line.

### The defect

The script copies from the **working tree** into `~/.claude/skills/`, where the copy shadows a project-local skill of the same name. Its header promised the install was derived from the tracked source, which was true of the *path* and said nothing about the *content*. On 2026-08-08 a global `curate` carried an uncommitted draft for ~42 minutes, and v1.17.0's release notes record that draft's rule as attempted and reverted — so during that window the skill sessions loaded instructed the opposite of the shipped one. `--check` reported agreement throughout, because it compares the install against the same working tree.

v1.20.0 got this right by discipline: the refresh ran after the tag was pushed, and `git diff v1.20.0 -- .claude/skills/` was empty first. The script contained no `git` invocation at all, so it checked neither fact.

### The guard

- **The release** is `git tag --sort=-v:refname --merged HEAD --list 'v[0-9]*'` with hyphenated names skipped. The sort order is the one `templates/release.md` Step 1 uses, and **Step 1 now carries the same three filters** — see the #41 entry below; until that landed, the guard and the release procedure answered the same question differently. What Step 1 does establish is the prohibition the guard follows: **not** `git describe --abbrev=0`, because it returns the *nearest* tag: after a hotfix tagged `v1.0.1` merges in behind `v1.1.0` it answers `v1.0.1`, and the guard would then measure a correct tree against a superseded release. The hyphen filter drops prereleases and hyphenated scratch tags such as `v2-spike` (a non-numeric one like `wip` is dropped by the glob); it also drops hyphenated CalVer (`v2026-08-11`), which a project tagging that way would have to widen.
- **The comparison is on git's object ids**: `git rev-parse <tag>:<path>` against `git hash-object --path=<path>`, per source. Two predicates were tried and refuted first, each answering a question adjacent to the one the install poses — the fixture README records both, and each of their five demonstrated failure modes is now a seeded case. What the shipped comparison proves is that the worktree *cleans to* the released blob, which is weaker than byte equality: a lossy `clean` filter such as `ident` satisfies it with arbitrary injected text, so a path carrying one is refused rather than compared (P16).
- Scoped to the three files the install copies. Widening it to `.claude/skills/` refuses whenever a project-local skill is mid-edit, which is most of a working session, and a guard that gets `--force`d as a matter of routine has stopped being one.
- Nothing is written to the destination on a refusal, but the **verify pass and the estate scan still run** — neither writes to the destination or the estate, and a #33 guard that suppressed the #36/#37 scan would be a poor trade. On that path the verify loop also compares the *installed* copy against the release, which is the only check that can see #33 having already happened: install and source both carry the draft, so comparing them to each other reports nothing.
- Undeterminable states refuse rather than pass: no `git` on `PATH`, a directory that is not a work-tree *root* (a checkout nested in an unrelated repo answers `--is-inside-work-tree` with "true"), no release tag, and a source that cannot be read.
- `--check` warns instead of refusing and keeps its exit code. It answers whether the install matches the tracked source, which is a separate question, and it is run mid-session.
- **Two limits worth stating.** It compares against a *local* tag, so a tag that was never pushed still passes — which is why the release procedure puts the refresh after a verified push. And it says nothing about whether the released content is correct; what it rules out is shipping bytes no release contains.

### New fixture — `tests/fixtures/installer-release-guard/`

Seventeen positives and fifteen negatives, each building a throwaway git repo in a known state. Thirty-two ablation rows are recorded in its README, each measured against the shipped code by disabling an arm and re-running the whole fixture — three of them were wrong at some point, in three different ways, and the README names all three. Three of the negatives assert the state they seeded before trusting the result; two positives assert that their seeded injection survives the clean filter, and a third asserts both halves of its own state; two of those assertions have fired on bad seeds.

### `templates/release.md` Step 1 — the same three filters (closes #41)

The guard picks a release tag with `--merged HEAD --list 'v[0-9]*'` and prereleases dropped. Step 1 of the release procedure — the step that establishes the baseline every diff, every bump classification and every changelog entry is computed against — picked one with `git tag --sort=-v:refname | head -1`. So one change added a guard refusing three tag states while leaving this repo's own procedure selecting them. Both close in v1.21.0, so no published release carried the divergence — but it sat in the working tree for a release cycle. Measured, on seeded repos:

| repo state | `\| head -1` answers | hardened selector answers |
|---|---|---|
| a `v1.1.0-rc1` prerelease exists | `v1.1.0-rc1` | `v1.0.0` |
| a `wip` scratch tag exists | `wip` | `v1.0.0` |
| `v2.0.0` on an unmerged branch | `v2.0.0` | `v1.0.0` |

Each wrong answer mis-scopes the release rather than failing: a baseline of `wip` produces a diff, a plausible bump and a changelog entry, all of them wrong, with nothing anywhere that reads as an error.

**Two decisions, since this is a normative template and not the installer.**

- **An empty answer has two causes and they take opposite fixes**, so Step 1 names both. A **shallow clone** may reach no tag, because `--merged HEAD` walks the history a `--depth` clone truncated; `git fetch --tags` adds refs but not the history that reaches them, so the fix is `git fetch --unshallow`. Not an absolute — `--depth 1 --branch <tag>` resolves fine, and a shallow clone whose HEAD carries a CalVer tag is fixed by widening after all — which is why Step 1 says to unshallow and *re-check* rather than treating `true` as a verdict. Separately, a **scheme these filters do not match** — hyphenated CalVer (`v2026-08-11`), which the prerelease filter drops — is fixed by widening. Either way the instruction is *stop*: an empty answer is indistinguishable from a first release, and the paragraph below it would otherwise have you cut `v0.1.0` over a project with a hundred releases behind it. Dotted CalVer (`v2026.08.11`) was never affected.
- **`--merged HEAD` is right for a changelog baseline**, not only for a release-state guard, and for a plainer reason: the baseline must be the release this one supersedes. A tag on an unmerged branch supersedes nothing on HEAD, and diffing against it is wrong in both directions — it reports changes that are not in this release and hides changes that are.

**The filter is `sed '/-/d'`, not `grep -v -- '-'`.** The first draft used grep and was measured to fail outright on **ugrep**, which is a real `grep` on a real machine — this maintainer's: it parses `-- '-'` as "no pattern specified", exits non-zero, and prints nothing, so the selector silently yields an empty baseline and the reader is sent down the first-release path. Caught by running the command rather than reading it, in the same session that wrote the paragraph telling adopters to run it. This is the same "hostile environment, not the clean one" rule the project file already carries, arriving from an angle it did not name: not a hostile *repo*, a hostile `PATH`.

The guard and Step 1 are deliberately **not** shared code — one runs under `set -u` in a script, the other is a command a human reads and checks — so `tests/lint/run.sh` cannot see them drift apart. That is a known limit, not an oversight; what keeps them together is that each now states the other's existence at its own site.

**The review battery refuted the first draft of this section, on the defect the same commit had just fixed one file over.** Step 1 gained `--merged HEAD` and with it the shallow-clone failure — and the "read the output" paragraph diagnosed the resulting empty answer as *probably CalVer, widen the filter*, which is measurably useless: dropping any or all of the filters still returns nothing, so an adopter widens, gets nothing, and lands on the first-release paragraph. So the maintainer-only script carried the correct diagnosis while the normative, adopter-facing half carried the wrong one, in a change whose stated purpose was making those two agree. The bullet above is the corrected version. Three further findings from the same battery: the fixture README still carried the "#41 filed, not done" paragraph — the third copy of a sentence whose other two were updated here, and the one file `CLAUDE.md` tells you to read before changing the comparison; the framing sentence claimed all four table rows were "states this framework's own installer refuses" when two of them (N11, N14) are states it must get right *without* refusing; and `before-refactor`, one of two scratch-tag examples, does not actually win the sort, because `b` sorts below `v`. The corrected row says so.

**A second pass then refuted the correction**, which is why this paragraph is worth reading rather than skipping. The rewritten diagnosis opened "An empty answer *while `git tag` lists tags*" — and a plain `git clone --depth 1` fetches **no tag refs at all**, so the commonest shallow state was excluded by the very sentence written to catch it, and the reader still fell through to the first-release paragraph. The gate is gone: the ordering is now explicit that a bare `git tag` is not the test, and the first-release paragraph itself requires `--is-shallow-repository` to answer `false`. The same pass found the scratch-tag example under the glob row was dropped by the *hyphen* filter, not the glob (`v2-spike` matches `v[0-9]*`) — so the template contradicted the changelog one section away; the row now uses `wip` and `zz-backup`, both measured. It also found **two ablation rows that had gone stale inside this same change**: tightening the P5/P10 needles made them sensitive to the shallow branch (that row is now P4, P5, P10) and adding P18 gave `--merged HEAD` a second pinning case (now N14, P18). New rows were measured; existing rows were not re-measured after the fixture grew under them — which is the table's own stated discipline, missed.

Also from the battery, in the guard itself: the shallow fallback used `--git-dir`, which in a **linked worktree** points at `.git/worktrees/<name>/`, where the `shallow` marker does not live — so on pre-2.15 git in a worktree the branch would have printed the tagless remedy, i.e. this entry's own defect, one layer down. Now `--git-common-dir` (git ≥ 2.5, older than the 2.15 gap it covers). The fallback arm is inert on modern git by construction and cannot be pinned by a case there; what shows it works is running the whole fixture with the *first* arm disabled, which passes. That is recorded as an ablation row rather than left to look like coverage.

### Found by running it, not by reading it

Four review batteries refuted this change before it was committed, and four further passes — the session that picked it up to release it — each refuted it again. Recording the defects because the pattern is the argument, not the list.

- **The refusal's own remedy was wrong for half the states it named.** `A shallow or tagless clone needs \`git fetch --tags\`` fixes only the tagless half: a shallow clone fetches every tag **ref** and reaches none of them, because `--merged HEAD` walks the history the truncation removed. Measured on this repo — 37 tags present after the advised command, selector still empty, guard still refusing. Someone following printed advice that visibly fails reaches for `--force` next, which is the single outcome the line exists to prevent. Now branches on `--is-shallow-repository` and advises `git fetch --unshallow` for that half. **The guard's predicate had been rebuilt three times and was, by then, right; this defect sat one step further out — in the consumer-facing recovery instruction, which is the part no battery ever ran.** Found by running the installer from a real `git clone --depth 1`, not by reading the line.
- **The predicate was wrong twice.** A name-based comparison (`git diff` + `ls-files`) misses `--assume-unchanged`, `--skip-worktree`, untracked paths, and both symlink shapes. A raw-blob comparison (`git show` + `cmp`) then refused *pristine* release checkouts under any checkout filter — `core.autocrlf=true` is the Git-for-Windows default, and this framework is explicitly tool-agnostic. A Windows maintainer would have passed `--force` from day one, which is the failure mode the design section above names.
- **The tag selector was the one this repo's own release procedure forbids**, in the same change that adds a step to that procedure.
- **The guard failed open on any git error**, found independently by all four lenses of the first battery: unreleased bytes installed, exit 0, `OK — global skills match the tracked source`. Later, the accumulation of findings was funnelled through `printf | grep .`, which made a *missing `grep`* empty them and let the install proceed — the same defect class, re-created two rounds after it was fixed. The findings are now accumulated with builtins.
- **A refusal cancelled the read-only checks**; **`--check`'s own advice contradicted the guard** ("run without `--check` to refresh" is the install the guard refuses); and the **path list under a refusal printed nothing**, because `printf '%s'` leaves the last line unterminated so `read` never runs the loop body on it. The headline still read correctly and three cases passed while naming no file.
- **Two arms measured inert** at different times: `--is-inside-work-tree`, replaced with a work-tree-*root* comparison, and `command -v git`, kept for its message and given the case that isolates it.
- **A fixture needle could never fail**: P9 matched `symlink`, which appears in its own case id inside the destination path every refusal prints. **A fixture case could not distinguish what it claimed**: N11's first topology answered `v1.1.0` under both tag selectors. **An ablation row was published without being measured**, with an explanation that is false.
- **The fixture wrote to this repository.** `git -C` loses to an inherited `GIT_DIR`/`GIT_WORK_TREE`, which a git hook or `git rebase --exec` exports — so a throwaway repo's commits, `tag` and `tag -d` landed on `master` during review. Fully restored (all 37 local tags verified byte-identical to origin, `master` back at `da767c4`); the harness now unsets those variables and pins `core.hooksPath`.

### Pre-existing bugs, found by the new cases

- **A CRLF checkout read as "no frontmatter".** The check compared `head -1` against `---`, and `head -1` yields `---\r`. Lint rules 4 and 6 strip `\r` deliberately; this script never did. Now a builtin-only `first_line` helper (N10).
- **`cp` and `mkdir` statuses were discarded**, so an unwritable destination printed `installed` for every skill while nothing was copied — the verify pass contradicted it four lines later (N12, N13).
- **`$HOME` unset aborted with bash's own message and exit 1**, this script's "N issue(s) found" code. Now an explicit error and exit 2.

### Also

- **`templates/release.md` and `.claude/skills/release/SKILL.md`** — Step 7 gains "refresh any copy installed outside the repo", after the tag-is-live check. The ordering the guard enforces was in no procedure in this repo (`git grep` over the docs finds one prior statement, and it states the *wrong* ordering — fixed below); v1.20.0 got it right from memory. The Step 7 warning about an unpushed tag named "steps 2–4" and was left stale by the insertion — three lenses flagged it, and it matters because the newly inserted step is the one whose failure mode *is* #33: refreshing after a tag that never pushed installs content no published release contains, and a local tag satisfies the guard.
- **`CLAUDE.md`** — the skill-installation row states the refusal and the `--force` escape; the `tests/fixtures/` subtree and Key Paths entry cover the new fixture; "How to Work Here" lists all four self-test commands, which were nowhere written down together; and the self-certification Hard Constraint is re-counted against `memory/gotcha-log.md`, which had moved ahead of it, with `scripts/install-global-skills.sh` added to the list of shipping procedural artifacts it governs.
- **`docs/GUIDE.md`** — the "global installs must be derived from a tracked source" rule now says *released*, with the reason.
- **The fixture README cited a case `P13` that has never existed** — the ids run P1–P12, P14–P18. A dangling id in the one table whose stated rule is "re-run a row before citing it" is that table's own failure mode, so it is corrected in place with a note rather than silently. The protection it meant to name is P14.
- **`docs/work-items/model-fit.md`** — an open checklist item said to refresh the global install "after committing", which the guard now refuses. Corrected.

## v1.20.0 (2026-08-10)

MINOR — closes #40, #23, #38, #36 and #37. **The Layer 3 memory index is not auto-loaded, and had not been since ADR-001.** The claim survived across the guide, the templates, the four-page visual walkthrough, the public README and the adopt prompt — 16 files corrected here; an exact site count was published twice with two different numbers before being dropped in favour of one that can be checked. **Adopter action: add the "Picking up where the last session left off" row to your project file** — without it your memory index is never read, and nothing tells you.

### The defect

ADR-001 moved Layer 3 from the tool's own memory path into the repo. At the old path it genuinely was auto-loaded; at the new one it is reached by a task-triggered pointer, like any other in-repo file. The files moved and the word did not. So the framework's own Layer 3 sat on the wrong side of the auto-loading cliff — the concept this framework named — for months.

**ADR-001 already stated the correct position** (in its consequences: "referenced there, not auto-loaded by path convention"). Nothing propagated it. That makes this unpropagated language rather than a design disagreement, and it is why the fix is a sweep rather than a decision.

Two things kept it alive. `docs/GUIDE.md` hedged it as "auto-loaded **if your tool supports it**", which reads as a statement about *tools* when the real variable is *which path the file sits at*. And `audit-context` Step 1 opened with "Check the auto-loaded files (project file and memory index)" — the audit that would have caught it re-asserted the premise it needed to question, on every run.

**Claude Code makes it maximally easy to get wrong**: it auto-loads `~/.claude/projects/<slug>/memory/MEMORY.md`, so a project has *two* files named `MEMORY.md` and only the untracked user-level one arrives on its own. Verifiable from inside a session — the in-repo file is absent from context until something reads it.

### Measured cost, from one adopter

1. **A session handoff never arrived.** The index's `Open Handoff` section reached the next session only when pasted by hand — and once was pasted with a superseded version alongside the current one, which is precisely the drift a committed handoff exists to prevent.
2. **A context-budget metric ran ~50% high.** Five audits tracked `wc -c` over project file *plus* memory index as "auto-loaded context": ~71k tracked against ~47.7k actually loaded. The whole trajectory measures a file that never arrives, so curation went into ~23k that cost nothing while the loaded surface went unmeasured.

### Templates

- **`templates/project-file.md`** — new **"Starting any session (project state)"** row, placed first. This is the load-bearing half and the only part that is new behaviour rather than corrected prose: the framework routes by task, and *starting a session* was a task with no row, so nothing pointed at the memory index at the moment it mattered. Tool-agnostic. The existing drift row is renamed "Starting any session (framework drift)" so the two triggers stay distinct.
- **`templates/memory-index.md`** — the header comment said "Loaded every session." It now says the opposite and names the consequence: an index that was never loaded is indistinguishable from one with nothing to say.
- **`templates/audit-context.md` Step 1** (and the tracked skill) — establish what the tool *actually* auto-loads before measuring, record what was measured, and state plainly whether an earlier budget series measured the same set. A trajectory across a change in what is being measured is not a trajectory.
- **`templates/README.md`** — the `memory-index.md` description.

### Docs

- **`docs/GUIDE.md`** — Layer 3's **Auto-loaded** line now reads "No", with the reason and the same-basename trap; the navigation diagram, the session-start paragraph, the compression guidance, and both ~200-line truncation notes corrected. The truncation limit applies to the *user-level* file, not the in-repo index — the reason to keep the index lean is context economics, not truncation, and the two had been conflated.
- **`docs/guide/01-the-cliff.md`** — "Two places, both auto-loaded" was false for the second; the pointer *to* the index is exactly why it must exist.
- **`docs/guide/02-the-layers.md`** — prose and the mermaid node (`auto-loaded` → `pointer-loaded`).
- **`docs/decisions/ADR-001-...`** — the **same-basename collision** is now named as a consequence of the decision, with the cost above. Worth its own bullet: the adopter who found this wrote the correction and still got it wrong on the first pass, omitting the auto-memory file from an enumeration of what loads.
- **`docs/EXAMPLE.md`** — the same header comment.

### Found by the review battery, after the first draft

The first draft of this change was committed and then refuted by a three-lens battery on six counts. Recording them because the pattern is the point — and because two of them are this repo's own freshly-filed issues, committed against.

- **The sweep was incomplete.** Six live sites still asserted it, including `README.md`'s layer table under a literal "Auto-loaded?" column, the `docs/guide/01-the-cliff.md` diagram that is the framework's own picture of its own concept, and — worst — `docs/task-triggered-pointers.md`, which told adopters that the memory index *does not need a trigger* because it is always present. A release whose load-bearing fix is adding that trigger shipped a public page instructing readers to skip it. All swept.
- **Four shipped absolutes were false, which is [#39](https://github.com/ducroq/agent-ready-projects/issues/39) committed one day after filing it.** "This row is the only thing that loads it" and "Layer 1 is the only auto-loaded layer" are refuted by Claude Code's documented `@path` import syntax, by `.claude/rules/`, and by session hooks — one of which this framework's own guide recommends. A `@memory/MEMORY.md` import is a one-line, tool-native way to make the in-repo index genuinely auto-loaded, so the first draft steered adopters away from a better fix than the one it was shipping. Absolutes removed, and the import is now named in `templates/memory-index.md` as the deliberate context-budget trade it is.
- **The new row loaded all of Layer 3 on every session.** It read "the index, plus whatever it routes you to" — which instructs the agent to follow the on-demand topic pointers at session start, collapsing Layer 3 into always-loaded context and restoring the very cost this entry cites as the bug. It now says *the index itself, not the topic files it lists*.
- **The two rows collided as triggers.** Both began "Starting any session", disambiguated by a parenthetical *category* — the exact weak-trigger shape `docs/task-triggered-pointers.md` condemns. Renamed to a situation.
- **`adopt.md` was untouched, so new adoptions reproduced the defect.** The "Adopter action" reached existing adopters only. STEP 4 now creates the index and the row that reaches it in the same breath.
- **`audit-context` Step 5 could not see the orphan this change makes possible.** Every check in that step walks *outward from* the memory index, so a missing pointer *to* the index takes all of Layer 3 out of reach and disables the checks that would report it. Step 5 now verifies the inbound pointer first.

Also from the battery: the ~200-line truncation figure is **unsourced anywhere in this repo** and was being restated with more confidence than before, in two directions at once. It is now bounded to Claude Code's documented cap on the *user-level* file — 200 lines or 25KB, whichever comes first — with the in-repo case explicitly marked unmeasured rather than asserted either way. `templates/memory-index.md` had retained the contradicting truncation claim that the same commit removed from the guide; dropped. The `pointer-loaded` coinage appeared once, was defined nowhere, and is gone. ADR-001's amendment is now date-stamped and no longer carries an adopter's unreproducible figures into a permanent record — they stay in #40, where they are attributable.

And this repo now applies its own adopter action: `CLAUDE.md`'s "Picking up project state" row was the category-shaped version the release argues against.

### Still open

The adoption gate — `templates/README.md` "If your tool has auto-memory (currently Claude Code), also grab `memory-index.md`", and `docs/GUIDE.md`'s "tools without auto-memory fold Layer 3 into the project file" — was **derived from** the auto-loading premise this release removes. Since Layer 3 is now pointer-loaded, the derivation no longer holds and Layer 3 may be available to every tool. That is a design decision, not a correction, so it is left as it stands and noted on #40 rather than settled here.

### Promotion erases the rate (closes #38)

**`templates/gotcha-log.md`** — the Promoted table gains an **Occurrences** column, and grows from three columns to four. Two mechanisms in this framework compress the gotcha record, both correctly: v1.17.0's 2-3 line cap folds each recurrence into one lesson, and promotion folds N recurrences into one row. Together they destroy the rate — after promotion, "five times this week" and "twice since April" render identically, and the rate is the number that changes behaviour. This repo's own self-certification constraint is argued by its count, which survived only because someone wrote it into prose by hand; the table it points at could not express it.

**`templates/curate.md` Step 2** — the column would otherwise sit unmaintained. Step 2 now checks promoted patterns against the session and increments the count **every** session, not only when something is newly promoted: a pattern already in the table is the one most likely to have bitten again, and the one nothing else reports. Recurrences are dated in the cell rather than only bumping a number, so a rate is readable and not just a total. A promoted pattern that keeps recurring means the promotion did not take — the step says to state that plainly, because a quietly growing number persuades nobody.

**Adopter action, two parts.** The Promoted table's other three columns changed too — `| Entry | Promoted to | Date |` becomes `| Date | Gotcha | Occurrences | Promoted to |`, so `Entry` is renamed and every column moves. Appending a fourth column to an existing table produces a fourth distinct shape; pasting the new header over existing rows files descriptions under `Date` and renders cleanly with no error anywhere. Reorder your existing rows to match. Separately, **re-run `scripts/install-global-skills.sh`** — `curate` is user-global, so without a reinstall you never receive the new Step 2 and the column stays empty. (A first draft of this entry described the change as "gains a column", inheriting a misquote of the old header from issue #38 itself.)

**Not done, and deliberately.** #38 also proposed a self-correction tally in Step 1 and a "corrections this session" line in the Step 6 report. Only the report line shipped, folded into the Gotchas bullet. The Step 1 tally is a second counter over the same events as the Occurrences column and would need a reconciliation rule before it earns its place; noted on the issue rather than settled here.

Dogfooded in this repo's own log before being written into the template.

### Installer: an unreadable subtree reported a clean estate (closes #36, #37)

**`scripts/install-global-skills.sh`** — two pre-existing defects in the estate scan, both found by the shell-correctness lens of an earlier battery and filed rather than fixed there.

- **#36** — `find`'s stderr was discarded, so a subtree the scanner cannot read contributed zero hits and zero warnings. `scanned 0 candidate path(s)` printed identically for "nothing there" and "couldn't look", and the script exited 0 with `OK`. That is the **fifth** instance of this defect class in this one script — a non-existent scan root and a symlinked one (v1.15.0), a relative one (#24), an empty argument (v1.19.0, introduced by the #24 fix itself), and now an unreadable subtree. A first draft of this entry said "third" by dropping two of them, in the same release whose other half argues that occurrence counts are the load-bearing number. Errors are now captured, deduplicated (`find` runs once per global skill, so one unreadable directory produced one error per skill), classified, and counted on the evidence line: `scanned N candidate path(s), M unreadable, K skipped (loops/transient)`.

  **The first fix for this was worse than the defect, on three counts, and the battery caught all three.** Treating any `find` stderr as lost coverage is wrong: under `-L` a filesystem loop is *handled* — find skips the cycle, keeps walking, and misses nothing — so an ordinary virtualenv `bin/local -> .` or a `docs/current -> ..` turned the check permanently red on any real estate, and a permanently-red check gets ignored. A path vanishing mid-walk (a build, a `git clean`, an `npm install` in a scanned repo) did the same, uncapped, thousands of lines at a time. And when `mktemp` failed — full disk, read-only `TMPDIR`, restricted container — `2>>""` failed to open, **find never executed**, and the script printed `scanned 0` and `OK` and exited 0: #36 again with a wider blast radius, losing every real hit instead of one subtree. Only a permission error now counts as lost coverage; loops and transient disappearances are counted separately as skipped; an unrecognized message counts as lost, because assuming otherwise is how a silent miss gets built; `mktemp` failure is an explicit loud failure; the listing is capped at ten with the true total still reported; and `LC_ALL=C` keeps the matched strings stable. The maintainer's own `~/repos` happens to be loop-free, which is exactly the sample-of-one the hostile-repo rule warns about.
- **#37** — the scan read `find`'s newline-delimited output, so a path containing a newline was consumed as two records: two bogus `FAIL` lines for one real file, an inflated `scanned` count, and — because neither fragment stripped the path suffix — the "this repo is the source" self-exclusion could never match, so the framework's own tracked skills could be reported as inert with the user told to delete them. Now `-print0` / `read -r -d ''`.

Both reproduced exactly as filed before and after the fix; the self-exclusion and a normal estate scan were re-checked as regressions.

### Maintainer infrastructure — nothing detects template↔install drift (closes #23)

Maintainer infrastructure — `tests/` and `CLAUDE.md`. This rides the release rather than warranting one; no `templates/`, `adopt.md`, `README.md` or `docs/` surface changed. **Adopters need do nothing.** (`.claude/skills/audit-context/SKILL.md` does change, by nine arrow glyphs — see below.)

A skill lives in two files — `templates/<name>.md` and `.claude/skills/<name>/SKILL.md` — and until now nothing compared them. Lint rule 3 checks a template *carries* installable frontmatter; rule 4 checks an install *can register*; `install-global-skills.sh --check` compares the global install to the tracked one, so both read as current while diverging from the template. The drift this allows had landed twice, both times found by hand: two `description:` fields in v1.15.0, and v1.17.0's gotcha-length rule written to `templates/curate.md` and not to its install. `description:` is what the model reads to decide whether to auto-invoke a skill, so this is behavioural, not cosmetic.

New **`tests/lint/skill-sync.sh`**, wired as lint rule 6, with **`tests/fixtures/skill-template-sync/`** — 17 seeded positives and 7 negatives, every guard confirmed load-bearing by ablation. Also adds the missing rule-4 row to `tests/lint/README.md`, whose table had documented four rules against `run.sh`'s five since rule 4 was introduced.

It compares the body, and the **whole** frontmatter block rather than a list of known keys — an unanticipated field (`allowed-tools:`, `model:`) or a duplicated one drifts silently under a key list. Body normalization is confined to structure: strip the H1 and the `SAVE AS` comment from the template, the frontmatter from the install, and leading/trailing blank lines from both. Nothing rewrites a character inside a body line, so a `→` that becomes `->` still reports. The frontmatter comparison additionally strips leading indentation and trailing whitespace, because the template quotes its frontmatter five spaces deep inside a comment — one consequence, stated rather than discovered later, is that a multi-line block scalar whose continuation indent differs between the two files reads as equal.

**Three things came out of measuring rather than assuming:**

- **The check's starting state was already green.** All five pairs matched under the normalization #23 proposed — which is precisely what a broken check looks like, so the fixture is the evidence, not the clean run.
- **One of the three proposed normalizations was rejected outright.** #23 proposed normalizing the frontmatter/`SAVE AS` split, the `→`/`->` arrows, and blank-line runs. The first is the entire basis of the check; the third reduced to trimming leading and trailing blanks. The arrow was the wrong fix: the sole divergence in the whole repo was nine lines of `→` vs `->` in `audit-context`, and normalizing it away would have hidden a genuine instance of exactly what the check exists to detect. The install was regenerated from its template instead.
- **The obvious implementation is permanently red.** Stripping *every* HTML comment from the template body — the natural reading of "strip the `SAVE AS` block" — breaks `audit-context` and `curate`, because both quote `<!-- verify: -->` in running prose. Ablation confirmed it against the fixture and the repo. The strip has to select the block containing `SAVE AS`.

**A body comparison alone would have missed the founding defect.** The two v1.15.0 `description:` fields sit in the stripped regions on *both* sides — inside the template's `SAVE AS` comment and inside the install's frontmatter — so no body diff can see them. The frontmatter block is compared separately for that reason.

**The fixture's first run never executed the check** — the script was not executable and the harness used `2>/dev/null || true`. The positives failed loudly; **every negative passed vacuously**, since "expect no violation" is satisfied byte-for-byte by a checker that did nothing. Written negatives-first, the harness would have reported green while testing nothing.

**And the same hole was then left open in the path that ships.** A four-lens battery found it independently in all four lenses: the fixture asserted the checker had run, but `run.sh` rule 6 consumed it through `done < <(bash …)`, which discards the exit status. With the checker deleted, renamed, or exiting 3, `run.sh` printed **"All lint checks passed"** and exited 0 — while `CLAUDE.md` tells every session to run it before committing. That is this repo's own cross-step contract rule, violated one file away from the comment describing the trap. Rule 6 now fails when the checker exits above 1 or omits its coverage line, and `skill-sync.sh` exits 2 rather than 0 when a directory argument does not exist.

The battery also refuted three claims drafted for this entry (that the comparison was byte-for-byte with no normalization at all — `trim_blank` is normalization and is load-bearing; that trailing-whitespace stripping had been proposed — it had not; and that all five original negatives were load-bearing — only one was independently so), and found four defects in the checker itself: a `-->` in the `SAVE AS` prose desynchronized both awk state machines into four misdiagnosed violations, an unterminated `<!--` in body prose silently truncated the comparison so every later edit became invisible, CRLF made the rule permanently red where rule 4 strips `\r` deliberately, and the reported "first differing line" was usually the blank separator. All fixed, each with a fixture case.

**A second battery, run against the rewrite, refuted it again on six counts** — including a hole in the fix for the first battery's top finding. Rule 6's guard asserted the coverage *line* had appeared but never that the *number* was above zero, so an empty or renamed `.claude/skills/` reported "0 pair(s) compared" and passed green; the `-->` fix was half-done, because the body extractor still leaked the truncated comment's frontmatter as a second, bogus violation; a stray `<!--` in template prose *above* the block was a new false positive introduced by the rewrite; the diff line count double-counted every modified line, reporting nine drifted lines as eighteen; three guards described as ablation-confirmed had no fixture case at all; and a deleted reference install still passed as a coverage note. The last is now an explicit allowlist — one named template may be install-less, anything else is a violation — matching the "explicit allowlists, not blanket skips" rule the rest of this lint follows. The fixture gained a `HIT1` expectation asserting a seeded defect produces *exactly one* violation, which is what made the leaked-frontmatter defect visible at all.

`test-verify-memory` is a skill template with no reference install, so nothing compares it; rule 6 reports that as a coverage note rather than a failure, and whether it should have an install is a separate question. `CLAUDE.md` gains a "Editing a skill" row: edit both files, because an edit to one is drift until the other matches.

## v1.19.0 (2026-08-10)

MINOR — issue sweep of the oldest open items, closing #24–#29 (#23, older still, is triaged and deliberately left open — see *Not done*). One new deterministic step in `review-changes`, one new verification disposition in `curate`, and three corrections. **Adopter action: reinstall the global skills** (`scripts/install-global-skills.sh`) if you use `curate`; re-copy `review-changes` into your repo. Nothing breaks if you don't.

### Templates

- **`templates/review-changes.md` — new Step 1.5, structural pre-check** (closes #28). Every lens in this skill reads *content*; none asked whether the file is still valid markdown after the edit. A `|` added inside a table cell — a regex like `'recordfail|initrdfail'`, an `||` in a shell fragment — pushes the rest of the row into phantom columns. It reads fine as prose in the diff and is wrong only when rendered, so both a human reviewer and the adversarial lens pass it. Deterministic, runs at **every tier and every magnitude**, and it is a step rather than a lens because no model is needed to evaluate it.

  **The first draft of this check was wrong and the review battery refuted it by measurement.** It compared each row's pipe count against the row that opened the block and declared every mismatch corruption. GFM does not agree: a row with *fewer* cells than the header is spec-legal — empty cells are inserted, and the `| **PART ONE** |` divider row inside a wide table is idiomatic — while only a row with *more* cells loses anything, because the excess is discarded. **39% of the first draft's hits were that legal-and-short class.** A further 15% were files with no delimiter row at all (a scikit-learn tree dump is not a table). The claim "every hit is real" was mine, it was asserted without measuring the direction, and it was false.

  Rebuilt to anchor on the **delimiter row** and report only the lossy direction. Re-measured over the same scope (`find ~/repos -name '*.md'`, excluding `.git` and `node_modules`, 4381 files): **168 hits → 68**, every removed hit in a class the lenses had identified as legal, and each surviving class spot-checked as genuine data loss. Ten fixture cases now pin the behaviour — including 4-backtick fences, `~~~`-versus-``` fences, indented code blocks, tables without leading pipes, and the header/delimiter mismatch that the first draft could not see at all. The first real defect it found sat in *this repo's* own gitignored `memory/`: a `<!-- verify: … || echo FAIL -->` comment inside a table cell, where the unescaped `||` adds two cells and truncates the row. Fixed during the same session's `/curate` — the check found it, and the fix is the `\|` escape the step prescribes.

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

- **#23** (nothing detects `templates/*.md` ↔ `.claude/skills/*/SKILL.md` drift) stays open, per its own gate in `memory/hypothesis-log.md` H-002. <!-- Correction, v1.20.0: this reading was wrong. The gate is "the next template edit lands in only one of the two files", and it had already fired twice — v1.15.0 and v1.17.0 — both before this release. What that gate asks is whether the two files drift when nobody is watching, and the answer was already recorded in H-002; this entry re-derived it from the issue text, where the firings are not recorded. Built in v1.20.0. -->
   This release edited both files for every template it touched, but *deliberately*, having read the issue first — that is not a sample of whether they stay in sync unattended, and closing on it would be scoring a test whose answer was known in advance. For whoever builds it: the normalization is to strip the template's H1 **and its `<!-- SAVE AS: … -->` block** (14–27 lines, holding the frontmatter that `SKILL.md` carries as real YAML), after which four of five skills are byte-identical and `audit-context` differs only in `→` versus `->`.

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
