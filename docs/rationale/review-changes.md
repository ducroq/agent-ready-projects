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

⚠️ **The exclusion ran in the flattering direction, not the conservative one.**
The ~110 seeded-benchmark findings excluded all carry `introduced = 0`, and they
are what drag the share from 33% to 8%.

**Found by an adopter, and the way it was found is the point.** Their
doc-accuracy lens verified every Step 5 number as ACCURATE — against this page,
where the same numbers were stated identically — while their adversarial lens
refuted them against the TSV. **The prose was internally consistent and
externally wrong, so the copy that ships to adopters was self-corroborating.**
A documentation-only check passing on a data error, in the release whose headline
is that review is worth its cost.

## The unclosed-frontmatter guard: the evidence behind its wording (#103, #144)

The guard's own comment in the skill states the mechanism and the decision. This page carries only what an adopter should not have to read on every invocation: the measurement, and the wordings that were rejected.

**Why the message says "no check ran" and not "no line was examined" (#144).** Reported by an adopter, who had carried a corrected wording as a declared deviation since 2026-08-28. Their wording — *"NO line in this file was examined"* — is an improvement on what shipped and is still not literally true: `{ sub(/\r$/, "") }` sits above `infm { next }` and runs on every line, as do both frontmatter regexes. What is true is that **no check** runs: all four finding `printf`s sit below that `next`, and END's fence rule reads `fch`, which is set only inside the skipped block. Given this repo's Hard Constraint on absolutes in descriptions, the narrower claim is the one that ships.

**The measurement.** One body, written twice — the frontmatter opened at line 1 and closed, then with the closing `---` typo'd as `----`:

| closing `---` | findings |
|---|---|
| present | 3 — a lossy table row, an emphasis span, an unclosed fence |
| typo'd | 1 — the frontmatter message |

⚠️ **Opened and never closed.** An *unopened* frontmatter never sets `infm`, so nothing is swallowed and every check runs normally; that case is outside the guard entirely. A draft of this section said "unopened" and was refuted by measuring it.

The guard was never a false negative — it fired before and after. The defect was a reader acting on it believing tables were the only casualty: **a message that understates what it lost, inside the guard added to remove exactly that silence.**

**Seeded at** `tests/fixtures/step15-tables/` as T8 with T9 as its control. Ablation A6 is the only one in that suite that tests a *message* rather than a firing, because `ablate()` scores cases by empty against non-empty and cannot see a finding whose text is wrong. ⚠️ A6's first draft was itself vacuous: it mutated the same literal the assertion grepped for, so it could not fail by construction, and the assertion it "proved" was a substring test that passed a message re-asserting #144's own false narrowing. Both were found by review, not by the suite.
