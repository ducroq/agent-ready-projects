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
