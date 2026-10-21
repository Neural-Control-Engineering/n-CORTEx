"""LLM council (reviewers): Gate 1 numeric check, then three judges vote in parallel, then a 2-of-3 tally."""
import json
import random
from collections import Counter
from typing import Literal

import numpy as np
from pydantic import BaseModel, Field

import sp_core as sp
from rtt import prompts
from rtt.configuration import CONFIG, DIRS
from rtt.nodes.orchestrator import over_budget, revise_or_human
from rtt.state import State
from rtt.tools.fitting import score
from rtt.tools.flags import compute_flags
from rtt.tools.gold import nearest
from rtt.tools.plots import fit_png
from rtt.utils import ask, clean, image_block


class Vote(BaseModel):
    vote: Literal["accept", "revise", "reject"]
    reasons: list[str] = Field(description="Short reasons, tied to the rubric items")
    suggested_change: str = Field(description="For revise: the one settings change that would fix the fit; otherwise empty")


def context_pack(u, qc, flags, near) -> list[dict]:
    """What every judge sees: fit + residual, the 3 nearest gold fits, the 37 params, qc and flags."""
    f, y = np.asarray(u["f"]), np.asarray(u["spectrum"])
    pack = [{"type": "text", "text": "Candidate fit:"}, image_block(fit_png(f, y, u["label"], u["unit_id"]))]
    for g in near:
        pack += [{"type": "text", "text": f"Gold example {g['unit_id']} (shape distance {g['distance']:.1f} dB):"},
                 image_block(fit_png(g["f"], g["spectrum"], g["label"]))]
    if not near: pack.append({"type": "text", "text": "No gold examples yet: judge on rubric items 1-3."})
    facts = {"N": u["N"], "params": dict(zip(sp.PARAM_LABELS, u["label"])), "qc": qc, "flags": flags}
    return pack + [{"type": "text", "text": json.dumps(clean(facts), indent=1)}]


def gate(state: State) -> dict:
    """Gate 1 (free): decides clean and failed fits in code; only unclear ones go to the judges."""
    u, attempts = state["unit"], state.get("attempts", 0)
    f, y = np.asarray(u["f"]), np.asarray(u["spectrum"])
    qc = state.get("qc") or score(f, y, u["label"])
    near = nearest(f, y)
    qc = qc | {"gold_distance": near[0]["distance"] if near else None}
    flags = compute_flags(f, y, u["label"], qc, qc["gold_distance"])
    out = {"qc": qc, "flags": flags, "council": None, "pack": None}
    serious = sorted(set(flags) - {"line_noise"})
    if not np.isfinite(qc["r2"]):  # without agents a refit would only repeat the same settings
        return out | (revise_or_human(attempts, "fit failed") if CONFIG.agents_enabled else dict(verdict="human", reason="fit failed"))
    audit = random.random() < CONFIG.audit_rate
    if not serious and not audit: return out | dict(verdict="accept", reason="gate pass")
    if not CONFIG.agents_enabled: return out | dict(verdict="human", reason=", ".join(serious) or "audit")  # no council: a human decides
    if over_budget(state, len(CONFIG.judges)): return out | dict(verdict="human", reason="over budget")
    return out | dict(verdict="unclear", reason=", ".join(serious) or "audit", pack=context_pack(u, qc, flags, near))


def judge(payload: dict) -> dict:
    """One judge; runs three times in parallel via Send({'model', 'pack'})."""
    v, usage = ask(payload["model"], prompts.JUDGE, payload["pack"], Vote)
    vote = v.model_dump() if v else {"vote": "abstain", "reasons": ["model declined"], "suggested_change": ""}
    return {"council": [{"model": payload["model"], **vote}], "usage": [usage]}


def tally(state: State) -> dict:
    """Majority (2 of 3) decides; splits and majority rejects go to a human."""
    votes = state["council"]
    log = DIRS["runs"] / state["run_id"] / "council_log.jsonl"
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("a") as fh: fh.write(json.dumps({"unit_id": state["unit"]["unit_id"], "attempt": state.get("attempts", 0), "votes": votes}) + "\n")

    counts = Counter(v["vote"] for v in votes if v["vote"] != "abstain")
    top, n = counts.most_common(1)[0] if counts else ("none", 0)
    if n < 2: return dict(verdict="human", reason="split " + "-".join(str(c) for c in sorted(counts.values(), reverse=True)))
    if top == "accept": return dict(verdict="accept", reason=f"council accept {n}-{len(votes) - n}")
    if top == "revise": return revise_or_human(state.get("attempts", 0), "council: revise")
    return dict(verdict="human", reason=f"reject {n}-{len(votes) - n}")
