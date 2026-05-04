# Physics Test Skeleton (Tier 1–3)

<!-- TEMPLATE: Copy-paste pytest scaffolding for runtime physics
     verification of a simulation. Provides fixtures and tests for:
     Tier 1 (free system invariants), Tier 2 (force/field invariants),
     Tier 3 (driven system invariants and conservation under driving).

     USAGE:
     - Adopt the suggested directory layout
     - Copy the conftest.py and test_*.py templates
     - Adapt the system-specific fixtures (params, EoM) to your project
     - Run with `pytest -v`

     ORIGIN: Created May 2026 from the agent-ready-projects
     physics-tests family. Tier structure follows
     verification-tier-hierarchy.md. The driven-pendulum project's
     archived bare-pendulum simulation is the worked example: it
     would have passed Tier 2 (EM force math is correct) but failed
     Tier 3 in its application context (no escapement model). The
     skeleton makes that gap visible.

     KEY INSIGHT: Physics invariants — energy conservation, time
     reversibility, integrator convergence order — are exact, not
     statistical. Tests on invariants catch a class of bugs that
     ordinary golden-input unit tests cannot, because they hold for
     ALL inputs of the right shape, not just the test's chosen ones.
     This is what makes physics testing different from ordinary
     software testing. -->

This template provides pytest scaffolding for runtime verification of physics simulation code. It targets Tiers 1–3 of the verification tier hierarchy: free-system invariants (energy, period, ring-down Q), force/field invariants (symmetry, polarity, far-field limits), and driven-system invariants (conservation under known forcing).

## Suggested layout

```
<project>/
  <sim>/                      # your physics code
    pendulum.py               # equations of motion, integrators, force models
    coil.py                   # field/force models (if separate)
    ...
  tests/
    physics/                  # this template's home
      __init__.py
      conftest.py             # fixtures: params, integrator, expected invariants
      test_free_invariants.py # Tier 1: energy, period, ring-down, time reversal
      test_force_invariants.py # Tier 2: symmetry, polarity, asymptotic limits
      test_driven_invariants.py # Tier 3: conservation under driving, limit cycles
      README.md               # which tier each test exercises, what it catches
```

Run with: `pytest tests/physics -v`

Add to CI so every commit runs the full battery.

## conftest.py

```python
"""Shared fixtures for physics tests. Adapt the params dataclass
to your project's parameters."""
import numpy as np
import pytest

# --- Fixture 1: standard physical parameters ---

@pytest.fixture
def standard_params():
    """A representative parameter set the tests build around. Adapt to your system."""
    from sim.pendulum import PendulumParams
    return PendulumParams(L=0.248, m=0.5, Q=300.0, g=9.81)


# --- Fixture 2: integrator step size (configurable per test class) ---

@pytest.fixture
def dt_fine():
    """Step size for high-precision invariant checks."""
    return 1e-4


@pytest.fixture
def dt_coarse():
    """Step size for ordinary tests; should still be inside the
    asymptotic-convergence regime of the integrator."""
    return 1e-3


# --- Fixture 3: integrator wrapper ---

@pytest.fixture
def integrator(standard_params):
    """Returns a function (state, t_end, dt, **kwargs) -> trajectory_dict.
    Adapt this to your project's `simulate(...)` entry point."""
    from sim.pendulum import simulate, PendulumState
    def _run(state=None, t_end=10.0, dt=1e-3, **kwargs):
        if state is None:
            state = PendulumState(theta=np.radians(5.0), theta_dot=0.0)
        return simulate(state, standard_params, t_end=t_end, dt=dt, **kwargs)
    return _run


# --- Fixture 4: total mechanical energy ---

@pytest.fixture
def energy(standard_params):
    """Computes total mechanical energy E(theta, theta_dot)."""
    p = standard_params
    def _E(theta, theta_dot):
        ke = 0.5 * p.m * p.L**2 * theta_dot**2
        pe = p.m * p.g * p.L * (1 - np.cos(theta))
        return ke + pe
    return _E
```

## Tier 1: free-system invariants

