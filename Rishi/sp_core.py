"""Spectral parameterization (Donoghue et al. 2020) using the lab kernel kernel_specparam_skewed_multiexp, fit in dB."""
import h5py  # HDF5 I/O
import numpy as np  # arrays
from scipy.optimize import least_squares  # bounded nonlinear least squares
from sp_config import SRC_H5, SRC_GROUP, CFG  # paths and fit settings

LN10 = np.log(10.0)  # ln(10), converts natural log <-> log10
N_KNEES, N_PEAKS = CFG["n_knees"], CFG["max_n_peaks"]  # kernel sizes (3 knees, 10 peaks)
PARAM_LABELS = ["OFF"] + [f"{p}{i}" for i in range(1, N_KNEES + 1) for p in ("EXP", "KNE")] \
    + [f"{p}{i}" for i in range(1, N_PEAKS + 1) for p in ("CF", "PW", "BW")]  # kernel parameter order (37 params)
KERNEL = dict(  # metadata describing how params become a curve
    name="kernel_specparam_skewed_multiexp",  # MATLAB kernel this mirrors
    formula="fit = OFF - sum_i log10(KNE_i + f.^EXP_i) + sum_n PW_n*exp(-(f-CF_n).^2/(2*BW_n^2))",  # model
    units="fit in dB (same units as df); CF, BW (Gaussian sigma) in Hz; PW in dB; unused peak slots are NaN",  # units
)
COL = dict(bg="black", raw="#3df075", fit="#ff546b", ap="white", axis="#3df075")  # fitScope colors


def load():
    """Return df as (t, chan, f) in dB, plus t, f, chans axes."""
    with h5py.File(SRC_H5, "r") as h:  # open source read-only
        g = h[SRC_GROUP]  # data group
        df = g["df"][()].transpose(0, 2, 1)  # on disk (t, f, chan) -> (t, chan, f)
        t, f, chans = (g[k][()].ravel() for k in ("t", "f", "chans"))  # flatten (n,1) axes
    return df, t, f, chans  # dB tensor and axes


def ap_curve(f, ap):
    """Aperiodic curve in dB. ap = [b, E1, log10(fk1), E2, log10(fk2), ...]."""
    lf = np.log10(f)  # log frequency
    y = np.full_like(lf, ap[0], dtype=float)  # start at the low-frequency plateau b
    for E, lfk in zip(ap[1::2], ap[2::2]):  # each knee
        y -= np.logaddexp(0.0, E * (lf - lfk) * LN10) / LN10  # subtract log10(1 + (f/fk)^E), overflow-safe
    return y  # aperiodic dB


def pk_curve(f, pk):
    """Sum of Gaussians. pk = flat [CF, PW, BW, ...]; NaN slots ignored."""
    pk = np.asarray(pk, float).reshape(-1, 3)  # one row per peak
    pk = pk[~np.isnan(pk).any(1)]  # drop empty slots
    return (pk[:, 1:2] * np.exp(-(f - pk[:, 0:1]) ** 2 / (2 * pk[:, 2:3] ** 2))).sum(0)  # summed Gaussians


def to_kernel(ap, pk):
    """Internal (ap, pk) -> 37-element lab kernel vector, peaks sorted by CF, NaN-padded."""
    b, E, lfk = ap[0], np.asarray(ap[1::2]), np.asarray(ap[2::2])  # unpack aperiodic
    v = [b + np.sum(E * lfk)]  # OFF = b + sum log10(KNE_i), since KNE_i = fk_i^E_i
    for e, l in zip(E, lfk): v += [e, 10.0 ** (e * l)]  # EXP_i, KNE_i
    pk = np.asarray(pk, float).reshape(-1, 3)  # peaks as rows
    pk = pk[np.argsort(pk[:, 0])]  # sort by CF (as spcpmIO_sortFitParams)
    slots = np.full((N_PEAKS, 3), np.nan)  # NaN-padded slots
    slots[:len(pk)] = pk[:N_PEAKS]  # fill used slots
    return np.r_[v, slots.ravel()]  # kernel vector


def from_kernel(v):
    """Lab kernel vector -> internal (ap, pk). Assumes EXP_i > 0."""
    E, K = np.asarray(v[1:1 + 2 * N_KNEES:2]), np.asarray(v[2:2 + 2 * N_KNEES:2])  # EXP_i, KNE_i
    lfk = np.log10(K) / E  # knee frequency: fk = KNE^(1/EXP)
    ap = np.r_[v[0] - np.log10(K).sum(), np.c_[E, lfk].ravel()]  # b = OFF - sum log10(KNE)
    return ap, np.asarray(v[1 + 2 * N_KNEES:], float)  # aperiodic, peaks


def kernel_eval(f, v):
    """Exact port of the MATLAB kernel (overflow-safe); returns (full fit, aperiodic only) in dB."""
    lf = np.log(f)  # natural log frequency
    ap = v[0] - sum(np.logaddexp(np.log(K), E * lf) / LN10 for E, K in zip(v[1:7:2], v[2:7:2]))  # OFF - sum log10(K + f^E)
    return ap + pk_curve(f, v[7:]), ap  # full curve, aperiodic curve


def ap_bounds(shape=None, cfg=CFG):
    """Bounds for internal aperiodic params; with `shape`, knees stay near that reference shape."""
    if shape is None: return [-300.0] + [0.0, -1.0] * N_KNEES, [0.0] + [250.0, 3.5] * N_KNEES  # loose: b in dB, E >= 0, fk 0.1..3000 Hz
    e, l = cfg["ap_exp_tol"], np.log10(cfg["ap_fk_tol"])  # relative exponent tolerance, log10 knee tolerance
    E, lfk = np.asarray(shape[1::2]), np.asarray(shape[2::2])  # reference exponents and log knees
    lo = np.r_[-300.0, np.c_[E * (1 - e), lfk - l].ravel()]  # lower bounds
    hi = np.r_[0.0, np.c_[E * (1 + e), lfk + l].ravel()]  # upper bounds
    return lo, hi  # tight bounds


def fit_ap(f, y, ap0, bounds=None):
    """Least-squares aperiodic fit from seed ap0."""
    lo, hi = bounds or ap_bounds()  # bounds
    return least_squares(lambda p: ap_curve(f, p) - y, np.clip(ap0, lo, hi), bounds=(lo, hi)).x  # fitted params


def robust_ap(f, y, ap0, q, bounds):
    """Paper step a: fit, keep points below the q-th residual percentile, refit (lower-envelope fit)."""
    ap0 = np.array(ap0, float)  # copy seed
    ap0[0] += np.percentile(y - ap_curve(f, ap0), q)  # shift seed offset onto this spectrum
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
