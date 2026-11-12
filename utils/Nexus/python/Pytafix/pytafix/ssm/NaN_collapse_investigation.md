# SSM GPU NaN collapse — investigation and fix

> **PARTIALLY SUPERSEDED — read `README.md` in this folder first.** This document
> predates the finding that actually fixed production. The `MVN`/Cholesky asymmetry
> described below as "the actual root cause" is a **real bug with a real fix that is
> still in place** — but direct testing showed it was *not* what was crashing `fit()`.
> The actual blocker was the M-step's own per-iteration `initial.cov` estimate coming
> out substantially indefinite (confirmed eigenvalue `-0.117`), fixed by an eigenvalue
> clip; see README "Critical fix 1". The ruled-out-theories and diagnostic-tooling
> sections below remain accurate and useful.

Context: first real end-to-end test of `mdlObj.model.fit()` on a properly batched,
trial-independent `(68, 480, 10)` DM (68 trials, ~480 timesteps, 10 reduced features)
after `nexOp_reshapeStackedByTrial` started handing SSM real 3D trial/time structure
instead of a flattened `[68*480, 10]` single-sequence array. GPU fit reproducibly
collapsed to all-NaN params; CPU fit (same data, same code) did not.

## What didn't turn out to be the cause

- **The flattening used for SVD-based init** (`emissions.reshape(-1, emissionDim)` to
  compute `C_init`): purely a one-time, cross-sectional (order-independent) computation
  for initialization, not part of the per-iteration EM loop. Checked directly —
  negligible cost, and statistically fine to flatten since C/data_var are permutation-
  invariant over rows. Not the bottleneck, not a correctness issue.
- **The reduced 10-feature DM being structurally near-singular.** Checked directly:
  `eig(cov(mdlObj.DM))` → all eigenvalues in `[0.41, 1.11]`, `cond ≈ 2.7`. Perfectly
  well-conditioned. Ruled out "bad/collinear data" as the explanation.
- **`A` (dynamics matrix) drifting unstable** (spectral radius > 1, which would blow up
  predicted covariance as `|λ|^(2T)` over a 480-step sequence — the mechanism
  `fit_block_diagonal()` already guards against for its own, differently-constrained
  fit). Added per-iteration logging + clipping (rescale `A` to `rho=0.95` if it drifts
  past that) to `fit()` — confirmed via the printed trace that `rho(A)` was being held
  at exactly `0.95` every iteration right up to the failure. Ruled out.
