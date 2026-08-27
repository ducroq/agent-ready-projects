# Update — Framework Drift

<!-- SAVE AS: ~/.claude/skills/update-drift/SKILL.md (Claude Code, USER-GLOBAL)
     For other tools, run this as a start-of-session prompt manually.

     Scope: user-global. The drift question is identical in every adopter
     repo, and no repo needs its own variant — see "Where a skill lives"
     in docs/GUIDE.md. Do NOT install this project-locally alongside a
     global copy; the local one would be inert.

     This promotes adopt.md §3 ("Update — am I behind?") from a
     copy-paste prompt into a skill. §3 is the one of adopt.md's three
     prompts that fires repeatedly — assess and adopt fire once per
     project — which is what earns it a slot under the cadence rule in
     docs/GUIDE.md.

     ---
     name: update-drift
     description: Check whether this project is behind the framework(s) it pins, triage each intervening release, and record what was adopted and what was declined. Stops before editing normative surfaces.
     disable-model-invocation: false
     --- -->

Check whether this project is behind the framework it pins, and decide — per release — what to do about it. **Stop at the end of Step 6.** Adopting is the engineer's call; this skill produces the triage, not the edits.

## Step 0 — Find every version stamp, without assuming its shape

A project may pin **more than one** framework. Find them all before comparing anything: a repo that adopts both a code framework and a writing framework carries two stamps that move independently, and a release that bumps one and leaves the other stale makes every later drift check report against the wrong baseline.

