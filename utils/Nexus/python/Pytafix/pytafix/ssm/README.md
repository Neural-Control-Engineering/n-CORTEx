# `pytafix.ssm` — LGSSM (dynamax) wrapper

`lgssm_dynamax.py` wraps dynamax's `LinearGaussianSSM` for the Nexus SSM pipeline
(`mdlObj_ssm` → `nexFit_ssm.m` → here). Called from MATLAB via `py.*`; emissions
arrive as `(num_trials, T, emission_dim)` (pass with `permute([3 2 1])` to correct
column-major → row-major).

This file documents the non-obvious fixes in that module and how to read its
per-iteration trace. Everything here was established by direct measurement on real
data, not inferred — where something is an inference or remains unexplained, it says so.

---

## Entry points

| Method | What it is | Status |
|---|---|---|
| `fit()` | Production path. Per-iteration stabilization loop, `initial.cov` reflooring via **eigenvalue clip**. | **Use this.** |
| `fit_no_inner_psd_defense()` | Byte-identical to `fit()` except `initial.cov` uses the old **flat additive jitter**. | Preserved deliberately — reproduces the pre-fix failure for comparison. |
| `fit_bulk()` | Original single bulk `fit_em(num_iters=N)` call, no per-iteration stabilization at all. | Reference/fallback. Works on CPU; reliably collapses to NaN on GPU for this problem shape. |
| `fit_block_diagonal()` | Constrained fit (block-diagonal `C` via mask projection). Runs EM on **CPU** by design — smoother covariances are `B × T × state_dim²` and too large for GPU at block-diagonal state dims. | Separate path, its own stabilization. |

`fit()` and `fit_no_inner_psd_defense()` both delegate to `_fit_core(..., reflooring_fn=...)`
— the per-iteration loop exists **once**, with only the reflooring strategy passed in.
That structure is deliberate: the two methods silently diverging is exactly the mistake
that cost a full night of misdirected investigation (see "Methodological lesson" below).

---

## Critical fix 1 — `initial.cov` going indefinite (the actual production blocker)

**Symptom.** `fit()` reliably completed iterations 0–2, then failed at iteration 3 with
`FloatingPointError: invalid value (nan) encountered in scan`. Reproducible across fresh
processes.

