# Release

<!-- SAVE AS: .claude/skills/release/SKILL.md (Claude Code)
     For other tools, run this as a release-time prompt manually.

     This is a skill (/release) that walks a version release: classify the
     bump, verify preconditions, write the changelog entry, sync version
     references, commit — and stop before publishing. The judgment it
     encodes is the bump decision, the part that drifts when it lives only
     in a prose header.

     Note `disable-model-invocation: true` below — unlike curate and
     review-changes, this skill is deliberately user-invocable only
     (/release), never model-invoked. An agent deciding on its own that
     it's time to cut a release is a failure the Step 6 stop-gate cannot
     catch, because by then the release is already being cut. The two
     mechanisms cover different things: the flag governs whether the skill
     starts, Step 6 governs whether it publishes. Tools without an
     equivalent flag (Codex, Cursor, Windsurf, Copilot, Aider) have only
     the Step 6 gate — there, run this template deliberately, never as
     part of a broader "wrap up the release" instruction.

     ---
     name: release
     description: Cut a version release — classify the semver bump, verify preconditions, write the changelog entry, sync version references, commit. Stops before tagging or pushing.
     disable-model-invocation: true
     --- -->

Cut a release. Work through the steps in order and **stop at the end of Step 6** — publishing is the engineer's call, never the agent's. Step 7 runs only after the engineer confirms the push.

