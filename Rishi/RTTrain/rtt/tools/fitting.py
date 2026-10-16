"""Labeler tools: fit one spectrum with the 37-param lab kernel and score it."""
import numpy as np

import sp_core as sp
from sp_config import CFG, SEED_AP


def score(f, y, label) -> dict:
    """R², MAE (dB) and peak count of a label against a dB spectrum."""
    v = np.asarray(label, float)
    if not np.isfinite(v[:7]).all(): return dict(r2=float("nan"), mae=float("nan"), n_peaks=0)
    res = y - sp.kernel_eval(f, v)[0]
    return dict(r2=float(1 - np.mean(res ** 2) / y.var()), mae=float(np.abs(res).mean()),
                n_peaks=int(np.isfinite(v[7::3]).sum()))


def fit(f, y, hints: dict) -> tuple[list[float], dict]:
    """Fit with CFG overridden by the analyzer's hints. Returns (label, qc); a failed fit gives a NaN label."""
    cfg = {**CFG, **hints}
    r = cfg["f_range"]
    cfg["f_range"] = (min(r), max(r)) if len(r) >= 2 else CFG["f_range"]
    cfg["max_n_peaks"] = int(np.clip(cfg["max_n_peaks"], 1, sp.N_PEAKS))
    m = (f >= cfg["f_range"][0]) & (f <= cfg["f_range"][1])
    if cfg["line_noise"] == "exclude": m &= ~sp.is_line_noise(f, cfg)
    try:
        ap, pk, _, _ = sp.fit_spectrum(f[m], y[m], SEED_AP, cfg)
        label = sp.to_kernel(ap, pk)
    except (ValueError, np.linalg.LinAlgError):
        label = np.full(len(sp.PARAM_LABELS), np.nan)
    return label.tolist(), score(f, y, label)
