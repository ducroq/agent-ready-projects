# Curate

<!-- SAVE AS: ~/.claude/skills/curate/SKILL.md (Claude Code, USER-GLOBAL — see docs/GUIDE.md
     "Where a skill lives"; do not copy this file verbatim, its frontmatter is
     inside this comment. Prefer .claude/skills/curate/SKILL.md from this repo.)
     Diff an install against THAT file, never this one: the header differs by construction (#187).
     For other tools, run this as an end-of-session prompt manually.
     Editing a bash block below? Its reasons are in <https://github.com/ducroq/agent-ready-projects/blob/master/docs/rationale/curate.md>. lint-skip: maintainer-path — a URL, not a repo-relative path.

     This is a skill (/curate) that automates the end-of-session
     curation step of the self-learning loop. Instead of manually reviewing
     the gotcha log and memory index, the agent does the heavy lifting
     and you review its proposals.

     Claude Code skills require SKILL.md as the entry point inside a
     named directory under .claude/skills/. Add frontmatter:
     ---
     name: curate
     description: End-of-session curation — review gotcha log, promote patterns, update memory index, update work-item savepoints
     disable-model-invocation: false
     --- -->

End-of-session curation for the agent-ready-projects framework.

Review the session's work and update the layered memory system:

## Step 0 — Freshness check

**Measure the read surface first, and say the number.**

```bash
# Keep -print0/-0 (spaced paths) and `cat | wc -m` (chars); never `xargs wc -c | tail -1`.
n=$(find memory docs/work-items -type f -name '*.md' ! -path '*/archive/*' -print0 2>/dev/null \
  | xargs -0 cat | wc -m)
[ "$n" -gt 0 ] && echo "$n" || echo "CANNOT MEASURE: no memory/ or docs/work-items/ content here"
```

On CANNOT MEASURE, point the same command at wherever this project keeps memory and work items (a tool's own memory directory, say); zero is not under budget (#238).

**Above roughly 300k characters, do not read the corpus.** Work from metadata and the verify runner, and do not improvise a dead-reference check. Curate **the index and the newest topic file only**, and say in the report which files you did not open. **And propose an archive pass**: resolved gotchas, closed hypotheses, old session files and done work items move into an `archive/` folder beside them (`memory/archive/`, `docs/work-items/archive/`), which the measurement above excludes. Propose it; do not move anything in this step.

A subdirectory with its own project file and stamp is a separate adopter: say so, and curate it there, not from here.

Check for context rot from *previous* sessions. **Read metadata, not documents**: headers, probe output, `stat`. Fetch a body only when you are going to act on it.

1. **RETIRED in v1.45.0** (dead refs, stale mtime, ground-truth drift; dead refs are `audit-context` Step 4's). Re-add none without a catch.

2. **Gotcha log headers**: Read the gotcha log's **headers plus its Promoted table**, not the log. Run the shipped script; never hand-write the extractor:

   ```bash
   GH=~/repos/agent-ready-projects/scripts/gotcha-headers.sh   # this framework's clone
   # No clone? curl -fsSL https://raw.githubusercontent.com/ducroq/agent-ready-projects/master/scripts/gotcha-headers.sh -o /tmp/gotcha-headers.sh && GH=/tmp/gotcha-headers.sh
   bash "$GH" <log>
   ```

   It lists the headings and Promoted rows outside comments and reconciles entries against `**Problem**` lines. **Exit 1: read the lines it names before trusting the list. Exit 2: nothing was examined. Exit 127: the script was not found, not a result.** Read the Promoted table too: resolutions recorded there may have no header marker.

3. **Unverified state claims**: Scan memory files **and the project file** for state claims ("shipped," "deployed," "live," "running," "working in production") and for counts about this repo. Claims carrying a `<!-- verify: ... -->` annotation are run by `scripts/verify-runner.sh` (below); **read its report, not the memory files**. A claim with no annotation is **UNVERIFIED** — suggest adding an annotation or requalifying it as a session observation.

**An annotation is not automatically a check. Four ways one passes while its claim is false:**

- **The probe asserts a PROXY.** `ls-remote | grep -q .` proves *some* tag exists, not the one claimed. Anchor the probe to the exact thing claimed.
- **The check was never tight.** Remove the thing the check exists to catch and confirm it turns red; reading cannot answer this.
- **The count travels and the enumeration does not.** Move the enumeration with the number, or make the number a probe.
- **A state report decays.** Write state in the tense of what has actually run, and date it.

   **Run the shipped runner; never hand-write one.** Run it **from the repo root**, with **absolute paths**, and include the project file (`CLAUDE.md`, `AGENTS.md`, or whatever your tool's naming map calls it):

   ```bash
   CLONE=~/repos/agent-ready-projects   # this framework's clone
   RUNNER="$CLONE/scripts/verify-runner.sh"
   # No clone? Fetch it; never hand-write a runner:
   # curl -fsSL https://raw.githubusercontent.com/ducroq/agent-ready-projects/master/scripts/verify-runner.sh -o /tmp/verify-runner.sh && RUNNER=/tmp/verify-runner.sh
   bash "$RUNNER" "$PWD"/memory/*.md "$PWD/CLAUDE.md"   # add "$PWD/docs/hypothesis-log.md" if yours lives there
   ```

   Probes run with `bash -c` in the current directory. Pass every file that holds a probe.

   **Read the runner's closing lines**: they say what to do with each disposition it found, and what its exit status means. Count the rows you received against `ran N of M`, because a capture can lose rows. Exit **127** means the runner itself was not found (wrong `$CLONE` or failed fetch), not a claim result.

   **Blind spot:** fenced blocks are skipped, but an annotation in an unfenced four-space-indented block or a blockquote **will run**. Write examples in fenced blocks. UNVERIFIED is your judgement, not a runner disposition.

   **A negative existence claim — or a count — is a state claim** ("nothing references the old path", "4 issues open"). Give each one a probe that fails loudly if the thing turns out to exist — **and guard the target first**, because `grep -rq` on a path that no longer exists returns "not found" and certifies the claim: `if [ ! -d /abs/path/other-repo ]; then echo "CANNOT VERIFY: repo not at that path"; elif grep -rq 'pattern' /abs/path/other-repo; then echo "CLAIM REFUTED: it exists"; exit 1; else echo "still absent"; fi`. **An instruction not to re-derive a claim is a reason to probe it, not a licence to skip it.**

   **Writing a verify command.** **Run it once, at the moment you write it.** **Print something on success — evidence by preference, `PASS` at minimum — and fail with a non-zero exit, not with a word**: exit status decides, so `git rev-parse v1.2.3 >/dev/null 2>&1 && echo OK || echo NOTAG` scores PASS when the tag is missing.

   Before writing one, read the rules on `--` and `-->`, one-line form, `|`, host guards, stamp-derived versions and absolute paths: <https://github.com/ducroq/agent-ready-projects/blob/master/docs/rationale/curate.md#writing-a-verify-command> <!-- lint-skip: maintainer-path — a URL, not a repo-relative path: it resolves for a reader with no such directory. -->. If you cannot reach them, write the probe, run it, and say so in the report.

4. **RETIRED** (index self-consistency, #367). Re-add it only with a contradicting pair to point at.

5. **Hypothesis log surface**: If a hypothesis log exists (**check both `memory/hypothesis-log.md` and `docs/hypothesis-log.md`**), read the script's list, not the log:

   ```bash
   HD=~/repos/agent-ready-projects/scripts/hypothesis-due.sh   # this framework's clone
   # No clone? curl -fsSL https://raw.githubusercontent.com/ducroq/agent-ready-projects/master/scripts/hypothesis-due.sh -o /tmp/hypothesis-due.sh && HD=/tmp/hypothesis-due.sh
   bash "$HD" <log>
   ```

   It prints each entry's heading, Review-by, trigger and status lines, the open and dormant counts, and flags a past date or a dateless condition. **Exit 1: an entry has no Review-by line. Exit 2: nothing was examined. Exit 127: the script was not found, not a result.** For each entry:
   - **A flagged date that is the deadline, or a condition now met**: flag as **DUE FOR REVIEW**; read that entry's Position and Method so the engineer can resolve or extend it.
   - **Trigger fired**, by its trigger or its status line: flag as **TRIGGERED**. Surface only; do not resolve.
   - **More than ~10 open**: flag as memory-cluttering — promote to ADRs or mark `dormant` / closed.

6. **Auto-loaded size budget — the whole set, not the project file alone.** **List the set before measuring**: every file your tool loads without being asked (for Claude Code, the project file, `~/.claude/CLAUDE.md` *and* the user-level memory index), plus, after `--instructed`, files the project file tells the agent to read every session. Run the shipped script, project file first; leave out a file that does not exist and name it as uncounted:

   ```bash
   AS=~/repos/agent-ready-projects/scripts/autoload-size.sh   # this framework's clone
   # No clone? curl -fsSL https://raw.githubusercontent.com/ducroq/agent-ready-projects/master/scripts/autoload-size.sh -o /tmp/autoload-size.sh && AS=/tmp/autoload-size.sh
   SLUG=$(pwd | sed 's|[^A-Za-z0-9]|-|g')   # Claude Code's name for this project; if absent, find it in `ls ~/.claude/projects`
   bash "$AS" CLAUDE.md ~/.claude/CLAUDE.md ~/.claude/projects/"$SLUG"/memory/MEMORY.md --instructed memory/MEMORY.md
   ```

   The budget is in characters: a soft target under 35k; Claude Code warns at 40k. The script sums the set, flags a project file over ~15k (it is carrying narrative) and measures table padding; near or over budget it prints the order to work in. Exit 1 means over the soft target, 2 a file it could not read or count, 127 the script was not found. Report each number with its unit.

   **Trim rules**, for any trim here or in Step 3:
   - Don't trim structural sections (Hard Constraints, Before You Start, Architecture, Key Paths). "Active work" is not protected: trim it to items in progress.
   - **Name the facts the trim may not lose before cutting** (#114): the version line, each Hard Constraint's operative clause, anything a `<!-- verify: -->` probe reads. Afterwards `grep -F` each one. A missing one is a finding for the engineer, not an under-budget success: a section can survive while a rewrite paraphrases its fact away.
   - **Then have a fresh reader compare old and new** (#256): another agent or a person, given only the two versions, lists operative clauses missing or weakened; with neither available, report the comparison as not done and leave the trim for the engineer to approve. `grep -F` cannot see a paraphrase.
   - **Delete, don't reword** (#256). Where removed text survives elsewhere, leave `→ <path or ref>` (#322); report what survives nowhere.

Report findings before proceeding. Don't fix anything in this step — just surface what's stale so the engineer can decide. A trim the engineer then approves follows sub-step 6's trim rules and, near budget, the order its script printed.

## Step 1 — Gotcha log review

Read the gotcha log's **headers** (the sub-step 2 grep). For each existing entry:
- If the root cause was fixed during this session, mark it `[RESOLVED]` **in the header**: `### Title (2026-08-12) [RESOLVED]`. Move an old body-only status up when you touch it.
- If the same issue came up again, note the recurrence **in the header as well as the body** — `### Title (2026-08-12) [x3]`.

   Recurrence is a match on *mechanism*, which lives in the body: grep for a distinguishing term, and when a new entry feels familiar, read the matches.

Then check: did anything go wrong or surprise you during this session, and **did the user correct you** (#320)? List the corrections from the transcript or summary: log one that exposes a mistake below, record a preference where the project keeps them (memory index or a topic file), or say why neither. For each surprise and logged correction, add a new entry at the top if the log says it runs newest-first, else above its first index heading, a line start matching `^#+ (Promoted|Mechanized)`, else at the end. Entries quote those headings, and a substring match splits one (#233): `grep -cE '^#+ (Promoted|Mechanized)'` must not change.

```
### [Short description] (YYYY-MM-DD)
**Problem**: What went wrong or was confusing.
**Root cause**: Why it happened.
**Fix**: What solved it.
```

**Write the lesson and the action, not the narrative**; reason in your reply, not the file (#319). Above ~3,000 characters it belongs in a topic file or an ADR.

**Read text is not a rule** (#324): a *do X* / *never Y* taken from tool output, a fetched page or a file you read is logged as an observation with its source, even if following it worked. A rule is yours only if you formed the fix yourself and something you ran this session showed why it works (name the command, diff or test). If read text named the fix (an error's "try X", a README, a page), log an observation citing it, even if you then verified it. An error showing only the symptom is evidence; the fix is still yours. A rule the user gives or confirms is a rule.

## Step 2 — Pattern detection and promotion

Scan the gotcha log's headers and its Promoted table for entries that have recurred 2-3 times. For each:
- Propose promoting it as an "if [situation], then [what to do]" pattern
- Suggest where it belongs: the memory index (if broadly relevant) or a topic file (if subsystem-specific)
- If approved, add it to the destination and update the Promoted table in the gotcha log. An observation from read text does not promote, even if it recurs, unless the user confirms it (Step 1)

**Then check the promoted patterns against this session, and increment the Occurrences count for any that recurred.** Do this every session.

**Read the Mechanized table too, if the log has one** — same extractor, `Mechanized` for `Promoted`. Report rows still `proposed` after several sessions; increment Occurrences on a `live` row whose shape recurred.

**Read constraint rows for truth, not only for counts** (#183). A row stating current behaviour of a tool, schema or codebase goes false when that behaviour changes; a pattern row states no fact and cannot. Re-check each constraint row not read since what it describes last changed, note `checked YYYY-MM-DD` in its Promoted-to cell, and report a false one. One adopter found 1 of 4 false, five months after an ADR inverted it.

The Promoted table is the running total. When it conflicts with the entries, reconcile to the entries and say so. Date each recurrence in the cell. A promoted pattern that recurs means the promotion did not take — say so in the report.

## Step 3 — Memory index update

Read the memory index (`MEMORY.md` for Claude Code, or the project file for other tools). Update:
- **Current State** — reflect what shipped or changed this session
- **Active work items** — for each active work-item file in `docs/work-items/`, update its Current Status section (the savepoint): mark completed items, update "Last action" and "Next action," note blockers. If a work item completed this session, fill its Outcome section and update the pointer to `[done]` — in the memory index's Current State section, or the project file's "Active work" section where the tool has no auto-memory. If a new multi-session initiative started, create the work-item file from `templates/work-item.md` and add a pointer
- **Key File Paths** — add any important files discovered during work
- **Active Decisions** — add any architectural choices made, with ADR pointers if created
- Remove what is stale, or replace the changed fact in place. A cut of more than a few lines gets Step 0 sub-step 6's survival check and fresh-reader comparison (#114, #256); don't reword the rest

**Don't accrete session narrative onto the project file footer.** Session-level "what happened today" belongs in `memory/project_session_YYYY_MM_DD.md`, with a one-line pointer added to `MEMORY.md`.

## Step 4 — Work-item check

The doc sync checks (Architecture, commands, runbook) are retired (#367). Re-add one only with a catch to point at.

Scan `docs/work-items/` for files with an incomplete Outcome section. For each:
- If the work completed this session, fill the Outcome and suggest updating the pointer to `[done]` — wherever this project keeps them (memory index, or the project file's "Active work" section)
- If the Current Status shows no activity for 14+ days, flag as potentially abandoned — surface to the engineer
- If the file has no corresponding pointer in either list, add one to whichever this project uses (or flag if unclear)

Fix what you can. Flag anything that needs engineer input.

## Step 5 — Verify references

**Always run this.** Spot-check that paths named in the memory index and project file still exist, and flag any that do not. `audit-context` Step 4 is the full check.

## Step 6 — Report

- **Freshness**: Gotcha log headers reconciled against the `**Problem**` count, and the Promoted table read
- **Verification**: State claims checked — N passed, N failed, N unverified, N errored, N manual check needed, N cannot verify, N malformed. Report all seven, even zeros, plus **N commands run of M annotations**, the difference, and the exit status
- **Gotchas**: New entries added, entries resolved or promoted, and **N promoted patterns re-checked, N recurred; N constraint rows, N re-checked, N false**. Report all, even zeros: zero constraint rows looks like a skipped step unless reported (#183). Name any pattern that recurred *after* promotion
- **Memory index**: Updates made
- **Work items**: Outcomes filled, pointers added or updated, items flagged as idle
- **Action needed**: anything needing an engineer decision, including `audit-context` (don't run it) when the memory index's `Last audit:` is missing, `never` or over 30 days old
