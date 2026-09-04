# Review Changes

<!-- SAVE AS: .claude/skills/review-changes/SKILL.md (Claude Code)
     For other tools, run this as a pre-commit prompt manually.

     This is a skill (/review-changes) that reviews staged or unstaged
     changes against the previous commit. It picks review lenses based on
     what changed — not every change needs the full multi-model battery.

     Claude Code skills require SKILL.md as the entry point inside a
     named directory under .claude/skills/. Add frontmatter:
     ---
     name: review-changes
     description: Diff-driven pre-commit review — picks review lenses based on what changed, from single-pass adversarial to full multi-model battery
     disable-model-invocation: false
     --- -->

Pre-commit review of pending changes. Scope and depth are driven by what changed, not a fixed checklist.

## Step 1 — Diff and classify

Resolve the review baseline first — **every command in this step depends on it.**

**The baseline is the default branch — `@{u}` only on the default branch itself.** On a branch that is committed and pushed but not merged — the commonest state in which anyone wants a pre-merge review — `@{u}` is *empty*, because the upstream exists and is current. Every `@{u}`-derived term then reports zero and the step reads as "nothing to review" on a whole PR. Resolve it once, **here, before anything else in this step**, and reuse it everywhere below — the tier table, the magnitude gate and Step 1.5 all read `$BASE`:

```bash
# Every arm ends in a success, or `set -e` aborts here — before the fallback below,
# which is the one place that reports the failure. Measured: a repo with no remote
# and no main/master branch died at the loop with no output at all.
BASE=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD) ||
# Fully qualified: `rev-parse` resolves refs/heads/ before refs/remotes/, so a
# LOCAL branch literally named `origin/main` would win and silently reintroduce
# #64 — measured, with only a stderr `ambiguous` warning nothing reads.
BASE=$(for c in refs/remotes/origin/main refs/remotes/origin/master main master; do
         git rev-parse --verify --quiet "$c" >/dev/null && { printf %s "$c"; break; }; done) || :
# On the default branch HEAD...HEAD is empty, so the upstream is the baseline.
if [ -n "${BASE:-}" ] && [ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" = "${BASE##*/}" ]; then
  BASE=$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || printf %s '')
fi
# A name that resolves to nothing is the dangerous case: an empty or dangling BASE
# makes "$BASE"...HEAD an empty diff, which is what a clean tree also yields. Fall
# back to the whole branch — over-reporting is the safe direction for a review tool.
# No `${BASE:-sentinel}` placeholder here: any word chosen as a sentinel is a
# legal branch name, and if it exists the check passes while BASE stays empty,
# so the guard below fires with a diagnosis that is simply wrong. Measured.
{ [ -n "${BASE:-}" ] && git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null; } || {
  BASE=$(git rev-list --max-parents=0 HEAD 2>/dev/null | tail -1)
  echo "BASELINE UNRESOLVED — reviewing the whole branch instead. Say so in the report." >&2
}
: "${BASE:?no commits in this repository — nothing can be reviewed}"

git diff --shortstat "$BASE"...HEAD    # committed on this branch
git diff --shortstat                   # unstaged
git diff --cached --shortstat          # staged
```

**Resolving a name is not enough — it has to resolve to a commit.** `git symbolic-ref` reads `origin/HEAD` without following it, so a renamed or deleted upstream default yields a ref that looks fine and diffs to nothing; a stale local `main` in a `master` repo does the same. Both were measured. That is why the block validates `^{commit}` and, on failure, falls back to the root commit and says so: an unresolved baseline and a clean tree produce identical output, and this step exists because those two were confused.

`origin/HEAD` is set by `git clone` (including `--depth 1`) and by the first `git fetch` on git ≥2.45 — measured on 2.53.0, not assumed. The loop covers `git init` + `git remote add` with no fetch, and older git. ⚠️ It does **not** cover a remote whose default branch is neither `main` nor `master` *and* whose `origin/HEAD` is unset: measured, a repo whose default is `develop` falls through to the root-commit fallback and reviews the whole branch. Over-reporting, which is the safe direction, but it is a fallback rather than the intended path.

⚠️ **`$BASE` lives in a shell, and Step 1.5 needs it. Run Step 1.5's blocks in the same shell invocation as this one** — paste them together, or re-run this block at the top of that shell. A tool call that starts a fresh shell does not inherit it, and Step 1.5 is written to abort rather than proceed with the term missing. That abort is the intended behaviour: the alternative is Step 1.5 quietly reviewing a fraction of the change, which is #64 one step later.

