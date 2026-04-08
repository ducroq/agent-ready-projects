# Adopting the Method

Three agent-facing prompts: **assess** (should I use this?), **adopt** (set it up), and **update** (am I behind?). Copy the one you need, paste it into your AI coding agent (Claude Code, Codex, Cursor, Windsurf, Copilot, Aider — any of them), and let it do the work.

## 1. Assess — "Should I use this?"

Use this first if you're not sure whether the method fits your project. The agent will analyze your repo and give you a concrete recommendation.

### Prompt

```
Read the guide at https://github.com/ducroq/agent-ready-projects/blob/master/README.md

Then analyze THIS repo — its structure, existing documentation, size, complexity, and how agent sessions currently work here. Based on what you find, answer:

1. **Current state**: What context engineering does this project already have? (project files, READMEs, CLAUDE.md, AGENTS.md, .windsurfrules, ADRs, etc.) What's working? What's missing?

2. **Pain points**: Based on the codebase structure, where would an agent most likely struggle without persistent context? (complex subsystems, non-obvious conventions, deployment quirks, fragile areas, cross-cutting concerns)

3. **Recommendation**: Would the layered memory method help here? Which layers would have the most impact?
   - Project file (Layer 1) — how much is there to capture?
   - Runbook (Layer 2) — is there operational complexity worth documenting?
   - Memory index + topic files (Layer 3) — are there enough subsystems to warrant splitting?
   - Gotcha log (Layer 4) — is this the kind of project where things go wrong in non-obvious ways?

4. **Effort estimate**: What's the minimum viable setup — which files, roughly how much content, and what should go in each?

5. **Skip if**: Any reasons this project might NOT benefit (too small, too simple, single-session scope, etc.)

Don't generate any files yet — just give me the analysis so I can decide.
```

## 2. Adopt — "Set it up for me"

Use this when you're ready. The agent reads the guide, analyzes your repo, and scaffolds everything — tailored to your actual project, not blank templates.

### Prompt

```
Read the guide at https://github.com/ducroq/agent-ready-projects/blob/master/README.md
Also read the templates at:
- https://github.com/ducroq/agent-ready-projects/blob/master/templates/project-file.md
- https://github.com/ducroq/agent-ready-projects/blob/master/templates/memory-index.md
- https://github.com/ducroq/agent-ready-projects/blob/master/templates/gotcha-log.md
- https://github.com/ducroq/agent-ready-projects/blob/master/templates/RUNBOOK.md
- https://github.com/ducroq/agent-ready-projects/blob/master/templates/curate.md
- https://github.com/ducroq/agent-ready-projects/blob/master/templates/audit-context.md

Now analyze THIS repo thoroughly — read the codebase structure, existing docs, config files, test setup, deployment scripts, CI/CD, and recent git history. Then scaffold the layered memory system for this project:

STEP 1 — Determine the right tool.
Check what AI coding agent files already exist (.claude/, CLAUDE.md, AGENTS.md, .cursor/, .windsurfrules, .github/copilot-instructions.md, .aider.conf.yml). Use the matching convention. If nothing exists, ask me which tool I'm using.

STEP 2 — Create the project file (Layer 1).
Save as the tool-appropriate filename. Fill in:
- Project identity (what this is, stack, status) — derive from the code
- An `agent-ready-projects: vX.Y.Z` line in the header metadata, using the version from the guide's README (look for "Version X.Y.Z" near the top). This lets the project track which framework version it adopted.
- "Before You Start" table with task-triggered pointers to docs that exist in this repo
- Hard constraints — infer from existing docs, CI config, linting rules, or ask me
- Architecture sketch — derive from directory structure and imports
- Key paths — the files an agent would need most
- How to work here — derive from package.json scripts, Makefile, CI config, etc.

STEP 3 — Create a gotcha log.
Save as gotcha-log.md in the appropriate location (memory/ for Claude Code, docs/ for others). Use the template structure. Leave it empty but ready — the first real entry will come from the next session.

STEP 4 — If the tool supports auto-memory (currently Claude Code): create the memory index.
Save as MEMORY.md. Fill in:
- Topic file index (even if there's only the gotcha log to start)
- Current project state — derive from git log and repo state
- Key file paths — supplement what's in the project file
- Recently Promoted section (empty, ready for the self-learning loop)

STEP 5 — Assess whether a runbook is needed.
If the project has deployment steps, multiple environments, CI/CD, or operational complexity: create docs/RUNBOOK.md with the operational detail. If it's a simple project with one test command and no deployment, skip this.

STEP 6 — Install skills.
For Claude Code: save both skill templates as .claude/skills/curate/SKILL.md and .claude/skills/audit-context/SKILL.md (with the frontmatter from the template comments). This gives the user /curate for end-of-session curation and /audit-context for periodic structural audits. Update the project file's "Before You Start" table to include: "Ending a session → Run /curate" and "Monthly or after major restructuring → Run /audit-context".
For other tools: note in the project file that end-of-session curation should be done by pasting the curate template as a prompt, and periodic audits by pasting the audit-context template.

STEP 7 — Report what you created.
List every file, what's in it, and one thing where I should review your work and adjust if needed (constraints you might have inferred incorrectly, architecture choices that need my context, etc.).

Important:
- Derive content from the actual codebase — don't leave placeholders where you can fill in real values
- Don't over-document — only capture what an agent would actually need
- Use task-triggered language in all pointers ("when doing X, read Y" not just "see Y")
- If the memory/ directory is user-specific (not shared across team members), add it to .gitignore
- If something is ambiguous or you're unsure, ask me rather than guessing
```

## 3. Update — "Am I behind?"

Use this when the framework has been updated and you want to bring an adopted project up to date.

### Prompt

```
Read the changelog at https://github.com/ducroq/agent-ready-projects/blob/master/CHANGELOG.md

Then check THIS repo's project file for the `agent-ready-projects` version line. Compare the adopted version against the latest version in the changelog.

PART 1 — VERSION DRIFT

If we're behind:
1. List what changed between our version and the latest
2. For each change, assess whether it applies to this project (not every change matters to every project)
3. Propose specific updates to our project file, memory index, gotcha log, or runbook — only what's relevant
4. Update the `agent-ready-projects` version line to the new version

If we're current, just confirm and continue to Part 2.

PART 2 — STRUCTURAL HEALTH

Whether or not the version changed, audit the quality of the current adoption by running the /audit-context skill (or, if not installed, follow the audit-context template at https://github.com/ducroq/agent-ready-projects/blob/master/templates/audit-context.md).

Report all findings before making changes. Group by severity:
- **Fix now**: broken references, misplaced secrets/credentials, orphaned files
- **Fix soon**: duplication, bloated auto-loaded files, passive pointer language
- **Consider**: minor size optimizations, optional restructuring

Don't make changes without showing me the plan first.
```

## Tips

- **Run the assess prompt first** if you've never used context engineering. It takes 30 seconds and tells you whether it's worth the setup.
- **The adopt prompt works best in a fresh session** — the agent needs context window space to read the guide and analyze your repo.
- **Review what the agent generates.** The project file especially — the agent derives constraints and architecture from code, but you know things the code doesn't say. Spend 5 minutes reviewing and adjusting what needs context only you have.
- **The self-learning loop starts automatically.** Once the files exist, just follow the rhythm: log gotchas during work, curate at end-of-session (5 minutes). The system gets better from there.
