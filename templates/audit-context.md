# Audit Context

<!-- SAVE AS: ~/.claude/skills/audit-context/SKILL.md (Claude Code, USER-GLOBAL — see docs/GUIDE.md
     "Where a skill lives"; do not copy this file verbatim, its frontmatter is
     inside this comment. Prefer .claude/skills/audit-context/SKILL.md from this repo.)
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

Check the auto-loaded files (project file and memory index). For each:

- Count lines
- Flag if over ~100 lines (project file) or ~60 lines (memory index) — these are heuristics, not hard limits
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
- **Session navigation in the project file**: "Current State", task progress → should be in the memory index
- **Always-needed constraints buried in topic files**: hard rules, thresholds, non-negotiables → should be in the project file
- **Derivable-from-code content in any memory file**: things `git log`, `grep`, or reading the source would tell you → shouldn't be persisted at all

## Step 4 — Reference integrity

For every file path mentioned in the project file, memory index, and gotcha log:
- Verify the file exists
- Flag any broken references

**First, skip negated existence assertions entirely.** A path inside `! test -f <path>` in a `<!-- verify: -->` comment asserts the file is GONE — its absence is the passing condition. This is about the reference's *intent*, not about whether the path resolves, so it has to be decided before the resolution order below and not inside it. **Prose deletion markers are the same assertion in a different costume** — `> **Deleted**: \`src/utils/full_text_fetcher.py\``, or a path inside `~~strikethrough~~`, states that the file is gone *and is correct as written*. Skip those too, or the audit will keep proposing you "fix" a line whose whole purpose is to record a removal.

**Scope every skip to the marked span, never to the line.** A line routinely retires one path and names its live replacement in the same sentence — `~~\`src/utils/old_thing.py\`~~ was removed; use \`src/utils/replacement.py\` instead.` — so skipping the line loses the successor. Measured on one adopter repo, line-scoping silently dropped 4 references on 2 lines, 3 of them load-bearing files, because session logs and ADRs use `~~done~~` as their standard completion convention and therefore carry strikethrough on their densest reference lines. Skip only the paths the marker actually covers, and **report the count of skipped paths** — a skip is the one outcome with no rung to name.

**Extract paths with an extension whitelist, not "a dot near the end".** A permissive suffix rule turns every dotted identifier (`re.sub`, `json.dumps`, `ContentItem.url`), every bare domain (`storm.mg`, `news.google.com`) and every version number (`3.1`) into a phantom reference. In one run this alone accounted for 20 phantom references. Whitelist real file extensions and extend the list when a project uses more; a reference the extractor never captures is invisible to every rung below.

**For every other path, try to resolve it before reporting it broken** — in this order:

1. **As written**, relative to the repo root.
2. **As a path suffix of a file in the working tree.** Most prose names a file by fragment, not full path: `models/temporal.py` resolves to `src/models/temporal.py`. Two constraints, both load-bearing. Match the **whole fragment**, not the bare basename — a lone `utils.py` landing on some unrelated `utils.py` is a collision, not a resolution, and a collision gets **reported**. And search the **working tree, not the git index** — `git ls-files` omits every gitignored-but-present file, which under this framework's own recommended setup means all of `memory/`.
3. **As runtime state.** A file the running system writes (`data/source_states.json`, `circuit_breakers.json`) is *correctly* absent from a development checkout. **Gitignored is necessary but not sufficient** — it means "not committed", which is not the same as "written by the running system". Require a positive signal too: the path sits in a state directory (`data/`, `state/`, `cache/`, `logs/`, `run/`, `var/`, `artifacts/`) or carries a state-file shape (`*_state.json`, `*_health.json`, `.pid`, `.sock`). And runtime state is **data** — a *source file* whose name merely contains "cache" or "state" is still source, and its absence is still a real break. Reaching the deployment host is confirmation if you can, not a requirement. **Order this rung before the sibling rung**: a file the audited repo's own runtime writes is explained *here*, and letting a neighbour with the same filename claim it first produces a provenance that is simply false.

