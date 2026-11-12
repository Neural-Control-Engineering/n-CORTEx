import os
os.environ["XLA_PYTHON_CLIENT_PREALLOCATE"] = "false"   # allocate on demand — prevents OOM on shared GPU
os.environ["XLA_PYTHON_CLIENT_ALLOCATOR"]   = "platform" # return memory to CUDA when arrays are freed
import gc
import pickle
import jax
jax.config.update("jax_enable_x64", True)   # float64 — prevents covariance blow-up at high iters
# jax_debug_nans was enabled here as a diagnostic (raises at the exact primitive op that
# first produces a NaN, instead of letting it silently propagate through the rest of the
# lax.scan). Root cause found and fixed (Nexus WIP.md #20 follow-up -- see fit()'s own
# docstring and _eigenvalue_clip_reflooring below: the M-step's own initial-covariance
# estimate going substantially indefinite, confirmed eigenvalue -0.117). Turned back off
# per that diagnostic's own documented intent, now that it's served its purpose -- real
# per-op overhead, not something to leave on permanently once there's no NaN left to catch.
import numpy as np
import jax.numpy as jnp
import jax.random as jr
from dynamax.linear_gaussian_ssm import LinearGaussianSSM
from dynamax.linear_gaussian_ssm.inference import lgssm_smoother
from dynamax.utils.utils import monotonically_increasing, random_rotation
import dynamax.linear_gaussian_ssm.inference as _dynamax_inference

# Spectral-radius ceiling for A, applied every EM iteration in fit()/_fit_core and
# fit_block_diagonal(). Any value < 1 prevents the |λ|^(2T) predicted-covariance
# blow-up; the ceiling only sets where timescales become CENSORED
# (tau_max = -dt / ln(RHO_A_CLIP)). Was 0.95 (tau_max = 97.5 ms at dt = 5 ms), which
# pinned >90% of the first real sweep's dominant modes -- see README "Critical fix 4".
# A_init's 0.95 * random_rotation is a starting point, not a ceiling, and is unchanged.
RHO_A_CLIP = 0.999

# Monkeypatch: dynamax's own _log_likelihood (a private closure inside lgssm_filter,
# not an importable name we could edit directly) builds S = R + H @ pred_cov @ H.T every
# single timestep and hands it UNJITTERED into MVN(m, S).log_prob(y) -- which internally
# runs tf.linalg.cholesky(S) with zero safety margin. A few lines away, _condition_on
# builds the SAME S for the Kalman gain and runs it through psd_solve, which DOES add a
# 1e-9 diagonal boost first. Same matrix, same role (both need S to be safely invertible),
# only one of the two sites protected -- confirmed directly via a native-Python traceback
# (JAX_TRACEBACK_FILTERING=off + jax.disable_jit()) pointing at exactly this MVN(m, S)
# call as the source of the reproducible GPU-only NaN collapse (Nexus WIP.md #20 follow-
# up; full writeup in NaN_collapse_investigation.md in this folder).
#
# _log_likelihood looks up `MVN` as a free variable against this module's own namespace
# every time it runs, so swapping what THIS name points to is the only available seam --
# there's no function to override directly. The wrapper adds the same style of boost
# psd_solve already uses, just larger (1e-6 vs dynamax's native 1e-9): GPU's cuSOLVER
# Cholesky kernel needs more margin than CPU's LAPACK to stay off this edge (see the
# writeup for why). This also affects the handful of MVN(...).sample(...) calls
# elsewhere in this module (never on the EM hot path) -- harmless there; a 1e-6 diagonal
# nudge is negligible next to any real covariance scale.
_LGSSM_LL_COV_JITTER = 1e-6
_RealMVN = _dynamax_inference.MVN

def _JitteredMVN(loc, covariance_matrix, *args, **kwargs):
    covariance_matrix = covariance_matrix + _LGSSM_LL_COV_JITTER * jnp.eye(covariance_matrix.shape[-1])
    return _RealMVN(loc, covariance_matrix, *args, **kwargs)

_dynamax_inference.MVN = _JitteredMVN

