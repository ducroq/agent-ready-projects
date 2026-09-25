---
name: release
description: Cut a version release — classify the semver bump, verify preconditions, write the changelog entry, sync version references, commit. Stops before tagging or pushing.
disable-model-invocation: true
---

Cut a release. Work through the steps in order and **stop at the end of Step 6** — publishing is the engineer's call, never the agent's. Step 7 runs only after the engineer confirms the push.

First read the project file (`CLAUDE.md`, `AGENTS.md`, or equivalent) for release preconditions and the changelog header for release mechanics. Where either conflicts with this skill, **the project's own process wins** — say so in your report.

## Step 0 — Substitute the version placeholder

Commands below use a literal `X.Y.Z`; run Step 1 first, agree the version in Step 2, then substitute it before running any. Unsubstituted, `git rev-parse "vX.Y.Z"` and a grep for `X\.Y\.Z` **succeed quietly**. If any command emits the literal `X.Y.Z`, stop and start over.

## Step 1 — Establish what changed

```bash
# The highest RELEASE tag reachable from HEAD. Every diff below is computed
# against it, so a wrong answer here mis-scopes the entire release silently.
git tag --sort=-v:refname --merged HEAD --list 'v[0-9]*' | sed '/-/d' | head -1
git log <last-tag>..HEAD --oneline      # commits since
git diff <last-tag>..HEAD --stat        # files touched
```

Why each part of the selector is there:

