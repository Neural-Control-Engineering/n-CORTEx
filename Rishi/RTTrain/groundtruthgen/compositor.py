"""priors -> d -> kernel -> chi-squared noise -> GroundTruthRow. Generic over parameter names: every draw is
prior_table[name].sample(rng); the only parameter-specific steps are the deterministic ones (cumsum, Inf/NaN fills)."""
import numpy as np

from groundtruthgen import paramspec
from groundtruthgen.kernel import kernel
from groundtruthgen.noise import chi2_noise, noise_amp
from groundtruthgen.priors import load_config, load_prior_table
from groundtruthgen.schemas import GroundTruthDataset, GroundTruthRow

PEAK_KEYS = ("CF", "logPW", "BW")


def check_keys(N: int, table: dict) -> None:
    """The YAML must hold exactly the aperiodic keys for N knees: d_1..d_N and FC1 + increments up to N."""
    need = {"OFF", "logFC1"} | {f"logD{k}" for k in range(1, N + 1)} | {f"logDFC{k}" for k in range(2, N + 1)}
    extra = {f"logD{k}" for k in range(N + 1, 4)} | {f"logDFC{k}" for k in range(N + 1, 4)}
    if missing := need - table.keys(): raise ValueError(f"N={N} config is missing {sorted(missing)}")
    if present := extra & table.keys(): raise ValueError(f"N={N} config must omit {sorted(present)}")


def sample_row(N: int, table: dict, f: np.ndarray, df: float, seed: int, sample_id: str) -> GroundTruthRow:
    rng = np.random.default_rng(seed)
    draw = {name: prior.sample(rng) for name, prior in table.items() if name not in ("count", *PEAK_KEYS)}
    d = np.zeros(paramspec.N_KNEES)  # k > N: never sampled; value is irrelevant because FC_k = Inf
    d[:N] = [draw[f"logD{k}"] for k in range(1, N + 1)]
    FC = np.full(paramspec.N_KNEES, np.inf)
    FC[:N] = np.cumsum([draw["logFC1"]] + [draw[f"logDFC{k}"] for k in range(2, N + 1)])  # ordering by construction
    n_peaks = int(round(table["count"].sample(rng)))
    peaks = np.array([[table[k].sample(rng) for k in PEAK_KEYS] for _ in range(n_peaks)]).reshape(-1, 3)

    psd_clean = kernel(f, draw["OFF"], d, FC, peaks)
    psd_noisy = chi2_noise(psd_clean, df, rng)
    true_params = paramspec.to_vector(draw["OFF"], paramspec.d_to_exp(d, N), FC, peaks)  # d itself is never reported
    return GroundTruthRow(sample_id=sample_id, N=N, seed=seed, true_params=true_params.tolist(), f=f.tolist(),
                          psd_clean=psd_clean.tolist(), psd_noisy=psd_noisy.tolist(), noise_config={"model": "chi2", "df": float(df), "amp": noise_amp(df)})


def generate_ground_truth(N: int, M: int, config_path: str, seed: int | None = None) -> GroundTruthDataset:
    """M samples of (true params, clean spectrum, noisy spectrum) for model order N."""
    cfg, table = load_config(config_path), load_prior_table(config_path)
    if cfg.get("N") != N: raise ValueError(f"{config_path} is for N={cfg.get('N')}, not N={N}")
    if cfg["noise"]["model"] != "chi2": raise ValueError("only the chi2 noise model is implemented")
    check_keys(N, table)
    ax = cfg["frequency_axis"]
    f = np.linspace(ax["f_start"], ax["f_end"], ax["n_points"])
    seeds = np.random.default_rng(seed).integers(0, 2**63, size=M)  # one seed per sample, so any row can be regenerated
    rows = [sample_row(N, table, f, cfg["noise"]["df"], int(s), f"N{N}_{seed}_{i:06d}") for i, s in enumerate(seeds)]
    return GroundTruthDataset(rows=rows, config=cfg, seed=seed)
