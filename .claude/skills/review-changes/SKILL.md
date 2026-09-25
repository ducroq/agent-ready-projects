---
name: review-changes
description: Diff-driven pre-commit review — picks review lenses based on what changed, from single-pass adversarial to full multi-model battery
disable-model-invocation: false
---
Pre-commit review of pending changes. Scope and depth are driven by what changed, not a fixed checklist.

## Step 1 — Diff and classify

Resolve the baseline first; everything below reads `$BASE`. It is the default branch — `@{u}` only on the default branch itself, since on a pushed, unmerged branch `@{u}` is empty.

```bash
# Every arm ends in a success, or `set -e` aborts before the fallback that is the
# one place reporting the failure.
BASE=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD) ||
# Fully qualified: `rev-parse` resolves refs/heads/ first, so a LOCAL branch named
# `origin/main` would win and silently reintroduce #64.
BASE=$(for c in refs/remotes/origin/main refs/remotes/origin/master main master; do
         git rev-parse --verify --quiet "$c" >/dev/null && { printf %s "$c"; break; }; done) || :
# On the default branch HEAD...HEAD is empty, so the upstream is the baseline.
if [ -n "${BASE:-}" ] && [ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" = "${BASE##*/}" ]; then
  BASE=$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || printf %s '')
fi
# An empty or dangling BASE diffs to nothing, which is what a clean tree yields.
# The fallback is NOT "the whole branch": three-dot excludes the root's own
# content, so a one-commit repo diffs to NOTHING (#149). No `${BASE:-sentinel}`
# placeholder — any sentinel word is a legal branch name.
ROOTFALLBACK=          # initialised, or a later `set -u` reader aborts on it
{ [ -n "${BASE:-}" ] && git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null; } || {
  # `|| :` is load-bearing: without it `set -eo pipefail` kills the shell here and
  # prints nothing. Four SHELL-OPTION modes are seeded in the fixture — the axis
  # matters, because the block was broken only in the ones without `set -e`.
  BASE=$(git rev-list --max-parents=0 HEAD 2>/dev/null | tail -1) || :
  : "${BASE:?no commits in this repository — nothing can be reviewed}"
  ROOTFALLBACK=1
  # PRINTED as well as set: a shell variable does not reach the next tool call and
  # this one degrades toward PERMITTING a clean result. Key off the printed token.
  { echo "BASELINE UNRESOLVED (ROOTFALLBACK=1) — fell back to root commit $BASE,"
    echo "  whose OWN content \"\$BASE\"...HEAD EXCLUDES. Run 'git show --stat $BASE'"
    echo "  too. Report this as a FINDING, never a clean result — Step 1.5's file"
    echo "  list carries the same term and the same hole."; } >&2
}

# #153 — a baseline can RESOLVE and still leave every term legitimately empty
# (HEAD already contained in $BASE). No other guard fires, so unreviewed commits
# report as a clean review. A diagnostic, not an abort.
# ⚠️ The equality case is EXCLUDED, or this fires on the commonest pre-commit
# state there is, and a guard that cries wolf is skipped.
if git merge-base --is-ancestor HEAD "$BASE" 2>/dev/null &&
   [ "$(git rev-parse HEAD)" != "$(git rev-parse "$BASE^{commit}" 2>/dev/null)" ]; then
  { echo "HEAD IS CONTAINED IN $BASE — nothing on this branch is absent from the"
    echo "  baseline, so an empty diff below is expected and is NOT a clean review."
    echo "  If you expected changes you are not on the branch you think: check"
    echo "  'git branch --show-current' and 'git log --oneline $BASE..<your-branch>'."
    echo "  Report this as a FINDING, never as a clean result."; } >&2
fi

git diff --shortstat "$BASE"...HEAD    # committed on this branch
git diff --shortstat                   # unstaged
git diff --cached --shortstat          # staged
# #145 — no `git diff` variant lists a file git has not seen, so the carve-out for
# "any new file in a HIGH path" fired on a class this step could not observe.
# Step 1.5 having its own `ls-files` is no substitute: it checks markdown, not tiers.
# ⚠️ ROOT-ANCHORED on purpose: `ls-files` defaults to the CWD SUBTREE while every
# term above is repo-wide, and this skill runs with the cwd of whatever repo is
# under review.
git -C "$(git rev-parse --show-toplevel)" -c core.quotePath=false \
    ls-files --others --exclude-standard    # untracked, not ignored
```

