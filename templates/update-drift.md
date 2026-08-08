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

A matcher keyed to one of these reports an **unstamped project** when the stamp is merely written differently — which reads identically to "no framework adopted here" and is the wrong conclusion. Use a wide separator class:

```bash
grep -rnE "agent-ready-[a-z]+[^0-9]{0,24}v?[0-9]+\.[0-9]+" <project file> <template dir>
```

**Report the stamps you found, by file and line, before continuing.** If you find none, say "no stamp found" and stop — do not assume the project is unadopted, and do not add a stamp yourself.

Then check the templates directory too, if the project ships one. A scaffolding template that stamps a framework version is the file releases habitually miss: nobody edits it during a normal release, so it never appears in a current-version grep, and a new adopter inherits a stamp that misdescribes the files they just got. A template with **no** stamp at all is the stronger version of the same defect — the drift check it tells the adopter to run has nothing to read, and passes.

## Step 1 — Establish the gap

For each stamp, read that framework's changelog and list every version between the pinned one (exclusive) and the latest (inclusive). Name the count.

Prefer a local clone if one exists (`~/repos/<framework>/CHANGELOG.md`) — it is authoritative and free. Fall back to the published URL. If the clone is behind its own remote, say so: you would otherwise triage against a stale upstream.

If the project is current, say so and stop. "Reviewed and declined" from a previous session counts as current — check the changelog or memory for a recorded decline before reporting drift on something already decided.

## Step 2 — Triage each release into one of four outcomes

Not "does this apply?" — which invites a yes/no and loses the reasoning. Every release gets exactly one of:

| Outcome | Means | What it must carry |
|---------|-------|--------------------|
| **Adopt** | Lands as a concrete change here | Which file(s), and what the change is |
| **Decline** | Applies, but this project shouldn't take it | **The reason.** This is the load-bearing one |
| **Not applicable** | No counterpart surface in this project | Which surface is missing |
| **Already in force** | The behaviour is present but undocumented here | What to correct in the docs |

**"Already in force" is the outcome people forget, and it produces real corrections.** A user-global skill updated outside this repo is current here without anything in this repo changing — and the project file may still describe it as project-local, which has quietly been false since whenever the scope changed. Check the actual installed artifact (`diff` it against the framework's tracked copy), not the project file's description of it.

**A decline without a recorded reason will be re-derived next session, and may be re-derived differently.** Write the reason where the next agent will read it — the changelog entry, the memory index, or a decision record.

## Step 3 — Check the surfaces `git diff` cannot see

Framework changes often land in paths that are gitignored in adopter repos: `.claude/skills/`, `memory/`, `docs/work-items/`, local settings. A drift check driven only by `git status` reports these as unchanged because they are invisible, not because they are current.

List the gitignored paths the framework touches and inspect each by eye. Say in the report when a behaviour changed only in an unshipped file — an adopter reading the diff cannot otherwise see it.

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
