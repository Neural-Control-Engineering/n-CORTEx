"""Synthetic spectra: perturb a fitted label, redraw it with the kernel, add back the real spectrum's residual."""
import numpy as np

import sp_core as sp


def make_synthetic(f, y, label, n, rng) -> list[tuple[list[float], list[float]]]:
    """n (spectrum, label) pairs built from one real spectrum and its fit; the label is the exact ground truth."""
    v = np.asarray(label, float)
    noise = y - sp.kernel_eval(f, v)[0]  # real residual = realistic noise
    out = []
    for _ in range(n):
        w = v.copy()
        w[0] += rng.normal(0, 0.05)  # OFF: about ±0.5 dB
        w[1:4] *= rng.uniform(0.95, 1.05, 3)  # EXP1-3
        w[4:7] *= rng.uniform(0.9, 1.1, 3)  # FC1-3
        pk = w[7:].reshape(-1, 3)  # view into w: CF, PW, BW rows
        pk[:, 0] += rng.normal(0, 1.0, len(pk))  # CF ±1 Hz
        pk[:, 1] *= rng.uniform(0.8, 1.2, len(pk))  # PW
        pk[:, 2] *= rng.uniform(0.9, 1.1, len(pk))  # BW
        used = np.flatnonzero(np.isfinite(pk[:, 0]))
        if len(used) and rng.random() < 0.3: pk[rng.choice(used)] = np.nan  # sometimes drop a peak
        w = sp.to_kernel(*sp.from_kernel(w))  # re-sort peaks by CF, NaN slots last
        spectrum = sp.kernel_eval(f, w)[0] + np.roll(noise, rng.integers(len(f)))  # shifted residual keeps its texture
        out.append((spectrum.tolist(), w.tolist()))
    return out
