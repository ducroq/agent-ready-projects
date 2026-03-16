# [Project Name]

<!-- SAVE AS: CLAUDE.md (Claude Code), AGENTS.md (Codex), .windsurfrules (Windsurf),
     .github/copilot-instructions.md (Copilot), .cursor/rules/*.mdc (Cursor),
     or .aider.conf.yml (Aider). See templates/README.md for details. -->

<!-- 3-5 lines: what this is, who it's for, what it does -->

[One-line description of the project.]

- **Stack**: [e.g., Python 3.12, FastAPI, PostgreSQL]
- **Status**: [e.g., Production / MVP / Prototype]
- **Repo**: [e.g., github.com/org/project]
- **agent-ready-projects**: v1.1.0 <!-- framework version — check CHANGELOG for updates -->

## Before You Start

<!-- Task-triggered pointers — not just "this exists" but "when doing X, read Y" -->

| When | Read |
|------|------|
| Making architectural decisions | `docs/adr/README.md` — decision index |
| Changing deployment or infra | `docs/RUNBOOK.md` — operational how-to |
| Stuck or debugging something weird | `memory/gotcha-log.md` — problem-fix archive |
| Ending a session | `memory/gotcha-log.md` — review, promote patterns, retire stale entries |

## Hard Constraints

<!-- The non-negotiables. Things that must always be true. -->

- [ constraint 1 ]
- [ constraint 2 ]

## Architecture

<!-- How the pieces fit together. Doesn't need to be exhaustive — just enough
     for an agent to know where to look and what depends on what. -->

```
[ simple diagram or directory tree ]
```

## Key Paths

<!-- The 10-15 files an agent is most likely to need -->

| Path | What it is |
|------|-----------|
| `src/main.py` | Entry point |
| `config/` | All configuration |
| `tests/` | Test suite |

## How to Work Here

<!-- The commands an agent needs to develop, test, and deploy -->

```bash
# Run tests
[ test command ]

# Run locally
[ dev server command ]

# Deploy
[ deploy command ]
```

## Commit Conventions

<!-- Optional: if you have specific commit message formats -->

[ e.g., conventional commits, imperative mood, etc. ]
