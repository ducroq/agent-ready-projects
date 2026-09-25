# Curate

<!-- SAVE AS: ~/.claude/skills/curate/SKILL.md (Claude Code, USER-GLOBAL — see docs/GUIDE.md
     "Where a skill lives"; do not copy this file verbatim, its frontmatter is
     inside this comment. Prefer .claude/skills/curate/SKILL.md from this repo.)
     Diff an install against THAT file, never this one: the header differs by construction (#187).
     For other tools, run this as an end-of-session prompt manually.

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

## Before Step 0 — Close the session's arc

Before tending memory, go back to what this session was asked to do. The detour you are standing in is not the arc.

1. **Re-read the opening ask in its own words**, from the transcript or the compaction summary.
2. **Take stock from artifacts, not memory**: `git status --short` and `git log --oneline -6` in every repo the session touched, any document that names its own gap (a work item's success criteria, a pending version), and any external system the session changed (a service, a watcher, a flag left on). Changes you did not make may mean **another session is working here**, or the user's own edits: do not commit or tidy them, and report them as unexplained.
3. **Mark each thread** closed, partial (name the missing part), open (displaced or blocked), or not yours (needs the engineer or someone else). A declined offer is closed.
4. **Land only what the session was asked for (the opening ask or a later explicit request) and not declined.** Recompute any number that goes into a deliverable instead of copying it. Commit only if the project file or the engineer says to commit without asking; otherwise leave it staged and say so. Turn off any stimulus or watcher the session started, and state what is left running. Leave pushes, deploys and anything irreversible to the engineer, with the command ready.
5. Open threads go into the active work item's Current Status in Step 3, or into the memory index's Current State if there is none. If the arc closed something, record the ask and the thread list in this session's file (Step 3), as a dated record, not a status board. The list heads the Step 6 report.

## Step 0 — Freshness check

**Measure the read surface first, and say the number.**

```bash
# -print0/-0 because a single spaced path (`docs/work-items/my slug.md`) is
# word-split into nonexistent paths and its bytes vanish from the total. `cat |
# wc -m` rather than `xargs wc -c | tail -1` for two reasons: xargs BATCHES above
# a few thousand files and `tail -1` then reports one batch's total (measured:
# 6000 files reported 105,600 of 600,000), and `wc -m` counts characters, which
# is what the threshold below is in. Both failures were silent and both read LOW.
find memory docs/work-items -type f -name '*.md' ! -path '*/archive/*' -print0 2>/dev/null \
  | xargs -0 cat | wc -m
```

**Above roughly 300k characters, do not read the corpus.** Work from metadata and the verify runner, and do not improvise a dead-reference check. Curate **the index and the newest topic file only**, and say in the report which files you did not open. **And propose an archive pass**: resolved gotchas, closed hypotheses, old session files and done work items move into an `archive/` folder beside them (`memory/archive/`, `docs/work-items/archive/`), which the measurement above excludes. Propose it; do not move anything in this step.

Check for context rot from *previous* sessions. **Read metadata, not documents**: headers, probe output, `stat`. Fetch a body only when you are going to act on it.

1. **RETIRED — dead references, stale-memory mtime, and ground-truth drift.** Retired in v1.45.0 (dead references are covered by `audit-context` Step 4); do not re-add without a catch.

2. **Gotcha log headers**: Read the gotcha log's **headers plus its Promoted table**, not the log.

   ```
   grep -nE '^#{2,3} ' <log>                 # entries: date, title, status, line number
   # Bounded at the next same-or-shallower heading. `,0` ran to EOF and swallowed any
   # later section: 11 rows read where 7 exist. Level-aware, because entries nest as
   # `###` under `## Promoted` — exiting at ANY heading returns zero rows there.
   awk '/^#+ Promoted/ && !f { f=1; match($(0),/^#+/); n=RLENGTH; next }
        f && /^#+ / { match($(0),/^#+/); if (RLENGTH<=n) exit } f' <log> | grep '^|'
   grep -c '^\*\*Problem\*\*' <log>          # ground truth: entry count, obtained a different way
   ```

   **Match both heading levels, and reconcile the count.** If the header count and the `**Problem**` count disagree by more than the section headings, the extractor is wrong. Ignore headings inside `<!-- -->` (the template's example entry). Read the Promoted table too: resolutions recorded there may have no header marker.

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

   **Zero commands extracted is a defect, never a pass.** Account for the difference in the `ran N of M` line item by item: syntax documentation (code spans, fenced examples) is expected; anything else is a bug. Exit status: **2** means the run itself cannot be trusted — no files given, an operand that is not a readable file, nothing extracted, or nothing produced a verdict because every annotation was manual or unreachable; **1** means a claim failed, errored or was malformed; **0** means everything reachable checked out; **127** means the runner script itself was not found (wrong `$CLONE` or failed fetch), not a claim result. Read the exit status, and count the rows you received against `ran N of M` — a capture can lose rows.

   **Dispositions** — first match wins:

   | Result | Disposition | What it means |
   |--------|-------------|---------------|
   | Command begins `manual` (then a space, a colon, or nothing) | **MANUAL CHECK NEEDED** | Nothing is run. Surface the noted reason to the engineer. `manual-check.sh` is a command, not a note. |
   | The annotation cannot be read as one command | **MALFORMED** | No closing `-->` on the line; a second `<!-- verify:` before the first closes; an opener inside a code span whose `-->` is outside it; an empty command; or, reported against the file, a fence that never closes. |
   | First non-blank line of **stdout** begins `CANNOT VERIFY` | **CANNOT VERIFY** | The check could not reach its target. Neither pass nor failure; the prefix wins regardless of exit status. Add a colon and a reason. |
   | Timed out | **ERROR** | Default 30s, `VERIFY_TIMEOUT` to change it, only where `timeout` is on `PATH`. Often too low. |
   | Exit 127 | **ERROR** | Command not found; the verify command itself is stale. |
   | No output on stdout | **ERROR** | Silence proves nothing, *whatever the exit status*: `exit 3` in silence is ERROR. Fix the command. |
   | Exit 0 | **PASS** | |
   | Any other non-zero | **FAIL** | The claimed state is no longer true. Flag the entry for correction or removal. |

   Deprecated: a first line exactly `FAIL` with exit 0 is scored FAIL. Rewrite such a command.

   **Blind spot:** fenced blocks are skipped, but an annotation in an unfenced four-space-indented block or a blockquote **will run**. Write examples in fenced blocks. UNVERIFIED is your judgement, not a runner disposition.

   **A negative existence claim — or a count — is a state claim** ("nothing references the old path", "4 issues open"). Give each one a probe that fails loudly if the thing turns out to exist — **and guard the target first**, because `grep -rq` on a path that no longer exists returns "not found" and certifies the claim: `if [ ! -d /abs/path/other-repo ]; then echo "CANNOT VERIFY: repo not at that path"; elif grep -rq 'pattern' /abs/path/other-repo; then echo "CLAIM REFUTED: it exists"; exit 1; else echo "still absent"; fi`. **An instruction not to re-derive a claim is a reason to probe it, not a licence to skip it.**

   **Writing a verify command.** Follow the rules below, then **run it once, at the moment you write it**.

   - **Avoid `--`, and never let `-->` appear.** `-->` ends the comment; bare `--` breaks naive extractors. In order of preference: **check the artifact instead of asking the tool** (`test -L ~/.config/systemd/user/UNIT` rather than `systemctl --user is-enabled`); **set an environment variable instead of passing a flag** (`SYSTEMD_PAGER=cat systemctl list-timers`); **use the short flag**.
   - **One line, opened and closed on that line.** Too long? Put it in a script the annotation calls.
   - **No unescaped `|` if the claim lives in a table cell — and no escaped `\|` if it does not.** The runner un-escapes `\|` only in table rows.
   - **A probe needing a literal `|` builds it: `b=$(printf '\174')`, then `"^$b 2026-08-25 $b"`.** BRE or `-F` only: under `-E` it is alternation.
   - **Guard anything host-dependent** so an unreachable target yields CANNOT VERIFY. Write the guard as an explicit `if`, not as `guard && check || echo ...`:

     ```
     if ping -c1 -W1 hostname >/dev/null 2>&1; then <real check>; else echo "CANNOT VERIFY: host unreachable"; fi
     ```

     `A && B || C` turns a real failure into CANNOT VERIFY. **Bound the guarded check too** — `curl -m 5`, `ssh -o ConnectTimeout=5`.
   - **Print something on success — evidence by preference, `PASS` at minimum — and fail with a non-zero exit, not with a word.** Two idioms to avoid:

     ```
     git rev-parse v1.2.3 >/dev/null 2>&1 || echo NOTAG          # silent when it passes: proves nothing
     git rev-parse v1.2.3 >/dev/null 2>&1 && echo OK || echo NOTAG   # speaks, but "NOTAG" exits 0 — scored PASS
     ```

     The second is a false PASS: exit status decides, not the word printed. Print the value you checked.
   - **Never hardcode the version a probe corroborates — derive it from the stamp.** Then bumping the stamp re-arms the probe.

     ```bash
     # Three outcomes: 0 verified, 1 drift, 2 could not decide. ⚠️ UNDECIDED IS
     # NOT A PASS — an earlier draft of this block printed "CANNOT VERIFY: <skill>
     # is not installed" and then "byte-identical", exit 0, because the skip left
     # the counter alone. That is the false PASS with the evidence of its own
     # failure printed beside it, forbidden eight lines above, inside the sub-step
     # that forbids it. The success line is now gated on a COUNT of what was
     # actually compared, not on the absence of a difference.
     stampcheck() {
       R=$(git rev-parse --show-toplevel 2>/dev/null) ||
         { echo "CANNOT VERIFY: not in a git repo"; return 2; }
       [ -n "${FRAMEWORK:-}" ] && [ -d "$FRAMEWORK/.git" ] ||
         { echo "CANNOT VERIFY: FRAMEWORK is unset or is not a git clone"; return 2; }
       # ⚠️ Five of the six stamp shapes `update-drift` Step 0 documents, not one.
       # A first draft keyed on `framework: <name> vX.Y.Z` alone and returned
       # CANNOT VERIFY in THIS repo, whose own stamp is the `- **<name>** (this
       # repo):` shape — a matcher keyed to one shape reporting an unstamped
       # project is the exact failure that step warns about. The sixth shape,
       # bare prose `Framework version X.Y.Z`, carries no repo name and stays
       # undecidable on purpose.
       P=$(grep -oE "agent-ready-projects[^0-9]{0,40}v?[0-9]+\.[0-9]+\.[0-9]+" \
             "$R/CLAUDE.md" 2>/dev/null | head -1 |
           grep -oE "v?[0-9]+\.[0-9]+\.[0-9]+$" | sed "s/^v*/v/")
       [ -n "$P" ] || { echo "CANNOT VERIFY: no framework stamp in CLAUDE.md"; return 2; }
       # ⚠️ DERIVE the list at the stamped tag, never restate it: a hardcoded
       # one missed review-changes for four releases (#200). `${P}`, not `$P`,
       # before a colon — zsh reads `$P:s` as a modifier.
       git -C "$FRAMEWORK" rev-parse -q --verify "${P}^{commit}" >/dev/null ||
         { echo "CANNOT VERIFY: $P is not in the framework clone — fetch tags"; return 2; }
       t=$(git -C "$FRAMEWORK" show "${P}:scripts/install-global-skills.sh" 2>/dev/null) ||
         { echo "CANNOT VERIFY: no installer at $P (it predates v1.15.0, or moved)"; return 2; }
       want=$(printf '%s\n' "$t" | sed -n 's/^GLOBAL_SKILLS="\([^"]*\)".*/\1/p')
       k=$(echo $want | wc -w | tr -d ' ')
       c=$(printf '%s\n' "$t" | grep -o 'GLOBAL_SKILLS+\{0,1\}=' | wc -l | tr -d ' ')
       [ "$k" -gt 0 ] && [ "$c" = 1 ] ||
         { echo "CANNOT VERIFY: $P's installer sets GLOBAL_SKILLS $c times, not once"; return 2; }
       n=0; d=0
       for s in $(echo $want); do   # $(…) splits in zsh too; a bare $want does not
         i="$HOME/.claude/skills/$s/SKILL.md"
         [ -f "$i" ] || { echo "CANNOT VERIFY: $s is not installed"; continue; }
         # ⚠️ SPLIT the pipeline. Piped, a `git show` that fails — the normal
         # state right after an upstream release, stamp bumped and clone not
         # fetched — is swallowed and `diff` supplies the verdict, so the
         # re-armed probe accuses every clean install of drifting.
         t=$(git -C "$FRAMEWORK" show "${P}:.claude/skills/$s/SKILL.md" 2>/dev/null) ||
           { echo "CANNOT VERIFY: $s is not in $P"; continue; }
         printf '%s\n' "$t" | diff -q - "$i" >/dev/null ||
           { echo "DRIFT: $s differs from $P"; d=1; }
         n=$((n + 1))
       done
       [ "$d" = 0 ] || return 1
       [ "$n" = "$k" ] || { echo "CANNOT VERIFY: compared $n of $k skills"; return 2; }
       echo "$k global skills byte-identical to $P: $want"
     }
     stampcheck; echo "  exit=$?"
     ```

     **Compare against the REFERENCE INSTALL (`.claude/skills/<name>/SKILL.md`), never `templates/<name>.md`**, whose header differs by construction. **Preconditions**: a framework clone at `$FRAMEWORK`, skills installed globally.
   - **Assume nothing about the working directory.** Use `git -C /path/to/repo …` and absolute paths.


4. **Index self-consistency**: Check whether two index entries assert opposite things.

   - **Start with the cheap cluster: entries citing the same identifier.** Against the index (`memory/MEMORY.md` for Claude Code, the project file for a tool without auto-memory):

     ```
     idx=/abs/path/to/index.md
     [ -f "$idx" ] || echo "NO INDEX AT THAT PATH — this check examined nothing"
     grep -onE '[A-Za-z0-9_.-]*#[0-9]+' "$idx" | sort -u | cut -d: -f2- | sort | uniq -d
     ```

     Read the surviving entries *together*. `adopterrepo#76` and a local `#76` are different trackers. Discard hex colours.
   - For ids like `ADR-023` or `PROJ-45`, change the pattern (`[A-Za-z]+-[0-9]+`) and check what it matches.
   - The pairwise entity pass was retired in v1.45.0; do not re-add it without a pair to point at.
   - **An entry that names and dates the claim it supersedes is a correction, not a contradiction.** A contradiction is two entries asserting without reference to each other.
   - **Report the pair verbatim; do not pick a winner from the text.** Probe whichever claim can be probed; otherwise surface both to the engineer.
   - If the index exceeds ~200 lines or the sub-step 6 budget, report that and run the identifier pass alone.

5. **Hypothesis log surface**: If a hypothesis log exists, scan its `## Open` section. **Check both `memory/hypothesis-log.md` and `docs/hypothesis-log.md`**. For each entry:
   - **Past `Review by:`**: Flag as **DUE FOR REVIEW**. Surface its Position and Method so the engineer can resolve or extend it.
   - **`Revisit trigger:` fired**: If its evidence threshold is now met, flag as **TRIGGERED**. Surface only; do not resolve.
   - **Stale (no movement, no trigger)**: Count open entries. If more than ~10, flag as memory-cluttering — promote to ADRs or mark `dormant` / closed.

6. **Auto-loaded size budget — the whole set, not the project file alone.** Sum **every file your tool loads without being asked** (for Claude Code, the project file *and* the user-level memory index), and compare the total against the budget. Claude Code warns at 40k chars; the soft target is under 35k. **List the set before measuring**, and name any file not counted. Budget the index in characters, not lines.

   **Flag a project file over ~15k characters on its own**, even when the set is under budget: a template-sized one is ~6k, and past 15k it is carrying narrative (one adopter's reached 35k).

   If the set is approaching or over budget:
   - **First, check for formatter table padding.** If a markdown formatter (prettier, dprint, markdownlint) pads tables, measure the de-padded size (cells stripped to `| value |`) before proposing any cut.
   - If padding is material, de-pad the file **and** exempt it from whatever re-pads it (editor format-on-save, pre-commit hook, CI) — confirm which one actually touches it.
   - Verify the exemption from the cwd the formatter runs in; Prettier resolves its ignore file from the cwd.
   - Then **session-narrative footers** (`_Last updated: ..._` / `_Earlier ..._` blocks), in any auto-loaded file: they duplicate `memory/project_session_*.md`. An index row is a pointer, not a re-summary.
   - Keep at most **one** footer block (the most recent), and only if the index can't carry it.
   - Don't trim structural sections (Hard Constraints, Before You Start, Architecture, Key Paths). "Active work" is not protected: trim it to items in progress.
   - If that is not enough, surface to the engineer.

Report findings before proceeding. Don't fix anything in this step — just surface what's stale so the engineer can decide.

## Step 1 — Gotcha log review

Read the gotcha log's **headers** (the sub-step 2 grep). For each existing entry:
- If the root cause was fixed during this session, mark it `[RESOLVED]` **in the header**: `### Title (2026-08-12) [RESOLVED]`. Move an old body-only status up when you touch it.
- If the same issue came up again, note the recurrence **in the header as well as the body** — `### Title (2026-08-12) [x3]`.

   Recurrence is a match on *mechanism*, which lives in the body: grep for a distinguishing term, and when a new entry feels familiar, read the matches.

Then check: did anything go wrong or surprise you during this session? For each one, append a new entry:

```
### [Short description] (YYYY-MM-DD)
**Problem**: What went wrong or was confusing.
**Root cause**: Why it happened.
**Fix**: What solved it.
```

**Write the lesson and the action, not the narrative.** Above ~3,000 characters it belongs in a topic file or an ADR.

## Step 2 — Pattern detection and promotion

Scan the gotcha log's headers and its Promoted table for entries that have recurred 2-3 times. For each:
- Propose promoting it as an "if [situation], then [what to do]" pattern
- Suggest where it belongs: the memory index (if broadly relevant) or a topic file (if subsystem-specific)
- If approved, add it to the destination and update the Promoted table in the gotcha log

**Then check the promoted patterns against this session, and increment the Occurrences count for any that recurred.** Do this every session.

**Read the Mechanized table too, if the log has one** — same extractor, `Mechanized` for `Promoted`. Report rows still `proposed` after several sessions; increment Occurrences on a `live` row whose shape recurred.

The Promoted table is the running total. When it conflicts with the entries, reconcile to the entries and say so. Date each recurrence in the cell. A promoted pattern that recurs means the promotion did not take — say so in the report.

## Step 3 — Memory index update

Read the memory index (`MEMORY.md` for Claude Code, or the project file for other tools). Update:
- **Current State** — reflect what shipped or changed this session
- **Active work items** — for each active work-item file in `docs/work-items/`, update its Current Status section (the savepoint): mark completed items, update "Last action" and "Next action," note blockers. If a work item completed this session, fill its Outcome section and update the pointer to `[done]` — in the memory index's Current State section, or the project file's "Active work" section where the tool has no auto-memory. If a new multi-session initiative started, create the work-item file from `templates/work-item.md` and add a pointer
- **Key File Paths** — add any important files discovered during work
- **Active Decisions** — add any architectural choices made, with ADR pointers if created
- Remove or correct anything that is now stale

**Don't accrete session narrative onto the project file footer.** Session-level "what happened today" belongs in `memory/project_session_YYYY_MM_DD.md`, with a one-line pointer added to `MEMORY.md`.

## Step 4 — Doc sync check

Check whether key docs reflect the current repo state.

1. **Project file Architecture section**: Compare listed files/directories against actual repo contents. Flag new files not listed, or listed files that no longer exist.
2. **Project file Key Commands / How to Work Here**: Verify commands still match actual CLI flags and defaults. Flag any mismatches.
3. **Runbook** (if it exists): Check that operational details (environment setup, deployment steps, common problems) match reality. Flag anything that looks stale.
4. **Work-item check**: Scan `docs/work-items/` for files with an incomplete Outcome section. For each:
   - If the work completed this session, fill the Outcome and suggest updating the pointer to `[done]` — wherever this project keeps them (memory index, or the project file's "Active work" section)
   - If the Current Status shows no activity for 14+ days, flag as potentially abandoned — surface to the engineer
   - If the file has no corresponding pointer in either list, add one to whichever this project uses (or flag if unclear)

Fix what you can. Flag anything that needs engineer input.

## Step 5 — Verify references

**Always run this.** Spot-check that paths named in the memory index and project file still exist, and flag any that do not. `audit-context` Step 4 is the full check.

## Step 6 — Report

- **Arc**: the opening ask, then each thread closed / partial / open / not yours
- **Freshness**: Gotcha log headers reconciled against the `**Problem**` count, and the Promoted table read
- **Verification**: State claims checked — N passed, N failed, N unverified, N errored, N manual check needed, N cannot verify, N malformed. Report all seven, even zeros, plus **N commands run of M annotations**, the difference, and the exit status
- **Index self-consistency**: N identifiers cited by more than one *entry*, and N contradicting pairs among them. Report both; say whether zero meant nothing to compare. Quote any pair verbatim
- **Gotchas**: New entries added, entries resolved or promoted, and **N promoted patterns re-checked, N recurred**. Report both, even zeros. Name any pattern that recurred *after* promotion
- **Memory index**: Updates made
- **Doc sync**: Project file, runbook, backlog updates made or flagged
- **Action needed**: anything needing an engineer decision
