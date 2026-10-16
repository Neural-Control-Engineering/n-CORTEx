"""Run settings: models, thresholds, budget and folders. Change them here, not in the nodes."""
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # RTTrain/
ENV_FILE = ROOT.parent / ".env"  # Rishi/.env holds ANTHROPIC_API_KEY
CHECKPOINTS = ROOT / "checkpoints.sqlite"  # LangGraph checkpointer (resume after a crash)
DIRS = dict(
    uploads=ROOT / "uploads",  # .h5 files dropped into the app
    normalized=ROOT / "normalized",  # collector output
    accepted=ROOT / "training" / "accepted",  # labels for RTSpec training
    gold=ROOT / "gold",  # human-approved fits (council reference)
    review=ROOT / "review",  # queue.jsonl + decisions.jsonl for the review page
    runs=ROOT / "runs",  # report.md + council_log.jsonl per run
)


@dataclass(frozen=True)
class Configuration:
    orchestrator_model: str = "claude-haiku-5-5"  # light LLM: writes the run report
    analyzer_model: str = "claude-opus-5-5"  # reads plots, proposes fit settings
    judges: tuple[str, ...] = ("claude-opus-5-5", "claude-sonnet-5-5", "claude-haiku-5-5")  # council, majority 2 of 3
    n_real: int = 3  # real spectra sampled per run (the UI can change it)
    n_synthetic: int = 5  # synthetic spectra per real spectrum
    max_attempts: int = 3  # revise cycles before a unit goes to human review
    max_llm_calls: int = 150  # per-run budget; past it, unclear units go straight to human review
    audit_rate: float = 0.02  # share of gate-passing units the council checks anyway
    r2_min: float = 0.97  # low_fit flag below this R²
    mae_max: float = 2.5  # ...or above this MAE (dB)
    rolloff_db_per_decade: float = -10.0  # no_rolloff flag if the slope above 150 Hz is flatter than this
    novel_db: float = 6.0  # novel flag if the nearest gold curve is further than this (mean dB)
    seed: int = 0  # spectrum sampling


CONFIG = Configuration()
