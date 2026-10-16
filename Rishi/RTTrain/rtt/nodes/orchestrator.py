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
from rtt.utils import ask_text, spend
from sp_config import CFG


# ── nodes ─────────────────────────────────────────────────────────────────────

def planner(state: State) -> dict:
    """Sample the real spectra for this run; each becomes one work unit."""
    with h5py.File(state["normalized"], "r") as h:
        df, t, f, chans = (h[k][()] for k in ("df", "t", "f", "chans"))
    m = (f >= CFG["f_range"][0]) & (f <= CFG["f_range"][1])  # fit range
    n_t, n_c = df.shape[:2]
    picks = np.random.default_rng(CONFIG.seed).choice(n_t * n_c, min(state.get("n_real") or CONFIG.n_real, n_t * n_c), replace=False)
    units = [dict(unit_id=f"{state['run_id']}/t{i}/ch{int(chans[c])}", t=float(t[i]), chan=int(chans[c]), synthetic=False,
                  source=None, f=f[m].tolist(), spectrum=df[i, c, m].tolist(), label=None)
             for i, c in (divmod(int(p), n_c) for p in picks)]
    return {"pending": units, "spawned": []}


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
    summary, usage = ask_text(CONFIG.orchestrator_model, prompts.ORCHESTRATOR_REPORT,
                              json.dumps({"stats": stats | {"spend": spend(state.get("usage", []))}, "units": results}))
    stats["spend"] = spend(state.get("usage", []) + [usage])  # includes this report call
    text = f"# Run {run_id}\n\n{summary}\n\n```json\n{json.dumps(stats, indent=2)}\n```\n"
    (DIRS["runs"] / run_id).mkdir(parents=True, exist_ok=True)
    (DIRS["runs"] / run_id / "report.md").write_text(text)
    return {"report_md": text, "usage": [usage]}


# ── limits ────────────────────────────────────────────────────────────────────

def over_budget(state: State, calls: int) -> bool:
    return len(state.get("usage", [])) + calls > CONFIG.max_llm_calls


def revise_or_human(attempts: int, why: str) -> dict:
    """Another revise cycle while attempts remain, otherwise human review."""
    if attempts < CONFIG.max_attempts: return dict(verdict="revise", attempts=attempts + 1, reason=why)
    return dict(verdict="human", reason=f"{attempts} retries")


# ── routers ───────────────────────────────────────────────────────────────────

def route_next(state: State) -> str:
    u = state.get("unit")
    if u is None: return "report"
    return "gate" if u["label"] is not None else "analyzer"  # synthetic units arrive already labeled


def route_council(state: State) -> str:
    v = state["verdict"]
    if v == "revise": return "analyzer"
    if v == "accept" and not state["unit"]["synthetic"]: return "write_training"
    return "queue_review"  # human verdicts, and every synthetic spectrum


def route_gate(state: State):
    if state["verdict"] == "unclear":  # fan out to the three judges in parallel
        return [Send("judge", {"model": m, "pack": state["pack"]}) for m in CONFIG.judges]
    return route_council(state)
