"""Review queue shared by the graph (writes items) and the review page (reads them, records decisions)."""
import json

from rtt.configuration import DIRS, LABEL_CONVENTION
from rtt.tools.gold import GOLD_H5
from rtt.tools.h5io import write_label

QUEUE = DIRS["review"] / "queue.jsonl"
DECISIONS = DIRS["review"] / "decisions.jsonl"
HUMAN_AS_VOTE = {"accept": "accept", "edit": "revise", "reject": "reject"}


def _read(path) -> list[dict]:
    return [json.loads(line) for line in path.read_text().splitlines() if line] if path.exists() else []


def _append(path, row: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as fh: fh.write(json.dumps(row) + "\n")


def add(item: dict):
    _append(QUEUE, item)


def waiting() -> tuple[list[dict], int]:
    """Latest queue item per undecided unit, and how many were skipped for using the old EXP=d label convention."""
    done = {d["unit_id"] for d in _read(DECISIONS)}
    latest = [i for uid, i in {i["unit"]["unit_id"]: i for i in _read(QUEUE)}.items() if uid not in done]
    current = [i for i in latest if i.get("label_convention") == LABEL_CONVENTION]
    return current, len(latest) - len(current)


def decide(item: dict, decision: str, label: list[float]):
    """accept / edit -> gold + training (marked human); reject -> logged discard.
    Generated spectra go to training only (with their truth), never to gold: gold is human fits of real data."""
    u = item["unit"]
    if decision != "reject":
        prov = dict(route="human", decision=decision, attempts=item["attempts"], votes=item["council"], human_seen=True,
                    edits=label if decision == "edit" else None, ground_truth=u.get("truth"))
        if not u.get("truth"): write_label(GOLD_H5, u, label, prov)
        write_label(DIRS["accepted"] / f"{item['run_id']}.h5", u, label, prov)
    _append(DECISIONS, dict(unit_id=u["unit_id"], run_id=item["run_id"], decision=decision, votes=item["council"]))


def agreement() -> float | None:
    """Share of judge votes that matched the human's decision (edit counts as revise)."""
    pairs = [(v["vote"], HUMAN_AS_VOTE[d["decision"]]) for d in _read(DECISIONS) for v in d["votes"] if v["vote"] != "abstain"]
    return sum(a == b for a, b in pairs) / len(pairs) if pairs else None