**What it was NOT.** Not GPU, jaxlib, cuSolver, driver state, or package versions — an
entire night of environment archaeology (WIP #22/#23) chased those and found real but
*unrelated* facts. Not per-timestep drift either: symmetrize+jitter applied to
`_condition_on`'s and `_predict`'s own covariance outputs (at `1e-6`, then `1e-2`, on one
then both functions — 480×68 calls/iteration) failed **identically** at iteration 3 all
three times.

**Root cause.** vmap-safe instrumentation (`jax.debug.print` + `jax.lax.cond`) threaded
through the *real, fully-batched* `fit_em` call showed the very first `_condition_on` call
of the failing iteration — `t=0`, before any per-timestep propagation — already receiving
a non-finite result. Its input, `params.initial.cov`, measured directly via
`np.linalg.eigvalsh`: **eigenvalue `-0.117`**. Substantial, not rounding noise — and
present *after* the existing `+1e-4` flat jitter had already been applied to it.

Why a tame preset doesn't prevent this: `P0_init = data_var * eye(state_dim)` only governs
iteration 0. From then on, **the M-step re-derives and overwrites `initial.cov` every
iteration** from the smoother's posterior statistics at `t=1`. That closed-form update is
PSD only in exact arithmetic — it's the standard difference-of-PSD-quantities form, and
floating-point cancellation can leave a genuinely negative eigenvalue. Nothing about the
initial preset constrains what the MLE recomputation produces later. (Note `C` is *not*
a covariance at all — rectangular emission weights, PSD doesn't apply; it was never the
indefinite matrix.)

**Fix** — `_eigenvalue_clip_reflooring()`:

```python
sym = 0.5 * (initial_cov + initial_cov.T)
eigvals, eigvecs = jnp.linalg.eigh(sym)
return eigvecs @ jnp.diag(jnp.maximum(eigvals, jitter)) @ eigvecs.T
```

A **floor**, not an additive bump — unconditionally correct regardless of how far negative
an eigenvalue has drifted, and it leaves already-healthy eigenvalues untouched (flat jitter
shifts all of them, always). A bigger flat constant would just be guessing at an unknowable
worst case.

**Why only here, not in the filter hot path.** `initial.cov` is one small
`state_dim × state_dim` matrix computed **once per outer EM iteration** — one extra `eigh`
is free. The same clip inside `_condition_on`/`_predict` would be an `eigh` (itself a
cuSolver call) per timestep, 480×68 times per iteration — reintroducing exactly the
call-volume problem that drove the earlier GPU chase. And the evidence says the problem
isn't there anyway.

Confirmed: all 20 iterations complete cleanly, 4/4 consecutive runs, unmodified
environment. `Q`/`R` keep the original flat `+jitter*eye` — they were never shown to be
the culprit.

---

## Critical fix 2 — `emission_dim < state_dim` silently mis-shaping `C_init`

**Symptom.** A `fitSWPGrid` grid cell crashed with
`TypeError: dot_general requires contracting dimensions to have the same shape, got (2,) and (3,)`
— raised deep inside dynamax's EM math, with no hint of the real cause.

**Root cause.** `np.linalg.svd(emissions_2d, full_matrices=False)` on an
`(N, emission_dim)` array returns `Vt` with only `min(N, emission_dim)` rows — i.e.
`emission_dim` rows here, since `N` (pooled timepoints) is always far larger. The old
`C_init = Vt[:state_dim].T` **does not error** when `state_dim` exceeds `Vt`'s row count;
numpy slicing past the end just returns however many rows exist. With `emission_dim=2`,
`state_dim=3` (a region subset with fewer observed channels than the fixed state dim),
`C_init` came out `(2, 2)` instead of the required `(2, 3)`.

**Fix** — `_structured_C_init(Vt, emissionDim, state_dim)`: builds the correctly-shaped
`(emissionDim, state_dim)` matrix, filling real SVD directions where available and padding
remaining columns with small random values (prints when it does). Fitting more latent
dimensions than observed channels is underdetermined but valid — those columns just have
nothing but noise to initialize from.

Wired into **both** `_fit_core` and `fit_bulk` (which carries its own duplicated init
block). Verified against the exact failing shape `(68, 480, 2)` with `state_dim=3`.

---

## Critical fix 3 — dynamax's `MVN`/Cholesky asymmetry (real, kept, *not* the blocker)

Inside `lgssm_filter`'s per-timestep step, dynamax computes the same innovation covariance
`S = R + H @ pred_cov @ H.T` in two places:

- `_condition_on` (Kalman gain) → routes through `psd_solve`, which **does** add a `1e-9`
  diagonal boost before Cholesky.
- `_log_likelihood` (scoring only) → builds `MVN(m, S).log_prob(y)`, and TFP's
  `MultivariateNormalFullCovariance.__init__` runs `tf.linalg.cholesky(S)` **unprotected**.

Same matrix, same requirement, only one site guarded. Confirmed via native-Python
traceback (`JAX_TRACEBACK_FILTERING=off` + `jax.disable_jit()`) pointing at exactly that
`MVN(m, S)` call.

**Fix.** `_log_likelihood` is a private closure — not overridable directly — but it looks
up `MVN` as a free variable against its module namespace at call time, so the available
seam is patching that name: `_JitteredMVN` adds `1e-6 * eye` before delegating to the real
`MVN`. `1e-6` is 1000× dynamax's native `1e-9` (GPU cuSolver needs more margin than CPU
LAPACK) but far below the `Q`/`R` floor (`1e-4`), so it has no material effect on reported
LL values. Dynamax's installed files are never modified.

**Status: real bug, real fix, kept — but direct testing showed it was not what was crashing
production.** `NaN_collapse_investigation.md` in this folder predates fix 1 and presents
this as "the actual root cause"; that framing is **superseded** by fix 1 above. The rest
of that document (ruled-out theories, diagnostic tooling notes) is still accurate.

---

## Critical fix 4 — per-iteration `Q`/`R` reflooring and `rho(A)` clipping

Defense-in-depth, independently justified, still active in `_fit_core`:

- **`Q`/`R` flat reflooring (`+1e-4*eye`)** — EM's M-step can legitimately drive a noise
  covariance toward singular (the mean structure already explains that direction almost
  perfectly, so the MLE noise estimate wants ~0). GPU cuSolver is far less tolerant of a
  matrix at that edge than CPU LAPACK; dynamax's fixed `1e-9` boost isn't reactive to how
  close *this* fit has drifted.
- **`rho(A)` clip to `RHO_A_CLIP`** (module constant; was 0.95, raised to **0.999** on
  2026-11-03) — if any dynamics eigenvalue exceeds 1, predicted covariance grows as
  `|λ|^(2T)` over `T=480` steps and reaches Inf/NaN within a single E-step, independent of
  `Q`/`R`. Mirrors `fit_block_diagonal`'s existing precedent. **Any ceiling < 1 prevents
  the blow-up; the value only sets where timescales become censored**
  (`tau_max = -dt / ln(RHO_A_CLIP)`: 0.95 → 97.5 ms, 0.999 → ~5 s at dt = 5 ms). At 0.95,
  >90% of the first real sweep's dominant modes sat exactly on the ceiling, so τ_dom
  reported the clip, not the data. `nexPlot_ssmEigenSweep(..., rhoClip=0.999)` flags
  cells still at the ceiling. `A_init = 0.95 * random_rotation(...)` is an initialization,
  not a ceiling, and is unchanged.
