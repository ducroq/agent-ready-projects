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

**First establish what your tool actually auto-loads, rather than assuming.** Only the project file is auto-loaded in most setups; since ADR-001 put Layer 3 in the repo, the memory index is reached by a pointer, not by the tool. In Claude Code the auto-loaded `MEMORY.md` is the *user-level* one at `~/.claude/projects/<slug>/memory/`, which shares a name with the in-repo file and is not it. Record what you measured — a size budget that includes a file which never arrives is wrong by the size of that file, and the error is invisible because the number still looks reasonable. If a budget series exists from earlier audits, say plainly whether it measured the same set; a trajectory across a change in what is being measured is not a trajectory.

Then check the project file and the memory index. For each:

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
- **Session navigation in the project file**: session narrative, "what I did today", task progress → should be in the memory index. **One exception, and only where there is no Layer 3**: the `## Active work` section `templates/project-file.md` ships for tools without auto-memory is the pointer list, not session narrative, and it belongs there because the project file is the only always-loaded artifact those tools have. Flag it as wrong-layer *only* when the project has a memory index too — then there are two lists, and they will disagree.
- **Always-needed constraints buried in topic files**: hard rules, thresholds, non-negotiables → should be in the project file
- **Derivable-from-code content in any memory file**: things `git log`, `grep`, or reading the source would tell you → shouldn't be persisted at all

## Step 4 — Reference integrity

For every file path mentioned in the project file, memory index, and gotcha log:
- Verify the file exists
- Flag any broken references

**First, skip negated existence assertions entirely.** A path inside `! test -f <path>` in a `<!-- verify: -->` comment asserts the file is GONE — its absence is the passing condition. This is about the reference's *intent*, not about whether the path resolves, so it has to be decided before the resolution order below and not inside it. **Prose deletion markers are the same assertion in a different costume** — `> **Deleted**: \`src/utils/full_text_fetcher.py\``, or a path inside `~~strikethrough~~`, states that the file is gone *and is correct as written*. Skip those too, or the audit will keep proposing you "fix" a line whose whole purpose is to record a removal.

**Give intentional non-resolvers the same treatment, for the same reason.** A path that was never meant to resolve — an instructional placeholder (`src/aggregators/my_new_aggregator.py` in a "how to add one" recipe), a file a runbook tells the reader to create, a unit owned by another repo — is re-triaged and re-dismissed on every audit, forever, which is exactly the cost the deletion skip was added to remove. Measured on one adopter repo: two audits three hours apart produced byte-identical three-line findings lists, one entry of which was this step's own worked example. Two markers, and **both are needed**:

- **`<!-- placeholder -->` on the line**, mirroring the `<!-- verify: -->` idiom — invisible when rendered, greppable. It is **span-scoped**: it must sit on the same line as the path it marks and *after* it, and it covers the **nearest extractable path before it** — not the whole line. A marker covering no extractable path is reported as an **ineffective marker**, because a marker that silently does nothing is the failure this whole step is built against. *(This sentence said "line-scoped" until v1.26.1, contradicting the next paragraph and the shipped behaviour. Line-scoping was the first draft and it relabelled a co-located genuine break as intentional — the defect seeded as T15.)*
- **An angle-bracket segment** — `docs/work-items/<slug>.md`, `filters/<name>/<version>/config.yaml` — which announces itself and costs the author nothing. Make sure the extractor's path pattern actually *admits* `<` and `>`: if it does not, these paths are never captured, and "not reported" then means "never checked", which is indistinguishable from a working skip and is not counted anywhere.

**One limit, stated rather than discovered: a marker is an assertion of intent, and a wrong one is not detectable.** If a path that *should* resolve is marked as a placeholder and does not resolve, it moves to the skip section and stays there — nothing can distinguish "never meant to resolve" from "meant to resolve and is broken" without knowing what the author meant. The existing deletion markers have exactly this property. What the design does instead is bound the damage: the marker is span-scoped so it cannot silence a neighbour, skips are enumerated rather than dropped so a reader sees what was excluded, and a marker on a path that *does* resolve is reported.

**Count them in their own section — `Skipped as declared-placeholder`** — separate from asserted-absent, because the two intents differ and a reader should be able to see both. And **a marker on a path that *does* resolve is a finding, not a skip**: mislabelling is how a real break would be hidden by this change, so it is reported as a stale marker. That is the failure this loosening newly permits, and it is seeded in `tests/fixtures/reference-integrity/run.sh` (T12, T13, T14) alongside the cases proving the skip works (N8, N9, N10).

