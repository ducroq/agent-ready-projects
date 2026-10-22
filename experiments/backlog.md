# Experiment backlog

Pre-committed methods. A section is frozen from the commit that pins it; a changed design is a
new section (EXP-NNN + 1), never an edit. See `README.md`.

## EXP-001: what does grep keep re-finding?

**Hypothesis**: H-032 in the maintainer's hypothesis log.
**Decision it feeds**: whether "write down only what search can't find" is a rule this
framework can state with evidence, and whether a controlled run (phase 2) is worth its spend.
**Spend**: $0 metered. Phase 1 parses existing transcripts; no model calls.

### What was seen before freezing

The transcript schema, the number of transcript files per project directory, and (from a
pre-freeze review, 2026-10-21) counts by tool name and of duplicated lines: about 44k `Bash`
calls against 2 `Grep` and 0 `Glob`; subagent files in `<project>/<session>/subagents/`;
441 message uuids in more than one file; 98 compaction markers; `cwd` varying inside 19 project
directories. No pattern, command text or result was read.

### Population

- Main sessions: `~/.claude/projects/*/*.jsonl`. Subagents: `~/.claude/projects/*/*/subagents/*.jsonl`,
  attributed to the parent `sessionId`. Only files with mtime before the pinning commit.
- Every tool call is deduplicated on `tool_use_id` (resumed and forked sessions copy history).
- A **repo** is the git toplevel of the call's `cwd`, with worktrees mapped to their main repo;
  a `cwd` outside any git repo is dropped. Repos with fewer than 5 sessions are dropped.
- The repo holding over half of all sessions is reported **separately** and left out of the
  pooled figures. Expected pooled population: about 300 main-session files. The headline uses
  main sessions; subagent figures are reported beside it.

### Instrument

A **search event** is a `Bash` call containing `grep`, `rg`, `git grep` or `find`, or a `Grep`/`Glob`
call. Bash commands are split on `&&`, `;`, `||` and `|`; each segment is parsed, after skipping
a leading `cd <dir>`, `git -C <dir>` and `xargs`. One segment that searches is one event.
**Unparsed**: Bash calls that contain one of those words but yield no event. Their share is
reported; above 10% the run is stopped as an instrument failure.

The **key** is the search term plus the path searched, normalized: lowercased, quotes stripped,
flags dropped **together with their values** (for grep/rg: `-A -B -C -m -e -f --glob --type
--max-count`; for find: every predicate except `-name`/`-iname`/`-path`, whose value is the term),
path made relative to the repo root. An event with **no term** (a bare `find .`, a `Glob` with only
a wildcard) is excluded from the key space and counted as excluded.

A **repeat** is an occurrence of a key in a session **after the first session** that used it, in
the same repo. The first occurrence is never a repeat. Repeats inside one session are counted
separately and are not in the headline.

**Cost** of an event: one call, plus the bytes of its tool result.

**Coverage** counts only memory that **existed before the repeat**, so it is computed only where
history is recoverable: the project file (`CLAUDE.md`, `AGENTS.md`) and any `memory/` with its own
git history, read at the last commit before the repeat's session. User-level memory has no
history and is excluded. A key is covered when its term appears there **as a whole token, at least
5 characters long, and not a bare path or glob**. Keys that fail that test are reported as
*uncoverable*, not as uncovered.

### Metrics

- **M1**: repeats as a share of all search events with a term (pooled).
- **M2**: covered repeats as a share of coverable repeats, over the repos with recoverable history
  (their number is reported).
- **M3**: tool-result bytes of repeats as a share of all search-result bytes.
- Per-repo values, with repos anonymized as R1…Rn; the excluded and unparsed counts.

### Instrument check (run first; the real data is not read until it passes)

Hand-written transcripts in the lab directory, in two fixture repos (git repos with a committed
`CLAUDE.md`), with one case each:

1. a planted repeat across sessions over the whole repo, written as `grep -rn "FooBar" .` and later
   `cd . && rg foobar | head`;
