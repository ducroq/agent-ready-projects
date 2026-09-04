# Reference-integrity fixture (audit-context Step 4)

Step 4 decides which documentation references are broken. Every past change to
it has been justified by "the old version reported N false positives" — a
statistic that measures **specificity** and says nothing about **sensitivity**.
Twice that reasoning shipped defects. This fixture exists so the sensitivity
half is testable.

    bash run.sh          # exits non-zero on a sensitivity regression

## What it seeds

**Case counts, re-measured 2026-09-03** (`grep -oE '\bT[0-9]+[a-z]?\b' run.sh | sort -u | wc -l`, and the same for `N`): **27 T-cases** and **28 N-cases**; `grep -c '^ablate "' run.sh` gives **12 ablations**. #102 added T28, T29 and N32. The numbering is not contiguous and cannot be written as a range — there is no T6, T20, N4, N5 or N29–N31 — so quote the command, never a span. ⚠️ **T28 and T29 are needled on the PATH, not the reason**, which T21's rule normally forbids: the oracle prints `UNRESOLVED` both when the gate declines a reference and when the target is absent, so no reason string separates them, and a needle carrying the reason is keyed on column padding that moves with the path length. The discriminator is an existence check on the two target files instead. The enumeration below is the original eleven and is kept for the reasoning, not as a census; treat any number in prose here as dated unless it carries a command.

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

## The exit-status table (X1–X16, added for #93)

Everything above asserts what the report **says**. Nothing asserted what the run
**returns** — `run.sh` discarded the status with `|| true` at all three call
sites — so the gate itself was untested while the report it prints was covered
54 named cases deep (`grep -oE '\bT[0-9]+[a-z]?\b' run.sh | sort -u | wc -l`
plus the same for `N`, plus D1 and E1 — the printed report emits more lines than
that, so the number is only reproducible with that method).

Step 4 has three outcomes, not two: defects, clean, and *coverage incomplete*
when nothing was ruled on but something was left undecided because rung 4 had no
neighbouring repo to run against. Read the rows as one table, because none of
them carries the change alone — exit 2 is wrong in two opposite directions, and
each row forbids one cheap way of reaching another row's answer.

Every row **except X10 and X16** asserts the exit **status** and the verdict
**label** — X10 is an isolation guard and X16 an enumeration guard; neither
asserts a status. The status alone is not enough: a
review swapped all three labels while leaving every `rc` untouched and every row
stayed green, which is T19's lesson one layer up.

**X11/X12 are the control for round 3's finding.** An angle-bracket segment is
decided by a regex over the fragment and nothing on disk, so rung 4 declines it
with every neighbour reachable and its verdict does not depend on whether one is.
Round 2 put it in the undecided bucket anyway, which moved a repo whose only
references are placeholders of that shape — including this one — from exit 0 to
exit 2 in a fresh clone. Round 3 fixed it and tested the marker before the shape,
so a path carrying **both** forms — which this step tells authors to write — did
the same thing. X13/X14 seed that path and A8/A9 hold the ordering from both
sides. **X15/X16 are round 4's**: no row produced a confirmed finding and an
undecided reference in one run, so the verdict's undecided clause could be
deleted green; and nothing asserted the undecided were *enumerated*, so the whole
section could be deleted green while 33 references vanished from every count —
33 being what a NO-NEIGHBOUR run of the main fixture leaves undecided. The run
this harness performs pins `--sibling-root` to 3 siblings, where that total is 0
by construction, so the deletion drops nothing there; X16 is the guard that
actually bites, and it runs `mixed.md` against an empty sibling root (#97).

**X8/X9 are the pair a review found missing.** A `<!-- placeholder -->` on a
cross-repo path is rung-4 traffic too — with the neighbour on disk it is a stale
marker, without one the test cannot run — so excusing it silently exited 0 on a
repo a reachable neighbour would have reported. The first draft of this change
had that hole and its own prose called it the worse direction.

**X10 is an isolation guard**, added because this change broke isolation once.
`exitcodes/repo` sits at `*/*` from the fixture root, which is the main run's
`--sibling-root`, so a `.git` in it made the main fixture scan a fourth
neighbour named `repo` — a token in 13 lines of this fixture's prose, since a
hyphen is a token boundary and every `sibling-repo` contains it. It sorted first
into a loop that breaks on the first hit. Nothing failed; a probe document
flipped from a reported break to a clean rung-4 resolution.

**The ablations are committed, not described.** The prose form of that claim was
reconstructed by two reviewers who got different row counts under equally
natural readings of two mutants — and a third of them, A1, turned out to kill one
row where its author had predicted two. `ablate()` pins the exact replacement
text, fails if the site has moved or the mutation is a no-op, and asserts the
exact set of rows that must go red. ⚠️ **X1, X5, X8, X11 and X13 are killed by none of the
ten.** They are shape coverage, not guards: each pins the neighbours-reachable
half of a pair so its twin's PASS cannot read as environment-independent by
accident.

## Why these cases

T7–T11 are the ones that matter. They are the failures a *permissive* change
newly lets through, and they are exactly what a "does it still find the old
breaks?" fixture omits. v1.15.1's first attempt passed 7/7 against such a
fixture while carrying six defects; these cases are what caught them.

If you make Step 4 more permissive, add the failure your change newly permits
to `build.sh` **before** you change the rule.
