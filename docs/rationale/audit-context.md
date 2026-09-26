# Why `audit-context` says what it says

Superseded drafts and the measurements that refuted them, moved out of `templates/audit-context.md` so that
adopters do not pay for this repo's litigation on every invocation. **The decision lives in the
skill; the argument lives here.** Nothing is duplicated between the two — if a claim appears in
both, one of them is wrong.

###  Row 5 is the one to get right: resolving nowhere on a tree that could test it is the plac…

- A draft of this table said *Findings* there — reporting every legitimate placeholder as a defect — and the suite stayed green, because the oracle agreed with the prose and not with the table.

### The angle-bracket row is the fall-through only: rungs 1 and 1b run first and can report su…

- A path carrying both forms follows the shape; two drafts got that ordering wrong in the two available directions.

### - Run rung 3 before rung 4 for a marked path too. ("Marked" carries two senses in this ste…

- A first draft of this arm ran rung 4 straight after the local test, so *marking* a runtime-state path flipped its owner to another repo.

### Before marking a cross-repo path, try naming the neighbouring repo in the bare prose aroun…

- ⚠️ **The remedy a stale rung-4 finding should print depends on which arm fired, and a draft of this change put one remedy in the table for all of them.** For the **single-match** arm — one sibling, one file — the remedy is *remove the marker*: that arm's precondition is that the paragraph already names the repo, so the path resolves and the marker is the false part.
- ⚠️ **For the ambiguous and collision arms the remedy is an open question (#107, #120) and this step does not prescribe one.** Do not read that as *no remedy exists* — a draft of this paragraph did, and it is false: naming one repo rather than two, or qualifying against the intended neighbour, both clear it.

###  This does not make the status a property of the repo, and nothing can. Rung 4's gate is a…

- Until v1.30.0 this paragraph said that of *every* marked reference and of the run's "ability to decide it" — unhedged, and false for anything a local rung answers.

### A negative that only proves "not in findings" is satisfied by a path that was never extrac…

- The **sensitivity** claim is separate and is what actually licenses the change: `tests/fixtures/reference-integrity/run.sh` seeds genuine breaks — fabricated path, local basename collision, fabricated path under a gitignored directory, unmarked sibling coincidence, a real move, a path that supplies its own cross-repo marker, a substring marker that must not mark, an ambiguous match inside a sibling, a deletion whose same-suffix twin survives, two references with extensions outside the whitelist, and (v1.23.0) a stale placeholder marker by each of its two forms, a marker covering no path, and an unmarked break sharing a marked line, and (v1.26.1) a stale marker resolving only at rung 4 and a whitelist entry that is filename-shaped rather than extension-shaped, and (v1.28.0) a broken markdown-link URL, a broken path outside the brackets on a line that also carries a link, a declined link URL that must be reported with its reason, and — in the must-stay-silent direction — a link label, a doc-relative reference, a template placeholder with a suffix twin, and a struck, deleted or placeheld markdown link — plus the cases that must stay silent, and assertions that each declared placeholder appears in the **counted** skip section.

### Do not substitute docs/.md for the topic files, and do not invent a home for the work-item…

- That is the failure class v1.15.1 spent a release removing from Step 4.
- The work-item half used to be the subtler trap: `docs/work-items/` is tool-independent, so checking it against the project file reads as obviously right — but until v1.22.0 `templates/work-item.md`, `templates/README.md` and `docs/GUIDE.md` all sent the pointer to *the memory index's Current State section* unconditionally, and `templates/project-file.md` shipped no such section, so an adopter without Layer 3 had work-item files and nowhere the pointer could have gone.

### That is a situation the agent recognises.…

- This step used to say exactly that, and the row it produced in a real adopter was `| Starting any session (project state) |`, sitting directly above that project's existing `| Starting any session (framework drift) |`: two rows with the same trigger prefix, separated by a parenthetical, which is the collision `docs/task-triggered-pointers.md` argues against and which v1.20.0 removed from this framework's own `CLAUDE.md`.

### Search case-insensitively for agent-ready-projects followed by a version-shaped token anyw…

- **Do not assume a single stamp format.** Adopters write it at least four ways — `agent-ready-projects: v1.14.0`, `framework: agent-ready-projects v1.14.0` in YAML frontmatter, `- **agent-ready-projects**: v1.12.0` as a bullet, and prose inside a status paragraph.

### Only a sibling named in prose may be matched — the measurements

- An earlier version exempted qualified paths, on the argument that a path containing `/` carries its own evidence. Measured false on a 30-repo estate: **544** qualified relative paths occur in more than one neighbour, headed by `memory/gotcha-log.md` (21 repos) and `docs/RUNBOOK.md` (8) — the files this method tells every adopter to create. Bare basenames were measured the same way: **207** on one adopter tree, and the unrestricted form told one adopter repo to qualify its own `principes.md` against an unrelated sibling that happened to sort first.

### The stale-marker remedy — what was measured

- Measured on both seeded instances: stripping the marker moves each to *resolved below rung 1* and the findings count drops. With the path qualified and the marker kept, the finding message is byte-identical.
- What is unsettled for the ambiguous and collision arms is which remedy an audit should recommend, and whether removing the marker is safe there: with two siblings it lets the first-sorting one win silently (#120), while with one sibling holding two files it produces a loud collision instead.
- A draft of this paragraph asserted *no remedy is available*, which is false: naming one repo rather than two, or qualifying against the intended neighbour, both clear it.

### Whole-token marking — the cases behind the rule

- `my_atlas` and `atlas.example.com` are marked too; `atlases` correctly is not. Open as #119. A hyphenated repo name beside a repo named after one of its components is the shape to watch.
- The window is one line either side rather than five because a dense component table puts unrelated rows within range.
- The backticked-span trap was measured: an author who names the neighbour exactly as instructed, in backticks, still gets a finding and no explanation.

### Link labels and declined URLs

- The pressure created by extracting labels is to stop backticking link text, which makes the docs worse.
- An unwhitelisted extension on a file that does not exist appears in neither the findings nor the "extensions in tree" trailer, which only names extensions the tree actually holds (#55).

### Angle-bracket shape versus a literal file of that name

- Both directions are rare — the name is illegal on NTFS — and both were measured.

### Loosening a check

- The first attempt at this fix shipped six defects and a self-confirming fixture that seeded only the failures the change was designed to preserve.

### The third verdict is coarse in both directions

- One unrelated clone next door is enough to make rung 4 count as having run for a reference naming a repo that is absent, and that reference is then reported as a defect.

## The cross-repo remedy took three drafts, wrong in both directions (#133)

Rung 4's candidate window is `para = ' '.join(lines[max(0, i-1):i+2])` — the
reference's line and one either side. Two consequences pull against each other,
and each of the first two drafts satisfied one and broke the other.

| draft | wording | measured outcome |
|---|---|---|
| 1 | "on a line that carries no *unqualified* reference" | satisfiable exactly while still turning a **resolved** neighbour into `AMBIGUOUS (2 siblings)` — the content of the remedy line is not the discriminator |
| 2 | "at least two lines away from any unqualified reference" | puts the name outside its **own** reference's window, so the row stays `UNRESOLVED` — the remedy stopped working at all |
| 3 | "on or beside THIS reference, and at least two lines from any OTHER unqualified reference" | both rows resolve; the forbidden placement still reports |

Seeded as T42 (draft 1's failure) and T43 (draft 2's), so neither can return
silently. Draft 1 shipped; draft 2 was caught by running the remedy rather than
reading it, which is the check #102's scar exists for.

## "No rung-4 hit" is not "the file is absent" (#140, #154)

`_tree` filters `PRUNE` — which holds `target` and `dist` — and `rglob` does not
follow directory symlinks. So a file that **exists** in the named sibling can be
unindexed, and the first version of the #140 message told the reader it was gone
or moved. That is a confident wrong answer about the filesystem, which
`_sibling_hit`'s own comment calls worse than a miss. The step now asks the
filesystem with `(sib / tail).exists()` before making the claim, and reports
present-but-unindexed as its own third cause. Seeded T44 (pruned directory) and
T45 (directory symlink), with A15 removing the check to prove they measure it.

## Moved out of the skill body on 2026-09-25

The original wording of every passage that was removed or shortened when the skill body was thinned. Lines are verbatim; a line whose instruction survives in shortened form is here in full.

### Step 1

**First establish what your tool actually auto-loads, rather than assuming.** Only the project file is auto-loaded in most setups; since ADR-001 put Layer 3 in the repo, the memory index is reached by a pointer, not by the tool. In Claude Code the auto-loaded `MEMORY.md` is the *user-level* one at `~/.claude/projects/<slug>/memory/`, which shares a name with the in-repo file and is not it. Record what you measured — a size budget that includes a file which never arrives is wrong by the size of that file, and the error is invisible because the number still looks reasonable. If a budget series exists from earlier audits, say plainly whether it measured the same set; a trajectory across a change in what is being measured is not a trajectory.

- **Measure characters, not lines** — `wc -c`, with `wc -l` beside it as a readability signal only. *(`wc -c` counts bytes, so a file with multi-byte characters reads larger than its character count — `curate` sub-step 6 carries the same caveat. On this framework's own project file the gap is ~2%: 29,479 bytes to 28,915 characters. Budget in bytes and the error is on the safe side.)*
- Flag the **project file** over **35,000 characters** (soft) or **40,000** (hard) — the same two numbers `curate`'s budget uses, on purpose: the hard one is where Claude Code itself warns, the soft one leaves headroom
- Flag the **memory index** over ~**60 lines**, in lines deliberately: an index is a list, so a line is a unit of content there in a way it is not for prose (`templates/memory-index.md` separately warns that some tools truncate at ~200 lines). Report its characters too and say which number you acted on; no character threshold is prescribed, because none has been derived

**Why characters for the project file.** This step and `curate`'s budget govern the same file and used to return opposite verdicts on it: **measured 2026-08-12**, 173 lines read as *73% over* here while 24,633 characters read as *comfortably under* there. A markdown source line has no length limit, so the two cannot be reconciled — that file averaged **142 characters per line**, being prose and wide table rows rather than code, and by 2026-08-26 it had drifted to 179 lines / 28,915 characters / 162 per line without the ratio's lesson changing. This step runs monthly and `curate` every session, so the weaker instrument was the one driving the expensive restructuring work.

### Step 3

- **Session navigation in the project file**: session narrative, "what I did today", task progress → should be in the memory index. **One exception, and only where there is no Layer 3**: the `## Active work` section `templates/project-file.md` ships for tools without auto-memory is the pointer list, not session narrative, and it belongs there because the project file is the only always-loaded artifact those tools have. Flag it as wrong-layer *only* when the project has a memory index too — then there are two lists, and they will disagree.

### Step 4

Pass a `--sibling-root` for every directory that holds neighbouring repos: rung 4 resolves
cross-repo references, and with no neighbour reachable it cannot rule, which is what the third
verdict is for. ⚠️ **The rules are specified in `tests/fixtures/reference-integrity/SPEC.md`,
beside the code. Read it only if you are CHANGING the checker** — an audit does not need it,
and an always-loaded copy of an algorithm the script already runs is a second thing to get wrong.

⛔ **Prove the checker is alive before you trust a short findings list.** Append a fabricated

**Then carry that distinction into the run's verdict, not only into its prose — three outcomes, not two.** *Defects*, when a rung that actually ran ruled a reference out or ambiguous, or a document could not be read. *Clean*, when nothing was found. And a third, **coverage incomplete**, when nothing was ruled on but something was left undecided because **rung 4** had no neighbouring repo to run against. Name which one the run reached, on a line of its own, and enumerate the undecided in a counted section — Step 8 has a bucket for them. Collapsing the third state into *defects* is what makes this step useless as a gate: a correct repo whose neighbours are simply not checked out — CI, a fresh clone, a container — then fails on **where it ran** rather than on what it audited, and a gate that fires on its environment trains its reader to ignore it. Collapsing it into *clean* is worse, because with no neighbour reachable a genuine break is in that same bucket. **If you automate this step**, that is exit 1 / exit 0 / **exit 2**, and 2 must stay non-zero: a caller written as `check && …` then behaves exactly as it always did, and only one that opts in (`|| [ $? -eq 2 ]`) accepts an undecided run. Run as prose, this step returns no status at all — the verdict line is what it produces, and the numbers are for whatever you wire around it (#93).

**So do not suppress. Re-label.** Split the output into sections instead of one list — these three, plus the table's other two whenever either has members:

- **Resolved below rung 1** — every rung-2, rung-3 and rung-4 resolution of an *unmarked* path, *enumerated with what it resolved to* (a marked path excused at rung 2 or 3 is counted in the skip section instead) (`config/settings.py → packages/worker/config/settings.py`). Not defects, and not presented as "worth correcting" — but visible, so a reader who knows the file was deleted from `packages/api` can see it matched the wrong twin.

**A sixth section, `PATH SHAPES NOT EXTRACTED`, names what was never looked at.** Five
backticked shapes are outside the extractor's population — brace groups, bracket placeholders,
root-absolute, Windows and UNC paths — so a document naming `C:\dev\notes.md` got CLEAN from a
run that never examined it. They are **not findings**: nothing there is known to be wrong, only
unchecked, and a CLEAN verdict above says nothing about them. This is the same doctrine as the
dropped-extensions line on the other axis — extensions were reported and shapes were not (#122).

**Report what the extractor dropped.** List the file extensions present in the working tree that the whitelist does not cover. Skips are silent by nature; every other rung has to name itself, and skips should too. The checker counts what that cost — `REFERENCES NOT EXTRACTED`, printed before the findings — and `--ext pdf,tex` widens the whitelist for this run: a documents repo can lose most of its references to it (#199).

**Expect a residue, and do not loosen further to erase it.** Some references are *meant* not to resolve: instructional placeholders, files a runbook tells the reader to create, units owned and deployed by another repo. **Mark them** — `<!-- placeholder -->` **immediately after** the path, same line (`` `src/aggregators/<name>.py` <!-- placeholder --> ``). **Span-scoped**: it covers the nearest path *before* it, never the line and never the rest of a row, so in a table it goes in that path's own cell — one parked at the end of the row marks whatever came last. That moves them into a counted section instead of leaving them to be re-dismissed every audit. ⚠️ **That form and no other**: a marker the checker never learned leaves the finding in the list while persuading the author it is gone. What remains after marking is the genuine residue, and a short list is a healthy result. **Zero is not the target**, and a change that drives the count to zero has almost certainly disabled the check rather than fixed it.

If a check re-derives the same non-finding on consecutive runs, fix the check — a probe that cries wolf is the failure mode this framework exists to catch. **But distinguish wolf-crying from residue before touching anything**: a repeated finding that is an acknowledged placeholder, a cross-repo unit, or a file the reader is told to create is residue — mark it (above) rather than loosening the extractor that found it. Seed a break first (see the ⛔ above); if the seeded break is caught and the repeat is still there, the repeat is residue and the check is fine. **Loosening any check is the most dangerous edit you can make** — the evidence for it is a run that found nothing real, which measures specificity and says nothing about sensitivity, so seed the failures the change newly *permits*. (`SPEC.md` carries the checker-specific rules.)

### Step 5

**First establish whether this project has a Layer 3 at all, by looking for it rather than by guessing the tool.** Layer 3 is the memory index plus its topic files. Find the index at whichever path this project actually uses — `MEMORY.md` at the root, `memory/MEMORY.md`, or whatever path the project file's own pointer row names — and treat topic files beside it as part of it. Do not gate on one hardcoded path: this framework's own naming map says `MEMORY.md`, `adopt.md` writes `memory/MEMORY.md`, and a gate on either one reports "no Layer 3" for a project that has a complete one.

- **Topic files present but no index**: that is the finding, not a reason to skip. It is the most broken Layer 3 state there is, and gating the step on the index would make the step silent precisely there.
- **No Layer 3 anywhere** — the case for every tool without auto-memory, where `docs/GUIDE.md` says plainly that everything goes into the project file: report the *topic-file* half as **not applicable, and say why**. A skipped check and a passing check are indistinguishable in a report that says neither, which is the whole reason this bullet exists rather than the step quietly doing nothing.

**The work-item half runs either way — only the artifact changes.** `docs/work-items/` is tool-independent, so check that every work-item file there (other than `README.md`) has a pointer tracking it, and that no pointer names a file that no longer exists. The pointers live in the memory index's Current State section where Layer 3 exists, and in the project file's **Active work** section where it does not. **Report which one you read — and if *both* exist, that is the finding**: two lists of the same thing disagree the moment one is updated and the other is not, so say which is canonical here (the memory index) and propose removing the other. Flag pointers to work that is finished: only in-progress items belong in either list, and in the project file that list is charged against the size budget Step 1 measures.

**Do not substitute `docs/*.md` for the topic files, and do not invent a home for the work-item pointers.** `docs/` is where this framework puts essays and reference material — a dozen files in the framework repo at v1.25.0 — so treating it as a topic-file directory reports every essay as an orphan. Checking it would have flagged every one. That is now fixed at the source rather than worked around here (#44): the project file has an **Active work** section, and all four artifacts name it.

That is a **situation the agent recognises**. Describing it instead by *when it fires* — "a row whose trigger fires at session start" — is a category, and an agent satisfying the finding will write what the finding described. Note the defect is the *collision*, not the parenthesis: one row reading `Starting any session (framework drift)` is fine, and `templates/project-file.md` ships one. Two rows whose triggers are identical up to a parenthetical are not, because the parenthetical becomes the only discriminator. Propose the canonical wording, or an equivalent situation — "resuming an interrupted migration", "returning after a week away" — never a category.

**Two rows whose triggers are identical up to a parenthetical are a finding on their own.** It is the observable form of the collision and it is cheap: take each row's **first cell** — the text between the first and second `|` — strip any trailing ` (…)` or ` — …`, and flag any two rows whose remainders are then *equal*. Equal, not merely sharing a leading substring: `Editing a skill` and `Editing templates` share a prefix and are two perfectly good triggers, and a substring rule reports four such pairs on this framework's own project file. An agent choosing between `Starting any session (project state)` and `Starting any session (framework drift)` is choosing by parenthetical, which is the thing a trigger exists to make unnecessary.

**For a row whose whole function is to fire on a situation, presence is not adoption — the wording is the artifact.** Report the row's actual text, so a reader can judge the shape rather than trusting a tick.

### Step 6

Search case-insensitively for `agent-ready-projects` followed by a version-shaped token anywhere in the project file, and read the surrounding line. **Do not assume a single stamp format** — adopters write it at least four ways: `agent-ready-projects: v1.14.0`, `framework: agent-ready-projects v1.14.0` in YAML frontmatter, `- **agent-ready-projects**: v1.12.0` as a bullet, and prose inside a status paragraph. A check that matches one format reports an *unstamped* project when the stamp is simply written differently — which is worse than no check, because it prompts work that has already been done.

The most useful stamp is not a bare number but a short reconciliation record: what was adopted, what was declined, and why. Prefer that shape when proposing one.

### Step 8

**Run this every audit, and record the answer.** For each step above, and for each sub-step of the project's other recurring skills, name what it has caught **in this project** since the last audit. A step with no catch this audit is not yet a problem; a step with **no catch in its whole recorded history** is.

- **A check whose only appearances in the record are its own false positives is not an immature check. It is a check with no subject.** The tell is available on day one and costs one grep. Measured here: one framework check accumulated six false-positive classes over as many releases, each fixed with a new rung and a comment, and had caught nothing in its entire life. Every individual fix was correct; nobody asked the aggregate question.
- **Before retiring, find out whether the class is covered elsewhere.** If it is, say by what, and whether the cadence changes — a per-session check replaced by a monthly one is still a loss, just a smaller one than it looks. If it is not covered, retiring leaves the class unchecked, and that has to be the explicit decision rather than a side effect.
- **Retire by deleting, not by moving.** Relocating the prose to a rationale file removes the reading cost and keeps the work. Both are worth removing.
- **Leave a tombstone that says what would justify bringing it back**: *retired on <date>, never caught anything, do not re-add without a catch to point at*. Without it the check returns on the next session that thinks of the idea fresh.
- ⚠️ **A check that has never fired may be preventing what it checks for rather than being useless, and the record cannot tell you which.** Say which retirements rest on that ambiguity instead of deciding it silently. A check with no plausible prevention story — one that prescribes nothing an author would otherwise do — does not have this defence.

**Then make the next audit able to answer this.** When any step finds something, record the finding *and the step that found it*. Attribution is what makes retirement decidable later; without it an audit cannot tell a check that works from one that has never had a subject, and the default becomes keeping everything.

### Step 9

Open with the **verdict** — *defects*, *clean*, or *coverage incomplete*, Step 4's three outcomes — on a line of its own, above everything else. A reader who takes only the first line must not be able to mistake an undecided run for a clean one.

And one bucket that is not a severity, because it is not a defect: **Unconfirmed** — what this run could not decide, per Step 4's undecided references. They exist alongside defects and are not confined to a *coverage incomplete* run, so populate this bucket whenever there are any. Name the rung that could not run and why. These do not belong under *fix now*: telling someone to fix a reference that is merely unchecked is how a report stops being read. An empty *unconfirmed* bucket is worth stating too — it is the difference between "everything was checked" and "everything checkable was checked".

## Moved out of Step 4 in v1.49.0

The measurement behind "those three and no others" (#117): run on this framework's own `CHANGELOG.md` at v1.36.1, with 32 sibling repos reachable, the checker reported 86 findings, most of them quotations.
