# Verification Rationale

**Status:** Reference
**Last updated:** 2026-05-29
**Issue:** #15

This framework's verification patterns — the QA checklist's multi-layer gate, the anti-hallucination tier discipline, the writing-guide language calibration, the self-verifying memory mechanism — share three structural principles. Naming them once here lets every template and every downstream consumer cite one rule instead of restating several. It also makes future decisions about adding, skipping, or composing verification layers decidable rather than ad-hoc.

This is a design-discussion doc. The principles belong in rationale, not in templates or slash commands. The anchor doc (`agent-ready-papers/docs/category-theory-as-design-lens.md`) warns: *if you find yourself reaching for category-theory vocabulary inside the codebase, you have gone too far.* The framing carries; the vocabulary does not need to.

## Principle 1: Multi-pass verification is a limit of functors

Each verification layer is a different view of the artifact, preserving some structural information and discarding other. The combined verification is what survives every layer. Layers are partial *by construction*, not by accident. The battery's strength is not redundancy but invariant coverage.

This names what `templates/checklists/qa-checklist.md` already does in plain language. The Git Reality Check preserves diff-vs-claim correspondence. The Minimum Findings Requirement preserves adversarial-review depth. The Code Quality, Documentation, and Deployment Readiness sections each preserve invariants the others do not. The battery's strength is that no single layer alone could substitute for the rest.

The decision rules the framing makes explicit:

- **Adding a verification layer** requires showing it preserves invariants the existing layers do not. Otherwise it is redundant.
- **Skipping a layer** requires showing its invariants are preserved elsewhere in the battery. Otherwise it weakens the limit.
- **Retiring a layer** requires showing its invariants no longer matter in the current scope (e.g., a deployment-readiness check has no purchase on a docs-only PR).

The upstream sibling is `agent-ready-papers/decisions/DR-011_multi-model-review-pattern.md`, which applies the same principle to a three-pass manuscript review (intra-family small, intra-family large, cross-vendor) with explicit invariant-by-pass breakdown.

## Principle 2: Citation drift is tier-monotonicity failure

The language tier used in any artifact must be at most the confidence tier in the evidence chain. ESTABLISHED language ("demonstrates," "shows") for SUPPORTED evidence is the failure case the principle subsumes. So is leaving language at "demonstrates" when the evidence chain only supports "found in this sample."

This names what `docs/vv/writing-guide.md` and `docs/vv/anti-hallucination.md` already enforce as several separate rules of thumb. The principle subsumes them:

- *Verify primary sources, not intermediate analysis files* is the rule that the registry tier itself must reflect the actual evidence chain.
- *Map confidence tier to article language explicitly* is the monotonicity rule applied to the language→tier mapping at write time.
- *Downshift language when a quote does not survive primary-source verification* is the rule applied at review time.

The decision rule: for every load-bearing claim, the reviewer's first check is whether the language sits at or below the registered tier. If not, either upgrade the registry (with new evidence) or downshift the language. Domain-specific rules (Framework Component language, Overclaiming categories, Special Cases) are projections of the same rule onto particular claim types.

The upstream sibling is `agent-ready-papers/templates/writing-guide.md`, which states the principle directly above the tier-to-language table.

## Principle 3: Validation is compositional, not monolithic

Verification of a complex artifact factors as the composition of verifications of its parts. The decomposition is the design choice. Monolithic verification ("one big check") is the failure mode.

This is the principle that organizes the layered memory system. `memory/MEMORY.md` indexes topic files, each scoped to one concern. `docs/decisions/ADR-001-in-repo-memory-over-auto-memory.md` is the composition decision for *where* memory lives. `docs/self-verifying-memory.md` is the per-entry verification mechanism: each state claim carries the command that proves it true. The composition is per-entry verification, per-topic curation, per-session audit. Each layer composes onto the next. A failure at any layer is a failure of the limit.

The decision rule: when designing a new verification surface, the question is *what decomposition makes the surface auditable*. Asking "does this look right?" is not a verification. Asking "what specific commands prove each component is in the claimed state?" is the compositional rephrasing.

## Where this framing does not apply

The framing belongs in design rationale. It does not belong in templates, slash commands, or user-facing guidance. The framework patterns it does *not* organize:

- **Task-triggered pointers** (cognitive ergonomics — reducing the cost of reaching the right artifact at the right moment; not a composition problem).
- **Before-You-Start tables** (UX — first-load wayfinding; not a structural-verification problem).
- **Versioning and CHANGELOG discipline** (process — chronology and attribution; not a structural property of the artifact).

Reaching for the framing in these places is the failure mode the anchor doc warns about. If a pattern's job is to reduce cognitive cost or coordinate humans, the principles here do not help and may distort it.

## References

- [`agent-ready-papers/docs/category-theory-as-design-lens.md`](https://github.com/ducroq/agent-ready-papers/blob/master/docs/category-theory-as-design-lens.md) — upstream anchor. Five operational principles, three of which are adopted here.
- [`agent-ready-papers/templates/writing-guide.md`](https://github.com/ducroq/agent-ready-papers/blob/master/templates/writing-guide.md) — principle 2 stated in the upstream template (added via `agent-ready-papers#12`).
- [`agent-ready-papers/decisions/DR-011_multi-model-review-pattern.md`](https://github.com/ducroq/agent-ready-papers/blob/master/decisions/DR-011_multi-model-review-pattern.md) — principle 1 applied to manuscript review, with explicit invariant-by-pass breakdown (added via `agent-ready-papers#13`).
- `docs/vv/anti-hallucination.md` — principle 2 in operational use.
- `docs/vv/writing-guide.md` — principle 2 in operational use.
- `templates/checklists/qa-checklist.md` — principle 1 in operational use.
- `docs/self-verifying-memory.md` — principle 3 in operational use.
- `docs/decisions/ADR-001-in-repo-memory-over-auto-memory.md` — composition decision for the memory system; principle 3 in operational use.
