"""Labeler (code only): refits with the analyzer's hints using the 37-param lab kernel and scores the fit."""
import numpy as np

from rtt.configuration import CONFIG
from rtt.state import State
from rtt.tools.fitting import fit


def labeler(state: State) -> dict:
    u = state["unit"]
    label, qc = fit(np.asarray(u["f"]), np.asarray(u["spectrum"]), state.get("hints", {}))
    return {"unit": {**u, "N": CONFIG.n_knees, "label": label}, "qc": qc}
