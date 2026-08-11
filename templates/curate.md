# Curate

<!-- SAVE AS: ~/.claude/skills/curate/SKILL.md (Claude Code, USER-GLOBAL — see docs/GUIDE.md
     "Where a skill lives"; do not copy this file verbatim, its frontmatter is
     inside this comment. Prefer .claude/skills/curate/SKILL.md from this repo.)
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

## Step 0 — Freshness check

Check for context rot from *previous* sessions. This catches what the session-focused steps below miss.

1. **Dead references**: Read the memory index and project file. For every file path mentioned, verify it still exists. List any broken paths.
2. **Stale memory**: Check modification dates of memory files. Flag any not modified in 30+ days — they may be outdated. Read dates from the **filesystem**, e.g. `ls -l --time-style=+%Y-%m-%d memory/` or `stat -c '%y %n' memory/*.md`. **Look for the files before reading their dates, and say which set you read.** Where there is no `memory/` there is no Layer 3, and this project's equivalents are the ones the naming map gives for a tool without auto-memory — `docs/gotcha-log.md`, `docs/hypothesis-log.md`, `docs/work-items/` — plus the project file itself. Both example commands fail the same silent way on a directory that is not there: `stat` and `ls` each write to stderr and print nothing to stdout, which reads exactly like "nothing is stale".

   Do not use `git log -1 --format=%ci -- <file>` as the primary check. When the memory directory is gitignored — the recommended setup, and this framework's own — `git log` returns **empty with exit 0** for every file, so the check reports nothing stale while having examined nothing. Empty `git log` output here means "the check did not run", not "no files are stale".

   If your memory files *are* tracked in git, `git log -1 --format=%ci -- <file>` is the better signal, since it reflects real edits rather than incidental touches (checkouts, formatters, syncs). Verify which case you're in first — and test that the directory exists before asking git about it, or a project with no `memory/` at all takes the "tracked" branch and is told `git log` is fine: `if [ ! -d memory ]; then echo "no memory/ — read the docs/ equivalents and the project file"; elif ! git rev-parse --git-dir >/dev/null 2>&1; then echo "not a git repo — use filesystem mtime"; elif git check-ignore -q memory/; then echo "gitignored — use filesystem mtime"; else echo "tracked — git log is fine"; fi`.
