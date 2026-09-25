# Update — Framework Drift

<!-- SAVE AS: ~/.claude/skills/update-drift/SKILL.md (Claude Code, USER-GLOBAL — see
     docs/GUIDE.md "Where a skill lives"; do not copy this file verbatim, its
     frontmatter is inside this comment. Prefer .claude/skills/update-drift/SKILL.md
     from this repo.)
     Diff an install against THAT file, never this one: the header differs by construction.
     For other tools, run this as a start-of-session prompt manually.

     Do NOT install this project-locally alongside a global copy; the local
     one would be inert.

     ---
     name: update-drift
     description: Check whether this project is behind the framework(s) it pins, triage each intervening release, and record what was adopted and what was declined. Stops before editing normative surfaces.
     disable-model-invocation: false
     --- -->

Check whether this project is behind the framework it pins, and decide — per release — what to do about it. **Stop at the end of Step 6.** Adopting is the engineer's call; this skill produces the triage, not the edits.

## Step 0 — Find every version stamp, without assuming its shape

A project may pin **more than one** framework, and the stamps move independently. Find them all before comparing anything, or every later drift check reports against the wrong baseline.

**A project file in a subdirectory with its own stamp is a separate adopter**: report it and run this skill there too. Its gap often looks worse than it is (one arm: 38 releases behind, 5 adoptions).