**Run Step 1.5 in the same shell invocation as this block**; a fresh shell does not inherit `$BASE`.

List the changed files with `git diff --stat "$BASE"...HEAD`, `git diff --stat`, `git diff --cached --stat`, `git diff --summary -M "$BASE"...HEAD` (renames, modes, binaries and submodules are invisible to `--stat`) and `git ls-files --others --exclude-standard` — an untracked file is a changed file and gets a tier.

**Read `.claude/review-profile.md` now.** It holds this project's risk tiers, guarantee surfaces, test baseline and carve-outs, plus three optional, additive sections: **Project lenses** and **Project additions to the shipped lens prompts** (used in Step 2), and **Project procedure kept with the profile** (run it here). A profile without them (written before v1.43.0) is not an error.

**If `.claude/review-profile.md` does not exist, STOP and say so** — do not proceed on defaults or invent a table, since every path would fall through to LOW. Point the reader at `templates/review-profile.md` in the framework.

Classify each changed file using the profile's tier table, then apply the magnitude gate. Its carve-outs always apply; a profile may add to them but never remove one.

### Magnitude gate

**Always full depth, regardless of size:**

- **`.gitignore`** — one line can expose private content in a public repo.
- **Renames and moves** — zero lines under `-M`, while every reference to the old path breaks.
- **Permission changes** — zero lines, visible only with `--summary`. A `chmod -x` makes a shipped script unrunnable downstream.
- **Binary files and submodule pointers** — a submodule bump changes one line and can move any amount of code.
- **Any change to a shell script or an executable, wherever it lives** — shell breaks in one character, and a small edit would otherwise lose the shell-correctness lens, which is the reason those paths are HIGH at all.
- **Any non-frontmatter edit to a reference install** (`.claude/skills/**`) — a defect there ships to every install derived from it.
- **Frontmatter edits to those same files** — removing one `---` silently unregisters a skill.
- **A new executable, or any new file in a HIGH path** — its tier has not been decided yet.
- **Any diff that removes or loosens a check** — a deleted guard, a weakened assertion, a broadened exclusion. Loosenings are characteristically a handful of lines.

**Otherwise size sets the depth** — the whole change that will land, all four terms together:

```bash
git diff --shortstat "$BASE"...HEAD    # committed on this branch
git diff --shortstat                   # unstaged
git diff --cached --shortstat          # staged
# Untracked lines count too — none of the three terms above sees them (#145).
# No `xargs -r` (a GNU extension) and no plain `xargs` either: on empty input that
# runs `wc -l` with no argument, which reads stdin and BLOCKS on a terminal. The
# form below prints 0 on an empty list. ⚠️ Not verified on BSD/macOS.
# ⚠️ `-z`, not a plain list: `ls-files` C-QUOTES any path with a non-ASCII byte, a
# tab or a newline, and `wc -l < "$f"` then opens nothing — measured 5 against a
# true 105. Same quoting hits the TIER listing, hence `core.quotePath=false`.
# `|| echo 0` keeps a broken symlink from aborting the stream under `set -e`.
git -C "$(git rev-parse --show-toplevel)" ls-files -z --others --exclude-standard |
  while IFS= read -r -d '' f; do wc -l < "$f" 2>/dev/null || echo 0; done |
  awk '{ n += $(1) } END { print n + 0, "untracked lines" }'
```

When the line count and your read of the change disagree, the line count is wrong: escalate.

