# Test Verify Memory

<!-- SAVE AS: .claude/skills/test-verify-memory/SKILL.md (Claude Code)

     Tests the self-verifying memory protocol from the curate skill (Step 0.5).
     Uses fixture files with known expected outcomes to validate that the agent
     correctly detects claim types, runs verify commands, and reports results.

     Claude Code skills require SKILL.md as the entry point inside a
     named directory under .claude/skills/. Add frontmatter:
     ---
     name: test-verify-memory
     description: Test the self-verifying memory protocol against fixture files
     disable-model-invocation: false
     --- -->

Test the self-verifying memory protocol (curate Step 0, sub-step 5) against fixture files with known expected outcomes.

## Setup

Copy the test fixtures into a temporary location:

```
cp -r templates/test-fixtures/memory/ /tmp/test-verify-memory/
```

If this project doesn't have the fixtures, fetch them from the [agent-ready-projects](https://github.com/ducroq/agent-ready-projects) repository under `templates/test-fixtures/memory/`.

## Test protocol

For each `.md` file in the fixture directory, run the curate verification logic from Step 0 sub-step 5:

1. Read the file
2. Detect whether it contains a state claim (trigger words: "shipped," "deployed," "live," "running," "working in production")
3. If it's a state claim, check for a `<!-- verify: ... -->` comment
4. If a verify command exists, run it **with the runner shipped in curate Step 0 sub-step 5** — not with an implementation written here, which is the defect that step exists to prevent
5. Classify the outcome against that step's disposition table

Steps 4 and 5 are deliberately not restated here. This test measures whether the
protocol classifies these eleven fixtures correctly; if it also carried its own
copy of the dispositions, a change to the step would leave the test asserting the
old ones and reporting green.

## Expected results

| Fixture file | Expected claim type | Expected outcome |
|---|---|---|
| `verified-pass.md` | State ("deployed") | **PASS** — verify command runs, outputs PASS |
| `verified-fail.md` | State ("shipped," "running") | **FAIL** — verify command runs, prints what it found, exits non-zero |
| `verified-error.md` | State ("deployed") | **ERROR** — the verify command's tool is gone (exit 127); nothing was proved either way |
| `verified-manual.md` | State ("deployed") | **MANUAL CHECK NEEDED** — has `<!-- verify: manual — ... -->` |
| `verified-cannot-verify.md` | State ("running") | **CANNOT VERIFY** — guarded command, target unreachable, output begins `CANNOT VERIFY:` |
| `unverified-state.md` | State ("deployed," "running") | **UNVERIFIED** — state claim without verify comment |
| `unverified-live.md` | State ("live") | **UNVERIFIED** — exercises the "live" trigger word |
| `unverified-working-in-production.md` | State ("working in production") | **UNVERIFIED** — exercises the multi-word trigger phrase |
| `decision-no-verify.md` | Decision ("chose") | **SKIP** — not a state claim, no verification needed |
| `observation-no-verify.md` | Observation ("during session," "tested") | **SKIP** — not a state claim, no verification needed |
| `pattern-no-verify.md` | Pattern ("always," "when X") | **SKIP** — not a state claim, no verification needed |

## Execution

Process each fixture and compare actual outcome against expected:

```
PASS  verified-pass.md       — expected: PASS, got: ___
PASS  verified-fail.md       — expected: FAIL, got: ___
PASS  verified-error.md      — expected: ERROR, got: ___
PASS  verified-manual.md     — expected: MANUAL CHECK NEEDED, got: ___
PASS  verified-cannot-verify.md — expected: CANNOT VERIFY, got: ___
PASS  unverified-state.md    — expected: UNVERIFIED, got: ___
PASS  unverified-live.md     — expected: UNVERIFIED, got: ___
PASS  unverified-working-in-production.md — expected: UNVERIFIED, got: ___
PASS  decision-no-verify.md  — expected: SKIP, got: ___
PASS  observation-no-verify.md — expected: SKIP, got: ___
PASS  pattern-no-verify.md   — expected: SKIP, got: ___
```

Replace `PASS` with `FAIL` if the actual outcome doesn't match expected.

## Report

Summarize:
- **Total fixtures**: 11
- **Passed**: N/11
- **Failed**: N/11 (list each with expected vs actual)

If all 11 pass, the curate verification protocol is working correctly for these cases.

If any fail, diagnose:
- **False positive** (flagged a non-state claim as state): the trigger-word detection is too broad
- **False negative** (missed a state claim): the trigger-word detection is too narrow
- **Wrong outcome** (detected the claim but misclassified the verify status): the verify-command parsing needs attention
- **CANNOT VERIFY scored as PASS**: the guarded command exits 0 and its output contains no `FAIL`, so anything keying on the exit code alone reads it as a pass. That is the failure this fixture exists to catch — an unreachable check reported as a satisfied one. The disposition must come from the `CANNOT VERIFY:` prefix, not from the exit status
- **A fixture scored by a word in its output**: if `verified-fail.md` reports FAIL because the string `FAIL` appeared somewhere in its prose, the protocol is reading verdicts out of text. The runner *does* read stdout, deliberately, and it is worth knowing exactly where rather than counting: a `CANNOT VERIFY` prefix sets that disposition; a first line of exactly `FAIL` **at exit 0** is rescored as a failure and annotated as a legacy verdict word; a first line merely *beginning* `FAIL` at exit 0 is left as-is but carries an advisory note; and empty output is `ERROR` whatever the exit status, because a command that printed nothing proved nothing. Everything else comes from the exit status. That third case will annotate genuine prose — `echo "FAILED to reach host"; exit 0` earns the note — so the fixtures are written to keep those signals apart from the claim's own content

## Cleanup

```
rm -rf /tmp/test-verify-memory/
```
