# Why `curate` says what it says

Superseded drafts and the measurements that refuted them, moved out of `templates/curate.md` so that
adopters do not pay for this repo's litigation on every invocation. **The decision lives in the
skill; the argument lives here.** Nothing is duplicated between the two — if a claim appears in
both, one of them is wrong.

###    One deprecated exception, and it is the only place a word in the output changes anythin…

- This framework taught `… && echo PASS || echo FAIL` until v1.21.0, and that idiom exits 0 on its failure branch, so without this every such command in every adopter's memory files would read as a pass on upgrade.

###      The second is a false PASS with the evidence of its own failure printed beside it, an…

- Put the failure on a non-zero exit: `git rev-parse v1.2.3 >/dev/null 2>&1 && echo TAG-PRESENT || { echo TAG-MISSING; exit 1; }`.

### Step 0.8 — the prettier ignore-file cwd measurement

Moved out of the skill 2026-09-05 to pay for the #109/#110 budget rewrite. The **rule** stays in
Step 0.8: verify the exemption from the cwd the formatter actually runs in. This is the evidence.

Measured on prettier 3.8.1 (adopter) and 3.9.4 (here), with a root `.prettierignore` naming the
project file:

| run from | command | exit |
|---|---|---|
| repo root | `prettier --check CLAUDE.md` | 0 — ignored |
| repo root | `prettier --check --ignore-path /dev/null CLAUDE.md` | 1 — it does want to re-pad |
| `frontend/` | `prettier --check ../CLAUDE.md` | 1 — the ignore file is never found |

Losing format-normalization on one markdown file is a smaller cost than a third of the budget.

### Step 0.8 — the two table-padding measurements

Moved 2026-09-05. The rule stays in Step 0.8: measure the de-padded size before proposing any cut.

| project | padding reclaimed | share of file | after |
|---|---|---|---|
| table-heavy project file | 12,685 chars | **35%** of 36.3k | 23.6k, identical content and rendering |
| second project | 21,030 chars | **61%** of 34,706 | content-identical |

The first project had no session footers left to trim and only structural sections remaining, so
the step had already escalated to the engineer as a *content* decision when the real cause was
whitespace. A file whose tables hold short cells sees far less than 35%.

## v1.43.0 — never hardcode the version a probe corroborates (#136)

Two adopter estates wrote the same fix for the same shape on the same day, independently. That
convergence is the reason it shipped rather than being noted.

The shape, written from this framework's own guidance:

```bash
for s in audit-context curate update-drift; do
  git -C "$FRAMEWORK" show "v1.36.1:.claude/skills/$s/SKILL.md" \
    | diff -q - "$HOME/.claude/skills/$s/SKILL.md" >/dev/null || echo "DRIFT: $s";
done; echo "checked 3 global skills vs v1.36.1"
```

**Two independent defects in one line.**

**(a) The verdict is a word in the output.** `|| echo` swallows the failure and the trailing
`echo` sets the status, so a runner scores PASS while it prints `DRIFT` three times. Step 0.5
already forbids this, and `docs/rationale/curate.md` records that this framework *taught* it
until v1.21.0 — so it is an idiom that survived being corrected, found in an adopter's record
dated 2026-09-05.

**(b) The probe hardcodes the tag it corroborates**, giving it the lifetime of that tag rather
than of the claim. It expires at the only moment it has anything to report — when the upstream
tag moves. One estate's derived version is what caught v1.37.0: it went red at `differing: 3` on
skills that had been diff-zero the session before. The other reports it as the fifth occurrence
of the family in their repo and the **first not authored locally**.

The shipped probe derives the version from the stamp, so bumping the stamp re-arms it with no
edit and pin and probe cannot silently disagree. Every branch was executed before shipping:
clean (exit 0), a seeded drifted install (`DRIFT: curate differs from v1.42.0`, exit 1), no
stamp, a skill not installed, and outside a git repo. The `2>/dev/null` on `rev-parse` is
load-bearing — without it git's own `fatal:` prints beside the CANNOT VERIFY line and reads as
the failure.

