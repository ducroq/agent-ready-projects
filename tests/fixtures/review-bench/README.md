# review-bench — a seeded-defect benchmark for the *review process*

Every other fixture here measures a **checker**. This one measures the **review**:
whether a given review configuration finds defects that are known to be present.

It exists because the scope knob was being turned on anecdote. After 2026-08-27,
narrow-scope review was adopted as the default on the strength of **one** run that
happened to find the worst defect of the day. That is not evidence, and this
harness is what would make it evidence. Registered as **H-016**.

## What it contains

| variant | carries | purpose |
|---|---|---|
| `seeded/` | D2–D7 | recall |
| `seeded-silent/` | D1 alone | recall, isolated |
| `clean/` | nothing | precision — any finding is a false positive |

`D1` is isolated because it **masks D7**: a loop that never runs cannot also drop
an item, and a seeded defect that hides another would silently inflate every
config's apparent recall.

The seven classes are drawn from defects that **actually bit this repo**, not from
imagination — silent-zero, unhedged absolute, stale restatement, unmeasured count,
vacuous ablation, false table row, silent drop. See `manifest.tsv`.

`build.sh` verifies every seed is present **and** that the control carries none of
them, and fails the build otherwise. A replace that silently matched nothing would
produce a benchmark where every config scores 100% against defects that are not
there — this harness's own failure mode, inside itself.

## Protocol

1. `bash build.sh <dest>`
2. Give the reviewer **one variant**, never the manifest, and never this README.
3. Collect findings as one per line, beginning `path/to/file:LINE`.
4. `bash score.sh <findings-file> <variant>`

Record `(config, variant, recall, false positives, tokens, wall-clock)` in the
review ledger. Configurations worth comparing, **including the control**:

```
no-review (suite only)   <- the baseline; a config that does not beat this is not paying
broad-cold
narrow-cold
narrow-fork
```

## Threats to validity — read these before believing a number

1. **The seeds are the defects the author thought of.** This is the same blind
   spot fixtures have, and it is not hypothetical here: on 2026-08-27 three drafts
   of an emphasis check each passed their own fixture and were refuted by the real
   corpus (28 false hits, then 15, then 1). **Treat any recall number as a lower
   bound, never as a certificate.** A config that scores well here has shown it
   catches known classes; it has shown nothing about unknown-unknowns, which is
   precisely what a broad review is supposed to buy.
2. **Agent variance.** The same config twice gives different results. No claim
   from fewer than 3 runs per config.
3. **Contamination.** Do not run against this repo's real history: a reviewer can
   read the fix in later commits or in `CHANGELOG.md`. The corpus is synthetic for
   this reason.
4. **n=1 repo.** Prose-heavy, single maintainer, one domain. Nothing here
   generalises to a code-heavy repo without re-measuring.
5. **The author scores their own experiment.** `score.sh` is mechanical and the
   manifest is written before any run, which is the whole mitigation.
6. **Precision has been suspiciously perfect.** Across five reviews on 2026-08-27,
   ~38 findings and **zero** rejected. A reviewer optimising for precision is a
   reviewer with poor recall; the `clean/` variant is what tests that directly.