```python
"""test_free_invariants.py — Tier 1.

Covers: energy conservation (undamped), exponential decay (damped),
small-angle period, circular-error correction, ring-down Q, time
reversibility. Catches: integrator drift, sign errors in EoM,
wrong damping coefficient, integration order errors."""
import numpy as np
import pytest


def test_undamped_energy_conserved(integrator, energy, standard_params, dt_fine):
    """Free undamped pendulum should conserve total mechanical energy.
    
    Tier 1. Catches: integrator drift, sign errors, wrong gravitational term.
    Tolerance: relative energy drift < 1e-4 over 100 cycles at dt=1e-4 (RK4).
    """
    standard_params_undamped = standard_params  # adapt: zero out damping
    standard_params_undamped.Q = 1e12  # effectively infinite Q
    
    n_cycles = 100
    t_end = n_cycles * standard_params.T_0
    traj = integrator(t_end=t_end, dt=dt_fine)
    
    E0 = energy(traj["theta"][0], traj["theta_dot"][0])
    E_final = energy(traj["theta"][-1], traj["theta_dot"][-1])
    relative_drift = abs(E_final - E0) / E0
    
    assert relative_drift < 1e-4, (
        f"Energy drift over {n_cycles} cycles: {relative_drift:.2e} (expected < 1e-4)"
    )


def test_small_angle_period(integrator, standard_params, dt_fine):
    """Small-amplitude period should equal 2*pi*sqrt(L/g) within 0.05%.
    
    Tier 1. Catches: wrong omega_0 calculation, missing /2pi factor.
    """
    from sim.pendulum import PendulumState
    initial = PendulumState(theta=np.radians(0.5), theta_dot=0.0)
    
    expected_T = 2 * np.pi * np.sqrt(standard_params.L / standard_params.g)
    traj = integrator(state=initial, t_end=10*expected_T, dt=dt_fine)
    
    # Find zero crossings; period = 2 * mean interval
    crossings = np.where(np.diff(np.sign(traj["theta"])))[0]
    intervals = np.diff(traj["t"][crossings])
    measured_T = 2 * np.mean(intervals)
    
    relative_error = abs(measured_T - expected_T) / expected_T
    assert relative_error < 5e-4, (
        f"Period: measured {measured_T}, expected {expected_T}, error {relative_error:.2e}"
    )


def test_circular_error(integrator, standard_params, dt_fine):
    """Period at 5° should match the circular-error series correction.
    
    Tier 1. Catches: wrong sin(theta) approximation, missing higher-order terms.
    Reference: Ch 02 EQ-04: T = T_0 * (1 + theta_max^2/16 + 11/3072 * theta_max^4 + ...)
    """
    from sim.pendulum import PendulumState
    theta_max = np.radians(5.0)
    initial = PendulumState(theta=theta_max, theta_dot=0.0)
    
    T_0 = 2 * np.pi * np.sqrt(standard_params.L / standard_params.g)
    expected_T = T_0 * (1 + theta_max**2/16 + 11*theta_max**4/3072)
    
    traj = integrator(state=initial, t_end=10*T_0, dt=dt_fine)
    crossings = np.where(np.diff(np.sign(traj["theta"])))[0]
    measured_T = 2 * np.mean(np.diff(traj["t"][crossings]))
    
    relative_error = abs(measured_T - expected_T) / expected_T
    assert relative_error < 1e-4, (
        f"5° period: measured {measured_T}, expected {expected_T} (with circular error)"
    )


def test_damped_exponential_envelope(integrator, energy, standard_params, dt_coarse):
    """Free damped pendulum amplitude envelope should decay as exp(-beta*t).
    
    Tier 1. Catches: wrong damping coefficient, sign error in damping term.
    """
    from sim.pendulum import PendulumState
    initial = PendulumState(theta=np.radians(5.0), theta_dot=0.0)
    
    tau = standard_params.tau  # 1/beta
    traj = integrator(state=initial, t_end=2*tau, dt=dt_coarse)
    
    # Extract amplitude envelope by peak detection; compare to exp fit
    from scipy.signal import find_peaks
    peaks, _ = find_peaks(np.abs(traj["theta"]))
    if len(peaks) < 5:
        pytest.skip("Insufficient peaks for envelope fit")
    
    t_peaks = traj["t"][peaks]
    amp_peaks = np.abs(traj["theta"][peaks])
    
    # Expected: amp(t) = amp_0 * exp(-beta * t)
    log_ratio = np.log(amp_peaks[-1] / amp_peaks[0])
    expected_log_ratio = -standard_params.beta * (t_peaks[-1] - t_peaks[0])
    
    relative_error = abs(log_ratio - expected_log_ratio) / abs(expected_log_ratio)
    assert relative_error < 0.05, (
        f"Damped envelope: log decay ratio {log_ratio}, expected {expected_log_ratio}"
    )


def test_time_reversibility(integrator, standard_params, dt_fine):
    """Run forward, then backward — should recover initial state.
    
    Tier 1. Catches: sign errors that flip under time reversal,
    integrator implementation bugs in backward stepping.
    Note: requires undamped system (damping is irreversible).
    """
    from sim.pendulum import PendulumState
    standard_params.Q = 1e12  # effectively undamped
    initial = PendulumState(theta=np.radians(3.0), theta_dot=0.5)
    
    t_end = 5 * standard_params.T_0
    
    # Forward
    fwd = integrator(state=initial, t_end=t_end, dt=dt_fine)
    final = PendulumState(theta=fwd["theta"][-1], theta_dot=fwd["theta_dot"][-1])
    
    # Backward (negate velocity, integrate same duration; equivalent to dt -> -dt)
    reversed_state = PendulumState(theta=final.theta, theta_dot=-final.theta_dot)
    bwd = integrator(state=reversed_state, t_end=t_end, dt=dt_fine)
    
    # Final state should be initial with negated velocity
    theta_err = abs(bwd["theta"][-1] - initial.theta)
    vel_err = abs(bwd["theta_dot"][-1] - (-initial.theta_dot))
    
    assert theta_err < 1e-6, f"Time-reversed theta: {bwd['theta'][-1]} vs {initial.theta}"
    assert vel_err < 1e-6, f"Time-reversed velocity: {bwd['theta_dot'][-1]} vs {-initial.theta_dot}"


def test_integrator_convergence_order(integrator, energy, standard_params):
    """Halving dt should reduce energy drift by ~16x for RK4.
    
    Tier 1 boundary toward Tier 4. Catches: wrong integration order,
    typos in RK4 coefficients.
    """
    standard_params.Q = 1e12
    n_cycles = 20
    t_end = n_cycles * standard_params.T_0
    
    drifts = []
    for dt in [1e-3, 5e-4, 2.5e-4]:
        traj = integrator(t_end=t_end, dt=dt)
        E0 = energy(traj["theta"][0], traj["theta_dot"][0])
        E_final = energy(traj["theta"][-1], traj["theta_dot"][-1])
        drifts.append(abs(E_final - E0) / E0)
    
    # Each halving of dt should reduce drift by ~16x for RK4 (4th order)
    ratio_1 = drifts[0] / drifts[1]
    ratio_2 = drifts[1] / drifts[2]
    
    # Allow some slack — true ratio is 16, accept [8, 32] as in-the-asymptotic-regime
    assert 8 < ratio_1 < 32, f"dt halving 1: ratio {ratio_1}, expected ~16"
    assert 8 < ratio_2 < 32, f"dt halving 2: ratio {ratio_2}, expected ~16"
```

