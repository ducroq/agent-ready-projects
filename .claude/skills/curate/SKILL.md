---
name: curate
description: End-of-session curation — review gotcha log, promote patterns, update memory index, update work-item savepoints
disable-model-invocation: false
---

End-of-session curation for the agent-ready-projects framework.

Review the session's work and update the layered memory system:

## Step 0 — Freshness check

⚠️ **Measure the read surface first, and say the number.** This step's *body* is paid once per invocation and is prompt-cached; what it **reads** is fresh tokens every run and is 4–25× larger. Measured across three real repos: 147k chars here, 222k in a sibling, and **1,000,426 chars across 69 files** in a third — where the step could not read its own inputs in one context window and nothing said so (#46).

```bash
# -print0/-0 because a single spaced path (`docs/work-items/my slug.md`) is
# word-split into nonexistent paths and its bytes vanish from the total. `cat |
# wc -m` rather than `xargs wc -c | tail -1` for two reasons: xargs BATCHES above
# a few thousand files and `tail -1` then reports one batch's total (measured:
# 6000 files reported 105,600 of 600,000), and `wc -m` counts characters, which
# is what the threshold below is in. Both failures were silent and both read LOW.
find memory docs/work-items -type f -name '*.md' -print0 2>/dev/null \
  | xargs -0 cat | wc -m
```

**Above roughly 300k characters, do not read the corpus.** Work from metadata and the verify runner in this step, which is built to avoid the full read: it takes paths and reports, and never needs the documents in context. ⚠️ **Do not improvise a dead-reference check to fill the gap** — one was retired in v1.45.0 for never having caught anything, and an improvised one is the #51 failure: 25 `MISSING:` lines of which essentially all were false. Then curate **the index and the newest topic file only**, and say in the report which files you did not open. A run that silently reads a third of its inputs and reports as though it read all of them is the failure this whole method exists to prevent, one layer up.

Check for context rot from *previous* sessions. This catches what the session-focused steps below miss.

**Read metadata, not documents.** Measured across 2,264 real sessions, an ordinary session reads a **median of 3** memory files — the layer works as designed. This step is the exception that reads everything, and it does not need to. A gotcha log's headers are ~6–7% of the file and carry most of what Step 0.2, Step 1 and Step 2 use; a verify probe is *run*, not read; staleness is `stat`, not content. Where a large artifact is involved, take its index first and fetch a body only when you are going to act on it. In one measured repo this is the difference between ~1,000,000 characters and ~35,000.

1. **RETIRED — dead references, stale-memory mtime, and ground-truth drift.** All three were audited against this framework's whole record in v1.45.0 and **none had ever caught anything**. The dead-reference extractor's entire record was its own defects — six false-positive classes, four more found while fixing those, `process.env` and absence-assertions both reported DEAD. ⚠️ **The class is still checked**, by `audit-context` Step 4, which is adopter-facing and measured against a fixture with seeded true positives; what was removed is the second, unmeasured checker. The mtime check measured file age, which is not staleness. Ground-truth drift had never had a table to examine. **Do not re-add any of them without a catch to point at.**

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

   **Match both heading levels, and reconcile the count.** Adopters use `##` and `###` for entries — one measured log uses `##` for 106 of its 200 entries and says so in its own file comment, and a `^### `-only read returned 94, a plausible number that silently omitted half the file including every entry from the last two weeks. If the header count and the `**Problem**` count disagree by more than the section headings, the extractor is wrong; a short answer here is a defect, not a small log. Ignore headings inside `<!-- -->` — a fresh adopter's log still contains the template's own example entry there. **The Promoted table is why this needs reading too**: Step 2 carries recurrences into it, and in one measured log 11 entries recorded resolved there carry no marker in their header, so a header-only pass reports every one of them as unresolved forever.

3. **Unverified state claims**: Scan memory files **and the project file** for state claims ("shipped," "deployed," "live," "running," "working in production") and for counts about this repo that decay silently. The project file is in scope because that is where version lines, adopter counts and occurrence tallies live, and an always-loaded wrong number misleads every session that starts — a count with no probe is a claim, not a fact. Claims carrying a `<!-- verify: ... -->` annotation are run by the runner below. **Do not read the memory files to do this** — the runner extracts and executes the annotations itself, and its report is what you read. Pulling the files into context to find annotations costs the whole corpus to obtain what a grep already returned. A claim with no annotation is **UNVERIFIED** — those decay immediately after the session that wrote them, so suggest adding an annotation or requalifying the claim as a session observation.

