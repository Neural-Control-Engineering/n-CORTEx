"""Check 2 (critical): at very low noise, specParam_multiExp's per-segment exponents recover the reported EXP1..EXP_N.

Segments are cut at the true corners (FC1 as the fit start, FC2.. as boundaries), so this isolates the EXP <-> d
conversion from corner detection. Peaks are switched off so segment exponents are not pulled by peak fitting."""
import numpy as np
import pytest

from groundtruthgen import generate_ground_truth
from matlab_ports import MULTIEXP_DEFAULTS, specParam_multiExp

REL_TOL = 0.05  # "near-exactly at low noise"


@pytest.mark.parametrize("N", [1, 2, 3])
def test_segment_exponents_recover_EXP(N, variant):
    ds = generate_ground_truth(N, 20, variant(N, peaks_off=True, df=1e6), seed=2)
    errors = []
    for r in ds.rows:
        v, f, y = np.asarray(r.true_params), np.asarray(r.f), np.asarray(r.psd_noisy)
        EXP, FC = v[1:1 + N], v[4:4 + N]
        _, SPEC, _ = specParam_multiExp(f, y, MULTIEXP_DEFAULTS | {"fRange_start": FC[0]}, df_cf=FC[1:])
        errors.append((SPEC[:N, 1] - EXP) / EXP)
    errors = np.array(errors)
    worst = np.abs(errors).max(0)
    assert (worst < REL_TOL).all(), f"N={N}: worst relative error per EXP_k = {np.round(worst, 3)}, mean = {np.round(errors.mean(0), 3)}"
