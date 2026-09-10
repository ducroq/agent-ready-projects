---
name: audit-context
description: Periodic structural audit of the layered memory system — checks for duplication, wrong-layer placement, bloat, and broken references
disable-model-invocation: false
---

Structural audit of the agent-ready-projects layered memory system. Run monthly or after major restructuring. Complements `/curate` (session-level cleanup) with framework-level health checks.

## Step 1 — Document size

**First establish what your tool actually auto-loads, rather than assuming.** Only the project file is auto-loaded in most setups; since ADR-001 put Layer 3 in the repo, the memory index is reached by a pointer, not by the tool. In Claude Code the auto-loaded `MEMORY.md` is the *user-level* one at `~/.claude/projects/<slug>/memory/`, which shares a name with the in-repo file and is not it. Record what you measured — a size budget that includes a file which never arrives is wrong by the size of that file, and the error is invisible because the number still looks reasonable. If a budget series exists from earlier audits, say plainly whether it measured the same set; a trajectory across a change in what is being measured is not a trajectory.

Then check the project file and the memory index. For each:

- **Measure characters, not lines** — `wc -c`, with `wc -l` beside it as a readability signal only. *(`wc -c` counts bytes, so a file with multi-byte characters reads larger than its character count — `curate` sub-step 8 carries the same caveat. On this framework's own project file the gap is ~2%: 29,479 bytes to 28,915 characters. Budget in bytes and the error is on the safe side.)*
- Flag the **project file** over **35,000 characters** (soft) or **40,000** (hard) — the same two numbers `curate`'s budget uses, on purpose: the hard one is where Claude Code itself warns, the soft one leaves headroom
- Flag the **memory index** over ~**60 lines**, in lines deliberately: an index is a list, so a line is a unit of content there in a way it is not for prose (`templates/memory-index.md` separately warns that some tools truncate at ~200 lines). Report its characters too and say which number you acted on; no character threshold is prescribed, because none has been derived
- If too long, identify sections that are reference material (looked up on demand, not needed every session) and propose moving them to topic files behind "Before You Start" pointers

**Why characters for the project file.** This step and `curate`'s budget govern the same file and used to return opposite verdicts on it: **measured 2026-08-12**, 173 lines read as *73% over* here while 24,633 characters read as *comfortably under* there. A markdown source line has no length limit, so the two cannot be reconciled — that file averaged **142 characters per line**, being prose and wide table rows rather than code, and by 2026-08-26 it had drifted to 179 lines / 28,915 characters / 162 per line without the ratio's lesson changing. This step runs monthly and `curate` every session, so the weaker instrument was the one driving the expensive restructuring work.

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
- **Session navigation in the project file**: session narrative, "what I did today", task progress → should be in the memory index. **One exception, and only where there is no Layer 3**: the `## Active work` section `templates/project-file.md` ships for tools without auto-memory is the pointer list, not session narrative, and it belongs there because the project file is the only always-loaded artifact those tools have. Flag it as wrong-layer *only* when the project has a memory index too — then there are two lists, and they will disagree.
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

Pass a `--sibling-root` for every directory that holds neighbouring repos: rung 4 resolves
cross-repo references, and with no neighbour reachable it cannot rule, which is what the third
verdict is for. ⚠️ **The rules are specified in `tests/fixtures/reference-integrity/SPEC.md`,
beside the code. Read it only if you are CHANGING the checker** — an audit does not need it,
and an always-loaded copy of an algorithm the script already runs is a second thing to get wrong.

The report labels each resolution by the rung that made it, so you can read it without the
spec: **1** the path as written · **1b** relative to the referencing document · **2** as a path
suffix in the working tree · **3** runtime state the system writes · **4** inside a sibling repo
the prose names in bare text. Anything below rung 1 is enumerated, not a defect.

⛔ **Prove the checker is alive before you trust a short findings list.** Append a fabricated
path to a copy of one audited document, re-run, and confirm it is reported; a cross-repo
fabrication too, if neighbours are reachable. **A run that finds nothing cannot distinguish a
fixed check from a disabled one.** Delete the seeded copy afterwards.

**Then carry that distinction into the run's verdict, not only into its prose — three outcomes, not two.** *Defects*, when a rung that actually ran ruled a reference out or ambiguous, or a document could not be read. *Clean*, when nothing was found. And a third, **coverage incomplete**, when nothing was ruled on but something was left undecided because **rung 4** had no neighbouring repo to run against. Name which one the run reached, on a line of its own, and enumerate the undecided in a counted section — Step 8 has a bucket for them. Collapsing the third state into *defects* is what makes this step useless as a gate: a correct repo whose neighbours are simply not checked out — CI, a fresh clone, a container — then fails on **where it ran** rather than on what it audited, and a gate that fires on its environment trains its reader to ignore it. Collapsing it into *clean* is worse, because with no neighbour reachable a genuine break is in that same bucket. **If you automate this step**, that is exit 1 / exit 0 / **exit 2**, and 2 must stay non-zero: a caller written as `check && …` then behaves exactly as it always did, and only one that opts in (`|| [ $? -eq 2 ]`) accepts an undecided run. Run as prose, this step returns no status at all — the verdict line is what it produces, and the numbers are for whatever you wire around it (#93).

**So do not suppress. Re-label.** Split the output into sections instead of one list — these three, plus the table's other two whenever either has members:

- **Findings** — unresolved references and collisions. These are the defects.
- **Resolved below rung 1** — every rung-2, rung-3 and rung-4 resolution of an *unmarked* path, *enumerated with what it resolved to* (a marked path excused at rung 2 or 3 is counted in the skip section instead) (`config/settings.py → packages/worker/config/settings.py`). Not defects, and not presented as "worth correcting" — but visible, so a reader who knows the file was deleted from `packages/api` can see it matched the wrong twin.
- **Skipped as asserted-absent** — paths the document states are gone.

**Report what the extractor dropped.** List the file extensions present in the working tree that the whitelist does not cover. Skips are silent by nature; every other rung has to name itself, and skips should too.

**Expect a residue, and do not loosen further to erase it.** Some references are *meant* not to resolve: instructional placeholders, files a runbook tells the reader to create, units owned and deployed by another repo. **Mark them** rather than tolerating them — that is what the placeholder skip above is for, and it moves them out of the findings list into a counted section instead of leaving them to be re-dismissed every audit. What remains after marking is the genuine residue, and a short list is a healthy result. **Zero is not the target**, and a change that drives the count to zero has almost certainly disabled the check rather than fixed it.

If a check re-derives the same non-finding on consecutive runs, fix the check. A probe that cries wolf is the failure mode this framework exists to catch. **But distinguish wolf-crying from residue before touching anything**: a repeated finding that is an acknowledged placeholder, a cross-repo unit, or a file the reader is told to create is residue — mark it (above) so it stops appearing, rather than loosening the extractor that found it. Prove the check is alive by seeding a break *first*; if the seeded break is caught and the repeat is still there, the repeat is residue and the check is fine. **Loosening a check is the most dangerous edit in this file**, because the evidence for it — a run that found nothing real — measures specificity and says nothing about sensitivity. Seed the failures the change newly *permits*. A run that finds nothing cannot distinguish a fixed check from a disabled one.

For every "Before You Start" pointer:
- Verify the target file exists
- Check that the trigger language is task-based ("when doing X, read Y") not passive ("see Y")

## Step 5 — Topic file and work-item reachability

**First establish whether this project has a Layer 3 at all, by looking for it rather than by guessing the tool.** Layer 3 is the memory index plus its topic files. Find the index at whichever path this project actually uses — `MEMORY.md` at the root, `memory/MEMORY.md`, or whatever path the project file's own pointer row names — and treat topic files beside it as part of it. Do not gate on one hardcoded path: this framework's own naming map says `MEMORY.md`, `adopt.md` writes `memory/MEMORY.md`, and a gate on either one reports "no Layer 3" for a project that has a complete one.

- **Topic files present but no index**: that is the finding, not a reason to skip. It is the most broken Layer 3 state there is, and gating the step on the index would make the step silent precisely there.
- **Layer 3 present**: check that every topic file has a task-triggered pointer in the "Before You Start" table. Flag orphaned topic files — they exist but no pointer leads to them, so an agent will never know to load them.
- **No Layer 3 anywhere** — the case for every tool without auto-memory, where `docs/GUIDE.md` says plainly that everything goes into the project file: report the *topic-file* half as **not applicable, and say why**. A skipped check and a passing check are indistinguishable in a report that says neither, which is the whole reason this bullet exists rather than the step quietly doing nothing.

**The work-item half runs either way — only the artifact changes.** `docs/work-items/` is tool-independent, so check that every work-item file there (other than `README.md`) has a pointer tracking it, and that no pointer names a file that no longer exists. The pointers live in the memory index's Current State section where Layer 3 exists, and in the project file's **Active work** section where it does not. **Report which one you read — and if *both* exist, that is the finding**: two lists of the same thing disagree the moment one is updated and the other is not, so say which is canonical here (the memory index) and propose removing the other. Flag pointers to work that is finished: only in-progress items belong in either list, and in the project file that list is charged against the size budget Step 1 measures.

**Do not substitute `docs/*.md` for the topic files, and do not invent a home for the work-item pointers.** `docs/` is where this framework puts essays and reference material — a dozen files in the framework repo at v1.25.0 — so treating it as a topic-file directory reports every essay as an orphan. Checking it would have flagged every one. That is now fixed at the source rather than worked around here (#44): the project file has an **Active work** section, and all four artifacts name it.

<!-- provisions: memory-index-row -->

**Check the row's wording, not just its presence, and quote the canonical one when proposing it.** `templates/project-file.md` ships it as:

> `| Picking up where the last session left off | memory/MEMORY.md …`

That is a **situation the agent recognises**. Describing it instead by *when it fires* — "a row whose trigger fires at session start" — is a category, and an agent satisfying the finding will write what the finding described. Note the defect is the *collision*, not the parenthesis: one row reading `Starting any session (framework drift)` is fine, and `templates/project-file.md` ships one. Two rows whose triggers are identical up to a parenthetical are not, because the parenthetical becomes the only discriminator. Propose the canonical wording, or an equivalent situation — "resuming an interrupted migration", "returning after a week away" — never a category.

**Two rows whose triggers are identical up to a parenthetical are a finding on their own.** It is the observable form of the collision and it is cheap: take each row's **first cell** — the text between the first and second `|` — strip any trailing ` (…)` or ` — …`, and flag any two rows whose remainders are then *equal*. Equal, not merely sharing a leading substring: `Editing a skill` and `Editing templates` share a prefix and are two perfectly good triggers, and a substring rule reports four such pairs on this framework's own project file. An agent choosing between `Starting any session (project state)` and `Starting any session (framework drift)` is choosing by parenthetical, which is the thing a trigger exists to make unnecessary.

**For a row whose whole function is to fire on a situation, presence is not adoption — the wording is the artifact.** Report the row's actual text, so a reader can judge the shape rather than trusting a tick.

## Step 6 — Framework version drift

Find this project's adopted framework version and compare it against the latest in `agent-ready-projects/CHANGELOG.md`.

Search case-insensitively for `agent-ready-projects` followed by a version-shaped token anywhere in the project file, and read the surrounding line. **Do not assume a single stamp format** — adopters write it at least four ways: `agent-ready-projects: v1.14.0`, `framework: agent-ready-projects v1.14.0` in YAML frontmatter, `- **agent-ready-projects**: v1.12.0` as a bullet, and prose inside a status paragraph. A check that matches one format reports an *unstamped* project when the stamp is simply written differently — which is worse than no check, because it prompts work that has already been done.

- **No stamp found**: flag it. Without one there is nothing to compare, and drift accumulates unnoticed. Propose adding one.
- **Behind the latest**: list the intervening versions and, for each, whether it applies here. Do not auto-update — adopting is the engineer's call.
- **Behind, but with a recorded reason**: a stamp that says a version was *reviewed and declined* is current, not stale. Report it as reconciled and move on.

The most useful stamp is not a bare number but a short reconciliation record: what was adopted, what was declined, and why. Prefer that shape when proposing one.

## Step 7 — Gitignore correctness

Check what's tracked vs untracked:

- Project-level context (project file, memory index, gotcha log, topic files) should be tracked in git
- User-specific data (tool auto-memory, personal notes, local credentials) should be gitignored
- Flag any mismatches

## Step 8 — Report

Open with the **verdict** — *defects*, *clean*, or *coverage incomplete*, Step 4's three outcomes — on a line of its own, above everything else. A reader who takes only the first line must not be able to mistake an undecided run for a clean one.

Then summarize findings by severity:

- **Fix now**: broken references, misplaced secrets/credentials, orphaned files
- **Fix soon**: duplication, bloated auto-loaded files, passive pointer language
- **Consider**: minor size optimizations, optional restructuring

And one bucket that is not a severity, because it is not a defect: **Unconfirmed** — what this run could not decide, per Step 4's undecided references. They exist alongside defects and are not confined to a *coverage incomplete* run, so populate this bucket whenever there are any. Name the rung that could not run and why. These do not belong under *fix now*: telling someone to fix a reference that is merely unchecked is how a report stops being read. An empty *unconfirmed* bucket is worth stating too — it is the difference between "everything was checked" and "everything checkable was checked".

For each finding, state what's wrong, where, and propose a specific fix. Don't make changes without showing the plan first.
