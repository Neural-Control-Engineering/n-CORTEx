"""Ground-truth input: turn rows of a groundtruthgen parquet into work units that carry their true parameters."""
import numpy as np
import pyarrow.parquet as pq

from sp_config import CFG


def load_units(path, n: int, run_id: str) -> list[dict]:
    """First n samples, cut to the fit range like real recordings (drops f = 0, 1); the agents see psd_noisy,
    the review page also gets the truth."""
    rows = pq.read_table(path).slice(0, n).to_pylist()
    units = []
    for r in rows:
        f = np.asarray(r["f"])
        m = (f >= CFG["f_range"][0]) & (f <= CFG["f_range"][1])
        units.append(dict(unit_id=f"{run_id}/{r['sample_id']}", t=None, chan=None, f=f[m].tolist(),
                          spectrum=np.asarray(r["psd_noisy"])[m].tolist(), N=None, label=None,
                          truth=dict(N=r["N"], true_params=r["true_params"], psd_clean=np.asarray(r["psd_clean"])[m].tolist(),
                                     seed=r["seed"], noise=r["noise_config"])))
    return units
