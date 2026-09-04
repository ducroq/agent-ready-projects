# Why `curate` says what it says

Superseded drafts and the measurements that refuted them, moved out of `templates/curate.md` so that
adopters do not pay for this repo's litigation on every invocation. **The decision lives in the
skill; the argument lives here.** Nothing is duplicated between the two — if a claim appears in
both, one of them is wrong.

###    One deprecated exception, and it is the only place a word in the output changes anythin…

- This framework taught `… && echo PASS || echo FAIL` until v1.21.0, and that idiom exits 0 on its failure branch, so without this every such command in every adopter's memory files would read as a pass on upgrade.

###      The second is a false PASS with the evidence of its own failure printed beside it, an…

- Put the failure on a non-zero exit: `git rev-parse v1.2.3 >/dev/null 2>&1 && echo TAG-PRESENT || { echo TAG-MISSING; exit 1; }`.
