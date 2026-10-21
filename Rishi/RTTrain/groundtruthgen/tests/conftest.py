from pathlib import Path

import pytest
import yaml

from groundtruthgen.priors import load_config

CONFIGS = Path(__file__).resolve().parents[1] / "configs"


def config_path(N: int) -> str:
    return str(CONFIGS / f"priors_N{N}.yaml")


@pytest.fixture
def variant(tmp_path):
    """Copy of the N config with overrides, e.g. variant(2, peaks_off=True, df=1e6)."""
    def make(N: int, peaks_off=False, df=None) -> str:
        cfg = load_config(config_path(N))
        if peaks_off: cfg["peaks"]["count"] = {"mu": 0.0, "sd": 0.0, "min": 0, "max": 0}
        if df is not None: cfg["noise"]["df"] = df
        out = tmp_path / f"priors_N{N}.yaml"
        out.write_text(yaml.safe_dump(cfg))
        return str(out)
    return make
