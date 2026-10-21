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
