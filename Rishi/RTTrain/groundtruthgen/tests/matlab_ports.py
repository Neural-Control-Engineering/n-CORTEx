"""Line-by-line Python ports of the lab's MATLAB code, used only as independent references in the tests.

kernel_specparam_segmented_multiexp.m  -> kernel_matlab (keeps the complex-number form on purpose)
specParam_multiExp.m (+ formatSpecParamOutputs.m, spec2psd.m, spcpmIO_multiSpecs2vector.m) -> specParam_multiExp
Only the caller-supplied-corner path of specParam_multiExp is ported; automatic corner detection
(psdIO_readCornerFrequencies -> smooth_ASLS) is not."""
import numpy as np
from specparam import SpectralModel

MULTIEXP_DEFAULTS = dict(peakWidth_min=4, peakWidth_max=8, numPeaks_max=8, peakHeight_min=0.1, peakThreshold=0.5,
                         fRange_start=2, fRange_end=50)  # CFG HEADER defaults of specParam_multiExp.m


def kernel_matlab(f, a: dict) -> np.ndarray:
    """kernel_specparam_segmented_multiexp.m, literally (args named as in MATLAB: EXP_k here is the kernel's d_k)."""
    f = np.asarray(f, float)
    fit_AP = (-np.log10((1 + (1j * f) / a["FC1"]) ** a["EXP1"])
              - np.log10((1 + (1j * f) / a["FC2"]) ** a["EXP2"])
              - np.log10((1 + (1j * f) / a["FC3"]) ** a["EXP3"]))
    fit_PE = np.zeros(len(f))
    j = 1
    while f"CF{j}" in a:
        fit_PE = fit_PE + a[f"PW{j}"] * np.exp(-(f - a[f"CF{j}"]) ** 2 / (2 * a[f"BW{j}"] ** 2))
        j += 1
    fit_AP_log = 10 * np.log10(np.abs(10 ** (fit_AP + a["OFF"])))
    return fit_AP_log + 10 * fit_PE


def spec2psd(f_spec, spec):
    """spec2psd.m, 'fixed' aperiodic + 'gaussian' periodic (log10 power)."""
    psd = spec[0] - np.log10(f_spec ** spec[1])
    for i in range(2, len(spec), 3):
        mu, A, sigma = spec[i:i + 3]
        if sigma: psd = psd + A * np.exp(-(f_spec - mu) ** 2 / (2 * sigma ** 2))
    return psd


def formatSpecParamOutputs(fg, args):
    """formatSpecParamOutputs.m: [offset, exponent, CF/PW/BW..., zero-padded to numPeaks_max*3]."""
    ap = np.asarray(fg.results.get_params("aperiodic"), float)
    pk = np.atleast_2d(np.asarray(fg.results.get_params("periodic"), float))
    pk = pk[~np.isnan(pk).any(1)].ravel()
    row = np.r_[pk, np.zeros(args["numPeaks_max"] * 3 - len(pk))]
    m = fg.results.metrics.results
    return np.r_[ap, row], (m["error_mae"], m["gof_rsquared"])


def spcpmIO_multiSpecs2vector(SPEC):
    """spcpmIO_multiSpecs2vector.m: [OFF of segment 1, EXP per segment, FC (segment start) per segment, nonzero peaks]."""
    s_OFF, s_AP, s_FC, s_PE = SPEC[0, 0], [], [], []
    for r in SPEC:
        s_AP.append(r[1])
        r_PE = r[2:-1]
        s_PE += list(r_PE[r_PE != 0])
        s_FC.append(r[-1])
    if len(SPEC) < 3:  # MATLAB pads a single slot, as written
        s_AP.append(0); s_FC.append(249)
    return np.r_[s_OFF, s_AP, s_FC, s_PE]


def specParam_multiExp(f_psd, df_psd, args, df_cf):
    """specParam_multiExp.m with caller-supplied corners df_cf. Returns (specs vector, SPEC rows, psd_fit)."""
    fg = SpectralModel(peak_width_limits=(args["peakWidth_min"], args["peakWidth_max"]),
                       max_n_peaks=int(args["numPeaks_max"]),
                       min_peak_height=int(args["peakHeight_min"]),  # MATLAB py.int(0.1) truncates to 0
                       peak_threshold=int(args["peakThreshold"]),  # MATLAB py.int(0.5) truncates to 0
                       aperiodic_mode="fixed", periodic_mode="gaussian", verbose=False)
    df_cf = list(df_cf) + [f_psd[-1]]
    SPEC, psd_fit_all = [], []
    for i, f_end in enumerate(df_cf):
        f_start = args["fRange_start"] if i == 0 else df_cf[i - 1]
        fCond = (f_psd >= f_start) & (f_psd <= f_end)
        if fCond.sum() < 3:
            specs_out, psd_fit = np.zeros(2 + args["numPeaks_max"] * 3), np.zeros(fCond.sum())
        else:
            fg.fit(f_psd[fCond], 10 ** (df_psd[fCond] / 10))
            specs_out, _ = formatSpecParamOutputs(fg, args)
            psd_fit = spec2psd(f_psd[fCond], specs_out)
        psd_fit_all.append(psd_fit)
        SPEC.append(np.r_[specs_out, f_start])
    SPEC = np.array(SPEC)
    return spcpmIO_multiSpecs2vector(SPEC), SPEC, np.concatenate(psd_fit_all)