3. **Lingering gotchas**: Read the gotcha log. Flag any unresolved entries older than 14 days — they're either fixed (mark `[RESOLVED]`) or stuck (surface to the user).
4. **Ground truth drift**: If the project file has a "Ground Truth Designations" table, verify each listed file exists and has been modified more recently than the artifacts that defer to it. Flag any where a downstream artifact is newer than its source of truth.
5. **Unverified state claims**: Scan memory files for state claims ("shipped," "deployed," "live," "running," "working in production"). Claims carrying a `<!-- verify: ... -->` annotation are run by the runner below. A claim with no annotation is **UNVERIFIED** — those decay immediately after the session that wrote them, so suggest adding an annotation or requalifying the claim as a session observation.

   **Use this runner. Do not write one on the spot.** Every hand-written implementation observed so far reported *nothing wrong having checked nothing* — a silent, self-certifying pass, reached by six independent routes: a command containing `exit` ends the loop mid-iteration; an `ssh` (or any other stdin-reading command) swallows the rest of the command list; prose that merely *mentions* the syntax is executed as shell; `[^>]*` extraction truncates at the first `>`, mangling every command with a redirect; a `\|`-escaped command from a table cell runs with its pipes as literal `echo` arguments, so its fallback branch is dead code; and a command that succeeds in silence is indistinguishable from one that never ran. Each of the six is sufficient on its own. Save the block to a scratch file and give it **absolute paths** — `bash /tmp/verify-runner.sh /repo/memory/*.md /repo/docs/hypothesis-log.md`.

   ````bash
   #!/usr/bin/env bash
   # curate Step 0 sub-step 5 — verify runner (canonical). Do not re-derive it; see issue #34.
   # Usage: bash verify-runner.sh <file>...        VERIFY_TIMEOUT=<seconds> caps each command.
   # Exit:  0 something was verified and nothing failed · 1 a claim failed, errored or was
   #        malformed · 2 the run cannot be trusted — no files, an operand that is not a
   #        readable file, nothing extracted, or nothing that produced a verdict.
   set -u

   [ "$#" -gt 0 ] || { echo "no files given — nothing was checked" >&2; exit 2; }
   for f in "$@"; do [ -f "$f" ] && [ -r "$f" ] || { echo "UNREADABLE $f — the run would be short by a whole file" >&2; exit 2; }; done

   extract() {
     awk '
       function isdelim(s,   x) { x = s; gsub(/\\\|/, "", x); gsub(/[ \t]/, "", x)
                                  return (x ~ /-/ && x ~ /^[|:-]+$/) }
       function haspipe(s,   x) { x = s; gsub(/\\\|/, "", x); return index(x, "|") > 0 }
       function maskspans(m, orig,   res, pos, o, L, nb, p2, R, e, i, pad, span) {
         res = m                                    # CommonMark: a run of N backticks opens a
         pos = 1                                    # span that the next run of exactly N closes
         while (1) {
           o = substr(res, pos); if (!match(o, /`+/)) break
           L = pos + RSTART - 1; nb = RLENGTH; p2 = L + nb; e = 0
           while (1) {
             o = substr(res, p2); if (!match(o, /`+/)) break
             R = p2 + RSTART - 1
             if (RLENGTH == nb) { e = R + nb - 1; break }
             p2 = R + RLENGTH
           }
           if (!e) { pos = L + nb; continue }       # an unpaired run masks nothing
           span = substr(res, L, e - L + 1)
           if (tolower(span) ~ /<!--[ \t]*verify:/ && index(span, "-->") == 0)
             print "B\034" FILENAME "\034" substr(orig, L, 60)   # opener inside, closer outside
           pad = ""; for (i = L; i <= e; i++) pad = pad " "
           res = substr(res, 1, L - 1) pad substr(res, e + 1); pos = e + 1
         }
         return res
       }
       FNR == 1 {
         if (fch != "") print "U\034" curfile "\034" "a fence opened at line " openline " and never closed"
         fch = ""; intbl = 0; prev = ""; curfile = FILENAME    # no state may cross a file
       }
       {
         bare = $0; sub(/^[ \t]*/, "", bare)                   # a fence may be indented
         if (bare ~ /^```/ || bare ~ /^~~~/) {                 # and opens on ``` or ~~~
           c = substr(bare, 1, 1); k = 0
           while (substr(bare, k + 1, 1) == c) k++
           if (fch == "") { fch = c; flen = k; openline = FNR }
           else if (c == fch && k >= flen) fch = ""            # closing only on the same
           intbl = 0; prev = ""; next                          # character, at least as long
         }
         if (fch != "") next                                   # inside a fence: documentation
         if (isdelim($0) && index($0, "|") && prev != "") { intbl = 1; prev = $0; next }
         if (intbl && !haspipe($0)) intbl = 0                  # a table ends at its last row
         line = $0
         mask = maskspans(tolower(line), line)                 # match case-insensitively, at
         while (match(mask, /<!--[ \t]*verify:[ \t]*/)) {      # preserved offsets
           p = RSTART + RLENGTH
           rest = substr(line, p)                              # take the command from the
           e = index(rest, "-->")                              # ORIGINAL line
           if (e == 0) { print "M\034" FILENAME "\034" substr(rest, 1, 60); break }
           cmd = substr(rest, 1, e - 1); sub(/[ \t]+$/, "", cmd)
           if (tolower(cmd) ~ /<!--[ \t]*verify:/) { print "D\034" FILENAME "\034" substr(cmd, 1, 60); break }
           if (intbl) gsub(/\\\|/, "|", cmd)                   # a table cell escapes its pipes
           if (cmd == "") print "E\034" FILENAME "\034" substr($0, 1, 60)
           else print "C\034" FILENAME "\034" cmd
           mask = substr(mask, p + e + 2); line = substr(line, p + e + 2)
         }
         prev = $0
       }
       END { if (fch != "") print "U\034" curfile "\034" "a fence opened at line " openline " and never closed" }
     ' "$@"
   }

   case "${VERIFY_TIMEOUT:-30}" in *[!0-9]*|'') echo "VERIFY_TIMEOUT must be whole seconds" >&2; exit 2 ;; esac
   TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT
   TO=""; command -v timeout >/dev/null 2>&1 && TO="timeout ${VERIFY_TIMEOUT:-30}"
   pass=0 fail=0 err=0 manual=0 cannot=0 bad=0 seen=0 n=0

   while IFS=$'\034' read -r kind file cmd; do
     if [ "$kind" != C ]; then
       bad=$((bad + 1))
       case "$kind" in
         M) why="never closed" ;; D) why="opens a second verify before closing the first" ;;
         B) why="inside a code span, but its --> is outside it" ;;
         U) why="every annotation after it was skipped" ;; *) why="empty" ;;
       esac
       printf 'MALFORMED      %s :: %s (%s)\n' "$file" "$cmd" "$why"; continue
     fi
     seen=$((seen + 1))
     case "$(printf '%s' "$cmd" | tr 'A-Z' 'a-z')" in
       manual|manual[[:space:]:]*)                          # `manual-check.sh` is a command
         manual=$((manual + 1)); printf 'MANUAL         %s :: %s\n' "$file" "$cmd"; continue ;;
     esac
     n=$((n + 1))
     OUTF="$TMPD/$n.out"; ERRF="$TMPD/$n.err"               # never reused: a backgrounded
     ${TO:-} bash -c "$cmd" </dev/null >"$OUTF" 2>"$ERRF"; rc=$?   # child still holds the old
     head1=$(awk 'NF { sub(/^[ \t]+/, ""); print; exit }' "$OUTF") # one and writes into it
     note=""
     case "$head1" in
       "CANNOT VERIFY"|"CANNOT VERIFY"[!A-Za-z0-9]*)        # the colon is conventional, not
         cannot=$((cannot + 1)); printf 'CANNOT-VERIFY  %s :: %s\n                 %s\n' "$file" "$cmd" "$head1"; continue ;;
       FAIL)                                                # this framework taught `|| echo FAIL`
         [ "$rc" -ne 0 ] || { rc=1; note="  ! legacy verdict word — rewrite it to exit non-zero"; } ;;
       FAIL*)                                               # cannot be told from evidence, so
         [ "$rc" -ne 0 ] || note="  ! output begins FAIL yet it exited 0 — if that is a verdict, rewrite it" ;;
     esac
     if   [ -n "$TO" ] && [ "$rc" -eq 124 ]; then d=ERROR; err=$((err + 1)); head1="(timed out)"
     elif [ "$rc" -eq 127 ];  then d=ERROR; err=$((err + 1)); [ -n "$head1" ] || head1="(command not found)"
     elif [ -z "$head1" ];    then d=ERROR; err=$((err + 1)); head1="(no output — it proved nothing)"
     elif [ "$rc" -eq 0 ];    then d=PASS;  pass=$((pass + 1))
     else                          d=FAIL;  fail=$((fail + 1))
     fi
     printf '%-14s %s :: %s\n                 %s%s\n' "$d" "$file" "$cmd" "$head1" "$note"
     [ "$d" = PASS ] || [ ! -s "$ERRF" ] || printf '                 ! %s\n' "$(awk 'NF { print; exit }' "$ERRF")"
   done < <(extract "$@")

   annotations=$(grep -ahoiE '<!--[[:space:]]*verify:' "$@" | wc -l)
   printf 'ran %d of %d annotations — %d pass, %d fail, %d error, %d cannot-verify; %d manual, %d malformed\n' \
     "$n" "$annotations" "$pass" "$fail" "$err" "$cannot" "$manual" "$bad"
   [ "$seen" -gt 0 ] || { [ "$bad" -eq 0 ] && echo 'ZERO COMMANDS EXTRACTED — a defect in the runner or the annotations, never a pass.' \
                                           || echo 'NO USABLE ANNOTATIONS — every one found was malformed.'; exit 2; }
   [ $((pass + fail + err)) -gt 0 ] || { echo 'NOTHING PRODUCED A VERDICT — every annotation was manual or unreachable.'; exit 2; }
   [ $((fail + err + bad)) -eq 0 ] || exit 1
   ````

   **Zero commands extracted is a defect, never a pass** — and so is a count the reader cannot account for. The runner's last line reconciles commands run against `<!--`-shaped annotations in the same files; account for the difference item by item. Documentation of the syntax — code spans, fenced examples — is the expected explanation; an annotation the extractor could not see is a bug in the annotation or in the runner. This is the same trap sub-step 2 warns about for `git log`, one step over: the step reports nothing wrong *precisely when* it has examined nothing. The exit status says which case you are in: **2** means the run itself cannot be trusted — no files given, an operand that is not a readable file, nothing extracted, or nothing that produced a verdict because every annotation was manual or unreachable — **1** means a claim failed, errored or was malformed, and **0** means everything reachable checked out. Do not report a run you did not read the exit status of.

   **Dispositions** — first match wins, and the order matters because one command can satisfy several:

   | Result | Disposition | What it means |
   |--------|-------------|---------------|
   | Command begins `manual` (then a space, a colon, or nothing) | **MANUAL CHECK NEEDED** | Nothing is run. Surface the noted reason to the engineer. `manual-check.sh` is a command, not a note. |
   | The annotation cannot be read as one command | **MALFORMED** | Five shapes: no closing `-->` on the line; a second `<!-- verify:` before the first one closes; an opener that sits inside a code span while its `-->` sits outside it, so markdown and the author disagree about whether it is documentation; an empty command; and — reported against the file rather than a line — a fence that opens and never closes, which silently swallows every annotation after it. Loud rather than skipped: a dropped annotation is a claim nobody checked. |
   | First non-blank line of **stdout** begins `CANNOT VERIFY` | **CANNOT VERIFY** | The check could not reach what it needed — a powered-off machine, an absent credential. Neither a pass nor a failure, and must not be reported as either. **The prefix wins regardless of exit status**, so a guard is free to exit 2. A colon and a reason are conventional and strongly preferred. stderr is captured separately and deliberately: an `ssh` guard's `Warning: Permanently added …` would otherwise arrive first and mask the prefix. |
   | Timed out | **ERROR** | Default 30s, `VERIFY_TIMEOUT` to change it, and only where `timeout` is on `PATH` — without it a hanging command hangs the step. |
   | Exit 127 | **ERROR** | Command not found; the verify command itself is stale. |
   | No output on stdout | **ERROR** | A command that prints nothing has proved nothing, *whatever its exit status*. Fix the command — see the writing rules — rather than relaxing the rule. Note this outranks the two rows below: `exit 3` in silence is ERROR, not FAIL. |
   | Exit 0 | **PASS** | |
   | Any other non-zero | **FAIL** | The claimed state is no longer true. Flag the entry for correction or removal. |

   **One deprecated exception, and it is the only place a word in the output changes anything.** A command whose entire first line is `FAIL` and which exits 0 is scored FAIL, not PASS, and the row says why. This framework taught `… && echo PASS || echo FAIL` until v1.21.0, and that idiom exits 0 on its failure branch, so without this every such command in every adopter's memory files would read as a pass on upgrade. It matches the bare word only — evidence like `FAIL: 0  WARN: 0  OK: 12` is evidence. Rewrite the command; do not rely on it.

   **Two blind spots, so a clean run is not read as more than it is.** Fenced blocks are skipped — including indented ones, `~~~` ones, and a `` ``` `` block nested inside a four-backtick one — but an annotation inside a *four-space-indented code block* (one with no fence at all) or inside a blockquote is indistinguishable from a live one and **will run**. Write examples in fenced blocks. And UNVERIFIED is not a disposition the runner can produce: it is your judgement about claims with no annotation at all, so "zero is a defect" does not apply to that one of the numbers in Step 6.

   **A negative existence claim — or a count — is a state claim, and it is the shape that escapes this step.** "There is no reader-facing count", "that endpoint doesn't exist", "nothing references the old path", "4 issues open" — these read as settled fact rather than as claims about a world that moves, so nobody attaches a probe to them and the decay rule never reaches them. They are also the claims most likely to be about *another* repository, where you cannot see the change that falsified them. Give each one a probe that fails loudly if the thing turns out to exist — **and guard the target first**, because `grep -rq` on a path that no longer exists returns "not found" and certifies the claim: `if [ ! -d /abs/path/other-repo ]; then echo "CANNOT VERIFY: repo not at that path"; elif grep -rq 'pattern' /abs/path/other-repo; then echo "CLAIM REFUTED: it exists"; exit 1; else echo "still absent"; fi`. A sibling repo being moved or renamed is the commonest way one of these claims goes unverifiable, and it is exactly the case the unguarded form cannot see. **An instruction not to re-derive a claim is a reason to probe it, not a licence to skip it** — "verified in ../other-repo, don't re-check" is how a false claim survives five days and several curate runs.

   **Writing a verify command — it has to survive two syntaxes it is not written in.** The body sits inside an HTML comment, inside markdown, and shell is hostile to both. Check each command against the six rules below, then **run it once, at the moment you write it**. A verify command that fails on day one is worthless; one that cannot be *extracted* is worse than none, because it reports nothing while looking like it ran.

   - **Avoid `--`, and never let `-->` appear.** The hard rule is narrow: an HTML comment ends at the first `-->`, so a command containing that sequence truncates the comment and spills the remainder onto the page. Bare `--` is conforming HTML and renders fine — but it breaks two things that matter here. XML and XHTML pipelines reject it outright, and, the failure actually observed, a naive extraction regex over comment bodies stops early and returns **zero** commands, so the step examines nothing and completes cleanly. Long flags are the commonest construct in shell, so this is near-certain rather than an edge case: `--user`, `--no-pager`, `--json`, `--quiet`. In order of preference: **check the artifact instead of asking the tool** (`test -L ~/.config/systemd/user/UNIT` rather than `systemctl --user is-enabled`); **set an environment variable instead of passing a flag** (`SYSTEMD_PAGER=cat systemctl list-timers`); **use the short flag**.
   - **One line, opened and closed on that line.** The extractor requires the `-->` on the same line as the `<!-- verify:`, because a multi-line annotation is indistinguishable from an unterminated one, and both are reported MALFORMED rather than skipped. If a command is too long for a line, that is a signal to put it in a script the annotation calls.
   - **No unescaped `|` if the claim lives in a table cell — and no escaped `\|` if it does not.** GFM splits a row into cells before it parses inline content, so the idiomatic `&& echo PASS || echo FAIL` adds two cells; GFM then discards everything past the table's width, taking the rest of the row with it. Escape as `\|` inside a table, or keep verified claims out of tables. **Outside a table the escape is not neutral**, which is why the runner un-escapes only table rows: in an ordinary bullet, `\|` is the escape *shell and awk* use for a literal pipe, and rewriting it silently changes the command. One adopter's `awk -F'|' '/^\| P[0-9]+ \|/…'` row-count check — correct, and passing — became `/^| P[0-9]+ |/`, an alternation with an empty operand, and reported FAIL on a healthy claim.
   - **Guard anything host-dependent** so an unreachable target yields CANNOT VERIFY rather than a false PASS or a misleading FAIL. Without a guard, a machine that is merely powered off reports FAIL every run, and the noise trains the reader to ignore the step. Write the guard as an explicit `if`, not as `guard && check || echo ...`:

     ```
     if ping -c1 -W1 hostname >/dev/null 2>&1; then <real check>; else echo "CANNOT VERIFY: host unreachable"; fi
     ```

     **`A && B || C` is the wrong shape here and it fails in the direction that hides bugs**: `C` runs when *either* `A` or `B` is false, so a reachable host whose check genuinely FAILS is reported as un-checkable. That converts a real defect into a shrug. Emit the reason too — "CANNOT VERIFY" with no cause is indistinguishable from a broken guard. **Bound the guarded check as well as the guard.** A reachable-but-filtered host answers `ping` and then blocks the real command for the full TCP timeout; the runner's 30-second cap only exists where `timeout` does. Pass the tool's own limit — `curl -m 5`, `ssh -o ConnectTimeout=5`.
   - **Print something on success — evidence by preference, `PASS` at minimum — and fail with a non-zero exit, not with a word.** A command that succeeds in silence is scored ERROR, and rightly: silence is what a command that never ran also produces, so exit status alone cannot tell "verified" from "did nothing". Two idioms to avoid, and the second is the dangerous one:

     ```
     git rev-parse v1.2.3 >/dev/null 2>&1 || echo NOTAG          # silent when it passes: proves nothing
     git rev-parse v1.2.3 >/dev/null 2>&1 && echo OK || echo NOTAG   # speaks, but "NOTAG" exits 0 — scored PASS
     ```

     The second is a false PASS with the evidence of its own failure printed beside it, and this repo shipped one for two months. The disposition is carried by exit status and by the `CANNOT VERIFY` prefix — never by a word in the output, which nothing parses. The single exception is deprecated and exists only to stop this framework's own four-month-old idiom reading as a pass on upgrade: a first line that is exactly `FAIL` with exit 0 is scored FAIL and told to rewrite itself. Put the failure on a non-zero exit: `git rev-parse v1.2.3 >/dev/null 2>&1 && echo TAG-PRESENT || { echo TAG-MISSING; exit 1; }`. Printing the value you checked, rather than a verdict, is better still — it tells the next reader what the claim was measured against.
   - **Assume nothing about the working directory.** The runner may be invoked from anywhere, and a relative command silently changes meaning when it is — `git ls-remote origin` checked a remote from the project root and, run one directory over, reported ERROR for a healthy claim. Address the target absolutely: `git -C /path/to/repo …`, absolute paths for files.


6. **Index self-consistency**: Every check above compares the index to something *outside* it — paths on disk, file mtimes, gotcha ages, ground truth, a verify probe. None asks whether the index agrees with itself, so two entries can assert opposite things indefinitely while each passes every check individually: both paths resolve, both files are fresh, neither is tagged as a state claim.

   This is worse than an ordinary stale entry. A stale entry is wrong; **a self-contradicting index is wrong while also carrying its own correction**, so which version an agent acts on depends on read order rather than on evidence. Where the index is always-loaded — the `@memory/MEMORY.md` import in `templates/memory-index.md` — both versions enter every session's context.

   - **Start with the cheap cluster: entries citing the same identifier.** Against the index (`memory/MEMORY.md` for Claude Code, the project file for a tool without auto-memory):

     ```
     idx=/abs/path/to/index.md
     [ -f "$idx" ] || echo "NO INDEX AT THAT PATH — this check examined nothing"
     grep -onE '[A-Za-z0-9_.-]*#[0-9]+' "$idx" | sort -u | cut -d: -f2- | sort | uniq -d
     ```

     `-o` with `-n` and `sort -u` counts an id **once per line**, so an entry that repeats `#34` four times is not a cluster of one. The optional prefix keeps a qualified id distinct: `llm-distillery#76` and a local `#76` are different trackers and must not be reconciled with each other. Read the surviving entries *together*, not in place. Known false positive: a six-digit hex colour reads as an id — discard it on sight. **An empty result with no index at that path is not a clean index**, which is why the guard prints rather than staying silent.
   - **The idea generalises to any stable identifier — the command does not.** For `ADR-023`, `GH-88` or `PROJ-45`, change the pattern (`[A-Za-z]+-[0-9]+`) and re-check what it matches before trusting the output.
   - **Then cluster by entity**: a repo, a file path, a component, a host. For each cluster ask one question — can all of these hold at once? Not "is each plausible", which is what reading them in place amounts to. **This half is a pairwise read of the whole index and is not bounded by anything but the index's size**, so it is the half to cut short when the index is large; the identifier pass above is the one that is cheap enough to run every session.
   - **Distinguish a contradiction from a recorded correction.** An entry that *names* the claim it supersedes and dates it — "this row asserted the opposite until 2026-08-11 and was false" — is correct practice, not a defect; the index is allowed to remember being wrong. A contradiction is two entries each asserting their version *without reference to the other*, so a reader has no way to tell which came second. If you cannot tell, say so and surface both.
   - **Report the contradicting pair verbatim and do not pick a winner from the text.** The more emphatic entry is not the more likely one; in the founding instance the false entry was the emphatic one *and* told the reader not to re-check. Resolve by measuring — whichever claim can be probed, probe it — and if neither can be, surface both to the engineer as an open question rather than deleting one.
   - This is model judgement, not a deterministic check. It is bounded only if the index is small: if it exceeds the ~200 lines `templates/memory-index.md` warns about, or the size budget in sub-step 8, report that as the finding and run the identifier pass alone.

