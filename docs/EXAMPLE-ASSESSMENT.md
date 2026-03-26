# Worked Example: Educational Assessment System

What populated files actually look like for a non-code project — an educational assessment framework where AI agents evaluate student reports. This demonstrates that the layered model works beyond software engineering: any domain where agents need persistent context benefits from the same structure.

**Domain**: University engineering programs, AI-assisted assessment of student project reports.

## Why this example matters

The Task Tracker API example (see [`EXAMPLE.md`](EXAMPLE.md)) shows a typical software project. This example shows a project with:
- No build system, no tests, no deployment pipeline
- Multiple independent modules (courses) sharing an assessment pattern
- Binary files (Excel, Word) alongside markdown
- Review agents as instruction documents, not code
- A ground truth principle (student-facing template is canonical)

The layered model adapts without forcing software conventions onto a non-software domain.

## Project file (CLAUDE.md)

```markdown
# Agent-Ready Assessment

Assessment frameworks, rubrics, and templates for HAN University of Applied Sciences
engineering programs. Used by tutors, coordinators, and AI agents to evaluate student
reports consistently.

- **Domain**: Higher education assessment (ML, DL, EML, thermodynamics, graduation projects)
- **Content**: Rubrics, assessment prompts, report templates, coordinator guidelines
- **Status**: Active — updated per academic year
- **agent-ready-projects**: v1.3.0

## Before You Start

| When | Read |
|------|------|
| Assessing an ML student report | `EVML/ML_Assessment_Prompt.md` — full assessment instructions |
| Assessing a DL student report | `EVML/DL_Assessment_Prompt.md` — DL-specific criteria |
| Assessing an EML student report | `eml/EML_Assessment_Prompt.md` — embedded ML, microcontroller deployment |
| Scoring a report | The module's `*_Assessment_Rubric.md` — criteria and scale |
| Before releasing an assessment to a student | `agents/audit-assessment.md` — quality gate |
| Comparing assessments for calibration | `agents/calibrate-scores.md` — inter-rater checks |
| Creating or editing a rubric | `agents/check-rubric-design.md` — structure validation |
| Creating or editing an assessment prompt | `agents/review-prompt-design.md` — safeguard checks |
| Stuck or debugging something weird | `memory/gotcha-log.md` — problem-fix archive |
| Ending a session | `memory/gotcha-log.md` — review, promote, retire |

## Hard Constraints

- Never fabricate assessment scores — always derive from the rubric criteria
- Never claim a student report meets criteria without reading the actual report content
- Never modify rubric scoring scales without coordinator approval
- DL reports require BOTH a custom CNN AND transfer learning
- Respect student privacy — anonymize when sharing assessments
```

**What's different from a software project file:**
- No build/test/deploy commands in "How to Work Here"
- "Before You Start" is heavy on assessment workflows rather than code areas
- Hard constraints are about academic integrity rather than technical safety
- The quality gate ("before releasing an assessment") is a review agent, not a test suite

## The three-document pattern

Each module has three files that work together:

```
Module directory (e.g., EVML/)
├── ML_Assessment_Prompt.md     ← Instructions (how to assess)
├── ML report assessment rubric.md  ← Criteria (how to score)
└── ML report assessment form.md    ← Output template (what to produce)
```

**Why separate them:**
- Changing a score descriptor only requires editing the rubric, not the prompt
- The form can be used by humans or agents — it's format, not instructions
- The prompt can reference the rubric by filename without embedding it (prevents drift)

**What went wrong before separation:** A 651-line DL prompt embedded the full rubric inline. Within weeks, the inline version diverged from the external rubric file — CNN visualization scoring thresholds differed by one level. An agent using the prompt scored differently than a human using the rubric for the same student work.

## Review agents as instruction documents

Review agents are markdown files that tell an AI agent how to systematically review an artifact. They're loaded on demand via the project file's routing table — not slash commands, not code, just documents.

```
agents/
├── audit-assessment.md      ← Quality gate before releasing grades
├── calibrate-scores.md      ← Compare two assessments of the same report
├── check-rubric-design.md   ← Validate rubric structure and coverage
└── review-prompt-design.md  ← Validate prompt safeguards
```

Each agent follows the same skeleton (see [`templates/review-agent.md`](../templates/review-agent.md)):

