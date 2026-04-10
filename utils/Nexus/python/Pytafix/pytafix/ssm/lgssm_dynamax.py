import os
os.environ["XLA_PYTHON_CLIENT_PREALLOCATE"] = "false"   # allocate on demand — prevents OOM on shared GPU
os.environ["XLA_PYTHON_CLIENT_ALLOCATOR"]   = "platform" # return memory to CUDA when arrays are freed
import gc
import jax
jax.config.update("jax_enable_x64", True)   # float64 — prevents covariance blow-up at high iters
import numpy as np
import jax.numpy as jnp
import jax.random as jr
from dynamax.linear_gaussian_ssm import LinearGaussianSSM
from dynamax.linear_gaussian_ssm.inference import lgssm_smoother
from dynamax.utils.utils import monotonically_increasing, random_rotation

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
    def fit(cls, emissions, state_dim=3, num_iters=50):
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
        C_init = Vt[:state_dim].T                               # (emissionDim, state_dim)
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
            scale = 0.95 / rho if rho > 0.95 else 1.0
            if i % 10 == 0:
                print(f"[lgssm_bd] iter {i:3d}  LL = {ll:.4f}"
                      f"  rho(A)={rho:.4f}{'→0.95' if scale < 1 else ''}"
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
        return

    def get_params(self):
        return
