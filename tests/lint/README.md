# Lint tests

Deterministic structural checks for this repo. No LLM in the loop. Run before commit or as a session-start sanity check.

```bash
bash tests/lint/run.sh
```

Exits `0` on pass, non-zero on any failure. Each failure prints what drifted and where.

## What each rule catches

| Rule | Drift mode | Example failure |
|------|-----------|-----------------|
| **1. CLAUDE.md path references resolve** | A file gets renamed or deleted, but `CLAUDE.md` still points at the old path. Gitignored maintainer dirs (`.claude/`, `memory/`) are exempt when absent — they are documented in `CLAUDE.md` but intentionally not shipped, so a fresh clone lacking them is not drift. | `FAIL  CLAUDE.md references \`docs/old-guide.md\` but it does not exist` |
| **2. memory/MEMORY.md index integrity** | A `memory/project_*.md` file is added but never linked from `MEMORY.md` (orphan), or `MEMORY.md` links to a file that does not exist (stale link) | `FAIL  memory/project_X.md exists but is not referenced in MEMORY.md` |
| **3. Skill template embedded frontmatter** | A skill-shape template (curate, audit-context, test-verify-memory) loses its embedded `name:`/`description:` lines inside the `SAVE AS: .claude/skills/...` comment, breaking installation for adopters | `FAIL  templates/curate.md: skill template missing \`name:\` in SAVE AS comment` |
| **4. Installed skills are loadable** | A reference install in `.claude/skills/` has no `SKILL.md`, no frontmatter, unclosed frontmatter, a `name:` that disagrees with its directory, or an empty `description:` — any of which makes it register as nothing, silently | `FAIL  .claude/skills/curate/SKILL.md: no YAML frontmatter — will not register as a skill` |
| **5. Top-level YAML frontmatter closure** | A template starting with `---` loses its closing `---`, leaving the file unparseable as YAML+markdown | `FAIL  templates/project-file.md: opens with \`---\` but no closing \`---\` within first 30 lines` |
| **6. Template ↔ reference install agree** | An edit lands in `templates/<name>.md` or in `.claude/skills/<name>/SKILL.md` but not the other. Rules 3 and 4 check each side alone; `install-global-skills.sh --check` compares the global install to the tracked one, so both read as current while diverging from the template. Implemented in `skill-sync.sh`, which compares the body and the **whole** frontmatter block — not a list of known keys, so an unanticipated field (`allowed-tools:`, `model:`) or a duplicated one is caught too | `FAIL  curate: body differs from templates/curate.md in 2 line(s); first: > ...` |
| **7. A skill that provisions a canonical row quotes it** | A file that tells an agent to *create* an artifact describes it by category instead of quoting it, so the agent writes the category wording. Rule 6 cannot see this: in #42 both `audit-context` copies agreed with each other and contradicted `templates/project-file.md`. Provisioning sections declare themselves with `<!-- provisions: memory-index-row -->`; the canonical trigger is derived from the row whose target is the memory index, never hardcoded. Implemented in `provision-quote.sh`; fixture at `tests/fixtures/provisioning-quote/` (9 positives, 4 negatives) | `FAIL  adopt.md provisions the memory-index row under "STEP 4 …" without quoting the canonical trigger "Picking up where the last session left off"` |
| **8. Adopter-facing templates have not grown** | A template gets longer and nobody notices what it costs. Two surfaces, charged differently: always-loaded files (project file, memory index) every session, and skill bodies every invocation — `/curate` runs every session, so its body is effectively a per-session cost. `templates/curate.md` grew 11,358 → 37,971 bytes over eight releases with no instrument reporting it. A **ratchet**, not a budget: no threshold invented, growth fails, shrinkage fails until locked in with `--update`, so the recorded number only goes down. Implemented in `size-ratchet.sh`; baseline in `size-baseline.tsv`; fixture at `tests/fixtures/size-ratchet/` (4 positives, 4 negatives, 2 structural) | `FAIL  templates/curate.md grew 37971 -> 39120 bytes (+1149)` |
| **9. No bare `$0`–`$9` in a skill body** | Skill **arguments** are substituted into the skill **body** between the file and the model, so a bare `$0` in an embedded awk program ships as the first argument word. That is #77: `review-changes` Step 1.5 examined a constant and printed what a clean run prints, and `curate`'s verify runner **executed** mangled commands. No other instrument here could see it — rule 6 compared two files carrying the same `$0`, which agreed, and every fixture extracts the program and runs it directly, with substitution nowhere on the path. Lexical is the only instrument available. The safe form depends on context and all three are needed: `$(N)` in awk, `${N}` in shell, `\$N` in prose — `${0}` and `\$0` are both awk syntax errors, and shell `$(1)` fails *silently* at rc 0. Scope is derived from the `SAVE AS` predicate (any `templates/**/*.md` carrying the marker, or any `.claude/skills/**/SKILL.md`), so `tests/**` and the LaTeX in `templates/physics-tests/` are out. Implemented in `dollar-digit.sh`; fixture at `tests/fixtures/dollar-digit/` | ``FAIL  templates/curate.md:112: bare `$0` in a skill body is delivered as an argument word`` |

