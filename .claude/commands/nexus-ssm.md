# nexus-ssm — LGSSM (dynamax) Design Skill

Reference for `mdlObj_ssm`, `nexFit_ssm`, and the `pytafix.ssm.lgssm_dynamax` Python wrapper.

---

## Architecture

```
STAT (table)
  ↓  stat2dm_stack() → nexOp_stackSamples()
DM  (T_total × emissionDim)   [time-first, all trials stacked]
  ↓  nexFit_ssm() → pytafix.ssm.LGSSM.fit()
mdlObj.W  (fitted LGSSM — dynamax backend)
  ↓  mdlObj_ssm.transform() → W.filter(emissions)
DF_Z  (.df = filtered_means T×state_dim, .cov = filtered_covariances)
```

CFG Header params in `nexFit_ssm`: `stateDim` (default 3), `numIters` (default 20).

---

## LGSSM parameter initialization

File: `utils/Nexus/python/Pytafix/pytafix/ssm/lgssm_dynamax.py`

### Root cause of non-convergence at high iteration counts

Default `model.initialize(key)` uses random matrices with no structural priors. Combined with
JAX's default float32, covariances become ill-conditioned over many EM iterations.

### Fix 1 — float64

```python
jax.config.update("jax_enable_x64", True)
```

Matrix inversions (Kalman gain, covariance updates) accumulate float32 error — float64
eliminates numerical blow-up as the primary convergence blocker.

### Fix 2 — Transition matrix A: `random_rotation` scaled to 0.95

```python
A_init = 0.95 * random_rotation(key_A, state_dim)
```

A governs `z_t = A z_{t-1} + noise`. A rotation matrix has all eigenvalues on the unit
circle (magnitude = 1); scaling by 0.95 pulls them just inside, making the system slightly
contractive. Default random A has no stability guarantee — eigenvalues outside the unit
circle send EM chasing an exploding state trajectory.

### Fix 3 — Emission matrix C: SVD of data

```python
U, S, Vt = np.linalg.svd(emissions, full_matrices=False)
C_init = Vt[:state_dim].T    # shape: (emissionDim, state_dim)
```

C maps hidden states → observations: `y_t = C z_t + noise`. Each column is a direction in
observation space that one state dimension activates. SVD gives the top-`state_dim` directions
of maximum variance — ranked, so state dim 1 immediately explains the dominant mode of the
data, state dim 2 the next, etc. Columns are orthonormal.

**Why this matters**: without SVD init, C points at low-variance directions. Residuals are
large, R compensates by growing, and EM has to simultaneously *discover* C's directions and
learn dynamics A — two objectives fighting each other on a poorly conditioned surface. With
SVD init, EM starts aligned and only refines from there.

**Shape `(emissionDim × state_dim)`**: each of the `state_dim` columns is a principal
direction in the `emissionDim`-dimensional observation space. The ranking ensures each state
dimension has a well-defined, non-redundant job from the first iteration.

### Fix 4 — Noise covariances: identity scaled to data variance

```python
data_var = float(np.var(emissions))
Q_init   = 0.1 * data_var * np.eye(state_dim)    # dynamics noise
R_init   = 0.1 * data_var * np.eye(emissionDim)  # emission noise
P0_init  = data_var * np.eye(state_dim)           # initial state covariance
```

Identity = "no prior on relative scale between dimensions." Scaling by `data_var` anchors
noise magnitude to the actual data scale — without this, Kalman gain is wildly miscalibrated
on iteration 1 and recovery compounds over many iterations.

---

## EM overview

Each iteration alternates:
- **E-step**: Kalman filter/smoother infers most likely state trajectory `z_1…z_T` given
  current parameters
- **M-step**: Analytically solves for C, A, Q, R that maximize likelihood under those states

C is updated each M-step as a least-squares regression of `y_t` onto smoothed `z_t` — it
naturally drifts toward variance-explaining directions. SVD initialization means EM starts
close to the solution and spends iterations on dynamics/noise refinement, not rediscovering C.

---

## Data scaling note

`mdlObj_ssm` holds a `py.stdScaler` (sklearn StandardScaler) — standardize emissions before
passing to `fit()` so covariance initialization scales correctly. The `data_var` in Fix 4
assumes standardized data (variance ≈ 1 per channel); if not standardized, `data_var` will
still adapt correctly but the 0.1 prefactors on Q/R may need tuning.

---

## Headline

`mdlObj_ssm` accepts an optional `headline` arg (last positional):

```matlab
mdlObj = mdlObj_ssm(Parent, Origin, dfID_source, headline)
```

Passed through to `mdlObject` base constructor → `applyHeadline()` sets `Figure.fh.Name`
after the figure is built. Pass `[]` or omit to leave the title bar at the MATLAB default.

---

## Save / Load

MATLAB `save()` cannot serialize Python handles. `saveFit` / `loadFit` route each artifact
through the appropriate serializer into a single self-contained folder:

```
FTR/mdlObj_ssm_{uniqueID}/
    lgssm.npz              ← JAX params as numpy arrays   (LGSSM.save / LGSSM.load)
    scaler.pkl             ← sklearn StandardScaler        (LGSSM.save_pickle / load_pickle)
    reducer_models.pkl     ← cell of per-block sklearn models (pickle via mdlObj_reducer)
    reducer_meta.mat       ← block indices, binEdges, modelID  (MATLAB save/load)
```

**Save:**
```matlab
mdlObj.saveFit("myExperiment_20260420");
```

**Load** (folder picker or explicit path):
```matlab
mdlObj.loadFit();                                  % opens uigetdir
mdlObj.loadFit("/path/to/mdlObj_ssm_myExperiment_20260420");
```

### Python serialization helpers (`lgssm_dynamax.LGSSM`)

| Method | Purpose |
|--------|---------|
| `LGSSM.save(path)` | Extract all JAX arrays → `numpy.savez` |
| `LGSSM.load(path)` | Reconstruct `LinearGaussianSSM` + params from `.npz` |
| `LGSSM.save_pickle(obj, path)` | Generic pickle — used for scaler and any other Python object |
| `LGSSM.load_pickle(path)` | Generic unpickle |

### Reducer save / load (`mdlObj_reducer`)

`mdlObj_reducer.save(fitDir)` / `load(fitDir)` handle their own artifacts internally.
Uses `pickle` directly (not through LGSSM) — the Reducer is model-agnostic (PCA, etc.).
MATLAB metadata (`ax`, `modelID`, `nComponents`) saved separately to `reducer_meta.mat`.