## Tier 2: force/field invariants

```python
"""test_force_invariants.py — Tier 2.

Covers: symmetry under coordinate transformations, force polarity,
field at known points, asymptotic limits, dimensional consistency
at runtime. Catches: sign errors in force model, wrong field formula,
missing constants, broken polarity logic."""
import numpy as np
import pytest


def test_solenoid_field_at_center(standard_params):
    """On-axis field at coil center should match the analytic formula.
    
    Tier 2. Catches: wrong solenoid formula, missing mu_0, wrong N or I.
    Reference: B_z(z=0) = mu_0 * N * I / sqrt(L^2 + (2r)^2) at coil center
    (for a thin solenoid; check your specific formula's exact form)."""
    from sim.pendulum import _solenoid_Bz_on_axis, CoilParams
    coil = CoilParams(N=500, V_pulse=5.0, R_coil=50.0, diameter=0.015,
                      length=0.025, mu_r=1.0)
    
    B_at_center = _solenoid_Bz_on_axis(z=0.0, coil=coil)
    
    # Analytic for finite solenoid at center, mu_r=1:
    # B = mu_0 * N * I / length * cos(theta_half)
    mu_0 = 4 * np.pi * 1e-7
    I = coil.V_pulse / coil.R_coil
    half_l = coil.length / 2
    r = coil.diameter / 2
    expected = mu_0 * coil.N * I / coil.length * (half_l / np.sqrt(r**2 + half_l**2))
    
    relative_error = abs(B_at_center - expected) / abs(expected)
    assert relative_error < 1e-3, (
        f"B at center: {B_at_center}, expected {expected}, error {relative_error:.2e}"
    )


def test_solenoid_far_field_dipole_limit(standard_params):
    """At z >> coil dimensions, B should fall as 1/z^3 (dipole limit).
    
    Tier 2. Catches: wrong asymptotic behaviour, missing factors at far field.
    """
    from sim.pendulum import _solenoid_Bz_on_axis, CoilParams
    coil = CoilParams(N=500, V_pulse=5.0, R_coil=50.0, diameter=0.015,
                      length=0.025, mu_r=1.0)
    
    z1 = 1.0  # 1 m, much larger than coil dimensions
    z2 = 2.0  # 2 m
    B1 = _solenoid_Bz_on_axis(z=z1, coil=coil)
    B2 = _solenoid_Bz_on_axis(z=z2, coil=coil)
    
    # At dipole limit, B ~ 1/z^3, so B1/B2 ~ (z2/z1)^3 = 8
    ratio = abs(B1 / B2)
    assert 7 < ratio < 9, f"Far-field ratio: {ratio}, expected ~8 (1/z^3)"


def test_force_polarity_symmetry(standard_params):
    """F(polarity=+1) must equal -F(polarity=-1) for the same geometry.
    
    Tier 2. Catches: broken polarity sign convention.
    """
    from sim.pendulum import em_torque, MagnetParams, MagnetOrientation, CoilParams, CoilPlacement
    magnet = MagnetParams(orientation=MagnetOrientation.DIAMETRAL)
    coil = CoilParams(placement=CoilPlacement.TANGENTIAL_BESIDE, x_offset=0.015)
    
    theta = np.radians(3.0)
    tau_plus = em_torque(theta, standard_params, magnet, coil, polarity=+1.0)
    tau_minus = em_torque(theta, standard_params, magnet, coil, polarity=-1.0)
    
    assert abs(tau_plus + tau_minus) < 1e-12, (
        f"Polarity asymmetry: +1 -> {tau_plus}, -1 -> {tau_minus} (should be opposite)"
    )


def test_force_decays_at_distance(standard_params):
    """As bob moves far from coil, EM force should -> 0.
    
    Tier 2. Catches: spurious constant-offset forces, missing locality.
    """
    from sim.pendulum import em_torque, MagnetParams, MagnetOrientation, CoilParams, CoilPlacement
    magnet = MagnetParams(orientation=MagnetOrientation.AXIAL)
    coil = CoilParams(placement=CoilPlacement.TANGENTIAL_BELOW, x_gap=0.010)
    
    # Bob at theta=0 should feel some force
    tau_near = em_torque(0.0, standard_params, magnet, coil, polarity=1.0)
    # Bob far away (x_gap virtually infinite) should feel ~0 force
    coil_far = CoilParams(placement=CoilPlacement.TANGENTIAL_BELOW, x_gap=10.0)
    tau_far = em_torque(0.0, standard_params, magnet, coil_far, polarity=1.0)
    
    assert abs(tau_far) < 0.01 * abs(tau_near), (
        f"Far-field torque: {tau_far} should be << near-field {tau_near}"
    )
```

