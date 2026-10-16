"""Collector and writer tools: read a nexDTS h5, write normalized arrays, write labels with provenance."""
import json
import re
from pathlib import Path

import h5py
import numpy as np

import sp_core as sp


def find_group(h: h5py.File) -> str:
    """First group holding df, t, f and chans (nexDTS layout)."""
    found = []
    h.visititems(lambda name, obj: found.append(name)
                 if isinstance(obj, h5py.Group) and {"df", "t", "f", "chans"} <= set(obj) else None)
    if not found: raise ValueError("no group with df, t, f, chans in this file")
    return found[0]


def load_nexdts(path):
    """Return df (t, chan, f) in dB with f > 0, the axes, a run_id and the checks that were run."""
    with h5py.File(path, "r") as h:
        name = find_group(h)
        df = h[name]["df"][()]
        t, f, chans = (h[name][k][()].ravel() for k in ("t", "f", "chans"))
    axes = {len(t): "t", len(chans): "chan", len(f): "f"}
    if len(axes) < 3 or sorted(df.shape) != sorted(axes): raise ValueError(f"cannot match df {df.shape} to t/chans/f lengths")
    checks = {"group": name, "axes_on_disk": [axes[n] for n in df.shape]}
    df = df.transpose([df.shape.index(n) for n in (len(t), len(chans), len(f))])  # -> (t, chan, f)
    keep = f > 0  # log-frequency kernel needs f > 0
    df, f = df[..., keep], f[keep]
    checks["dropped_f0_bins"] = int((~keep).sum())
    checks["converted_to_dB"] = bool(np.nanmin(df) >= 0)  # dB power is negative here; all >= 0 means linear power
    if checks["converted_to_dB"]: df = 10 * np.log10(df)
    date, trial = re.search(r"\d{4}-\d{2}-\d{2}", name), re.search(r"trial_\d+", name)
    run_id = f"{date.group()}_{trial.group()}" if date and trial else Path(path).stem
    return df, t, f, chans, run_id, checks


def write_normalized(path, df, t, f, chans, checks):
    """Collector output: df (t, chan, f) in dB plus axes and the checks that passed."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with h5py.File(path, "w") as h:
        h["df"], h["t"], h["f"], h["chans"] = df, t, f, chans
        h.attrs["checks"] = json.dumps(checks)


def write_label(path, unit, label, provenance):
    """Store one 37-param label with its spectrum and provenance; writing the same unit_id again overwrites it."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with h5py.File(path, "a") as h:
        h.attrs["nParams"], h.attrs["kernel"] = sp.PARAM_LABELS, str(sp.KERNEL)
        if unit["unit_id"] in h: del h[unit["unit_id"]]
        g = h.create_group(unit["unit_id"])
        g["label"], g["f"], g["spectrum"] = np.asarray(label, float), unit["f"], unit["spectrum"]
        g.attrs["provenance"] = json.dumps(provenance)