Now run `git diff --stat "$BASE"...HEAD`, `git diff --stat` and `git diff --cached --stat` to see the changed files, and `git diff --summary -M "$BASE"...HEAD` alongside them. **All three terms are needed and the baseline one is the one that is usually non-empty**: on a pushed, unmerged branch the other two are empty, and an earlier version of this step listed only those two — so the tier table, the Unclassified section and the report header were all computed over zero files while the magnitude gate below reported the real number. That was #64 surviving its own fix in the place nobody re-read. **`--stat` alone cannot see a mode change, a rename, a submodule, or a binary** — all four render as zero or near-zero lines, and three of them are carve-outs below. A carve-out you cannot observe is not in force; `--summary` without the baseline term cannot observe any of them on a pushed branch. Classify each changed file into a risk tier:

| Tier | File patterns | Depth |
|------|-------------|-------|
| **HIGH** | `templates/**`, `adopt.md`, `/README.md`, `docs/GUIDE.md`, `docs/verification-rationale.md`, `tests/**`, `scripts/**`, `.claude/skills/**`, `.gitignore` | Full battery (3-4 lenses) |
| **MEDIUM** | `CLAUDE.md`, `docs/**`, `templates/checklists/**`, `templates/physics-tests/**`, `templates/test-fixtures/**` | Two lenses (adversarial + doc-accuracy) |
| **LOW** | `CHANGELOG.md`, `memory/**`, `docs/work-items/**` | One lens (adversarial) |

`**` crosses directory levels; a leading `/` anchors to the repo root. **The most specific matching pattern wins** — `templates/checklists/foo.md` is MEDIUM, not HIGH, even though `templates/**` also matches it. Where no pattern is more specific than another, take the highest tier.

The HIGH row is the normative surface — everything an adopter consumes or executes. Four entries are easy to miss, and each is here because it burned someone: `scripts/**` is shell that runs on another machine; `.claude/skills/**` holds the reference installs adopters copy, so a defect there ships to every install derived from it; `/README.md` is anchored so it means *the repo's own* README, not every nested one; and `.gitignore` decides what is published at all — a one-line change there has exposed private content in a public repo.

### Magnitude gate

The tier above is set by *path*. Depth is also set by *size* — but size is the weaker signal, so the exceptions are stated first and override everything below them.

**Always full depth, regardless of size.** Each of these is dangerous *because* it is small, and each would otherwise slip through on line count alone:

- **`.gitignore`** — see the paragraph above; one line has exposed private content in a public repo.
- **Renames and moves** — `git diff --stat` reports `0 insertions(+), 0 deletions(-)` under `-M`, while every reference to the old path breaks.
- **Permission changes** — also zero insertions and deletions, and invisible without `--summary`. A `chmod -x` on a shipped script makes it unrunnable for everyone downstream.
- **Binary files and submodule pointers** — the other two members of the zero-line class. A submodule bump changes one line and can move an arbitrary amount of code.
- **Any change to a shell script or an executable, wherever it lives** — `scripts/**` and `tests/**` are both HIGH because they are code that runs on someone else's machine, and shell breaks in one character. A small edit would otherwise lose the shell-correctness lens, which is the reason those paths are HIGH at all.
- **Any non-frontmatter edit to a reference install** (`.claude/skills/**`) — HIGH because a defect there ships to every install derived from it; that is as true of a three-line body edit as of a frontmatter one.
- **Frontmatter edits to those same files** — removing one `---` silently unregisters a skill.

  *Both bullets used to end a bolded phrase with a `**`-suffixed glob, and that shape is corrupted by prettier: the closing `**` becomes a literal `\*\*` and the phrase loses its bold, or with two globs the spaces between them are eaten. **The rule worth remembering is the shape** — never end a bolded phrase with such a glob; put the path in a parenthetical, as above. The mechanism is not worth remembering and is recorded only so nobody re-derives it: it breaks on prettier 2 and 3.8.1 and is fixed in 3.9.6, and **exactly one** later code span on the line masks it while two reintroduce it in the other form. That is why this framework shipped the broken shape for a day while every test of it passed. Step 1.5 **now catches this exact shape** — the emphasis check added in v1.31.0 reports two backticked `**`-abutting tokens inside one bold span. *This sentence read "Step 1.5 does not catch it" until v1.36.1, having been left standing when the check that refutes it shipped in the same release.**
