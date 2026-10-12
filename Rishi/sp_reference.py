"""Steps 1-3: rebuild the hand-tuned fit from reference_fit.png, validate it on the raw spectrum, compare the automated fit."""
import h5py  # HDF5 I/O
import matplotlib; matplotlib.use("Agg")  # headless plotting
import matplotlib.pyplot as plt  # plotting
import numpy as np  # arrays
from PIL import Image  # image reading
from scipy.optimize import least_squares  # bounded least squares
import sp_core as sp  # lab kernel + fitting
from sp_config import CFG, REF_PNG, REF_H5, FIG_DIR, REF_T_IDX, REF_CHAN  # settings

X0, X1, F0, F1 = 171, 1038, 2.0, 249.0  # screenshot x pixels of f=2 and f=249 Hz (log axis)
Y0, Y1, D0, D1 = 50, 775, -90.0, -160.0  # screenshot y pixels of -90 and -160 dB (linear axis)


def digitize(mask):
    """Mean row per pixel column of a color mask -> (f in Hz, dB)."""
    cols = np.flatnonzero(mask.any(0))  # columns containing the curve
    rows = np.array([np.flatnonzero(mask[:, c]).mean() for c in cols])  # mean curve row per column
    f = 10 ** (np.log10(F0) + (cols - X0) / (X1 - X0) * np.log10(F1 / F0))  # column -> Hz
    return f, D0 + (rows - Y0) / (Y1 - Y0) * (D1 - D0)  # row -> dB


def rendered(fq, F, y):
    """What MATLAB draws: kernel at integer F joined by straight lines in log-f, sampled at fq."""
    return np.interp(np.log10(fq), np.log10(F), y)  # piecewise-linear in log10(f)


