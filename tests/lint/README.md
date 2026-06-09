# Lint tests

Deterministic structural checks for this repo. No LLM in the loop. Run before commit or as a session-start sanity check.

```bash
bash tests/lint/run.sh
```

Exits `0` on pass, non-zero on any failure. Each failure prints what drifted and where.

## What each rule catches

| Rule | Drift mode | Example failure |
|------|-----------|-----------------|
| **1. CLAUDE.md path references resolve** | A file gets renamed or deleted, but `CLAUDE.md` still points at the old path | `FAIL  CLAUDE.md references \`docs/old-guide.md\` but it does not exist` |
| **2. memory/MEMORY.md index integrity** | A `memory/project_*.md` file is added but never linked from `MEMORY.md` (orphan), or `MEMORY.md` links to a file that does not exist (stale link) | `FAIL  memory/project_X.md exists but is not referenced in MEMORY.md` |
| **3. Skill template embedded frontmatter** | A skill-shape template (curate, audit-context, test-verify-memory) loses its embedded `name:`/`description:` lines inside the `SAVE AS: .claude/skills/...` comment, breaking installation for adopters | `FAIL  templates/curate.md: skill template missing \`name:\` in SAVE AS comment` |
| **4. Top-level YAML frontmatter closure** | A template starting with `---` loses its closing `---`, leaving the file unparseable as YAML+markdown | `FAIL  templates/project-file.md: opens with \`---\` but no closing \`---\` within first 30 lines` |

## What this lint deliberately does *not* check

- **Semantic pairing between Hard Constraints and Before You Start.** The two sections serve different functions (rules vs. trigger-action routing); forcing 1:1 would impose editorial structure that does not match how the sections actually work.
- **Version pin coherence.** Templates' `framework: agent-ready-projects vX.Y.Z` frontmatter is allowed to lag the current repo version intentionally — bumping every template on every release would be noise.
- **Content correctness.** Whether a template's *content* is good, accurate, or up-to-date is the job of `/audit-context` and review, not lint.
- **LLM-driven behavioral testing.** That is Phase C (multi-vendor reviewer battery + per-trick behavioral fixtures). The single existing behavioral test is `templates/test-verify-memory.md`.

## Adding a new rule

1. Add a new section `echo "[N/M] description"` block in `run.sh`
2. Use `fail "..."` for any violation found; rule should not set or modify `$ISSUES` directly
3. Smoke-test against the current repo (should pass)
4. Verify it catches the drift it claims to catch by temporarily breaking the relevant file
5. Document the rule in the table above

Keep rules deterministic and cheap. Anything LLM-in-the-loop belongs in `tests/behavioral/` (when that exists), not here.
