# Fixture — the canonical verify runner (issue #34)

Sensitivity harness for the runner shipped in `templates/curate.md`, Step 0
sub-step 5. Run it after any change to that block:

```bash
bash tests/fixtures/verify-runner/run.sh
```

## Why this fixture exists

Step 0 sub-step 5 executes the `<!-- verify: ... -->` annotations in the memory
files. Its failure mode is silence — it reports nothing wrong having checked
nothing, which is byte-for-byte what a clean pass looks like. Running it against
this repo proves little: it holds two real annotations, and only one of them —
a table cell with escaped pipes — touches any of the defects below.

Six ways a hand-written runner has silently verified nothing, each sufficient on
its own, each seeded here:

| # | Cause | Seeded as |
|---|-------|-----------|
| 1 | A command containing `exit` ends the runner's own loop mid-iteration | `p04` |
| 2 | `ssh` — or any stdin-reading command — swallows the rest of the command list | `p05` |
| 3 | Prose that merely *mentions* the syntax is executed as shell | `n01`–`n10` |
| 4 | `[^>]*` extraction truncates at the first `>`, mangling every redirect | `p10` |
| 5 | A table cell's `\|` escapes run as literal `echo` arguments; the fallback branch is dead code | `p02`, `p12`, `p16` |
| 6 | A command that succeeds in silence is indistinguishable from one that never ran | `p06` |

Causes 1 and 2 are the issue as filed; 3 and 4 arrived on it later; 5 was found
by measuring this repo's own annotations; 6 came in from
agent-ready-papers/pipeline-atlas, which shipped `ops/run_verifies.sh` for it.

## The runner is extracted, not copied

`run.sh` pulls the runner out of `templates/curate.md` at run time — the
four-backtick block carrying the sentinel `verify runner (canonical)` — and
fails if there is not exactly one. Nothing here is a copy, so this harness
cannot drift from the text adopters actually run. That drift is what cost this
repo lint rule 6; a fixture testing a stale copy of a procedure is worse than no
fixture, because it reports green about something nobody runs.

## What the cases assert

- **33 positives** (`c00`, `p01`–`p34`) — each must be extracted *and* classified as the
  named disposition. A positive that vanishes from the report fails just as
  loudly as one that is misclassified.
- **4 malformed cases** (`m01`–`m04`) plus `u01` — no closing `-->`, a second
  `<!-- verify:` before the first closes, an annotation whose opener is inside a
  code span while its `-->` is outside, an empty command, and a fence that opens
  and never closes. Each must be reported MALFORMED and not executed. Silently skipping
  any of them drops a claim nobody then checks, which is the failure class in
  miniature.
