# Experiments: pre-commitment log

Bets that produce numbers. Ported in shape from FyE's `experiments/`, which took it from Augur's
ADR-007. The point: **a script, not good intentions, should catch a criterion edited after the
result arrived.**

| File | Role |
|------|------|
| `backlog.md` | One `## EXP-NNN` section per experiment: method, predictions, decision rule. Written and committed **before** any data is read. The commit that pins it is recorded in the experiment's hypothesis-log entry; never edit a section after that. |
| `artifacts/` | JSON the runner emits. Aggregates only: no project names, search strings or transcript text (this repo is public). |

Raw data lives off-repo in `lab/experiments/<date>-<name>/` (the gitignored symlink to
`~/lab/agent-ready-projects`). A registry of concluded experiments and an auditor that checks
each section against its pinned commit are deferred until EXP-001 concludes.
