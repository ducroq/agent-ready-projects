# Intercomparison Test Template (Tier 5)

<!-- TEMPLATE: Copy-paste pytest scaffolding for code-to-code
     intercomparison. Runs the same physical scenario in your code
     AND in an independent reference implementation (e.g., SciPy
     solve_ivp, Julia DifferentialEquations.jl). Asserts agreement
     within tolerance.

     USAGE:
     - Adopt alongside `physics-test-skeleton.md`
     - Identify a reference implementation that is independent of
       your code (different language, different solver, or different
       formulation)
     - For each canonical scenario, write an intercomparison test
     - Run with `pytest tests/physics/test_intercomparison.py -v`

     ORIGIN: Created May 2026. The single highest-leverage missing
     check in most physics simulation projects per the survey of
     mature V&V practice (ASME V&V 20, climate model intercomparison
     CMIP, Geant-val). Tier 5 in the verification-tier hierarchy.

     KEY INSIGHT: By definition, a verifier run on your own code
     cannot find a misconception you also embedded in your tests.
     Dimensional checks, conservation tests, golden-input tests — all
     share your model of what is correct. Independent implementation
     is the cheapest way to break out of that epistemic cage. The
     mainstream V&V community (climate models, Geant4, CFD) leans on
     this technique harder than any other. -->

This template provides pytest scaffolding for **independent-implementation cross-check** — the single highest-leverage verification technique your own tests structurally cannot perform. You run the same physics scenario in two implementations that share no code path; if they agree within tolerance, both are likely correct; if they disagree, one is wrong and the disagreement localises which.

## Why this is Tier 5, not Tier 2

A unit test pins a specific numerical output for a chosen input. If you wrote both the code and the test based on a wrong understanding (sign convention, formula, scope), the unit test passes and your bug survives. Intercomparison breaks that loop because the second implementation was written by someone else, in another language, or against another reference — its only commitment is to the *physics*, not to your encoding of it.

The cost is real (you must keep two implementations in agreement) but lower than it sounds: for ODEs, calling `scipy.integrate.solve_ivp` with a different method is enough; for PDEs, comparing FEniCS to a different mesh library; for n-body simulations, comparing direct summation to a tree code.

## Independence — what counts and what doesn't

| Independence type | Counts as independent? | Why |
|---|---|---|
| Same code, different parameters | No | Tests robustness, not correctness |
| Same code, different timestep | No | Tests convergence (Tier 4), not physics |
| Your custom RK4 vs SciPy `solve_ivp(method='RK45')` | **Yes** | Different implementation of the same ODE |
| Your custom RK4 vs SciPy `solve_ivp(method='Radau')` | **Yes** (stronger) | Different integrator family + different implementation |
| Your Python code vs Julia DifferentialEquations.jl | **Yes** (strongest practical) | Different language, different solver, different team |
| Your Newtonian formulation vs your own Lagrangian formulation | **Partial** | Same physics, but different code path catches transcription errors |
| Your simulation vs analytical solution (where one exists) | **Yes** | Strongest possible — but limited to special cases |

A practical rule: if both implementations would crash from the same bug in `import yourpackage`, they are not independent. Aim for at least "different solver, same project" as a minimum; "different language, different team" is the gold standard.

## Suggested layout

```
tests/physics/
  test_intercomparison.py     # this template
  reference/
    scipy_pendulum.py         # reference implementations live here
    ...
```

## Test pattern (Python, SciPy as reference)