- **Finiteness check before `eigvalsh`** — `eigvalsh` raises
  `LinAlgError: Eigenvalues did not converge` (rather than returning NaN) on an
  already-non-finite matrix, which would crash the diagnostic before the graceful stop.

`jax_debug_nans` was used as a diagnostic and is now **off** — it has real per-op overhead
and there's no remaining NaN to catch.

---

## Reading the per-iteration trace diagnostically

```
[lgssm] iter  19  LL=-388862.0090  min(eig(Q))=8.409e-03  min(eig(R))=8.423e-04  rho(A)=0.9954 -> clipping to 0.95
```

**Healthy cell:** LL strictly negative and monotonically increasing toward convergence;
`min(eig(Q))`/`min(eig(R))` small but comfortably *above* the `1e-4` floor; `rho(A)`
oscillating in-band with occasional clipping; converged `R` showing real off-diagonal
correlation structure across channels.

**Degenerate cell — watch for this signature** (observed on a real `unit=ccb` grid cell):

| Signal | Reading |
|---|---|
| `SVD singular values=[136.9, 0., 0., 0.]` | Data matrix is **rank 1**. Values print as exactly `0.` → those channels are exactly constant across every timepoint and trial in this stratum. |
| `min(eig(R))=0.000e+00` pinned every iteration | The *un-jittered* MLE estimate never leaves zero (the `R` actually used has `+1e-4`). |
| Converged `emissions.weights` rows exactly `[0,0,0]`; `emissions.cov` diagonal exactly `0.0001` | Those channels are sitting on the jitter floor — the model correctly learned "zero information here." |
| **LL positive and climbing fast** (e.g. `-60755 → +235403`) | A Gaussian log-density diverges toward `+∞` as modeled variance → 0. This is the degeneracy, **not** a better fit. |

**Consequence: LL is not comparable across grid cells with differing degeneracy.** A cell
with constant channels will always show runaway-positive LL regardless of how well the
latent dynamics explain anything. Don't rank cells by final LL without checking the SVD
spectrum first.

**Is the jitter load-bearing or dormant?** Re-run with a couple of `jitter` values
(`1e-6`, `1e-4`, `1e-2`) and check whether fitted `A`/`C` — the scientifically meaningful
parameters — move. Stable → dormant insurance. Shifting → the floor is doing real work,
and that's worth chasing (likely `state_dim` or block structure, not a bigger floor). The
printed `min(eig(Q))`/`min(eig(R))` trace is the direct instrument: comfortably above the
floor = inactive; pinned at it = active.

---

## Methodological lesson (the expensive one)

**Always instrument the real, fully-`vmap`-batched call path. Never an isolated
single-trial bypass**, however tempting for localizing *which* trial is responsible.

Calling `model.e_step(params, emissions[0], None)` directly to isolate one trial produces
a *genuinely different compiled XLA program* than `fit_em`'s own always-batched
`vmap(partial(self.e_step, params))(...)`. That different program has its own real,
apparently GPU-specific cuSolver limitation that the production path never triggers.
Mistaking that artifact for a property of the real code consumed most of a night and
generated an entire false GPU/driver/dependency-version investigation.

Corollary for instrumentation written inside monkeypatched functions: plain `np.array()`
or concrete-value checks **crash under `vmap`** (`TracerArrayConversionError` on a
`BatchTracer`). Use `jnp.isfinite`, `jax.lax.cond`, `jax.debug.print` — all JAX-native.

---

## MATLAB `py.*` bridge notes

- **Tracebacks are truncated** to exception type + message. For a real traceback, export
  the input (`py.numpy.save(...)`) and reproduce in native Python.
- **Underscore-prefixed names can't be dot-accessed** (`di._condition_on` is a parse
  error, even for single-underscore names). Use `py.getattr(di, "_condition_on")`.
- **Forcing a genuinely fresh module state** — `importlib.reload()` re-executes into the
  *existing* namespace and never clears stale names (monkeypatches, partial reloads), which
  produced a `RecursionError: maximum recursion depth exceeded` in a long-lived session.
  The reliable reset, no MATLAB restart needed:

  ```matlab
  pyrun("import sys; [sys.modules.pop(k) for k in list(sys.modules) if k.startswith('dynamax') or k.startswith('pytafix')]");
  pytafix = py.importlib.import_module('pytafix');
  mdlObj.model = pytafix.ssm.LGSSM;
  ```

- Smart/curly quotes pasted from a browser cause `Invalid text character` — retype quotes.

---

## ⚠ REVISIT — masked Kalman for variable-length epochs (pending decision, 2026-11-02)

**Status:** Leaning yes; not started. Revisit with a fresh mind before the next
`fitSWPGrid` SSM run.

