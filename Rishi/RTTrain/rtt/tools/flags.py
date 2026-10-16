"""Flag calculator: the numeric flags from the blueprint (page 2). Thresholds live in configuration.py."""
import numpy as np

import sp_core as sp
from rtt.configuration import CONFIG
from sp_config import CFG, SEED_AP


def compute_flags(f, y, label, qc, gold_distance=None) -> list[str]:
    v, flags = np.asarray(label, float), []
    if not np.isfinite(qc["r2"]) or qc["r2"] < CONFIG.r2_min or qc["mae"] > CONFIG.mae_max: flags.append("low_fit")
    if qc["n_peaks"] >= CFG["max_n_peaks"]: flags.append("peak_cap")
    if np.isfinite(v[:7]).all():
        ap, _ = sp.from_kernel(v)
        lo, hi = sp.ap_bounds(SEED_AP)
        if (np.isclose(ap[1:], lo[1:], atol=1e-3) | np.isclose(ap[1:], hi[1:], atol=1e-3)).any(): flags.append("knee_at_bound")
    top = f > 150
    if top.sum() > 5 and np.polyfit(np.log10(f[top]), y[top], 1)[0] > CONFIG.rolloff_db_per_decade: flags.append("no_rolloff")
    cf = v[7::3]
    if sp.is_line_noise(cf[np.isfinite(cf)]).any(): flags.append("line_noise")  # labeled, never a reason to reject
    if gold_distance is not None and gold_distance > CONFIG.novel_db: flags.append("novel")
    return flags