7. **Hypothesis log surface**: If a hypothesis log exists, scan its `## Open` section. **Check both `memory/hypothesis-log.md` and `docs/hypothesis-log.md`** — projects put it in either, so a single-path check silently scans nothing. For each entry:
   - **Past `Review by:`**: Flag as **DUE FOR REVIEW** — the deadline has arrived. Surface to the engineer with the entry's Position and Method so they can resolve (move to `## Resolved`) or extend the deadline.
   - **`Revisit trigger:` fired**: If the trigger references an evidence threshold ("once 7 days of cycles complete," "after 14 contiguous eval rows"), check whether that threshold is now met. If yes, flag as **TRIGGERED**. The agent shouldn't resolve the hypothesis — only surface it; resolution requires reading the Method and applying it, which is the engineer's call.
   - **Stale (no movement, no trigger)**: Just count how many open entries exist. If more than ~10, flag as memory-cluttering — entries that never resolve should either be promoted to ADRs or marked `dormant` / closed.

8. **Project file size budget**: Check the project file (`CLAUDE.md` for Claude Code, equivalent for other tools). Claude Code warns at 40k chars; the soft target is under 35k to leave headroom. If the file is approaching or over budget:
   - **First, check for formatter table padding — it costs nothing to reclaim, so it comes before any content decision.** If the project runs a markdown formatter (prettier, dprint, some markdownlint configs) the project file's tables are padded with spaces so columns align in an editor. The budget is measured in **characters**, so that padding is charged in full against it — and against the context window every session. Measure the de-padded size before proposing any cut: strip each table cell to `| value |` and compare. In one adopter project with a table-heavy project file, this was **12,685 chars — 35% of a 36.3k file**, taking it to 23.6k with identical content and identical rendering. That project had no session footers left to trim and only structural sections remaining, so this step had already escalated to the engineer as a content decision when the real cause was whitespace.
   - If padding is a material share, the fix is **two** changes and needs both: de-pad the file, **and** exempt it from the formatter (e.g. add it to `.prettierignore`) — otherwise the pre-commit hook re-pads it on the very next commit and the work silently reverts. Verify the exemption is load-bearing rather than assuming it (`prettier --check --ignore-path /dev/null <file>` should report the file as needing changes, while the normal `--check` passes). Losing format-normalization on one markdown file is a smaller cost than a third of the budget; note the trade in the ignore file so the next reader knows it was deliberate.
   - Then the most common *content* cause: **session-narrative footers** (blocks like `_Last updated: ..._` / `_Earlier ..._`) accreting from prior sessions. These duplicate content that already lives in `memory/project_session_*.md` and is indexed in `MEMORY.md`.
   - Rule: keep at most **one** session footer block (the most recent), and only if it adds at-a-glance value the index can't carry. Drop older `_Earlier ..._` blocks — their content is preserved in session-memory files.
   - Don't trim structural sections (Hard Constraints, Before You Start, Architecture, Key Paths). Those are what the project file is *for*. **"Active work" is not on that list and is not protected** — it is a pointer list, and a pointer to finished work is exactly what should go. Trim it to the items actually in progress before proposing any structural cut.
   - If trimming wouldn't get under budget, surface to the engineer — structural restructuring is their call, not the agent's.