⚠️ **The framework was still printing the forbidden idiom itself.** `templates/release.md`
carried `… && echo "TAG EXISTS — STOP" || echo "free"`, exit 0 on both branches, measured.
Defensible while only a human read it, and still the framework printing what it forbids. Replaced
in v1.43.0 with a function whose exit status carries the verdict and which distinguishes a third
outcome — 0 free, 1 taken, 2 could not be decided (offline, no origin).

## v1.45.0 — the dead-reference extractor: comments moved here, then the code RETIRED

⚠️ **READ THIS FIRST. The extractor no longer ships.** The section below was written when only
its comments moved here; hours later the check itself was retired, having never caught anything
in the framework's whole record — its only appearances were its own defects. The code is gone
from `templates/curate.md`, `tests/fixtures/dead-reference/` is deleted, and the skill keeps no
rungs and no guards. **Do not read what follows as describing a live check, and do not re-add it
without a catch to point at.** The class is covered by `audit-context` Step 4, which is
adopter-facing and measured against a fixture with seeded true positives.

The account is kept because it is the best worked example this repo has of the failure that
motivated the retirement: six false-positive classes, each fixed with a new rung and a comment,
and nobody ever asking what the check had caught.


The block in `templates/curate.md` Step 0.1 was **73% comment**: 13,157 characters of
archaeology against 4,958 of code, in the skill an adopter runs every session. The account below
is what was removed. The code is unchanged — before and after produce byte-identical output on
the same input, and `tests/fixtures/dead-reference/` passes every seeded case and ablation.

⚠️ **No pointer to this file exists in the skill, deliberately.** Lint rule 13 forbids it:
adopters install the skill and never get `docs/rationale/`. The skill keeps one-line guards at
each rung that a maintainer might plausibly "simplify"; the reasoning lives here.

**Why each rung is shaped the way it is** — every one of these was a defect in a shipped draft:

- **`.resolve()` on the repo root.** Outside a git repo the lookup falls back to `.`, and
  `Path('.') in Path('../x.md').parents` is True — so every `../` fragment read as inside the
  tree and was decided DEAD. Absolute on both sides or neither.
