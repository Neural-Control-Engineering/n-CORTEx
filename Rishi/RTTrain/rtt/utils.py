"""Anthropic client and small helpers shared by the agents."""
import base64
import math
from functools import cache

import anthropic
from dotenv import load_dotenv
from pydantic import BaseModel

from rtt.configuration import ENV_FILE

load_dotenv(ENV_FILE)  # ANTHROPIC_API_KEY lives in Rishi/.env

PRICES = {  # $ per 1M tokens (input, output); Haiku price is for prompts up to 100K tokens
    "claude-opus-5-5": (4.00, 20.00),
    "claude-sonnet-5-5": (2.00, 10.00),
    "claude-haiku-5-5": (0.10, 0.50),
}


@cache
def client() -> anthropic.Anthropic:
    return anthropic.Anthropic()


def usage_row(model: str, usage) -> dict:
    """Tokens and dollars for one call (output includes thinking tokens)."""
    i, o = usage.input_tokens, usage.output_tokens
    pi, po = PRICES.get(model, (0.0, 0.0))
    return dict(model=model, input=i, output=o, usd=(i * pi + o * po) / 1e6)


def spend(rows: list[dict]) -> dict:
    """Totals per model and overall for a list of usage rows."""
    per = {}
    for r in rows:
        m = per.setdefault(r["model"], dict(calls=0, input=0, output=0, usd=0.0))
        m["calls"] += 1; m["input"] += r["input"]; m["output"] += r["output"]; m["usd"] += r["usd"]
    return dict(per_model=per, calls=len(rows), input=sum(r["input"] for r in rows),
                output=sum(r["output"] for r in rows), usd=sum(r["usd"] for r in rows))


def image_block(png: bytes) -> dict:
    """PNG bytes -> image content block."""
    return {"type": "image", "source": {"type": "base64", "media_type": "image/png",
                                        "data": base64.standard_b64encode(png).decode()}}


def ask(model: str, system: str, content: list[dict], schema: type[BaseModel]) -> tuple[BaseModel | None, dict]:
    """One structured call; returns (validated `schema` instance or None if the model declined, usage row)."""
    r = client().messages.parse(model=model, max_tokens=16000, system=system,
                                messages=[{"role": "user", "content": content}], output_format=schema)
    return (None if r.stop_reason == "refusal" else r.parsed_output), usage_row(model, r.usage)


def ask_text(model: str, system: str, text: str) -> tuple[str, dict]:
    """One plain-text call; returns (text, usage row)."""
    r = client().messages.create(model=model, max_tokens=4000, system=system,
                                 messages=[{"role": "user", "content": text}])
    return "".join(b.text for b in r.content if b.type == "text"), usage_row(model, r.usage)


def clean(x):
    """NaN -> None, so values serialise as valid JSON for the LLMs."""
    if isinstance(x, float) and math.isnan(x): return None
    if isinstance(x, dict): return {k: clean(v) for k, v in x.items()}
    if isinstance(x, (list, tuple)): return [clean(v) for v in x]
    return x