```python
"""test_intercomparison.py — Tier 5.

Runs canonical scenarios in YOUR code and in SciPy `solve_ivp`,
asserts agreement within tolerance. Adapt the scenarios to your
project.

If two implementations disagree, ONE is wrong. The disagreement
localises *where* (which scenario, which observable). Investigation
required. Do not loosen tolerances to make tests pass."""
import numpy as np
import pytest
from scipy.integrate import solve_ivp


# --- Reference implementation (lives in tests/physics/reference/) ---

def scipy_free_pendulum(L, m, Q, g, theta_0, theta_dot_0, t_end, dt):
    """Free damped pendulum via scipy solve_ivp (Radau, stiff-capable)."""
    omega_0 = np.sqrt(g / L)
    beta = omega_0 / (2 * Q)
    
    def rhs(t, y):
        theta, theta_dot = y
        return [theta_dot, -2 * beta * theta_dot - (g / L) * np.sin(theta)]
    
    t_eval = np.arange(0, t_end + dt, dt)
    sol = solve_ivp(rhs, (0, t_end), [theta_0, theta_dot_0],
                    method='Radau', t_eval=t_eval, rtol=1e-10, atol=1e-12)
    return sol.t, sol.y[0], sol.y[1]


# --- Intercomparison tests ---

def test_free_pendulum_matches_scipy(integrator, standard_params):
    """Your free-pendulum integrator must match SciPy Radau on the same EoM.
    
    Tier 5. Catches: wrong integrator coefficients, sign error in EoM,
    misimplemented damping, accumulated floating-point error in your code
    that scipy doesn't have."""
    from sim.pendulum import PendulumState
    initial = PendulumState(theta=np.radians(5.0), theta_dot=0.0)
    t_end = 10.0
    dt = 1e-3
    
    # Your code
    yours = integrator(state=initial, t_end=t_end, dt=dt)
    
    # SciPy reference
    p = standard_params
    t_ref, theta_ref, _ = scipy_free_pendulum(
        L=p.L, m=p.m, Q=p.Q, g=p.g,
        theta_0=initial.theta, theta_dot_0=initial.theta_dot,
        t_end=t_end, dt=dt
    )
    
    # Compare trajectories on the common time grid
    # (SciPy and yours may have slightly different t arrays; interpolate if needed)
    max_abs_error = np.max(np.abs(yours["theta"] - theta_ref))
    
    # Tolerance: depends on integrator orders and step size.
    # For RK4 at dt=1e-3 vs Radau, expect agreement to better than 1e-5.
    assert max_abs_error < 1e-5, (
        f"Trajectory disagreement: max |theta_yours - theta_scipy| = {max_abs_error:.2e}\n"
        f"This is a real disagreement, not floating-point noise.\n"
        f"INVESTIGATE; do not loosen tolerance."
    )


def test_lock_acquisition_matches_scipy(integrator, standard_params):
    """Same scenario with EM driving — your code's lock acquisition matches SciPy.
    
    Tier 5. Catches: bugs in pulse machinery, force model, force-velocity coupling
    that pass the per-component tests in Tier 2 but compound under driving."""
    # Adapt: drive the SciPy reference with the SAME pulse profile as yours.
    # Compare phase-locked steady state (e.g., theta(t=10) within tolerance).
    pytest.skip("Adapt to your project's driven setup")


def test_against_known_analytical(integrator, standard_params):
    """For special cases with analytical solutions, compare directly.
    
    Tier 5 (strongest form). Catches everything intercomparison-with-scipy can
    catch, plus errors that SciPy might also share (e.g., common floating-point
    handling, common formula in the standard library)."""
    # Example: undamped small-amplitude pendulum. Analytical: theta(t) = theta_0 * cos(omega_0 * t)
    from sim.pendulum import PendulumState
    standard_params.Q = 1e12  # undamped
    theta_0 = np.radians(0.5)  # small angle
    omega_0 = np.sqrt(standard_params.g / standard_params.L)
    
    initial = PendulumState(theta=theta_0, theta_dot=0.0)
    t_end = 10.0
    dt = 1e-4
    
    yours = integrator(state=initial, t_end=t_end, dt=dt)
    analytical = theta_0 * np.cos(omega_0 * yours["t"])
    
    max_abs_error = np.max(np.abs(yours["theta"] - analytical))
    
    # At small angle and high precision, expect very tight agreement
    assert max_abs_error < 1e-6, (
        f"Disagreement with analytical solution: {max_abs_error:.2e}\n"
        f"Either your integrator has a bug, or your dt is too coarse for this test."
    )
```

## When intercomparison disagrees

A disagreement is a finding, not a tolerance problem. Procedure:

1. **Do not loosen the tolerance** to make the test pass. The tolerance is a feature, not a bug.
2. **Identify the discrepancy locus.** At what time does the disagreement first exceed noise? At what observable? On what initial condition?
3. **Hypothesise.** Most disagreements are sign errors, off-by-one in array indices, wrong initial condition handed to the reference, or missing terms in one of the implementations.
4. **Run a Tier 1 test** on each implementation in isolation (energy conservation, period). If one fails Tier 1 and the other passes, the failure points to the buggy implementation.
5. **Fix the bug, then re-run the test.** It should now pass at the original tolerance.

## Worked example: applied to driven-pendulum

If the archived `sim/pendulum.py` had been intercompared against `scipy.integrate.solve_ivp(method='Radau')` on the same EoM:

- **Free pendulum tests** would pass — the EoM and RK4 are correct.
- **Driven (open-loop pulsed) tests** would also pass — both implementations would compute the same trajectory and both would show amplitude decay over 300s. *Tier 5 cannot detect a modelling error.*
- **What Tier 5 would NOT catch in this case:** the absence of an escapement. Both implementations are bare-pendulum + EM; both agree; both are within scope of the same wrong-for-the-application model.

This illustrates the boundary between tiers: Tier 5 catches *implementation* errors with high power but does not catch *modelling* errors. For modelling errors, you need Tier 6 (experimental data — Hodzelmans Table 2 in this case) or Tier 0 cross-document consistency (which would have flagged the v2 doc against Ch 03's injection-locking framing).

The lesson: **adopt all the tiers you can afford.** None is sufficient on its own.

## Limitations

- **Reference implementation must be trustworthy.** Bugs in SciPy or Julia are rare but possible; for safety-critical work, prefer two implementations whose disagreement diagnoses a bug rather than blaming one a priori.
- **Disagreement localises but does not diagnose.** Knowing two trajectories diverge at $t=3$ s doesn't tell you which is wrong. You need Tier 1 tests on each implementation independently to triangulate.
- **Models, not implementations.** Tier 5 cannot catch the case where both implementations encode the same wrong model. For that, Tier 6 (experimental data) or Tier 0 (theory consistency).
- **Performance.** Reference implementations may be 10–100× slower than your custom code (SciPy's Radau is general-purpose, your RK4 is specialised). Run the intercomparison test suite less often than your full suite — perhaps as a nightly CI job rather than on every commit.

## Sources

- ASME V&V 20-2009: Standard for Verification and Validation in Computational Fluid Dynamics and Heat Transfer. Cross-code comparison is the recommended top-tier practice.
- CMIP (Coupled Model Intercomparison Project): https://wcrp-cmip.org. Foundational example of cross-model intercomparison at climate-modelling scale.
- Geant-val (Geant4 physics validation): https://geant-val.cern.ch/. Cross-version and cross-code intercomparison for particle-physics simulations.
- SciPy `solve_ivp` documentation: standard Python reference solver, useful for ODE intercomparison.
- DifferentialEquations.jl (Julia ecosystem): https://diffeq.sciml.ai. Cross-language reference for stiff and symplectic integrators.
- `verification-tier-hierarchy.md` (in `agent-ready-papers/templates/physics-verification/`): the framework that places this technique at Tier 5 and explains what it catches that lighter tiers cannot.
