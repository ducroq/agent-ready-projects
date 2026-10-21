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
