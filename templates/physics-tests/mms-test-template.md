# Method of Manufactured Solutions Template (Tier 4)

<!-- TEMPLATE: Pytest scaffolding for the Method of Manufactured
     Solutions (MMS), a verification technique that decouples code
     correctness from physical modelling. You manufacture a smooth
     function, derive the forcing term that would make it a solution
     of your equation, run the code with that forcing, and check the
     numerical solution converges to your manufactured function at
     the formal order of accuracy.

     USAGE:
     - Adopt alongside `physics-test-skeleton.md`
     - For each governing equation in your simulation, write one MMS
       test
     - Run with `pytest tests/physics/test_mms.py -v`

     ORIGIN: Created May 2026. Method of Manufactured Solutions is a
     long-established technique in computational physics, formalised
     by Roache (2002) for CFD. Tier 4 in the verification-tier
     hierarchy. The cleanest test of code correctness because the
     manufactured solution does not need to be physically meaningful
     — only mathematically valid.

     KEY INSIGHT: MMS tests the integrator's *order of accuracy*, not
     just whether it converges. A first-order error in a "fourth-order"
     RK4 implementation passes property tests and even passes
     intercomparison if the reference also has the same first-order
     error. MMS catches it because the convergence rate is exact:
     halving dt should reduce error by 16× for a fourth-order method,
     by 4× for a second-order method. -->

This template provides scaffolding for the Method of Manufactured Solutions (MMS), a verification technique introduced by Roache for CFD and adopted across computational physics. It catches discretization errors and integration-order errors that property tests and intercomparison cannot.

## The MMS procedure

1. **Manufacture a solution.** Choose any smooth function $u_{\text{manuf}}(x, t)$ with the right shape (vector for ODEs, field for PDEs). It need not be physically meaningful. Common choices: $u = \sin(\omega t)$, $u = e^{-\alpha t} \cos(\beta t)$, low-degree polynomials.

2. **Derive the forcing term.** Substitute $u_{\text{manuf}}$ into your governing equation. The residual — what's left after substitution — becomes the source/forcing term $f(x, t)$ that, if added to the equation, would make $u_{\text{manuf}}$ an exact solution.

   For an ODE $\ddot{\theta} + 2\beta\dot{\theta} + \omega_0^2 \theta = f(t)$, choosing $\theta_{\text{manuf}}(t) = \sin(\Omega t)$ gives $f(t) = -\Omega^2 \sin(\Omega t) + 2\beta\Omega\cos(\Omega t) + \omega_0^2 \sin(\Omega t)$.

3. **Run the simulation with that forcing.** Pass $f(t)$ as the external driving term in your code.

4. **Compare numerical to manufactured.** Compute $\| u_{\text{numerical}} - u_{\text{manuf}} \|$ at multiple resolutions $h$ (or $dt$). The error must decrease at the formal order of accuracy of your scheme.

5. **Verify the observed order matches the formal order.** For RK4: error $\propto dt^4$. Halving $dt$ should reduce error by 16×.

## What MMS catches

| Error class | Caught by MMS? | Why |
|---|---|---|
| Wrong integrator coefficient (typo in RK4 Butcher tableau) | **Yes** | Manifests as wrong order of accuracy |
| First-order term implemented as second-order (or vice versa) | **Yes** | Convergence rate diagnostic |
| Sign error in EoM | **Yes (usually)** | Numerical solution diverges from manufactured |
| Off-by-one in array indexing | **Yes** | Manifests as boundary or initial-condition error |
| Wrong physical model | **No** | MMS tests code, not model |
| Forcing-term derivation error | **No** | If you derive $f$ wrong, MMS tests against the wrong target |

## Suggested layout

```
tests/physics/
  test_mms.py
```

## Test pattern (Python, ODE example)

