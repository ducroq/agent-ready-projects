# Reference-integrity fixture (audit-context Step 4)

Step 4 decides which documentation references are broken. Every past change to
it has been justified by "the old version reported N false positives" — a
statistic that measures **specificity** and says nothing about **sensitivity**.
Twice that reasoning shipped defects. This fixture exists so the sensitivity
half is testable.

    bash run.sh          # exits non-zero on a sensitivity regression

## What it seeds

**Case counts, measured 2026-08-26** (`grep -oE '\bT[0-9]+[a-z]?\b' run.sh | sort -u | wc -l`, and the same for `N`): **25 T-cases** — T1–T27 with no T6 or T20 — and **27 N-cases**, N2–N28b. The enumeration below is the original eleven and is kept for the reasoning, not as a census; it went four releases without being re-counted, so treat any number in prose here as dated unless it carries a command.

The original eleven genuine breaks that must be reported:

| case | what it proves |
|---|---|
| T1 | a fabricated path is caught |
| T2 | a bare basename matching two local files is a collision, not a resolution |
| T3 | a fabricated path under a **gitignored** directory is still caught |
| T4 | a path existing only in a neighbouring repo, **unmarked**, is a coincidence |
| T5 | a real move that changes the parent directory is caught |
| T7 | a path may not supply its **own** cross-repo marker (`docs/DEPLOY.md` + a sibling repo named `docs`) |
| T8 | the marker is a whole token — "infrastructure" must not mark `infra` |
| T9 | two files inside a sibling matching one fragment is an ambiguity |
| T10 | a **deletion** whose same-suffix twin survives elsewhere must stay visible |
| T11 | references whose extension is outside the whitelist must not vanish silently (×2) |

Five that must stay silent: a hostname (N2), a prose deletion marker (N3), a
negated existence assertion (N6), a struck path (N7) — and, the one that makes
span-scoping load-bearing, N7's **live successor named on the same line**, which
line-scoped skipping would have dropped.

## Why these cases

T7–T11 are the ones that matter. They are the failures a *permissive* change
newly lets through, and they are exactly what a "does it still find the old
breaks?" fixture omits. v1.15.1's first attempt passed 7/7 against such a
fixture while carrying six defects; these cases are what caught them.

If you make Step 4 more permissive, add the failure your change newly permits
to `build.sh` **before** you change the rule.