- **`Q`/`R` (process/measurement noise covariance) slowly collapsing toward singular**
  — a real, general EM pathology (same root as the classic "a Gaussian-mixture
  component collapses onto one point" problem): with limited data relative to model
  flexibility, the MLE estimate of a noise covariance can legitimately drift toward
  zero. Added per-iteration re-flooring of `Q`, `R`, AND `initial.cov` (the initial-
  state covariance, which feeds the very first filter step the same way `Q` feeds every
  later one — a gap `fit_block_diagonal()` also has). Confirmed via logging that both
  were still comfortably above the floor (`~1e-2`, floor `1e-4`) right up until the
  iteration that failed. Ruled out as the proximate cause (though keeping it — see
  below, it's legitimate defense-in-depth regardless).

## The actual root cause

Confirmed via a native-Python reproduction (bypassing MATLAB's `py.*` bridge, which
truncates Python tracebacks) with `JAX_TRACEBACK_FILTERING=off` and
`jax.disable_jit()` for full eager-mode localization:

```
File ".../dynamax/linear_gaussian_ssm/inference.py", line 483, in _log_likelihood
    return MVN(m, S).log_prob(y)
File ".../tensorflow_probability/.../mvn_full_covariance.py", line 190, in __init__
    scale_tril = tf.linalg.cholesky(covariance_matrix)
FloatingPointError: invalid value (nan) encountered in cholesky
```

Inside `lgssm_filter`'s per-timestep `_step`, dynamax computes the SAME quantity
`S = R + H @ pred_cov @ H.T` (the innovation/residual covariance) in two places, for
two different jobs:

- **`_condition_on`** uses `S` to compute the Kalman gain — "how much should I revise
  my belief about the hidden state, given this observation." This is the actual state
  update. It routes through `psd_solve(S, ...)`, which adds a `1e-9` diagonal jitter
  before its Cholesky factorization.
- **`_log_likelihood`** uses the SAME `S` only to score "how surprising was this
  observation, given what I predicted before seeing it" — a pure diagnostic number,
  summed into the `LL`/`marginal_logprob` value EM is trying to maximize. It never
  touches the state estimate. It builds `MVN(m, S).log_prob(y)` — and TFP's
  `MultivariateNormalFullCovariance.__init__` runs `tf.linalg.cholesky(S)` completely
  unprotected, zero jitter.

Same matrix, same mathematical requirement (needs to be safely positive-definite for
Cholesky to succeed), computed independently twice — and only one of the two sites
got dynamax's own safety margin. That asymmetry is the actual bug. It explains
everything: why our `Q`/`R`/`A` stabilization never could have fixed it (this `S` is
built fresh, independently, regardless of how well-floored `Q`/`R` are going in); why
CPU tolerated it and GPU didn't (same near-singular `S`, but CPU's LAPACK Cholesky
limps through a matrix sitting right at that numerical edge where GPU's cuSOLVER
kernel flips to NaN); and why this surfaced now specifically (10 channels compressed
through only 3 latent states, fit over real 68-trial batched data, is a comparatively
unusual combination for `S` to approach that edge at all — plausibly outside what
dynamax's own test suite exercises on GPU hardware).

**Why would a widely-used, reputable library ship this asymmetry?** Best mechanical
inference (not confirmed from dynamax's own issue tracker): `_condition_on`'s version
is written as "solve a linear system" — a form where the risk of hitting a singular
matrix is visually obvious, and jittering before a solve is an almost reflexive habit.
`_log_likelihood`'s version is written as "construct a standard distribution object and
call `.log_prob()`" — which doesn't visually resemble a matrix inversion at all, even
though several layers down inside TFP it secretly needs one. Easy blind spot, same
underlying math wearing a different surface shape in the two call sites.

## The fix

`_log_likelihood` is a private closure defined inside `lgssm_filter` — not an
importable name we can override directly. But it looks up `MVN` as a free variable
against `dynamax.linear_gaussian_ssm.inference`'s own module namespace every time it
runs. So the one available seam is monkeypatching that name — implemented in
`lgssm_dynamax.py`, right after the dynamax imports:

```python
import dynamax.linear_gaussian_ssm.inference as _dynamax_inference

_LGSSM_LL_COV_JITTER = 1e-6
_RealMVN = _dynamax_inference.MVN

def _JitteredMVN(loc, covariance_matrix, *args, **kwargs):
    covariance_matrix = covariance_matrix + _LGSSM_LL_COV_JITTER * jnp.eye(covariance_matrix.shape[-1])
    return _RealMVN(loc, covariance_matrix, *args, **kwargs)

_dynamax_inference.MVN = _JitteredMVN
```

This restores parity with what `_condition_on`/`psd_solve` already does for the other
copy of `S` — same technique, same spot (just before a Cholesky), just extended to
cover the second, previously-unprotected site. `1e-6` is 1000x dynamax's own native
`1e-9` (GPU's cuSOLVER needs more margin than CPU's LAPACK to stay off this edge) but
far smaller than the external `Q`/`R` floor (`1e-4`), so it has no material effect on
the actual log-likelihood values being reported — it only prevents the Cholesky
factorization itself from blowing up. Dynamax's installed files are never touched;
nothing outside this one name, in this one module, is affected. The patch also
affects a handful of `MVN(...).sample(...)` calls elsewhere in `inference.py` (never on
the EM hot path) — harmless; a `1e-6` diagonal nudge is negligible next to any real
covariance scale.

## What's still in `fit()`, and why it's staying (defense-in-depth, not redundant)

Even though none of these were the proximate cause of the crash, they remain correct,
independently-justified stabilizations, now implemented in `fit()`
(`lgssm_dynamax.py`):

- **Per-iteration `Q`/`R`/`initial.cov` re-flooring** — a real, general EM pathology
  (variance collapse) that the `MVN` patch doesn't address at all; it governs how fast
  `Q`/`R` drift toward singular in the first place. Floored at `1e-4`.
- **Per-iteration `rho(A)` logging + clipping to 0.95** — guards against a genuinely
  different failure mode (unstable forward dynamics blowing up predicted covariance
  over long sequences), mirroring `fit_block_diagonal()`'s existing precedent.
- **Finiteness check before every `eigvalsh` call** — `eigvalsh` raises
  `LinAlgError: Eigenvalues did not converge` (not a NaN return) when fed an
  already-non-finite matrix; checking first lets the loop stop cleanly with a clear
  message instead of crashing the diagnostic itself.
- **The original, un-stabilized bulk `fit_em(num_iters=N)` call is preserved** as
  `fit_bulk()` (not deleted) — a reference/fallback, known to work on CPU.

## Falsifying "is this just papering over the problem"

Before fully trusting any fit that required jitter/flooring to converge at all: re-run
with a couple of different `jitter` values (e.g. `1e-6`, `1e-4`, `1e-2` on the `Q`/`R`
floor) and check whether the fitted `A`/`C` — the actual scientifically meaningful
parameters — move meaningfully between runs.
- Stable `A`/`C` across jitter choices → the floor is dormant insurance, rarely
  binding. Not papering over anything real.
- `A`/`C` shifting meaningfully → the floor is load-bearing, and that's worth chasing
  further (possibly `state_dim` or the per-region block structure needs rethinking,
  not a bigger floor).

The printed `min(eig(Q))`/`min(eig(R))` trace is the direct instrument for this: if
those values settle comfortably above the floor, it's inactive; if they're pinned
right at it, it's actively doing work.

## Diagnostic tooling notes (for next time)

- MATLAB's `py.*` bridge truncates Python tracebacks to just the exception type and
  message — to get the real traceback, reproduce the failing call in native Python
  (export the input array via `py.numpy.save(...)` from MATLAB, then run a standalone
  `python -c "..."` script).
- `jax.config.update("jax_debug_nans", True)` catches NaN at the output of a jitted
  function and reruns de-optimized to localize — but doesn't descend below a
  `lax.scan` primitive's own dispatch boundary on its own.
- `JAX_TRACEBACK_FILTERING=off` + `jax.disable_jit()` together give full eager-mode
  execution with an unfiltered traceback — the combination that actually pinpointed
  the exact failing line here. Much slower (no fusion), fine at this dataset's tiny
  scale (68×480×10 ≈ 2.6MB).
- `jax_debug_nans` is diagnostic-only and should be turned off once a fit is trusted —
  it adds real per-op overhead. **Now removed** from `lgssm_dynamax.py` (a comment at
  the import block records why), the fit having been confirmed stable across 4/4
  consecutive full runs after the `initial.cov` eigenvalue clip landed.
- Instrumentation placed inside a monkeypatched function must be JAX-native
  (`jnp.isfinite`, `jax.lax.cond`, `jax.debug.print`) — a plain `np.array()` or any
  concrete-value check raises `TracerArrayConversionError` on a `BatchTracer` the moment
  it runs under `vmap`, which the real batched call path always does.