**The question to revisit:** Should before/during/after epochs be defined by the
behavioral events themselves — *before* = trial start → `stimOnset`, *during* =
`stimOnset` → `stimPeak` (variable length per trial), *after* = `stimPeak` → end — and
fit with a **masked Kalman filter** so variable-length trials share one model without
padding?

**Why the current approach can't stretch to this.** dynamax has no missing-observation
masking (confirmed against installed source; see `nexOp_reshapeStackedByTrial.m` header).
Zero-padding is tolerable for the existing 1–2-bin shortfalls, but variable epochs would
mean tens to hundreds of padded bins. After standardization zero = mean, so padded tails
read as "state settled at baseline" → fake decay in `A` → biased τ. Padding amount
correlates with threshold (low-threshold trials are shorter), so the bias is confounded
with exactly the contrast H1/H2 test.

**Options considered:**

| Option | Verdict |
|---|---|
| Zero-pad / impute variable epochs | ✗ biases `A`, confounded with threshold |
| Single event, during = N% leading up to it | ✗ before/during/after lose meaning when trial durations differ |
| Time-warp onset→peak to fixed bins | Visualization only — per-trial Δt varies, so τ in real time is undefined |
| Fixed-width windows anchored to each event | **Fallback** — clean, but arbitrary W and may drop short trials |
| **Masked Kalman (`fit_masked()`)** | **Preferred** — standard EM with missing data (Shumway & Stoffer 1982) |

**Implementation sketch (`fit_masked()`, same `_fit_core` pattern + eigenvalue-clip loop):**
- Missing steps marked NaN → boolean mask `m_t`.
- Filter: at masked `t`, skip the measurement update (posterior = predicted).
- Smoother: unchanged (operates on filtered/predicted moments).
- M-step: initial/`A`/`Q` statistics over **all** steps; `C`/`R` statistics over
  **observed** steps only.
- Log-likelihood summed over observed steps only (keeps held-out comparisons fair).
- Mirror the change in `fit_block_diagonal()`.

**Validate first (doubles as supplementary fig S2):** simulate an LGSSM with known `A`; mask
trial ends with lengths *correlated with a label*. Pass = masked fits recover `A` equally
across labels while zero-padded fits show label-dependent bias.

**What masking does NOT fix:**
- Force-ramp confound — low-threshold trials are shorter partly mechanically; include
  onset→peak duration as a covariate in H2.
- Longer trials carry more observed steps in pooled fits — decide (and record)
  equal-trial vs. per-step weighting for the shared H2/H3 model.

**Timebox:** ~3–4 days including validation. If it slips → fall back to anchored fixed
windows and log that in the hypothesis ledger
(`Manuscript/M_Evoked_Neuropathic_Pain/sections/hypotheses.tex`).

**Side benefit:** masked updates are how an online Kalman filter handles dropped samples —
carries directly to the real-time closed-loop latent-state estimator.

**Update 2026-11-02 — masking likely unnecessary under the revised design.** The first real
sweep (event-centered epochs, `nexPlot_ssmEigenSweep`) showed >90% of cells' dominant
|λ| pinned at the `rho(A)` 0.95 clip, and many withdrawals land 100–200 ms after contact —
2–4 samples at 50 ms bins, so a per-epoch `A` for "during" isn't estimable regardless of
masking. Revised design (logged as pre-test redefinitions in the hypothesis ledger):
- **No "during" fit.** Treat it as the perturbation.
- **H1:** post-withdrawal *recovery* time constant (model-free exponential relaxation of
  population-state distance from baseline).
- **H2:** pre-stimulus baseline τ from an LGSSM on the long "before" epoch.
- **H3:** event magnitude at withdrawal = Kalman innovation from ONE shared model fit on
  before/after, filtered per trial at natural length (no padding needed).
- **Input/stability:** raster counts in 25–50 ms bins + sqrt transform (no Gaussian kernel);
  raise the `rho(A)` clip 0.95 → 0.999 in `_fit_core` and `fit_block_diagonal`; interpret τ
  only above a kernel-only null (per-unit circular spike shifts through the same pipeline).

Masked Kalman stays a valid future tool (dropped samples in real-time use), but it is no
longer on the critical path.

---

## Related

- `NaN_collapse_investigation.md` (this folder) — full narrative of the `MVN` asymmetry
  investigation. Its "actual root cause" section is superseded by Critical fix 1; its
  ruled-out-theories and diagnostic-tooling sections remain accurate.
- `utils/Nexus/WIP.md` #22, #23, #24 — the authoritative chronological record, including
  the deliberately-deferred environment findings (`cublas`/jax 0.6.1 regression, the
  `nexus_jaxtest` Python 3.12 conda-forge fallback environment, the still-unexplained
  compile-time cuSolver error on isolated/un-batched calls).
