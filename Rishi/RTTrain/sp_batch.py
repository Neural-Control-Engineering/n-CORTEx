"""Steps 4-6: fit every (time, channel) spectrum, save in the df_fit layout, make QC plots."""
import json  # config serialization
import warnings  # silence optimizer warnings in workers
from multiprocessing import Pool  # parallel fitting
import h5py  # HDF5 I/O
import matplotlib; matplotlib.use("Agg")  # headless plotting
import matplotlib.pyplot as plt  # plotting
import numpy as np  # arrays
import sp_core as sp  # lab kernel + fitting
from sp_config import CFG, REF_H5, OUT_H5, FIG_DIR  # settings

NP = len(sp.PARAM_LABELS)  # 37 kernel parameters


def fit_row(args):
    """Fit all channels of one time point; failed fits -> NaN params, success=False."""
    F, Y, ap0 = args  # frequencies, (chan, f) spectra, reference aperiodic shape
    warnings.filterwarnings("ignore")  # quiet workers
    out = np.full((len(Y), NP), np.nan)  # params
    qc = np.full((len(Y), 3), np.nan)  # r2, mae, n_peaks
    for c, y in enumerate(Y):  # each channel
        try:
            ap, pk, r2, mae = sp.fit_spectrum(F, y, ap0)  # paper procedure
            out[c], qc[c] = sp.to_kernel(ap, pk), (r2, mae, len(pk) // 3)  # store
        except Exception:
            pass  # leave NaNs; success flag derives from them
    return out, qc  # one time row


def main():
    FIG_DIR.mkdir(exist_ok=True)  # output folder
    df, t, f, chans = sp.load()  # (t, chan, f) dB
    m = (f >= CFG["f_range"][0]) & (f <= CFG["f_range"][1])  # fit range (drops f=0)
    F = f[m]  # fit frequencies
    ap0, _ = sp.from_kernel(h5py.File(REF_H5, "r")["DF/df_fit"][0, 0])  # reference aperiodic shape
    with Pool() as pool:  # all cores
        rows = pool.map(fit_row, [(F, df[i][:, m], ap0) for i in range(len(t))])  # one task per time point
    df_fit = np.stack([r[0] for r in rows])  # [t x chans x nParams]
    qc = np.stack([r[1] for r in rows])  # [t x chans x 3]
    ok = ~np.isnan(df_fit[..., 0])  # success flag
    cf = df_fit[..., 7::3]  # peak centers [t x chans x 10]
    line = sp.is_line_noise(np.nan_to_num(cf)) & ~np.isnan(cf)  # line-noise label per peak slot

    with h5py.File(OUT_H5, "w") as h:  # new file; source untouched
        h["DF/df_fit"] = df_fit  # params, kernel order, NaN-padded peak slots
        h["DF/ax_fit/t"], h["DF/ax_fit/chans"] = t, chans  # axes
        h["DF/ax_fit/nParams"] = np.array(sp.PARAM_LABELS, dtype="S")  # parameter labels
        h["DF/ax_fit/kernel"] = str(sp.KERNEL)  # kernel metadata
        h["DF/qc/r2"], h["DF/qc/mae"] = qc[..., 0], qc[..., 1]  # goodness of fit
        h["DF/qc/n_peaks"], h["DF/qc/success"] = qc[..., 2], ok  # peak count, success flag
        h["DF/qc/is_line_noise"] = line  # per peak slot
        h["DF"].attrs["cfg"] = json.dumps(CFG)  # settings used
        h["DF"].attrs["dims"] = "df_fit is [t, chans, nParams] (MATLAB h5read shows it reversed)"  # axis note
    print(f"saved {OUT_H5.name}: df_fit {df_fit.shape}, success {ok.mean():.1%}, "
          f"R2 median {np.nanmedian(qc[..., 0]):.3f} (5th pct {np.nanpercentile(qc[..., 0], 5):.3f}), "
          f"peaks median {np.nanmedian(qc[..., 2]):.0f}")  # summary
    for k in (1, 2, 3, 4): print(f"  peak within ±{CFG['line_tol']:.0f} Hz of {60*k} Hz in {(line & (np.abs(cf - 60*k) <= CFG['line_tol'])).any(-1).mean():.0%} of spectra")  # line-noise prevalence

    b = 10 * df_fit[..., 0]  # aperiodic plateau (dB): 10*OFF
    maps = [("R²", qc[..., 0], (0.8, 1)), ("n peaks", qc[..., 2], None), ("aperiodic offset 10*OFF (dB)", b, None),
            ("EXP1", df_fit[..., 1], None), ("EXP2", df_fit[..., 2], None), ("EXP3", df_fit[..., 3], None)]  # QC panels
    fig, axs = plt.subplots(2, 3, figsize=(18, 9))  # heatmap grid
    for a, (name, z, lim) in zip(axs.flat, maps):  # each map
        im = a.imshow(z.T, aspect="auto", origin="lower", extent=[t[0], t[-1], chans[0], chans[-1]],
                      cmap="viridis", vmin=lim and lim[0], vmax=lim and lim[1])  # channel x time
        a.axvline(0, color="w", lw=0.8, ls="--"); a.set(title=name, xlabel="t (s)", ylabel="channel")  # stimulus at t=0
        fig.colorbar(im, ax=a)  # scale
    fig.tight_layout(); fig.savefig(FIG_DIR / "qc_heatmaps.png", dpi=100)  # save

    rng = np.random.default_rng(0)  # reproducible sample
    good = np.argwhere(ok)  # successful fits
    worst = good[np.argsort(qc[ok][:, 0])[:6]]  # 6 lowest R²
    rand = good[rng.choice(len(good), 6, replace=False)]  # 6 random
    fig, axs = plt.subplots(3, 4, figsize=(22, 13))  # sample grid
    for a, (i, c), tag in zip(axs.flat, np.r_[rand, worst], ["random"] * 6 + ["worst"] * 6):  # each sample
        full, ap = sp.kernel_eval(F, df_fit[i, c])  # curves from saved params
        sp.plot_fit(a, F, df[i, c, m], full, ap, f"{tag}: ch{chans[c]:.0f} t={t[i]:.1f}s R²={qc[i, c, 0]:.3f}")  # overlay
    fig.tight_layout(); fig.savefig(FIG_DIR / "qc_samples.png", dpi=90)  # save
    print("saved figures/qc_heatmaps.png, figures/qc_samples.png")  # done


if __name__ == "__main__":
    main()  # run
