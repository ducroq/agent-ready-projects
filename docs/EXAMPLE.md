# Worked Example: Task Tracker API

What populated files actually look like for a mid-size project — a REST API with a React frontend, PostgreSQL database, and CI/CD pipeline. This is illustrative, not prescriptive. Your project's content will differ, but the structure and tone should feel familiar.

## Project file (CLAUDE.md / AGENTS.md / etc.)

```markdown
# Task Tracker API

A REST API for managing tasks and projects, with a React frontend and PostgreSQL backend. Used by ~200 internal users. Deployed to staging automatically on merge, production on tag.

- **Stack**: Express.js, TypeScript, React, PostgreSQL 15, Redis
- **Status**: Production (v2.3.1)
- **Repo**: github.com/example/task-tracker
- **agent-ready-projects**: v1.1.0

## Before You Start

| When | Read |
|------|------|
| Making architectural decisions | `docs/adr/README.md` — index of 8 ADRs |
| Changing API endpoints or response shapes | `docs/RUNBOOK.md` — versioning policy, backwards compatibility rules |
| Stuck or debugging something weird | `memory/gotcha-log.md` — problem-fix archive |
| Touching auth or permissions | `memory/auth-patterns.md` — RBAC model, token lifecycle |
| Ending a session | `memory/gotcha-log.md` — review, promote patterns, retire stale entries |

## Hard Constraints

- Never modify migration files after they've been deployed to staging — create a new migration instead
- Never expose internal IDs in API responses — use UUIDs from the `public_id` column
- Never skip tests. If tests fail, fix them or explain why they should change.
- Never claim tests pass without running them. Never claim a file exists without reading it.
- All API endpoints must return consistent error shapes: `{ error: string, code: string, details?: object }`

## Decision Framework

Before completing a task, self-assess:
- **PASS**: Tests pass, constraints respected, code matches project patterns
- **REVIEW**: Works but touches auth, migrations, or public API — flag for human review
- **FAIL**: Tests fail, constraints violated, or approach contradicts an ADR — stop and discuss

## Architecture

- **API**: Express.js + TypeScript, `src/api/`
- **Frontend**: React + Vite, `src/frontend/`
- **Database**: PostgreSQL 15, migrations in `src/db/migrations/`
- **Auth**: JWT with refresh tokens, RBAC via `role` column on `users` table
- **Queue**: Bull + Redis for async jobs (email notifications, report generation)

## Key Paths

| Path | What it is |
|------|-----------|
| `src/api/routes/` | API route definitions |
| `src/api/middleware/` | Auth, validation, error handling |
| `src/db/migrations/` | Knex migrations (never modify deployed ones) |
| `src/frontend/src/components/` | React components |
| `tests/` | Jest tests (unit + integration) |

## How to Work Here

```bash
# Run tests
npm test                      # unit tests
npm run test:integration      # needs local Postgres

# Run locally
docker-compose up && npm run dev

# Migrations
npx knex migrate:latest       # never migrate:rollback in staging/prod
```

## Commit Conventions

Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`
```

## Memory index (MEMORY.md) — for tools with auto-memory

```markdown
<!-- Loaded every session. Topic files loaded on demand. -->

## Topic Files

| File | When to load | Key insight |
|------|-------------|-------------|
| `memory/api-quirks.md` | Working on API endpoints | Rate limiting gotchas, pagination edge cases |
| `memory/auth-patterns.md` | Touching auth or permissions | RBAC model, token refresh flow |
| `memory/gotcha-log.md` | Stuck or debugging | Problem-fix archive |

## Current State

- v2.3.1 shipped, v2.4 in progress (adding team workspaces)
- Migration to Bull v5 blocked on Redis 7 upgrade (ops ticket INFRA-234)
- Frontend bundle size regression under investigation

## Recently Promoted

- If creating a migration, always pull latest first — timestamp collisions cause ordering issues. Promoted from gotcha-log 2026-01-30.

## Key File Paths

| Path | Why it matters |
|------|---------------|
| `src/api/middleware/auth.ts` | JWT validation + RBAC checks — touch carefully |
| `src/db/knexfile.ts` | Database config for all environments |
| `docker-compose.yml` | Local dev setup — Postgres + Redis |

## Active Decisions

- ADR-005: Chose UUIDs over sequential IDs for public API (security + portability)
- ADR-007: Chose Bull over Agenda for job queue (Redis already in stack)
```

## Gotcha log

```markdown
# Gotcha Log

### Integration tests hang on CI (2026-02-15)
**Problem**: `npm run test:integration` passes locally but hangs on GitHub Actions.
**Root cause**: CI uses a shared Postgres instance. Tests don't clean up transactions, causing lock contention.
**Fix**: Wrapped each test in a transaction that rolls back. Added `afterEach` cleanup hook.

### Knex migration ordering surprise (2026-01-22)
**Problem**: New migration ran before an older one that hadn't been committed yet.
**Root cause**: Knex sorts migrations by filename. Two developers created migrations on different branches with timestamps that interleaved.
**Fix**: Team convention: always pull latest migrations before creating a new one. Added CI check that validates migration order.
**Status**: [PROMOTED] → added to RUNBOOK.md as "Before creating a migration" checklist item, and to MEMORY.md's Recently Promoted section.

### Redis connection pool exhaustion (2026-03-01)
**Problem**: API returned 503s under load. Bull jobs backed up.
**Root cause**: Default connection pool size (5) was too small for concurrent job processing.
**Fix**: Increased pool to 20, added connection pool monitoring to health endpoint.
**Status**: [RESOLVED] — pool size is now in environment config with sensible defaults.
```

## What to notice

- **The project file is ~50 lines** and follows the template structure: metadata header → Before You Start → Hard Constraints → Decision Framework → Architecture → Key Paths (table) → How to Work Here (bash block) → Commit Conventions.
- **"Before You Start" comes before "Hard Constraints."** It's the primary navigation mechanism — the first thing an agent scans to decide what to load.
- **Hard constraints include honesty constraints.** "Never claim tests pass without running them" prevents the most common agent failure mode: confidently asserting something that isn't true.
- **The decision framework gives agents a self-assessment rubric.** Without it, agents optimize for whatever seems reasonable. With it, they flag auth changes for review instead of shipping them silently.
- **The memory index is ~30 lines** with full paths in the topic index. It has sections the template defines: Topic Files, Current State, Recently Promoted, Key File Paths, Active Decisions.
- **The gotcha log shows the lifecycle.** One entry is active (CI hang — current workaround). One is promoted (migration ordering → runbook + memory index). One is resolved (Redis pool → fixed). Status tags: `[PROMOTED]` means the lesson was moved up the stack. `[RESOLVED]` means the root cause was fixed.
- **This example intentionally omits** a runbook, ADRs, and topic files. A real project at this maturity level would likely have all three. The example focuses on the three core files to keep it digestible.
- **None of these files are exhaustive.** They capture what an agent needs to avoid mistakes and find context — not everything the team knows.
