# Why `review-changes` says what it says

Superseded drafts and the measurements that refuted them, moved out of `templates/review-changes.md` so that
adopters do not pay for this repo's litigation on every invocation. **The decision lives in the
skill; the argument lives here.** Nothing is duplicated between the two — if a claim appears in
both, one of them is wrong.

### Now run git diff --stat "$BASE"...HEAD, git diff --stat and git diff --cached --stat to se…

- **All three terms are needed and the baseline one is the one that is usually non-empty**: on a pushed, unmerged branch the other two are empty, and an earlier version of this step listed only those two — so the tier table, the Unclassified section and the report header were all computed over zero files while the magnitude gate below reported the real number.

### Known blind spots, so a clean result is not read as more than it is: tables inside blockqu…

- **CRLF was one of these until v1.25.1** — `isdelim()` strips spaces and tabs but not `\r`, so on a CRLF checkout tables went unentered and a file whose defect was in a table printed what a clean file prints.

### The prettier emphasis corruption — mechanism and version history

Moved out of the magnitude gate 2026-09-05. The **rule** (never end a bolded phrase with a
`**`-suffixed glob; put the path in a parenthetical) stays in the skill. This is the argument.

- The closing `**` becomes a literal `\*\*` and the phrase loses its bold; with two globs, the
  spaces between them are eaten instead.
- It breaks on **prettier 2 and 3.8.1** and is fixed in **3.9.6**. ⚠️ The 3.8.1 datum came from an
  *adopter*, measuring a version never tested here, after this repo shipped
  `"breaks on prettier 2 and survives prettier 3"` — an absolute in a description, generalised from
  two one-line tests, refuted from outside. That refutation is why the Hard Constraint on absolutes
  ships merged with the negatives rule.
- **Exactly one** later code span on the line masks the corruption; **two** reintroduce it in the
  other form. That asymmetry is why the framework shipped the broken shape for a day while every
  test of it passed.
- Step 1.5's emphasis check (v1.31.0) reports two backticked `**`-abutting tokens inside one bold
  span, which is this shape. ⚠️ The skill read *"Step 1.5 does not catch it"* until **v1.36.1** —
  left standing when the check that refuted it shipped in the same release. That sentence is one of
  the three superseded-beside-its-correction instances v1.36.1 exists to fix.

### Step 5 — the numbers behind "fixing is where the cost is"

Added 2026-09-05; **corrected the same day by an adversarial review that refuted two claims in it.**
The **rules** live in Step 5; this is the measurement they rest on, and its limits.

Source: `memory/review-ledger.tsv`. **Population: 4 real-work rounds** — the rows that carry a
numeric `missed`/`introduced` classification. Synthetic-benchmark rows are excluded as not being
real work.

| what the finding turned out to be | count | share of classified |
|---|---|---|
| a defect the previous round's own **fixes** created | 14 | **50%** |
| a defect earlier review had **missed** | 6 | 21% |
| first sighting, neither | 8 | 29% |

⚠️ **The denominator is the classified subset, not all findings.** Real-work rows carry **43**
findings in total; **15 of them sit in 5 rows whose `missed`/`introduced` columns are `?`** and were
excluded. The ledger header is explicit that `?` means *not guessed*, and the two stopped 2026-09-04
lenses are annotated "a null, not a zero" — so they may not be treated as no-introduced-defects.
Against all 43 counted findings the introduced share is **33%**, not 50%. Both numbers are stated
because the honest one depends on a question the ledger cannot answer. **The direction of the bias
is unknown**: the largest excluded row is round 5 of a 7-round sequence, which is where introduced
defects are *most* likely, so the exclusion is not conservative.

⚠️ **Two errors in the first draft of this section, both found by review, both worth recording:**
1. It claimed **"5 rounds"**. There are **4**. The awk that produced the figure used `NR>1` to skip a
   leading comment line and therefore counted the file's **header row** as data — `$11` held the
   literal string `missed`, which is neither empty nor `?`, so it passed the filter. The sums were
   unaffected (awk coerces the text to 0), so **every number was right and the sample size was
   inflated by one, silently.** An instrument that counts its own header as a specimen.
2. It claimed **"half of all review findings"**. `all` is a descriptive universal, which this repo's
   Hard Constraint forbids unmeasured — and it was reached by dropping 35% of the findings.

⚠️ **Limits.** One repo, one maintainer, prose-heavy, **n=4 rounds**. The `introduced` column was
classified **by the person who wrote the fixes** — an admission against interest, so more likely
under-counted than inflated, but self-classified either way, and unreplicated outside this repo.
**Treat the direction as the finding and the percentage as an estimate.** If your own rounds do not
behave this way, trust your rounds.

The disjoint-lenses claim in Step 5 is a **single** observation: 2026-09-04, one diff, a shell lens
returning 3 findings and an adversarial lens returning 2 blockers, with no overlap. Enough to refuse
the *collapse* of lenses into the author's context; not a measurement of what independence is worth.

### Baseline resolution — provenance moved out of Step 1, 2026-09-05

- `git symbolic-ref` reads `origin/HEAD` **without following it**, so a renamed or deleted upstream
  default yields a ref that looks fine and diffs to nothing; a stale local `main` in a `master` repo
  does the same. **Both were measured.** The `^{commit}` validation exists because an unresolved
  baseline and a clean tree produce identical output, and this step exists because those two were
  once confused — that is #64.
- `origin/HEAD` is set by `git clone` (including `--depth 1`) and by the first `git fetch` on
  git ≥ 2.45 — **measured on 2.53.0, not assumed.** The `develop`-default blind spot noted in the
  step was also measured, not reasoned.

### Step 1.5 table check — the measurement behind "only excess cells"

Reporting *both* directions (short rows as well as long) was measured at a **39% false-positive
rate**. Anchoring on the delimiter row and reporting only the lossy direction took the estate from
**168 hits to 68 across 4,381 files**, with every removed hit in a legal-but-short or
not-a-table-at-all class.

### Step 1.5 CRLF — what the fix was

Of the checks, only the fence check survived CRLF, because it anchors at line start where a trailing
`\r` cannot reach. Fixed by the `sub(/\r$/, "")` rule. `core.autocrlf=true` — which the
Git-for-Windows installer **pre-selects** — is what puts CRLF in the working tree in the first place.
Lone CR remains a blind spot, and the step still says so.