- **A new executable, or any new file in a HIGH path** — the tier for new content has not been decided yet.
- **Any diff that removes or loosens a check** — a deleted guard, a weakened assertion, a broadened exclusion. Loosenings are characteristically a handful of lines, and this is the class the seeded-true-positives rule exists for.

**Otherwise size sets the depth.** Size means the whole change that will land, not the slice in front of you — 10 lines committed locally plus 15 staged is a 25-line change, and reviewing each half on its own means nothing ever sees the whole. `$BASE` is already resolved at the top of this step; do not resolve it again.

```bash
git diff --shortstat "$BASE"...HEAD    # committed on this branch
git diff --shortstat                   # unstaged
git diff --cached --shortstat          # staged
```


Line count is a proxy, and in these templates a weak one — they are written one sentence per line, so replacing two dense normative paragraphs is four changed lines while a whitespace reflow is a hundred. **When the line count and your read of the change disagree, the line count is wrong.** Escalate.

| Changed lines | Depth |
|---------------|-------|
| **< 20** | One adversarial pass |
| **20–200** | Path tier as above |
| **> 200** | Full battery, whichever tier the paths fall in |

Run that single pass in a **fresh context** — a subagent if your tool provides them, otherwise a separate pass that re-reads the diff from scratch. Reviewing your own edit in the context that produced it is the self-certification failure this skill exists to prevent; the saving comes from running *one* independent reviewer instead of four, not from dropping independence.

The gate changes how many lenses run. It never changes *whether* a change is reviewed — every diff still gets at least one adversarial pass.

If only LOW files changed **and the gate above does not escalate**, run Step 1.5, then do a single adversarial pass and skip to Step 3. Step 1.5 is never skipped — it is deterministic and costs nothing, and LOW is where the memory files that motivated it live. The gate wins where the two disagree: a 400-line change to `memory/**` is still a large change, and tier is about blast radius, not size.

**If a changed file matches no pattern, treat it as MEDIUM, and name it in the report under "Unclassified" even when a HIGH file in the same diff makes the tier moot.** The naming is the point: an unrecognized path is usually new shipped content whose tier nobody has decided yet, and it will keep arriving un-triaged until someone adds a row. Do not silently drop it, and do not default it to LOW. **If it is executable or is copied into an adopter's tree, escalate it to HIGH rather than leaving it at MEDIUM** — MEDIUM omits both the guarantee-preservation and shell-correctness lenses, which are exactly the two that shipped content needs.

If no files changed, report "nothing to review" and stop — but only after `$BASE` resolved. A clean tree because everything is merged and a clean tree because the work is already pushed are indistinguishable from `git diff` alone, and the second is a full PR. If the baseline could not be resolved, that is the finding; report it instead of a clean result.

## Step 1.5 — Structural pre-check

Runs at **every tier and every magnitude**, before any lens, on every changed markdown file — the single-adversarial-pass gate above trims lenses, not this. It is deterministic, so it costs nothing to run and does not need a model to evaluate, which is the reason it is a step rather than a lens.

The lenses below all read *content*: does this path exist, is this flag right, what would a future session do wrong. None of them asks whether the file is still **valid markdown** after the edit. That gap matters disproportionately here, because the memory layer is predominantly wide tables — inventories, index files, machine lists — where a row is one very long line. A `|` added inside a cell (a regex like `'recordfail|initrdfail'`, an `||` in a shell fragment, an alternation in a note) pushes cells past the end of the table, and **GFM drops the excess silently**. It reads fine as prose in the diff and is wrong only when rendered, so a human reviewer and an adversarial lens both pass it.