Before starting, read **both** the project file (the auto-loaded Layer-1 file — `CLAUDE.md`, `AGENTS.md`, or your tool's equivalent) and the project's changelog header. Projects record release preconditions in the former and release mechanics in the latter. If either conflicts with anything below, **the project's own process wins** — say so explicitly in your report rather than silently following this template.

## Step 0 — Substitute the version placeholder

Every command below is written with a literal `X.Y.Z`. Substitute the actual version before running anything.

This matters more than it looks. `git rev-parse "vX.Y.Z"` and a grep for `X\.Y\.Z` both **succeed quietly** against an unsubstituted placeholder — they report "tag free" and "no stale references", which is exactly what a healthy release looks like. If any command in this skill emits the literal string `X.Y.Z`, you did not substitute it: stop and start over.

You will not know the version number until Step 2. Run Step 1 first, agree the version, then substitute throughout.

## Step 1 — Establish what changed

```bash
# The highest RELEASE tag reachable from HEAD. Every diff below is computed
# against it, so a wrong answer here mis-scopes the entire release silently.
git tag --sort=-v:refname --merged HEAD --list 'v[0-9]*' | sed '/-/d' | head -1
git log <last-tag>..HEAD --oneline      # commits since
git diff <last-tag>..HEAD --stat        # files touched
```

Each part of that selector rules out a tag that is not this release's baseline. All four failure states are real, not hypothetical — each is a seeded case in this framework's own installer fixture (`tests/fixtures/installer-release-guard/`): the scratch tag and the prerelease as states the guard **refuses**, the hotfix and unmerged-branch cases as states it must get right *without* refusing.

| Part | What a bare `git tag --sort=-v:refname \| head -1` does without it |
|---|---|
| `--sort=-v:refname`, **not** `git describe --abbrev=0` | `describe` returns the *nearest* tag rather than the highest: after a hotfix tagged `v1.0.1` merges in behind `v1.1.0` it answers `v1.0.1` |
| `--merged HEAD` | a tag on an unmerged branch — a co-maintainer's release-in-progress — becomes your baseline, and the diff is wrong in both directions at once |
| `--list 'v[0-9]*'` | a scratch tag (`wip`, `zz-backup`) sorts in and wins — measured. A name sorting *below* `v`, like `before-refactor`, happens not to win, which is luck rather than protection. Note `v2-spike` is **not** an example here: it matches the glob and is dropped by the row below |
| `sed '/-/d'` | a prerelease (`v1.1.0-rc1`) becomes the baseline, so the changelog covers only what changed since the rc — and omits everything an adopter pinned at the last stable release still needs to read |

**Read the output before using it.** An empty answer has two causes, and they take opposite fixes. Check them in this order — **a bare `git tag` is not the test**, because a shallow clone can list no tags at all and so looks exactly like a first release:

- **A shallow clone** — `git rev-parse --is-shallow-repository` answers `true`. `--merged HEAD` walks history and a `--depth` clone truncated it, so tags that are present may be unreachable, and a plain `--depth 1` clone usually has no tag refs at all. `git fetch --tags` is not a reliable fix: it adds refs, not the history that reaches them. Run **`git fetch --unshallow`**, which restores both. Expect this in CI, where a shallow checkout is usually the default. Shallow does not *always* mean empty — `--depth 1 --branch <tag>` resolves fine — so treat `true` as "unshallow before concluding anything", not as a verdict.
- **A tag scheme these filters do not match** — most likely hyphenated CalVer (`v2026-08-11`), which the prerelease filter drops. Widen the filter for your project.

Do not continue past an empty answer in either case. It is indistinguishable from a first release, and the next paragraph would then have you cut `v0.1.0` over a project with a hundred releases behind it.

**If there are genuinely no tags** — `git rev-parse --is-shallow-repository` says `false` *and* `git tag` is empty — this is a first release.

Group the changed files by surface:

- **Normative surfaces** — anything downstream consumers install, import, or depend on (templates, public API, exported config, schemas)
- **Documentation** — guides, references, rationale docs, READMEs
- **Internal** — tests, maintainer tooling, CI, project memory

If nothing changed since the last tag, report that and stop.

## Step 2 — Classify the bump

| Bump | When | Examples |
|------|------|----------|
| **MAJOR** | Existing consumers must take action to stay working | Removed or renamed a normative artifact; changed required structure; behavior change that breaks existing usage |
| **MINOR** | New capability, additive and optional | New template, new pattern, new behavior, new documented convention |
| **PATCH** | Nothing new to adopt | Documentation-only changes, clarifications, cross-references, corrections, refinements to existing artifacts |

Apply these two rules **in order** — the first one that fires decides:

1. **Does any existing consumer have to do something to keep working?** If yes, MAJOR. This outranks everything below: a "refinement" that changes a required structure is MAJOR, however small the diff.
2. **Otherwise: is there a new artifact to adopt, or only changes to existing ones?** New artifact (file, pattern, documented behavior) → MINOR. Changes confined to existing artifacts → PATCH. Rewriting half of an existing template is still PATCH, provided rule 1 didn't already fire.

State the proposed bump **with the reason**, and ask the engineer to confirm before continuing. Do not proceed on a guessed version number.

If the project's changelog records prior bump decisions, cite the closest precedent rather than re-deriving the rule. Where a precedent and these rules disagree, follow the precedent and flag the discrepancy.

## Step 3 — Verify preconditions

Run every check and report the results. **Do not continue past a failure** — surface it and stop.

1. **Clean tree**: `git status --porcelain` returns empty. Uncommitted work must not be in a tagged release.
2. **Right branch**: `git rev-parse --abbrev-ref HEAD` matches the project's release branch — the default branch unless the project says otherwise. If it doesn't match, stop and ask.
3. **Tag is free**, locally *and* on the remote. A tag a co-maintainer already pushed is invisible to a local-only check, and the remote is where "already published" is actually decided.
4. **Tests pass**: run the project's test and lint commands, as named in the project file. Report actual output. Never report a check as passing without running it — and if you cannot find a test command, report **"no test command found"** as a *failure to verify*, not a pass, and ask the engineer.
5. **Version references located**: find every file carrying the *current* version. These are the files Step 5 must update.

```bash
git status --porcelain
git rev-parse --abbrev-ref HEAD

# Tag free? Anchor to refs/tags — a bare `git rev-parse vX.Y.Z` also matches
# a *branch* named vX.Y.Z and would block a legitimate release.
git rev-parse --verify --quiet "refs/tags/vX.Y.Z" && echo "LOCAL TAG EXISTS — STOP" || echo "local: free"
git ls-remote --exit-code --tags origin "refs/tags/vX.Y.Z" && echo "REMOTE TAG EXISTS — STOP" || echo "remote: free"

# Version references. Use git grep: it is gitignore-aware (skips node_modules/,
# vendor/, .venv/), repo-root-relative rather than cwd-relative, and excludes by
# PATH. A content-based `| grep -v CHANGELOG` would drop any line that merely
# links to the changelog — which is exactly how version badges are usually
# written ("**Version 1.2.3** | [Changelog](CHANGELOG.md)"), silently hiding
# the most visible version reference in the project.
git grep -n "1\.2\.3" -- ':!CHANGELOG.md'

# Then sweep VERSION-AGNOSTICALLY. This is the only check that finds a file stuck
# two releases back — the grep above cannot, because such a file does not contain
# the current version. Do NOT do this by matching any version-shaped number: in a
# repo with a lockfile that returns hundreds of dependency pins, and lockfiles are
# committed, so git grep's gitignore-awareness does not save you. An agent facing
# that output will rationally skip the check.
#
# Match the two things that actually carry your version instead. Substitute your
# own project name in the first pattern.
git grep -nE "your-project-name v?[0-9]+\.[0-9]+" -- ':!CHANGELOG.md'
git grep -niE "version[\"': ]*v?[0-9]+\.[0-9]+" -- ':!CHANGELOG.md' ':!*.lock' ':!*lock.json'

# Two-component versions (v1.13) are matched by design; a bare
# `[0-9]+\.[0-9]+\.[0-9]+` would miss them.
```

Search **all** file types, not just `*.md`. Version strings live in `package.json`, `pyproject.toml`, `Cargo.toml`, `setup.py`, `__init__.py`, `docs/conf.py`, and CI configs — the manifests Step 5 has to update. Restricting the search to Markdown is the most common way a release ships with a manifest still on the old version.

Two things this check cannot do, which you must cover by reading:

- The first grep finds only references already at the *current* version, which is why the version-agnostic greps follow it. **Templates and scaffolding files are the usual victims:** nobody edits them during a normal release, so they never show up in a current-version grep and never get touched. A file that should carry a version but doesn't will not appear in any of these greps; compare against the file list from the previous release if there is one.
- Neither grep can distinguish a stale reference from a legitimate historical citation ("the vX.Y.Z precedent") or a deliberately dated snapshot (a published essay, an archived doc). Judge each hit; don't bulk-replace. **The version-agnostic greps are expected to return hits you leave alone** — that is not a failure condition, and unlike the other Step 3 checks they have no pass/fail state to stop on.
- Neither grep sees untracked files. A freshly scaffolded file that has never been `git add`ed is invisible to both. Run `git status --porcelain` alongside them and check any new file by eye.

## Step 4 — Write the changelog entry

**First check how this project's changelog is maintained.** Two conventions are common, and they call for different actions:

- **Candidate-block projects** keep a `vX.Y.Z (candidate, unreleased)` section that accumulates entries during development. Releasing means **promoting** that block — adding the date, not adding a section. Writing a fresh section here leaves a duplicate.
- **Write-at-release projects** have no candidate block; add a new dated section at the top, below the header.

Read the top of the changelog to see which you're in before writing anything.

A complete entry has:

- **Version heading and ISO date** — `## vX.Y.Z (YYYY-MM-DD)`. Required even if recent entries in this changelog lack one; match the *documented* structure, not accumulated drift.
- **Summary line** — what shipped and why, one or two sentences, ending with the bump and its justification
- **Per-surface sections** — one per surface touched, each listing the specific files and what changed in them
- **Consumer notes** — what new consumers get, and what existing consumers must do (say "no action required" explicitly when that's true)
  - ⚠️ **For a copied artifact, name the surgical change and its marker strings — never only "re-copy it".** A consumer who *adapted* the copy cannot re-copy without destroying the adaptation, and theirs is the copy that has diverged furthest — the one most likely to need the fix. List a few strings a current copy must contain, so they can grep however far theirs has drifted, plus the edit that adds them. Shipped twice here before anyone noticed (#94).
- **Versioning rationale** — one or two sentences naming which Step 2 rule fired and the precedent it follows

Follow the *content* shape of recent entries, but don't inherit their structural defects — if the last two entries are missing version headings, that's drift to correct, not a pattern to copy.

Write for someone deciding whether to upgrade. "Updated templates" is useless; "added a new required field to X, existing files without it still work" is what they need.

## Step 5 — Sync version references

Update the files found in Step 3, check 5, **that are meant to track the current version** — not every hit. Check 5's second grep deliberately surfaces hits you leave alone (historical citations, dated snapshots, dependency pins); rewriting those is the failure mode Step 3 warned about. Typically in scope:

- The project file's version line
- Any README or docs version badge
- Package or manifest version fields
- **Any template or scaffolding file that stamps the framework version.** These are the ones releases habitually miss: nobody edits them during a normal release, so they never appear in a current-version grep, and they ship stamped at whatever release last happened to touch them. A new adopter then scaffolds from them and inherits a stamp that misdescribes the files they just got.

Afterward, re-run the **current-version** grep from Step 3 and confirm the only hits are files you intended to update. Do not try to drive the version-agnostic greps to zero output — they never reach zero in a real repo, and an agent chasing that exit criterion will either loop or start rewriting historical references to make it quiet.

## Step 6 — Commit, then stop

Stage **only** the files this release touched — the changelog plus the files enumerated in Step 3, check 5:

```bash
# lint-skip: not-executable — `<each file updated in Step 5>` is a placeholder
# the engineer fills in, so this block cannot parse by design (rule 11).
git add CHANGELOG.md <each file updated in Step 5>
git status --porcelain          # confirm nothing unexpected is staged
git commit -m "release: vX.Y.Z"
```

Do not use `git add -A`. Step 3 verified a clean tree, but Steps 4 and 5 wrote files and any scratch work landed in between; `-A` stages every untracked, unignored file in the repo into the commit the tag will permanently point at.

Then **stop and report**:

- The proposed tag and the commit it points at
- The exact commands the engineer should run (below)
- A one-line summary of what the release contains

**Do not run the following. They are for the engineer to copy.** A pushed tag is public and effectively permanent — consumers pin to it, and deleting a published tag breaks them. Approval to cut a release is not approval to publish it.

    # DO NOT RUN — hand these to the engineer
    # -a makes an annotated tag (tagger, date, message, signable). A lightweight
    #    tag has no metadata and is treated differently by git describe and by
    #    release tooling.
    # push a single ref, NOT --tags: `git push --tags` publishes every local tag,
    #    including wip-* and private scratch tags, permanently.
    git tag -a vX.Y.Z <commit> -m "vX.Y.Z"
    git push origin vX.Y.Z

## Step 7 — After the tag is pushed

Only once the engineer confirms the push:

1. **Verify the tag is actually live**, with an exact-ref check:

   ```bash
   git ls-remote --exit-code --tags origin "refs/tags/vX.Y.Z"
   ```

   Do not use a substring grep.

2. **Refresh any copy of a skill or command installed outside the repo** — a user-level install is not covered by the tag, and refreshing it *before* the tag would have put content no release contains into the copy that shadows every repo. This is the point at which that refresh is safe.
3. ⚠️ **Tell consumers who stamp your version that the stamp is a *number*, not an adjective.** A pinned line reading "we are current with vX.Y.Z" is a state claim about a world that moves, and **your release cadence is what falsifies it** — an adopter cannot see the next tag coming. One adopter had the word *current* become false **within hours** of committing a correct stamp, because two more releases went out the same evening. The stamp was right; the adjective was not. This is `curate` sub-step 5's *a state report decays; a claim does not*, landing on the one line in an always-loaded file that every session of theirs starts from.

4. Update the memory index's current-state entry to the new version — and ⚠️ **rescope the probe on the line you just superseded.** A *current release* claim and a *previous release* claim are different claims: a probe reading "the highest tag equals vX.Y.Z" is true the day it is written and false the moment the next release ships, and it travels down with the line unless you change it. A historical line's probe asserts the tag **exists**. Measured here twice in one day, on three lines the first time — the release process regenerates this defect on every release that does not do it.
5. Close any issue the release resolves
6. If the project tracks work items, fill in the Outcome section of any work item this release completed

## Do not

- **Do not tag with a dirty tree.** The tag would point at a commit that doesn't match what was tested.
- **Do not retag or force-push a tag.** If a released version is wrong, release a new patch version.
- **Do not choose the version number yourself.** Propose it with reasoning; the engineer confirms.
- **Do not claim a check passed without running it.** Report the actual command output. "I couldn't run it" is a valid report; "it passed" without evidence is not.
- **Do not batch unrelated changes into a release** just because they're sitting in the tree. If the diff contains work that isn't part of this release, surface it and ask.