```python
"""test_mms.py — Tier 4.

Method of Manufactured Solutions for the pendulum EoM. Verifies the
integrator achieves its formal order of accuracy.

For each governing equation in your simulation, manufacture a smooth
solution, derive the forcing analytically, run the code with that
forcing, verify convergence rate."""
import numpy as np
import pytest
import sympy as sp


# --- Manufacture the solution and derive the forcing ---

def manufactured_solution_and_forcing(beta, omega_0):
    """For theta_ddot + 2*beta*theta_dot + omega_0^2 * theta = f(t),
    manufacture theta_manuf(t) = A * sin(Omega * t) and derive f(t).
    Returns (theta_manuf, f) as Python callables."""
    A = 0.05  # rad
    Omega = 7.0  # rad/s; chosen to be different from omega_0 to avoid resonance
    
    # Symbolic derivation
    t_sym = sp.Symbol('t', real=True)
    theta_manuf_sym = A * sp.sin(Omega * t_sym)
    theta_dot_sym = sp.diff(theta_manuf_sym, t_sym)
    theta_ddot_sym = sp.diff(theta_dot_sym, t_sym)
    
    f_sym = theta_ddot_sym + 2 * beta * theta_dot_sym + omega_0**2 * theta_manuf_sym
    
    # Convert to Python callables
    theta_manuf = sp.lambdify(t_sym, theta_manuf_sym, modules='numpy')
    theta_dot_manuf = sp.lambdify(t_sym, theta_dot_sym, modules='numpy')
    f = sp.lambdify(t_sym, f_sym, modules='numpy')
    
    return theta_manuf, theta_dot_manuf, f


# --- The MMS test ---

def test_mms_convergence_order(integrator, standard_params):
    """Run with manufactured forcing at multiple step sizes;
    verify error decreases at the formal order of accuracy.
    
    Tier 4. Catches: wrong integrator order, integrator coefficient typos."""
    from sim.pendulum import PendulumState
    
    p = standard_params
    theta_manuf, theta_dot_manuf, f = manufactured_solution_and_forcing(p.beta, p.omega_0)
    
    # Initial condition matching the manufactured solution at t=0
    initial = PendulumState(theta=theta_manuf(0.0), theta_dot=theta_dot_manuf(0.0))
    
    t_end = 1.0  # short enough that the manufactured solution doesn't blow up
    
    # Run at three resolutions; record max error
    errors = []
    dts = [1e-3, 5e-4, 2.5e-4]
    
    for dt in dts:
        # Adapt: your simulate() needs a way to accept the manufactured forcing
        # Pseudocode below — bind to your project's API
        traj = integrator_with_external_forcing(initial, p, t_end, dt, f)
        
        theta_expected = theta_manuf(traj["t"])
        max_err = np.max(np.abs(traj["theta"] - theta_expected))
        errors.append(max_err)
    
    # Convergence rate: should be ~16x for RK4 (4th order) per dt halving
    rate_1 = errors[0] / errors[1]
    rate_2 = errors[1] / errors[2]
    
    # Allow factor-of-2 slack — true rate is 16, accept [8, 32]
    assert 8 < rate_1 < 32, (
        f"MMS convergence (RK4 expected 16x): dt halving 1 gave {rate_1:.1f}x error reduction\n"
        f"This indicates the integrator is NOT achieving its formal order of accuracy."
    )
    assert 8 < rate_2 < 32, (
        f"MMS convergence (RK4 expected 16x): dt halving 2 gave {rate_2:.1f}x"
    )
    
    # Also verify error itself is small at the finest dt
    assert errors[-1] < 1e-7, (
        f"MMS final error at dt={dts[-1]}: {errors[-1]:.2e} (expected < 1e-7 for RK4)"
    )


def integrator_with_external_forcing(initial, params, t_end, dt, f):
    """Wrap your project's simulate() to accept an arbitrary forcing function f(t).
    Adapt this to your code's API."""
    raise NotImplementedError(
        "Bind to your project's simulate() with external forcing. "
        "If your code only supports EM-pulse forcing, you may need to add an "
        "'external_torque(t)' parameter for MMS testing."
    )
```

## Worked example: applied to driven-pendulum's RK4

The archived `pendulum.py` uses a fixed-step RK4 integrator. An MMS test would:

- Choose $\theta_{\text{manuf}}(t) = 0.05 \sin(7 t)$ rad (small enough for the linearised EoM, frequency away from $\omega_0 \approx 6.28$ rad/s to avoid resonance).
- Symbolically derive the forcing $f(t) = -49 \cdot 0.05 \sin(7t) + 2\beta \cdot 7 \cdot 0.05 \cos(7t) + \omega_0^2 \cdot 0.05 \sin(7t)$.
- Run the simulation with this $f(t)$ as the external torque.
- Compare $\theta_{\text{numerical}}(t)$ to $\theta_{\text{manuf}}(t)$ at $dt = 10^{-3}, 5 \times 10^{-4}, 2.5 \times 10^{-4}$.
- Expect 16× error reduction per halving of $dt$. If observed reduction is closer to 4×, the integrator is implemented as second-order rather than fourth-order — a clear bug, even if the code "looks right."

To enable this, the existing `simulate()` would need to accept an arbitrary forcing function (currently it only accepts EM-pulse forcing via `magnet`/`coil`/`pulse` parameters). Adding an `external_torque: Callable[[float], float]` parameter is a small refactor that pays for itself the first time MMS catches an integration-order regression.

## Why MMS is sometimes considered overkill

MMS requires:
- Symbolic derivation of the forcing (manageable with `sympy`)
- An API for arbitrary forcing functions (a small refactor)
- Multiple runs at different timesteps (more compute)

In return, it catches a class of bugs no other tier can: **wrong order of accuracy**. A "fourth-order" RK4 that has been silently downgraded to second-order will pass property tests, intercomparison, and even experimental validation in many regimes — but will fail to converge at the rate it claims. For numerical work where convergence rate is part of the deliverable (papers, simulation studies), MMS is non-negotiable.

For an engineering simulation where the goal is "the answer at a known dt," MMS is optional but cheap insurance.

## Limitations

- **Tests code, not model.** MMS verifies the implementation matches the equation; it does not verify the equation matches reality. Modelling errors require Tier 6 (experimental).
- **Forcing-term derivation can be error-prone.** A mistake in deriving $f$ produces a wrong target and the test passes for the wrong reason. Use `sympy` to derive symbolically; do not hand-derive complex forcings.
- **Choose the manufactured solution carefully.** Avoid resonance ($\Omega \approx \omega_0$); keep amplitude small if your EoM is linearised; keep $t_{\text{end}}$ short enough that the manufactured solution doesn't blow up the integrator.
- **Boundary conditions.** For PDEs, the manufactured solution generally won't satisfy your code's natural boundary conditions. You'll need to either choose a manufactured solution that does, or add boundary forcing terms — both add complexity.
- **Cost.** Three runs at progressively finer dt at, say, 4× the cost each. For long simulations this matters.

## Sources

- Roache, P.J. (2002). "Code Verification by the Method of Manufactured Solutions." *J. Fluids Eng.*, 124(1), 4–10. The defining paper.
- Roache, P.J. (1998). *Verification and Validation in Computational Science and Engineering*. Hermosa Publishers. The expanded treatment.
- Roy, C.J. (2005). "Review of Code and Solution Verification Procedures for Computational Simulation." *J. Comput. Phys.*, 205(1), 131–156.
- Salari, K., Knupp, P. (2000). "Code Verification by the Method of Manufactured Solutions." Sandia National Labs report SAND2000-1444.
- ASME V&V 10 §5.3 (Code Verification by MMS).
- `verification-tier-hierarchy.md` Tier 4.
