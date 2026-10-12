"""Single source of truth for paths and fit settings."""
from pathlib import Path  # path handling

HERE = Path(__file__).parent  # Rishi/ folder
SRC_H5 = HERE / "nexDTS_specparam_fitScope.h5"  # raw spectra (read-only)
SRC_GROUP = "date/2025-06-30_subj/0020-06302025_geno/Wt_npxls/R-npx10_phase/L-hind-paw_g0/trial_0023/specparam_fitScope"  # group holding df/t/f/chans
REF_PNG = HERE / "reference_fit.png"  # screenshot of the hand-tuned fit
REF_H5 = HERE / "reference_fit.h5"  # reference fit rebuilt from the screenshot
OUT_H5 = HERE / "nexDTS_specparam_fits.h5"  # batch results (new file)
FIG_DIR = HERE / "figures"  # all output plots

REF_T_IDX, REF_CHAN = 9, 10  # reference spectrum: time index (0-based, t=-2.598 s), channel number (1-based)

CFG = dict(  # automated fit settings, tuned by grid search to reproduce reference_fit.png (all power units are dB, widths are Gaussian sigma in Hz)
    f_range=(2, 249),  # fit range in Hz, same as fitScope viewer (1 < f < 250)
    n_knees=3,  # aperiodic knees, matches kernel_specparam_skewed_multiexp
    max_n_peaks=10,  # peak slots, matches the kernel's CF1..CF10
    peak_width_limits=(3.0, 8.0),  # allowed sigma range for peaks (Hz)
    peak_threshold=1.0,  # stop peak search when max residual < this many SDs of the flattened spectrum
    min_peak_height=2.0,  # ...or when it is below this many dB
    ap_exp_tol=0.1,  # each knee exponent may move +/- this fraction from the reference
    ap_fk_tol=1.05,  # each knee frequency may move by up to this factor from the reference
    ap_percentile=13.0,  # robust aperiodic fit keeps residuals below this percentile (lower envelope)
    overlap_sd=0.75,  # drop the weaker of two peaks whose centers are within this many sigmas
    cf_bound_sd=1.5,  # joint Gaussian fit keeps each CF within this many sigmas of its seed
    final_joint=False,  # joint polish of aperiodic + peaks at the end (off: lets the aperiodic drift up into the peaks)
    line_freq=60.0,  # mains frequency used to label line-noise peaks
    line_tol=2.0,  # a peak within this many Hz of k*line_freq is flagged as line noise
)
