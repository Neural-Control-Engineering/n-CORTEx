"""Collector (code only): load the h5, check axes against t/f/chans, drop f=0, confirm dB, write normalized arrays.
A groundtruthgen parquet is already normalized (dB, f > 0), so it is passed straight through."""
from pathlib import Path

from rtt.configuration import DIRS
from rtt.state import State
from rtt.tools.h5io import load_nexdts, write_normalized


def collector(state: State) -> dict:
    if gt := state.get("gt_path"):
        return {"run_id": Path(gt).stem, "normalized": gt, "checks": {"source": "groundtruthgen parquet"}}
    df, t, f, chans, run_id, checks = load_nexdts(state["h5_path"])
    out = DIRS["normalized"] / f"{run_id}.h5"
    write_normalized(out, df, t, f, chans, checks)
    return {"run_id": run_id, "normalized": str(out), "checks": checks}