2. a repeat of `parse_config` whose term was in `CLAUDE.md` at a commit before its second session;
3. a repeat of `load_cache` whose term was added to `CLAUDE.md` only **after** its second session;
4. a key repeated inside one session only;
5. the same key in both repos, once each;
6. the same session's lines copied into a second file (a resume), with the same `tool_use_id`s;
7. a subagent file under `<session>/subagents/` carrying a repeat;
8. `grep barbaz src` from the repo root, then in a later session `grep barbaz .` from `cwd` `src/`;
9. a repeated short term (`test`) that also appears in `CLAUDE.md`;
10. `grep -A 3 baz` and `grep -A 3 qux` in different sessions (a flag value must not become the
    key), and a bare `find .`.

Expected: main-session repeats **5** (cases 1, 2, 3, 8 and 9), of which **4** coverable and
**1** covered (case 2; case 3 is uncovered) and case 9 **uncoverable**; cases 4–6 add **0**, case 7 appears only in the subagent figure,
case 10 has 0 repeats and 1 excluded event. Any other count is an instrument failure, fixed
before the run.

### Predictions (before looking)

| Metric | Expected range | A result outside it means |
|--------|---------------|---------------------------|
| M1 | 15–40% | below: agents rarely re-search across sessions; above: memory is doing little |
| M2 | 20–50% | above: pointers exist but are not used; below: memory and search cover different ground |
| M3 | 10–30% | above: repeats are the expensive searches, which strengthens the case for memory |

### Decision rule

Checked in order; the first branch that matches decides.

1. **Unparsed above 10%**: instrument failure. No decision; redesign as EXP-002.
2. **M1 below 10%**: re-searching is too rare to matter. Record that, do not claim memory saves
   search, and skip phase 2.
3. **M2 at least 50%**: memory had the answer and the agent searched anyway. Pointer design is
   the problem; open an issue on task-triggered pointers before any phase 2.
4. **Otherwise** (M1 at least 10%, M2 below 50%, or M2 not computable): most repeats are not in
   memory. Phase 2: write entries for the top uncovered repeats in two repos and compare their
   repeat rate over the next 10 sessions against the rest. Its design is a new section, EXP-002.

### Data

Raw extracts: `lab/experiments/2026-10-21-grep-vs-memory/`. The repo gets one artifact,
`artifacts/exp001-grep-vs-memory.json`, with aggregates only.

## EXP-002: EXP-001 re-run with a parser that can read the commands

**Hypothesis**: H-032, as for EXP-001.
**Why**: EXP-001 stopped on decision rule 1 (unparsed 10.65%). Diagnosis, on the unparsed calls
only: about 1,160 merely *mentioned* `grep` or `find` inside quoted text, so the candidate test
over-counted; about 970 searched inside `$( )`, `<( )`, backticks or loops; about 100 ran behind
`bash -c` or `timeout`; 48 failed to tokenize.
**Spend**: $0 metered.

### Not blind, and what was seen

EXP-001's metrics were seen: M1 12.3%, M2 29.7%, M3 11.5%. While fixing the parser only the
unparsed share was measured on real data: 67 of 19,080 candidates (0.35%). **No predictions are
made.** The thresholds in the decision rule were set blind in EXP-001 and are kept unchanged.

### What changes from EXP-001

- **Candidate**: a Bash call whose unquoted shell words include `grep`, `egrep`, `fgrep`, `rg` or
  `find` (or a path ending in one), in the command, in a `$( )`, `<( )`, `>( )` or backtick body,
  or in the argument of `bash -c`. Quoted mentions are not candidates. **Unparsed** is a candidate
  that yields no event, as before.
- Substitution bodies are parsed as commands run from the call's directory.
- `bash -c '<cmd>'` is parsed as `<cmd>`; `timeout` and `watch` with their arguments, and
  `command` after `xargs`, are skipped like other leading words.
- Paths and repo roots are resolved through symlinks before the relative path is taken.

Everything else is EXP-001's, unchanged: population and cutoff (`2026-10-21T16:08:11+02:00`), key,
repeat, cost, coverage, metrics and the decision rule, applied in the same order.

### Instrument check

EXP-001's 10 cases with their expected counts, plus single-event controls that must each yield
their key: `$( )`, `<( )`, backticks, `bash -c`, `timeout`, `xargs command grep`, a `for` loop and
a leading `cd`; and a quoted mention (`sed -n '/grep/p'`) that must not be a candidate (27
candidates expected). Each new rule, when removed, must make the check fail. The symlink rule is
shown by running the check through the `lab` symlink with the fixture's own path fix removed.