- **10 negatives** (`n01`–`n11`, no `n04`) — prose forms the runner must refuse to
  execute, including a `~~~` fence, a `` ``` `` block nested inside a
  four-backtick one, and an indented fence under a nested bullet. Each would
  `touch` a canary file if it ran, so the assertion is not merely "no row
  appeared" but "the shell never happened". Two are the exact strings this
  repo's `memory/gotcha-log.md` was executing.
- **7 structural cases** (`S1`–`S6`, `M3`) — no arguments, an unreadable operand,
  a directory operand, a file with no annotations, a clean file, a manual-only
  run and a cannot-verify-only run, each asserted on the runner's *exit status*.
  The last two matter most: a run in which nothing was actually verified must
  not report all-clear. `S1` also asserts the runner does not hang.
- **4 timing cases** (`M1`, `M1a`, `M2`, `M2a`) — the per-command timeout and the
  per-command output file, each with its own mutant. They run against two-line
  inputs rather than the main tree, because seeding them there would cost several
  seconds on every one of the 29 ablation runs.
- **The reconciliation line** — `ran 32 of 48 annotations`. Both numbers are
  asserted. An extractor that silently yields fewer commands still prints a
  summary, and that line is the only place the shortfall is visible.
- **29 ablations** — each removes one guard and must produce *its own specific
  defect*, named as a row disposition, a canary, a missing row or a missing
  summary. "The output changed" was the first draft and is too weak: a mutation
  that breaks the runner in some unrelated way also changes the output, so it
  passes without ever demonstrating the defect the guard prevents.
- **The ablation control `c00`** — the nine absence-shaped ablations
  (`norow:`/`notrow:`) additionally require a row the mutant must *still* report
  correctly. See the next section: without it those nine proved nothing.

## The control, and the measurement that forced it (#90)

An absence-shaped consequence — "row `p22` is gone" — was guarded only by the
summary line, on the reasoning that a runner which died mid-loop never prints
one. That closes the **crash** form of a dead runner and not the **silence**
form. Measured on the shipped fixture: suppressing the four per-row report sites
(`MALFORMED`, `MANUAL`, `CANNOT-VERIFY`, and the `%-14s` verdict row) with a `:`
prefix — leaving extraction, execution, counting, the summary line and the exit
status intact — produced this:

| | before the control | with the control |
|---|---|---|
| ablations that PASS against the silence-mutant | **15** | **6** |
| of those, legitimate | 6 | 6 |
| of those, **vacuous** | **9** | **0** |

The six legitimate passes are the five `canary:` ablations, which assert a
filesystem side-effect the mutant deliberately preserves, and `A5-subshell`,
whose mutation genuinely kills the run before its summary. The nine vacuous ones
were `A8`, `A9`, `A10`, `A22`, `A23`, `A25`, `A27`, `A29` and `A30`.

`c00` is seeded in the file passed **first**, above every fence, in plain prose,
lower-case marker, no pipe, no code span, no table — the position is the design,
because every mutation these ablations apply must leave it reportable. `A10`
is why it must be in the first file at all: that ablation removes the per-file
state reset, so an open fence legitimately blanks every later file, and any
control living in `claims.md` would fail for a reason that is not death.

**Four** of the nine assert the disappearance of a **MALFORMED** row, and for
those `c00` alone is not enough — a mutant silencing only the MALFORMED site
satisfies the consequence with a live verdict site. Those four — `A8`, `A23`,
`A25` and `A30`, whose `a fence opened … and never closed` row is a MALFORMED
row too — carry `ctl:c00,m02` and require the MALFORMED site alive as well.
`m02` reports through the double-open branch, which none of these ablations
touch. (`grep -c '^ablate .*ctl:c00,m02' run.sh` is the check, and it returns 4. The
anchor matters: without it the count is 5, because the explanatory comment above
the ablations names the spec too — a needle that matches its own documentation.)

An **empty** `ctl:` spec is refused as loudly as a missing one. `ablate`'s guard
tests only the prefix, so a bare `ctl:` would otherwise iterate zero controls
and return success — absence satisfying the assertion, inside the mechanism
built to stop exactly that. Measured: `A22` with `ctl:` instead of `ctl:c00`
passed under full silencing before the guard existed.

An absence-shaped consequence declared with **no** control is a fixture failure,
not a silent default — otherwise the next ablation added reopens the hole.

The sibling fixture `tests/fixtures/installer-release-guard/` was audited for the
same class and is **structurally immune**: both of its dispositions assert a
filesystem side-effect (`REFUSE` requires the destination to be untouched;
`INSTALL` requires the installed copy to exist and `cmp` equal) alongside an exit
code, so no case there is satisfied by a report that went quiet. That is the
`canary:` shape, which is why it is the right answer wherever it is available.

The suite takes about 90 seconds — the slowest check in this repo. Nearly all of
it is 29 ablations each running the full seed.

## The rejected predicate: un-escape `\|` everywhere

The first version un-escaped `\|` in every extracted command, on the reasoning
that GFM forces the escape and shell never wants it. Running it against
agent-ready-papers — a repo with 18 memory files and annotations more hostile
than anything here — refuted it in one command:

```
awk -F'|' '/^\| P[0-9]+ \|/{n++; if (NF!=8) bad++} END{…}' memory/priorities.md
```

That check is correct and passing. It is *not* in a table, and its `\|` is awk's
own escape for a literal pipe. Un-escaping it produced `/^| P[0-9]+ |/` — an
alternation with an empty operand — and reported **FAIL on a healthy claim**,
the direction that trains a reader to ignore the step.

Un-escaping is a GFM concern, so it belongs only to GFM's context: the runner
does it on table rows and nowhere else. `p13` is that regression, and `A9` is
the ablation proving the restriction is load-bearing. Do not widen it back
without a case that shows the prose form still survives.

`A9`'s consequence is asserted as "`p13` stops being PASS" rather than "`p13`
becomes FAIL", because which one it becomes depends on the local `awk`: mawk
rejects the empty alternation outright, busybox awk accepts it and returns a
wrong answer. An ablation whose consequence holds only under one awk is an
ablation that quietly stops proving anything on someone else's machine.

## What three rounds of review added

Every draft passed its own fixture completely before the next round refuted it.
That is the whole argument for the rule: an artifact passes every check its
author thought to run, because the author picked the checks and the artifact
from one mental model.

**Round 1** — four lenses over the first draft:

| Found | Now seeded as |
|-------|---------------|
| Backtick command substitution deleted from the command | `p14`, `A12` |
| stderr merged into stdout, arriving first and masking `CANNOT VERIFY` | `p15`, `A13` |
| One unclosed fence in an early file blanking every later file | `a-unclosed.md`, `A10` |
| No file arguments → reads stdin and hangs forever | `S1` |
| An unreadable operand invisible in the reconciliation line | `S2` |
| A forked child holding the output pipe open | `p17` |
| `~~~` fences executed as live annotations | `n07`, `A11` |
| GFM's legal pipe-less table form missing the un-escape | `p16`, `p28`, `A17` |
| `Manual` (older capitalisation) executed as shell | `p19`, `A14` |
| 127 after partial output scored FAIL rather than ERROR | `p08`, `A16` |
| Exit status always 0, whatever the run found | `S1`–`S6` |

**Round 2**, over the rewrite — including two defects the round-1 fixes
*created*, which is why a second round exists at all:

| Found | Now seeded as |
|-------|---------------|
| A `` ``` `` inside a four-backtick block read as a fence close — created by round 1's `~~~` fix | `n08`, `n09`, `A18` |
| A fence indented more than three spaces no longer recognised — created by round 2's fence rewrite | `n10`, `A26` |
| `istable` firing on any pipe earlier in the line, resurrecting the rejected `\|` predicate | `p27`, `A17` |
| `---` under any pipe-bearing line read as a table delimiter | `p29`, `A27` |
| One stray backtick silently deleting an annotation | `m03`, `A23` |
| A second `<!-- verify:` on a line supplying the first one's `-->` | `m02`, `A19` |
| An empty annotation silently dropped | `m04`, `A25` |
| A real command named `manual-…` filed as a note | `p21`, `A21` |
| `<!-- VERIFY:` invisible to the extractor *and* to the reconciliation count | `p22`, `A22` |
| A backgrounded child writing into the next command's output file | `M2`, `M2a` |
| A directory operand passing the readability guard | `M3` |
| A manual-only or unreachable-only run reporting all-clear | `S5`, `S6` |
| The 30s timeout: a shipped disposition with no case at all | `M1`, `M1a` |
| Adopters' `… \|\| echo FAIL` — this guide's own idiom — scoring PASS | `p20`, `p31`, `A20`, `A28` |

