# Physics Test Templates

A family of test-scaffolding templates for physics simulation code. Sibling to the LLM-based theory-verification family in [`agent-ready-papers/templates/physics-verification/`](https://github.com/ducroq/agent-ready-papers/tree/master/templates/physics-verification).

## Why this family exists

Physics simulation code has failure modes ordinary unit tests don't catch:

- Integrator drift (energy slowly bleeds out of a Hamiltonian system)
- Wrong order of accuracy (a "fourth-order" RK4 actually first-order)
- Sign errors that look fine for one cycle
- Forces with wrong asymptotic behaviour
- Conservation laws silently violated under driving
- Bugs that survive your own tests because the same misconception infected the test

These templates target each class explicitly, organised into tiers per the [verification tier hierarchy](https://github.com/ducroq/agent-ready-papers/blob/master/templates/physics-verification/verification-tier-hierarchy.md).

## Template index

| Template | Tier | Status | What it catches |
|---|---|---|---|
| [`physics-test-skeleton.md`](physics-test-skeleton.md) | 1–3 | Shipped | Energy conservation, integrator convergence, time reversal, force invariants, conservation under driving |
| [`intercomparison-test-template.md`](intercomparison-test-template.md) | 5 | Shipped | **Highest leverage** — bugs your own tests are blind to (shared misconceptions). Run same scenario in two independent solvers. |
| [`mms-test-template.md`](mms-test-template.md) | 4 | Shipped | Method of Manufactured Solutions — wrong order of accuracy, discretization errors |
| [`conservation-log-template.md`](conservation-log-template.md) | 3 | Shipped | Symplectic / energy-stable integrator + per-step conservation diagnostic with drift plot |

## How to use

Each template provides copy-paste pytest scaffolding plus a worked example. The expected adoption pattern:

1. Read [`verification-tier-hierarchy.md`](https://github.com/ducroq/agent-ready-papers/blob/master/templates/physics-verification/verification-tier-hierarchy.md) to understand which tier each test exercises.
2. Adopt `physics-test-skeleton.md` first — it sets up the conftest fixtures every other template builds on.
3. Add tier-4 (MMS), tier-5 (intercomparison), and tier-3 conservation diagnostics as the simulation matures.
4. Each test file documents what tier it exercises and what error class it catches.

## Provenance

- **Triggering case study:** Driven Pendulum project, 2026-04-06 / 2026-05-04. Bare-pendulum simulation passed all the tests its author thought to write but had no test for "does this match Hodzelmans 2017 measured data" or "does an independent second integrator give the same answer." See [driven-pendulum's archive README](https://github.com/ducroq/driven-pendulum/blob/master/sim/archive_v2_bare_pendulum/README.md).
- **Investigation:** Survey of mainstream V&V practice (ASME V&V 10/20/40, Roache's MMS, SciML.jl ecosystem testing patterns, Geant4 physics validation, climate model intercomparison). The single highest-leverage finding: **independent-implementation cross-check** — by definition, a verifier run on your own code cannot find a misconception you also embedded in your tests.

## Relationship to the rest of the framework

| Layer | What | Where |
|---|---|---|
| Theory verification | LLM-based document checks for physics claims | `agent-ready-papers/templates/physics-verification/` |
| **Code verification (this folder)** | **Runtime physics tests, MMS, intercomparison, conservation diagnostics** | `agent-ready-projects/templates/physics-tests/` |
| Process | Quality gates, claim registry, anti-hallucination | `agent-ready-papers/` framework body |
| Ordinary code testing | Unit tests for non-physics code | Standard pytest patterns; nothing physics-specific |

The templates here cover Tiers 1–5 of the verification hierarchy. Tier 0 (lightweight LLM checks) lives in `agent-ready-papers`; Tier 6 (experimental validation) is project-specific; Tier 7 (formal verification) is documented as an opt-in advanced tier in `agent-ready-papers/templates/physics-verification/lean-as-optional-tier.md` (planned).
