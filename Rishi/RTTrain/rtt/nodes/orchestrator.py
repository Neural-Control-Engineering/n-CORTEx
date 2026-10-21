"""Orchestrator agent (code + light LLM): plans the run, hands out work units, routes between stages,
enforces retry and budget limits, writes the run report."""
import json
from collections import Counter

import h5py
import numpy as np
from langgraph.types import Send

from rtt import prompts
from rtt.configuration import CONFIG, DIRS
from rtt.state import State
from rtt.tools.gt_io import load_units
from rtt.utils import ask_text, spend
from sp_config import CFG


# ── nodes ─────────────────────────────────────────────────────────────────────

def planner(state: State) -> dict:
    """Pick the spectra for this run; each becomes one work unit (random sample of a recording, or the first n generated)."""
    n = state.get("n_real") or CONFIG.n_real
    if state.get("gt_path"): return {"pending": load_units(state["gt_path"], n, state["run_id"])}
    with h5py.File(state["normalized"], "r") as h:
        df, t, f, chans = (h[k][()] for k in ("df", "t", "f", "chans"))
    m = (f >= CFG["f_range"][0]) & (f <= CFG["f_range"][1])  # fit range
    n_t, n_c = df.shape[:2]
    picks = np.random.default_rng(CONFIG.seed).choice(n_t * n_c, min(n, n_t * n_c), replace=False)
    units = [dict(unit_id=f"{state['run_id']}/t{i}/ch{int(chans[c])}", t=float(t[i]), chan=int(chans[c]),
                  f=f[m].tolist(), spectrum=df[i, c, m].tolist(), N=None, label=None, truth=None)
             for i, c in (divmod(int(p), n_c) for p in picks)]
    return {"pending": units}


def next_unit(state: State) -> dict:
    """Pop the next work unit and reset the per-unit fields."""
    pending = state.get("pending", [])
    if not pending: return {"unit": None}
    return dict(unit=pending[0], pending=pending[1:], flags=[], hints={}, notes="", qc={}, pack=None,
                council=None, attempts=0, verdict=None, reason="")


def report(state: State) -> dict:
    """Counts per route plus a short LLM summary, saved to runs/<run_id>/report.md."""
    results, run_id = state.get("results", []), state["run_id"]
    stats = dict(run_id=run_id, units=len(results), routes=dict(Counter(r["route"] for r in results)),
                 reasons=dict(Counter(r["reason"] for r in results if r["route"] == "human_review")))
    if CONFIG.agents_enabled:
        summary, usage = ask_text(CONFIG.orchestrator_model, prompts.ORCHESTRATOR_REPORT,
                                  json.dumps({"stats": stats | {"spend": spend(state.get("usage", []))}, "units": results}))
        usage = [usage]
    else:
        summary, usage = "Agents off: code-only run (fit + numeric gate), no API calls.", []
    stats["spend"] = spend(state.get("usage", []) + usage)  # includes the report call, if any
    text = f"# Run {run_id}\n\n{summary}\n\n```json\n{json.dumps(stats, indent=2)}\n```\n"
    (DIRS["runs"] / run_id).mkdir(parents=True, exist_ok=True)
    (DIRS["runs"] / run_id / "report.md").write_text(text)
    return {"report_md": text, "usage": usage}


# ── limits ────────────────────────────────────────────────────────────────────

def over_budget(state: State, calls: int) -> bool:
    return len(state.get("usage", [])) + calls > CONFIG.max_llm_calls


def revise_or_human(attempts: int, why: str) -> dict:
    """Another revise cycle while attempts remain, otherwise human review."""
    if attempts < CONFIG.max_attempts: return dict(verdict="revise", attempts=attempts + 1, reason=why)
    return dict(verdict="human", reason=f"{attempts} retries")


# ── routers ───────────────────────────────────────────────────────────────────

def route_next(state: State) -> str:
    return "report" if state.get("unit") is None else "analyzer"


def route_council(state: State) -> str:
    v = state["verdict"]
    if v == "revise": return "analyzer"
    if v == "accept" and not state["unit"].get("truth"): return "write_training"
    return "queue_review"  # human verdicts, and every generated (ground-truth) spectrum


def route_gate(state: State):
    if state["verdict"] == "unclear":  # fan out to the three judges in parallel
        return [Send("judge", {"model": m, "pack": state["pack"]}) for m in CONFIG.judges]
    return route_council(state)
