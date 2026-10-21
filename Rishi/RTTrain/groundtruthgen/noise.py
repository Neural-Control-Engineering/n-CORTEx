"""Chi-squared periodogram noise: noisy = true * chi2_df / df in linear power (df = 2K averaged segments/tapers)."""
import numpy as np
from scipy.special import polygamma
from scipy.stats import chi2

LN10 = np.log(10.0)


def noise_amp(df: float) -> float:
    """Noise amplitude relative to the signal: std of noisy/true linear power = sqrt(2/df). Same at every frequency."""
    return float(np.sqrt(2.0 / df))


def noise_db_spread(df: float) -> float:
    """The same noise seen in dB: std of 10*log10(chi2_df / df) (exact, via the trigamma function)."""
    return float(10.0 / LN10 * np.sqrt(polygamma(1, df / 2.0)))


def chi2_noise(psd_db, df: float, rng: np.random.Generator) -> np.ndarray:
    """dB in, dB out. Bins treated as independent (accepted v1 simplification)."""
    true_linear_power = 10.0 ** (np.asarray(psd_db, float) / 10.0)
    noisy_linear_power = true_linear_power * chi2.rvs(df, size=true_linear_power.shape, random_state=rng) / df
    return 10.0 * np.log10(noisy_linear_power)
