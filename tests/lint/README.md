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
| **4. Top-level YAML frontmatter closure** | A template starting with `---` loses its closing `---`, leaving the file unparseable as YAML+markdown | `FAIL  templates/project-file.md: opens with \`---\` but no closing \`---\` within first 30 lines` |

## What this lint deliberately does *not* check

- **Semantic pairing between Hard Constraints and Before You Start.** The two sections serve different functions (rules vs. trigger-action routing); forcing 1:1 would impose editorial structure that does not match how the sections actually work.
- **Version pin coherence.** Templates' `framework: agent-ready-projects vX.Y.Z` frontmatter is not checked here, because deciding whether a given version string should track the current release or is a deliberately dated snapshot needs judgment a deterministic rule can't supply. That does *not* mean the stamps may drift freely — the position changed in v1.14.0, after `templates/project-file.md` and `templates/coordination.md` sat at v1.10.0 for three minors. `project-file.md` ships a "Before You Start" row telling the agent to compare its own stamp against the changelog and report drift, so a stale stamp there makes a new adopter's first session report drift against content that is in fact current. Keeping the stamps honest is now `templates/release.md` Step 5's job, not lint's.
- **Content correctness.** Whether a template's *content* is good, accurate, or up-to-date is the job of `/audit-context` and review, not lint.
- **LLM-driven behavioral testing.** That is Phase C (multi-vendor reviewer battery + per-trick behavioral fixtures). The single existing behavioral test is `templates/test-verify-memory.md`.

## Adding a new rule

1. Add a new section `echo "[N/M] description"` block in `run.sh`
2. Use `fail "..."` for any violation found; rule should not set or modify `$ISSUES` directly
3. Smoke-test against the current repo (should pass)
4. Verify it catches the drift it claims to catch by temporarily breaking the relevant file
5. Document the rule in the table above

Keep rules deterministic and cheap. Anything LLM-in-the-loop belongs in `tests/behavioral/` (when that exists), not here.