Report findings before proceeding. Don't fix anything in this step — just surface what's stale so the engineer can decide.

## Step 1 — Gotcha log review

Read `memory/gotcha-log.md` (or `docs/gotcha-log.md` if not using Claude Code). For each existing entry:
- If the root cause was fixed during this session, mark it `[RESOLVED]`
- If the same issue came up again, note the recurrence

Then check: did anything go wrong or surprise you during this session? For each one, append a new entry:

```
### [Short description] (YYYY-MM-DD)
**Problem**: What went wrong or was confusing.
**Root cause**: Why it happened.
**Fix**: What solved it.
```

**Keep each entry to 2-3 lines** — the lesson and the action, not the narrative of the session that found it. Having just lived through it, you will overweight the detail. If an entry needs a page, that is a signal it belongs in a topic file or an ADR. Apply this to new entries only; retrofitting the existing log is a separate, engineer-approved decision.

## Step 2 — Pattern detection and promotion

Scan the gotcha log for entries that have recurred 2-3 times. For each:
- Propose promoting it as an "if [situation], then [what to do]" pattern
- Suggest where it belongs: the memory index (if broadly relevant) or a topic file (if subsystem-specific)
- If approved, add it to the destination and update the Promoted table in the gotcha log

**Then check the promoted patterns against this session, and increment the Occurrences count for any that recurred.** Do this every session, not only when something is newly promoted.

