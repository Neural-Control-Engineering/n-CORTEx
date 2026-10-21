"""Fixed parameter layout (spcpmIO_paramNames.m) and the EXP <-> d conversion.

EXP_k = local log-log slope of band k (what specParam_multiExp.m reports, and what every dataset reports).
d_k   = the kernel's per-knee increment. EXP_k = d_1 + ... + d_k ; d_k = EXP_k - EXP_{k-1}, EXP_0 = 0.
Inactive knees (k > N): FC_k = Inf, EXP_k = NaN."""
import numpy as np

AP_NAMES = ["OFF", "EXP1", "EXP2", "EXP3", "FC1", "FC2", "FC3"]
N_KNEES = 3


def param_names(n_peaks: int) -> list[str]:
    """OFF, EXP1-3, FC1-3, then CF/PW/BW for each peak."""
    return AP_NAMES + [f"{p}{i}" for i in range(1, n_peaks + 1) for p in ("CF", "PW", "BW")]


def d_to_exp(d, N: int) -> np.ndarray:
    """Kernel increments -> reported local slopes; NaN for k > N."""
    exp = np.full(N_KNEES, np.nan)
    exp[:N] = np.cumsum(np.asarray(d, float)[:N])
    return exp


def exp_to_d(EXP) -> np.ndarray:
    """Reported local slopes -> kernel increments; inactive (NaN) slots give d = 0 (their FC is Inf, so the term is dead)."""
    return np.nan_to_num(np.diff(np.r_[0.0, np.asarray(EXP, float)]), nan=0.0)


def to_vector(OFF, EXP, FC, peaks=()) -> np.ndarray:
    """[OFF, EXP1-3, FC1-3, CF1, PW1, BW1, ...]."""
    return np.r_[OFF, EXP, FC, np.asarray(peaks, float).ravel()]


def from_vector(v):
    """Inverse of to_vector: (OFF, EXP[3], FC[3], peaks as rows)."""
    v = np.asarray(v, float)
    return v[0], v[1:4], v[4:7], v[7:].reshape(-1, 3)


def n_active(FC) -> int:
    """Number of active knees (finite FC)."""
    return int(np.isfinite(np.asarray(FC, float)).sum())