4. **In a sibling repo — only when the reference is *marked* as cross-repo**, by carrying a sibling repo's name in the prose around it. A bare path that happens to also exist next door is a coincidence, not a resolution; without the marker this rung will quietly absorb any common path (`.claude/README.md`, `docs/ARCHITECTURE.md`) that every repo happens to have. Five details decide whether this rung works at all — each one, omitted, either reported real files as broken or resolved broken ones as clean:
   - **Match inside the sibling the same way rung 2 matches locally.** A cross-repo reference is a fragment just as often as a local one: "SiblingRepo's `deploy_filters.sh`" means `SiblingRepo/scripts/deploy_filters.sh`. Joining the fragment to the sibling root and testing existence resolves almost nothing.
   - **Strip a leading component that repeats the repo name.** `SiblingRepo/scripts/main.py` joined to the SiblingRepo checkout yields `SiblingRepo/SiblingRepo/scripts/main.py`. Try the stripped form too.
   - **Find siblings at more than one nesting depth.** Repos nest unevenly (`~/repos/<repo>` *and* `~/repos/<org>/<repo>`), so globbing only the immediate parent misses whole trees.
   - **Carry rung 2's collision rule across with its matching.** Two files in the sibling matching the same fragment is an ambiguity, not a resolution — report it. Exporting the suffix match without the collision guard was how `main.py` came back as a clean cross-repo hit.
   - **The marker must be a whole token, and a reference may not mark itself.** Substring matching lets the word "infrastructure" mark a repo called `infra`. Worse, matching the path's own text lets `docs/DEPLOY.md` mark a sibling repo named `docs`, after which *any* broken `docs/X.md` resolves next door. Strip the backticked paths out of the prose before looking for a repo name, and keep the window tight — a wrapped sentence justifies looking one line either side, not five, because a dense component table puts unrelated rows within range.

   Bound the work: walk a sibling's tree only for references that actually name it, and prune `.git`, `node_modules`, `venv`, `target` and `__pycache__`. An unpruned recursive walk across a few dozen sibling repos is the one part of this step that can take minutes instead of seconds.
**A rung you cannot run is not a pass.** Report the reference as broken only when a rung you actually executed rules it out. If you have no sibling repos, no filesystem access above the repo root, or no way to reach a deployment host, report it as *unresolved* and name which rungs you could not run — never silently suppress it, and never upgrade it to a confirmed break.

Any resolution weaker than rung 1 should say which rung it came from.

**Do not report every rung-2 resolution as "written stale".** That instruction used to live here and it was wrong, because two different populations resolve at rung 2 and only one is decay:

- **Decay** — the file moved and the doc still names the old place. Worth correcting.
- **House style** — prose names a file by its meaningful suffix under a base the document has already established (`utils/redaction.py` in a component table whose header says everything is under `src/`). Correcting these means expanding dozens of deliberate short references into full paths, which bloats the very documents the audit exists to keep lean.

Nothing about a single reference distinguishes the two, and **no threshold reliably does either** — an earlier attempt classified each document by the share of its references that resolved at rung 1 and suppressed fragments below a cut-off. That was withdrawn: on the repo it was calibrated against, *no document crossed the cut-off*, so the "list the outliers" branch was dead code and the rule was 100% suppression. It also created a blind band (a 4-reference document with one stale fragment can never cross), and it hid **deletions** — where a same-suffix twin survives in another package, deleting one file *reduced* the report by downgrading a collision to a silent resolution.

**So do not suppress. Re-label.** Split the output into three sections instead of one list:

- **Findings** — unresolved references and collisions. These are the defects.
- **Resolved below rung 1** — every rung-2, rung-3 and rung-4 resolution, *enumerated with what it resolved to* (`config/settings.py → packages/worker/config/settings.py`). Not defects, and not presented as "worth correcting" — but visible, so a reader who knows the file was deleted from `packages/api` can see it matched the wrong twin.
- **Skipped as asserted-absent** — paths the document states are gone.

That removes the noise from the findings list without inventing a constant, without a blind band, and without hiding anything. A document whose house style is fragments produces a long "resolved below rung 1" section and an empty findings list, which reads correctly at a glance.

**Report what the extractor dropped.** List the file extensions present in the working tree that the whitelist does not cover. Skips are silent by nature; every other rung has to name itself, and skips should too.

