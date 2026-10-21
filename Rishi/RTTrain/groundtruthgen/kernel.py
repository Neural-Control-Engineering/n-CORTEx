"""Port of kernel/kernel_specparam_segmented_multiexp.m. Takes the kernel-native increments d (not EXP)."""
import numpy as np

LN10 = np.log(10.0)


def aperiodic(f, OFF, d, FC):
    """Aperiodic part in dB: 10*OFF - sum_k 5*d_k*log10(1 + (f/FC_k)^2).

    This is the real part of the MATLAB form 10*log10|10^(OFF - sum_k log10((1 + i*f/FC_k)^d_k))|.
    FC_k = Inf contributes exactly 0 for any finite d_k (f/Inf = 0)."""
    f = np.asarray(f, float)
    y = np.full(f.shape, 10.0 * OFF)
    for dk, fc in zip(d, FC):
        y -= 5.0 * dk * np.log1p((f / fc) ** 2) / LN10
    return y


def periodic(f, peaks):
    """Sum of Gaussians in log10 power. peaks = rows of [CF, PW, BW]; NaN rows are ignored."""
    f = np.asarray(f, float)
    pk = np.asarray(peaks, float).reshape(-1, 3)
    pk = pk[~np.isnan(pk).any(1)]
    return (pk[:, 1:2] * np.exp(-(f - pk[:, 0:1]) ** 2 / (2 * pk[:, 2:3] ** 2))).sum(0)


def kernel(f, OFF, d, FC, peaks=()):
    """Full curve in dB: fit_AP_log + 10*fit_PE, as in the MATLAB kernel."""
    return aperiodic(f, OFF, d, FC) + 10.0 * periodic(f, peaks)