**Known gap**: no case seeds a term that matches inside a longer word in memory; whole-token
matching is implemented but not tested.

### Runner and data

`experiments/exp001/parse.py` at the pinning commit. Artifact:
`artifacts/exp002-grep-vs-memory.json`. Raw extracts: `lab/experiments/2026-10-21-grep-vs-memory/`.

## EXP-003: blind confirmation on new transcripts

**Hypothesis**: H-032. **Decision it feeds**: whether EXP-002's result survives a parser that
has not seen the data.
**Method**: EXP-002's runner at EXP-002's pinning commit, unchanged, on transcripts with mtime
**after** `2026-10-21T16:08:11+02:00`. Run on or after 2026-11-18, and only once the pooled
population has at least 100 main sessions; otherwise wait and say so.
**Agreement**: EXP-003 confirms EXP-002 when it lands in the same decision-rule branch. A
different branch means EXP-002's result does not stand.

## EXP-004: does the slim version hold up in one real repo?

**Hypothesis**: a slim setup (one-page project file, gotcha log, a few self-checking claims, a
five-minute end-of-session habit) serves a working repo no worse than the full system.
**Decision it feeds**: whether to offer the slim version as the framework's front door.
**Subject**: R7, the repo EXP-002 anonymized under that label, chosen by the maintainer 2026-10-21; its name is kept in the private hypothesis log.
**Spend**: $0 metered.

### What was seen before freezing

EXP-002's figures for R7: 20 sessions, 2026-09-22 to 2026-10-19;
M1 11.2%, M2 40.5%, M3 9.9%. Its memory surfaces: a 10,400-byte `CLAUDE.md`, a tracked
`docs/hypothesis-log.md`, and user-level memory with no git history (so EXP-002's M2 for it
rests on `CLAUDE.md` alone).

### The switch

- **When**: only after EXP-003's artifact is committed, and no earlier than 2026-11-18. The
  switch commit in R7 is recorded in H-032 and starts the after-window.
- **To**: a `CLAUDE.md` of at most 3,000 bytes with three sections (what this is; rules that are
  not obvious from the code; "when you do X, read Y"), a tracked `docs/gotchas.md`
  (problem → cause → fix, one entry per lesson), at least 3 claims carrying a verify probe, and
  the end-of-session habit (what did we learn that search can't find; what came up twice; what
  is stale).
- **Old material is moved, not deleted**: the old `CLAUDE.md` to `docs/archive/`, the user-level
  memory directory out of the auto-load path. Lessons the engineer wants kept go into
  `docs/gotchas.md` at the switch. Nothing else from the old setup is loaded.

### Windows and control

- **Before**: EXP-002's window for R7 (to the EXP-001 cutoff).
- **After**: from the switch commit until 20 main sessions in R7, or 6 weeks,
  whichever comes first.
- **Control**: every other repo that EXP-002 kept, with their EXP-003 window (cutoff to the EXP-003
  run) as their before and the same calendar after-window as R7.

### Instrument

EXP-002's runner (`experiments/exp001/parse.py` at `b77b45e`), unchanged, run with the window
bounds above. Coverage reads R7's tracked files (`CLAUDE.md`, `docs/gotchas.md`) at the
last commit before each repeat's session, as in EXP-002.

**Guard, logged by the engineer**: at the end of each after-window session in R7, one
line in `docs/gotchas.md` § Slim trial: whether the agent missed something the old notes would have
told it (yes/no, and what).

### Metrics

- **D1**: R7's M1 change (after − before) minus the median M1 change of the control repos.
- **D2**: R7's M2 after, against its 40.5% before.
- **G**: the number of "yes" lines in the guard log.

### Decision rule

Checked in order; the first branch that matches decides.

1. **Fewer than 10 after-window sessions**: no decision; extend or redesign as a new section.
2. **G at least 3**: slim fails. The old setup is restored from `docs/archive/`; record what it
   missed.
