"""Spectral parameterization (Donoghue et al. 2020) using the lab kernel kernel_specparam_segmented_multiexp, fit in dB.
Parameter layout follows spcpmIO_paramNames: OFF, EXP1-3, FC1-3, then CF/PW/BW for each of 10 peaks (37 params).
Labels report EXP_k as local slopes (= d_1 + ... + d_k, README_marc.md); the fit itself works in the kernel's increments d."""
import h5py  # HDF5 I/O
import numpy as np  # arrays
from scipy.optimize import least_squares  # bounded nonlinear least squares
from groundtruthgen import paramspec  # fixed layout + EXP <-> d conversion
from groundtruthgen.kernel import aperiodic, kernel  # shared kernel port
from sp_config import SRC_H5, SRC_GROUP, CFG  # paths and fit settings

N_KNEES, N_PEAKS = CFG["n_knees"], CFG["max_n_peaks"]  # kernel sizes (3 knees, 10 peaks)
PARAM_LABELS = paramspec.param_names(N_PEAKS)  # kernel parameter order (37 params)
KERNEL = dict(  # metadata describing how params become a curve
    name="kernel_specparam_segmented_multiexp",  # MATLAB kernel this mirrors
    formula="fit = 10*OFF - 5*sum_k d_k*log10(1+(f/FC_k).^2) + 10*sum_n PW_n*exp(-(f-CF_n).^2/(2*BW_n^2)), d_k = EXP_k - EXP_{k-1}",  # model
    units="fit in dB; OFF and PW in log10 power (x10 = dB); EXP_k = local slope of band k; FC, CF, BW (Gaussian sigma) in Hz; "
          "unused peak slots are NaN; inactive knees FC = Inf, EXP = NaN",  # units
)
COL = dict(bg="black", raw="#3df075", fit="#ff546b", ap="white", axis="#3df075")  # fitScope colors


def load(path=SRC_H5, group=SRC_GROUP):
    """Return df as (t, chan, f) in dB, plus t, f, chans axes."""
    with h5py.File(path, "r") as h:  # open source read-only
        g = h[group]  # data group
        df = g["df"][()].transpose(0, 2, 1)  # on disk (t, f, chan) -> (t, chan, f)
        t, f, chans = (g[k][()].ravel() for k in ("t", "f", "chans"))  # flatten (n,1) axes
    return df, t, f, chans  # dB tensor and axes


def ap_curve(f, ap):
    """Aperiodic curve in dB. ap = [OFF, d1, d2, d3, log10 FC1, log10 FC2, log10 FC3] (kernel increments, not EXP)."""
    return aperiodic(f, ap[0], ap[1:1 + N_KNEES], 10.0 ** np.asarray(ap[1 + N_KNEES:]))  # shared kernel port


def pk_curve(f, pk):
    """Sum of Gaussians in dB. pk = flat [CF, PW(dB), BW, ...]; NaN slots ignored."""
    pk = np.asarray(pk, float).reshape(-1, 3)  # one row per peak
    pk = pk[~np.isnan(pk).any(1)]  # drop empty slots
    return (pk[:, 1:2] * np.exp(-(f - pk[:, 0:1]) ** 2 / (2 * pk[:, 2:3] ** 2))).sum(0)  # summed Gaussians


def to_kernel(ap, pk):
    """Internal (ap with d, pk with PW in dB) -> 37-element label: EXP as local slopes, peaks sorted by CF, NaN-padded."""
    pk = np.asarray(pk, float).reshape(-1, 3) * [1.0, 0.1, 1.0]  # peaks as rows, PW dB -> log10 power
    pk = pk[np.argsort(pk[:, 0])]  # sort by CF (as spcpmIO_sortFitParams); NaN rows go last
    slots = np.full((N_PEAKS, 3), np.nan)  # NaN-padded slots
    slots[:len(pk)] = pk[:N_PEAKS]  # fill used slots
    return paramspec.to_vector(ap[0], paramspec.d_to_exp(ap[1:1 + N_KNEES], N_KNEES), 10.0 ** np.asarray(ap[1 + N_KNEES:]), slots)


def from_kernel(v):
    """37-element label -> internal (ap with d, pk with PW in dB). Reads every CF/PW/BW triplet (no dropped last peak)."""
    OFF, EXP, FC, peaks = paramspec.from_vector(v)
    ap = np.r_[OFF, paramspec.exp_to_d(EXP), np.log10(FC)]  # OFF, d1-3, log10 FC1-3 (Inf for inactive knees)
    return ap, (peaks * [1.0, 10.0, 1.0]).ravel()  # PW log10 power -> dB


