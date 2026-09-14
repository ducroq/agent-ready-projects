# Why `curate` says what it says

Superseded drafts and the measurements that refuted them, moved out of `templates/curate.md` so that
adopters do not pay for this repo's litigation on every invocation. **The decision lives in the
skill; the argument lives here.** Nothing is duplicated between the two — if a claim appears in
both, one of them is wrong.

###    One deprecated exception, and it is the only place a word in the output changes anythin…

- This framework taught `… && echo PASS || echo FAIL` until v1.21.0, and that idiom exits 0 on its failure branch, so without this every such command in every adopter's memory files would read as a pass on upgrade.

###      The second is a false PASS with the evidence of its own failure printed beside it, an…

- Put the failure on a non-zero exit: `git rev-parse v1.2.3 >/dev/null 2>&1 && echo TAG-PRESENT || { echo TAG-MISSING; exit 1; }`.

### Step 0.8 — the prettier ignore-file cwd measurement

Moved out of the skill 2026-09-05 to pay for the #109/#110 budget rewrite. The **rule** stays in
Step 0.8: verify the exemption from the cwd the formatter actually runs in. This is the evidence.

Measured on prettier 3.8.1 (adopter) and 3.9.4 (here), with a root `.prettierignore` naming the
project file:

| run from | command | exit |
|---|---|---|
| repo root | `prettier --check CLAUDE.md` | 0 — ignored |
| repo root | `prettier --check --ignore-path /dev/null CLAUDE.md` | 1 — it does want to re-pad |
| `frontend/` | `prettier --check ../CLAUDE.md` | 1 — the ignore file is never found |

Losing format-normalization on one markdown file is a smaller cost than a third of the budget.

### Step 0.8 — the two table-padding measurements

Moved 2026-09-05. The rule stays in Step 0.8: measure the de-padded size before proposing any cut.

| project | padding reclaimed | share of file | after |
|---|---|---|---|
| table-heavy project file | 12,685 chars | **35%** of 36.3k | 23.6k, identical content and rendering |
| second project | 21,030 chars | **61%** of 34,706 | content-identical |

The first project had no session footers left to trim and only structural sections remaining, so
the step had already escalated to the engineer as a *content* decision when the real cause was
whitespace. A file whose tables hold short cells sees far less than 35%.

## v1.43.0 — never hardcode the version a probe corroborates (#136)

Two adopter estates wrote the same fix for the same shape on the same day, independently. That
convergence is the reason it shipped rather than being noted.

The shape, written from this framework's own guidance:

```bash
for s in audit-context curate update-drift; do
  git -C "$FRAMEWORK" show "v1.36.1:.claude/skills/$s/SKILL.md" \
    | diff -q - "$HOME/.claude/skills/$s/SKILL.md" >/dev/null || echo "DRIFT: $s";
done; echo "checked 3 global skills vs v1.36.1"
```

**Two independent defects in one line.**

**(a) The verdict is a word in the output.** `|| echo` swallows the failure and the trailing
`echo` sets the status, so a runner scores PASS while it prints `DRIFT` three times. Step 0.5
already forbids this, and `docs/rationale/curate.md` records that this framework *taught* it
until v1.21.0 — so it is an idiom that survived being corrected, found in an adopter's record
dated 2026-09-05.

**(b) The probe hardcodes the tag it corroborates**, giving it the lifetime of that tag rather
than of the claim. It expires at the only moment it has anything to report — when the upstream
tag moves. One estate's derived version is what caught v1.37.0: it went red at `differing: 3` on
skills that had been diff-zero the session before. The other reports it as the fifth occurrence
of the family in their repo and the **first not authored locally**.

The shipped probe derives the version from the stamp, so bumping the stamp re-arms it with no
edit and pin and probe cannot silently disagree. Every branch was executed before shipping:
clean (exit 0), a seeded drifted install (`DRIFT: curate differs from v1.42.0`, exit 1), no
stamp, a skill not installed, and outside a git repo. The `2>/dev/null` on `rev-parse` is
load-bearing — without it git's own `fatal:` prints beside the CANNOT VERIFY line and reads as
the failure.

⚠️ **The framework was still printing the forbidden idiom itself.** `templates/release.md`
carried `… && echo "TAG EXISTS — STOP" || echo "free"`, exit 0 on both branches, measured.
Defensible while only a human read it, and still the framework printing what it forbids. Replaced
in v1.43.0 with a function whose exit status carries the verdict and which distinguishes a third
outcome — 0 free, 1 taken, 2 could not be decided (offline, no origin).
