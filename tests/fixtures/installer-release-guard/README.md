# Installer release-guard fixture (#33)

`scripts/install-global-skills.sh` copies from the **working tree** into
`~/.claude/skills/`, where the copy shadows a project-local skill of the same
name in each repo. Until this guard landed, nothing checked that what it copied
had ever been released. On 2026-08-08 a global `curate` carried an uncommitted
draft for ~42 minutes, and the rule that draft carried was refuted before release
— so for that window the skill sessions loaded instructed the opposite of the
shipped one. `--check` reported agreement throughout, because it compares the
install against the same working tree.

The guard refuses to install when the bytes `cp` would copy are not the bytes the
highest release tag reachable from HEAD holds at that path. This fixture exists
because a run against this repo just after a release finds nothing — which is
byte-for-byte what a disabled guard looks like.

    bash run.sh          # exits non-zero on a sensitivity or specificity regression

## The predicate, and the two that were refuted before it

Four review batteries ran against this change. The first three each refuted the
comparison itself, and the shape of the error was the same every time: the
predicate answered a question adjacent to the one the install actually poses.

**Rejected: `git diff --name-only <tag>` plus `git ls-files --others`.** Asks
"does git *think* this path changed". Wrong in four ways, each now a case:
`--assume-unchanged` and `--skip-worktree` make git report a modified file clean
by request (P11); an untracked path is invisible to `diff` (P3); a symlinked
source is compared as a link while `cp` follows it (P9); and a symlinked parent
*directory* is not covered by a leaf-level `[ -L ]` test at all (P12).

**Rejected: `git show <tag>:<path>` compared with `cmp` against the file.** Asks
"does the raw blob equal the working file". That is the wrong side of the
checkout filter: the worktree holds smudge(blob), so a pristine release checkout
refuses under `core.autocrlf=true` — the Git-for-Windows default — or any
`.gitattributes` filter such as `ident` or LFS (N10).

**Shipped: git's own object ids.** `git rev-parse <tag>:<path>` for what the
release holds, `git hash-object --path=<path>` for what is on disk. `hash-object`
applies the *clean* filter, so a correct checkout under an eol filter compares
equal (N10) and a draft never does.

What that proves is `clean(disk) == released blob`, which is **weaker** than "the
bytes are the released bytes", because `clean` is not always injective. With
`ident`, anything inside a `$Id: ... $` expansion cleans back to `$Id$` and
compares equal — arbitrary injected text installing at exit 0 with an `OK`
verdict (P16). The eol filter, the one that actually occurs on markdown, is
content-preserving, so the comparison holds there. `git cat-file --filters` is
the other side of the same coin: it catches `ident` and gets `text` wrong
(measured). Since no single command answers both, a path carrying a lossy filter
— `ident`, or any custom `filter=` driver — is **refused rather than compared**.

