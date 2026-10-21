"""Check 1: kernel.py matches kernel_specparam_segmented_multiexp.m (complex form) to floating-point precision."""
import numpy as np
import pytest

from groundtruthgen.kernel import kernel
from matlab_ports import kernel_matlab

f = np.linspace(2, 249, 248)
CASES = [  # (OFF, d, FC, peaks)
    (10.0, [2.0, 12.0, 25.0], [7.0, 63.0, 250.0], [[20.0, 0.4, 3.0]]),  # kernel defaults
    (-11.3, [0.1, 0.85, 5.9], [3.2, 8.7, 60.3], []),
    (8.0, [1.5, 10.0, 0.0], [5.0, 40.0, np.inf], [[12.0, 0.2, 2.0], [60.0, 0.5, 1.0]]),  # N=2
    (9.0, [3.0, 0.0, 0.0], [10.0, np.inf, np.inf], []),  # N=1
]


@pytest.mark.parametrize("OFF,d,FC,peaks", CASES)
def test_kernel_matches_matlab(OFF, d, FC, peaks):
    args = {"OFF": OFF, **{f"EXP{k + 1}": d[k] for k in range(3)}, **{f"FC{k + 1}": FC[k] for k in range(3)}}
    for j, (cf, pw, bw) in enumerate(peaks, 1):
        args |= {f"CF{j}": cf, f"PW{j}": pw, f"BW{j}": bw}
    np.testing.assert_allclose(kernel(f, OFF, d, FC, peaks), kernel_matlab(f, args), rtol=1e-12, atol=1e-9)