- **Walk with a denylist, not `rglob` and not `git ls-files`.** `rglob` indexes `node_modules/`,
  `.venv/` and `vendor/`, so a doc naming a root `package.json` that does not exist counted
  RESOLVED against `node_modules/lodash/package.json` — a false negative in the one check whose
  purpose is finding dead references (#51). Switching to `git ls-files` fixed that and introduced
  its mirror: a real file in a gitignored data dir is untracked, so a bare basename referring to
  it read as DEAD. The denylist walk excludes vendored trees without excluding what an adopter
  chose not to commit. And a **list** per basename, not one winner: `{p.name: p}` kept whichever
  of two same-named files `rglob` yielded last, so a bare `helpers.py` with two answers resolved
  silently while the sibling step reports the same input as a COLLISION.
- **Absence assertions are span-scoped, never line-scoped** (#142). `audit-context` Step 4 had
  skipped this class since v1.15.0 and this extractor did not, so two shipped checkers gave the
  same input opposite dispositions — reported by an adopter who hit it twice, the second time in
  the text they wrote to record the first. Line-scoping dropped 4 references on 2 lines in one
  adopter repo, 3 of them load-bearing: a line routinely retires one path and names its live
  replacement in the same sentence, so `**Deleted**:` binds the ONE backticked token that
  follows it.
- **A shape is checked before it is quarantined.** `[slug]` is a literal directory in Next.js and
  SvelteKit, `<slug>.md` is legal on ext4. Four conventions, not two — `{a,b}` and `[slug]` are
  neither placeholder markers nor glob stars and both reached the resolver and were reported DEAD
  on an adopter run (#104, #106). Brace members are **not** expanded, and the measured cost of
  that is nil: across 66 directories every member of every comma-brace fragment resolves. A draft
  claimed two real losses from a member check asking `(root/member).is_file()` — which is #51's
  own false positive. Filed as unprioritised (#121).
- **The absolute-path rung must precede the cross-repo rung.** It sat below it for three releases,
  unreachable for every path it was written for: a POSIX absolute path contains a `/` and its
  first segment is `''`, never a top-level dir here, so the cross-repo rung took it first and —
  pathlib discarding the left side of an absolute join — printed a false `DEAD … absent in the
  sibling <parent>`. Windows forms arrive by the opposite route, no `/` at all: 10 false DEAD rows
  in 8 repos, measured on an estate and never filed. `os.path.expanduser`, not
  `Path.expanduser()`, which raises on a `~user` with no home.
- **No directory-on-disk gate on the absolute arm, unlike the doc-relative arm.** The asymmetry is
  deliberate: a `../` fragment is unambiguously about the author's own tree, while an absolute
  path is a claim about *a* filesystem that may not be this one. With the gate,
  `/opt/app/x.json` from another machine reads DEAD wherever `/opt/app` happens to exist here — a
  false DEAD invented by the environment.
- **`./` and `../` are doc-relative, lexical, and resolved against ONE base.** They reached the
  cross-repo rung because `..` is not a top-level dir here, which then tested a path one level
  above the one the fragment names and called a live file dead — its own reason said so, *absent
  in the sibling `..`* (#106). A draft used two bases, the document's directory and the repo root;
  the root base lands outside the tree for any `../` fragment, so a stray `RUNBOOK.md` beside the
  repo silenced a dead reference. In the population this method creates that matters —
  `memory/gotcha-log.md` exists in 35 git roots of one estate, `RUNBOOK.md` in 13. Nothing
  exercised it: deleting that base left every row and ablation green.
- **The cross-repo rung is not the rung-4 gate #93 rejected.** Rung 4 read a repo *name out of
  prose*, recognisable only when that repo is on disk, so per-reference decidability was not
  computable. Here the fragment qualifies itself — `AdopterRepo/scripts/x.py` names its repo in
  the path — so no prose is parsed. A qualified sibling reference is the form the sibling step
  tells authors to write, so a repo-local check invents phantom dead references in proportion to
  how well an adopter follows that advice: measured on one adopter, 12 dead reported, 0 actually
  dead, 9 of them qualified sibling paths. A sibling **on disk** decides it; an adopter measured a
  genuinely dead cross-repo reference being reported `not checkable` on the one reference they
  keep unfixed as a control, which is #93's sentence pointing the other way. ⚠️ Residual, and
  narrower than the "shallow or partial checkout" phrasing that shipped in v1.34.0 and was wrong:
  `--depth 1` truncates **history**, not the working tree, and reproduces nothing. Sparse checkout
  does omit files, and there a file present upstream reads as a confirmed dead reference — seeded
  in the fixture as a known, unfixed exposure. `--filter=blob:none` is **untested**: two drafts
  claimed it as measured, both over a local `file://` remote, which answers *filtering not
  recognized by server, ignoring* while still writing `promisor=true` into the config. Treat that
  mode as unknown, not as safe.
- **An unqualified directive value is not a path** (#141). `ExecStartPre=wait_for_edh.sh` is a
  unit-file line and reached DEAD because the cross-repo arm keys on a first segment it does not
  have. Only the unqualified form: `ExecStart=/usr/bin/x` still carries a `/`.
- **Filename-shaped, not extension-shaped.** `env` in the whitelist captures `process.env`, a
  ubiquitous code identifier no rung can resolve. The extractor shipped without this test and
  reported `process.env` as DEAD on the first `/curate` that ran it.
- **Strip one leading `@`, and only as a fallback.** `lstrip` is a character set, so it also ate
  the `@` of a scoped npm path and printed `types/node/index.d.ts` — text the document never
  contained.