## The baseline fallback, and why it under-reported for eight releases (#149)

`BASE=$(git rev-list --max-parents=0 HEAD | tail -1)` with `"$BASE"...HEAD` diffs
from `merge-base(BASE, HEAD)` — which **is** the root commit — so the root's own
content was excluded while the message announced *"reviewing the whole branch
instead"*. Measured on scratch repos:

```
3 commits, 1 line each:  1 file changed, 2 insertions(+)      (of 3)
1 commit, whole change:  every Step 1 command empty; git show --stat HEAD -> 1 file changed
```

The guard could not catch it, because `$BASE` **did** resolve — to the root. And
the comment above the fallback claimed *"over-reporting is the safe direction for
a review tool"* while the code under it under-reported by 100% in the one-commit
case. That sentence stood in two more places in the same file after the runtime
message was corrected, and a doc-accuracy lens found it there.

**Rejected fix: the empty tree with a two-dot diff.** `git diff $(git hash-object
-t tree /dev/null)..HEAD` genuinely reviews everything, but three-dot **rejects a
tree** (`fatal: Invalid symmetric difference expression`) and the existing
`$BASE^{commit}` guard rejects it too, so it needs a special-cased path at six
call sites. Kept as the structurally correct option; not taken as a hotfix.

**Why the marker is printed rather than only set.** A shell variable does not
survive to the next tool call, and this one degrades toward *permitting* a clean
result — lost, it reads unset and the terminator allows "nothing to review",
which is the defect restored. Scrollback survives what the shell does not.

**`|| :` on the rev-list assignment.** In a repo with no commits `git rev-list`
exits 128 and `tail` exits 0; under `set -eo pipefail` the pipeline's 128 killed
the shell *before* the abort, printing nothing at all. Measured in four modes;
only `-eo pipefail` was broken — the mode Step 1's own preamble reasons about —
and the fixture ran without `-e`, so it certified the ordering it could not test.

## Three states, not two, and the one with no tell (#153)

| state | `$BASE` resolves | fallback fires | reported |
|---|---|---|---|
| baseline unresolvable | no | yes | unresolved-baseline finding |
| root-commit fallback | yes, to root | yes | a finding, via the printed marker |
| **HEAD contained in `$BASE`** | **yes** | **no** | **"nothing to review"** |

The third row was found by running this skill on a branch whose checkout a
concurrent session had moved: every diff term was correctly empty because `HEAD`
**was** `origin/master`. Reviewing by explicit ref range is immune to it.

## The Step 5 statistic, and how it was wrong in the shipped copy

v1.37.0 shipped *"of the findings classified as to origin, half were … 14 of 28,
against 6 misses"* and a changelog line putting the share at 33% "against all 43
counted findings". Measured against the ledger:

```
$ awk -F'\t' '$(1)~/^2026-/{ f+=$(9); if($(11)~/^[0-9]+$/&&$(12)~/^[0-9]+$/){c++; cf+=$(9); m+=$(11); i+=$(12)} } END{print f, c, cf, m, i}' memory/review-ledger.tsv
178 rows-of-findings   11 classified rows   138 findings in them   13 missed   14 introduced
```

So **43 was the four-real-work-round subtotal, not "all counted findings"** (178),
and **the classified subset is 138 findings, not 28** — the `review-bench` rows
carry explicit `0`/`0` and are therefore classified. 14/138 is 10%; 14/178 is 8%.
The 52% figure is sound and belongs to the introduced-or-missed pairs in four
hand-picked rounds.

⚠️ **All six numbers above are the 2026-09-06 reading and every one of them has
since moved.** At v1.39.0 the same command prints `219 14 159 13 24` — 219
findings, 14 classified rows, 159 findings in them, 13 missed, **24 introduced**,
so the pair share is **65%** and the whole-ledger share **11%**. Two things caused
the jump, and only one of them is new data: the 2026-09-06 `CLAUDE.md`-cut rounds added **two**
classified rows, and the session that ran five lenses on the evening of
**2026-09-06** and shipped them as v1.39.0 the next morning **never appended any
of those five rows** — including the round whose nine findings were nine-of-nine `introduced`,
the single largest contribution to this statistic in the ledger's history. They
were reconstructed from the subagent transcripts the next day; the row notes say
so, and say that their `tokens` column is not measured the same way as any other
row. **The instrument that measures whether review is worth its cost was missing
the session that produced its headline number, and the shipped skill went on
quoting the pre-gap figure for a release and a half.** This section is the second
time the same paragraph has shipped a stale reading of the same command.

⚠️ **The exclusion ran in the flattering direction, not the conservative one.**
The seeded-benchmark findings excluded all carry `introduced = 0`, and they are
what drag the share down. ⚠️ **The 33%-to-8% this paragraph used to quote was the
2026-09-06 reading and is now 22%-to-11%** — `awk -F'\t' '$(1)~/^2026-/ &&
$(5)!~/review-bench/{f+=$(9); i+=$(12)} END{print f, i}'` gives `109 24`. The
caveat above is scoped *"all six numbers above"* and did not reach down here,
which is how a correction leaves a stale number three lines below itself.

**Found by an adopter, and the way it was found is the point.** Their
doc-accuracy lens verified every Step 5 number as ACCURATE — against this page,
where the same numbers were stated identically — while their adversarial lens
refuted them against the TSV. **The prose was internally consistent and
externally wrong, so the copy that ships to adopters was self-corroborating.**
A documentation-only check passing on a data error, in the release whose headline
is that review is worth its cost.

## The unclosed-frontmatter guard: the evidence behind its wording (#103, #144)

The guard's own comment in the skill states the mechanism and the decision. This page carries only what an adopter should not have to read on every invocation: the measurement, and the wordings that were rejected.

