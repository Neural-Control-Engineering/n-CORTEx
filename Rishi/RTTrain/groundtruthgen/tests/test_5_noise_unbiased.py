"""Check 5: for fixed params, noisy draws average toward psd_clean as the draw count grows.

Unbiased in linear power (chi2_df / df has mean 1). The mean of dB values is not expected to match: E[log] != log E."""
import numpy as np

from groundtruthgen.kernel import kernel
from groundtruthgen.noise import chi2_noise, noise_amp


def test_noise_mean_converges():
    f = np.linspace(2, 249, 248)
    clean = kernel(f, 10.0, [2.0, 12.0, 0.0], [7.0, 63.0, np.inf], [[20.0, 0.4, 3.0]])
    rng = np.random.default_rng(5)
    draws = 10 ** (np.array([chi2_noise(clean, 8, rng) for _ in range(20000)]) / 10)  # linear power
    rel = lambda n: np.abs(draws[:n].mean(0) / 10 ** (clean / 10) - 1)
    assert rel(20000).max() < 0.025
    assert rel(20000).mean() < rel(200).mean() / 5  # error shrinks roughly as 1/sqrt(n)
    ratio = draws / 10 ** (clean / 10)  # noisy / true, linear power
    assert abs(ratio.std() - noise_amp(8)) < 0.01  # noiseAmp is the measured relative spread
