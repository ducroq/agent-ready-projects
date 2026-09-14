# Seeded Defects and Ablations

**A check that finds nothing has told you nothing.** It might be working and the code
might be clean. It might be broken. It might be pointed at an empty population. From the
outside those are the same result: silence, and an exit code of zero.

This page describes the two cheap instruments that tell them apart. They are, by this
framework's own record, the part of it with the most catches recorded — and they are not
specific to any tool, language, or agent.

## The problem, concretely

Every example below is real and from this repository. The first three are checks that were
green while broken; the fourth is the neighbouring failure — a thing that was never exercised
at all, which is how a check gets to be green without ever having been tested.

- A structural rule matched **0 of 4** of the references it existed to validate, for its
  entire life. It was green from both directions: a second loop happened to cover the same
  ground, so nothing ever disagreed.
- A rule comparing a template against its installed copy passed for **eight releases**
  while the thing it compared was a shell syntax error. Both copies carried the same
  defect, so they agreed perfectly.
- A guard was added, reviewed, and merged that **could not fail** — no input existed that
  would make it fire.
- A test-suite family shipped for months having **never been run** against the system it
  claimed to test. Its own README disclosed this; it was archived rather than fixed once
  someone re-read it.

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

⚠️ **An ablation cannot fail if its kill-set is already failing.** This is the subtler
sibling of the rule above, and it is the one that bit us. A typical ablation scores a
case by *reported* against *silent*: mutate the check, and the case that should now go
undetected must go silent. But if the unmutated check is **already** reporting on that
case — because the guarantee is broken in the shipped code — then both the original and
the mutant report, the sets match, and the ablation prints PASS. It is green precisely
*because* the thing it guards is broken.

We shipped that. A BOM-stripping guard was written with a length in units two `awk`
implementations disagree about; it worked on the maintainer's machine and failed on CI.
On the CI run where the guard was broken, the seeded case FAILED and its ablation
**PASSED**, in the same log, four lines apart. The ablation was not measuring the guard;
it was measuring whether the case reported at all, which it did, wrongly.

Two things follow. **Read an ablation's PASS together with its own seeded case** — a PASS
beside a FAIL on the same case is not evidence, it is an artefact. And **an ablation is
only meaningful over an otherwise-green suite**, so a run with any failure should not be
read for ablation results at all.

## What these instruments cannot do

This is the part most write-ups omit, and it decides how much your numbers are worth.

**Your seeds are the defects you thought of.** Recall against them is a *lower bound* and
never a certificate. A check that scores perfectly has shown it catches known classes; it
has shown nothing about the classes nobody imagined — which is where the expensive
failures live.

That limit is not hypothetical, and it is not only ours:

- Three successive drafts of one check here each **passed their own fixture** and were each
  refuted by running them over a real corpus — 28 false hits, then 15, then 1.