**Why the message says "no check ran" and not "no line was examined" (#144).** Reported by an adopter, who had carried a corrected wording as a declared deviation since 2026-08-28. Their wording — *"NO line in this file was examined"* — is an improvement on what shipped and is still not literally true: `{ sub(/\r$/, "") }` sits above `infm { next }` and runs on every line. ⚠️ **That enumeration was written against a three-rule program and #151 made it a five-rule one** — the BOM test now shares the first action block, and two `fmpend` rules sit between the opener and `infm { next }`. Re-counted rather than carried forward: the `\r` strip and the BOM test both run on every line (the BOM test guarded by `NR == 1`, so its `sub()` evaluates once — ⚠️ **this said `substr` until `f8bc9e3` was reviewed, naming a construct that commit had already deleted**: the strip is `sub(/^\357\273\277/, "")`, and a paragraph whose thesis is *re-counted rather than carried forward* had carried its own count forward); awk short-circuits `&&`, so the frontmatter opener `NR == 1 && $(0) ~ /^---[ \t]*$/` never evaluates its regex past line 1; and the `fmpend` rules, the closing-delimiter regex and `infm { next }` are all bare-pattern tests that evaluate on every line but *act* on almost none. The paragraph this corrects is one whose own point is that rule-counting has to be counted. A draft of this paragraph said "as do both frontmatter regexes" — an absolute in a description, refuted by counting evaluations on mawk and busybox awk, inside the paragraph that invokes the constraint against it. What is true is that **no check** runs: all four *other* finding `printf`s sit below that `next` (counted as printf sites, of which there are five including the guard's own; the skill's "all three are lost" counts *blocks*, and its "five shapes" counts printf sites — the units differ and are now named), and END's fence rule reads `fch`, which is set only inside the skipped block. Given this repo's Hard Constraint on absolutes in descriptions, the narrower claim is the one that ships.

**The measurement.** One body, written twice — the frontmatter opened at line 1 and closed, then with the closing `---` typo'd as `----`:

| closing `---` | findings |
|---|---|
| present | 3 — a lossy table row, an emphasis span, an unclosed fence |
| typo'd | 1 — the frontmatter message |

⚠️ **Opened and never closed.** An *unopened* frontmatter never sets `infm`, so nothing is swallowed and every check runs normally; that case is outside the guard entirely. A draft of this section said "unopened" and was refuted by measuring it.

The guard was never a false negative — it fired before and after. The defect was a reader acting on it believing tables were the only casualty: **a message that understates what it lost, inside the guard added to remove exactly that silence.**

**Seeded at** `tests/fixtures/step15-tables/` as T8 with T9 as its control. Ablation A6 is the only one in that suite that tests a *message* rather than a firing, because `ablate()` scores cases by empty against non-empty and cannot see a finding whose text is wrong. ⚠️ A6's first draft was itself vacuous: it mutated the same literal the assertion grepped for, so it could not fail by construction, and the assertion it "proved" was a substring test that passed a message re-asserting #144's own false narrowing. Both were found by review, not by the suite.

## v1.43.0 — four Step 1 / profile defects (#145, #153, #164, #166)

Detail moved out of the skill body so an adopter does not pay for it on every invocation.

### #145 — Step 1 could not observe untracked files

`git diff` in every form lists only files git has seen. Step 1's classification ran on
`--stat`, `--cached --stat`, the baseline term and `--summary -M`, none of which reports an
untracked file — while the magnitude gate carved out *"a new executable, or any new file in a
HIGH path"*. The same file says, one paragraph away, **a carve-out you cannot observe is not in
force**; this was that sentence's own class, one file-state over.

Not a regression: the reporter checked v1.17.0, v1.19.0, v1.22.0, v1.26.1, v1.31.0 and
v1.37.0 — `grep -c untracked` over the Step 1 span is 0 at every tag, and the whole-file count
went 0 → 2 only when Step 1.5 arrived with its own `ls-files --others`. Step 1.5 having it was
never a substitute: that step checks markdown validity and assigns no tiers.

They noticed because the commit introducing the skill in their repo was 695 lines, **645 of
them in new untracked files**, and `git diff --summary` returned empty on it. They have carried
a local fix since v1.17.0 and recorded the divergence in their skill header so a merge would
not silently undo it.

### #153 — HEAD contained in the baseline

The third member of the family #149 and the unresolved-baseline guard already cover, and the
only one where every existing guard reports healthy: `$BASE` resolves, `^{commit}` passes, no
fallback fires, and the committed-on-this-branch term is *correctly* empty because HEAD is
already an ancestor of the baseline. ⚠️ **"every diff term" was wrong and is corrected here**:
only `"$BASE"...HEAD` depends on the baseline — `git diff` and `git diff --cached` do not — so
the state coexists with real uncommitted work. That is why the shipped guard also excludes the
EQUALITY case: without it the diagnostic fired on the ordinary default-branch pre-commit run,
where the block reassigns BASE to `@{u}` and makes HEAD an ancestor by construction. The terminator then says "nothing to review".

| state | `$BASE` resolves | fallback fires | diff empty | reported |
|---|---|---|---|---|
| baseline unresolvable | no | yes | maybe | unresolved-baseline finding |
| root-commit fallback (#149) | yes (to root) | yes | yes, if one commit | finding, via `ROOTFALLBACK` |
| **HEAD contained in `$BASE`** | **yes** | **no** | the `$BASE`...HEAD term only | **"nothing to review"** |

Found by running the skill on a branch carrying three unreviewed commits after a concurrent
session moved the checkout back to `master`. It is also the *likeliest* of the three in ordinary
use — being on the base branch, a detached HEAD, a worktree someone else moved, or reviewing
after the fast-forward already landed. A diagnostic rather than an abort, because the state is
legitimate when reviewing merged work.

⚠️ **Worth revisiting**: reviewing by explicit ref range (`git diff master..<branch>`) is immune
to all three rows. `HEAD` is ambient state, and Step 1 already treats ambient state as the thing
to pin down. Not taken here — it changes the skill's whole interface.

### #164 — the octal BOM strip and one-true-awk

v1.39.0 replaced `substr($0, 1, 3)` with an octal `sub()`, and the comment shipped with it read
as though the octal spelling settled portability. The parenthetical *"(nawk here is mawk)"* was
the tell. Measured by the reporting adopter across four implementations:

```
mawk 1.3.4            match=YES
gawk 5.3.2            match=YES
busybox awk 1.37.0    match=YES
original-awk 20250804 match=NO     <- LC_ALL=C makes it match; any UTF-8 locale does not
```

End-to-end on a BOM'd file whose last frontmatter line carries a pipe — the exact #52 shape the
skip exists to remove — original-awk reports a phantom malformed table and the other three are
clean.

**The direction is safe**, which is why this is a comment fix and not a code fix: the skip does
not fire, so the pre-fix false positive returns as visible noise rather than silence. Three
alternatives were checked and declined before filing: `\xef` fails there too (gawk extension),
`index()` + `substr()` is worse (original-awk counts *characters* in UTF-8 mode, the precise
trap the comment already warns about), and `LC_ALL=C` on the invocation would flip gawk's
`length()`/`substr()` to bytes inside the emphasis-masking loop.

⚠️ Not re-verified in this repo: this machine carries only mawk, and its `nawk` is a symlink to
mawk — the same condition that produced the original over-claim. The measurement is the
adopter's, and the comment now says so.

### #166 — the profile had no slot for lenses

v1.40.0 moved `review-changes` to user-global and split the project's half into
`.claude/review-profile.md` — four sections, none of which holds a lens. For an adopter whose
project-local copy had only been *re-tiered*, a clean port. For one that had **added lenses**,
lossy and silent: the skill refuses on a *missing* profile and cannot tell a complete profile
from a half-ported one.

The reporting repo defined five lenses against the shipped four, and the sets did not nest —
`config-shape` and `concurrency-and-budget` local-only, `shell-correctness` global-only,
`adversarial` and `doc-accuracy` shared but carrying project-specific text. Adopting as shipped
would have dropped `config-shape`, the lens guarding the surface behind that repo's worst
recorded bug: a group key with no `url` of its own yields nothing *and its children are never
visited*, so 13 feeds sat `enabled: true` collecting nothing for about nine months with no
error, no warning and no zero-yield alert.

The same repo's retired skill also carried an anchored extractor for the Step 1.5 awk block plus
a `bash -n` rule — written after that block shipped unparseable in nine consecutive tags, and
after the repo re-broke it locally *in the comment warning about it*. On retirement that had
nowhere to go either. Hence the third new section: the split assumed a project's half is data,
and some of it is procedure.

⚠️ **Not taken, and worth deciding separately**: a required-section list, so an incomplete
profile fails the way a missing one does. It would close the silent half of this issue — the
new sections are optional, so a profile that loses them still passes.

⚠️ **The `.gitignore` edge, also from #166**: an adopter with a `.claude/*` ignore and no
negation writes a profile that is untracked. `git status` stays clean, the local session works,
and every fresh clone and deploy target gets no profile and a refusal.

### Why the emphasis guard is as narrow as it is (measurements moved out of the skill, v1.43.0)

The skill body carried these figures until v1.43.0; they are evidence for a decision already
taken, which is what this file is for.

- The **table** check reached a **39% false-positive rate** before it was anchored. That is why
  the emphasis check was written to report only the shape actually observed to break, rather
  than every shape that could in principle break.
- Widening it to the one-token form costs **33 hits over a 5,168-file estate** — a precision
  change, tracked as #158, not a correctness one.
- Weaker discriminators were measured and rejected: *"a risky token anywhere on a bold line"*
  reported **28 lines** in this repo, and *"two of them"* still reported **15** — every
  risk-tier row, where `**HIGH**` opens and closes inside one cell while the globs sit in the
  next. Only a token inside an *open* bold run can be joined by a formatter, so adjacency is
  the discriminator.
- Broader rules still rejected: counting `**` per line, and balancing across lines. Both fire on
  ordinary bold and on multi-line spans.

## The v1.45.0 HIGH-tier cut — what was measured, and what it does not license (2026-09-14)

`templates/review-profile.md` points here from its *"Consider a cheaper HIGH"* note. This is the
whole evidence base, including the parts that argue against the change.

**What this repo did.** Dropped its own HIGH tier from a 3–4 lens battery to one adversarial lens
plus two conditional ones — guarantee-preservation when the diff touches a declared guarantee
surface, shell-correctness when it changes a shell file.

**The saving, and the two ways the headline figure is soft.** The pre-cut figure quoted as
"~840k per release" is **not re-derivable from the ledger**: the only grouping that produces it
averages `#172`+`#173`+`#174` (1,681,403 tokens, all three shipped in v1.42.0) over two releases,
one of which has no recorded review at all — `grep -c v1.43.0 memory/review-ledger.tsv` returns 0.
The defensible statement is that the last heavily-reviewed release cost **1.68M**. And roughly
**17% of the drop belongs to the v1.44.0 round cap, not the lens cut**: `#173`'s rounds 3 and 4
alone were 250,488 tokens, and the cap removes those regardless of lens count.

**The post-cut figure is per-run, not per-round.** The two one-lens runs cost 86,169 and 127,939
(mean ~107k). The HIGH row prescribes a second lens whenever a guarantee surface is touched, so the
commonest HIGH case costs roughly **two runs, ~214k** — a budget set from the 107k figure is one a
compliant review cannot meet. That mistake shipped in a draft of `.claude/review-profile.md` and
was caught by review.

**What the measurement cannot tell you, and never will.** Both cited ledger rows carry
`missed=0`, and both carry the warning that this is **not a measurement**: the round cap shipped in
the same release means no second round will ever run on those targets, so nothing will ever
classify what the single lens missed. **The recall of the evidence for this cut is unmeasurable by
construction.** Against it: on a four-lens round, *two* lenses each found a blocker no other lens
found — and `CHANGELOG.md` records which two, adversarial and **shell-correctness**, which is why
shell-correctness is a conditional carve-out rather than a casualty.

**Why it is not the shipped default.** A review round refuted making it one. HIGH at one lens sits
*below* MEDIUM at two, so the skill's own instruction to escalate shipped content from MEDIUM to
HIGH would lower its depth, and the always-full-depth carve-outs (`.gitignore`, renames, mode
changes, any loosening of a check) would resolve at HIGH to exactly what a changelog edit gets.
Fixing that means re-tiering MEDIUM as well — a larger change with no evidence base of its own.
**n=2, same author, same day, same reviewer model** is enough to change one repo's own profile
deliberately; it is not enough to move a default under 28+ adopters who will not re-derive it.

## Step 1.5 provenance, moved out of the skill body (2026-09-14)

`templates/review-changes.md` points here. The skill kept every *rule*; what moved is the
litigation behind each one, which an adopter pays for on every invocation and needs only when
editing the checker. `templates/review-changes.md` 49,516 → 43,040 bytes (the installed SKILL.md
is 42,460; `tests/lint/size-baseline.tsv` carries the authoritative pair).

**The awk program is behaviourally identical — its CODE is byte-identical, the comments are not —
and the evidence is the fixture, not the corpus.**
Extract both versions, strip comments with a tokenizer that respects `"…"` and `/…/`, and the code
is 60 lines each, identical; then `tests/fixtures/step15-tables/run.sh` run against each template
gives byte-identical output, 33 cases including 11 ablations that each still fail exactly their
named case. ⚠️ **A corpus run over this repo's 107 markdown files was cited first and is a blind
instrument here**: ablating the program — dropping the `\r` strip — leaves its output over those
107 files unchanged. It was true and it proved nothing.

**The frontmatter skip's deciding line.** Line 1 only *arms* the skip; the first non-blank line
decides, because a leading `---` is also a CommonMark thematic break and opening on it alone
silenced whole well-formed files (#151). Blank lines and YAML *comments* are scanned past rather
than decisive — Obsidian writes `---`, a blank, then the key, and 10 files in the estate measured
open with a `#` comment. A quoted key counts. `#` cannot be made to decide: a YAML comment is
indistinguishable from a heading.

**What the row shape can report that is not a table at all.** `isdelim()` accepts a bare `---` and
its guard is satisfied by a pipe in the *previous* line, so a setext heading, a spaced `- - -`
break, and frontmatter that does not begin at line 1 can each report. Classes and repros in #52.
Frontmatter *at* line 1 no longer reports; that narrowing was measured, not assumed (#150).

**The three refuted attempts to widen the 3-space fence strip (#150 part 2).** The skill points
here for these; they were in `CHANGELOG.md` alone, which is a different document with a different
job.

| attempt | what it bought |
|---|---|
| strip all indentation | an 8-space marker inside a python block became a *close*; a balanced real file reported `unclosed` |
| bound the close relatively (`ind <= find + 3`) | a top-level indented **code block** with an unpaired marker opened a fence and **silenced the whole file**, losing a lossy row the shipped version reports |
| add CommonMark's no-info-string rule for closes | correct per spec, and moved **18 files** in the estate — 8 stopped reporting, 10 started, none cheaply adjudicable |

The class being fixed has **zero instances in the 5,168-file estate**, and it is a *visible* false
positive. ⚠️ **One attempt silenced a whole file outright; a second traded visibility for silence
in 8 files.** A trim on 2026-09-14 compressed that to "two of them silencing a whole file", which
neither this table nor `CHANGELOG.md` supports — a count is not provenance and should not have
moved in a provenance trim.

**Blockquotes and missing delimiter rows are not examined.** The check finds lossy rows in
well-formed tables. It is not a markdown validator, and a clean result should not be read as one.

**The lone-CR failure has a loud half and a quiet half**, and the quiet one is why it is named in
the skill at all: with the first fence as the file's opening construct a correctly closed fence is
reported as unclosed, but with anything above it — a heading is enough — the file goes entirely
silent and a genuine lossy row is lost. Both measured (#150).

**Why the `set -e`/`|| :` guards in the Step 1 baseline block are shaped as they are.** Measured
failure modes: a repo with no remote and no `main`/`master` died at the candidate loop with no
output at all; without `|| :`, `set -eo pipefail` kills the shell before the message that reports
the failure; and an empty repo was told to run `git show --stat` with no argument. Four modes are
seeded in `tests/fixtures/baseline-fallback/`.

**Why `ls-files` is root-anchored and `-z`.** It defaults to the CWD subtree while every `git diff`
term is repo-wide, so from a subdirectory it silently dropped every untracked file outside it — and
this skill is user-global, running with the cwd of whatever repo is under review. `release.md`
praises `git grep` for being repo-root-relative for the same reason.

**Why the guarantee invariant is checked entry-first.** It used to span the skill (tier table) and
the lens (guarantees), which adopters rewrote independently and therefore inconsistently; v1.40.0
put both halves in the profile so it is checkable inside one file.

## Moved out of the skill body on 2026-09-25

Token-reduction trim of `templates/review-changes.md` and its reference install. Every prose paragraph of the skill body that did not survive verbatim is kept here, verbatim, under the step it came from. Fenced blocks were not touched and are not repeated. Where the skill now carries a shorter restatement, the paragraph below is the longer original.

### Step 1

Resolve the review baseline first — **every command in this step depends on it.**

**The baseline is the default branch — `@{u}` only on the default branch itself.** On a branch that is committed and pushed but not merged — the commonest state in which anyone wants a pre-merge review — `@{u}` is *empty*, because the upstream exists and is current. Every `@{u}`-derived term then reports zero and the step reads as "nothing to review" on a whole PR. Resolve it once, **here, before anything else in this step**, and reuse it everywhere below — the tier table, the magnitude gate and Step 1.5 all read `$BASE`:

**Resolving a name is not enough — it has to resolve to a commit.** A ref can look fine and diff to nothing. That is why the block validates `^{commit}` and, on failure, falls back to the root commit and says so: an unresolved baseline and a clean tree produce identical output.

The loop covers the cases where `origin/HEAD` is absent: `git init` + `git remote add` with no fetch, and older git. ⚠️ It does **not** cover a remote whose default branch is neither `main` nor `master` *and* whose `origin/HEAD` is unset: a repo defaulting to `develop` falls through to the root-commit fallback, which reviews everything **except the root commit's own content** — see the fallback's own comment; it is a fallback rather than the intended path, and it under-reports rather than over-reporting (#149).

⚠️ **`$BASE` lives in a shell, and Step 1.5 needs it. Run Step 1.5's blocks in the same shell invocation as this one** — paste them together, or re-run this block at the top of that shell. A tool call that starts a fresh shell does not inherit it, and Step 1.5 is written to abort rather than proceed with the term missing. That abort is the intended behaviour: the alternative is Step 1.5 quietly reviewing a fraction of the change, which is #64 one step later.

Now run `git diff --stat "$BASE"...HEAD`, `git diff --stat` and `git diff --cached --stat` to see the changed files, `git diff --summary -M "$BASE"...HEAD` alongside them, and `git ls-files --others --exclude-standard` for the ones git has not seen — **an untracked file is a changed file and gets a tier like any other** (#145). That was #64 surviving its own fix in the place nobody re-read. **`--stat` alone cannot see a mode change, a rename, a submodule, or a binary** — all four render as zero or near-zero lines, and three of them are carve-outs below. A carve-out you cannot observe is not in force; `--summary` without the baseline term cannot observe any of them on a pushed branch. Classify each changed file into a risk tier:

**Read `.claude/review-profile.md` now** — it holds this project's risk tiers,
guarantee surfaces, test baseline, carve-outs, and three optional sections a
project may add (#166): **Project lenses** and **Project additions to the shipped
lens prompts**, both read in Step 2, and **Project procedure kept with the profile**,
which you read HERE if it is present — it holds local checks the project wants
run that are procedure rather than data. All three are additive and never replace
what ships; a profile written before v1.43.0 has none of them, which is not an
error. The tier table is **not** in this skill,
deliberately: this file ships identically to every project, and a table of one project's
paths silently classifies every other project's changes as LOW.

⛔ **If `.claude/review-profile.md` does not exist, STOP and say so. Do not proceed on
defaults, and do not invent a table.** There is no safe default: with no profile every path
falls through to LOW, which is the one outcome indistinguishable from a review that ran and
found the change unimportant. Report the missing profile as the result, and point the reader
at `templates/review-profile.md` in the framework. Refusing is cheap; a silently-LOW battery
on a HIGH change is what this skill exists to prevent.

Classify each changed file using the profile's tier table, then apply the magnitude gate below.
⚠️ **The gate's carve-outs are part of THIS file and always apply**; a profile may add to them
but never remove one.

The tier above is set by *path*. Depth is also set by *size* — but size is the weaker signal, so the exceptions are stated first and override everything below them.

**Always full depth, regardless of size.** Each of these is dangerous *because* it is small, and each would otherwise slip through on line count alone:

- **`.gitignore`** — see the paragraph above; one line has exposed private content in a public repo.
- **Renames and moves** — `git diff --stat` reports `0 insertions(+), 0 deletions(-)` under `-M`, while every reference to the old path breaks.
- **Permission changes** — also zero insertions and deletions, and invisible without `--summary`. A `chmod -x` on a shipped script makes it unrunnable for everyone downstream.
- **Binary files and submodule pointers** — the other two members of the zero-line class. A submodule bump changes one line and can move an arbitrary amount of code.
- **Any change to a shell script or an executable, wherever it lives** — `scripts/**` and `tests/**` are both HIGH because they are code that runs on someone else's machine, and shell breaks in one character. A small edit would otherwise lose the shell-correctness lens, which is the reason those paths are HIGH at all.
- **Any non-frontmatter edit to a reference install** (`.claude/skills/**`) — HIGH because a defect there ships to every install derived from it; that is as true of a three-line body edit as of a frontmatter one.
- **Frontmatter edits to those same files** — removing one `---` silently unregisters a skill.

  *Both bullets used to end a bolded phrase with a `**`-suffixed glob, and prettier corrupts that shape. **The rule worth remembering is the shape** — never end a bolded phrase with such a glob; put the path in a parenthetical, as above. Step 1.5 reports the TWO-token form of it and is silent on the one-token form, so the check is a backstop and **the shape is the thing to remember** (#151).*
- **A new executable, or any new file in a HIGH path** — the tier for new content has not been decided yet.
- **Any diff that removes or loosens a check** — a deleted guard, a weakened assertion, a broadened exclusion. Loosenings are characteristically a handful of lines, and this is the class the seeded-true-positives rule exists for.

**Otherwise size sets the depth.** Size means the whole change that will land, not the slice in front of you — 10 lines committed locally plus 15 staged is a 25-line change, and reviewing each half on its own means nothing ever sees the whole. `$BASE` is already resolved at the top of this step; do not resolve it again.

Line count is a proxy, and in these templates a weak one — they are written one sentence per line, so replacing two dense normative paragraphs is four changed lines while a whitespace reflow is a hundred. **When the line count and your read of the change disagree, the line count is wrong.** Escalate.

Run that single pass in a **fresh context** — a subagent if your tool provides them, otherwise a separate pass that re-reads the diff from scratch. Reviewing your own edit in the context that produced it is the self-certification failure this skill exists to prevent; the saving comes from running *one* independent reviewer instead of four, not from dropping independence.

The gate changes how many lenses run. It never changes *whether* a change is reviewed — every diff still gets at least one adversarial pass.

If only LOW files changed **and the gate above does not escalate**, run Step 1.5, then do a single adversarial pass and skip to Step 3. Step 1.5 is never skipped — it is deterministic and costs nothing, and LOW is where the memory files that motivated it live. The gate wins where the two disagree: a 400-line change to `memory/**` is still a large change, and tier is about blast radius, not size.

**If a changed file matches no pattern, treat it as MEDIUM, and name it in the report under "Unclassified" even when a HIGH file in the same diff makes the tier moot.** The naming is the point: an unrecognized path is usually new shipped content whose tier nobody has decided yet, and it will keep arriving un-triaged until someone adds a row. Do not silently drop it, and do not default it to LOW. **If it is executable or is copied into an adopter's tree, escalate it to HIGH rather than leaving it at MEDIUM** — MEDIUM omits both the guarantee-preservation and shell-correctness lenses, which are exactly the two that shipped content needs.

If no files changed, report "nothing to review" and stop — but only after `$BASE` resolved **and the block printed neither a `BASELINE UNRESOLVED` nor a `HEAD IS CONTAINED IN` line**. ⚠️ **The second is the state with no other tell** (#153): the baseline resolves, `^{commit}` passes, no fallback fires, and every term is legitimately empty because HEAD is already in the baseline — so three unreviewed commits report as a clean review. Key on the printed line there too; it is a finding, not a pass. ⚠️ Key on the printed line, not the variable: a fallback baseline *resolves* while excluding the root's own content, so an empty result there is the unresolved-baseline finding, and `git show --stat <root>` is what shows you what the diff omitted (#149). A clean tree because everything is merged and a clean tree because the work is already pushed are indistinguishable from `git diff` alone, and the second is a full PR. If the baseline could not be resolved, that is the finding; report it instead of a clean result.

### Step 1.5

Runs at **every tier and every magnitude**, before any lens, on every changed markdown file — the single-adversarial-pass gate above trims lenses, not this. It is deterministic, so it costs nothing to run and does not need a model to evaluate, which is the reason it is a step rather than a lens.

The lenses below all read *content*: does this path exist, is this flag right, what would a future session do wrong. None of them asks whether the file is still **valid markdown** after the edit. That gap matters disproportionately here, because the memory layer is predominantly wide tables — inventories, index files, machine lists — where a row is one very long line. A `|` added inside a cell (a regex like `'recordfail|initrdfail'`, an `||` in a shell fragment, an alternation in a note) pushes cells past the end of the table, and **GFM drops the excess silently**. It reads fine as prose in the diff and is wrong only when rendered, so a human reviewer and an adversarial lens both pass it.

The file list is the union of unstaged, staged, **everything committed on this branch**, and **untracked** — `git diff` in any form never lists a file git has not seen, and a brand-new document is where fresh corruption is most likely. `core.quotePath=false` is load-bearing: git otherwise renders a non-ASCII path as `"caf\303\251.md"`, which does not end in `.md`, so the file is dropped from both the check and the count with no error.

**The delimiter row defines the table, and only *excess* cells are reported.** GFM inserts empty cells when a row is short and discards them when a row is long, so a short row renders exactly as intended and is not a defect — a section-divider row like `| **PART ONE** |` inside a wide table is idiomatic, not corruption. A long row loses data.

Hits come in five shapes: a row whose excess cells are discarded, a header that disagrees with its own delimiter row (which means GFM renders no table at all), an unbalanced code fence, two backticked tokens abutting `**` inside one bold span, and a frontmatter that opens and never closes. Fix each before running the lenses, **with the repair its shape calls for.** *Row and header*: escape as `\|`, or move the command out of the table — this includes pipes inside backticks, since GFM splits a row into cells *before* it parses inline content and its spec says so explicitly, so a `|` in an inline-code span breaks the row exactly like a bare one. *Fence*: close it. *Emphasis*: separate the two backticked tokens, or take one out of the bold run. ⚠️ *Frontmatter*: this one is a **denominator signal**, not a table defect — no check ran on any line of that file, so close the delimiter and **run Step 1.5 again**. Until you do, that file's real findings are unknown (#144, #150).

**Treat a hit as real until you have looked at it, not as proven** — this applies to the *row* shape, the only one with a documented false-positive class. A row hit says the row supplies more cells than the delimiter defines, which is a loss only when those cells carry content, and it says nothing about whether you are looking at a table at all: a setext heading, a spaced `- - -` break and frontmatter that does not begin at line 1 can each report (#52).

**Known blind spots, so a clean result is not read as more than it is.** Tables inside blockquotes are not examined, nor is a table whose delimiter row is missing — this finds lossy rows in well-formed tables and is not a markdown validator. The emphasis guard is a **backstop, not coverage**: it needs two risky tokens in one bold run, and the one-token form goes unreported (#151, #158). Prose quoting the shape in a double-backtick span no longer reports (#159). A fenced block indented four or more spaces is scanned as markdown, so a table inside it can report — a *documented* false positive, not an unfixed one (#150) — and frontmatter is the same trade: one whose first deciding line is a block sequence, a `%YAML` directive or a spaced key is not recognised, and its closing `---` can report as a delimiter row. **Lone CR is the one that matters**: awk sees the file as a single record, and with anything above the first fence the file goes **entirely silent**, which is indistinguishable from a clean run.

⚠️ **Three attempts to widen the fence rule each bought a worse class. The attempts, and what each cost, are in <https://github.com/ducroq/agent-ready-projects/blob/master/docs/rationale/review-changes.md> <!-- lint-skip: maintainer-path — a URL, not a repo-relative path: it resolves for a reader with no such directory. --> before touching any of these trades.**

The command prints nothing on a clean run — which is also what it prints when the file list was empty. **Report the count alongside the result** so the two are distinguishable:

That count is files *in scope*, not files you edited: the baseline term includes everything committed on this branch, and `ls-files --others` includes every untracked markdown in the tree. If it is zero while the Step 1 diff listed markdown files, the pipeline is broken — not the changes clean. It reads `$BASE` from Step 1, **in the same shell**: an unset `$BASE` aborts this pipeline rather than dropping its largest term, so a fresh shell gives you a loud failure and not a small number.

### Step 2

For each lens, spawn a subagent with the specific prompt below. Run lenses concurrently.

**Run the profile's `Project lenses` too, and append its `Project additions to the shipped lens
prompts` to the matching prompts** (#166). They are additive: a project lens never replaces one below, and a
project addition never replaces the shipped text it extends. A profile with neither section
runs exactly the set below.

**Invariant: every path with a guarantee must sit in the profile's HIGH row.** The lens is HIGH-gated, so a guarantee on a lower-tiered path can *never* fire — and the report renders that as a clean pass, a silent failure that looks like success. Both halves live in `.claude/review-profile.md`, so check it inside one file, and in the direction that catches it: read each guarantee entry, then find its tier. If a path does not deserve HIGH, it does not deserve a guarantee entry.

### Step 3

Combine all lens reports. Structural hits from Step 1.5 do not enter this table — they were fixed before the lenses ran; carry their count into the Step 4 summary instead. A hit you deliberately left unfixed enters here as a BLOCKER with the lens recorded as `structural`, and the summary count still includes it.

### Step 3.1

Run this on the findings already in context. It spawns no subagent and needs no new context — it costs the output tokens of the triage itself and nothing more.

For **each** finding, answer one question: **could a deterministic check have found this?**

- **Yes** — name what it greps, parses or runs, and the file it lands in. A shape you can state in one sentence is usually scriptable; one that needs the diff's intent is not.
- **No** — say why, in four words or fewer (`needs intent`, `one-off`, `judgment call`). A blank is not an answer; it is indistinguishable from a finding nobody triaged.

⚠️ **Naming a check is not writing one, and the row is not done until the check fires on a seeded case.** A check that has never caught anything is indistinguishable from one that does not work — the method is at <https://github.com/ducroq/agent-ready-projects/blob/master/docs/seeded-defects-and-ablations.md> — a URL, not a repo-relative path: this skill is user-global and runs with the cwd of whatever repo is under review, where `docs/` is someone else's tree. Record the named check in the gotcha log's **Mechanized** table as `proposed` — the log is wherever your project keeps it (`memory/gotcha-log.md`, `docs/gotcha-log.md`; `templates/README.md` has the map). It becomes `live` only once a seeded positive has made it go red.

⚠️ **Ask what the check measures, not only what it reports, and beware the one that measures something ADJACENT to the claim** — byte size standing in for content, a file *listed* standing in for a file *changed*, a printed verdict word standing in for an exit status. A guard that measures nothing looks wrong and never ships; one that measures the neighbouring thing returns a plausible number and does. **State what a positive looks like, then produce one.**

⚠️ **Mark a `proposed` row's check path with `<!-- placeholder -->`, immediately after the path and in the same cell** — `` `tests/lint/count-commands.sh` <!-- placeholder --> ``. It covers the nearest path *before* it, so a marker further along the row binds to whatever path came last — harmless in a bare row whose trailing cells hold no path, wrong the moment one does. The file does not exist yet, so a reference-integrity audit reports a path that does not resolve; the marker is what tells the auditor this is a declared placeholder rather than a dead link. Without it every proposed row becomes a standing false finding, which trains readers to dismiss that audit. ⚠️ **That exact marker, no other** — one the reading end was never taught is worse than none, because it stops the author looking while the finding is still in the list.

**Why a step and not advice.** A finding that becomes a check is paid once; a finding that stays a finding is paid every round, forever, at full lens price. It is the one lever that *plausibly* makes review cheaper **and** better rather than trading one against the other — the axes you might cut instead (lenses, independence) each have measured evidence they buy something, and round count is the one axis nothing here contradicts. ⚠️ **This lever itself is unmeasured**: an expectation, not a result.

### Step 4

The Unclassified list is not cosmetic and is not made moot by a HIGH file elsewhere in the same diff. An unrecognized path is usually new shipped content whose tier nobody has decided yet; naming it is what gets a row added, and until someone adds one it will keep arriving un-triaged.

### Step 5

**Reviewing is not where the cost is. Fixing is.** In this framework's own ledger, a large share of findings classified `missed` or `introduced` were defects the previous round's own fixes created. **Re-derive it, never quote it** — note `$(N)`, not `$N`, or the substituter eats the field refs (#77): `awk -F'\t' '$(1)~/^2026-/{f+=$(9); i+=$(12); m+=$(11)} END{print i, m, f}' <ledger>`. ⚠️ Seeded-benchmark rows carry `introduced` 0 by construction, so the whole-ledger ratio is low for a reason that has nothing to do with fixing. **A round cap does not remove the defects fixing creates; it ships them.**

- **A fix is a change, and takes the tier of the file it lands in.** Treating it as a correction too small and too well-understood to re-read is self-certification in miniature: small is why loosenings hide, and knowing the intent is what stops you seeing the result.
- **Re-read the steps that consume what you changed.** These defects live in the *relationship between* steps, so re-reading the fixed step alone finds nothing.
- **Fix one finding at a time when findings touch the same file.** Batched fixes interact, and the interaction is invisible in a diff showing them as separate hunks.
- **Name what the fix could have broken before another round.** If you cannot name a candidate you have not looked; if you can, that is the next round's scope — far narrower than a battery. ⚠️ **Naming a candidate does not by itself license the round — the cap below governs whether it runs at all.**

**A round is one pass of the lens set, however many lenses it contains** — not one lens, and not a re-run of a deterministic check.

**Two rounds maximum.** A third runs only when round 2 found **the same defect a second time** — a second instance anywhere, in this file or another, which makes it a class rather than a one-off. ⚠️ **When that trigger fires, the remedy is a census before it is a round**: enumerate every site the class could occupy and check them all at once. This framework needed three rounds to stop finding instances of one defect, and the thing that ended it was a one-line enumeration, not the third round.

⚠️ **A cost decision, and it buys the risk named above**: a cap ships the introduced defects instead of catching them. What makes the trade pay is that **within a single target, tokens per acted finding rises with each round** — on the one recorded four-round sequence it roughly tripled from round 1 to round 4. Re-derive before quoting: `awk -F'\t' '$(1)~/^2026-/ && $(10)>0 {print $(5), $(4), $(6)/$(10)}' <ledger>`, compared **within one target**; aggregating across targets hides the effect and once read as flat here. **Re-open the cap on a measured rise in that per-target ratio's flattening, or on a class of defect a capped round demonstrably shipped — not on one missed finding**, which is the trade working as described.

State the lens set and the ceiling **before** starting; record the cost after. Left unbudgeted, a review tends to expand toward the most expensive form available — observed here as four lenses on one diff, two stopped part-way for cost.

- **Decide the lens set up front.** Stopping a reviewer part-way spends its cost to that point and returns nothing. A lens not worth its cost should not be started.
- **Never run a lens for a class a deterministic check covers *completely*.** Partial coverage is not coverage: where the tier table mandates a lens and a check covers only part of its class, the tier table wins — say which part the check already settled, and let the lens have the rest.
- ⚠️ **Do not economise by collapsing lenses into the author's own context.** This is about *whose context* the reviewer holds, not how many run: one independent reviewer instead of four is a legitimate saving, and the magnitude gate prescribes that for small diffs. Asking the questions inside the context that wrote the change is not — that reviewer holds the author's blind spots, the failure this skill exists to prevent. Measured twice: two lenses once returned **disjoint** findings; and on a four-lens round *every* lens found the top blocker while **two of them each found a blocker no other lens did**. Breadth buys the defects nobody predicted — not disjointness.
- **Promote rather than re-catch.** Step 3.1 triages each round's findings into checks; this is where the loop closes. **Read the Mechanized table in Step 1, before choosing lenses** — not here, which is read before Step 3.1 has ever run. ⚠️ A `live` row is not a reason to drop a lens the tier table mandates: it covers one *shape*, a lens covers a *class*, and the bullet above governs — partial coverage is not coverage. Use it to narrow a lens's scope, never to skip one.