⚠️ **An annotation is not automatically a check. Four ways one passes while its claim is false** — each observed, and each invisible in a green run:

- **The probe asserts a PROXY.** `ls-remote | grep -q .` under *"v1.21.0 tagged and pushed"* proves *some* tag exists, so it stays green after the claim rots and is greenest on the day it is most wrong. Anchor the probe to the exact thing claimed — an exact ref, not a non-empty listing.
- **The check was never tight.** The seeded-true-positives rule fires when a check is *loosened*; a check that never caught anything looks identical to one that works. The tell is a **deletion**: remove the thing the check exists to catch and confirm it turns red. If nothing turns red, there was no check.

  ⚠️ ***Could this assertion have failed?* is answered by running, not by reading — so no amount of static checking substitutes for the deletion.** Two estates converged on this in one day. A lexer catches the shapes that are unambiguous on their face — a mutation identical to its target, an empty expected result — and stops there, because the same construct is a hole in one place and correct in another: a disjunction in a **pass** condition gives the test two ways to succeed and you only ever exercise one, while the same disjunction in a **fail** condition widens detection and is right. Nothing lexical separates them.

  Measured across the two estates on one evening: a fixture reporting **26/26 cases and 6/6 ablations green** while carrying three assertions that could not fail; `assert checked or True` sitting **two lines under a comment stating the rule it defeats**; and `assert "&amp;" not in result or "&" in result`, a tautology in a test named for removing entities, which passed on decoded output, raw input and the empty string alike. **None was found by a linter, a review, or a green suite. Every one was found by deleting the thing the check names and watching what stayed green.**