## What this lint deliberately does *not* check

- **Semantic pairing between Hard Constraints and Before You Start.** The two sections serve different functions (rules vs. trigger-action routing); forcing 1:1 would impose editorial structure that does not match how the sections actually work.
- **Version pin coherence.** Templates' `framework: agent-ready-projects vX.Y.Z` frontmatter is not checked here, because deciding whether a given version string should track the current release or is a deliberately dated snapshot needs judgment a deterministic rule can't supply. That does *not* mean the stamps may drift freely — the position changed in v1.14.0, after `templates/project-file.md` and `templates/coordination.md` sat at v1.10.0 for three minors. `project-file.md` ships a "Before You Start" row telling the agent to compare its own stamp against the changelog and report drift, so a stale stamp there makes a new adopter's first session report drift against content that is in fact current. Keeping the stamps honest is now `templates/release.md` Step 5's job, not lint's.
- **Content correctness.** Whether a template's *content* is good, accurate, or up-to-date is the job of `/audit-context` and review, not lint.
- **LLM-driven behavioral testing.** That is Phase C (multi-vendor reviewer battery + per-trick behavioral fixtures). The single existing behavioral test is `templates/test-verify-memory.md`.

## Rule 6 and its fixture

Rule 6 lives in `skill-sync.sh` rather than inline, so that `tests/fixtures/skill-template-sync/run.sh` can drive it against seeded drift:

```bash
bash tests/fixtures/skill-template-sync/run.sh
```

**17 positives** — drift in `description`, `name`, `disable-model-invocation`, a field outside those three, a duplicated field, a quoting-only change; a template-only body edit, an install-only one, a deleted step, a mid-body edit; an install with no template and a template with no install; a `-->` in the `SAVE AS` prose and a `---` opening one, both of which truncate the comment; a stray unterminated `<!--` above the block; a demoted H1; and one asserting the reported first-differing line carries content.

**7 negatives** — three for divergence that is there **by design** (the `SAVE AS` comment, the H1, leading/trailing blank lines), plus a clean-pair control, the one named install-less template, a CRLF pair, and an unterminated `<!--` in *body* prose identical on both sides.

A case declared `HIT1` asserts the seeded defect produces **exactly one** violation. A needle match alone cannot see bogus lines reported alongside the right one, and that blindness hid a real defect: a truncated `SAVE AS` comment emitted its accurate diagnostic *and* leaked the frontmatter into the body comparison as a second, spurious violation.

Every guard is confirmed load-bearing by ablation rather than assumed — each row below was measured, not reasoned:

| Ablation | Result |
|---|---|
| `trim_blank` → `cat` | 8 cases fail |
| Strip *every* HTML comment, not just `SAVE AS` | `audit-context` and `curate` go permanently red — both quote `<!-- verify: -->` in running prose |
| Drop the awk `END` flush | N7 fails: an unterminated `<!--` silently truncates the template body, so the pair reads as drift *and* every later edit becomes invisible |
| Decide `save` from any line in the block, not the opening line | P15 fails: a stray `<!--` above the block swallows the real prose |
| Drop `tr -d '\r'` | N6 fails |
| First-diff excerpt → plain first line | P2b fails: an append's first differing line is the blank separator |
| Compare the body even when the template could not be parsed | P12 and P14 fail with a second, spurious violation |

The fixture also asserts the checker's coverage line reached stderr rather than inferring "it ran" from silence. On its first run it never executed the check at all — the script was not executable and `2>/dev/null || true` swallowed the error — and **every negative passed anyway**, because "expect no violation" is satisfied byte-for-byte by a checker that did nothing. Only the positives failed. Keep that asymmetry in mind when adding cases: a negative cannot detect a dead harness. (The mode bit was incidental — both callers invoke `bash <path>`, so the durable fix is the coverage-line assertion, in the fixture *and* in `run.sh` rule 6.)

## Rule 9 and its fixture

```bash
bash tests/fixtures/dollar-digit/run.sh
```

