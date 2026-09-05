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

For every file path mentioned in the project file, memory index, and gotcha log:
- Verify the file exists
- Flag any broken references

**First, skip negated existence assertions entirely.** A path inside `! test -f <path>` in a `<!-- verify: -->` comment asserts the file is GONE — its absence is the passing condition. This is about the reference's *intent*, not about whether the path resolves, so it has to be decided before the resolution order below and not inside it. **Prose deletion markers are the same assertion in a different costume** — `> **Deleted**: \`src/utils/full_text_fetcher.py\``, or a path inside `~~strikethrough~~`, states that the file is gone *and is correct as written*. Skip those too, or the audit will keep proposing you "fix" a line whose whole purpose is to record a removal.

**Give intentional non-resolvers the same treatment, for the same reason.** A path that was never meant to resolve — an instructional placeholder (`src/aggregators/my_new_aggregator.py` in a "how to add one" recipe), a file a runbook tells the reader to create, a unit owned by another repo — is re-triaged and re-dismissed on every audit, forever, which is exactly the cost the deletion skip was added to remove. Measured on one adopter repo: two audits three hours apart produced byte-identical three-line findings lists, one entry of which was this step's own worked example. Two markers, and **both are needed**:

- **`<!-- placeholder -->` on the line**, mirroring the `<!-- verify: -->` idiom — invisible when rendered, greppable. It is **span-scoped**: it must sit on the same line as the path it marks and *after* it, and it covers the **nearest extractable path before it** — not the whole line. A marker covering no extractable path is reported as an **ineffective marker**, because a marker that silently does nothing is the failure this whole step is built against. *(This sentence said "line-scoped" until v1.26.1, contradicting the next paragraph and the shipped behaviour. Line-scoping was the first draft and it relabelled a co-located genuine break as intentional — the defect seeded as T15.)*
- **An angle-bracket segment** — `docs/work-items/<slug>.md`, `filters/<name>/<version>/config.yaml` — which announces itself and costs the author nothing. Make sure the extractor's path pattern actually *admits* `<` and `>`: if it does not, these paths are never captured, and "not reported" then means "never checked", which is indistinguishable from a working skip and is not counted anywhere.

**One limit, stated rather than discovered: a marker is an assertion of intent, and a wrong one is not detectable.** If a path that *should* resolve is marked as a placeholder and does not resolve, it moves to the skip section — and stays there on any run that can test it, since nothing can distinguish "never meant to resolve" from "meant to resolve and is broken" without knowing what the author meant. (Which section it lands in, and when, is the table below — one section or the other, never both, which is a design rule nothing checks.) The existing deletion markers have exactly this property. What the design does instead is bound the damage: the marker is span-scoped so it cannot silence a neighbour, skips are enumerated rather than dropped so a reader sees what was excluded, and a marker on a path that resolves at an adjudicating rung is reported.

**Count them in their own section — `Skipped as declared-placeholder`** — separate from asserted-absent, because the two intents differ and a reader should be able to see both. And **a marker on a path that resolves at an adjudicating rung is a finding, not a skip** (the table below): mislabelling is how a real break would be hidden by this change. That is the failure this loosening newly permits, and it is seeded in `tests/fixtures/reference-integrity/run.sh` (T12, T13, T14) alongside the cases proving the skip works (N8, N9, N10).

⚠️ **What a marked path does, once, so the rest of this step can point at it.** It runs the same rungs in the same order as an unmarked one — 1, 1b, 2, 3, 4 — and two different questions are being asked. *Decidable*: any rung that **ran** and resolved it answers yes, and the run is not undecided about it. *Mislabelled*: only the rungs below marked **adjudicates** answer that. Conflating the two produced #93 a third time — skipping 1b and 2 here made *marking* a locally-resolvable reference flip the run to undecided (exit 2 with no neighbour, exit 0 with one, while unmarked it resolved at exit 0 in both; X17–X20).