```bash
  : "${BASE:?run the Step 1 baseline block in THIS shell invocation — a fresh shell does not inherit it}"
{ git -c core.quotePath=false diff --name-only
  git -c core.quotePath=false diff --cached --name-only
  git -c core.quotePath=false diff --name-only "$BASE"...HEAD 2>/dev/null
  git -c core.quotePath=false ls-files --others --exclude-standard; } |
  sort -u | grep '\.md$' | while IFS= read -r f; do
  [ -f "$f" ] || continue
  awk -v F="$f" '
    function cells(s,   t, n) {
      t = s; gsub(/\\\|/, "", t)
      sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
      sub(/^\|/, "", t); sub(/\|$/, "", t)
      n = gsub(/\|/, "|", t); return n + 1
    }
    function isdelim(s,   t) {
      t = s; gsub(/\\\|/, "", t); gsub(/[ \t]/, "", t)
      return (t ~ /-/ && t ~ /^[|:-]+$/)
    }
    # `$(0)`, never `\$0`: skill ARGUMENTS are substituted into the skill BODY, so a
    # bare `\$0` arrives as the first argument word and this program examines a
    # constant while printing what a clean run prints. See #77.
    { sub(/\r$/, "") }               # CRLF: strip before anything reads the line,
                                     # or isdelim() never matches and no table in
                                     # the file is examined. See #52.
    # YAML frontmatter, skipped whole: `isdelim()` accepts a bare `---` and its
    # guard is satisfied by a pipe in the PREVIOUS line, so a closing `---` under
    # `description: Runs a | b` reported as a malformed table — and every SKILL.md
    # here has a `description:`. Preferred over requiring a pipe in the delimiter
    # row, which would reject the pipe-less rows GFM permits (#52).
    NR == 1 && $(0) ~ /^---[ \t]*$/ { infm = 1; next }
    infm && $(0) ~ /^(---|\.\.\.)[ \t]*$/ { infm = 0; prev = ""; next }
    infm { next }
    {
      bare = $(0); sub(/^ ? ? ?/, "", bare)
      if (bare ~ /^```/ || bare ~ /^~~~/) {
        c = substr(bare, 1, 1); n = 0
        while (substr(bare, n + 1, 1) == c) n++
        if (fch == "") { if (n >= 3) { fch = c; flen = n } }
        else if (c == fch && n >= flen) fch = ""
        intbl = 0; prev = ""; next
      }
      if (fch != "") next
      # Emphasis spans — the third construct with Step 1.5’s property: correct in
      # the diff, wrong when rendered (#50). Deliberately NARROW. The table check
      # reached a 39% false-positive rate before being anchored, so this reports
      # only the shape actually observed to break: a backticked token whose
      # content abuts `**`, sitting on a line that also carries bold OUTSIDE the
      # backticks. A formatter can join the two runs and corrupt both. Broader
      # rules (counting `**` per line, balancing across lines) were rejected —
      # they fire on ordinary bold and on multi-line spans.
      # Mask each code span to ONE character — \001 if its content abuts `**`,
      # \002 otherwise — so bold runs can be paired positionally. Adjacency is
      # the discriminator, and nothing weaker works: "a risky token anywhere on a
      # bold line" reported 28 lines here, and "two of them" still reported 15 —
      # every risk-tier row, where `**HIGH**` opens AND CLOSES in one cell and the
      # globs sit in the next. Only a token INSIDE an open bold run can be joined.
      { masked = ""; rest = $(0)
        while (match(rest, /`[^`]*`/)) {
          inner = substr(rest, RSTART + 1, RLENGTH - 2)
          mark = "\002"
          if (inner ~ /\*\*$/ || inner ~ /^\*\*/) mark = "\001"
          masked = masked substr(rest, 1, RSTART - 1) mark
          rest = substr(rest, RSTART + RLENGTH)
        }
        masked = masked rest
        inb = 0; nrisk = 0
        for (i = 1; i <= length(masked); i++) {
          if (substr(masked, i, 2) == "**") { inb = 1 - inb; i++; continue }
          if (inb && substr(masked, i, 1) == "\001") nrisk++
        }
        # The backtick test guards against a literal \001/\002 byte in the source
        # masquerading as a masked span: without it, a line with no backticks at
        # all reported "two backticked tokens", a message that is simply false.
        # No tracked file here contains those bytes; the message would be wrong
        # anyway, and a wrong message is what sends a reader to the wrong line.
        if (nrisk > 1 && index($(0), "`"))
          printf "%s:%d: two backticked tokens abutting ** inside one bold span — a formatter can join the runs and corrupt both\n", F, NR
      }
      if (isdelim($(0)) && prev != "" && (index($(0), "|") || index(prev, "|"))) {
        base = cells($(0)); intbl = 1
        if (cells(prev) != base)
          printf "%s:%d: header has %d cells, delimiter row defines %d — not a valid table\n", F, NR-1, cells(prev), base
        prev = $(0); next
      }
      if (intbl) {
        if ($(0) ~ /^[ \t]*$/) intbl = 0
        else if (index($(0), "|") && cells($(0)) > base)
          printf "%s:%d: row has %d cells, table defines %d — the excess is dropped when rendered\n", F, NR, cells($(0)), base
      }
      prev = $(0)
    }
    END { if (fch != "") printf "%s: unclosed %s code fence\n", F, fch
          # An unclosed frontmatter leaves `infm` set, so `infm { next }` swallows
          # every remaining line and NO table is examined — the check then prints
          # exactly what a clean run prints. That is the same silence the
          # frontmatter rule was added to remove, in the one step whose purpose is
          # catching corruption invisible in the diff (#103). Report the state
          # rather than recovering from it: a file whose frontmatter never closes
          # is malformed on its own, and guessing where it should have ended is
          # how a check starts inventing findings.
          if (infm) printf "%s: unclosed YAML frontmatter — NO table in this file was examined\n", F }
  ' "$f"