| Part | Without it |
|---|---|
| `--sort=-v:refname`, **not** `git describe --abbrev=0` | `describe` returns the *nearest* tag, not the highest: a hotfix `v1.0.1` merged in behind `v1.1.0` wins |
| `--merged HEAD` | a tag on an unmerged branch (a co-maintainer's release-in-progress) becomes your baseline |
| `--list 'v[0-9]*'` | a scratch tag (`wip`, `zz-backup`) sorts in and wins |
| `sed '/-/d'` | a prerelease (`v1.1.0-rc1`) becomes the baseline, and the changelog omits what changed since the last stable release |

**Read the output before using it.** An empty answer has two causes; check in this order (a bare `git tag` is not the test — a shallow clone can list no tags):

- **Shallow clone** — `git rev-parse --is-shallow-repository` answers `true` (common in CI). Run **`git fetch --unshallow`**; `git fetch --tags` is not a reliable fix. Treat `true` as "unshallow before concluding anything", not as a verdict.
- **Unmatched tag scheme** — most likely hyphenated CalVer (`v2026-08-11`), which the prerelease filter drops. Widen the filter.

Do not continue past an empty answer: it looks exactly like a first release, which it is only when `git rev-parse --is-shallow-repository` says `false` *and* `git tag` is empty. For a genuine first release, skip the diff commands, review the full history (`git log --oneline`), and propose `v0.1.0` or `v1.0.0` per the project's own convention.

Group the changed files by surface: **normative** (anything consumers install, import, or depend on — templates, public API, exported config, schemas), **documentation** (guides, references, rationale, READMEs), **internal** (tests, maintainer tooling, CI, project memory). If nothing changed since the last tag, report that and stop.

## Step 2 — Classify the bump

| Bump | When | Examples |
|------|------|----------|
| **MAJOR** | Existing consumers must take action to stay working | Removed or renamed a normative artifact; changed required structure; behavior change that breaks existing usage |
| **MINOR** | New capability, additive and optional | New template, new pattern, new behavior, new documented convention |
| **PATCH** | Nothing new to adopt | Documentation-only changes, clarifications, cross-references, corrections, refinements to existing artifacts |

Apply these two rules **in order** — the first one that fires decides:

1. **Does any existing consumer have to do something to keep working?** If yes, MAJOR, however small the diff: a "refinement" that changes a required structure is MAJOR.
2. **Otherwise:** a new artifact (file, pattern, documented behavior) → MINOR. Changes confined to existing artifacts → PATCH, even rewriting half a template.

State the proposed bump **with the reason** and have the engineer confirm before continuing; never proceed on a guessed version. Cite the changelog's closest prior bump decision, if any; where it and these rules disagree, follow the precedent and flag the discrepancy.

## Step 3 — Verify preconditions

Run every check and report the results. **Do not continue past a failure** — surface it and stop.

1. **Clean tree**: `git status --porcelain` returns empty.
2. **Right branch**: `git rev-parse --abbrev-ref HEAD` matches the release branch — the default branch unless the project says otherwise. If not, stop and ask.
3. **Tag is free**, locally *and* on the remote.
4. **Tests pass**: run the test and lint commands the project file names, and report actual output. If you cannot find a test command, report **"no test command found"** as a *failure to verify*, not a pass, and ask the engineer.
5. **Version references located**: every file carrying the *current* version — the files Step 5 must update.

```bash
git status --porcelain
git rev-parse --abbrev-ref HEAD

# Tag free? Anchor to refs/tags — a bare `git rev-parse vX.Y.Z` also matches
# a *branch* named vX.Y.Z and would block a legitimate release.
# ⚠️ THE VERDICT IS THE EXIT STATUS, never the word. `cmd && echo STOP || echo free`
# exits 0 on BOTH branches, so anything scoring it reads PASS while it prints STOP.
# This file printed that shape until v1.43.0 — defensible while only a human read
# it, and still the framework printing the idiom `curate` Step 0.3 forbids (#136).
# Braced, never bare: a skill's ARGUMENTS are substituted into its BODY, so a
# bare \$1 here ships as the first argument word (#77). Lint rule 9 catches it —
# including in THIS comment, whose first draft warned about the token by writing
# it, which is the same trap one level up.
tagfree() {
  # Empty or missing arg was a FALSE PASS: `tagfree` with no argument printed
  # "tag  free, local and remote" and exited 0, having checked nothing, with a
  # double space as the only tell. Reachable whenever $VERSION did not survive
  # into this shell.
  t=${1:-}
  [ -n "$t" ] || { echo "CANNOT VERIFY: no tag given"; return 2; }
  if git rev-parse --verify --quiet "refs/tags/$t" >/dev/null; then
    echo "LOCAL TAG $t EXISTS — STOP"; return 1
  fi
  lsr=$(git ls-remote --tags origin "refs/tags/$t" 2>/dev/null) || {
    echo "CANNOT VERIFY $t on the remote — ls-remote failed (offline? no origin?)"
    return 2
  }
  if [ -n "$lsr" ]; then
    echo "REMOTE TAG $t EXISTS — STOP"; return 1
  fi
  echo "tag $t free, local and remote"
}
# ⚠️ GUARDED. Under `set -e` a bare `tagfree vX.Y.Z` kills the shell on both the
# 1 and the 2 branch, so the status line never prints and the remaining
# preconditions are skipped — the 1-vs-2 distinction this rewrite exists to
# create, invisible in exactly the regime the framework recommends running in.
if tagfree vX.Y.Z; then rc=0; else rc=$?; fi
echo "  exit=$rc   # 0 free, 1 taken, 2 COULD NOT BE DECIDED"
# ⚠️ 2 IS NOT A PASS HERE. Elsewhere this framework treats CANNOT VERIFY as a
# third outcome rather than a failure; for THIS precondition it means the remote
# was never checked, so treat it as STOP. Do not continue to Step 7 on a 2.

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

Search **all** file types, not just `*.md` (`package.json`, `pyproject.toml`, `Cargo.toml`, `setup.py`, `__init__.py`, `docs/conf.py`, CI configs). Then cover by reading what the greps cannot see:

- **A file that should carry a version but doesn't** — templates and scaffolding are the usual victims. Compare against the previous release's file list if there is one.
- **Stale or historical?** Judge each hit against historical citations ("the vX.Y.Z precedent") and deliberately dated snapshots; don't bulk-replace. The version-agnostic greps are **expected** to return hits you leave alone — they have no pass/fail state.
- **Untracked files** — check any new file in `git status --porcelain` by eye.

## Step 4 — Write the changelog entry

**Read the top of the changelog first** to see which convention it uses:

- **Candidate block** (`vX.Y.Z (candidate, unreleased)`, accumulating entries): **promote** it by adding the date. A new section would leave a duplicate.
- **Write at release**: add a new dated section at the top, below the header.

A complete entry has:

- **Version heading and ISO date** — `## vX.Y.Z (YYYY-MM-DD)`, even if recent entries lack one
- **Summary line** — what shipped and why in one or two sentences, ending with the bump and its justification
- **Per-surface sections** — the specific files touched and what changed in each
- **Consumer notes** — what new consumers get and what existing ones must do ("no action required" when true). For a copied artifact, **name the surgical change and its marker strings — never only "re-copy it"**: a consumer who adapted their copy cannot re-copy without losing the adaptation, so give strings a current copy must contain and the edit that adds them.
- **Versioning rationale** — which Step 2 rule fired and the precedent it follows

Follow the *content* shape of recent entries but not their structural defects. Write for someone deciding whether to upgrade: "added a new required field to X, existing files without it still work", not "updated templates".

## Step 5 — Sync version references

Update the hits from Step 3, check 5, **that are meant to track the current version** — not historical citations, dated snapshots, or dependency pins. Typically: the project file's version line, README or docs badges, manifest version fields, and **any template or scaffolding file that stamps the framework version** (releases habitually miss these).

Then re-run the **current-version** grep and confirm the only hits are files you meant to update. Do not try to drive the version-agnostic greps to zero — in a real repo they never get there.

## Step 6 — Commit, then stop

Stage **only** the files this release touched — the changelog plus the files enumerated in Step 3, check 5:

```bash
# lint-skip: not-executable — `<each file updated in Step 5>` is a placeholder
# the engineer fills in, so this block cannot parse by design (rule 11).
git add CHANGELOG.md <each file updated in Step 5>
git status --porcelain          # confirm nothing unexpected is staged
git commit -m "release: vX.Y.Z"
```

Do not use `git add -A`: it stages every untracked, unignored file into the commit the tag will point at.

Then **stop and report**: the proposed tag and its commit, the commands below, and a one-line summary of the release.

**Do not run the following. They are for the engineer to copy.** A pushed tag is public and effectively permanent. Approval to cut a release is not approval to publish it.

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

2. **Refresh any copy of a skill or command installed outside the repo** (e.g. user-level). Only now is that safe; before the tag it would install content no release contains.
3. **Tell consumers who stamp your version that the stamp is a *number*, not an adjective:** "we are current with vX.Y.Z" goes false at your next release.
4. Update the memory index's current-state entry, and **rescope the probe on the line you just superseded**: "the highest tag equals vX.Y.Z" goes false at the next release, so a historical line's probe asserts the tag **exists**.
5. Close any issue the release resolves.
6. If the project tracks work items, fill in the Outcome section of any work item this release completed.

## Do not

- **Do not tag with a dirty tree** — the tag would not match what was tested.
- **Do not retag or force-push a tag.** If a released version is wrong, release a new patch.
- **Do not choose the version number yourself.** Propose it; the engineer confirms.
- **Do not claim a check passed without running it.** "I couldn't run it" is a valid report; "it passed" without evidence is not.
- **Do not batch unrelated changes into a release.** Surface work that isn't part of this release and ask.
