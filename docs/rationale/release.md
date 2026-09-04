# Why `release` says what it says

Superseded drafts and the measurements that refuted them, moved out of `templates/release.md` so that
adopters do not pay for this repo's litigation on every invocation. **The decision lives in the
skill; the argument lives here.** Nothing is duplicated between the two — if a claim appears in
both, one of them is wrong.

### If there are genuinely no tags — git rev-parse --is-shallow-repository says false and git …

- Skip the diff commands, review the full history (`git log --oneline`), and propose `v0.1.0` or `v1.0.0` per the project's own convention.

###    Do not use a substring grep.…

- `grep v1.2.3` matches a months-old `v1.2.3-rc1`, so a failed or forgotten push reads as success — and every step below would then act on a release that does not exist: step 2 installs unreleased content into a copy that shadows every repo, and steps 3–5 record the release as shipped in project memory, on the issue tracker, and in the work item.
