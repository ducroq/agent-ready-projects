# Claim audit sample — 2026-08-13

The 20 lines drawn from the claim sweep described in `CHANGELOG.md` v1.26.0, and
how two independent reviewers classified each. Committed because the sweep's own
denominators are not reproducible (scratch extractor, gitignored corpus) — this
sample is, and it is what actually supports the 2-of-20 rate.

Draw: `random.seed(20260813); random.sample(bare, 20)` over the lines carrying
no probe, hedge or citation. Classifications:

- **PRESCRIPTION** — an instruction or design decision. The absolute is a choice.
- **HISTORICAL** — a past-tense record of what was found or done.
- **EXTRACTOR-FALSE-POSITIVE** — not a claim at all.
- **DESCRIPTION-SUPPORTED** — behavioural claim whose support sits nearby.
- **DESCRIPTION-UNSUPPORTED** / **DESCRIPTION-FALSE** — the defect class.

| # | Location | Classification |
|---|---|---|
| 1 | `docs/GUIDE.md:43` | DESCRIPTION-SUPPORTED |
| 2 | `docs/GUIDE.md:94` | PRESCRIPTION |
| 3 | `docs/GUIDE.md:117` | PRESCRIPTION |
| 4 | `docs/GUIDE.md:508` | DESCRIPTION-SUPPORTED |
| 5 | `docs/GUIDE.md:509` | DESCRIPTION-SUPPORTED |
| 6 | `docs/GUIDE.md:571` | HISTORICAL |
| 7 | `docs/GUIDE.md:782` | PRESCRIPTION |
| 8 | `memory/gotcha-log.md:67` | HISTORICAL |
| 9 | `memory/gotcha-log.md:167` | HISTORICAL |
| 10 | `memory/hypothesis-log.md:67` | PRESCRIPTION |
| 11 | `memory/hypothesis-log.md:169` | HISTORICAL |
| 12 | `templates/audit-context.md:138` | PRESCRIPTION |
| 13 | `templates/audit-context.md:140` | DESCRIPTION-SUPPORTED |
| 14 | `templates/curate.md:47` | DESCRIPTION-SUPPORTED |
| 15 | `templates/curate.md:179` | DESCRIPTION-SUPPORTED |
| 16 | `templates/gotcha-log.md:14` | **DESCRIPTION-UNSUPPORTED** — fixed in v1.26.0 |
| 17 | `templates/project-file.md:83` | EXTRACTOR-FALSE-POSITIVE |
| 18 | `templates/review-changes.md:30` | PRESCRIPTION |
| 19 | `templates/test-verify-memory.md:94` | **DESCRIPTION-FALSE** — fixed in v1.26.0 |
| 20 | `templates/update-drift.md:6` | DESCRIPTION-SUPPORTED |

**2 of 20.** Line numbers are as of the v1.26.0 branch point; items 16 and 19
have since been rewritten, so those two lines will not read as they did when drawn.

Two judgement calls worth preserving, both from the reviewers:

- Item 1 (`every session starts from zero`) is literally the flagged shape and was
  let stand: the only available repair is to hedge it to *most* sessions, which
  would be weaker **and** less true. **When the only available repair is a vacuous
  hedge, the finding is spurious.**
- Support-at-a-distance, not absence of support, is the dominant reason a line reads
  as "bare" — the extractor is line-scoped while support is written at paragraph
  scale. That is the #45 line-scoping defect, rebuilt while auditing for it.
