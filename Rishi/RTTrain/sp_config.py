"""Single source of truth for paths and fit settings."""
from pathlib import Path  # path handling

HERE = Path(__file__).parent  # RTTrain/ folder
RISHI = HERE.parent  # Rishi/ folder: raw data and the reference screenshot stay there
SRC_H5 = RISHI / "nexDTS_specparam_fitScope.h5"  # raw spectra (read-only)
SRC_GROUP = "date/2025-06-30_subj/0020-06302025_geno/Wt_npxls/R-npx10_phase/L-hind-paw_g0/trial_0023/specparam_fitScope"  # group holding df/t/f/chans
REF_PNG = RISHI / "reference_fit.png"  # screenshot of the hand-tuned fit
REF_H5 = HERE / "reference_fit.h5"  # reference fit rebuilt from the screenshot, segmented-kernel layout (sp_reference.py)
OUT_H5 = HERE / "nexDTS_specparam_fits.h5"  # batch results (new file)
FIG_DIR = HERE / "figures"  # all output plots

REF_T_IDX, REF_CHAN = 9, 10  # reference spectrum: time index (0-based, t=-2.598 s), channel number (1-based)

# Seed aperiodic shape [OFF, EXP1, EXP2, EXP3, log10 FC1, log10 FC2, log10 FC3] for the segmented kernel,
# converted from the fitparams.mat seed (plateau -113 dB; knees at 3.2, 8.7, 60 Hz; slopes -1, -8.5, -59 dB/decade)
SEED_AP = [-11.3, 0.1, 0.85, 5.9, 0.5, 0.94, 1.78]

CFG = dict(  # automated fit settings (all power units are dB, widths are Gaussian sigma in Hz); the analyzer's hints override these
    f_range=(2, 249),  # fit range in Hz, same as fitScope viewer (1 < f < 250)
    n_knees=3,  # aperiodic knees: EXP1-3 / FC1-3, matches kernel_specparam_segmented_multiexp
    max_n_peaks=10,  # peak slots, matches the kernel's CF1..CF10
    peak_width_limits=(3.0, 8.0),  # allowed sigma range for peaks (Hz)
    peak_threshold=1.0,  # stop peak search when max residual < this many SDs of the flattened spectrum
    min_peak_height=2.0,  # ...or when it is below this many dB
    ap_exp_tol=0.25,  # each knee exponent may move +/- this fraction from the seed (looser than the skewed-kernel 0.1: new knee shape)
    ap_fk_tol=1.5,  # each knee frequency may move by up to this factor from the seed
    ap_percentile=13.0,  # robust aperiodic fit keeps residuals below this percentile (lower envelope)
    overlap_sd=0.75,  # drop the weaker of two peaks whose centers are within this many sigmas
    cf_bound_sd=1.5,  # joint Gaussian fit keeps each CF within this many sigmas of its seed
    final_joint=False,  # joint polish of aperiodic + peaks at the end (off: lets the aperiodic drift up into the peaks)
    line_freq=60.0,  # mains frequency used to label line-noise peaks
    line_tol=2.0,  # a peak within this many Hz of k*line_freq is flagged as line noise
    line_noise="label",  # "label": keep line-noise peaks as labeled peaks; "exclude": drop those bins from the fit
    extra_peaks=(),  # CFs (Hz) to seed even if the peak search misses them (analyzer hint)
)