## Tier 3: driven-system invariants

```python
"""test_driven_invariants.py — Tier 3.

Covers: energy balance under driving, limit-cycle existence (with
escapement), conservation under known forcing protocols. Catches:
broken work integral, model bugs in the driven term, missing 
escapement model."""
import numpy as np
import pytest


def test_pulse_inactive_means_zero_torque(standard_params):
    """When pulse window is closed, EM torque should be exactly 0.
    
    Tier 3. Catches: pulse machinery bugs, leaked force outside pulse window.
    """
    from sim.pendulum import simulate, PendulumState, PulseParams, MagnetParams, CoilParams
    initial = PendulumState(theta=np.radians(3.0), theta_dot=0.0)
    pulse = PulseParams(t_w=0.001, T_drive=10.0)  # very narrow pulse, very long period
    
    traj = simulate(initial, standard_params, t_end=1.0, dt=1e-3,
                    magnet=MagnetParams(), coil=CoilParams(), pulse=pulse)
    
    # In the gap between pulses, torque should be exactly 0
    # (find timesteps outside pulse window and verify)
    quiet_torques = traj["torque_em"][int(0.5/1e-3):]  # second half, far from any pulse
    assert np.max(np.abs(quiet_torques)) < 1e-15, (
        f"Non-zero torque outside pulse window: max {np.max(np.abs(quiet_torques))}"
    )


def test_work_done_equals_energy_change(integrator, energy, standard_params):
    """Energy delta over a window must equal integral of (torque . theta_dot) dt.
    
    Tier 3. The most general physics test there is: it ties force, position,
    and velocity into one number that has to balance. Catches force-model
    errors that other tests miss.
    """
    from sim.pendulum import simulate, PendulumState, PulseParams, MagnetParams, CoilParams
    standard_params.Q = 1e12  # remove damping so only EM does work
    
    initial = PendulumState(theta=np.radians(3.0), theta_dot=0.0)
    pulse = PulseParams(t_w=0.05, T_drive=1.0)
    
    traj = simulate(initial, standard_params, t_end=2.0, dt=1e-4,
                    magnet=MagnetParams(), coil=CoilParams(), pulse=pulse)
    
    E_initial = energy(traj["theta"][0], traj["theta_dot"][0])
    E_final = energy(traj["theta"][-1], traj["theta_dot"][-1])
    
    # Work done by EM = integral of torque * theta_dot dt
    work = np.trapz(traj["torque_em"] * traj["theta_dot"], traj["t"])
    
    energy_change = E_final - E_initial
    relative_error = abs(work - energy_change) / max(abs(work), abs(energy_change), 1e-12)
    
    assert relative_error < 1e-3, (
        f"Work-energy balance: work={work}, deltaE={energy_change}, error={relative_error:.2e}"
    )
```

