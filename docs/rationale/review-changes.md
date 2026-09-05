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
