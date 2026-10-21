"""Check 3: N=1 gives FC2 = FC3 = Inf and EXP2 = EXP3 = NaN exactly, and psd_clean matches an independent one-knee formula."""
import numpy as np

from conftest import config_path
from groundtruthgen import generate_ground_truth


def test_n1_fills_and_curve():
    for r in generate_ground_truth(1, 200, config_path(1), seed=3).rows:
        v, f = np.asarray(r.true_params), np.asarray(r.f)
        assert r.N == 1
        assert np.isinf(v[5]) and np.isinf(v[6]) and v[5] > 0 and v[6] > 0
        assert np.isnan(v[2]) and np.isnan(v[3])
        OFF, EXP1, FC1, peaks = v[0], v[1], v[4], v[7:].reshape(-1, 3)
        expected = 10 * OFF - 10 * EXP1 * 0.5 * np.log10(1 + (f / FC1) ** 2)  # single Lorentzian knee, slope -EXP1 above FC1
        for cf, pw, bw in peaks:
            expected += 10 * pw * np.exp(-(f - cf) ** 2 / (2 * bw ** 2))
        np.testing.assert_allclose(r.psd_clean, expected, rtol=1e-12, atol=1e-9)