def kernel_eval(f, v):
    """Label -> (full fit, aperiodic only) in dB, through the shared kernel port."""
    OFF, EXP, FC, peaks = paramspec.from_vector(v)
    d = paramspec.exp_to_d(EXP)
    return kernel(f, OFF, d, FC, peaks), aperiodic(f, OFF, d, FC)


def ap_bounds(shape=None, cfg=CFG):
    """Bounds for internal aperiodic params; with `shape`, knees stay near that reference shape."""
    if shape is None: return [-50.0] + [0.0] * N_KNEES + [-1.0] * N_KNEES, [50.0] + [30.0] * N_KNEES + [3.5] * N_KNEES  # loose: OFF, E >= 0, FC 0.1..3000 Hz
    e, l = cfg["ap_exp_tol"], np.log10(cfg["ap_fk_tol"])  # relative exponent tolerance, log10 knee tolerance
    E, lfc = np.asarray(shape[1:1 + N_KNEES]), np.asarray(shape[1 + N_KNEES:])  # reference exponents and log knees
    lo = np.r_[-50.0, E * (1 - e), lfc - l]  # lower bounds (OFF wide: real data ~ -11, generated priors ~ +10)
    hi = np.r_[50.0, E * (1 + e), lfc + l]  # upper bounds
    return lo, np.maximum(hi, lo + 1e-6)  # tight bounds, every interval non-empty


def fit_ap(f, y, ap0, bounds=None):
    """Least-squares aperiodic fit from seed ap0."""
    lo, hi = bounds or ap_bounds()  # bounds
    return least_squares(lambda p: ap_curve(f, p) - y, np.clip(ap0, lo, hi), bounds=(lo, hi)).x  # fitted params


def robust_ap(f, y, ap0, q, bounds):
    """Paper step a: fit, keep points below the q-th residual percentile, refit (lower-envelope fit)."""
    ap0 = np.array(ap0, float)  # copy seed
    ap0[0] += np.percentile(y - ap_curve(f, ap0), q) / 10.0  # shift seed offset onto this spectrum (OFF is log10 units)
    ap = fit_ap(f, y, ap0, bounds)  # first-pass fit on all points
    keep = (y - ap_curve(f, ap)) <= np.percentile(y - ap_curve(f, ap), q)  # points least likely to be peaks
    return fit_ap(f[keep], y[keep], ap, bounds)  # refit on those points only


def find_peaks(f, flat, cfg):
    """Paper step c: iteratively take the max of the flattened spectrum, estimate a Gaussian, subtract."""
    flat, df, seeds = flat.copy(), f[1] - f[0], []  # working copy, frequency step, peak seeds
    lo, hi = cfg["peak_width_limits"]  # sigma limits
    for _ in range(cfg["max_n_peaks"]):  # at most max_n_peaks
        i = int(np.argmax(flat)); h = flat[i]  # tallest remaining point
        if h < max(cfg["min_peak_height"], cfg["peak_threshold"] * flat.std()): break  # below noise floor -> stop
        below = flat < h / 2  # points under half max
        left = i - np.flatnonzero(below[:i])[-1] if below[:i].any() else i  # distance to left half-max
        right = np.flatnonzero(below[i:])[0] if below[i:].any() else len(f) - 1 - i  # distance to right half-max
        sd = np.clip(2 * max(min(left, right), 1) * df / (2 * np.sqrt(2 * np.log(2))), lo, hi)  # FWHM (2x shorter side) -> sigma
        seeds.append([f[i], h, sd])  # store seed
        flat -= h * np.exp(-(f - f[i]) ** 2 / (2 * sd ** 2))  # remove it and continue
    return seeds  # list of [CF, PW, BW]


def drop_overlap(seeds, k):
    """Drop the weaker of any two peaks whose centers are within k*(sd1+sd2)."""
    keep = []  # surviving peaks
    for s in sorted(seeds, key=lambda s: -s[1]):  # strongest first
        if all(abs(s[0] - q[0]) > k * (s[2] + q[2]) for q in keep): keep.append(s)  # keep if clear of stronger peaks
    return keep  # filtered seeds


def peak_bounds(pk, cfg):
    """Bounds around current peaks: CF within cf_bound_sd sigmas, PW >= 0, BW within width limits."""
    pk, (wlo, whi), k = np.asarray(pk).reshape(-1, 3), cfg["peak_width_limits"], cfg["cf_bound_sd"]  # rows, limits
    f0, f1 = cfg["f_range"]  # CFs must stay inside the fit range
    lo = np.c_[np.maximum(pk[:, 0] - k * pk[:, 2], f0), np.zeros(len(pk)), np.full(len(pk), wlo)].ravel()  # lower bounds
    hi = np.c_[np.minimum(pk[:, 0] + k * pk[:, 2], f1), np.full(len(pk), np.inf), np.full(len(pk), whi)].ravel()  # upper bounds
    lo, hi = np.minimum(lo, hi - 1e-6), np.maximum(hi, lo + 1e-6)  # keep every interval non-empty
    return lo, hi  # flat bounds


