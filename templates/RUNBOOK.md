# Runbook

<!-- Operational principles + how-to. Loaded via the project file's "Before You Start" table.
     Keep the most critical commands (test, deploy) in the project file as a summary —
     this file has the full operational detail. -->

## Principles

<!-- Opinionated, actionable, non-obvious guidelines.
     Bad: "write good code" (vague), "test your code" (obvious)
     Good: "pipeline reliability > feature richness" (opinionated + actionable) -->

- [ principle 1 — why it matters ]
- [ principle 2 — why it matters ]

## Local Development

<!-- How to set up and run the project locally -->

### Prerequisites

- [ required tools and versions ]

### Setup

```bash
[ setup commands ]
```

### Running

```bash
[ run commands ]
```

## Deployment

<!-- How to deploy, what to check before and after -->

### Pre-deploy checklist

- [ ] Tests pass
- [ ] [ other checks ]

### Deploy steps

```bash
[ deploy commands ]
```

### Post-deploy verification

- [ what to check after deploying ]

## Adding a New [Extension Point]

<!-- Replace with your project's main extension point:
     "Adding a New Source", "Adding a New API Endpoint", etc. -->

1. [ step 1 ]
2. [ step 2 ]
3. [ step 3 ]

## Common Problems

<!-- Operational debugging — "if you see X, try Y" -->

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| [ symptom ] | [ cause ] | [ fix ] |

## Documentation Practices

<!-- What goes where, when to update -->

| Type of change | Update |
|---------------|--------|
| New constraint or principle | Project file |
| Operational process change | This file (RUNBOOK.md) |
| Hit a weird bug | `memory/gotcha-log.md` |
| Chose between approaches | New ADR + update index |
| Learned something non-obvious | Relevant memory topic file |
