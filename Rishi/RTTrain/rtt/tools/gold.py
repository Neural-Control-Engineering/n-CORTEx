"""Gold retriever: the human-approved fits closest to a spectrum."""
import h5py
import numpy as np

from rtt.configuration import DIRS

GOLD_H5 = DIRS["gold"] / "gold_fits.h5"


def load_gold() -> list[dict]:
    if not GOLD_H5.exists(): return []
    out = []
    with h5py.File(GOLD_H5, "r") as h:
        h.visititems(lambda name, g: out.append(dict(unit_id=name, f=g["f"][()], spectrum=g["spectrum"][()], label=g["label"][()]))
                     if isinstance(g, h5py.Group) and "label" in g else None)
    return out


def curve_distance(f, y, g) -> float:
    """Mean |dB difference| after removing each curve's mean, so it compares shape, not level."""
    gy = np.interp(f, g["f"], g["spectrum"])
    return float(np.abs((y - y.mean()) - (gy - gy.mean())).mean())


def nearest(f, y, k=3) -> list[dict]:
    """The k closest gold examples, each with its distance."""
    return sorted((dict(g, distance=curve_distance(f, y, g)) for g in load_gold()), key=lambda g: g["distance"])[:k]
