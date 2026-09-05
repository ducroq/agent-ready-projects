# Seeded Defects and Ablations

**A check that finds nothing has told you nothing.** It might be working and the code
might be clean. It might be broken. It might be pointed at an empty population. From the
outside those are the same result: silence, and an exit code of zero.

This page describes the two cheap instruments that tell them apart. They are the part of
this framework with the most measured catches, and they are not specific to any tool,
language, or agent.

## The problem, concretely

Every example below is a real check in this repository that was green while broken.

- A structural rule matched **0 of 4** of the references it existed to validate, for its
  entire life. It was green from both directions: a second loop happened to cover the same
  ground, so nothing ever disagreed.
- A rule comparing a template against its installed copy passed for **eight releases**
  while the thing it compared was a shell syntax error. Both copies carried the same
  defect, so they agreed perfectly.
- A test-suite family shipped for months having **never been run** against the system it
  claimed to test. Its own README said so; nobody read the README.
- A guard was added, reviewed, and merged that **could not fail** — no input existed that
  would make it fire.

None of these were caught by reading. All of them were caught by *running the check
against known failures* — or by discovering there were none to run against.

## Instrument 1: the seeded-defect fixture

Build a small corpus that **contains the failures the check must catch**, and assert the
check reports every one.

```
fixtures/<check-name>/
  cases/          the corpus: known-bad inputs, plus known-good controls
  manifest        what is seeded, and where — written BEFORE any run
  run.sh          runs the check over the corpus, compares against the manifest
```

Three properties make it worth the effort:

1. **A run that finds nothing is now a failure**, not a pass. This is the whole point.
   The default outcome of a broken check flips from "silence" to "red".
2. **Controls measure the other half.** Clean cases that must *not* report catch a check
   that fires on everything, which is the failure mode of an over-eager rule and is
   invisible if you only seed positives.
3. **The fixture must verify its own seeds.** A find-and-replace that silently matched
   nothing produces a corpus where every run scores 100% against defects that are not
   there. Assert the seeds are present before trusting the score.

⚠️ **Write the manifest before the run, not after.** A manifest edited to match what the
check found is a record of the check's behaviour, not a test of it.

## Instrument 2: the ablation

A fixture proves the check fires on known-bad input. It does **not** prove the check is
what made it fire. For that, break the check on purpose and require the fixture to go red.

```
for each guarantee the check makes:
    mutate the check so that guarantee is removed
    run the fixture
    it MUST fail — if it still passes, that guarantee was never tested
```

This is the same idea as mutation testing, pointed at your checks rather than your code.
It answers a question a green suite cannot: *is this assertion load-bearing, or is it
decoration?*

**A guard that survives its own removal is not a guard.** That failure has occurred here
often enough to warrant its own automated rule.

⚠️ **Every ablation should co-seed a control the mutant must keep passing.** Otherwise an
ablation that breaks the check *globally* looks identical to one that removes the specific
guarantee under test, and you learn nothing about which.

## What these instruments cannot do

This is the part most write-ups omit, and it decides how much your numbers are worth.

**Your seeds are the defects you thought of.** Recall against them is a *lower bound* and
never a certificate. A check that scores perfectly has shown it catches known classes; it
has shown nothing about the classes nobody imagined — which is where the expensive
failures live.

That limit is not hypothetical, and it is not only ours:

- Three successive drafts of one check here each **passed their own fixture** and were each
  refuted by running them over a real corpus — 28 false hits, then 15, then 1.
- In the mutation-testing literature, Just et al. (FSE 2014) examined 357 real faults across
  five projects and found mutation score does correlate with real-fault detection — but only
  about **73%** of real faults were coupled to standard mutation operators at all, and the
  correlation is an aggregate, not a warrant for any individual mutant's realism.
- One 2026 evaluation of LLM code reviewers measured **F1 0.847 on synthetic mutated samples
  against 0.066 on real pull requests** — a ~92% degradation from synthetic to real.
- The much older software-inspection literature on defect seeding reached the same warning
  first: estimates are biased unless seeded and naturally-occurring defects are **equally
  detectable**.

**So: use fixtures to stop checks from rotting silently. Do not use them to certify that a
check is sufficient.** Those are different claims, and conflating them is how a fixture
becomes a comfort blanket.

⚠️ **The sharpest failure of all is a fixture written by the author of the change it
justifies.** When a check is *loosened*, the natural fixture demonstrates the false
positives that motivated the loosening — a sample containing zero true positives, which
measures specificity and cannot measure sensitivity at all. It will pass. It proves
nothing. It happened here: a case was written asserting a hole was *correct*, and applying
the proper fix turned that fixture red.

**Whenever a change makes a check more permissive, seed the failures it must still catch —
and get those from someone other than the person who wrote the change.**

## Starting small

You do not need a harness. The minimum viable version is a directory of known-bad files and
a script that greps for the expected report:

1. Take the last real defect your check was built for. Save the input that triggered it.
2. Add a clean file that must stay silent.
3. Write a script that runs the check over both and exits non-zero if either is wrong.
4. Once it passes, break the check on purpose and confirm the script goes red.

Step 4 is the one people skip, and it is the one that has caught the most here.

Grow it the same way: **every time a defect escapes, add the case that would have caught
it** — before fixing the defect, so you see the fixture fail first. A fixture that has
never been red has never been tested either.

## Related

- [Verification Rationale](verification-rationale.md) — the structural principles behind
  multi-pass verification, and where they do and do not apply.
- [Verifying What We Write](verifying-what-we-write.md) — the same discipline applied to
  prose claims rather than to code.
