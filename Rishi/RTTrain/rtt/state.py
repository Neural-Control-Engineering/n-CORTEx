"""Shared state passed between nodes (blueprint, section 3: shared state)."""
import operator
from typing import Annotated, Literal, TypedDict


def votes(old: list, new: list | None) -> list:
    """Judges append their votes in parallel; None clears them for the next unit."""
    return [] if new is None else old + new


class Unit(TypedDict):
    """One work unit = one spectrum."""
    unit_id: str  # run_id/t<idx>/ch<chan>
    t: float  # seconds
    chan: int  # channel number
    f: list[float]  # Hz, fit range, no f=0
    spectrum: list[float]  # dB
    N: int | None  # model order of the label (explicit, never inferred from FC/EXP values)
    label: list[float] | None  # 37 params: OFF, EXP1-3 (local slopes), FC1-3, CF/PW/BW x10; FC=Inf, EXP=NaN for k > N
    truth: dict | None  # generated spectra only: N, true_params, psd_clean, seed, noise (the agents never see it)


class State(TypedDict, total=False):
    # run
    h5_path: str  # uploaded recording, or...
    gt_path: str  # ...a groundtruthgen parquet
    n_real: int  # spectra to process
    run_id: str  # session_trial
    normalized: str  # collector output path
    checks: dict  # what the collector verified
    pending: list[Unit]  # units still to process
    results: Annotated[list[dict], operator.add]  # one row per finished unit
    usage: Annotated[list[dict], operator.add]  # one row per LLM call: model, input, output tokens, usd (budget + spend)
    report_md: str  # run report
    # current unit
    unit: Unit | None
    flags: list[str]  # numeric flags
    hints: dict  # analyzer's setting changes (overrides for sp_config.CFG)
    notes: str  # analyzer's explanation, shown on the review page
    qc: dict  # r2, mae, n_peaks, gold_distance
    pack: list[dict] | None  # context pack every judge sees
    council: Annotated[list[dict], votes]  # per judge: model, vote, reasons, suggested_change
    attempts: int  # revise cycles so far
    verdict: Literal["accept", "revise", "unclear", "human"] | None
    reason: str  # why the unit ended where it did (queue card text)