⚠️ **"Does resolve" means at *any* rung, including rung 4** — but widening the search must not let it invent a provenance. A marked reference typically does not name its repo, so the normal rung-4 gate usually cannot fire on it — *usually*, not never: a marked reference whose prose does name the neighbour resolves through the ordinary gate, and that case is seeded as T21. Cross-repo paths are the population most likely to be marked. Three rules keep the widening honest:

- **Run rung 3 before rung 4 for a marked path too.** (*"Marked" carries two senses in this step: `<!-- placeholder -->`-marked, meant here; and "marked as cross-repo" by naming a neighbour in prose, meant in rung 4's own bullet. They gate differently and the words are not interchangeable.*) A file this repo's own runtime writes is explained locally; letting a sibling claim it first produces a provenance that is simply false — and the remedy the finding prescribes would write that falsehood into the document. A first draft of this arm ran rung 4 straight after the local test, so *marking* a runtime-state path flipped its owner to another repo.
- **A qualified path may match any reachable sibling; a bare basename may match only a sibling named in prose.** A qualified path carries its own evidence. A bare basename does not: measured on one adopter tree, **207** extractable bare basenames absent locally occurred in more than one sibling repo, and the unrestricted form told a news project to qualify its own `principes.md` against a house-renovation repo that happened to sort first. **A confident wrong answer is worse than a miss** — it is what makes a reader stop trusting the step.
- **If more than one sibling matches, report the ambiguity and refuse a single provenance.** The finding names a repo and a file and tells the author to qualify against them; that sentence has to be true.

The excused path otherwise leaves the checked set **permanently**: if the sibling file later moves, nothing reports it. Seeded as T19, with N17 holding the other direction. Walk the sibling listings **lazily and cache them per repository, keyed on the path rather than the name** — a name-keyed cache silently drops one of two siblings sharing a basename, and the tie is broken in hash order, which is randomized per process. That made the checker's own findings vary between two runs of the same command. Caching also removes a pre-existing per-reference re-walk: measured 19.7s → 7.8s on one adopter tree and over four minutes → 5.8s on another.

**Before marking a cross-repo path, try qualifying it instead** — name the repo in the surrounding prose so rung 4 resolves it. A qualified reference is checked on every run; a marked one is never checked again.

⚠️ **Known cost, stated rather than discovered: there is no marker form for a path that is *quoted* rather than *referenced*.** A log entry documenting a wrong path form contains that path as its subject; marking it no longer suppresses it if it resolves at rung 4, and qualifying it would defeat the entry's purpose. Three such cases were found in one adopter log. The distinction is INTENT, which no command can read, so this is an open design question and not a bug in the rule above — but it is a real recurring finding for anyone whose memory layer narrates its own mistakes.

**Scope every skip to the marked span, never to the line.** A line routinely retires one path and names its live replacement in the same sentence — `~~\`src/utils/old_thing.py\`~~ was removed; use \`src/utils/replacement.py\` instead.` — so skipping the line loses the successor. Measured on one adopter repo, line-scoping silently dropped 4 references on 2 lines, 3 of them load-bearing files, because session logs and ADRs use `~~done~~` as their standard completion convention and therefore carry strikethrough on their densest reference lines. Skip only the paths the marker actually covers, and **report the count of skipped paths** — a skip is the one outcome with no rung to name.

**Extract paths with an extension whitelist, not "a dot near the end".** A permissive suffix rule turns every dotted identifier (`re.sub`, `json.dumps`, `ContentItem.url`), every bare domain (`storm.mg`, `news.google.com`) and every version number (`3.1`) into a phantom reference. In one run this alone accounted for 20 phantom references. Whitelist real file extensions and extend the list when a project uses more; a reference the extractor never captures is invisible to every rung below.

⚠️ **An entry that is filename-shaped rather than extension-shaped re-admits the phantom class the whitelist exists to exclude.** The rule matches the tail of any dotted token, so whitelisting `env` captures `process.env` — a ubiquitous code identifier that no rung can ever resolve. Keep such a token only when it still looks like a path: it contains a `/` (`config/settings.env`), or it starts with a `.` (`.config.env` — **not** `.env.example`, whose extension is `example`, so it never reaches the test at all). Measured on `env`; `example`, `gitignore` and `dockerfile` are the same shape and are left alone until a collision is actually observed, because tightening on argument rather than evidence loses sensitivity nobody notices.

**Two things about that rule are easy to state wrongly, so state them precisely.** A bare `.env` is **not** preserved by the leading-dot clause — a path pattern of this shape requires a dot with something before it, so `.env` is never extracted in the first place, with or without the rule. The clause exists for `.something.env`. (`.env.example` does not exercise it either: its extension is `example`, so it never reaches the test.) And the rule has one known cost beyond the obvious `settings.env`: a **self-announcing placeholder** ending in such an extension — `<slug>.env` — is now dropped rather than counted in the skip section, which is the never-extracted-versus-skipped distinction this step exists to enforce, arriving in a corner of its own fix. Rare enough to record rather than fix; both were found by a non-author review, not by the author.

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

**Expect a residue, and do not loosen further to erase it.** Some references are *meant* not to resolve: instructional placeholders, files a runbook tells the reader to create, units owned and deployed by another repo. **Mark them** rather than tolerating them — that is what the placeholder skip above is for, and it moves them out of the findings list into a counted section instead of leaving them to be re-dismissed every audit. What remains after marking is the genuine residue, and a short list is a healthy result. **Zero is not the target**, and a change that drives the count to zero has almost certainly disabled the check rather than fixed it.

A check keyed to fully-qualified paths reports almost every prose reference as missing, because almost no prose reference is fully qualified. **Measured**, across 1877 real references in 26 repos: 54% resolve as written, 25% resolve only as a fragment (real references, previously all reported broken), and 21% are reported — while 311 of 311 seeded genuine breaks were still caught, including every basename-collision trap. The rung-2 constraints are not stylistic — whole-fragment matching and working-tree-not-git-index were each added because dropping one cost real detections in that run, and gitignored-is-sufficient alone silently resolved *every* fabricated path under a gitignored `.claude/`.

**Second measurement (2026-08-06, one adopter repo, 4 documents).** Both numbers below come from the same committed instrument, `tests/fixtures/reference-integrity/refcheck.py`, which implements the old rules under `--legacy` so the "before" is re-derivable rather than remembered:

- **Before: 139 items put to a human** — 47 reports plus 92 references labelled "written stale". Two consecutive audits of that repo had found nothing real, which is the signal that the check, not the repo, is broken.
- **After: 12 findings**, 129 enumerated as resolved-below-rung-1, 1 asserted-absent.

The **sensitivity** claim is separate and is what actually licenses the change: `tests/fixtures/reference-integrity/run.sh` seeds genuine breaks — fabricated path, local basename collision, fabricated path under a gitignored directory, unmarked sibling coincidence, a real move, a path that supplies its own cross-repo marker, a substring marker that must not mark, an ambiguous match inside a sibling, a deletion whose same-suffix twin survives, two references with extensions outside the whitelist, and (v1.23.0) a stale placeholder marker by each of its two forms, a marker covering no path, and an unmarked break sharing a marked line, and (v1.26.1) a stale marker resolving only at rung 4 and a whitelist entry that is filename-shaped rather than extension-shaped — plus the cases that must stay silent, and assertions that each declared placeholder appears in the **counted** skip section. A negative that only proves "not in findings" is satisfied by a path that was never extracted, which is the same silence this step exists to prevent. **All of them behave correctly**; the harness prints the count. Run it before and after any edit to this step.

If a check re-derives the same non-finding on consecutive runs, fix the check. A probe that cries wolf is the failure mode this framework exists to catch. **But distinguish wolf-crying from residue before touching anything**: a repeated finding that is an acknowledged placeholder, a cross-repo unit, or a file the reader is told to create is residue — mark it (above) so it stops appearing, rather than loosening the extractor that found it. Prove the check is alive by seeding a break *first*; if the seeded break is caught and the repeat is still there, the repeat is residue and the check is fine. **But loosening a check is the most dangerous edit in this file**, because the evidence for it — a run that found nothing real — measures specificity and says nothing about sensitivity. The first attempt at this very fix shipped six defects and a self-confirming fixture that seeded only the failures the change was designed to preserve. Seed the failures the change newly *permits*. A run that finds nothing cannot distinguish a fixed check from a disabled one.

For every "Before You Start" pointer:
- Verify the target file exists
- Check that the trigger language is task-based ("when doing X, read Y") not passive ("see Y")

## Step 5 — Topic file and work-item reachability

**First establish whether this project has a Layer 3 at all, by looking for it rather than by guessing the tool.** Layer 3 is the memory index plus its topic files. Find the index at whichever path this project actually uses — `MEMORY.md` at the root, `memory/MEMORY.md`, or whatever path the project file's own pointer row names — and treat topic files beside it as part of it. Do not gate on one hardcoded path: this framework's own naming map says `MEMORY.md`, `adopt.md` writes `memory/MEMORY.md`, and a gate on either one reports "no Layer 3" for a project that has a complete one.

- **Topic files present but no index**: that is the finding, not a reason to skip. It is the most broken Layer 3 state there is, and gating the step on the index would make the step silent precisely there.
- **Layer 3 present**: check that every topic file has a task-triggered pointer in the "Before You Start" table. Flag orphaned topic files — they exist but no pointer leads to them, so an agent will never know to load them.
- **No Layer 3 anywhere** — the case for every tool without auto-memory, where `docs/GUIDE.md` says plainly that everything goes into the project file: report the *topic-file* half as **not applicable, and say why**. A skipped check and a passing check are indistinguishable in a report that says neither, which is the whole reason this bullet exists rather than the step quietly doing nothing.

**The work-item half runs either way — only the artifact changes.** `docs/work-items/` is tool-independent, so check that every work-item file there (other than `README.md`) has a pointer tracking it, and that no pointer names a file that no longer exists. The pointers live in the memory index's Current State section where Layer 3 exists, and in the project file's **Active work** section where it does not. **Report which one you read — and if *both* exist, that is the finding**: two lists of the same thing disagree the moment one is updated and the other is not, so say which is canonical here (the memory index) and propose removing the other. Flag pointers to work that is finished: only in-progress items belong in either list, and in the project file that list is charged against the size budget Step 1 measures.

**Do not substitute `docs/*.md` for the topic files, and do not invent a home for the work-item pointers.** `docs/` is where this framework puts essays and reference material — a dozen files in the framework repo at v1.25.0 — so treating it as a topic-file directory reports every essay as an orphan. That is the failure class v1.15.1 spent a release removing from Step 4. The work-item half used to be the subtler trap: `docs/work-items/` is tool-independent, so checking it against the project file reads as obviously right — but until v1.22.0 `templates/work-item.md`, `templates/README.md` and `docs/GUIDE.md` all sent the pointer to *the memory index's Current State section* unconditionally, and `templates/project-file.md` shipped no such section, so an adopter without Layer 3 had work-item files and nowhere the pointer could have gone. Checking it would have flagged every one. That is now fixed at the source rather than worked around here (#44): the project file has an **Active work** section, and all four artifacts name it.

<!-- provisions: memory-index-row -->

**Check the row's wording, not just its presence, and quote the canonical one when proposing it.** `templates/project-file.md` ships it as:

> `| Picking up where the last session left off | memory/MEMORY.md …`

That is a **situation the agent recognises**. Describing it instead by *when it fires* — "a row whose trigger fires at session start" — is a category, and an agent satisfying the finding will write what the finding described. This step used to say exactly that, and the row it produced in a real adopter was `| Starting any session (project state) |`, sitting directly above that project's existing `| Starting any session (framework drift) |`: two rows with the same trigger prefix, separated by a parenthetical, which is the collision `docs/task-triggered-pointers.md` argues against and which v1.20.0 removed from this framework's own `CLAUDE.md`. Note the defect is the *collision*, not the parenthesis: one row reading `Starting any session (framework drift)` is fine, and `templates/project-file.md` ships one. Two rows whose triggers are identical up to a parenthetical are not, because the parenthetical becomes the only discriminator. Propose the canonical wording, or an equivalent situation — "resuming an interrupted migration", "returning after a week away" — never a category.

**Two rows whose triggers are identical up to a parenthetical are a finding on their own.** It is the observable form of the collision and it is cheap: take each row's **first cell** — the text between the first and second `|` — strip any trailing ` (…)` or ` — …`, and flag any two rows whose remainders are then *equal*. Equal, not merely sharing a leading substring: `Editing a skill` and `Editing templates` share a prefix and are two perfectly good triggers, and a substring rule reports four such pairs on this framework's own project file. An agent choosing between `Starting any session (project state)` and `Starting any session (framework drift)` is choosing by parenthetical, which is the thing a trigger exists to make unnecessary.

**For a row whose whole function is to fire on a situation, presence is not adoption — the wording is the artifact.** Report the row's actual text, so a reader can judge the shape rather than trusting a tick.

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