Read the project file (`CLAUDE.md`, `AGENTS.md`, or the tool's equivalent) and search for stamps **without keying on one format**. At least six shapes are in the wild:

```
<framework>: vX.Y.Z
- **<framework>**: vX.Y.Z
- **<framework>** (this repo): vX.Y.Z
- **<framework>:** vX.Y.Z
framework: <framework> vX.Y.Z
Framework version X.Y.Z (prose)
```

What varies is the **separator** — emphasis before or after the colon, a parenthetical, the word `framework`, or no colon — not the number. A matcher keyed to one shape reports an **unstamped project** when the stamp is merely written differently, so use a wide separator class, and a **second** matcher for a pin that is not a version.

**Choose the operands first, and do NOT default to `<project file> <template dir>`** — with no `templates/`, the project file reconciles **against itself** and reports clean. **Use every directory the project writes prose into** — typically the project file plus `docs/`, `memory/`, `.claude/`, and `templates/` where it exists; a framework named only outside the operands is invisible to every check below. Absent operands are not an error, so name them explicitly:

```bash
OPERANDS="<project file> docs memory .claude templates"   # drop what you do not have, and SAY which
for o in $OPERANDS; do [ -e "$o" ] || echo "operand absent, not searched: $o"; done
# ⚠️ LABEL each matcher and end each with `|| :`. grep exits 1 on no match and 2
# on an absent operand — which this block's own prose says is normal — so under
# `set -e` the run DIES at the first silent matcher and the later ones never run.
# Three unlabelled empty regions are also indistinguishable from each other, so a
# matcher that never ran reads exactly like a matcher that found nothing.
echo "--- 1. version-shaped pins"
grep -rnE "agent-ready-[a-z]+(-[a-z][a-z]+)*[^0-9]{0,60}v?[0-9]+\.[0-9]+[0-9.]*" $OPERANDS 2>/dev/null || :
echo "--- 2. commit-hash pins"
grep -rnE "agent-ready-[a-z]+(-[a-z][a-z]+)*[^A-Za-z0-9]{0,24}[0-9a-f]{7,40}" $OPERANDS 2>/dev/null || :
echo "--- 3. prose commit pins — a connector word carries the hash (#134)"
grep -rnEi "agent-ready-[a-z]+(-[a-z][a-z]+)*[^0-9]{0,40}\b(commit|rev|sha|ref|pinned to)[^A-Za-z0-9]{1,4}[0-9a-f]{7,40}" $OPERANDS 2>/dev/null || :
```

**A single-operand run is a finding, not a result** — say so in the report; a self-reconciliation always agrees.

If you adapt the matchers, keep matcher 1's allowance for letters before the version (a filename sits there) and its `{0,60}` gap (``Adopted from `agent-ready-projects` `templates/review-changes.md` (v1.18.0`` puts **33** characters between name and version), matcher 2's exclusion of letters before the hash (else a hex run matches inside a word), and matcher 3's `\b` and narrow trailing gap (else `href d89ec62` or `commitment` match). Keep `\b`, not `(^|[^A-Za-z])` — ugrep 7.8.4 refuses the group form with no output, which inside `2>/dev/null` reads as "no pins found".

Known holes: **a DIGIT between the name and the connector** escapes all three (`agent-ready-projects (2026-09-14) commit 0d67131`, `agent-ready-projects #134 commit 0d67131`) — an ordinary shape, not a rare one; so does a pin written *«fixed at»* or *«as of»*, a branch name, a date or a `main` pin. **`\b` is not POSIX ERE**: it measured identical on GNU grep 3.12, ugrep 7.8.4 and busybox 1.37, which is not a portability guarantee — an engine reading it as a literal `b` returns a silent zero. If `grep --version` shows something else, seed a known pin and confirm the matcher finds it before trusting a clean run.

No matcher here is exhaustive, so do not read a clean matcher run as a clean result — the reconciliation below is not optional.

**Report the stamps you found, by file and line, before continuing.** If you find none, say "no stamp found" and stop — do not assume the project is unadopted, and do not add a stamp yourself.

### Reconcile: a partial find reads exactly like a complete one

That guard fires only on **zero** hits; find two stamps of three and the miss is invisible. So state the denominator:

```bash
M=$(mktemp); S=$(mktemp); trap 'rm -f "$M" "$S"' EXIT
# every (file, framework) PAIR that is mentioned...
grep -rnoE "agent-ready-[a-z]+(-[a-z][a-z]+)*" $OPERANDS 2>/dev/null |
  sed -E 's/:[0-9]+:/:/' | LC_ALL=C sort -u > "$M" || :
# ...against every pair a stamp was actually found for
{ grep -roE "agent-ready-[a-z]+(-[a-z][a-z]+)*[^0-9]{0,60}v?[0-9]+\.[0-9]+[0-9.]*" $OPERANDS 2>/dev/null || :
  grep -roE "agent-ready-[a-z]+(-[a-z][a-z]+)*[^A-Za-z0-9]{0,24}[0-9a-f]{7,40}"     $OPERANDS 2>/dev/null || :
  # Matcher 3 too, or a pin only it finds reads as UNSTAMPED here (#134).
  grep -roEi "agent-ready-[a-z]+(-[a-z][a-z]+)*[^0-9]{0,40}\b(commit|rev|sha|ref|pinned to)[^A-Za-z0-9]{1,4}[0-9a-f]{7,40}" $OPERANDS 2>/dev/null || :
} | awk '{ i = index($(0), ":agent-ready-"); f = substr($(0), 1, i - 1); r = substr($(0), i + 1)
       # A stamp belongs to the LAST name before it, not the first (#134).
       while (match(r, /agent-ready-[a-z]+(-[a-z][a-z]+)*/)) { n = substr(r, RSTART, RLENGTH); r = substr(r, RSTART + RLENGTH) }
       print f ":" n }' | LC_ALL=C sort -u > "$S"
printf 'mentioned pairs: %s  stamped pairs: %s\n' "$(wc -l < "$M")" "$(wc -l < "$S")"
[ -s "$M" ] || echo 'EMPTY — the mention grep matched nothing. Check the operands before reading this as clean.'
LC_ALL=C comm -23 "$M" "$S"
```

Do not simplify the block: the `(file, framework)` unit (a file pinning two frameworks reads as stamped when only one pin matched), the printed counts (with mistyped operands `comm` prints nothing at exit 0), `sort -u` and `LC_ALL=C` on both sides and on `comm`, and `|| :` on each grep each prevent a wrong difference. **Keep the operands disjoint** — overlap, such as adding `.` or a parent of another operand, makes `comm -23` report a stamped file as unstamped.

**Report both counts and every file in the difference.** Each one gets a disposition out loud: *a stamp the matcher missed* (read the line, name the shape, use it) or *a mention that is not a pin*.

### A pin that resolves to no version

A commit hash, branch name or date is a pin but **not** a version, so Step 1 cannot list the releases after it. Give it its own outcome:

- Resolve it if you can — `git -C ~/repos/<framework> describe --tags --contains <hash>` names the first release containing that commit, and that release is the pin.
- Otherwise report **`unresolvable pin: <what was found>, in <file>:<line>`** and carry it to the report as an explicit outcome. Do not substitute the latest version, and do not treat the framework as un-pinned.

Then check the templates directory too, if the project ships one: releases habitually miss a scaffolding template's stamp, and a template with **no** stamp is worse — the drift check it prescribes has nothing to read, and passes.

## Step 1 — Establish the gap

For each stamp, read that framework's changelog and list every version between the pinned one (exclusive) and the latest (inclusive). Name the count.

**Ignore a diff confined to a template's `framework:` stamp line**: every release bumps it. `0` here means stamp-only (the second `grep` drops only the `---`/`+++` headers, not an added `- bullet`):

```bash
git diff vOLD..vNEW -- templates/<file>.md | grep -E '^[-+]' | grep -Ev '^(\+\+\+|---) ' | grep -vc 'framework:'
```

Prefer a local clone if one exists (`~/repos/<framework>/CHANGELOG.md`), else the published URL. If the clone is behind its own remote, say so.

If the project is current, say so and stop. "Reviewed and declined" from a previous session counts as current — check the changelog or memory for a recorded decline before reporting drift on something already decided.

## Step 2 — Triage each release into one of five outcomes, plus one for a framework whose pin never resolved

Every release gets exactly one of:

| Outcome | Means | What it must carry |
|---------|-------|--------------------|
| **Adopt** | Lands as a concrete change here | Which file(s), and what the change is |
| **Decline** | Applies, but this project shouldn't take it | **The reason.** This is the load-bearing one. Cite the upstream issue where one exists, not a version: a version-pinned note goes stale on their cadence, unnoticed. With no issue, the version is the only handle |
| **Not applicable** | No counterpart surface in this project | Which surface is missing |
| **Already in force** | The behaviour is present but undocumented here | What to correct in the docs |
| **Superseded** | A later release in this same gap changed it again | Which release. Triage that one instead |
| **Unresolvable pin** | The stamp is not a version, and Step 0 could not resolve it to one | What was found, and where — this outcome applies to the *framework*, not to one release, and it means the release list below it could not be built |

**"Already in force" is the outcome people forget** — e.g. a user-global skill updated outside this repo, which the project file may still describe as project-local. Check the actual installed artifact (`diff` it against the framework's tracked copy), not the project file's description of it.

**A decline without a recorded reason will be re-derived next session, and may be re-derived differently.** Write the reason where the next agent will read it — the changelog entry, the memory index, or a decision record.

## Step 3 — Check the surfaces `git diff` cannot see

Framework changes often land in paths gitignored in adopter repos — `.claude/skills/`, `memory/`, `docs/work-items/`, local settings — which `git status` reports as unchanged because they are invisible. List the gitignored paths the framework touches and inspect each by eye. Say in the report when a behaviour changed only in an unshipped file.

**A re-mapped project-local skill needs a CONTENT check; its stamp cannot answer for it. Diff the installed file against the framework's REFERENCE INSTALL, not against its template — the answer is then an exact zero, not a minimum.** This framework installs with a plain `cp` from `.claude/skills/<name>/SKILL.md` — **no install-time transform**; the `SAVE AS` frontmatter is a maintainer-side edit between template and reference install — so an install is **byte-identical to one tracked file at exactly one tag**:

```
curate, installed        vs templates/curate.md @v1.34.2       -> 24 differing lines
curate, installed        vs .claude/skills/curate/SKILL.md @v1.34.2 -> 0
```

**Only fall back to the minimise-sweep below if your framework's installer genuinely transforms at install time** — check before assuming it does; ours does not.

<details><summary>Fallback for a framework whose installer really does transform</summary>

**Diff the installed file against EVERY tag and read which one MINIMISES.** This applies only to such a framework: there a single diff against latest reads *differs* whether the install is behind or current, and the false *not adopted* makes an adopter re-copy a skill they re-mapped. The **monotone fall to a floor** is the signal and the floor is the installer's constant.

```
audit-context   v1.28.0 diff 84   v1.29.0 diff 74   v1.30.0 diff 23   v1.31.0 diff 23
curate          v1.28.0 diff 119  v1.29.0 diff 119  v1.30.0 diff 119  v1.31.0 diff 24
```

`audit-context` is flat from v1.30.0 — current since then. `curate` falls only at v1.31.0 — current as of it.

</details>

**Grep for the marker strings the release note names** — a defensive fix can look identical to the broken version in isolation. If no markers are named, ask, and record `not verified`.

**A marker is not evidence that the thing runs. If the release changes a fenced executable block, extract it and `bash -n` BOTH the version you are leaving and the version you are taking, before adopting either.** A block that dies on a syntax error prints nothing, like a clean run, and upstream lint never reaches a project-local or re-mapped copy in your tree.

## Step 4 — Verify by execution, not by reading

Anything the framework's changelog *asserts* about behaviour is a claim, and adopting a claim is adopting whatever is wrong with it.

- If a release says a check now catches X, **run it against X** before writing that down.
- If it prescribes a command, **run the command** and confirm it produces the output described.
- If it names a threshold or a failure mode, reproduce it.

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

State the count adopted, declined, not-applicable, and already-in-force. **A run where everything is "adopt" is suspicious** — it usually means the triage collapsed into "take it all".

## Step 6 — Stop, and hand over

Report before editing anything normative — the project file, templates, decision records: surfaces a human may need to disagree with, where a wrong edit propagates silently to every future session.

Present:
- The stamps found, and the gap for each
- The triage table
- What you verified by execution, and what you could not
- The proposed edits, file by file
- The proposed new stamp value(s)

**Do not bump the stamp until the changes it describes have actually landed.** A stamp ahead of its content is worse than a stale one: it silences the check that would catch the gap.

## After the engineer approves

Once the edits land, the adoption itself is a change like any other:

- Run the project's pre-commit review if it has one.
- Record the declines somewhere durable — a gitignored file is invisible to others; an issue is not.
- If the adoption warrants a release, that is a separate decision and a separate skill.

## Do not

- **Do not auto-adopt.** Surfacing drift is this skill's job; deciding is the engineer's.
- **Do not bump a stamp you did not earn.** See Step 6.
- **Do not report "no stamp found" as "not adopted."** See Step 0.
- **Do not treat the framework's changelog as verified.** See Step 4.
- **Do not install this skill project-locally** if a user-global copy exists. It would be inert, and would drift from the copy actually loading.