| a marked path resolves at | what it means | where it is counted |
|---|---|---|
| **rung 1**, as written, or **rung 1b**, doc-relative | adjudicates — mislabelled, because the file is where the reference points | Findings |
| **rung 2**, suffix, or **rung 3**, runtime state | decides only — excused, never reported | Skipped as declared-placeholder |
| **rung 4**, a sibling named in prose | adjudicates — mislabelled; the remedy depends on the arm, below | Findings |
| **nowhere**, a neighbour reachable | **correctly marked** — this is the case the marker exists for | Skipped as declared-placeholder |
| **nowhere**, no neighbour reachable | undecided — rung 4 could not run | Unconfirmed |
| an **angle-bracket segment** at no local rung | decided by its shape, not by disk | Skipped as declared-placeholder |

⚠️ **Row 5 is the one to get right**: resolving nowhere on a tree that *could* test it is the placeholder doing its job.

The angle-bracket row is the **fall-through** only: rungs 1 and 1b run first and can report such a path (carve-out below), so the shape decides where it lands once nothing local answered, not whether it is looked at.

⚠️ **Rung 2 decides without adjudicating on purpose (#56).** A path that merely shares a *suffix* with a file elsewhere is not evidence of intent. With the suffix arm adjudicating, a repo shipping a template **and** instances of it had no correct move — marked reported STALE, unmarked reported COLLISION, both findings, neither a defect, re-triaged every audit. Three references were left knowingly unfixed on one adopter for that reason.

⚠️ **Across repos, "does resolve" means rung 4** — the table's fourth row — but widening the search must not let it invent a provenance. A marked reference typically does not name its repo, so the normal rung-4 gate usually cannot fire on it — *usually*, not never: a marked reference whose prose does name the neighbour resolves through the ordinary gate, and that case is seeded as T21. Cross-repo paths are the population most likely to be marked. Three rules keep the widening honest:

- **Run rung 3 before rung 4 for a marked path too.** (*"Marked" carries two senses in this step: `<!-- placeholder -->`-marked, meant here; and "marked as cross-repo" by naming a neighbour in prose, meant in rung 4's own bullet. They gate differently and the words are not interchangeable.*) A file this repo's own runtime writes is explained locally; letting a sibling claim it first produces a provenance that is simply false — and the provenance the finding names would be that falsehood.
- **Only a sibling NAMED IN PROSE may be matched — for a qualified path as much as for a bare basename.** A `/` in the path is not evidence of provenance: the same relative path recurs across neighbouring repos, and the ones this method tells every adopter to create recur the most, so marking one before writing it produces a permanent finding on every audit. **A confident wrong answer is worse than a miss** — it is what makes a reader stop trusting the step.
- ⚠️ **What this leaves unsolved, stated rather than discovered:** a marked cross-repo reference whose prose does *not* name the repo — the population #73 was filed for — is still never checked. Naming the repo in **bare** prose is the remedy and the step says so, but nothing detects the omission. Same family as the quoted-versus-referenced gap below.
- **If more than one sibling matches, report the ambiguity and refuse a single provenance.** The finding names a repo and a file; that sentence has to be true. It no longer tells the author to *qualify against them* — for the single-match arm the remedy is to remove the marker (#102), and an ambiguous arm has no single provenance to name.

The excused path otherwise leaves the checked set **permanently**: if the sibling file later moves, nothing reports it. Seeded as T19, with N17 holding the other direction. Walk the sibling listings **lazily and cache them per repository, keyed on the path rather than the name** — a name-keyed cache silently drops one of two siblings sharing a basename, and the tie is broken in hash order, which is randomized per process. That made the checker's own findings vary between two runs of the same command. Caching also removes a pre-existing per-reference re-walk: measured 19.7s → 7.8s on one adopter tree and over four minutes → 5.8s on another.

**Before marking a cross-repo path, try naming the neighbouring repo in the bare prose around it instead** — that is what lets rung 4 resolve it, and a resolved reference needs no marker. ⚠️ **Do not do both**: a marked reference whose prose names the repo is precisely the stale-marker finding, seeded as T21. ⚠️ **The remedy depends on which arm fired.** For the **single-match** arm — one sibling, one file — it is *remove the marker*: that arm's precondition is that the paragraph already names the repo, so the path resolves and the marker is the false part. Saying *qualify it instead* does not clear it, because the marker is what is adjudicated. ⚠️ **For the ambiguous and collision arms the remedy is an open question (#107) and this step does not prescribe one** — which is not the same as *no remedy exists*. ⚠️ **Both arms report ambiguity alike** (#120, fixed): the unmarked arm used to stop at the first matching sibling and state it as fact, so marking a reference made the tool *more* careful than leaving it alone — backwards, and unmarked is far commoner. ⚠️ **"Qualify" cost an adopter a run (#102)**: it reads as *write `Repo/path/file`*, and that on its own — with no bare-prose mention — resolves nothing at all.

⚠️ **Known cost, stated rather than discovered: there is no marker form for a path that is *quoted* rather than *referenced*.** A log entry documenting a wrong path form contains that path as its subject; marking it no longer suppresses it if it resolves at rung 4, and the remedies that finding offers — remove the marker, or name the repo in bare prose — both defeat an entry whose subject *is* the path form. Three such cases were found in one adopter log. The distinction is INTENT, which no command can read, so this is an open design question and not a bug in the rule above — but it is a real recurring finding for anyone whose memory layer narrates its own mistakes.

**Scope every skip to the marked span, never to the line.** A line routinely retires one path and names its live replacement in the same sentence — `~~\`src/utils/old_thing.py\`~~ was removed; use \`src/utils/replacement.py\` instead.` — so skipping the line loses the successor. Measured on one adopter repo, line-scoping silently dropped 4 references on 2 lines, 3 of them load-bearing files, because session logs and ADRs use `~~done~~` as their standard completion convention and therefore carry strikethrough on their densest reference lines. Skip only the paths the marker actually covers, and **report the count of skipped paths** — a skip is the one outcome with no rung to name.

**A markdown link's TEXT is a label, not a reference; its URL is the reference.** In ``[`writing-guide.md`](templates/writing-guide.md)`` the URL resolves and the label is presentation — extract the label and you manufacture a collision against any same-named file, so *the better a document follows this framework's own link style, the more phantom findings it generates*. Mask the label, then extract the URL in its place. **Masking alone is a silent loss, not a noise reduction**: the label used to give a broken URL accidental coverage, so a URL you decline to check — external, a bare anchor, a directory, an extension outside the whitelist — must be **reported as declined, with its reason**, never dropped (#55).

**Extract paths with an extension whitelist, not "a dot near the end".** A permissive suffix rule turns every dotted identifier (`re.sub`, `json.dumps`, `ContentItem.url`), every bare domain (`storm.mg`, `news.google.com`) and every version number (`3.1`) into a phantom reference. In one run this alone accounted for 20 phantom references. Whitelist real file extensions and extend the list when a project uses more; a reference the extractor never captures is invisible to every rung below.

⚠️ **An entry that is filename-shaped rather than extension-shaped re-admits the phantom class the whitelist exists to exclude.** The rule matches the tail of any dotted token, so whitelisting `env` captures `process.env` — a ubiquitous code identifier that no rung can ever resolve. Keep such a token only when it still looks like a path: it contains a `/` (`config/settings.env`), or it starts with a `.` (`.config.env` — **not** `.env.example`, whose extension is `example`, so it never reaches the test at all). Measured on `env`; `example`, `gitignore` and `dockerfile` are the same shape and are left alone until a collision is actually observed, because tightening on argument rather than evidence loses sensitivity nobody notices.

**Two things about that rule are easy to state wrongly, so state them precisely.** A bare `.env` is **not** preserved by the leading-dot clause — a path pattern of this shape requires a dot with something before it, so `.env` is never extracted in the first place, with or without the rule. The clause exists for `.something.env`. (`.env.example` does not exercise it either: its extension is `example`, so it never reaches the test.) And the rule has one known cost beyond the obvious `settings.env`: a **self-announcing placeholder** ending in such an extension — `<slug>.env` — is now dropped rather than counted in the skip section, which is the never-extracted-versus-skipped distinction this step exists to enforce, arriving in a corner of its own fix. Rare enough to record rather than fix; both were found by a non-author review, not by the author.

**For every other path, try to resolve it before reporting it broken** — in this order:

1. **As written**, relative to the repo root.
1b. **Doc-relative** — relative to the directory of the document doing the referencing. This is not a courtesy rung: markdown link semantics *are* doc-relative, so a bare `` `backlog.md` `` in `papers/one/CLAUDE.md` means the file next to it, and that is how the rendered link resolves. Without it such a reference either misses rung 1 outright or gets downgraded at rung 2 to a **collision** against a same-named file elsewhere — reported as a defect requiring a decision when there is nothing to decide. Measured on one adopter: **42 of 102 findings, 41%**, were exactly this. It must sit above rung 2 or the collision fires first, and it is *enumerated*, not silent, so a reader can see how much of a tree resolves this way (#54).

2. **As a path suffix of a file in the working tree.** Most prose names a file by fragment, not full path: `models/temporal.py` resolves to `src/models/temporal.py`. Two constraints, both load-bearing. Match the **whole fragment**, not the bare basename — a lone `utils.py` landing on some unrelated `utils.py` is a collision, not a resolution, and a collision gets **reported**. And search the **working tree, not the git index** — `git ls-files` omits every gitignored-but-present file, which under this framework's own recommended setup means all of `memory/`.
3. **As runtime state.** A file the running system writes (`data/source_states.json`, `circuit_breakers.json`) is *correctly* absent from a development checkout. **Gitignored is necessary but not sufficient** — it means "not committed", which is not the same as "written by the running system". Require a positive signal too: the path sits in a state directory (`data/`, `state/`, `cache/`, `logs/`, `run/`, `var/`, `artifacts/`) or carries a state-file shape (`*_state.json`, `*_health.json`, `.pid`, `.sock`). And runtime state is **data** — a *source file* whose name merely contains "cache" or "state" is still source, and its absence is still a real break. Reaching the deployment host is confirmation if you can, not a requirement. **Order this rung before the sibling rung**: a file the audited repo's own runtime writes is explained *here*, and letting a neighbour with the same filename claim it first produces a provenance that is simply false.

4. **In a sibling repo — only when the reference is *marked* as cross-repo**, by carrying a sibling repo's name in the prose around it. A bare path that happens to also exist next door is a coincidence, not a resolution; without the marker this rung will quietly absorb any common path (`.claude/README.md`, `docs/ARCHITECTURE.md`) that every repo happens to have. Five details decide whether this rung works at all — each one, omitted, either reported real files as broken or resolved broken ones as clean:
   - **Match inside the sibling the same way rung 2 matches locally.** A cross-repo reference is a fragment just as often as a local one: "SiblingRepo's `deploy_filters.sh`" means `SiblingRepo/scripts/deploy_filters.sh`. Joining the fragment to the sibling root and testing existence resolves almost nothing.
   - **Strip a leading component that repeats the repo name.** `SiblingRepo/scripts/main.py` joined to the SiblingRepo checkout yields `SiblingRepo/SiblingRepo/scripts/main.py`. Try the stripped form too.
   - **Find siblings at more than one nesting depth.** Repos nest unevenly (`~/repos/<repo>` *and* `~/repos/<org>/<repo>`), so globbing only the immediate parent misses whole trees.
   - **Carry rung 2's collision rule across with its matching.** Two files in the sibling matching the same fragment is an ambiguity, not a resolution — report it. Exporting the suffix match without the collision guard was how `main.py` came back as a clean cross-repo hit.
   - **The marker must be a whole token, and a reference may not mark itself.** Substring matching lets the word "infrastructure" mark a repo called `infra`. ⚠️ **`-` and `_` count as part of the name**, so `data-alpha` does not mark a sibling `alpha` (#119, fixed). `.` stays a separator, or a sentence ending "we use alpha." would stop marking. Knowing cost: "alpha-based" no longer marks `alpha` — **a miss, which is the safe direction**, the alternative being a confident wrong provenance. Worse, matching the path's own text lets `docs/DEPLOY.md` mark a sibling repo named `docs`, after which *any* broken `docs/X.md` resolves next door. Strip **every backticked span** out of the prose before looking for a repo name — not merely the paths — and keep the window to one line either side. ⚠️ **Say "every span" to the author, because the difference is a trap this framework walks into.** A repo name written as `` `SiblingRepo` `` is inside a span, so it is stripped and does **not** mark the reference — which is the house style of these very docs, so an author who follows the instruction gets a finding and no explanation. Name the repo in **bare prose**, whole word, within a line either side.

   Bound the work: walk a sibling's tree only for references that actually name it, and prune `.git`, `node_modules`, `venv`, `target` and `__pycache__`. An unpruned recursive walk across a few dozen sibling repos is the one part of this step that can take minutes instead of seconds.
**A rung you cannot run is not a pass.** Report the reference as broken only when a rung you actually executed rules it out. If you have no sibling repos, no filesystem access above the repo root, or no way to reach a deployment host, report it as *unresolved* and name which rungs you could not run — never silently suppress it, and never upgrade it to a confirmed break.

**Then carry that distinction into the run's verdict, not only into its prose — three outcomes, not two.** *Defects*, when a rung that actually ran ruled a reference out or ambiguous, or a document could not be read. *Clean*, when nothing was found. And a third, **coverage incomplete**, when nothing was ruled on but something was left undecided because **rung 4** had no neighbouring repo to run against. Name which one the run reached, on a line of its own, and enumerate the undecided in a counted section — Step 8 has a bucket for them. Collapsing the third state into *defects* is what makes this step useless as a gate: a correct repo whose neighbours are simply not checked out — CI, a fresh clone, a container — then fails on **where it ran** rather than on what it audited, and a gate that fires on its environment trains its reader to ignore it. Collapsing it into *clean* is worse, because with no neighbour reachable a genuine break is in that same bucket. **If you automate this step**, that is exit 1 / exit 0 / **exit 2**, and 2 must stay non-zero: a caller written as `check && …` then behaves exactly as it always did, and only one that opts in (`|| [ $? -eq 2 ]`) accepts an undecided run. Run as prose, this step returns no status at all — the verdict line is what it produces, and the numbers are for whatever you wire around it (#93).

The **disposition** is the one `curate` Step 0 sub-step 5 already uses: a thing that is neither a pass nor a failure gets its own state instead of being rounded to one of the other two. The **trigger** is not the same and should not be cited as though it were — that runner reaches its third state only when *nothing* produced a verdict, where this one reaches it on a single undecided reference in an otherwise fully decided run.

⚠️ **This does not make the status a property of the repo, and nothing can.** Rung 4's gate is a repo *name in the prose*, so whether an individual reference was decidable is not computable, and *was any neighbour reachable* is a coarse stand-in in both directions. What the third state buys is narrower and still worth having: **an undecided run says so, instead of picking one of the two verdicts it has not earned.** ⚠️ **There is one move, not two, and it is scoped.** Run the audit where the neighbours are reachable. *Marking* is not a second move **for a reference no local rung resolves**: it is rung-4 traffic either way, so it lands in the same undecided section at the same status.

⚠️ **A `<!-- placeholder -->` marker is rung-4 traffic too — and an angle-bracket segment is not.** The stale-marker test runs a marked path against the neighbours, so where none is reachable it is *undecided*, not excused — but only once nothing local has answered it, which is the order the table above gives. **An angle-bracket segment is decided by its shape instead** and stays excused; treating it as undecided moves a repo whose placeholders are all of that form from *clean* to *coverage incomplete* on a fresh clone. ⚠️ **"Shape" does not mean nothing on disk can touch it.** A literal file of that name resolves at rung 1 or 1b and is reported, with a wording that does **not** say *stale marker*, since there is no marker to remove; a *neighbour* holding one suffix-matches at rung 4 the same way.

Any resolution weaker than rung 1 should say which rung it came from.

**Do not report every rung-2 resolution as "written stale".** That instruction used to live here and it was wrong, because two different populations resolve at rung 2 and only one is decay:

- **Decay** — the file moved and the doc still names the old place. Worth correcting.
- **House style** — prose names a file by its meaningful suffix under a base the document has already established (`utils/redaction.py` in a component table whose header says everything is under `src/`). Correcting these means expanding dozens of deliberate short references into full paths, which bloats the very documents the audit exists to keep lean.

Nothing about a single reference distinguishes the two, and **no threshold reliably does either** — an earlier attempt classified each document by the share of its references that resolved at rung 1 and suppressed fragments below a cut-off. That was withdrawn: on the repo it was calibrated against, *no document crossed the cut-off*, so the "list the outliers" branch was dead code and the rule was 100% suppression. It also created a blind band (a 4-reference document with one stale fragment can never cross), and it hid **deletions** — where a same-suffix twin survives in another package, deleting one file *reduced* the report by downgrading a collision to a silent resolution.

**So do not suppress. Re-label.** Split the output into sections instead of one list — these three, plus the table's other two whenever either has members:

- **Findings** — unresolved references and collisions. These are the defects.
- **Resolved below rung 1** — every rung-2, rung-3 and rung-4 resolution of an *unmarked* path, *enumerated with what it resolved to* (a marked path excused at rung 2 or 3 is counted in the skip section instead) (`config/settings.py → packages/worker/config/settings.py`). Not defects, and not presented as "worth correcting" — but visible, so a reader who knows the file was deleted from `packages/api` can see it matched the wrong twin.
- **Skipped as asserted-absent** — paths the document states are gone.

That removes the noise from the findings list without inventing a constant, without a blind band, and without hiding anything. A document whose house style is fragments produces a long "resolved below rung 1" section and an empty findings list, which reads correctly at a glance.

**Report what the extractor dropped.** List the file extensions present in the working tree that the whitelist does not cover. Skips are silent by nature; every other rung has to name itself, and skips should too.

**Expect a residue, and do not loosen further to erase it.** Some references are *meant* not to resolve: instructional placeholders, files a runbook tells the reader to create, units owned and deployed by another repo. **Mark them** rather than tolerating them — that is what the placeholder skip above is for, and it moves them out of the findings list into a counted section instead of leaving them to be re-dismissed every audit. What remains after marking is the genuine residue, and a short list is a healthy result. **Zero is not the target**, and a change that drives the count to zero has almost certainly disabled the check rather than fixed it.

A check keyed to fully-qualified paths reports almost every prose reference as missing, because almost no prose reference is fully qualified. **Measured**, across 1877 real references in 26 repos: 54% resolve as written, 25% resolve only as a fragment (real references, previously all reported broken), and 21% are reported — while 311 of 311 seeded genuine breaks were still caught, including every basename-collision trap. The rung-2 constraints are not stylistic — whole-fragment matching and working-tree-not-git-index were each added because dropping one cost real detections in that run, and gitignored-is-sufficient alone silently resolved *every* fabricated path under a gitignored `.claude/`.

**Second measurement (2026-08-06, one adopter repo, 4 documents).** Both numbers below come from the same committed instrument, `tests/fixtures/reference-integrity/refcheck.py`, which implements the old rules under `--legacy` so the "before" is re-derivable rather than remembered:

- **Before: 139 items put to a human** — 47 reports plus 92 references labelled "written stale". Two consecutive audits of that repo had found nothing real, which is the signal that the check, not the repo, is broken.
- **After: 12 findings**, 129 enumerated as resolved-below-rung-1, 1 asserted-absent.

A negative that only proves "not in findings" is satisfied by a path that was never extracted, which is the same silence this step exists to prevent. **All of them behave correctly**; the harness prints the count. Run it before and after any edit to this step.

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
