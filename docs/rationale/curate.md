# Why `curate` says what it says

Superseded drafts and the measurements that refuted them, moved out of `templates/curate.md` so that
adopters do not pay for this repo's litigation on every invocation. **The decision lives in the
skill; the argument lives here.** Nothing is duplicated between the two — if a claim appears in
both, one of them is wrong.

###    One deprecated exception, and it is the only place a word in the output changes anythin…

- This framework taught `… && echo PASS || echo FAIL` until v1.21.0, and that idiom exits 0 on its failure branch, so without this every such command in every adopter's memory files would read as a pass on upgrade.

###      The second is a false PASS with the evidence of its own failure printed beside it, an…

- Put the failure on a non-zero exit: `git rev-parse v1.2.3 >/dev/null 2>&1 && echo TAG-PRESENT || { echo TAG-MISSING; exit 1; }`.

### Step 0.8 — the prettier ignore-file cwd measurement

Moved out of the skill 2026-09-05 to pay for the #109/#110 budget rewrite. The **rule** stays in
Step 0.8: verify the exemption from the cwd the formatter actually runs in. This is the evidence.

Measured on prettier 3.8.1 (adopter) and 3.9.4 (here), with a root `.prettierignore` naming the
project file:

| run from | command | exit |
|---|---|---|
| repo root | `prettier --check CLAUDE.md` | 0 — ignored |
| repo root | `prettier --check --ignore-path /dev/null CLAUDE.md` | 1 — it does want to re-pad |
| `frontend/` | `prettier --check ../CLAUDE.md` | 1 — the ignore file is never found |

Losing format-normalization on one markdown file is a smaller cost than a third of the budget.

### Step 0.8 — the two table-padding measurements

Moved 2026-09-05. The rule stays in Step 0.8: measure the de-padded size before proposing any cut.

| project | padding reclaimed | share of file | after |
|---|---|---|---|
| table-heavy project file | 12,685 chars | **35%** of 36.3k | 23.6k, identical content and rendering |
| second project | 21,030 chars | **61%** of 34,706 | content-identical |

The first project had no session footers left to trim and only structural sections remaining, so
the step had already escalated to the engineer as a *content* decision when the real cause was
whitespace. A file whose tables hold short cells sees far less than 35%.