## Worked example: applied to driven-pendulum's bare-pendulum simulation

The archived `sim/archive_v2_bare_pendulum/pendulum.py` would pass:

- All Tier 1 tests (the EoM and integrator are correct)
- All Tier 2 tests (the EM force math is correct)
- The first two Tier 3 tests (pulse machinery and work-energy balance work)

It would *not have a test* for the limit-cycle behaviour with an escapement (because no escapement is modelled). That gap is exactly the scope-mismatch that drove the v2 doc error: the simulation didn't model the application scenario, and there was no test that would have made the gap visible.

The lesson: **a passing test suite is necessary but not sufficient.** The framework's value comes from the tests *and* the tier hierarchy that exposes which tiers are not yet exercised. A project with full Tier 1–3 coverage but no Tier 5 (intercomparison) and no Tier 6 (experimental) should carry that gap on its label.

## How to extend

- **Add a Tier 4 MMS test** when you publish a numerical result. See `mms-test-template.md` (planned).
- **Add a Tier 5 intercomparison test** before publishing or deploying. See `intercomparison-test-template.md` (planned). This is the highest-leverage missing tier in most projects.
- **Add Tier 3 limit-cycle tests** when your simulation includes a self-sustained oscillator. See `conservation-log-template.md` (planned) for the symplectic+conservation-log pattern.

## Limitations

- **The fixtures in `conftest.py` assume a pendulum.** Adapt the `PendulumParams`, `simulate()`, and `energy()` shapes to your project's API. The test logic is general; the bindings are not.
- **Tolerances are dt-dependent.** The numerical thresholds in the tests above were chosen for RK4 at dt=1e-4. For different integrators or step sizes, recompute.
- **Some tests need supporting infrastructure.** Time-reversibility requires an integrator that supports backward stepping (or equivalently, dt → -dt). Convergence tests require enough steps to be in the asymptotic regime.
- **These tests catch implementation errors, not modelling errors.** A test suite that passes proves your code does what your model says, not that your model is correct. For modelling errors, use Tier 5 (intercomparison) or Tier 6 (experimental).

## Sources

- Hairer, E., Lubich, C., Wanner, G. (2006). *Geometric Numerical Integration*. Springer. The reference for symplectic methods and energy-conservation tests.
- SciML.jl ecosystem (https://sciml.ai). Test patterns for differential-equation solvers.
- Roache, P.J. (2002). "Code Verification by the Method of Manufactured Solutions." *J. Fluids Eng.*, 124(1), 4–10. Tier 4 reference.
- Hodzelmans, B. (2017). "Slingers dwingen — Circular error of gedwongen trilling?" Driven-pendulum project's primary experimental reference; Tier 6 validation target for that project.
- `agent-ready-papers/templates/physics-verification/verification-tier-hierarchy.md`. The organising framework that places each test in its tier.