def fit_peaks(f, flat, seeds, cfg):
    """Paper step d: joint multi-Gaussian fit on the flattened spectrum."""
    if not seeds: return np.empty(0)  # nothing to fit
    p0 = np.ravel(seeds)  # seed vector
    lo, hi = peak_bounds(p0, cfg)  # bounds around seeds
    return least_squares(lambda p: pk_curve(f, p) - flat, np.clip(p0, lo, hi), bounds=(lo, hi)).x  # fitted peaks


def fit_spectrum(f, y, ap0, cfg=CFG):
    """Full paper procedure on one dB spectrum. ap0 = reference aperiodic shape (seed + knee bounds). Returns (ap, pk, r2, mae)."""
    abnd = ap_bounds(ap0, cfg)  # knees constrained around the reference shape
    ap = robust_ap(f, y, ap0, cfg["ap_percentile"], abnd)  # a: robust aperiodic fit
    flat = y - ap_curve(f, ap)  # b: flatten
    seeds = drop_overlap(find_peaks(f, flat, cfg), cfg["overlap_sd"])  # c: find peaks, drop overlaps
    extra = [[f[i], max(flat[i], cfg["min_peak_height"]), cfg["peak_width_limits"][0]]
             for i in (int(np.abs(f - cf).argmin()) for cf in cfg["extra_peaks"])]  # analyzer-proposed peaks the search missed
    seeds = (extra + seeds)[:cfg["max_n_peaks"]]  # extras first so the cap never drops them
    pk = fit_peaks(f, flat, seeds, cfg)  # d: joint Gaussian fit
    ap = fit_ap(f, y - pk_curve(f, pk), ap, abnd)  # e-f: refit aperiodic on peak-removed spectrum
    if cfg["final_joint"] and len(pk):  # optional joint polish of everything
        (alo, ahi), (plo, phi) = abnd, peak_bounds(pk, cfg)  # combined bounds
        n = len(ap)  # split index
        x = least_squares(lambda p: ap_curve(f, p[:n]) + pk_curve(f, p[n:]) - y, np.r_[ap, pk],
                          bounds=(np.r_[alo, plo], np.r_[ahi, phi])).x  # joint refit
        ap, pk = x[:n], x[n:]  # unpack
    res = y - ap_curve(f, ap) - pk_curve(f, pk)  # g-h: final residual
    return ap, pk, 1 - np.mean(res ** 2) / y.var(), np.abs(res).mean()  # params, R^2, MAE


def is_line_noise(cf, cfg=CFG):
    """True where a CF sits within line_tol Hz of a multiple of line_freq."""
    lf = cfg["line_freq"]  # mains frequency
    return (np.abs(cf - lf * np.round(cf / lf)) <= cfg["line_tol"]) & (cf >= lf - cfg["line_tol"])  # near k*60, k >= 1


def style_ax(ax, f):
    """fitScope look: black background, green axes, log-frequency x-axis with Hz tick labels."""
    ax.set_facecolor(COL["bg"]); ax.figure.set_facecolor(COL["bg"])  # black canvas
    ax.set_xscale("log")  # log frequency axis
    ticks = np.logspace(np.log10(f[0]), np.log10(f[-1]), 12)  # log-spaced ticks
    ax.set_xticks(ticks, [f"{x:.4g}" for x in ticks], rotation=30); ax.minorticks_off()  # Hz labels
    ax.tick_params(colors=COL["axis"], labelsize=8)  # green ticks
    for s in ax.spines.values(): s.set_color(COL["axis"])  # green spines
    ax.title.set_color(COL["axis"])  # green title


def plot_fit(ax, f, raw, fit=None, ap=None, title=""):
    """Overlay raw (green), full fit (red), aperiodic (white dashed)."""
    ax.plot(f, raw, color=COL["raw"], lw=1.5)  # raw trace
    if fit is not None: ax.plot(f, fit, color=COL["fit"], lw=1)  # full fit
    if ap is not None: ax.plot(f, ap, color=COL["ap"], lw=1, ls="--")  # aperiodic
    ax.set_title(title, fontsize=9); style_ax(ax, f)  # title + style