| Changed lines | Depth |
|---------------|-------|
| **< 20** | One adversarial pass |
| **20–200** | Path tier as above |
| **> 200** | Full battery, whichever tier the paths fall in |

Run the single pass in a **fresh context** (a subagent, or a pass that re-reads the diff from scratch), never in the context that wrote the change. If only LOW files changed and the gate does not escalate, run Step 1.5, one adversarial pass, then Step 3. Where gate and tier disagree, the gate wins.

**A changed file matching no pattern is MEDIUM — HIGH if executable or copied into an adopter's tree — and is named under "Unclassified" in the report**, even when a HIGH file makes the tier moot.

If no files changed, report "nothing to review" and stop — unless the block printed `BASELINE UNRESOLVED` or `HEAD IS CONTAINED IN`, which is a finding, never a clean result.

## Step 1.5 — Structural pre-check

Runs at **every tier and every magnitude**, before any lens, on every changed markdown file. It catches markdown that reads fine in the diff but renders wrong — chiefly a `|` in a table cell, whose excess cells GFM drops silently.

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
    # `$(0)`, never `\$0` — skill arguments are substituted into the body, so a bare
    # `\$0` arrives as an argument word and this program examines a constant while
    # printing what a clean run prints (#77).
    # BOM: a SUB with an OCTAL escape, never `substr(...) == "\xef..."` — `\x` is a
    # gawk extension and the length is bytes in one awk, characters in another.
    # ⚠️ Octal does not settle portability either: one-true-awk in a UTF-8 locale
    # was measured BY AN ADOPTER, not here, not to strip it — costing a false
    # positive, not silence (#151, #164).
    { if (NR == 1) sub(/^\357\273\277/, "")
      sub(/\r$/, "") }              # CRLF: strip first, or isdelim() never matches
                                     # and no table in the file is examined (#52).
    # YAML frontmatter, skipped whole (#52). ⚠️ Line 1 only ARMS the skip and the
    # first non-blank line decides: a leading `---` is also a thematic break, and
    # opening on it alone SILENCED whole well-formed files (#151). Blank lines and
    # YAML comments are scanned past, not decisive. Residual cost is a false
    # positive, not lost detection. Do not widen without reading the rationale.
    # `\047` is an apostrophe as OCTAL and has to be: a literal one closes the
    # single-quoted shell string this program lives inside (#105, lint rule 11).
    NR == 1 && $(0) ~ /^---[ \t]*$/ { fmpend = 1; next }
    fmpend && $(0) ~ /^([ \t]*|[ \t]*#.*)$/ { next }
    fmpend { fmpend = 0
             if ($(0) ~ /^["\047]?[A-Za-z_][A-Za-z0-9_.-]*["\047]?[ \t]*:/) { infm = 1; next } }
    infm && $(0) ~ /^(---|\.\.\.)[ \t]*$/ { infm = 0; prev = ""; next }
    infm { next }
    {
      # ⚠️ DO NOT WIDEN THE 3-SPACE STRIP — the three refuted attempts are in the
      # Known blind spots note below. Each bought a worse class, ONE of them
      # SILENCING a whole file, against a defect with zero instances in a
      # 5,168-file estate (#150).
      bare = $(0); sub(/^ ? ? ?/, "", bare)
      if (bare ~ /^```/ || bare ~ /^~~~/) {
        c = substr(bare, 1, 1); n = 0
        while (substr(bare, n + 1, 1) == c) n++
        if (fch == "") { if (n >= 3) { fch = c; flen = n } }
        else if (c == fch && n >= flen) fch = ""
        intbl = 0; prev = ""; next
      }
      if (fch != "") next
      # Emphasis spans — correct in the diff, wrong when rendered (#50). NARROW by
      # design: only TWO backticked tokens abutting `**` inside one open bold run.
      # ⚠️ The one-token form was measured to corrupt under prettier 2 and 3.8.1
      # (fixed in 3.9.6) and passes here in silence — a BACKSTOP, not coverage
      # (#151, #158). Each code span is masked to one character so
      # bold runs pair positionally; adjacency is the discriminator.
      # A span opens on a run of N backticks and closes on the next run of
      # exactly N, as in CommonMark, so a double-backtick span QUOTING this shape
      # is one span, not two risky tokens (#159). An unclosed run is literal.
      { masked = ""; rest = $(0)
        while (match(rest, /`+/)) {
          s = RSTART; n = RLENGTH; after = substr(rest, s + n); t = after; off = 0; cl = 0
          while (match(t, /`+/)) {
            if (RLENGTH == n) { cl = off + RSTART; break }
            off += RSTART + RLENGTH - 1; t = substr(t, RSTART + RLENGTH)
          }
          if (!cl) { masked = masked substr(rest, 1, s + n - 1); rest = after; continue }
          inner = substr(after, 1, cl - 1)
          if (inner ~ /^ .* $/) inner = substr(inner, 2, length(inner) - 2)
          mark = "\002"
          if (inner ~ /\*\*$/ || inner ~ /^\*\*/) mark = "\001"
          masked = masked substr(rest, 1, s - 1) mark
          rest = substr(after, cl + n)
        }
        masked = masked rest
        inb = 0; nrisk = 0
        for (i = 1; i <= length(masked); i++) {
          if (substr(masked, i, 2) == "**") { inb = 1 - inb; i++; continue }
          if (inb && substr(masked, i, 1) == "\001") nrisk++
        }
        # The backtick test stops a literal \001/\002 byte masquerading as a masked
        # span: without it a line with no backticks reported "two backticked
        # tokens", which is simply false.
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
          # Unclosed frontmatter leaves `infm` set, so `infm { next }` swallows the
          # rest of the file and the check prints what a clean run prints (#103).
          # ⚠️ It says NO CHECK RAN, not "no table": that `next` sits above the
          # fence and emphasis blocks too, so all three are lost (#144).
          if (infm) printf "%s: unclosed YAML frontmatter — no check ran on any line of this file\n", F }
  ' "$f"
done
```

Fix every hit before running the lenses:

- *Row with excess cells*, or *header that disagrees with its delimiter row*: escape as `\|` (inside backticks too), or move the command out of the table.
- *Unclosed code fence*: close it.
- *Two backticked tokens abutting the bold marker inside one bold span*: separate them, or take one out of the bold run.
- *Unclosed YAML frontmatter*: no check ran on any line of that file. Close the delimiter and **run Step 1.5 again**.

Treat a row hit as real until you have looked at it. Known false positives: a setext heading, a spaced `- - -`, frontmatter not at line 1, a table inside a fenced block indented four or more spaces, and unrecognised frontmatter whose closing `---` reads as a delimiter row. Do not "fix" those. **Known blind spots:** tables in blockquotes or with no delimiter row, the one-token emphasis form; a lone-CR file can go **entirely silent**. Before widening any of these trades, read <https://github.com/ducroq/agent-ready-projects/blob/master/docs/rationale/review-changes.md> <!-- lint-skip: maintainer-path — a URL, not a repo-relative path: it resolves for a reader with no such directory. -->.

A clean run and an empty file list both print nothing, so **report the count alongside the result:**

```bash
  : "${BASE:?run the Step 1 baseline block in THIS shell invocation — a fresh shell does not inherit it}"
{ git -c core.quotePath=false diff --name-only
  git -c core.quotePath=false diff --cached --name-only
  git -c core.quotePath=false diff --name-only "$BASE"...HEAD 2>/dev/null
  git -c core.quotePath=false ls-files --others --exclude-standard; } |
  sort -u | grep -c '\.md$'
```

If it is zero while Step 1 listed markdown files, the pipeline is broken, not the changes clean.

## Step 2 — Execute review lenses

For each lens, spawn a subagent with the prompt below; run lenses concurrently. Also run the profile's `Project lenses`, and append its `Project additions to the shipped lens prompts` to the matching prompts.

**Every path with a guarantee must sit in the profile's HIGH row**, or the HIGH-only lens never fires on it. Check each guarantee entry's tier.

### Lens: guarantee-preservation (HIGH only)

```
You are reviewing changes to adopter-facing surfaces. These files carry
guarantees — invariants that must hold for every downstream consumer.

For each changed file, identify what it guarantees. **The surfaces and their
guarantees are listed under "Guarantee surfaces" in `.claude/review-profile.md`** —
read that file; they are project-specific and are not reproduced here.

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
reinstates exactly the delay the log exists to remove. `/curate` Step 0 sub-step 5
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

Combine all lens reports. Step 1.5 hits were fixed before the lenses ran; carry their count into the Step 4 summary. A hit you deliberately left unfixed enters here as a BLOCKER with lens `structural`.

For each finding:
- **Severity**: BLOCKER (must fix before commit) / WARNING (should fix) / NOTE (consider)
- **Lens**: which lens found it
- **File**: where
- **Finding**: what's wrong
- **Fix**: proposed fix

If any BLOCKER: recommend fixing before commit.
If only WARNING/NOTE: recommend the user review and decide.

## Step 3.1 — Mechanization triage

No subagent. For **each** finding, answer: **could a deterministic check have found this?**

- **Yes** — name what it greps, parses or runs, and the file it lands in.
- **No** — say why, in four words or fewer (`needs intent`, `one-off`, `judgment call`). A blank is not an answer.

Record each named check in the gotcha log's **Mechanized** table as `proposed`, with `<!-- placeholder -->` right after its path in the same cell (`` `tests/lint/count-commands.sh` <!-- placeholder --> ``) so a reference audit does not report it dead. It becomes `live` only once a seeded positive has made it go red (<https://github.com/ducroq/agent-ready-projects/blob/master/docs/seeded-defects-and-ablations.md>). Check it measures the claim, not something adjacent (bytes for content, a file listed for a file changed).

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

### Mechanizable

[One row per finding above, by number. Never omit this section: an empty one is
evidence the triage ran, a missing one is indistinguishable from a triage that
was skipped.]

| # | Check it becomes, or why not | Status |
|---|------------------------------|--------|
| 1 | `grep -c ...` in tests/lint/<rule>.sh | proposed |
| 2 | needs intent | — |

### Summary

- **Structural pre-check**: [N] markdown files checked, [N] problems
- **Lenses run**: [list]
- **Blockers**: [N] (must fix before commit)
- **Warnings**: [N]
- **Notes**: [N]
- **Mechanizable**: [N] of [M] findings; [K] rows added to the Mechanized table
- **Verdict**: [READY TO COMMIT | FIX BLOCKERS FIRST | REVIEW WARNINGS]
```

## Step 5 — Fixing, and whether to run another round

Fixing is a major source of new defects.

- A fix is a change, and takes the tier of the file it lands in.
- Re-read the steps that consume what you changed.
- Fix one finding at a time when findings touch the same file.
- Name what the fix could have broken; that is the next round's scope, if the cap allows one.

### Round cap

A round is one pass of the lens set, however many lenses it contains — not a re-run of a deterministic check. **Two rounds maximum.** A third runs only when round 2 found **the same defect a second time**, anywhere — a class — and then enumerate every site the class could occupy and check them all before running it. The cap is a cost decision: on the one measured four-round sequence, tokens per acted finding rose each round, compared within one target. Re-open it on a measured flattening of that per-target ratio, or on a class of defect a capped round demonstrably shipped, not on one missed finding.

### Budget the round before you spawn it

State the lens set and the ceiling before starting; record the cost after. A lens stopped part-way returns nothing.

- Do not run a lens for a class a deterministic check covers *completely*; where coverage is partial, run it and say which part the check already settled. Read the Mechanized table in Step 1, before choosing lenses: a `live` row may narrow a mandated lens, never skip it: a row covers one shape, a lens a class.
- Never collapse lenses into the author's own context. Fewer independent reviewers is a legitimate saving; none is not.