## Three defects the fixture cannot catch

The first two are properties of the *commands*, not the runner, so they are
stated as writing rules in the skill instead. The third is a limit of the
extractor, stated as a blind spot in the same step:

- **A failure branch that exits 0** — `… && echo OK || echo NOTAG` is a false
  PASS with the evidence of its own failure printed beside it. `docs/GUIDE.md`
  shipped one in its worked example from v1.9.0 until this release.
- **A command that assumes a working directory** — `git ls-remote origin`
  passed from the project root and reported ERROR one directory over. The runner
  can be invoked from anywhere; commands must address their target absolutely.
- **An annotation inside a four-space-indented code block with no fence at all,
  or inside a blockquote**, is indistinguishable from a live one and will run.
  Skipping every four-space-indented line would silently drop annotations in
  nested list items, and dropping a live claim is the worse failure of the two —
  so the extractor runs them and the step says so. Write examples in fenced
  blocks; indented *fences* are recognised (`n10`), bare indentation is not.

**Round 3**, over the second rewrite. Two of these are the round-2 fixes' own
doing, and the first is the worst defect any round produced — documentation
executing as shell:

| Found | Now seeded as |
|-------|---------------|
| A CommonMark **double-backtick** code span mis-paired, so the annotation inside it *ran* | `n11`, `A2` |
| An unclosed fence *within* a file silently dropping every later claim — round 1 fixed only the cross-file case | `u01`, `A30` |
| `intbl` outliving its table, un-escaping `\|` in the bullet after it — the rejected predicate by a third route | `p33`, `A29` |
| `---` under a pipe-bearing line read as a delimiter — the same predicate by a fourth | `p34`, `A27` |
| MALFORMED firing on any `<!--`, so a command grepping for an HTML marker never ran (a live annotation in an adopter repo) | `p32`, `A19` |
| The odd-backtick rule false-positiving on ordinary prose, including this repo's own CHANGELOG | removed; correct span pairing replaces it |
| `ran N of M` counting MANUAL claims as run, when MANUAL means nothing ran | the summary now separates ran / manual / malformed / documentation |
| `A25` a null ablation — its mutation broke awk outright, so "the row disappeared" was satisfied by a dead runner | `A25` rewritten; `norow:`/`notrow:` now also require the summary line |

The round-3 lens also measured the shipped runner against real adopter memory
trees, which is what the hostile-repo rule asks for and what no fixture can
substitute for. `disentangled-infrastructure` reports **0 pass, 8 error** — every
annotation it has — because its guards are silent by design. That is the
`no output → ERROR` rule meeting four months of annotations written before it
existed, and it is the reason this release's adopter action is not "none".

The same round found four defects in the round-3 runner itself, one of which was
the round-3 fix doing exactly what this design forbids: a precomputed
"documentation" residual on the summary line, meant to save the reader an
accounting step, which went negative on some inputs and — worse — absorbed
genuine extractor misses into the bucket labelled "expected explanation". It was
removed rather than corrected. The reader does the accounting; that is the whole
point of the reconciliation line.
