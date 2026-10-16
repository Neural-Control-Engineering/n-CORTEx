"""Synthetic data (code only): n_synthetic spectra per real spectrum, each its own work unit linked to its source."""
import numpy as np

from rtt.configuration import CONFIG
from rtt.state import State
from rtt.tools.synth import make_synthetic


def synthesizer(state: State) -> dict:
    u = state["unit"]
    if u["synthetic"] or u["unit_id"] in state.get("spawned", []) or not np.isfinite(u["label"][0]):
        return {}  # only once per real spectrum, and only from a usable fit
    pairs = make_synthetic(np.asarray(u["f"]), np.asarray(u["spectrum"]), u["label"], CONFIG.n_synthetic, np.random.default_rng())
    synth = [dict(unit_id=f"{u['unit_id']}/syn{k}", t=u["t"], chan=u["chan"], synthetic=True, source=u["unit_id"],
                  f=u["f"], spectrum=s, label=l) for k, (s, l) in enumerate(pairs)]
    return {"pending": synth + state.get("pending", []), "spawned": state.get("spawned", []) + [u["unit_id"]]}
