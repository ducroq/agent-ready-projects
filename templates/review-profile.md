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
