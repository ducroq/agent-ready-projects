# Why `review-changes` says what it says

Superseded drafts and the measurements that refuted them, moved out of `templates/review-changes.md` so that
adopters do not pay for this repo's litigation on every invocation. **The decision lives in the
skill; the argument lives here.** Nothing is duplicated between the two — if a claim appears in
both, one of them is wrong.

### Now run git diff --stat "$BASE"...HEAD, git diff --stat and git diff --cached --stat to se…

- **All three terms are needed and the baseline one is the one that is usually non-empty**: on a pushed, unmerged branch the other two are empty, and an earlier version of this step listed only those two — so the tier table, the Unclassified section and the report header were all computed over zero files while the magnitude gate below reported the real number.

### Known blind spots, so a clean result is not read as more than it is: tables inside blockqu…

- **CRLF was one of these until v1.25.1** — `isdelim()` strips spaces and tabs but not `\r`, so on a CRLF checkout tables went unentered and a file whose defect was in a table printed what a clean file prints.