# Per-iteration initial-covariance reflooring strategies (Nexus WIP.md #20 follow-up).
# Two attempts were tried and ruled out by direct evidence before landing on this one --
# kept documented here rather than silently discarded, since the ruling-out IS the
# finding:
#   1. Per-timestep symmetrize+jitter on _condition_on's AND _predict's own covariance
#      outputs (monkeypatching both, 480x68 calls/iteration) -- hypothesis was "drift
#      compounds across the 480 sequential timesteps within one EM iteration." Tried at
#      jitter=1e-6 then 1e-2 on _condition_on alone, then both functions together at
#      1e-2 -- all three still failed identically at iteration 3.
#   2. Direct instrumentation (vmap-safe jax.debug.print + jax.lax.cond, run through the
#      REAL batched fit_em call) showed why: the very FIRST _condition_on call of the
#      ENTIRE iteration (t=0, before any per-timestep propagation happens at all)
#      already receives a non-finite result. The input at that point is params.initial
#      .cov itself -- confirmed directly: eigenvalue -0.117, even AFTER our existing
#      flat +jitter (1e-4) reflooring already ran. Not accumulated drift at all -- the
#      M-step's own one-time-per-iteration MLE estimate of the initial-state covariance
#      is already substantially indefinite, and a flat constant 1000x smaller than the
#      actual negative eigenvalue was never going to fix it, no matter how many times
#      per iteration it's applied.
# Given that, a proper eigenvalue clip (symmetrize + floor every eigenvalue to at least
# `jitter`) is the right tool -- and unlike the per-timestep case, this one runs ONCE
# per outer EM iteration on a single small (state_dim x state_dim) matrix, so the
# eigh-is-a-cuSolver-call-too concern that ruled out doing this inside _condition_on/
# _predict's hot path simply doesn't apply here.
def _flat_jitter_reflooring(initial_cov, state_dim, jitter):
    """Preserved, unmodified: fit_no_inner_psd_defense's own original reflooring."""
    return initial_cov + jitter * jnp.eye(state_dim)

def _eigenvalue_clip_reflooring(initial_cov, state_dim, jitter):
    """fit()'s reflooring: unconditionally correct regardless of how far negative the
    real eigenvalue has drifted, unlike a flat additive constant."""
    sym = 0.5 * (initial_cov + initial_cov.T)
    eigvals, eigvecs = jnp.linalg.eigh(sym)
    eigvals_floored = jnp.maximum(eigvals, jitter)
    return eigvecs @ jnp.diag(eigvals_floored) @ eigvecs.T

def _structured_C_init(Vt, emissionDim, state_dim):
    """Build the (emissionDim, state_dim) emission-matrix init from the SVD's own Vt.
    Found via a real fitSWPGrid grid-cell crash (emission_dim=2 < state_dim=3, a
    region/REG subset with fewer observed channels than the fixed state_dim): np.linalg
    .svd(..., full_matrices=False) on an (N, emissionDim) array only ever returns
    min(N, emissionDim) rows in Vt -- here, emissionDim itself, since N (total pooled
    timepoints) is always far larger. A naive Vt[:state_dim] doesn't error when
    state_dim exceeds Vt's own row count -- numpy slicing past the end just silently
    returns however many rows actually exist -- so C_init came out (emissionDim,
    emissionDim) = (2, 2) instead of the required (emissionDim, state_dim) = (2, 3),
    surfacing many calls later as a cryptic "dot_general requires contracting
    dimensions to have the same shape" deep inside dynamax's own EM math, with no hint
    of the actual init-time shape bug. Any state dimension beyond what the data's own
    channel count can supply a real variance-based direction for gets a small-random
    column instead -- fitting MORE latent dimensions than observed channels is a valid,
    if underdetermined, model; it just has nothing but noise to initialize the extra
    column(s) from."""
    n_real = min(state_dim, Vt.shape[0])
    C_init = np.zeros((emissionDim, state_dim))
    C_init[:, :n_real] = Vt[:n_real].T
    if n_real < state_dim:
        print(f"[lgssm] emission_dim={emissionDim} < state_dim={state_dim} -- only "
              f"{n_real} real SVD direction(s) available; padding remaining "
              f"{state_dim - n_real} C_init column(s) with small random values.")
        rng = np.random.default_rng(42)
        C_init[:, n_real:] = 0.01 * rng.standard_normal((emissionDim, state_dim - n_real))
    return C_init