done
```

The file list is the union of unstaged, staged, **everything committed on this branch**, and **untracked** — `git diff` in any form never lists a file git has not seen, and a brand-new document is where fresh corruption is most likely. `core.quotePath=false` is load-bearing: git otherwise renders a non-ASCII path as `"caf\303\251.md"`, which does not end in `.md`, so the file is dropped from both the check and the count with no error.

**The delimiter row defines the table, and only *excess* cells are reported.** GFM inserts empty cells when a row is short and discards them when a row is long, so a short row renders exactly as intended and is not a defect — a section-divider row like `| **PART ONE** |` inside a wide table is idiomatic, not corruption. A long row loses data. Reporting both was measured at a **39% false-positive rate**; anchoring on the delimiter and reporting only the lossy direction took the estate from 168 hits to 68 across 4381 files, with the removed hits all in legal-but-short or not-a-table-at-all classes.

Hits come in three shapes: a row whose excess cells are discarded, a header that disagrees with its own delimiter row (which means GFM renders no table at all), and an unbalanced code fence. This includes pipes inside backticks — GFM splits a row into cells *before* it parses inline content, and its spec says so explicitly, so a `|` in an inline-code span breaks the row exactly like a bare one. Fix each (escape as `\|`, or move the command out of the table) before running the lenses.

**Treat a hit as real until you have looked at it, not as proven.** A hit says the row supplies more cells than the delimiter row defines, and GFM discards the excess. That is a loss only when the discarded cells carry content — `| 1 | 2 | |` against a two-column delimiter reports, and loses nothing. And it says nothing about whether you are looking at a table at all: `isdelim()` accepts a bare `---` and its guard is satisfied by a pipe in the *previous* line, so YAML frontmatter, a setext heading and a spaced `- - -` break can each report. Classes and repros in #52.

**Known blind spots, so a clean result is not read as more than it is**: tables inside blockquotes are not examined, nor is a table whose delimiter row is itself missing. The check finds lossy rows in well-formed tables; it is not a markdown validator. **CRLF was one of these until v1.25.1** — `isdelim()` strips spaces and tabs but not `\r`, so on a CRLF checkout tables went unentered and a file whose defect was in a table printed what a clean file prints. Only the fence check survived, anchored at line start where a trailing `\r` cannot reach. Fixed by the `sub(/\r$/, "")` rule above; `core.autocrlf=true`, which the Git-for-Windows installer pre-selects, is what puts CRLF in the working tree. **Lone CR is still a blind spot** and a worse-behaved one: awk sees the whole file as a single record, so no table is examined and the fence check misreports — a lone-CR file whose fence is correctly *closed* is reported as unclosed.

The command prints nothing on a clean run — which is also what it prints when the file list was empty. **Report the count alongside the result** so the two are distinguishable:

```bash
  : "${BASE:?run the Step 1 baseline block in THIS shell invocation — a fresh shell does not inherit it}"
{ git -c core.quotePath=false diff --name-only
  git -c core.quotePath=false diff --cached --name-only
  git -c core.quotePath=false diff --name-only "$BASE"...HEAD 2>/dev/null
  git -c core.quotePath=false ls-files --others --exclude-standard; } |
  sort -u | grep -c '\.md$'