def main():
    FIG_DIR.mkdir(exist_ok=True)  # output folder
    df, t, f, chans = sp.load()  # (t, chan, f) dB tensor
    print(f"df (t,chan,f) {df.shape}, t {t[0]:.3f}..{t[-1]:.3f} s, f {f[0]:.0f}..{f[-1]:.0f} Hz, "
          f"chans {chans[0]:.0f}..{chans[-1]:.0f}, dB {df.min():.1f}..{df.max():.1f}")  # step 1 sanity print
    m = (f >= CFG["f_range"][0]) & (f <= CFG["f_range"][1])  # fit range mask (drops f=0)
    F, y = f[m], df[REF_T_IDX, REF_CHAN - 1, m]  # reference raw spectrum

    im = np.asarray(Image.open(REF_PNG).convert("RGB")).astype(int)  # screenshot pixels
    R, G, B = im[..., 0], im[..., 1], im[..., 2]  # channels
    fr, yr = digitize((R > 150) & (R - G > 80) & (R - B > 40))  # red = full fit
    fw, yw = digitize((R > 200) & (G > 200) & (B > 200))  # white dashed = aperiodic

    ap0 = [-113.0, 1.0, 0.5, 8.5, 0.94, 59.0, 1.78]  # seed: aperiodic shape of fitparams.mat
    ap = least_squares(lambda p: rendered(fw, F, sp.ap_curve(F, p)) - yw, ap0, bounds=sp.ap_bounds()).x  # aperiodic <- white line
    flat = rendered(F, fr, yr) - sp.ap_curve(F, ap)  # red minus aperiodic on the integer grid
    seeds = sp.find_peaks(F, flat, dict(CFG, peak_width_limits=(3.0, 8.0), min_peak_height=0.5, peak_threshold=0.0))  # peaks of the hand fit (fixed settings)
    pk = sp.fit_peaks(F, flat, seeds, dict(CFG, peak_width_limits=(3.0, 8.0)))  # Gaussian fit to the hand-fit peaks
    n = len(ap)  # split index
    (alo, ahi), (plo, phi) = sp.ap_bounds(), sp.peak_bounds(pk, dict(CFG, peak_width_limits=(3.0, 8.0)))  # joint bounds
    res = lambda p: np.r_[rendered(fw, F, sp.ap_curve(F, p[:n])) - yw,  # white residual
                          rendered(fr, F, sp.ap_curve(F, p[:n]) + sp.pk_curve(F, p[n:])) - yr]  # red residual
    x = least_squares(res, np.r_[ap, pk], bounds=(np.r_[alo, plo], np.r_[ahi, phi])).x  # joint fit to both curves
    ref = sp.to_kernel(x[:n], x[n:])  # reference in lab kernel encoding
    fit_ref, ap_ref = sp.kernel_eval(F, ref)  # step 2: rebuild curves from params via the kernel
    print(f"digitization error: red {np.abs(rendered(fr, F, fit_ref) - yr).mean():.2f} dB, "
          f"white {np.abs(rendered(fw, F, ap_ref) - yw).mean():.2f} dB (MAE)")  # how well params reproduce the png
    r2_ref = 1 - np.mean((y - fit_ref) ** 2) / y.var()  # reference fit quality on raw data

    with h5py.File(REF_H5, "w") as h:  # save reference in the df_fit layout
        h["DF/df_fit"] = ref[None, None, :]  # [1 x 1 x nParams]
        h["DF/ax_fit/t"], h["DF/ax_fit/chans"] = [t[REF_T_IDX]], [REF_CHAN]  # where it was fit
        h["DF/ax_fit/nParams"] = np.array(sp.PARAM_LABELS, dtype="S")  # parameter labels
        h["DF/ax_fit/kernel"] = str(sp.KERNEL)  # kernel metadata
        h["DF/digitized/red"], h["DF/digitized/white"] = np.c_[fr, yr], np.c_[fw, yw]  # raw digitized points

    ap_a, pk_a, r2_a, mae_a = sp.fit_spectrum(F, y, x[:n])  # step 3: automated fit seeded with reference aperiodic shape
    auto = sp.to_kernel(ap_a, pk_a)  # kernel encoding
    fit_a, apc_a = sp.kernel_eval(F, auto)  # automated curves
    print(f"\nR2 vs raw: reference {r2_ref:.3f} | auto {r2_a:.3f} (MAE {mae_a:.2f} dB) | "
          f"auto-vs-reference curve MAE {np.abs(fit_a - fit_ref).mean():.2f} dB, aperiodic MAE {np.abs(apc_a - ap_ref).mean():.2f} dB")
    print(f"\n{'param':>6} {'reference':>12} {'auto':>12}")  # parameter table header
    for i, lab in enumerate(sp.PARAM_LABELS[:7]): print(f"{lab:>6} {ref[i]:12.4g} {auto[i]:12.4g}")  # aperiodic params
    print(f"{'knee':>6} " + " ".join(f"fk{i+1} {10**x[2+2*i]:6.1f}/{10**ap_a[2+2*i]:6.1f} Hz" for i in range(3)))  # knee Hz, ref/auto
    pr, pa = ref[7:].reshape(-1, 3), auto[7:].reshape(-1, 3)  # peak rows
    pr, pa = pr[~np.isnan(pr[:, 0])], pa[~np.isnan(pa[:, 0])]  # used slots only
    print(f"\n{'ref CF/PW/BW':>22} | {'auto CF/PW/BW':>22} | line")  # peak table header
    for p in pr:  # each reference peak, matched to the nearest automated peak
        q = pa[np.argmin(np.abs(pa[:, 0] - p[0]))] if len(pa) else [np.nan] * 3  # nearest auto peak
        hit = abs(q[0] - p[0]) < 2 * p[2]  # counts as matched if within 2 sigma
        print(f"{p[0]:7.1f}{p[1]:7.1f}{p[2]:7.1f}  | " + (f"{q[0]:7.1f}{q[1]:7.1f}{q[2]:7.1f}" if hit else f"{'missed':>21}")
              + f"  | {'yes' if sp.is_line_noise(p[0]) else ''}")  # row
    extra = [q for q in pa if np.min(np.abs(pr[:, 0] - q[0])) > 2 * q[2]]  # auto peaks with no reference partner
    print("auto-only peaks:", [tuple(np.round(q, 1)) for q in extra])  # list them

    fig, axs = plt.subplots(1, 3, figsize=(20, 6))  # three panels
    axs[0].imshow(im[30:880, 60:1080], extent=[0, 1, 0, 1]); axs[0].axis("off")  # original screenshot (cropped)
    sp.plot_fit(axs[1], F, y, fit_ref, ap_ref, f"reference (from png) on raw ch{REF_CHAN} t={t[REF_T_IDX]:.2f}s  R2={r2_ref:.3f}")  # rebuilt hand fit
    axs[1].plot(fr, yr, ".", color="orange", ms=1.5)  # digitized red points (check alignment)
    sp.plot_fit(axs[2], F, y, fit_a, apc_a, f"automated fit  R2={r2_a:.3f}")  # automated fit
    axs[2].plot(F, fit_ref, color="orange", lw=0.8, alpha=0.7)  # reference for comparison
    for a in axs[1:]: a.set_ylim(-170, -90)  # same y-range as the screenshot
    fig.tight_layout(); fig.savefig(FIG_DIR / "reference_vs_auto.png", dpi=110)  # save
    print(f"\nsaved {REF_H5.name}, figures/reference_vs_auto.png")  # done


if __name__ == "__main__":
    main()  # run
