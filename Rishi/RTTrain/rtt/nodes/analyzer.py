"""Analyzer agent (LLM, vision): reads the plot, stats and flags, explains the problem, proposes fit settings."""
import json
from typing import Literal

import numpy as np
from pydantic import BaseModel, Field

from rtt import prompts
from rtt.configuration import CONFIG
from rtt.nodes.orchestrator import over_budget
from rtt.state import State
from rtt.tools.fitting import fit, score
from rtt.tools.flags import compute_flags
from rtt.tools.plots import fit_png
from rtt.utils import ask, clean, image_block
from sp_config import CFG

HINT_KEYS = ("ap_exp_tol", "ap_fk_tol", "max_n_peaks", "peak_threshold", "f_range", "line_noise", "extra_peaks")


class Hints(BaseModel):
    problem: str = Field(description="One or two sentences: what is wrong with the current fit")
    ap_exp_tol: float | None = Field(description="Knee exponent tolerance (fraction), or null to keep")
    ap_fk_tol: float | None = Field(description="Knee frequency tolerance (factor > 1), or null to keep")
    max_n_peaks: int | None = Field(description="Peak cap 1-10, or null to keep")
    peak_threshold: float | None = Field(description="Peak threshold in SDs, or null to keep")
    f_range: list[float] | None = Field(description="[low, high] Hz to fit, or null to keep")
    line_noise: Literal["label", "exclude"]
    extra_peaks: list[float] = Field(description="Centre frequencies (Hz) of missed peaks; empty if none")


def analyzer(state: State) -> dict:
    u = state["unit"]
    f, y = np.asarray(u["f"]), np.asarray(u["spectrum"])
    label = u["label"] or fit(f, y, {})[0]  # first pass: look at a default fit
    qc = score(f, y, label)
    flags = compute_flags(f, y, label, qc)
    if over_budget(state, 1): return {"notes": "LLM budget reached; kept current settings", "flags": flags}

    current = {k: CFG[k] for k in HINT_KEYS} | state.get("hints", {})
    feedback = [f"{v['model']}: {v['vote']}. {' '.join(v['reasons'])} {v['suggested_change']}" for v in state.get("council") or []]
    facts = {"qc": qc, "flags": flags, "current_settings": current, "council_feedback": feedback, "synthetic": u["synthetic"]}
    h, usage = ask(CONFIG.analyzer_model, prompts.ANALYZER,
                   [image_block(fit_png(f, y, label, u["unit_id"])), {"type": "text", "text": json.dumps(clean(facts), indent=1)}], Hints)
    if h is None: return {"notes": "analyzer declined; kept current settings", "flags": flags, "usage": [usage]}
    hints = state.get("hints", {}) | h.model_dump(exclude={"problem"}, exclude_none=True)
    return {"hints": hints, "notes": h.problem, "flags": flags, "usage": [usage]}
