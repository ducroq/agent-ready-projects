# Checklists

Lightweight validation gates for each workflow stage. Each checklist is 10-15 items — a concrete "am I done?" reference, not an enterprise compliance gate.

## Usage

Reference these from your project file's "Before You Start" table:

```markdown
| When | Read |
|------|------|
| Finishing architecture/design | `docs/checklists/architect-checklist.md` |
| Writing or reviewing tests | `docs/checklists/test-checklist.md` |
| Completing implementation | `docs/checklists/implement-checklist.md` |
| Reviewing before merge | `docs/checklists/qa-checklist.md` |
```

Or load them ad-hoc when you need a definition-of-done for any stage.

## The files

- **[`architect-checklist.md`](architect-checklist.md)** — Context validated? ADR created? Handoff-ready?
- **[`test-checklist.md`](test-checklist.md)** — Coverage targets? Edge cases? Deterministic?
- **[`implement-checklist.md`](implement-checklist.md)** — Tests pass? No untracked files? Architecture compliance?
- **[`qa-checklist.md`](qa-checklist.md)** — Git diff matches claims? Minimum findings? Deployment-ready?