1. **Role + Operating Principles** — what it does and doesn't do
2. **Issue Categories** — typed findings with severity (e.g., `MISMATCH`, `SKIPPED`, `VAGUE`)
3. **Review Procedure** — step-by-step checks
4. **Output Format** — structured report template
5. **Self-Check** — surfaces new patterns not in the issue categories
6. **Rules** — guardrails

**Example: what the audit agent catches.** A completed assessment had Data Split scored 2 but the description text said "Data is not split" — which is score 1's text. The agent flagged it as `DESC_MISMATCH`. Same assessment had Code Quality = 1 ("missing") but Code Snippets = 4 ("good") — flagged as `CONTRADICTION`. And the comments section was empty on a borderline-pass student with six low scores — flagged as `NO_COMMENTS`.

None of these would have been caught by a human review of the final grade alone. The audit agent runs in seconds and catches mechanical errors before they reach the student.

## The self-learning loop in practice

**Session 1 findings → Agent improvements:**

| What the reviews found | New issue code added to agent |
|---|---|
| Level 0/1 overlap in rubrics (both mean "missing") | `FLOOR_DUP` in check-rubric-design |
| "Could be improved"/"sufficient" undifferentiated pairs | `SYNONYM_PAIR` in check-rubric-design |
| Excel dropdown text doesn't match rubric for score | `DESC_MISMATCH` in audit-assessment |
| Code quality = 1 but snippets = 4 | `CONTRADICTION` in audit-assessment |
| DL prompt referenced ML rubric file | `BAD_REF` in review-prompt-design |
| Rubric embedded inline in prompt | `INLINE_DUP` in review-prompt-design |

Each agent now runs a self-check at the end of every review. If it finds a pattern that doesn't fit its existing issue categories, it asks: "I found N new pattern(s). Want me to add them to my issue categories?" This closes the loop — agents improve their own review capability over time.

## Ground truth principle

When multiple artifacts describe the same thing, one must be canonical. In this project:

**The student-facing Word template is ground truth.** It defines what students are told to produce. The rubric, assessment form, Excel scoring sheet, and agent prompt all align *to the template*, not the other way around.

This was learned the hard way: a cross-artifact comparison found that the DL module had four different versions of the Introduction acceptance criteria:
- Template: 2 criteria
- Rubric: 3 criteria
- Prompt: 3 criteria (same as rubric)
- Excel: 2 criteria (but a *different* 2 than the template)

The fix: declare the template as canonical, then align everything else. The only exception: when the template itself is clearly incomplete (e.g., it asked students to "List your learning objectives" in the assignment text but didn't include it as an acceptance criterion), update the template first, then align the rest.

## Gotcha log (first session entries)

```markdown
### Level 0/1 overlap in rubric score descriptors (2026-03-26)
**Problem**: Multiple criteria had level 1 = "missing" which is identical to level 0.
**Root cause**: Natural to start level 1 with "missing" but level 0 already means that.
**Fix**: Convention — level 0 = absent from report; level 1 = attempt exists but fails
minimum threshold. Applied across all three module rubrics.
**Status**: [RESOLVED]

### Inline rubric in prompt drifts from external rubric (2026-03-26)
**Problem**: DL prompt embedded full rubric tables (651 lines). External rubric had
already diverged — CNN viz threshold at different score levels.
**Root cause**: Duplicating content without single source of truth.
**Fix**: Removed inline rubric. Prompt references external file only.
**Status**: [RESOLVED]
```

These gotchas were promoted immediately — the level 0/1 pattern became a check in the rubric design agent (`FLOOR_DUP`), and the inline duplication became a check in the prompt design agent (`INLINE_DUP`).

## Key takeaways for non-code projects

1. **The layered model works without code.** Project file, memory, gotcha log, routing table — all useful even when there's nothing to build or deploy.
2. **Review agents replace test suites.** In a code project, tests catch regressions. In a non-code project, review agents catch quality issues. Same function, different medium.
3. **Ground truth prevents drift.** When multiple artifacts describe the same thing, designate one as canonical. Update it first, align the rest.
4. **Three-document separation prevents monoliths.** Instructions, criteria, and output format in separate files — each can evolve independently.
5. **Self-learning agents surface their own gaps.** The self-check step means you don't have to notice patterns yourself — the agent asks you.