**The shape is the point.** All eight occurrences the rule found on master were `#` comment lines *inside a fenced* ```` ```bash ```` *block*. A first draft of this fixture seeded bare lines with no fence and no comments — so the two exemptions a maintainer would plausibly add (skip fenced regions, skip comment lines) passed the entire suite while silently un-fixing #77. `mktree` now builds the real shape and A6/A7 ablate it.

**13 positives** — the real shape (a bare `$0` in a comment inside a fence); `$0` as awk's whole-line variable; `$1`; `$9`; one in bare prose; one in a reference install; `\\$0` (an *even* backslash run does not escape the dollar); `$0` at start of line; `$10`; two live occurrences on one line asserted separately; a bare `$0` beside a named `$BASE`; and a skill template one directory down.

**12 negatives** — `$(0)`, `${0}`, `\$0`, `$@`, named variables, `$`/`$$`/`$x` with no digit, `\\\$0` (an *odd* run does escape), LaTeX in a top-level non-skill template, LaTeX in a nested one, a `templates/*.md` with no `SAVE AS` marker, a `tests/` helper, and a clean control.

**7 structural** — zero skill bodies found must exit 2, not report clean (the rule-6 "0 pair(s) compared" trap); a missing root must refuse rather than sweep the cwd; the reported line must equal the line the defect is actually on, asserted against `grep -n` rather than a hardcoded number; a **stubbed awk must exit 2**, not report clean; an **unreadable candidate must exit 2**, because the `SAVE AS` grep fails on it exactly as it fails on a non-skill and would drop a real skill body in silence; an **unreadable directory must exit 2**, because `find` skips it, warns, and exits 1, and a pipeline to `sort` discards all three; and a **symlinked `.claude/skills` must be descended**, which needs `find -H` — without it the whole reference-install tree drops out at rc 0.

**5 truth-table cases** pin the remedy the error message prints, because the first draft offered `$(N)`, `${N}` and `\$N` interchangeably and two of the three are wrong in any given context:

| written | in an awk program | in a shell snippet |
|---|---|---|
| `$(N)` | correct | `$(1)` runs `1` as a command — empty output, **rc 0, silent** |
| `${N}` | **syntax error, rc 2** | correct |
| `\$N` | **syntax error, rc 2** | a literal `$1`, not the parameter |

Measured on mawk 1.3.4 and bash 5; the cases re-measure it on every run, so the advice cannot rot into wrong advice. The message now says `$(N)` in awk, `${N}` in shell, `\$N` in prose — which is also what `templates/curate.md` already said when it called `$(0)` the only form correct on both the delivery path and the extraction path.

**10 ablations**, each naming the case it must move and in which direction — a mutant that merely breaks differently is a FAIL, not a PASS:

| Ablation | Consequence it must produce |
|---|---|
| Backslash *parity* → "any backslash escapes" | `\\$0` stops being reported — a live `$0` goes silent |
| Parity test made unsatisfiable | `\$0` becomes a false positive |
| Drop the `SAVE AS` predicate | LaTeX `$10^4$` in a non-skill template is reported |
| Point the install glob at a name that does not exist | `.claude/skills/**/SKILL.md` stops being scanned |
| Digit test → "any character" | `$BASE` is reported |
| **Add** a fenced-block exemption | the real-shape positive stops being reported |
| **Add** a comment-line exemption | the real-shape positive stops being reported |
| Discard awk's exit status | a stubbed `awk` reads as clean: coverage line, rc 0 |
| Drop the readability guard | an unreadable skill body is dropped in silence at rc 0 |
| Discard `find`'s status and stderr | a `chmod 000` subdirectory is skipped in silence at rc 0 |

The last three run outside the `ablate` helper on purpose: their consequences are "the mutant goes green" and "the mutant exits 2", and `ablate` rejects both by design. They carry their own aliveness proof instead.

**Every ablation co-seeds a CONTROL defect the mutant must still report, and that — not the coverage line — is what makes them mean anything.** The first draft asserted only the coverage line, which closes the *crash* form of a dead checker and not the *silence* form: a checker that still lists, reads, runs awk, prints its coverage line and exits 0 while reporting nothing satisfies every CLEAN-direction ablation by absence. Measured twice, one round apart. First draft: no coverage assertion, two ablations passed against a neutered scan loop. Second draft, coverage assertion added: mutating one `printf` to `if (0) printf` failed all 13 positives and still **passed six of nine ablations, including all four CLEAN ones**. With controls, the same mutant fails all ten, each naming the reason. That is the "a negative cannot detect a dead harness" lesson recorded for rule 6 two sections above, re-learned twice in one change — the second time inside the fix for the first.

**No prose exemption**, and the day the rule was written is the argument for it: the only bare `$N` left in any skill body were the four comment blocks *explaining #77* (eight reported lines), so the warning against `$0` was delivered as "`$(0)`, never `worktree`". Whether the substituter skips fences or code spans is **unmeasured**; requiring the escaped form everywhere is chosen so the rule does not depend on the answer.

The fixture inherits #77's blind spot by construction — it cannot substitute arguments either, so it tests the lexical rule and nothing about delivery. That limit is the reason the rule is lexical, not a gap in the fixture.

## Adding a new rule

1. Add a new section `echo "[N/M] description"` block in `run.sh`
2. Use `fail "..."` for any violation found; rule should not set or modify `$ISSUES` directly
3. Smoke-test against the current repo (should pass)
4. Verify it catches the drift it claims to catch by temporarily breaking the relevant file — a pass on a clean repo is not evidence the rule works. If the rule is non-trivial, factor it out and add a fixture with seeded true positives, as rule 6 does
5. Document the rule in the table above

Keep rules deterministic and cheap. Anything LLM-in-the-loop belongs in `tests/behavioral/` (when that exists), not here.
