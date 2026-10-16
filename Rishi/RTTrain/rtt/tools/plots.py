"""Plot renderer: fitScope-style PNGs (fit on top, residual below) for the analyzer and the judges."""
import io

import matplotlib
matplotlib.use("Agg")  # headless
import matplotlib.pyplot as plt
import numpy as np

import sp_core as sp


def fit_png(f, y, label, title="") -> bytes:
    f, y, v = np.asarray(f), np.asarray(y), np.asarray(label, float)
    fig, (top, bottom) = plt.subplots(2, 1, figsize=(8, 6), height_ratios=[3, 1], sharex=True)
    full, ap = sp.kernel_eval(f, v) if np.isfinite(v[:7]).all() else (None, None)
    sp.plot_fit(top, f, y, full, ap, title)
    if full is not None:
        bottom.plot(f, y - full, color=sp.COL["raw"], lw=1)
        bottom.axhline(0, color=sp.COL["ap"], lw=0.6, ls="--")
    sp.style_ax(bottom, f)
    buf = io.BytesIO()
    fig.tight_layout(); fig.savefig(buf, format="png", dpi=90); plt.close(fig)
    return buf.getvalue()