**Which step owns the count.** Step 1 notes a recurrence on the entry itself; this step is what carries it into the Promoted table. The two are not redundant and must not disagree — the entry records *that* it happened again, the table is the running total, and the table is the number anything else cites. When they conflict, reconcile to the entries and say so in the report. Date each recurrence in the cell rather than only bumping the number, so a rate is readable and not just a total.

A promoted pattern that recurs means the promotion did not take: the lesson is written down somewhere the agent reads, and is being missed anyway. Say that plainly in the report rather than letting a quietly growing number carry it.

## Step 3 — Memory index update

Read the memory index (`MEMORY.md` for Claude Code, or the project file for other tools). Update:
- **Current State** — reflect what shipped or changed this session
- **Active work items** — for each active work-item file in `docs/work-items/`, update its Current Status section (the savepoint): mark completed items, update "Last action" and "Next action," note blockers. If a work item completed this session, fill its Outcome section and update the pointer to `[done]` — in the memory index's Current State section, or the project file's "Active work" section where the tool has no auto-memory. If a new multi-session initiative started, create the work-item file from `templates/work-item.md` and add a pointer
- **Key File Paths** — add any important files discovered during work
- **Active Decisions** — add any architectural choices made, with ADR pointers if created
- Remove or correct anything that is now stale

