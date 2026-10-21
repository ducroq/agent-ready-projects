# Experiments: pre-commitment log

Bets that produce numbers. Ported in shape from FyE's `experiments/`, which took it from Augur's
ADR-007. The point: **a script, not good intentions, should catch a criterion edited after the
result arrived.**

| File | Role |
|------|------|
| `backlog.md` | One `## EXP-NNN` section per experiment: method, predictions, decision rule. Written and committed **before** any data is read, then pinned in `pins.tsv`; never edit a section after that. |
| `pins.tsv`, `check_pins.sh` | The lock: one sha256 per frozen section. `bash experiments/check_pins.sh` re-hashes each section (heading to the next `## EXP-`, trailing blanks dropped); exit 1 means a frozen section changed. Run it before every experiment run. EXP-002's hash was re-expressed under this rule on 2026-10-21, after its original pin was re-verified. |
| `artifacts/` | JSON the runner emits. Aggregates only: no project names, search strings or transcript text (this repo is public). |

Raw data lives off-repo in `lab/experiments/<date>-<name>/` (the gitignored symlink to
`~/lab/agent-ready-projects`). A registry of concluded experiments is deferred until EXP-003 confirms or overturns EXP-002.