- Just et al., *Are Mutants a Valid Substitute for Real Faults in Software Testing?* (FSE 2014,
  [ACM](https://dl.acm.org/doi/10.1145/2635868.2635929)) examined 357 real faults across five
  projects and found mutation score does correlate with real-fault detection — but only about
  **73%** of real faults were coupled to standard mutation operators at all, and the correlation
  is an aggregate, not a warrant for any individual mutant's realism.
- *Bigger Isn't Always Better* ([arXiv](https://arxiv.org/html/2606.15689v1), 2026) measured LLM
  code reviewers at **F1 0.847 on synthetic mutated samples against 0.066 on real pull requests**
  — a ~92% degradation from synthetic to real.
- The much older software-inspection literature on defect seeding reached the same warning first:
  estimates are biased unless seeded and naturally-occurring defects are **equally detectable**
  ([capture-recapture after ten years](https://www.researchgate.net/publication/222300754_Capture-recapture_in_software_inspections_after_10_years_research_-_Theory_evaluation_and_application)).

*(All three are reported here with their sources; none is a measurement made by this framework.
Its own numbers are the ones above, from this repository.)*

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

## The general case: a guard that measures something ADJACENT to its claim

The two rules above are about reading an *ablation's* result. This is the same failure without
an ablation anywhere, and it is the one you will meet in your own code first.

**A guard can measure something genuinely next to the claim it is taken as evidence for.** That
adjacency is the whole problem: a guard measuring *nothing* looks wrong immediately, so nobody
ships it. These look right, return a plausible number, and are wrong.

Seven instances across two independent estates in one day, none of them ablations and none
reachable by a lexer:

| what the guard measured | what it was read as proving |
|---|---|
| PDF byte size | PDF content — an error page passed as a success for a week |
| `git status` file list | that the content changed — a file already listed stays listed |
| `grep -c` over an alternation | which of the alternatives matched |
| the review tier assigned | the real population — tiers written over gitignored paths |
| a `grep -v` filter | the content field — it matched the path prefix and excluded the file under test |
| a cited phrase | the file the phrase had been moved out of |
| a printed verdict word | the exit status, which was never set |

**The move that settles all seven is one sentence: state what a positive looks like, then
produce one.** A guard that has never been shown failing has been *read*, not tested.

### The sub-shape worth its own name: an instrument that could not have found what it was pointed at

Three of the seven were this, and it is the one that survives review, because the output is a
number and the number is plausible.

A sweep for use-before-assign returned "no first-use found" for every variable in a script that
plainly uses them. The search pattern was `"\$$v"`. Re-run correctly with a bracket expression,
`"[\$]{\?$v"`, the same sweep saw 47 references and caught a seeded case.

⚠️ **Then the diagnosis was wrong in a way that would have propagated the bug.** It was first
explained as *"`$$` is the shell's PID"*. It is not — the backslash escapes the first `$`, so
the pair never forms:

```bash
v=FOO
printf '%s\n' "\$$v"    # -> $FOO        the escaped form: no PID
printf '%s\n' "$$v"     # -> 796764v     the PID appears only when UNescaped
```

The pattern really was `$FOO`, and it matched nothing for an unrelated reason — that `$` was
read as an end-of-line anchor. ⚠️ **And here a third factor appeared, which is why this example
is written out in full rather than asserted: the two greps disagree.**

```bash
printf 'line with $FOO in it\n' > s.txt

grep -c '$FOO'   s.txt   # ugrep 7.8.4 -> 0     GNU grep 3.12 -> 1
grep -c '\$FOO'  s.txt   # both -> 1
grep -c '[$]FOO' s.txt   # both -> 1
```

An unescaped mid-pattern `$` is **engine-dependent**, and `grep` on the machine where this was
found is a shell function shimming to ugrep while GNU grep sits at `/usr/bin/grep`. A first
draft of this very section reported the `0` as a plain fact, because that is what the shim
returned — an absolute in a description, shipped without its scope, in the document about
instruments being wrong. Run `grep --version` before trusting either number.

**The consequence is bigger than the example.** Any check invoked as bare `grep` runs whichever
engine the reader's shell resolves, not the one it was written and seeded against. A rule
containing an unescaped mid-pattern `$` can therefore return a clean zero on one machine and a
correct count on another — and by the doctrine of this whole page, a rule that cannot match is
indistinguishable from a rule with nothing to find. Escape it, or bracket it.

The bracket expression fixes it by making `$` literal **to the regex engine**, not by
suppressing a PID. The repair was correct and the explanation was not — so a reader who takes
away *"beware `$$`"* escapes the dollar, still gets zero, and concludes the sweep is clean.
**When an instrument is repaired, check that its explanation was repaired too; the explanation
is what the next person reuses.**

### The rule

> **A sweep returning ZERO must be shown finding something before its zero is believed.**

That is the seeded-positive discipline of this whole page, pointed at the checker instead of at
the code. It costs one deliberately broken input.

⚠️ **A sweep is a one-time check; a language guard is standing.** `set -euo pipefail` at the top
of a shell script makes the use-before-assign class fail loudly instead of silently, and no
sweep is a substitute for it. Use both: the guard for the code you will write tomorrow, the
sweep for the code already there.

### Why this is documentation and not a rule in your linter

We looked. The lexical cousins *are* mechanizable and we ship a rule for them — a mutation equal
to its target, an empty expected kill set. This class is **semantic**: whether `git status`
answers "did the content change" depends on what the claim was, and no pattern over the text
reaches that. Two candidate lint rules were built and declined here after measurement. Expect to
catch these by asking the question, not by running something.

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
