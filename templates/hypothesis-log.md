# Hypothesis Log

<!-- SAVE AS: docs/hypothesis-log.md (project repo)

     The hypothesis log captures provisional positions whose evidence
     lives in the future. It complements the gotcha log (problems
     encountered & solved) and ADRs (decisions accepted, with rationale
     frozen) by giving a home to bets you've placed but haven't yet
     resolved.

     Why this matters: the falsification criterion is pinned BEFORE the
     data lands, which is hard discipline against post-hoc
     rationalization. Every entry forces you to write down what
     evidence would change your mind, what failure-mode signal you'd
     watch for, and what date you'll revisit by. -->

Provisional design decisions under observation. Each entry is a position taken where the evidence to confirm or revise it lives in the future. Different from:

- **`docs/TODO`** / issue tracker — tasks with an owner, ready to execute
- **ADRs** — decisions accepted, with rationale frozen
- **`memory/gotcha-log.md`** — problems encountered & solved

Lifecycle: **open** → dormant → revisit (with evidence) → resolved (close or promote to ADR).

**How to use this file:**

- Add an entry when you take a provisional position you want to revisit later.
- Each entry has a `Review by:` date and a `Revisit trigger:` so the agent can surface due items at session start and in `/curate`.
- The **Method** field pins the falsification criterion *before* the data lands — that's the whole point. Don't loosen Method when the answer arrives; if you want to redefine the bet, open a new entry.
- When an entry is resolved (ratified, revised, or no longer relevant), move it to the `## Resolved` section at the bottom with a one-line outcome.
- Keep entries tight. If an entry grows a plan, it becomes a TODO; if it grows a rationale, it becomes an ADR.

## Entry template

```markdown
### [YYYY-MM-DD] One-sentence position

**Position (provisional):** What you're betting on, with concrete forecasts (numbers, ranges, dates). Cite the evidence that motivates the bet.

**Alternative:** The failure mode you'd see if the position is wrong, with a *signal* — not just "it could fail." A useful Alternative tells future-you exactly what observation would refute the Position.

**Method:** How you'll test it later. Pre-commit the falsification criterion. Often a small code snippet or a checklist of observations to compare against the forecasts in Position.

**Revisit trigger:** What event causes the entry to become reviewable. Prefer evidence triggers ("once 7 days of cycles complete") over calendar triggers when the data drives the decision.

**Review by:** YYYY-MM-DD — backstop date. The agent flags entries past this in `/curate`.

**Domain:** Tags for filtering (e.g. "API rate limits", "ML training", "deployment")
**Status:** open | open (low priority) | open (blocked on X) | dormant
```

---

## Open

*(populate with project-specific entries)*

---

## Resolved

### [YYYY-MM-DD] One-sentence position

**Outcome:** One-line result. Confirmed / refuted / nuanced (with a brief why). Link to the ADR or commit if the resolution produced one.