class LGSSM:

    """
    Dynamax LGSSM wrapper - Marc Sorrentino"
    """

    # ---------- core ----------
    def __init__(self, model, params):
        self.model = model
        self.params = params

    # ---------- constructors ----------
    @classmethod
    def fit(cls, emissions, state_dim=3, num_iters=50, jitter=1e-4):
        """
        Same loop as fit_no_inner_psd_defense (both call _fit_core, zero duplication),
        with one difference: reflooring params.initial.cov with an eigenvalue clip
        instead of a flat additive jitter. Confirmed, via direct instrumentation, to be
        the actual fix: the real failure is NOT per-timestep drift (two attempts at
        that -- see the module-level comment above _flat_jitter_reflooring -- were
        tried and ruled out) -- it's that the M-step's own one-time-per-iteration MLE
        estimate of the initial-state covariance comes out substantially indefinite
        (eigenvalue -0.117, confirmed), and a flat jitter 1000x smaller was never going
        to fix that regardless of how large a constant was tried.
        """
        return cls._fit_core(emissions, state_dim=state_dim, num_iters=num_iters, jitter=jitter,
                              reflooring_fn=_eigenvalue_clip_reflooring)

    @classmethod
    def fit_no_inner_psd_defense(cls, emissions, state_dim=3, num_iters=50, jitter=1e-4):
        """
        Preserved, unmodified (per explicit request after tonight's wild chase) --
        this IS what `fit()` was before the eigenvalue-clip reflooring was added. Still
        has the per-ITERATION Q/R/A flat-jitter re-flooring/clipping. Kept callable so
        the two can be compared directly.
        """
        return cls._fit_core(emissions, state_dim=state_dim, num_iters=num_iters, jitter=jitter,
                              reflooring_fn=_flat_jitter_reflooring)

    @classmethod
    def _fit_core(cls, emissions, state_dim, num_iters, jitter, reflooring_fn):
        # emissions: (num_trials, T, emission_dim) — batched trials as independent sequences
        #            (T, emission_dim)              — single sequence
        # Pass from MATLAB with permute([3 2 1]) to correct for column-major → row-major

        emissions = np.asarray(emissions, dtype=np.float64)
        emissionDim = emissions.shape[-1]
        print(f"[lgssm] emissions shape={emissions.shape}, dtype={emissions.dtype}")

        model = LinearGaussianSSM(
            state_dim=state_dim,
            emission_dim=emissionDim
        )
        print(f"[lgssm] model: state_dim={state_dim}, emission_dim={emissionDim}")

        init_key = jr.PRNGKey(42)

        # Structured initialization — avoids ill-conditioning at high iteration counts.
        # A: random rotation scaled to 0.95 (contractive → guaranteed stable dynamics)
        # C: top-k right singular vectors of data (emission matrix reflects data variance)
        # Q: small isotropic noise relative to data scale
        # R: isotropic noise scaled to data residual variance after C projection
        key_A, key_rest = jr.split(init_key)
        A_init = 0.95 * random_rotation(key_A, state_dim)
        print(f"[lgssm] A_init shape={A_init.shape}")

        emissions_2d = emissions.reshape(-1, emissionDim)       # flatten trials for SVD
        print(f"[lgssm] emissions_2d for SVD shape={emissions_2d.shape}")
        U, S, Vt = np.linalg.svd(emissions_2d, full_matrices=False)
        C_init = _structured_C_init(Vt, emissionDim, state_dim)  # (emissionDim, state_dim)
        print(f"[lgssm] SVD singular values (top 10)={S[:10]}")
        print(f"[lgssm] C_init shape={C_init.shape}")

        data_var   = float(np.var(emissions))
        print(f"[lgssm] data_var={data_var:.4f}")
        Q_init     = 0.1 * data_var * np.eye(state_dim)
        R_init     = 0.1 * data_var * np.eye(emissionDim)
        P0_init    = data_var * np.eye(state_dim)
        print(f"[lgssm] Q_init shape={Q_init.shape}, R_init shape={R_init.shape}, P0_init shape={P0_init.shape}")

        params, param_props = model.initialize(
            key_rest,
            dynamics_weights        = A_init,
            dynamics_covariance     = Q_init,
            emission_weights        = C_init,
            emission_covariance     = R_init,
            initial_covariance      = P0_init,
        )
        print(f"[lgssm] params initialized")

        # Iteration-by-iteration instead of one bulk fit_em(num_iters=num_iters) call.
        # fit_em's own body (dynamax/ssm.py) IS already just a plain Python for loop
        # calling one jitted em_step num_iters times, threading params through eagerly
        # in between -- this reproduces exactly that, byte-for-byte, with one seam added:
        # a chance to inspect/re-floor Q (dynamics.cov) and R (emissions.cov) between
        # iterations. Needed because EM's own M-step can legitimately drive Q or R's
        # smallest eigenvalue toward singular (variance collapse -- the model's mean
        # structure already explains that channel/direction almost perfectly, so the MLE
        # noise estimate wants to go to ~0), and GPU's cuSOLVER Cholesky kernel (inside
        # every psd_solve call in dynamax's own filter/smoother) is far less tolerant of
        # a matrix sitting at that edge than CPU's LAPACK -- same numbers, GPU emits NaN,
        # CPU limps through. dynamax's own psd_solve already adds a FIXED 1e-9 diagonal
        # boost before every Cholesky call, but that's sized for "typical" well-conditioned
        # problems, not reactive to how close THIS fit's Q/R has actually drifted to
        # singular. Re-flooring the PARAMETERS themselves (not just one transient solve)
        # with a larger, problem-scaled jitter stops the collapse before the 1e-9 boost
        # is ever asked to rescue something already nearly singular.
        print(f"[lgssm] calling fit_em iteration-by-iteration: emissions shape={emissions.shape}, "
              f"num_iters={num_iters}, jitter={jitter}")
        log_likelihoods = []
        for i in range(num_iters):
            params, lls = model.fit_em(params, param_props, emissions, num_iters=1, verbose=False)
            ll = float(np.array(lls)[-1])
            log_likelihoods.append(ll)

            # Check finiteness BEFORE eigvalsh -- eigvalsh (LAPACK's symmetric
            # eigensolver) raises LinAlgError("Eigenvalues did not converge") rather
            # than returning NaN when fed a matrix that already contains NaN/Inf, so
            # calling it on a possibly-already-collapsed Q/R would crash this very
            # diagnostic before the graceful stop below ever runs.
            A_np = np.array(params.dynamics.weights)
            C_np = np.array(params.emissions.weights)
            Q_np = np.array(params.dynamics.cov)
            R_np = np.array(params.emissions.cov)
            if not (np.all(np.isfinite(A_np)) and np.all(np.isfinite(C_np))
                    and np.all(np.isfinite(Q_np)) and np.all(np.isfinite(R_np))):
                print(f"[lgssm] iter {i:3d}  non-finite value in params -- collapse happened "
                      f"INSIDE this iteration's fit_em call itself, before any re-floor/clip "
                      f"could run; stopping.")
                break

            # rho(A): A's spectral radius. If any eigenvalue of the dynamics matrix has
            # magnitude >1, the forward Kalman filter's predicted covariance grows as
            # |λ|^(2T) over a T-step sequence (T=480 here) -- even a mild overshoot
            # compounds to Inf/NaN within a SINGLE E-step pass, independent of how
            # gradually Q/R happen to be shrinking. This is the same mechanism
            # fit_block_diagonal() already guards against for its own (constrained) fit;
            # the unconstrained fit() above never had that guard until now.
            rho_A  = float(np.max(np.abs(np.linalg.eigvals(A_np))))
            Q_eigs = np.linalg.eigvalsh(Q_np)
            R_eigs = np.linalg.eigvalsh(R_np)
            print(f"[lgssm] iter {i:3d}  LL={ll:.4f}  min(eig(Q))={Q_eigs.min():.3e}  "
                  f"min(eig(R))={R_eigs.min():.3e}  rho(A)={rho_A:.4f}"
                  f"{f' -> clipping to {RHO_A_CLIP}' if rho_A > RHO_A_CLIP else ''}")

            # Clip A's spectral radius back to RHO_A_CLIP (contractive/stable) if it
            # drifted past it -- same rescaling fit_block_diagonal() already uses.
            A_stable = A_np * (RHO_A_CLIP / rho_A) if rho_A > RHO_A_CLIP else A_np

            # Re-floor Q, R, AND the initial-state covariance (params.initial.cov --
            # "S"/P0_init at init time), and apply the (possibly rescaled) A, for the
            # NEXT iteration's E-step/filter calls. initial.cov feeds the very first
            # filter step (prior_cov at t=0) exactly the same way Q feeds every later
            # one -- same collapse risk, different-strength fix depending on which
            # reflooring_fn was passed in (see fit() vs fit_no_inner_psd_defense above).
            params = params._replace(
                initial   = params.initial._replace(cov=reflooring_fn(params.initial.cov, state_dim, jitter)),
                dynamics  = params.dynamics._replace(
                    weights = jnp.array(A_stable),
                    cov     = params.dynamics.cov + jitter * jnp.eye(state_dim),
                ),
                emissions = params.emissions._replace(cov=params.emissions.cov + jitter * jnp.eye(emissionDim)),
            )

        marginal_lls = jnp.array(log_likelihoods)

        # assert monotonically_increasing(marginal_lls, atol=1e-2, rtol=1e-2)

        print(f"[lgssm] fit complete. marginal_lls shape={np.array(marginal_lls).shape}, final ll={float(np.array(marginal_lls)[-1]):.4f}")
        print(f"[lgssm] result params: ", params)

        return cls(model, params)

    @classmethod
    def fit_bulk(cls, emissions, state_dim=3, num_iters=50):
        """
        Original, unstabilized fit path — one single bulk model.fit_em(..., num_iters=num_iters)
        call, relying entirely on dynamax's own built-in 1e-9 psd_solve diagonal boost with no
        per-iteration Q/R re-flooring. Preserved (not deleted) as a reference/fallback: this is
        what `fit()` did before the per-iteration stabilization loop was added (Nexus WIP.md #20
        follow-up) to fix a reproducible GPU-only NaN collapse (cuSOLVER's Cholesky kernel is far
        less tolerant than CPU LAPACK of a covariance that EM's own M-step has driven near-singular
        -- see `fit()`'s own docstring/comments for the full mechanism). Known to work fine on CPU;
        known to reliably collapse to NaN on GPU for this kind of small-state-dim/few-trial problem.
        """
        emissions = np.asarray(emissions, dtype=np.float64)
        emissionDim = emissions.shape[-1]
        print(f"[lgssm] emissions shape={emissions.shape}, dtype={emissions.dtype}")

        model = LinearGaussianSSM(
            state_dim=state_dim,
            emission_dim=emissionDim
        )
        print(f"[lgssm] model: state_dim={state_dim}, emission_dim={emissionDim}")

        init_key = jr.PRNGKey(42)

        key_A, key_rest = jr.split(init_key)
        A_init = 0.95 * random_rotation(key_A, state_dim)
        print(f"[lgssm] A_init shape={A_init.shape}")

        emissions_2d = emissions.reshape(-1, emissionDim)       # flatten trials for SVD
        print(f"[lgssm] emissions_2d for SVD shape={emissions_2d.shape}")
        U, S, Vt = np.linalg.svd(emissions_2d, full_matrices=False)
        C_init = _structured_C_init(Vt, emissionDim, state_dim)  # (emissionDim, state_dim)
        print(f"[lgssm] SVD singular values (top 10)={S[:10]}")
        print(f"[lgssm] C_init shape={C_init.shape}")

        data_var   = float(np.var(emissions))
        print(f"[lgssm] data_var={data_var:.4f}")
        Q_init     = 0.1 * data_var * np.eye(state_dim)
        R_init     = 0.1 * data_var * np.eye(emissionDim)
        P0_init    = data_var * np.eye(state_dim)
        print(f"[lgssm] Q_init shape={Q_init.shape}, R_init shape={R_init.shape}, P0_init shape={P0_init.shape}")

        params, param_props = model.initialize(
            key_rest,
            dynamics_weights        = A_init,
            dynamics_covariance     = Q_init,
            emission_weights        = C_init,
            emission_covariance     = R_init,
            initial_covariance      = P0_init,
        )
        print(f"[lgssm] params initialized")

        print(f"[lgssm] calling fit_em: emissions into fit_em shape={emissions.shape}, num_iters={num_iters}")
        params, marginal_lls  = model.fit_em(
            params,
            param_props,
            emissions,
            num_iters=num_iters
        )

        # assert monotonically_increasing(marginal_lls, atol=1e-2, rtol=1e-2)

        print(f"[lgssm] fit complete. marginal_lls shape={np.array(marginal_lls).shape}, final ll={float(np.array(marginal_lls)[-1]):.4f}")
        print(f"[lgssm] result params: ", params)

        return cls(model, params)

    @classmethod
    def fit_block_diagonal(cls, emissions, C_mask, state_dim=None, num_iters=50, jitter=1e-4):
        """
        Fit LGSSM with a block-diagonal constraint on the emission matrix C.

        After each M-step the unconstrained C is projected back onto the feasible
        set by element-wise multiplication with C_mask (zero-ing out off-block
        entries).  A is left fully unconstrained so its off-diagonal blocks are
        interpretable as inter-regional coupling.

        Parameters
        ----------
        emissions : array (T, emission_dim) or (num_trials, T, emission_dim)
            Observations. Pass from MATLAB with permute([3 2 1]).
        C_mask : array (emission_dim, state_dim)
            Binary mask enforcing block-diagonal structure.
            C_mask[i, j] = 1  iff channel i may load on latent j.
            Build with LGSSM.build_emission_mask() or pass from MATLAB.
        state_dim : int, optional
            Latent dimensionality.  Inferred from C_mask.shape[1] if None.
        num_iters : int
            Number of EM iterations.

        Returns
        -------
        LGSSM instance with fitted block-diagonal C.
        """
        # Release any GPU buffers held from prior calls before allocating new ones
        gc.collect()
        jax.clear_caches()

        emissions = np.asarray(emissions, dtype=np.float64)
        C_mask    = jnp.array(np.asarray(C_mask, dtype=np.float64))

        emission_dim = emissions.shape[-1]
        if state_dim is None:
            state_dim = int(C_mask.shape[1])

        print(f"[lgssm_bd] emissions shape={emissions.shape}, state_dim={state_dim}, emission_dim={emission_dim}")

        model = LinearGaussianSSM(state_dim=state_dim, emission_dim=emission_dim)

        # -- Structured initialisation --
        init_key        = jr.PRNGKey(42)
        key_A, key_rest = jr.split(init_key)
        A_init = 0.95 * random_rotation(key_A, state_dim)

        emissions_2d = emissions.reshape(-1, emission_dim)
        _, S, _ = np.linalg.svd(emissions_2d, full_matrices=False)
        print(f"[lgssm_bd] SVD singular values (top 10)={S[:10]}")

        # Block-wise SVD for C_init — global SVD then masking leaves near-zero columns
        # for blocks whose variance isn't captured by the global singular vectors.
        # Instead, find each block's row support from C_mask and run SVD per block.
        C_mask_np    = np.array(C_mask)
        col_supports = [tuple(np.where(C_mask_np[:, j] > 0)[0]) for j in range(state_dim)]
        unique_supports = list(dict.fromkeys(col_supports))   # ordered unique row-ranges

        C_init = np.zeros((emission_dim, state_dim))
        for support in unique_supports:
            row_idx = list(support)
            col_idx = [j for j in range(state_dim) if col_supports[j] == support]
            _, _, Vt_block = np.linalg.svd(emissions_2d[:, row_idx], full_matrices=False)
            C_init[np.ix_(row_idx, col_idx)] = Vt_block[:len(col_idx)].T

        data_var = float(np.var(emissions))
        Q_init   = (0.1 * data_var + jitter) * np.eye(state_dim)
        R_init   = (0.1 * data_var + jitter) * np.eye(emission_dim)
        P0_init  = (data_var       + jitter) * np.eye(state_dim)

        params, param_props = model.initialize(
            key_rest,
            dynamics_weights    = A_init,
            dynamics_covariance = Q_init,
            emission_weights    = C_init,
            emission_covariance = R_init,
            initial_covariance  = P0_init,
        )

        # Run EM on CPU — state_dim for block-diagonal fits is O(num_blocks × states_per_block)
        # which makes Kalman smoother covariances (B × T × state_dim²) too large for GPU.
        # fit_em uses lax.scan so it is O(1) in T; the bottleneck is state_dim², not T.
        # CPU has no hard memory cap so this always works regardless of GPU occupancy.
        cpu = jax.devices('cpu')[0]
        emissions_cpu = jax.device_put(emissions, cpu)
        params        = jax.device_put(params,    cpu)
        C_mask        = jax.device_put(C_mask,    cpu)

        log_likelihoods = []

        for i in range(num_iters):
            params, lls = model.fit_em(params, param_props, emissions_cpu, num_iters=1)

            # Check if fit_em itself produced NaN (before any of our modifications)
            if np.any(np.isnan(np.array(params.dynamics.weights))):
                print(f"[lgssm_bd] NaN from fit_em at iter {i} — upstream issue")
                break

            ll = float(np.array(lls)[-1])
            log_likelihoods.append(ll)

            # Clip A spectral radius using numpy (reliable for non-symmetric matrices).
            # After masking C, unobserved latents have no Kalman correction — if A has
            # any |λ| > 1, P_pred grows as |λ|^{2T} over T steps → NaN in Cholesky(S).
            A_np  = np.array(params.dynamics.weights)
            rho   = float(np.max(np.abs(np.linalg.eigvals(A_np))))
            scale = RHO_A_CLIP / rho if rho > RHO_A_CLIP else 1.0
            if i % 10 == 0:
                print(f"[lgssm_bd] iter {i:3d}  LL = {ll:.4f}"
                      f"  rho(A)={rho:.4f}{f'→{RHO_A_CLIP}' if scale < 1 else ''}"
                      f"  Q_min={float(np.min(np.diag(np.array(params.dynamics.cov)))):.2e}"
                      f"  R_min={float(np.min(np.diag(np.array(params.emissions.cov)))):.2e}")
            params = params._replace(
                dynamics=params.dynamics._replace(weights=jnp.array(A_np * scale))
            )

            # Re-floor Q and R after each M-step
            Q_stable = params.dynamics.cov  + jitter * jnp.eye(state_dim)
            R_stable = params.emissions.cov + jitter * jnp.eye(emission_dim)
            params = params._replace(
                dynamics  = params.dynamics._replace(cov=Q_stable),
                emissions = params.emissions._replace(cov=R_stable),
            )

            # Projection step: re-enforce block-diagonal constraint on C
            constrained_C = params.emissions.weights * C_mask
            params = params._replace(
                emissions=params.emissions._replace(weights=constrained_C)
            )

        print(f"[lgssm_bd] fit complete. final LL = {log_likelihoods[-1]:.4f}")
        return cls(model, params)

    @staticmethod
    def build_emission_mask(region_channel_map, emission_dim, latent_per_region):
        """
        Build a binary block-diagonal mask for the emission matrix.

        Parameters
        ----------
        region_channel_map : dict  {region_name: [channel_indices, ...]}
            Maps each region label to a list of 0-based channel indices.
        emission_dim : int
            Total number of observation channels.
        latent_per_region : int
            Number of latent dimensions assigned to each region.

        Returns
        -------
        C_mask : jnp.array  (emission_dim, state_dim)
            Binary mask; 1 where emission weight is allowed, 0 otherwise.

        Example (from MATLAB)
        ---------------------
        C_mask = py.pytafix.ssm.lgssm_dynamax.LGSSM.build_emission_mask(
            py.dict({'SSp': py.list([...]), 'STN': py.list([...])}),
            py.int(385), py.int(4));
        """
        region_names = list(region_channel_map.keys())
        state_dim    = latent_per_region * len(region_names)
        mask         = jnp.zeros((emission_dim, state_dim))

        for r, name in enumerate(region_names):
            lat_start = r * latent_per_region
            lat_end   = (r + 1) * latent_per_region
            for ch in region_channel_map[name]:
                mask = mask.at[int(ch), lat_start:lat_end].set(1.0)

        return mask

    @classmethod
    def from_params(cls, params):
        return

    @classmethod
    def load(cls, path): 
        return

    @classmethod
    def random(cls, state_dim, emission_dim):
        return

    # ---------- inference ----------
    def smooth(self, emissions):
        return

    def filter(self, emissions):
        gc.collect()
        jax.clear_caches()
        print("filtering ssm...")
        emissions = jnp.asarray(emissions, dtype=jnp.float64)
        print(f"[lgssm] filter emissions shape={emissions.shape}, dtype={emissions.dtype}")
        # First call after a cache clear triggers JIT recompilation; cuSolver can
        # fail transiently during warm-up even though the kernel compiles fine.
        # Retry once — the second call hits the now-cached kernel and succeeds.
        for attempt in range(2):
            try:
                if emissions.ndim == 3:
                    Z = jax.vmap(lambda e: self.model.filter(self.params, e))(emissions)
                else:
                    Z = self.model.filter(self.params, emissions)
                return Z
            except Exception as e:
                if attempt == 0:
                    print(f"[lgssm] filter warm-up fail (attempt 1), retrying: {e}")
                else:
                    raise

    def predict(self, steps):
        return

    # ---------- utilities ----------
    def save(self, path):
        """Serialize fitted params to .npz (all JAX arrays converted to numpy)."""
        p = self.params
        np.savez(str(path),
            state_dim     = np.array(self.model.state_dim),
            emission_dim  = np.array(self.model.emission_dim),
            initial_mean  = np.array(p.initial.mean),
            initial_cov   = np.array(p.initial.cov),
            dyn_weights   = np.array(p.dynamics.weights),
            dyn_cov       = np.array(p.dynamics.cov),
            em_weights    = np.array(p.emissions.weights),
            em_cov        = np.array(p.emissions.cov),
        )
        print(f"[lgssm] saved to {path}")

    @classmethod
    def load(cls, path):
        """Reconstruct LGSSM instance from .npz saved by save()."""
        data         = np.load(str(path))
        state_dim    = int(data['state_dim'])
        emission_dim = int(data['emission_dim'])
        model        = LinearGaussianSSM(state_dim=state_dim, emission_dim=emission_dim)
        params, _    = model.initialize(jr.PRNGKey(0))
        params = params._replace(
            initial   = params.initial._replace(
                mean = jnp.array(data['initial_mean']),
                cov  = jnp.array(data['initial_cov']),
            ),
            dynamics  = params.dynamics._replace(
                weights = jnp.array(data['dyn_weights']),
                cov     = jnp.array(data['dyn_cov']),
            ),
            emissions = params.emissions._replace(
                weights = jnp.array(data['em_weights']),
                cov     = jnp.array(data['em_cov']),
            ),
        )
        print(f"[lgssm] loaded from {path}")
        return cls(model, params)

    @staticmethod
    def save_pickle(obj, path):
        """Serialize any Python object to a pickle file."""
        with open(str(path), 'wb') as f:
            pickle.dump(obj, f)
        print(f"[lgssm] pickled to {path}")

    @staticmethod
    def load_pickle(path):
        """Deserialize a pickle file."""
        with open(str(path), 'rb') as f:
            obj = pickle.load(f)
        print(f"[lgssm] unpickled from {path}")
        return obj

    def get_params(self):
        return