- **The count travels and the enumeration does not.** A number copied forward without the list behind it cannot be re-derived, and diverges silently from what it counts. Move the enumeration with the number, or make the number a probe.
- **A state report decays; a claim does not.** *"Merged and tagged"* written before either happened is not distinguishable later from one that was true when written. Write state in the tense of what has actually run, and stamp it, so a reader can tell *reported wrong* from *was true then*.

   **Use this runner. Do not write one on the spot.** Every hand-written implementation observed so far reported *nothing wrong having checked nothing* — a silent, self-certifying pass, reached by six independent routes: a command containing `exit` ends the loop mid-iteration; an `ssh` (or any other stdin-reading command) swallows the rest of the command list; prose that merely *mentions* the syntax is executed as shell; `[^>]*` extraction truncates at the first `>`, mangling every command with a redirect; a `\|`-escaped command from a table cell runs with its pipes as literal `echo` arguments, so its fallback branch is dead code; and a command that succeeds in silence is indistinguishable from one that never ran. Each of the six is sufficient on its own. Save the block to a scratch file, **run it from the repo root**, and give it **absolute paths** — including the project file (`CLAUDE.md`, `AGENTS.md` or whatever your tool's naming map calls it): `bash /tmp/verify-runner.sh /repo/memory/*.md /repo/docs/hypothesis-log.md /repo/CLAUDE.md`. The cwd matters because the runner executes each command with `bash -c` and does not tell it which file it came from, so a probe resolving a relative path depends on where you stood. A probe in a file you never pass to the runner is worse than no probe: it reads as a checked claim and is never checked.

   ````bash
   #!/usr/bin/env bash
   # curate Step 0 sub-step 3 — verify runner (canonical). Do not re-derive it; see issue #34.
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
       { sub(/\r+$/, "") }                                    # CRLF: strip before anything reads
                                                              # the line. isdelim() strips spaces and
                                                              # tabs but not \r, so intbl is never set,
                                                              # the table un-escape never runs, and an
                                                              # escaped-pipe command is still extracted,
                                                              # counted and EXECUTED — mangled.
                                                              # Corruption, not silence: the shape of
                                                              # #52 with a worse disposition. See #58.
                                                              # `\r+`, not `\r`: an index blob already
                                                              # holding CRLF, converted again, yields
                                                              # `\r\r\n`, and stripping one CR left the
                                                              # defect intact on the fixed runner.
                                                              # ⚠️ A LONE CR (no LF) is NOT fixed and
                                                              # cannot be here: awk reads the file as one
                                                              # record, so no table is entered and the
                                                              # un-escape never runs — a false PASS at
                                                              # exit 0. Same residual review-changes
                                                              # discloses beside its own #52 fix; worse
                                                              # here, because this runner EXECUTES.
                                                              # NB no apostrophe anywhere in this block:
                                                              # the awk program is single-quoted.
       # `$(0)`, never `\$0`: skill ARGUMENTS are substituted into the skill BODY,
       # so a bare `\$0` is delivered as the first argument word and this program
       # then reads a constant — no table entered, escaped pipes EXECUTED mangled.
       # `$(0)` is the only form correct on both that path and the extraction
       # path the fixture uses. Measured; see #77 and the v1.27.0 changelog entry.
       FNR == 1 {
         if (fch != "") print "U\034" curfile "\034" "a fence opened at line " openline " and never closed"
         fch = ""; intbl = 0; prev = ""; curfile = FILENAME    # no state may cross a file
       }
       {
         bare = $(0); sub(/^[ \t]*/, "", bare)                 # a fence may be indented
         if (bare ~ /^```/ || bare ~ /^~~~/) {                 # and opens on ``` or ~~~
           c = substr(bare, 1, 1); k = 0
           while (substr(bare, k + 1, 1) == c) k++
           if (fch == "") { fch = c; flen = k; openline = FNR }
           else if (c == fch && k >= flen) fch = ""            # closing only on the same
           intbl = 0; prev = ""; next                          # character, at least as long
         }
         if (fch != "") next                                   # inside a fence: documentation
         if (isdelim($(0)) && index($(0), "|") && prev != "") { intbl = 1; prev = $(0); next }
         if (intbl && !haspipe($(0))) intbl = 0                # a table ends at its last row
         line = $(0)
         mask = maskspans(tolower(line), line)                 # match case-insensitively, at
         while (match(mask, /<!--[ \t]*verify:[ \t]*/)) {      # preserved offsets
           p = RSTART + RLENGTH
           rest = substr(line, p)                              # take the command from the
           e = index(rest, "-->")                              # ORIGINAL line
           if (e == 0) { print "M\034" FILENAME "\034" substr(rest, 1, 60); break }
           cmd = substr(rest, 1, e - 1); sub(/[ \t]+$/, "", cmd)
           if (tolower(cmd) ~ /<!--[ \t]*verify:/) { print "D\034" FILENAME "\034" substr(cmd, 1, 60); break }
           if (intbl) gsub(/\\\|/, "|", cmd)                   # a table cell escapes its pipes
           if (cmd == "") print "E\034" FILENAME "\034" substr($(0), 1, 60)
           else print "C\034" FILENAME "\034" cmd
           mask = substr(mask, p + e + 2); line = substr(line, p + e + 2)
         }
         prev = $(0)
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

   **Zero commands extracted is a defect, never a pass** — and so is a count the reader cannot account for. The runner's last line reconciles commands run against `<!--`-shaped annotations in the same files; account for the difference item by item. Documentation of the syntax — code spans, fenced examples — is the expected explanation; an annotation the extractor could not see is a bug in the annotation or in the runner. It is the same trap as reading memory-file dates with `git log` where `memory/` is gitignored — the recommended setup, and this framework's own: `git log` returns **empty with exit 0** for every file, so the check reports nothing stale having examined nothing. The step reports nothing wrong *precisely when* it has examined nothing. The exit status says which case you are in: **2** means the run itself cannot be trusted — no files given, an operand that is not a readable file, nothing extracted, or nothing that produced a verdict because every annotation was manual or unreachable — **1** means a claim failed, errored or was malformed, and **0** means everything reachable checked out. Do not report a run you did not read the exit status of.

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

   **One deprecated exception, and it is the only place a word in the output changes anything.** A command whose entire first line is `FAIL` and which exits 0 is scored FAIL, not PASS, and the row says why. It matches the bare word only — evidence like `FAIL: 0  WARN: 0  OK: 12` is evidence. Rewrite the command; do not rely on it.

   **Two blind spots, so a clean run is not read as more than it is.** Fenced blocks are skipped — including indented ones, `~~~` ones, and a `` ``` `` block nested inside a four-backtick one — but an annotation inside a *four-space-indented code block* (one with no fence at all) or inside a blockquote is indistinguishable from a live one and **will run**. Write examples in fenced blocks. And UNVERIFIED is not a disposition the runner can produce: it is your judgement about claims with no annotation at all, so "zero is a defect" does not apply to that one of the numbers in Step 6.

   **A negative existence claim — or a count — is a state claim, and it is the shape that escapes this step.** "There is no reader-facing count", "that endpoint doesn't exist", "nothing references the old path", "4 issues open" — these read as settled fact rather than as claims about a world that moves, so nobody attaches a probe to them and the decay rule never reaches them. They are also the claims most likely to be about *another* repository, where you cannot see the change that falsified them. Give each one a probe that fails loudly if the thing turns out to exist — **and guard the target first**, because `grep -rq` on a path that no longer exists returns "not found" and certifies the claim: `if [ ! -d /abs/path/other-repo ]; then echo "CANNOT VERIFY: repo not at that path"; elif grep -rq 'pattern' /abs/path/other-repo; then echo "CLAIM REFUTED: it exists"; exit 1; else echo "still absent"; fi`. A sibling repo being moved or renamed is the commonest way one of these claims goes unverifiable, and it is exactly the case the unguarded form cannot see. **An instruction not to re-derive a claim is a reason to probe it, not a licence to skip it** — "verified in ../other-repo, don't re-check" is how a false claim survives five days and several curate runs.

   **Writing a verify command — it has to survive two syntaxes it is not written in.** The body sits inside an HTML comment, inside markdown, and shell is hostile to both. Check each command against the six rules below, then **run it once, at the moment you write it**. A verify command that fails on day one is worthless; one that cannot be *extracted* is worse than none, because it reports nothing while looking like it ran.

   - **Avoid `--`, and never let `-->` appear.** The hard rule is narrow: an HTML comment ends at the first `-->`, so a command containing that sequence truncates the comment and spills the remainder onto the page. Bare `--` is conforming HTML and renders fine — but it breaks two things that matter here. XML and XHTML pipelines reject it outright, and, the failure actually observed, a naive extraction regex over comment bodies stops early and returns **zero** commands, so the step examines nothing and completes cleanly. Long flags are the commonest construct in shell, so this is near-certain rather than an edge case: `--user`, `--no-pager`, `--json`, `--quiet`. In order of preference: **check the artifact instead of asking the tool** (`test -L ~/.config/systemd/user/UNIT` rather than `systemctl --user is-enabled`); **set an environment variable instead of passing a flag** (`SYSTEMD_PAGER=cat systemctl list-timers`); **use the short flag**.
   - **One line, opened and closed on that line.** The extractor requires the `-->` on the same line as the `<!-- verify:`, because a multi-line annotation is indistinguishable from an unterminated one, and both are reported MALFORMED rather than skipped. If a command is too long for a line, that is a signal to put it in a script the annotation calls.
   - **No unescaped `|` if the claim lives in a table cell — and no escaped `\|` if it does not.** GFM splits a row into cells before it parses inline content, so the idiomatic `&& echo PASS || echo FAIL` adds two cells; GFM then discards everything past the table's width, taking the rest of the row with it. Escape as `\|` inside a table, or keep verified claims out of tables. **Outside a table the escape is not neutral**, which is why the runner un-escapes only table rows: in an ordinary bullet, `\|` is the escape *shell and awk* use for a literal pipe, and rewriting it silently changes the command. One adopter's `awk -F'|' '/^\| P[0-9]+ \|/…'` row-count check — correct, and passing — became `/^| P[0-9]+ |/`, an alternation with an empty operand, and reported FAIL on a healthy claim.
   - **A probe needing a literal `|` builds it: `b=$(printf '\174')`, then `"^$b 2026-08-25 $b"`.** It means the same in or out of a table, and a row restructured into a bullet otherwise turns `\|` into BRE alternation — one probe then matched every line and could never fail (#186). ⚠️ BRE or `-F` only: under `-E` it is alternation again.
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

     The second is a false PASS with the evidence of its own failure printed beside it, and this repo shipped one for two months. The disposition is carried by exit status and by the `CANNOT VERIFY` prefix — never by a word in the output, which nothing parses. The single exception is deprecated and exists only to stop this framework's own four-month-old idiom reading as a pass on upgrade: a first line that is exactly `FAIL` with exit 0 is scored FAIL and told to rewrite itself. Printing the value you checked, rather than a verdict, is better still — it tells the next reader what the claim was measured against.
   - **Never hardcode the version a probe corroborates — derive it from the stamp.** A probe written as `git show "v1.36.1:<path>" | diff -q - <installed>` has the lifetime of *that tag*, not of the claim: it expires at the exact moment it has something to report, since what makes it interesting is the upstream tag moving. Derive the version from the stamp, so bumping the stamp re-arms the probe and the two cannot silently disagree. Two adopter estates wrote the same fix independently on the same day, and one of them caught a release with it (#136).

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

     Every branch was executed, not read: clean, a seeded drift (exit 1), no stamp, skill absent, outside a repo, `FRAMEWORK` unset, an unfetched tag, a stamp older than the installer, a list assigned twice, a skill absent at the tag — under bash, dash and zsh. The `2>/dev/null` matters — without it git's own `fatal:` prints beside CANNOT VERIFY and reads as the failure.

     ⚠️ **Compare against the REFERENCE INSTALL (`.claude/skills/<name>/SKILL.md`), never `templates/<name>.md`** — the template's `SAVE AS` comment is frontmatter in the install, a structural residue no tag clears, so every run reads as drift. **Preconditions, not universal**: a framework clone at `$FRAMEWORK`, skills installed globally.
   - **Assume nothing about the working directory.** The runner may be invoked from anywhere, and a relative command silently changes meaning when it is — `git ls-remote origin` checked a remote from the project root and, run one directory over, reported ERROR for a healthy claim. Address the target absolutely: `git -C /path/to/repo …`, absolute paths for files.


4. **Index self-consistency**: Every check above compares the index to something *outside* it — gotcha ages, a verify probe, a hypothesis deadline. None asks whether the index agrees with itself, so two entries can assert opposite things indefinitely while each passes every check individually: both paths resolve, both files are fresh, neither is tagged as a state claim.

   This is worse than an ordinary stale entry. A stale entry is wrong; **a self-contradicting index is wrong while also carrying its own correction**, so which version an agent acts on depends on read order rather than on evidence. Where the index is always-loaded — the `@memory/MEMORY.md` import in `templates/memory-index.md` — both versions enter every session's context.

   - **Start with the cheap cluster: entries citing the same identifier.** Against the index (`memory/MEMORY.md` for Claude Code, the project file for a tool without auto-memory):

     ```
     idx=/abs/path/to/index.md
     [ -f "$idx" ] || echo "NO INDEX AT THAT PATH — this check examined nothing"
     grep -onE '[A-Za-z0-9_.-]*#[0-9]+' "$idx" | sort -u | cut -d: -f2- | sort | uniq -d
     ```

     `-o` with `-n` and `sort -u` counts an id **once per line**, so an entry that repeats `#34` four times is not a cluster of one. The optional prefix keeps a qualified id distinct: `adopterrepo#76` and a local `#76` are different trackers and must not be reconciled with each other. Read the surviving entries *together*, not in place. Known false positive: a six-digit hex colour reads as an id — discard it on sight. **An empty result with no index at that path is not a clean index**, which is why the guard prints rather than staying silent.
   - **The idea generalises to any stable identifier — the command does not.** For `ADR-023`, `GH-88` or `PROJ-45`, change the pattern (`[A-Za-z]+-[0-9]+`) and re-check what it matches before trusting the output.
   - ⚠️ **The entity pass was RETIRED in v1.45.0** — a pairwise read of the whole index, unbounded by anything but the index's size, which had **never found a contradicting pair**, including in the dog-food run that shipped it. The identifier grep above is one command and stays. Do not re-add the pairwise read without a pair to point at.
   - **Distinguish a contradiction from a recorded correction.** An entry that *names* the claim it supersedes and dates it — "this row asserted the opposite until 2026-08-11 and was false" — is correct practice, not a defect; the index is allowed to remember being wrong. A contradiction is two entries each asserting their version *without reference to the other*, so a reader has no way to tell which came second. If you cannot tell, say so and surface both.
   - **Report the contradicting pair verbatim and do not pick a winner from the text.** The more emphatic entry is not the more likely one; in the founding instance the false entry was the emphatic one *and* told the reader not to re-check. Resolve by measuring — whichever claim can be probed, probe it — and if neither can be, surface both to the engineer as an open question rather than deleting one.
   - This is model judgement, not a deterministic check. It is bounded only if the index is small: if it exceeds the ~200 lines `templates/memory-index.md` warns about, or the size budget in sub-step 6, report that as the finding and run the identifier pass alone.

5. **Hypothesis log surface**: If a hypothesis log exists, scan its `## Open` section. **Check both `memory/hypothesis-log.md` and `docs/hypothesis-log.md`** — projects put it in either, so a single-path check silently scans nothing. For each entry:
   - **Past `Review by:`**: Flag as **DUE FOR REVIEW** — the deadline has arrived. Surface to the engineer with the entry's Position and Method so they can resolve (move to `## Resolved`) or extend the deadline.
   - **`Revisit trigger:` fired**: If the trigger references an evidence threshold ("once 7 days of cycles complete," "after 14 contiguous eval rows"), check whether that threshold is now met. If yes, flag as **TRIGGERED**. The agent shouldn't resolve the hypothesis — only surface it; resolution requires reading the Method and applying it, which is the engineer's call.
   - **Stale (no movement, no trigger)**: Just count how many open entries exist. If more than ~10, flag as memory-cluttering — entries that never resolve should either be promoted to ADRs or marked `dormant` / closed.

6. **Auto-loaded size budget — the whole set, not the project file alone.** Sum **every file your tool loads without being asked**, and compare the total against the budget. Claude Code warns at 40k chars; the soft target is under 35k to leave headroom.

   ⚠️ **Measuring one file of a set keeps a repo green while over budget** (#109). Claude Code auto-loads the project file *and* a user-level memory index; an adopter measured 31,613 + 9,941 = **41,554 chars — over the hard cap — while this step read 31,613 and reported "comfortably under the soft target"**. It had been wrong for roughly a fortnight and was caught only because that adopter had recorded the pair by hand in an earlier audit. **List the set before measuring**, and name any file you decided not to count.

   ⚠️ **Budget the index in characters too, not lines** (#110). `templates/memory-index.md` warns at ~200 lines, and a line count cannot see cell width: one adopter's index was **127 lines** and, in this budget's own units, **several times the 40k cap** — the largest thing loaded each session, yet inside the line budget. Two auto-loaded files in non-comparable currencies means the denser one escapes. The line warning is a readability hint; the character budget is the cost.

   If the set is approaching or over budget:
   - **First, check for formatter table padding — it costs nothing to reclaim, so it comes before any content decision.** If the project runs a markdown formatter (prettier, dprint, some markdownlint configs) the project file's tables are padded with spaces so columns align in an editor. The budget is measured in **characters**, so that padding is charged in full against it — and against the context window every session. Measure the de-padded size before proposing any cut: strip each table cell to `| value |` and compare. **In measured adopter projects this has been a large share of the file**, content and rendering identical — one had escalated to the engineer as a *content* decision when the cause was whitespace. *()*
   - **The share varies widely; table shape predicts it** — the two measured projects differ by nearly 2x. The cause is the **delimiter rows**, not the cells: one paragraph-length cell widens its whole column and its delimiter row, so the task-triggered pointer index this method prescribes is the idiom hit hardest. *(Measure in the budget's own units: `wc -c` counts bytes, so multi-byte characters read larger.)*
   - If padding is a material share, the fix is **two** changes and needs both: de-pad the file, **and** exempt it from whatever re-pads it. **Identify that agent before claiming one exists.** Editor format-on-save, a pre-commit hook and CI are all candidates. An adopter patched the pre-commit hook first, then ran the control with the patch removed and found it had never touched the file at all: `lint-staged` applies a config only to files beneath that config's own directory, and theirs lived in `frontend/`, so the root project file had never been in its reach. Where the runner's config is scoped to a subdirectory, the exemption is for the humans' editors, not the hook.
   - **Verify the exemption from the cwd the formatter actually runs in.** Prettier resolves its default ignore file relative to the **cwd**, not by walking up from the file, so the obvious check passes from the repo root while the exemption is inert for any invocation starting elsewhere — project file at the root, toolchain in a subdirectory, a common layout. Note the trade in the ignore file so the next reader knows it was deliberate. *()*
   - Then the most common *content* cause: **session-narrative footers** (blocks like `_Last updated: ..._` / `_Earlier ..._`) accreting from prior sessions. These duplicate content that already lives in `memory/project_session_*.md` and is indexed in `MEMORY.md`. ⚠️ **This rule applies to every auto-loaded file, the index included** (#110): index rows for old sessions balloon from one-line hooks into paragraph-length re-summaries of the files they point to. The reasoning transfers verbatim — the detail is preserved in the session file, so the row is a pointer.
   - Rule: keep at most **one** session footer block (the most recent), and only if it adds at-a-glance value the index can't carry. Drop older `_Earlier ..._` blocks — their content is preserved in session-memory files.
   - Don't trim structural sections (Hard Constraints, Before You Start, Architecture, Key Paths). Those are what the project file is *for*. **"Active work" is not on that list and is not protected** — it is a pointer list, and a pointer to finished work is exactly what should go. Trim it to the items actually in progress before proposing any structural cut.
   - If trimming wouldn't get under budget, surface to the engineer — structural restructuring is their call, not the agent's.

Report findings before proceeding. Don't fix anything in this step — just surface what's stale so the engineer can decide.

## Step 1 — Gotcha log review

Read the gotcha log's **headers** — the same `grep -nE '^#{2,3} '` as sub-step 2, both levels, not `^### ` alone — rather than the whole log. For each existing entry:
- If the root cause was fixed during this session, mark it `[RESOLVED]` **in the header**, not in the body: `### Title (2026-08-12) [RESOLVED]`. A status buried in a body cannot be seen by a header read, which makes every later run open the whole file to find out what is still open. Headers written before this convention have no marker and read as open; move one up when you touch its entry.
- If the same issue came up again, note the recurrence **in the header as well as the body** — `### Title (2026-08-12) [x3]`. Step 2 counts recurrences and reads headers; a recurrence recorded only in a body is invisible to the step that exists to promote it.

   **Recurrence is the one check headers cannot serve, and this is a limit rather than a solution.** Recognising that today's problem is last month's problem is a match on *mechanism*, which lives in the body — a header reading "extraction returned near-zero and looked like a clean run" does not tell you it was a `[^>]*` character class. Grep the log for a distinguishing term, read the entries that match, and accept that the term is a guess. Note the counter-evidence honestly: this framework's own log records that same bug being re-implemented **three times**, twice by sessions that had the whole log open. A full read did not prevent it, so header-first is not obviously worse — but do not claim it is better, and when a new entry feels familiar, spend the read.

Then check: did anything go wrong or surprise you during this session? For each one, append a new entry:

```
### [Short description] (YYYY-MM-DD)
**Problem**: What went wrong or was confusing.
**Root cause**: Why it happened.
**Fix**: What solved it.
```

**Write the lesson and the action, not the narrative of the session that found it.** Having just lived through it, you will overweight the detail. Measured across three logs and 277 entries, a real entry runs ~700–1,200 characters and that is fine: since Step 0.2 reads headings, a body costs nothing until someone opens it. The old rule here said "2–3 lines", which was unenforceable — a markdown line has no length limit, so every log passed it while running 3–6× the size the rule intended. **Above ~3,000 characters is the signal worth acting on** (2–5% of entries in every log measured): that is a page, and a page belongs in a topic file or an ADR.

## Step 2 — Pattern detection and promotion

Scan the gotcha log's headers and its Promoted table for entries that have recurred 2-3 times — the counts live in the table and the titles in the headers, so neither needs a body read. For each:
- Propose promoting it as an "if [situation], then [what to do]" pattern
- Suggest where it belongs: the memory index (if broadly relevant) or a topic file (if subsystem-specific)
- If approved, add it to the destination and update the Promoted table in the gotcha log

**Then check the promoted patterns against this session, and increment the Occurrences count for any that recurred.** Do this every session, not only when something is newly promoted.

**Read the Mechanized table too, if the log has one** — same extractor, `Mechanized` for `Promoted`. Written by `review-changes` Step 3.1: review findings promoted to deterministic checks. Report any row still `proposed` after several sessions (a check nobody built), and increment Occurrences on a `live` row whose shape recurred — that is the signal the check does not fire on the real shape. ⚠️ Unread, the table is write-only: a live check that stopped firing looks exactly like one that works.

**Which step owns the count.** Step 1 notes a recurrence on the entry itself; this step is what carries it into the Promoted table. The two are not redundant and must not disagree — the entry records *that* it happened again, the table is the running total, and the table is the number anything else cites. When they conflict, reconcile to the entries and say so in the report. Date each recurrence in the cell rather than only bumping the number, so a rate is readable and not just a total.

A promoted pattern that recurs means the promotion did not take: the lesson is written down somewhere the agent reads, and is being missed anyway. Say that plainly in the report rather than letting a quietly growing number carry it.

## Step 3 — Memory index update

Read the memory index (`MEMORY.md` for Claude Code, or the project file for other tools). Update:
- **Current State** — reflect what shipped or changed this session
- **Active work items** — for each active work-item file in `docs/work-items/`, update its Current Status section (the savepoint): mark completed items, update "Last action" and "Next action," note blockers. If a work item completed this session, fill its Outcome section and update the pointer to `[done]` — in the memory index's Current State section, or the project file's "Active work" section where the tool has no auto-memory. If a new multi-session initiative started, create the work-item file from `templates/work-item.md` and add a pointer
- **Key File Paths** — add any important files discovered during work
- **Active Decisions** — add any architectural choices made, with ADR pointers if created
- Remove or correct anything that is now stale

**Don't accrete session narrative onto the project file footer.** Session-level "what happened today" belongs in `memory/project_session_YYYY_MM_DD.md`, with a one-line pointer added to `MEMORY.md`. The project file is structural context (constraints, architecture, key paths) — appending session footers there bloats it past the 40k Claude Code perf threshold within ~7 sessions and duplicates what the index already holds. If a previous workflow left footer blocks behind, Step 0 sub-step 6 catches and trims them.

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

**Always run this.** ⚠️ It read *"skip if Step 0 already ran a full freshness check"* until v1.45.0, which was true only while Step 0 carried a dead-reference extractor. That was retired for never having caught anything, and the skip clause went with it — left in place it would have taken path checking inside this skill from twice per run to **zero**, silently. Spot-check that paths named in the memory index and project file still exist, and flag any that do not. For a full, measured check of the class, `audit-context` Step 4 is the instrument; it runs monthly, so this per-session spot-check is what stands between.

## Step 6 — Report

Summarize what you changed:
- **Freshness**: Gotcha log headers reconciled against the `**Problem**` count, and the Promoted table read (from Step 0)
- **Verification**: State claims checked — N passed, N failed, N unverified, N errored, N manual check needed, N cannot verify, N malformed (from Step 0). Report all seven numbers even when they are zero; a disposition omitted because it was empty is indistinguishable from one that was never checked. Carry the runner's reconciliation line and its exit status through too — **N commands run of M annotations** — and say what the difference was. Seven zeroes and no reconciliation is the shape of a step that did not run
- **Index self-consistency**: N identifiers cited by more than one *entry*, and N contradicting pairs among them (from Step 0). Report both. Zero pairs out of zero clusters means the check found nothing to compare, which is not the same as an index that agrees with itself — say which one it was. ⚠️ **Do not report a disposition for the entity pass**; it was retired in v1.45.0, and inventing one — or re-running the pairwise read to have something to say — is what that retirement forbids. Quote any pair verbatim and leave it unresolved unless a probe settled it
- **Gotchas**: New entries added, entries resolved or promoted, and **N promoted patterns re-checked, N recurred** (from Step 2). Report both numbers even when the second is zero — "checked, nothing recurred" and "never checked" are otherwise indistinguishable, which is the failure the Occurrences column exists to prevent. Name any pattern that recurred *after* promotion; that is the signal the promotion did not take
- **Memory index**: Updates made
- **Doc sync**: Project file, runbook, backlog updates made or flagged (from Step 4)
- **Action needed**: Anything flagged that requires engineer decision
