"""Writers (code only): accepted labels -> training/accepted/, everything a human must see -> review queue."""
from rtt.configuration import DIRS
from rtt.state import State
from rtt.tools import review_queue
from rtt.tools.h5io import write_label


def result(state: State, route: str, reason: str) -> dict:
    """One row of the run report."""
    u, qc = state["unit"], state.get("qc", {})
    return dict(unit_id=u["unit_id"], synthetic=u["synthetic"], route=route, reason=reason, attempts=state.get("attempts", 0),
                r2=qc.get("r2"), mae=qc.get("mae"), flags=state.get("flags", []))


def write_training(state: State) -> dict:
    u = state["unit"]
    prov = dict(route="council" if state.get("council") else "gate", attempts=state.get("attempts", 0), votes=state.get("council", []),
                human_seen=False, synthetic=u["synthetic"], source=u["source"], edits=None, qc=state["qc"], flags=state["flags"])
    write_label(DIRS["accepted"] / f"{state['run_id']}.h5", u, u["label"], prov)
    return {"results": [result(state, "training", state.get("reason", ""))]}


def queue_review(state: State) -> dict:
    u = state["unit"]
    reason = "synthetic" if u["synthetic"] and state["verdict"] == "accept" else state.get("reason", "")
    review_queue.add(dict(run_id=state["run_id"], unit=u, reason=reason, flags=state.get("flags", []), qc=state.get("qc", {}),
                          council=state.get("council", []), notes=state.get("notes", ""), hints=state.get("hints", {}),
                          attempts=state.get("attempts", 0)))
    return {"results": [result(state, "human_review", reason)]}