```

That count is files *in scope*, not files you edited: the baseline term includes everything committed on this branch, and `ls-files --others` includes every untracked markdown in the tree. If it is zero while the Step 1 diff listed markdown files, the pipeline is broken — not the changes clean. It reads `$BASE` from Step 1, **in the same shell**: an unset `$BASE` aborts this pipeline rather than dropping its largest term, so a fresh shell gives you a loud failure and not a small number.

## Step 2 — Execute review lenses

For each lens, spawn a subagent with the specific prompt below. Run lenses concurrently.

**Invariant: every file named in the guarantee lens must sit in the HIGH row of Step 1.** The lens is HIGH-gated. A file it defines a guarantee for but that tiers below HIGH has a guarantee that can *never* be checked — and the report renders "no HIGH files changed" as a clean pass, so the failure is silent and looks like success. Whenever you add an entry to the guarantee lens, add its path to the HIGH row in the same edit; if a path does not deserve HIGH, it does not deserve a guarantee entry. Check the invariant in the direction that catches it: read each guarantee entry and find its tier, not the other way round.

This matters most when you first adopt this skill. Both the tier table and the guarantee lens name files in *this* repo's tree, so you will rewrite both — and the two rewrites are easy to do independently. In the version shipped here the invariant happens to hold, so the template never demonstrates the constraint it depends on.

### Lens: guarantee-preservation (HIGH only)

```
You are reviewing changes to adopter-facing surfaces. These files carry
guarantees — invariants that must hold for every downstream consumer.

For each changed file, identify what it guarantees:
- templates/work-item.md: five-section structure, no frontmatter, no lifecycle state machine
- templates/curate.md: Steps 0-6 in order, work-item savepoint updates in Step 3
- templates/audit-context.md: Steps 1-8 in order, work-item reachability in Step 5, framework-version drift in Step 6
- docs/GUIDE.md: all claimed paths resolve, no broken anchors, version badge matches CHANGELOG
- adopt.md: every step is executable by an agent that has only URLs and no clone; no step
  instructs a copy that would strip frontmatter; assess/adopt/update stay three separate prompts