**Expect a residue, and do not loosen further to erase it.** Some references are *meant* not to resolve: instructional placeholders (`src/aggregators/my_new_aggregator.py` in a "how to add one" recipe), files a runbook tells the reader to create, units owned and deployed by another repo. A short list is a healthy result. **Zero is not the target**, and a change that drives the count to zero has almost certainly disabled the check rather than fixed it.

A check keyed to fully-qualified paths reports almost every prose reference as missing, because almost no prose reference is fully qualified. **Measured**, across 1877 real references in 26 repos: 54% resolve as written, 25% resolve only as a fragment (real references, previously all reported broken), and 21% are reported — while 311 of 311 seeded genuine breaks were still caught, including every basename-collision trap. The rung-2 constraints are not stylistic — whole-fragment matching and working-tree-not-git-index were each added because dropping one cost real detections in that run, and gitignored-is-sufficient alone silently resolved *every* fabricated path under a gitignored `.claude/`.

**Second measurement (2026-08-06, one adopter repo, 4 documents).** Both numbers below come from the same committed instrument, `tests/fixtures/reference-integrity/refcheck.py`, which implements the old rules under `--legacy` so the "before" is re-derivable rather than remembered:

- **Before: 139 items put to a human** — 47 reports plus 92 references labelled "written stale". Two consecutive audits of that repo had found nothing real, which is the signal that the check, not the repo, is broken.
- **After: 12 findings**, 129 enumerated as resolved-below-rung-1, 1 asserted-absent.

The **sensitivity** claim is separate and is what actually licenses the change: `tests/fixtures/reference-integrity/run.sh` seeds 11 genuine breaks — fabricated path, local basename collision, fabricated path under a gitignored directory, unmarked sibling coincidence, a real move, a path that supplies its own cross-repo marker, a substring marker that must not mark, an ambiguous match inside a sibling, a deletion whose same-suffix twin survives, and two references with extensions outside the whitelist — plus 5 cases that must stay silent. **All 16 behave correctly.** Run it before and after any edit to this step.

If a check re-derives the same non-finding on consecutive runs, fix the check. A probe that cries wolf is the failure mode this framework exists to catch. **But loosening a check is the most dangerous edit in this file**, because the evidence for it — a run that found nothing real — measures specificity and says nothing about sensitivity. The first attempt at this very fix shipped six defects and a self-confirming fixture that seeded only the failures the change was designed to preserve. Seed the failures the change newly *permits*. A run that finds nothing cannot distinguish a fixed check from a disabled one.

For every "Before You Start" pointer:
- Verify the target file exists
- Check that the trigger language is task-based ("when doing X, read Y") not passive ("see Y")

## Step 5 — Topic file and work-item reachability

Check that every topic file in memory/ has a task-triggered pointer in the "Before You Start" table. Flag orphaned topic files — they exist but no pointer leads to them, so an agent will never know to load them.

Check that every work-item file in `docs/work-items/` (other than `README.md`) has a corresponding pointer in the memory index's Current State section. Flag orphaned work-item files — they exist but no pointer tracks them. Also flag pointers in MEMORY.md whose target files no longer exist (stale pointer cleanup).

## Step 6 — Framework version drift

Find this project's adopted framework version and compare it against the latest in `agent-ready-projects/CHANGELOG.md`.

**Do not assume a single stamp format.** Adopters write it at least four ways — `agent-ready-projects: v1.14.0`, `framework: agent-ready-projects v1.14.0` in YAML frontmatter, `- **agent-ready-projects**: v1.12.0` as a bullet, and prose inside a status paragraph. Search case-insensitively for `agent-ready-projects` followed by a version-shaped token anywhere in the project file, and read the surrounding line. A check that matches one format reports an *unstamped* project when the stamp is simply written differently — which is worse than no check, because it prompts work that has already been done.

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

Summarize findings by severity:

- **Fix now**: broken references, misplaced secrets/credentials, orphaned files
- **Fix soon**: duplication, bloated auto-loaded files, passive pointer language
- **Consider**: minor size optimizations, optional restructuring

For each finding, state what's wrong, where, and propose a specific fix. Don't make changes without showing the plan first.