Read the project file (`CLAUDE.md`, `AGENTS.md`, or the tool's equivalent) and search for stamps **without keying on one format**. At least six shapes are in the wild:

```
<framework>: vX.Y.Z
- **<framework>**: vX.Y.Z
- **<framework>** (this repo): vX.Y.Z
- **<framework>:** vX.Y.Z
framework: <framework> vX.Y.Z
Framework version X.Y.Z (prose)
```

The versions above are placeholders on purpose. What varies between the shapes is the **separator** — emphasis before or after the colon, a parenthetical, the word `framework`, or no colon at all — not the number. Real versions here would go stale and would be returned by every future release sweep as hits to re-triage.

A matcher keyed to one of these reports an **unstamped project** when the stamp is merely written differently — which reads identically to "no framework adopted here" and is the wrong conclusion. Use a wide separator class, and a **second** matcher for a pin that is not a version:

```bash
# 1. version-shaped pins
grep -rnE "agent-ready-[a-z]+[^0-9]{0,60}v?[0-9]+\.[0-9]+[0-9.]*" <project file> <template dir>
# 2. commit-hash pins
grep -rnE "agent-ready-[a-z]+[^A-Za-z0-9]{0,24}[0-9a-f]{7,40}" <project file> <template dir>
```

- **`{0,60}`, not `{0,24}`** — ``Adopted from `agent-ready-projects` `templates/review-changes.md` (v1.18.0`` puts **33** characters between name and version. At `{0,24}` that stamp was invisible for a whole adoption while two others in the same repo were found.
- **Matcher 2** exists because matcher 1 needs two dot-separated numeric groups, which no separator width reaches on a hash.
- **The two separator classes differ, and that is why these are two matchers rather than one alternation.** Matcher 1 allows letters between the name and the version, because a provenance line puts a filename there. Matcher 2 must *exclude* them, or a 7-character hex run matches inside an ordinary word. One pattern cannot hold both rules. Combining them as `(a|b)` also works on every implementation tried here — GNU grep 3.12 and busybox — so combine them if you prefer; the reason for two is the classes, not the tool.

Neither matcher is exhaustive — a branch name, a date or a `main` pin is a pin they cannot see — which is why the reconciliation below is not optional.

**Report the stamps you found, by file and line, before continuing.** If you find none, say "no stamp found" and stop — do not assume the project is unadopted, and do not add a stamp yourself.

### Reconcile: a partial find reads exactly like a complete one

That guard only fires on **zero** hits. Find two stamps of three and the step reports two real stamps and proceeds — the miss is invisible, and that framework is then triaged against the wrong baseline or not at all. It has happened twice: to a 33-character separator, and to a commit-hash pin.

So state the denominator:

```bash
M=$(mktemp); S=$(mktemp); trap 'rm -f "$M" "$S"' EXIT
# every (file, framework) PAIR that is mentioned...
grep -rnoE "agent-ready-[a-z]+" <project file> <template dir> 2>/dev/null |
  sed -E 's/:[0-9]+:/:/' | LC_ALL=C sort -u > "$M" || :
# ...against every pair a stamp was actually found for
{ grep -roE "agent-ready-[a-z]+[^0-9]{0,60}v?[0-9]+\.[0-9]+[0-9.]*" <project file> <template dir> 2>/dev/null || :
  grep -roE "agent-ready-[a-z]+[^A-Za-z0-9]{0,24}[0-9a-f]{7,40}"     <project file> <template dir> 2>/dev/null || :
} | sed -E 's/^(.*):(agent-ready-[a-z]+).*/\1:\2/' | LC_ALL=C sort -u > "$S"
printf 'mentioned pairs: %s  stamped pairs: %s\n' "$(wc -l < "$M")" "$(wc -l < "$S")"
[ -s "$M" ] || echo 'EMPTY — the mention grep matched nothing. Check the operands before reading this as clean.'
LC_ALL=C comm -23 "$M" "$S"
```

Five details in that block are load-bearing, and each was measured rather than reasoned:

- **The unit is `(file, framework)`, not `file`.** A file-scoped difference cannot see the failure this section exists for. #72's own repro is one `CLAUDE.md` pinning two frameworks, one by hash and one by tag: with only the version matcher running, that file is "stamped" because the *other* framework matched, and the missing hash pin never appears in the difference. Measured on exactly that shape — file-scoped reported a clean reconciliation while a pin was invisible.
- **The counts are printed by the command, not left to the reader.** With mistyped operands both files come out empty, `comm` prints nothing and exits 0 — indistinguishable from a clean reconciliation. That is this section's own failure one layer up: an instrument that cannot report its blind spot. The `printf` and the `[ -s ]` line are what make a zero denominator visible.
- **`sort -u` on BOTH sides.** This is a set difference. With `sort` on the left and `sort -u` on the right, an operand pair that overlaps — a project file *inside* the template dir, or `CLAUDE.md .` — emits the file twice on the left and once on the right, and `comm -23` reports a correctly stamped file as unstamped. Measured.
- **`LC_ALL=C` on both sorts *and on `comm`*.** `comm` compares bytes in the implementation measured here, but GNU `comm` collates by locale when the locale is "hard" — in which case C-sorted input under a UTF-8 locale is the "not in sorted order, wrong difference" failure this bullet is about, *caused by the recipe*. Putting `LC_ALL=C` on all three costs nothing and removes the question. (Measured on uutils coreutils 0.8.0; GNU `comm` not available here to test.)
- **`|| :` on each grep.** A grep that matches nothing exits 1. Under `set -eo pipefail` that kills the block *after* the redirect has already truncated the stamped list, so a later `comm` reports every mention as a miss.

**Report both counts and every file in the difference.** Each one gets a disposition out loud: *a stamp the matcher missed* (read the line, name the shape, use it) or *a mention that is not a pin*. A difference nobody looked at is the same failure one layer up.

### A pin that resolves to no version

A commit hash, branch name or date is a pin but **not** a version, so Step 1 cannot list the releases after it. Give it its own outcome:

- Resolve it if you can — `git -C ~/repos/<framework> describe --tags --contains <hash>` names the first release containing that commit, and that release is the pin.
- Otherwise report **`unresolvable pin: <what was found>, in <file>:<line>`** and carry it to the report as an explicit outcome. Do not substitute the latest version, and do not treat the framework as un-pinned.

Then check the templates directory too, if the project ships one. A scaffolding template that stamps a framework version is the file releases habitually miss: nobody edits it during a normal release, so it never appears in a current-version grep, and a new adopter inherits a stamp that misdescribes the files they just got. A template with **no** stamp at all is the stronger version of the same defect — the drift check it tells the adopter to run has nothing to read, and passes.

## Step 1 — Establish the gap

For each stamp, read that framework's changelog and list every version between the pinned one (exclusive) and the latest (inclusive). Name the count.

Prefer a local clone if one exists (`~/repos/<framework>/CHANGELOG.md`) — it is authoritative and free. Fall back to the published URL. If the clone is behind its own remote, say so: you would otherwise triage against a stale upstream.

If the project is current, say so and stop. "Reviewed and declined" from a previous session counts as current — check the changelog or memory for a recorded decline before reporting drift on something already decided.

## Step 2 — Triage each release into one of four outcomes, plus one for a framework whose pin never resolved

Not "does this apply?" — which invites a yes/no and loses the reasoning. Every release gets exactly one of:

| Outcome | Means | What it must carry |
|---------|-------|--------------------|
| **Adopt** | Lands as a concrete change here | Which file(s), and what the change is |
| **Decline** | Applies, but this project shouldn't take it | **The reason.** This is the load-bearing one |
| **Not applicable** | No counterpart surface in this project | Which surface is missing |
| **Already in force** | The behaviour is present but undocumented here | What to correct in the docs |
| **Unresolvable pin** | The stamp is not a version, and Step 0 could not resolve it to one | What was found, and where — this outcome applies to the *framework*, not to one release, and it means the release list below it could not be built |

**"Already in force" is the outcome people forget, and it produces real corrections.** A user-global skill updated outside this repo is current here without anything in this repo changing — and the project file may still describe it as project-local, which has quietly been false since whenever the scope changed. Check the actual installed artifact (`diff` it against the framework's tracked copy), not the project file's description of it.

**A decline without a recorded reason will be re-derived next session, and may be re-derived differently.** Write the reason where the next agent will read it — the changelog entry, the memory index, or a decision record.

## Step 3 — Check the surfaces `git diff` cannot see

Framework changes often land in paths that are gitignored in adopter repos: `.claude/skills/`, `memory/`, `docs/work-items/`, local settings. A drift check driven only by `git status` reports these as unchanged because they are invisible, not because they are current.

List the gitignored paths the framework touches and inspect each by eye. Say in the report when a behaviour changed only in an unshipped file — an adopter reading the diff cannot otherwise see it.

⚠️ **A re-mapped project-local skill needs a CONTENT check; a version stamp cannot answer for it.** A user-global skill is covered — the installer compares bytes. A project-local one is a copy the adopter owns, and a *re-mapped* copy will never match the template again, so eyeballing a 577-line diff is not a method and the pin says nothing about the file. ⚠️ **Diff the installed file against EVERY tag and read which one MINIMISES, not against HEAD alone.** A user-global install is not byte-identical to any tracked copy — the installer rewrites the header — so a single diff against latest returns *differs* both for "behind by four releases" and for "current, plus the installer's transformation", and the naive reading produces a false *not adopted* on a repo that is fully up to date. That is the reading that makes an adopter re-copy a skill they re-mapped. The **monotone fall to a floor** is the signal and the floor is the installer's constant. Measured by an adopter across four tags:

```
audit-context   v1.28.0 diff 84   v1.29.0 diff 74   v1.30.0 diff 23   v1.31.0 diff 23
curate          v1.28.0 diff 119  v1.29.0 diff 119  v1.30.0 diff 119  v1.31.0 diff 24
```

`audit-context` is flat from v1.30.0 — current since then. `curate` falls only at v1.31.0 — current as of it. Neither reading is available from a diff against HEAD alone.

**Grep for the marker strings the release note names.** A defensive fix looks like nothing: the framework shipped one where broken and fixed were semantically identical in isolation — no error, no empty output, no non-zero status, the check simply examined a constant and printed what a clean run prints. If no markers are named, ask, and record `not verified` (#94).

## Step 4 — Verify by execution, not by reading

Anything the framework's changelog *asserts* about behaviour is a claim, and adopting a claim is adopting whatever is wrong with it.

- If a release says a check now catches X, **run it against X** before writing that down.
- If it prescribes a command, **run the command** and confirm it produces the output described.
- If it names a threshold or a failure mode, reproduce it.

This is not ceremony. Prose describing a check is routinely wrong in ways that survive several readings by its own author — including, on at least one occasion, prose describing how a check can be gamed that named the one route that does not work. Reading it against the code is a weaker instrument than running it.

Where you cannot run something (no network, no credentials, no fixture), report **"not verified"** and say why. Never report a check as passing on the strength of its description.

## Step 5 — Write the adoption record

Produce a table — this is the artifact the skill exists to create:

```
| From | What | Outcome |
|------|------|---------|
| v1.13.0 | release skill | Adopted → .claude/skills/release/ |
| v1.13.1 | layer-depth guide section | Not applicable — no GUIDE.md counterpart here |
| v1.15.0 | install-global-skills.sh | Declined — belongs upstream, where the globals live |
| v1.15.1 | audit-context Step 4 rewrite | Already in force — global skill is current |
```

State the count adopted, declined, not-applicable, and already-in-force. **A run where everything is "adopt" is suspicious** — it usually means the triage collapsed into "take it all" without asking what this project actually needs.

## Step 6 — Stop, and hand over

Report before editing anything normative. Adoption touches the project file, templates, and decision records — surfaces a human may reasonably need to disagree with, and where a wrong edit propagates silently to every future session.

Present:
- The stamps found, and the gap for each
- The triage table
- What you verified by execution, and what you could not
- The proposed edits, file by file
- The proposed new stamp value(s)

**Do not bump the stamp until the changes it describes have actually landed.** A stamp that runs ahead of its content is worse than a stale one: it silences the very check that would have caught the gap.

## After the engineer approves

Once the edits land, the adoption itself is a change like any other:

- Run the project's pre-commit review if it has one — this skill's own output has been found holed by one.
- Record the declines somewhere durable. A finding that lives only in a gitignored file is invisible to adopters and to sibling projects; an issue is the copy others can see.
- If the adoption warrants a release, that is a separate decision and a separate skill.

## Do not

- **Do not auto-adopt.** Surfacing drift is this skill's job; deciding is the engineer's.
- **Do not bump a stamp you did not earn.** See Step 6.
- **Do not report "no stamp found" as "not adopted."** See Step 0.
- **Do not treat the framework's changelog as verified.** See Step 4.
- **Do not install this skill project-locally** if a user-global copy exists. It would be inert, and would drift from the copy actually loading.