- tests/lint/run.sh: deterministic checks, no network calls, explicit allowlists not blanket skips
- scripts/*.sh: verifying and mutating modes stay distinct; a no-op run and a clean run are
  distinguishable in the output; exits non-zero on the failure it exists to detect
- templates/README.md: naming map covers all templates, tool-specific paths correct,
  every skill carries its scope (user-global or project-local)

For each guarantee: does the change preserve it? Flag any weakening.

Then ask: is the change broader than its stated intent? (Example: a change described as
"fixing rule 1 for .claude/" that actually relaxes the check for all gitignored dirs.)

Report: GUARANTEE OK or GUARANTEE WEAKENED for each surface touched.
```

### Lens: adversarial (all tiers)

```
You are an adversarial reviewer. Your job is to refute the changes — find what breaks,
what edge cases fail, what assumptions don't hold.

For each changed file:
1. What is the change trying to accomplish?
2. What could go wrong? Try to find at least one concrete failure scenario.
3. Are there silent failure modes — things that would pass but be wrong?
4. If this is a self-test or lint change: what real failure does the weaker test now pass silently?
5. If this touches templates: what would a downstream adopter break by following the new version?

Go in assuming the change is refutable and try to break it. Report REFUTED with a
**concrete** failure — a triggering input, an edge case, or a contradiction between
two things the change now asserts. Prose contradictions count and often have no
triggering input; do not withhold one for lacking a repro. Report NOT REFUTED only
after a thorough attempt has failed to produce any of those.

**A claim that needs a measurement gets one, gets hedged, or is not ready.**
Two shapes need one, and they are the same failure from two sides:

- **Negatives.** "0 rows", "not called anywhere", "nothing reads it", "no other
  callers", "all clean" — a negative cannot distinguish a real absence from a
  broken instrument, an empty sample, or a mismatched population. Report the
  claim, the command that produced it, and **what a non-empty result would have
  looked like**. If you cannot state the shape of a positive, the claim is not
  ready to make. Where a negative is being used to *license a loosening* — "no
  false positives", "nothing was affected" — seed a positive first: a run that
  finds nothing cannot distinguish a fixed check from a disabled one.
- **Absolutes in descriptions.** *every*, *all*, *always*, *never*, *none*,
  *zero*, *cannot*, *impossible*, *no … can*, *not permitted*, *guaranteed* —
  in a claim about how a tool, spec or codebase **behaves**. An absolute in an
  *instruction* is a decision and is fine: `never edit in place` prescribes.
  An absolute in a *description* is a measurement, and it ships unmeasured by
  default. Each needs a measurement with its scope, a spec citation, or a hedge
  ("in the cases measured", "for well-formed tables") — and if none of those is
  available, the claim is not ready to make.

**A claim whose measurement cannot be taken yet is a finding in its own right.**
Report it as one. Do not attempt to register it here: this lens reports, it does
not write, and a hypothesis needs a Method and a Revisit trigger that the
reviewer of a diff is not placed to supply. `templates/hypothesis-log.md` says
what an entry requires, and it is written **by the author, at the time of the
claim** — not deferred to `/curate`, which runs at end of session and so
reinstates exactly the delay the log exists to remove. `/curate` Step 0 sub-step 7
keeps the entries that exist honest, reviewing open ones for staleness and due
dates;
it does **not** detect a claim that never got an entry, so writing it at claim
time is the only thing that does.

This is not a step to perform; it is the sentence to write. A separate
"verify your claims" step is skippable in exactly the cases where it matters.
Making the check travel with the claim is what makes omitting it visible.

Report: REFUTED or NOT REFUTED, with failure scenario if refuted. Every negative
in your report carries its command and the shape of a positive; every absolute
about behaviour carries its measurement, its citation, or its hedge.
```

### Lens: doc-accuracy (MEDIUM and HIGH)

```
You are reviewing documentation changes for accuracy against disk state.

For each documentation change:
1. Does every file path mentioned in the changed docs actually exist on disk?
2. Does every command mentioned (bash, git, etc.) use correct flags and syntax?
3. Do version numbers, dates, and references match what's actually shipped?
4. If a new template or pattern is documented, does the referenced file exist?
5. Are there internal inconsistencies — does the doc say one thing in one place
   and something else in another?

Report: ACCURATE or INACCURATE, with specific mismatch if found.
```

### Lens: shell-correctness (HIGH only, and only when shell files changed)

```
You are reviewing shell script changes for correctness and edge cases.

For each shell change:
1. set -u safe? (no unbound variables in changed paths)
2. Quoting correct? (variables in quotes, no word-splitting bugs)
3. Edge cases: empty input, spaces in filenames, missing files, unexpected exit codes
4. Does the change introduce any non-determinism (date, random, network)?
5. Are error exits explicit and loud, not silent?

Report: SHELL OK or SHELL ISSUE, with specific bug if found.
```

## Step 3 — Synthesize

Combine all lens reports. Structural hits from Step 1.5 do not enter this table — they were fixed before the lenses ran; carry their count into the Step 4 summary instead. A hit you deliberately left unfixed enters here as a BLOCKER with the lens recorded as `structural`, and the summary count still includes it.

For each finding:
- **Severity**: BLOCKER (must fix before commit) / WARNING (should fix) / NOTE (consider)
- **Lens**: which lens found it
- **File**: where
- **Finding**: what's wrong
- **Fix**: proposed fix

If any BLOCKER: recommend fixing before commit.
If only WARNING/NOTE: recommend the user review and decide.

## Step 4 — Report

```
## Review: [N] files changed, [tier] risk, [M] lenses

### Findings

| # | Severity | Lens | File | Finding |
|---|----------|------|------|---------|
| 1 | BLOCKER | adversarial | ... | ... |

### Unclassified

[Every changed file matching no tier row in Step 1, one per line — or "none".
Never omit this section. An empty one is evidence the check ran; a missing one
is indistinguishable from a check that was skipped.]

### Summary

- **Structural pre-check**: [N] markdown files checked, [N] problems
- **Lenses run**: [list]
- **Blockers**: [N] (must fix before commit)
- **Warnings**: [N]
- **Notes**: [N]
- **Verdict**: [READY TO COMMIT | FIX BLOCKERS FIRST | REVIEW WARNINGS]
```

The Unclassified list is not cosmetic and is not made moot by a HIGH file elsewhere in the same diff. An unrecognized path is usually new shipped content whose tier nobody has decided yet; naming it is what gets a row added, and until someone adds one it will keep arriving un-triaged.