3. **D1 above +3 percentage points**: slim fails on search; restore as above.
4. **Otherwise**: slim holds. Keep it in R7 and draft the slim front door for the
   framework. D2 below 40.5% is reported as a sign the new pointers work; it does not decide.

**Known limits**: one repo, one engineer, about 20 sessions. The test can show "clearly worse"
or "no worse", not "slightly better". The engineer knows which setup is live, so G is not blind.

## EXP-005: EXP-004 widened to five adopters that slimmed on their own

**Why**: on 2026-10-22 five repos kept in EXP-002 (R1, R2, R3, R5, R6) independently asked to
slim their setup, each reporting that process commits matched or outnumbered code commits. Every
one of them would have been an EXP-004 control. The maintainer chose to make them subjects.
**Hypothesis**: EXP-004's, tested on these five: a slimmer setup serves a working repo no worse
than the full system.
**Decision it feeds**: EXP-004's, plus whether the framework should offer a lighter profile.
**Spend**: $0 metered.
**Change to EXP-004**: its control set ("every other repo that EXP-002 kept") is read as EXP-002's
kept repos minus R7 and these five. Nothing else in EXP-004 changes, and R7 stays its subject.

### What was seen before freezing

EXP-002's figures (window 2026-09-22 to the cutoff `2026-10-21T16:08:11+02:00`):

| Repo | Sessions | M1 | M2 |
|---|---|---|---|
| R1 | 35 | 13.9% | 29.8% |
| R2 | 32 | 13.3% | 22.7% |
| R3 | 31 | 18.0% | 35.5% |
| R5 | 21 | 11.6% | 31.0% |
| R6 | 20 | 13.1% | 15.7% |

Each session's own measurements of its repo's weight were also seen. Each was asked to record
its switch commit and to move old material to an archive rather than delete it.

### The switch

Each repo slims **to its own plan**, not EXP-004's spec. Each owner decides on their own
schedule, and no date is imposed. The switch commit is whatever that repo records; it is copied
into H-032 and starts that repo's after-window. A repo that never switches within 8 weeks of
this pin is dropped from the subjects. If it never switched, it rejoins EXP-004's controls.

### Windows and control

- **Before**: EXP-002's window for each subject.
- **After**: from the subject's switch commit until 20 main sessions or 6 weeks, whichever comes
  first. Sessions between the cutoff and the switch are not read.
- **Control**: EXP-002's kept repos that are neither R7 nor a subject (R4, R8 to R17), each with
  EXP-002's window as its before, and as its after the same calendar window as the subject it is
  compared with. A control repo that changes its setup inside a window is dropped for that
  comparison, and the drop is reported.

### Instrument

EXP-002's parser (`experiments/exp001/parse.py` at `b77b45e`), unchanged, with coverage as
EXP-002 defined it. The after-window's lower bound is applied by passing only the transcripts
of sessions that started after the switch commit; the parser itself is not edited.

**Guard, read from git, so no one has to log it**: one miss is an after-window commit in a
subject that moves material back out of its archive, or re-adds text the switch removed.
Count each restoring commit once.

### Metrics

- **D1(i)**: subject i's M1 change (after − before) minus the median M1 change of the controls
  over the same windows.
- **G(i)**: the number of restoring commits in subject i's after-window.
- **D2(i)**: subject i's M2 after, against its before. Reported only.

### Decision rule

Checked in order; the first branch that matches decides.

1. Subjects with fewer than 10 after-window sessions are excluded. **If fewer than 3 subjects
   remain**: no decision; redesign as a new section.
2. A subject **fails** if G(i) is at least 3 or D1(i) is above +3 percentage points.
3. **A majority of the remaining subjects fail**: slim fails; do not offer a lighter profile.
4. **At most one fails, and the median D1 is at most +3 points**: slim holds; draft the lighter
   profile and the slim front door, whatever EXP-004 shows.
5. **Otherwise**: mixed. No profile decision; report which subjects failed and how. EXP-004's
   result is read alongside.

**Known limits**: not blind, since every owner knows the switch happened. The subjects selected
themselves, being the repos whose owners felt the weight, so a "holds" result may not transfer
to repos that did not complain. The five slim to different targets, so this tests slimming, not
one spec. One engineer runs all of them. The guard only sees misses someone fixed by restoring
text.
