"""Interactive viewer for DF (raw dB spectra) and df_fit (kernel params).
Run: python sp_viz.py [fits.h5]   (default: nexDTS_specparam_fits.h5; reference_fit.h5 also works)
Click any heatmap to jump there; arrow keys step time (left/right) and channel (up/down)."""
import ast  # parse kernel metadata string
import sys  # CLI arg
import h5py  # HDF5 I/O
import matplotlib.pyplot as plt  # plotting
import numpy as np  # arrays
from matplotlib.widgets import Slider  # sliders
import sp_core as sp  # load(), kernel_eval(), colors
from sp_config import OUT_H5  # default fits file


def load_fits(path, t, chans):
    """Place df_fit (and QC maps if present) onto the raw (t, chan) grid; NaN where no fit exists."""
    with h5py.File(path, "r") as h:
        ax = h["DF/ax_fit"]
        ix = np.ix_([np.abs(t - x).argmin() for x in ax["t"][()]], [np.abs(chans - c).argmin() for c in ax["chans"][()]])

        def put(a):  # embed a [t_fit x chans_fit x ...] array in the full grid
            g = np.full((len(t), len(chans)) + a.shape[2:], np.nan); g[ix] = a
            return g
        fit = put(h["DF/df_fit"][()])  # [t x chans x nParams]
        labels = [s.decode() for s in ax["nParams"][()]]
        kernel = ast.literal_eval(ax["kernel"][()].decode())
        layers = [(k, put(h[f"DF/qc/{k}"][()].astype(float))) for k in ("r2", "mae", "n_peaks") if f"DF/qc/{k}" in h]
    return fit, kernel, layers + [(n, fit[..., i]) for i, n in enumerate(labels)]


def main(path=OUT_H5):
    df, t, f, chans = sp.load()  # (t, chan, f) dB
    fit, kernel, layers = load_fits(path, t, chans)
    fp = f > 0  # log-x needs f > 0
    lim = np.nanpercentile(df, [1, 99])  # shared color range for raw power

    plt.style.use("dark_background")
    fig, ((aS, aD), (aP, aM)) = plt.subplots(2, 2, figsize=(14, 9))
    fig.subplots_adjust(bottom=0.17, hspace=0.3, wspace=0.25)
    fig.suptitle(f"{kernel['name']}:  {kernel['formula']}", fontsize=9)
    ext_tc = [t[0], t[-1], chans[0], chans[-1]]  # x=time, y=channel

    imS = aS.imshow(df[:, 0].T, aspect="auto", origin="lower", extent=[t[0], t[-1], f[0], f[-1]], clim=lim, cmap="magma")
    aS.set(xlabel="time (s)", ylabel="freq (Hz)"); fig.colorbar(imS, ax=aS, label="dB")
    imD = aD.imshow(df[0], aspect="auto", origin="lower", extent=[f[0], f[-1], chans[0], chans[-1]], clim=lim, cmap="magma")
    aD.set(xlabel="freq (Hz)", ylabel="channel"); fig.colorbar(imD, ax=aD, label="dB")
    imM = aM.imshow(layers[0][1].T, aspect="auto", origin="lower", extent=ext_tc, cmap="viridis", interpolation="nearest")
    aM.set(xlabel="time (s)", ylabel="channel"); cbM = fig.colorbar(imM, ax=aM)

    raw, = aP.plot(f[fp], df[0, 0, fp], color=sp.COL["raw"], lw=1.5, label="raw")
    full, = aP.plot(f[fp], np.full(fp.sum(), np.nan), color=sp.COL["fit"], lw=1, label="fit")
    apc, = aP.plot(f[fp], np.full(fp.sum(), np.nan), color=sp.COL["ap"], lw=1, ls="--", label="aperiodic")
    aP.set(xscale="log", xlabel="freq (Hz)", ylabel="dB"); aP.legend(loc="upper right", fontsize=8)
    info = aP.text(0.02, 0.03, "", transform=aP.transAxes, fontsize=8, family="monospace", va="bottom", bbox=dict(fc="black", alpha=0.6, lw=0))
    peaks = []  # peak marker artists

    cross = [aS.axvline(t[0], color="c", lw=0.8), aD.axhline(chans[0], color="c", lw=0.8),
             aM.axvline(t[0], color="r", lw=0.8), aM.axhline(chans[0], color="r", lw=0.8)]
    sl = lambda y, lab, n: Slider(fig.add_axes([0.12, y, 0.75, 0.025]), lab, 0, n - 1, valinit=0, valstep=1)
    sT, sC, sL = sl(0.08, "time", len(t)), sl(0.05, "channel", len(chans)), sl(0.02, "map", len(layers))

    def draw(_=None):
        i, c, (name, m) = int(sT.val), int(sC.val), layers[int(sL.val)]
        sT.valtext.set_text(f"{t[i]:.3f} s"); sC.valtext.set_text(f"{chans[c]:.0f}"); sL.valtext.set_text(name)
        imS.set_data(df[:, c].T); imD.set_data(df[i])
        imM.set_data(m.T); imM.set_clim(*np.nan_to_num(np.nanpercentile(m, [2, 98]) if np.isfinite(m).any() else [0, 1]))
        aS.set_title(f"spectrogram  ch {chans[c]:.0f}"); aD.set_title(f"channel x freq  t = {t[i]:.3f} s"); aM.set_title(f"df_fit / qc: {name}")
        cbM.set_label(name)
        for a in cross[0::2]: a.set_xdata([t[i]])
        for a in cross[1::2]: a.set_ydata([chans[c]])

        v = fit[i, c]
        raw.set_ydata(df[i, c, fp])
        y, ap = sp.kernel_eval(f[fp], v) if np.isfinite(v[0]) else (np.nan * f[fp],) * 2
        full.set_ydata(y); apc.set_ydata(ap)
        while peaks: peaks.pop().remove()
        pk = v[7:].reshape(-1, 3); pk = pk[np.isfinite(pk).all(1)]  # [CF, PW, BW] rows
        peaks.extend(aP.axvline(cf, color=sp.COL["fit"], ls=":", lw=0.8) for cf in pk[:, 0])
        q = "  ".join(f"{n}={l[i, c]:.3g}" for n, l in layers if n in ("r2", "mae", "n_peaks"))
        info.set_text(("no fit here" if not np.isfinite(v[0]) else q + "\n" + "\n".join(f"CF {a:6.1f} Hz  PW {b:5.2f} (x10 dB)  BW {s:4.1f}" for a, b, s in pk)))
        aP.set_title(f"spectrum  t = {t[i]:.3f} s, ch {chans[c]:.0f}")
        aP.relim(); aP.autoscale_view(); fig.canvas.draw_idle()

    def click(e):
        if e.inaxes in (aS, aM): sT.set_val(np.abs(t - e.xdata).argmin())
        if e.inaxes in (aD, aM): sC.set_val(np.abs(chans - e.ydata).argmin())

    def key(e):
        step = {"right": (sT, 1), "left": (sT, -1), "up": (sC, 1), "down": (sC, -1)}.get(e.key)
        if step: s, d = step; s.set_val(np.clip(s.val + d, s.valmin, s.valmax))

    for s in (sT, sC, sL): s.on_changed(draw)
    fig.canvas.mpl_connect("button_press_event", click); fig.canvas.mpl_connect("key_press_event", key)
    draw(); plt.show()


if __name__ == "__main__":
    main(*sys.argv[1:])
