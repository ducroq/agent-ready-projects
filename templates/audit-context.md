# Audit Context

<!-- SAVE AS: ~/.claude/skills/audit-context/SKILL.md (Claude Code, USER-GLOBAL — see docs/GUIDE.md
     "Where a skill lives"; do not copy this file verbatim, its frontmatter is
     inside this comment. Prefer .claude/skills/audit-context/SKILL.md from this repo.)
     Diff an install against THAT file, never this one: the header differs by construction (#187).
     For other tools, run this as an ad-hoc prompt when needed.

     This is a skill (/audit-context) that audits the structural health
     of the layered memory system. Run monthly or after major restructuring.
     Complements /curate (session-level) with framework-level checks.

     Claude Code skills require SKILL.md as the entry point inside a
     named directory under .claude/skills/. Add frontmatter:
     ---
     name: audit-context
     description: Periodic structural audit of the layered memory system — checks for duplication, wrong-layer placement, bloat, and broken references
     disable-model-invocation: false
     --- -->

Structural audit of the agent-ready-projects layered memory system. Run monthly or after major restructuring. Complements `/curate` (session-level cleanup) with framework-level health checks.

## Step 1 — Document size

**First establish what your tool actually auto-loads, rather than assuming.** In most setups only the project file; the memory index is reached by a pointer. In Claude Code the auto-loaded `MEMORY.md` is the *user-level* one at `~/.claude/projects/<slug>/memory/`, not the in-repo file of the same name. Record what you measured: a budget that includes a file which never arrives is wrong by that file's size. If earlier audits left a budget series, say whether it measured the same set — if not, it is not a trajectory.

Then check the project file and the memory index. For each:

- **Measure characters, not lines** — `wc -c`, with `wc -l` beside it as a readability signal only. `wc -c` counts bytes, so multi-byte characters read slightly high; that error is on the safe side.
- Flag the **project file** over **35,000 characters** (soft) or **40,000** (hard) — the same numbers as `curate`'s budget; the hard one is where Claude Code itself warns
- Flag the **memory index** over ~**60 lines** (an index is a list, so lines fit; `templates/memory-index.md` notes some tools truncate at ~200). Report its characters too and say which number you acted on; no character threshold is prescribed
- If too long, identify sections that are reference material (looked up on demand, not needed every session) and propose moving them to topic files behind "Before You Start" pointers

## Step 2 — Cross-layer duplication

Check whether the same fact appears in multiple places across the layers:

- Project file (CLAUDE.md / AGENTS.md / etc.)
- Memory index (MEMORY.md)
- Topic files (memory/\*.md)
- Tool-specific auto-memory (e.g. ~/.claude/projects/ for Claude Code)

For each duplicate found, recommend which layer should be the single source of truth based on:

- Is it needed every session? → project file
- Is it navigational? → memory index
- Is it reference material loaded on demand? → topic file
- Is it user-specific (preferences, positions, local machine quirks)? → tool auto-memory

## Step 3 — Wrong-layer placement

Check for content that's in the wrong layer:

- **User-specific data in project files**: personal preferences, positions, local machine limitations → should be in tool auto-memory
- **Session navigation in the project file**: session narrative, "what I did today", task progress → should be in the memory index. **Exception, only where there is no Layer 3**: the `## Active work` pointer list `templates/project-file.md` ships for tools without auto-memory is not session narrative. Flag it as wrong-layer *only* when the project also has a memory index — two lists will disagree.
- **Always-needed constraints buried in topic files**: hard rules, thresholds, non-negotiables → should be in the project file
- **Derivable-from-code content in any memory file**: things `git log`, `grep`, or reading the source would tell you → shouldn't be persisted at all

## Step 4 — Reference integrity

For every file path mentioned in the project file, memory index, and gotcha log: verify the
file exists, and flag the broken ones.

**Run the checker; do not re-derive its rules.** `tests/fixtures/reference-integrity/refcheck.py`
in this framework's clone implements all of them — path extraction, the five resolution rungs,
placeholder and deletion markers, cross-repo gating, and the three-outcome verdict:

```bash
CLONE=~/repos/agent-ready-projects   # this framework's clone
# Repeat --sibling-root for every directory holding neighbouring repos.
python3 "$CLONE/tests/fixtures/reference-integrity/refcheck.py" \
        --sibling-root ~/repos \
        . CLAUDE.md memory/MEMORY.md memory/gotcha-log.md
```

Pass a `--sibling-root` for every directory holding neighbouring repos: rung 4 resolves
cross-repo references and, with no neighbour reachable, cannot rule. The rules are in
`tests/fixtures/reference-integrity/SPEC.md`; **read it only if you are CHANGING the checker.**

The report labels each resolution by the rung that made it, so you can read it without the
spec: **1** the path as written · **1b** relative to the referencing document · **2** as a path
suffix in the working tree · **3** runtime state the system writes · **4** inside a sibling repo
the prose names in bare text. Anything below rung 1 is enumerated, not a defect.

**Prove the checker is alive before you trust a short findings list.** Append a fabricated
path to a copy of one audited document, re-run, and confirm it is reported; a cross-repo
fabrication too, if neighbours are reachable. **A run that finds nothing cannot distinguish a
fixed check from a disabled one.** Delete the seeded copy afterwards.

**Carry that into the verdict — three outcomes, not two.** *Defects*: a rung that ran ruled a reference out or ambiguous, or a document could not be read. *Clean*: nothing found. **Coverage incomplete**: nothing ruled on, but something left undecided because **rung 4** had no neighbouring repo to run against. Name the outcome on a line of its own and enumerate the undecided in a counted section (Step 9's *Unconfirmed* bucket). Do not fold the third into *defects* — a correct repo would then fail on **where it ran** (CI, a fresh clone, a container) rather than on what it audited — nor into *clean*, where a genuine break can sit undecided. **If you automate this step**: exit 1 / exit 0 / **exit 2**, and 2 must stay non-zero, so a caller written as `check && …` behaves as before and only one that opts in (`|| [ $? -eq 2 ]`) accepts an undecided run. Run as prose, the verdict line is the output.

**Do not suppress; re-label.** Split the output into sections instead of one list — these three, plus the table's other two whenever either has members:

- **Findings** — unresolved references and collisions. These are the defects.
- **Resolved below rung 1** — every rung-2, rung-3 and rung-4 resolution of an *unmarked* path, *enumerated with what it resolved to* (`config/settings.py → packages/worker/config/settings.py`); a marked path excused at rung 2 or 3 is counted in the skip section instead. Not defects, not "worth correcting", but visible, so a wrong-twin match can be spotted.
- **Skipped as asserted-absent** — paths the document states are gone.

**A sixth section, `PATH SHAPES NOT EXTRACTED`,** lists backticked shapes the extractor never
examines — brace groups, bracket placeholders, root-absolute, Windows and UNC paths. **Not
findings**, only unchecked; a CLEAN verdict says nothing about them.

**Report what the extractor dropped**: the file extensions in the working tree that the whitelist does not cover. The checker counts the cost as `REFERENCES NOT EXTRACTED`, printed before the findings; `--ext pdf,tex` widens the whitelist for the run — a documents repo can otherwise lose most of its references.

**Expect a residue; do not loosen the check to erase it.** Some references are *meant* not to resolve: instructional placeholders, files a runbook tells the reader to create, units owned and deployed by another repo. **Mark them** — `<!-- placeholder -->` **immediately after** the path, same line (`` `src/aggregators/<name>.py` <!-- placeholder --> ``). **Span-scoped**: it covers the nearest path *before* it, never the line or the rest of a row, so in a table it goes in that path's own cell; a marker at the row's end silently excuses the row's last path instead. Marked paths move to a counted section. **That form and no other**: a marker the checker never learned leaves the finding in the list. A short residue is a healthy result. **Zero is not the target**; a change that drives the count to zero has almost certainly disabled the check rather than fixed it.

If the same non-finding repeats on consecutive runs, fix the check — **but first distinguish wolf-crying from residue**: a repeated finding that is an acknowledged placeholder, a cross-repo unit, or a file the reader is told to create is residue; mark it rather than loosening the extractor. Seed a break first (above); if it is caught and the repeat remains, the repeat is residue and the check is fine. **Loosening any check is the most dangerous edit you can make**: a run that found nothing real measures specificity, not sensitivity, so seed the failures the change newly *permits*. (`SPEC.md` carries the checker-specific rules.)

For every "Before You Start" pointer:
- Verify the target file exists
- Check that the trigger language is task-based ("when doing X, read Y") not passive ("see Y")

## Step 5 — Topic file and work-item reachability

**First establish whether this project has a Layer 3 (memory index plus topic files) by looking for it, not by guessing the tool.** Find the index wherever this project keeps it — `MEMORY.md` at the root, `memory/MEMORY.md`, or the path the project file's own pointer row names — and treat topic files beside it as part of it. Do not gate on one hardcoded path; that reports "no Layer 3" for a project that has a complete one elsewhere.

- **Topic files present but no index**: that is the finding, not a reason to skip — the most broken Layer 3 state there is.
- **Layer 3 present**: check that every topic file has a task-triggered pointer in the "Before You Start" table. Flag orphaned topic files — they exist but no pointer leads to them, so an agent will never know to load them.
- **No Layer 3 anywhere** — the case for every tool without auto-memory, where `docs/GUIDE.md` says plainly that everything goes into the project file: report the *topic-file* half as **not applicable, and say why**. A skipped check and a passing check are indistinguishable in a report that says neither.

**The work-item half runs either way — only the artifact changes.** Check that every file in `docs/work-items/` (other than `README.md`) has a pointer and that no pointer names a missing file. Pointers live in the memory index's Current State section where Layer 3 exists, otherwise in the project file's **Active work** section. **Report which one you read — and if *both* exist, that is the finding**: name the memory index as canonical and propose removing the other. Flag pointers to finished work: only in-progress items belong in either list, and in the project file that list counts against Step 1's size budget.

**Do not substitute `docs/*.md` for the topic files** — it holds essays and reference material, and every one would report as an orphan — **and do not invent another home for the work-item pointers.**

<!-- provisions: memory-index-row -->

**Check the row's wording, not just its presence, and quote the canonical one when proposing it.** `templates/project-file.md` ships it as:

> `| Picking up where the last session left off | memory/MEMORY.md …`

That is a **situation the agent recognises**. Describing it by *when it fires* — "a row whose trigger fires at session start" — is a category, and an agent satisfying the finding will write what the finding described. Propose the canonical wording or an equivalent situation ("resuming an interrupted migration", "returning after a week away"), never a category.

**Two rows whose triggers are identical up to a parenthetical are a finding on their own**; one row reading `Starting any session (framework drift)` is fine, and `templates/project-file.md` ships one. Take each row's **first cell** (between the first and second `|`), strip any trailing ` (…)` or ` — …`, and flag any two rows whose remainders are then *equal* — not merely sharing a prefix: `Editing a skill` and `Editing templates` are two good triggers.

**For a row whose function is to fire on a situation, presence is not adoption — the wording is the artifact.** Report the row's actual text, so a reader can judge it rather than trust a tick.

## Step 6 — Framework version drift

Find this project's adopted framework version and compare it against the latest in `agent-ready-projects/CHANGELOG.md`.

Search case-insensitively for `agent-ready-projects` followed by a version-shaped token anywhere in the project file, and read the surrounding line. **Do not assume a single stamp format** — adopters write at least four: `agent-ready-projects: v1.14.0`, `framework: agent-ready-projects v1.14.0` in YAML frontmatter, `- **agent-ready-projects**: v1.12.0` as a bullet, and prose inside a status paragraph.

- **No stamp found**: flag it. Without one there is nothing to compare, and drift accumulates unnoticed. Propose adding one.
- **Behind the latest**: list the intervening versions and, for each, whether it applies here. Do not auto-update — adopting is the engineer's call.
- **Behind, but with a recorded reason**: a stamp that says a version was *reviewed and declined* is current, not stale. Report it as reconciled and move on.

When proposing a stamp, prefer a short reconciliation record to a bare number: what was adopted, what was declined, and why.

## Step 7 — Gitignore correctness

Check what's tracked vs untracked:

- Project-level context (project file, memory index, gotcha log, topic files) should be tracked in git
- User-specific data (tool auto-memory, personal notes, local credentials) should be gitignored
- Flag any mismatches

## Step 8 — Retirement: what has each check ever caught?

**Run this every audit, and record the answer.** For each step above, and each sub-step of the project's other recurring skills, name what it has caught **in this project** since the last audit. No catch this audit is not yet a problem; **no catch in its whole recorded history** is.

- **A check whose only appearances in the record are its own false positives is not immature — it has no subject.** One grep tells you, from day one.
- **Before retiring, find out whether the class is covered elsewhere.** If it is, say by what, and whether the cadence changes — a per-session check replaced by a monthly one is still a loss. If not, retiring leaves the class unchecked; make that the explicit decision, not a side effect.
- **Retire by deleting, not by moving.** Relocating the prose to a rationale file removes the reading cost but keeps the work; remove both.
- **Leave a tombstone that says what would justify bringing it back**: *retired on <date>, never caught anything, do not re-add without a catch to point at*. Without it the check returns the next time someone thinks of it fresh.
- **A check that has never fired may be preventing what it checks for, and the record cannot tell you which.** Say which retirements rest on that ambiguity instead of deciding it silently. A check that prescribes nothing an author would otherwise do has no such defence.

**Record each finding with the step that found it**, so the next audit can answer this question; without attribution the default becomes keeping everything.

## Step 9 — Report

Open with the **verdict** — *defects*, *clean*, or *coverage incomplete*, Step 4's three outcomes — on a line of its own, above everything else, so a reader of only the first line cannot mistake an undecided run for a clean one.

Then summarize findings by severity:

- **Fix now**: broken references, misplaced secrets/credentials, orphaned files
- **Fix soon**: duplication, bloated auto-loaded files, passive pointer language
- **Consider**: minor size optimizations, optional restructuring

Plus one bucket that is not a severity, because it is not a defect: **Unconfirmed** — Step 4's undecided references, naming the rung that could not run and why. Populate it whenever there are any, not only on a *coverage incomplete* run, and never under *fix now*. State an empty bucket too — it separates "everything was checked" from "everything checkable was checked".

For each finding, state what's wrong, where, and propose a specific fix. Don't make changes without showing the plan first.
