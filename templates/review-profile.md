# Review Profile

<!-- SAVE AS: .claude/review-profile.md (in the project being reviewed)
     Read by the review-changes skill at Step 1. One per repo; never user-global
     (the skill is global, this file is the repo-specific half). -->

Read by `review-changes` Step 1. **This file is your project's half of that skill.** The
skill ships identically to every project and is re-copied on each framework release;
everything in this file is yours and never travels.

⛔ **The skill STOPS if this file is absent.** That is deliberate. With no profile every
path falls through to LOW, which is indistinguishable from a review that ran and found the
change unimportant — the one failure a review tool must not have. Write this file before
first use.

## Risk tiers

Replace every pattern below with paths that exist in YOUR tree. ⚠️ **Copying the framework's
own profile verbatim classifies all your changes as LOW**, because none of its paths exist
in your repo.

| Tier | File patterns | Depth |
|------|-------------|-------|
| **HIGH** | *paths whose breakage reaches a consumer you cannot fix: published schemas, deployed scripts, anything copied into another tree, `.gitignore`* | Full battery (3-4 lenses) |
| **MEDIUM** | *paths that matter but fail locally and visibly* | Two lenses (adversarial + doc-accuracy) |
| **LOW** | *paths where a defect costs a re-read: changelogs, memory, notes* | One lens (adversarial) |

`**` crosses directory levels; a leading `/` anchors to the repo root. **The most specific
matching pattern wins.** Where no pattern is more specific than another, take the highest tier.

### Consider a cheaper HIGH — an option, not the default

The framework's own repo runs HIGH as **one adversarial lens plus two conditional ones**
(guarantee-preservation when the diff touches a declared guarantee surface, shell-correctness when
it changes a shell file) and measured a large drop in review spend. **It is an option, not a default: the evidence
does not support moving yours**, and the measurements are at
<https://github.com/ducroq/agent-ready-projects/blob/master/docs/rationale/review-changes.md> <!-- lint-skip: maintainer-path — a URL, not a repo-relative path: it resolves for a reader with no such directory. -->
rather than inlined here.

If you take it, three things are not optional:

- **Keep both conditional lenses.** Each is HIGH-gated in the skill, so a HIGH row naming neither
  retires them silently. Losing shell-correctness "is the reason those paths are HIGH at all", and a
  guarantee that can never fire renders as a clean pass. Both are conditional, so neither costs
  anything on a diff that does not trigger it.
- **Re-tier MEDIUM in the same edit, or you invert your own ladder.** MEDIUM is two lenses. A HIGH
  path that is neither shell nor a declared guarantee surface would then get *one* — so the skill's
  instruction to escalate shipped content from MEDIUM to HIGH would *lower* its depth, and the
  always-full-depth carve-outs would resolve to what a changelog edit gets.
- **Decide it per tier.** One lens where a defect costs a re-read; the battery where it reaches
  someone who will not re-run it.

⚠️ **What the framework's own measurement cannot tell you**: its two one-lens runs both found
blockers, but their *recall* is unmeasured and permanently unmeasurable — the round cap that shipped
alongside means no second round will ever classify what they missed. Against that, on a four-lens
round two lenses each found a blocker no other lens found. Treat the saving as measured, the safety as not.

## Guarantee surfaces

⚠️ **Every path here must sit in the HIGH row above.** The guarantee lens is HIGH-gated, so a
guarantee on a lower-tiered path can never fire — and the report renders that as a clean pass.
Check it in this direction: read each entry here, then find its tier above.

- `path/to/surface`: *what it guarantees to whoever consumes it*

## Test baseline

The exact command that produces a trustworthy baseline. ⚠️ Name the interpreter if a bare one
is wrong — a wrong interpreter yields a phantom failure baseline that gets believed.

```bash
# e.g. venv/bin/python -m pytest tests/ --ignore=tests/integration
```

## Always-full-depth carve-outs (project additions)

The skill's own carve-outs (`.gitignore`, renames, mode changes, binaries, submodules) always
apply and cannot be removed here. Add project-specific ones — files whose danger is inverse to
their size:

- `path/to/file`: *why a few bytes here is a large change*

## Project lenses

Extra lenses this project runs, and when. **The skill's own lens set always runs too** — this
section adds, it never replaces. One per entry: the name, the trigger, and the prompt the
subagent gets.

⚠️ **This section exists because the v1.40.0 split silently lost an ADOPTER's lens** — the
framework's own four were unchanged across that release. The skill refuses on a *missing*
profile and cannot tell a complete one from a half-ported one, so a lens that is not written
here is not run and nothing says so (#166).

- `lens-name` — fires on: `path/glob/**`
  *The prompt. What it must refute, and what a positive looks like.*

## Project additions to the shipped lens prompts

Text appended to the shipped `adversarial` / `doc-accuracy` / `guarantee-preservation` prompts
for this project. Use this when a shipped lens is *right* but needs local vocabulary, rather
than forking it into a project lens.

- **adversarial**: *what to attack here that the generic prompt would not know to*

## Project procedure kept with the profile

Some of a project's half is **procedure, not data** — a local extractor, an extra parse check.
The split assumed tiers, paths and guarantees. Put procedure here and point the project file at
it, rather than leaving it in a skill that is no longer read.