**Don't accrete session narrative onto the project file footer.** Session-level "what happened today" belongs in `memory/project_session_YYYY_MM_DD.md`, with a one-line pointer added to `MEMORY.md`. The project file is structural context (constraints, architecture, key paths) — appending session footers there bloats it past the 40k Claude Code perf threshold within ~7 sessions and duplicates what the index already holds. If a previous workflow left footer blocks behind, Step 0 sub-step 8 catches and trims them.

## Step 4 — Doc sync check

Check whether key docs reflect the current repo state. Code changes during a session can leave docs stale — this step catches drift that inline updates missed.

1. **Project file Architecture section**: Compare listed files/directories against actual repo contents. Flag new files not listed, or listed files that no longer exist.
2. **Project file Key Commands / How to Work Here**: Verify commands still match actual CLI flags and defaults. Flag any mismatches (e.g., a renamed flag, a changed default).
3. **Runbook** (if it exists): Check that operational details (environment setup, deployment steps, common problems) match reality. Flag anything that looks stale.
4. **Work-item check**: Scan `docs/work-items/` for files with an incomplete Outcome section. For each:
   - If the work completed this session, fill the Outcome and suggest updating the pointer to `[done]` — wherever this project keeps them (memory index, or the project file's "Active work" section)
   - If the Current Status shows no activity for 14+ days, flag as potentially abandoned — surface to the engineer
   - If the file has no corresponding pointer in either list, add one to whichever this project uses (or flag if unclear)

Fix what you can. Flag anything that needs engineer input.

## Step 5 — Verify references

Skip if Step 0 already ran a full freshness check. Otherwise, spot-check that paths mentioned in the memory index and project file still exist. Flag any broken references.

## Step 6 — Report

Summarize what you changed:
- **Freshness**: Dead references, stale memory files, lingering gotchas, ground truth drift (from Step 0)
- **Verification**: State claims checked — N passed, N failed, N unverified, N errored, N manual check needed, N cannot verify, N malformed (from Step 0). Report all seven numbers even when they are zero; a disposition omitted because it was empty is indistinguishable from one that was never checked. Carry the runner's reconciliation line and its exit status through too — **N commands run of M annotations** — and say what the difference was. Seven zeroes and no reconciliation is the shape of a step that did not run
- **Index self-consistency**: N identifiers cited by more than one *entry*, N contradicting pairs, and whether the entity pass ran or was cut short for size (from Step 0). Report all three. Zero pairs out of zero clusters means the check found nothing to compare, which is not the same as an index that agrees with itself — say which one it was. Quote any pair verbatim and leave it unresolved unless a probe settled it
- **Gotchas**: New entries added, entries resolved or promoted, and **N promoted patterns re-checked, N recurred** (from Step 2). Report both numbers even when the second is zero — "checked, nothing recurred" and "never checked" are otherwise indistinguishable, which is the failure the Occurrences column exists to prevent. Name any pattern that recurred *after* promotion; that is the signal the promotion did not take
- **Memory index**: Updates made
- **Doc sync**: Project file, runbook, backlog updates made or flagged (from Step 4)
- **Action needed**: Anything flagged that requires engineer decision