The release itself is `git tag --sort=-v:refname --merged HEAD --list 'v[0-9]*'`
with hyphenated names skipped. `templates/release.md` Step 1 forbids
`git describe --abbrev=0` when picking a release baseline, on the grounds that it
returns the *nearest* tag rather than the highest — which here would measure a
correct tree against a superseded release (N11). The sort order is Step 1's; the
three filters are not. Step 1's own form is `git tag --sort=-v:refname | head -1`,
which would return `v1.2.3-rc1` (P10), a scratch tag (P5), or a tag on an
unmerged branch (N14) — **worth hardening there too, and not done in this
change** (#41), since that template is normative and adopter-facing.

## What it seeds

Each case builds a throwaway git repo in a known state, runs the real installer
against it with `CLAUDE_SKILLS_DIR` pointed at a scratch destination, and asserts
the exit code, a needle in the output, and — for refusals — that **no bytes
reached the destination**. A refusal that prints and falls through would still
ship the file and still read correctly in a transcript.

| case | state seeded | why it is here |
|---|---|---|
| P1 | uncommitted edit to `curate` | the 2026-08-08 shape itself |
| P2 | committed, not tagged | `git diff --quiet HEAD`, the form first proposed on #33, calls this tree clean |
| P3 | a global source git never tracked | absent from the tag; a diff against the tag cannot see it |
| P4 | the release tag deleted | the released state cannot be determined |
| P5 | only a non-release tag (`wip`) | an unfiltered tag list would certify the tree against a scratch tag |
| P6 | `.git` removed | fails closed rather than assuming fine |
| P7 | same checkout nested in an unrelated repo that ignores it | git answers every question, about the wrong repo — and answers `--is-inside-work-tree` with "true" |
| P8 | the source file unreadable (mode `000`) | a failed read must not compare equal; skipped for root, who has no unreadable files |
| P9 | a source committed as a symlink, its target edited after the tag | git holds the link, `cp` copies the target |
| P10 | only a prerelease tag (`v1.0.1-rc1`) | a prerelease is not a release |
| P11 | `--assume-unchanged` plus an edit | git reports clean *by request*; the shape that survived the first fix |
| P12 | the skill **directory** committed as a symlink, its target edited | a leaf-level `[ -L ]` test is blind to it; git even shows the target as modified |
| P17 | a custom `filter=` driver whose clean strips a local-only marker | the other half of the lossy-filter arm; without this case that half is inert — measured — and it guards the likelier shape |
| P14 | a `PATH` with everything except `git` | see the ablation note: this arm was inert until this case existed |
| P15 | a `--force` install already in the destination, then a refusing run | #33 having already happened: the verify pass compares install against source and both are the draft, so the report read "0 issue(s)" while the destination carried it |
| P16 | `*.md ident`, with text injected inside the `$Id: … $` expansion | a lossy `clean` filter: the injected text hashes to the released blob, so the comparison the guard is built on says "released" |
| N1 | clean at the tag | the control — it must install |
| N2 | a **project-local** skill mid-edit | the normal state of a working session; refusing here teaches the habit of passing `--force`, and then there is no guard |
| N3 | an unrelated file mid-edit | same |
| N4 | dirty tree, `--force` | the documented override has to override, and must still exit 0 |
| N5 | dirty tree, `--check` | `--check` warns but keeps its exit code and its own verdict line |
| N6 | install stale **and** tree unreleased | the verify loop's refresh hint used to say "run without `--check` to refresh" — the exact install the guard refuses |
| N7 | install stale, tree released | ...and the ordinary hint has to survive for the case where refreshing *is* the answer |
| N8 | dirty tree, install run with an estate scan root | refusing the install must not cancel the checks that write nothing; an earlier draft exited first, so a #33 guard suppressed the #36/#37 scan |
| N9 | a source file deleted | not a shipping hazard — nothing gets copied — so it stays the install loop's report, exit 1, and must not be misreported as a symlink |
| N10 | a clean checkout under a committed `text` attribute, CRLF in the worktree | a pristine release checkout on Windows defaults; it also caught a real pre-existing bug, `head -1` reading `---\r` as "no frontmatter" |
| N11 | a hotfix tagged `v1.0.1` merging in behind `v1.1.0`, with two commits of padding | the padding is what makes it discriminating: without it both tag selectors answer `v1.1.0` and an earlier version of this case passed under `describe` too |
| N12 | the installed file exists and is unwritable | `cp`'s status was discarded, so the transcript said "installed" while nothing was copied. The *file* must be unwritable, not its directory: replacing a file truncates it in place — measured, a mode-500 directory alone lets `cp` succeed |
| N13 | the destination directory cannot be created | the same failure one step earlier; with N12's directories pre-created, nothing exercised `mkdir`'s status |
| N14 | a higher tag on an unmerged branch | without `--merged HEAD` the guard measures a correct `v1.0.0` checkout against `v2.0.0` |
| N15 | a `PATH` with everything except `readlink` | it used to be a dependency, and the arm that probed for it refused a **clean** released tree on any system whose `readlink` lacks `-f` (BSD, older macOS) — the platform the script already accommodates for `$0` |

**Needles are chosen so they can fail.** P1–P3, P8, P11 assert the offending path
*and* its reason; P9's needle was once `symlink`, which appears in its own case id
inside the destination path every refusal prints, so it could never fail. P14 asserts only
its own diagnosis rather than a path, because in that state there is no released
tag to name a path against.

**Seeds are asserted too.** N10, N11 and N14 check that the tree they built is
what they claim, and P16 and P17 check that their seeded injection actually
survives the clean filter — a case whose seed does not reproduce the hazard
proves nothing. N10 and N11 check it — clean, by `git diff` rather than `git status`, since under a checkout
filter `status` reports ` M` from the stale stat cache while `diff` applies the
filter and reports no content difference. Both assertions have already fired on
bad seeds, as has the mutator-name check in `run_case`.

**Hermeticity.** The harness unsets `GIT_DIR`, `GIT_WORK_TREE` and their
relatives, and pins `core.hooksPath`. `git -C` loses to an inherited `GIT_DIR`,
and a git hook or `git rebase --exec` exports one — under which `mkrepo`'s
`commit`, `tag` and `tag -d` land in **the real repository**. That is not
hypothetical: it happened during the review of this change, which committed to
`master` and retagged `v1.0.0` before being restored.

## Ablations

Each arm was disabled in a scratch copy and the whole fixture re-run. Measured on
the shipped code, not reasoned from it:

| Ablation | Cases that fail |
|---|---|
| `git hash-object` id comparison → raw `git show \| cmp` | P8, N10 |
| Drop the `ident` half of the lossy-filter arm | P16 |
| Drop the `filter=` half of it | P17 |
| Drop the lossy-filter arm entirely | P16, P17 |
| Replace the tag loop with `git describe --abbrev=0 --match 'v[0-9]*'` (which also drops the hyphen filter) | P10, N11 |
| Drop the `v[0-9]*` glob from the tag listing | P5 |
| Drop `--merged HEAD` | N14 |
| Drop the hyphen filter | P10 |
| Test only the leaf with `[ -L ]` | P12 |
| Test only the canonicalised ancestor | P9 |
| Drop the symlink arm | P9, P12 |
| Ignore `git rev-parse`'s exit status | P3 |
| Ignore `git hash-object`'s exit status | P8 |
| Drop the id comparison itself | P1, P2, P11, P15, N4, N5, N6, N8 |
| Drop the "source does not exist" skip | N9 |
| Drop the git-is-installed arm | P14 |
| Drop the work-tree-root arm | P6, P7 |
| Warn instead of setting `REFUSED` | all 16 positives, plus N8 — the destination gets the unreleased bytes |
| Exit immediately on refusal | P15, N8 |
| Drop the installed-copy-vs-release check | P15 |
| Run that check on every path, not only a refusal | N4, N5 — a deliberate `--force` would exit non-zero, and `--check` would go red on every unreleased tree |
| `head -1` instead of the CR-stripping `first_line` | N10 |
| Ignore `cp`'s exit status | N12 |
| Ignore `mkdir`'s exit status | N13 |
| Scope the check to all of `.claude/skills/` | 20 fail; **N2** is the informative one (a project-local skill mid-edit blocks the install), the rest are collateral from pointing the comparison at a directory |
| Ignore `--force` | P15, N4, N5 |
| Let `--check` refuse too | N5, N6 |
| Restore the `printf '%s'` path-list bug | P1, P2, P3, P8, P9, P11, P12 |
| Drop the unreleased-tree refresh hint | N6 |

**One guarantee here is structural, not ablatable.** The findings are accumulated
with builtins; there is no round-trip through an external command that could
empty them. Re-introducing one and *not* breaking it measures nothing (that row
came back inert), so the protection is P13: of the two externals that remain,
losing one still refuses.

**Two arms measured inert before their case existed** — `--is-inside-work-tree`
and `command -v git`. Both refused the states they were written for, but so did
the arm below them, so removing either changed no outcome. One was replaced with
a stronger predicate (work-tree *root*, which P7 distinguishes); the other was
kept for its message and given P14, which isolates it with a `PATH` holding every
binary the script needs except `git`. Stripping `PATH` entirely does *not*
isolate it: `dirname` goes too, and the script exits at its repo-root check
before the guard runs.

**Three rows in this table were wrong at some point, in three different ways**,
and each was caught by a reviewer re-running it rather than by anyone reading it:
one recorded a result that does not reproduce with an explanation that is false;
one was "measured" by an ablation that edited the file without changing its
behaviour, and reported inert; and one claimed 15 failures for a swap that fails
2, because the ablation used to measure it broke more than the arm it targeted.

**An ablation that does not change behaviour is indistinguishable from an inert
arm.** One row here was first "measured" by a `sed` that edited the file — so it
looked applied — while leaving the predicate equivalent; it reported inert, which
reads as "this check does nothing, delete it". An earlier draft of this table was
worse: a row recorded a result that does not reproduce, with a false explanation,
and it was the one row presented as measured that had not been. Re-run a row
before citing it, and check that the ablation inverts the behaviour it claims to
remove.

**One state stopped being refused**, and is recorded rather than dropped: an
earlier case deleted the tag's loose object, which the `git show` predicate could
not read. Under the id comparison that state now installs — `git rev-parse` reads
the blob id out of the tree without touching the object, and a file hashing to
that id *is* the released content, damaged object store or not. P8 replaced it
with a state that is still a hazard: a source the guard cannot read at all.

## Adding a case

Seed the state, assert the destination. If you make the guard **more permissive**
— a new state it tolerates — add the shipment that state newly permits, and show
the guard still refuses everything above. A run that finds nothing cannot
distinguish a working guard from a disabled one.
