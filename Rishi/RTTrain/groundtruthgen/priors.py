"""YAML loading and Normal sampling. Every sampled parameter goes through ParamPrior; keys starting with
"log" are Normal on the log of the quantity (draw = exp(Normal)), which keeps it strictly positive."""
import math
import re
from dataclasses import dataclass

import numpy as np
import yaml

SAMPLED_SECTIONS = ("aperiodic", "peaks")


class _Loader(yaml.SafeLoader):
    """SafeLoader without implicit booleans: YAML 1.1 would read the key OFF as False."""


_Loader.yaml_implicit_resolvers = {k: [r for r in v if r[0] != "tag:yaml.org,2002:bool"]
                                   for k, v in yaml.SafeLoader.yaml_implicit_resolvers.items()}


@dataclass
class ParamPrior:
    name: str  # matches a YAML key exactly, e.g. "logD2"
    mu: float
    sd: float
    log_space: bool = False  # True -> draw is exp(Normal(mu, sd))
    min: float | None = None  # only used by bounded draws, e.g. peak `count`
    max: float | None = None

    def sample(self, rng: np.random.Generator) -> float:
        x = rng.normal(self.mu, self.sd)
        x = np.exp(x) if self.log_space else x
        if self.min is not None or self.max is not None:
            x = np.clip(x, self.min, self.max)
        return float(x)


def _number(x) -> float:
    """YAML value -> float; accepts plain numbers and 'log(<number>)' as written in the configs."""
    if isinstance(x, str):
        m = re.fullmatch(r"\s*log\(\s*([-+0-9.eE]+)\s*\)\s*", x)
        if not m: raise ValueError(f"cannot read prior value {x!r}")
        return math.log(float(m.group(1)))
    return float(x)


def load_config(config_path: str) -> dict:
    with open(config_path) as fh:
        return yaml.load(fh, Loader=_Loader)


def load_prior_table(config_path: str) -> dict[str, ParamPrior]:
    """One ParamPrior per YAML key under aperiodic/peaks. Retuning (mu, sd) or adding a parameter is a YAML edit,
    never a code change."""
    cfg = load_config(config_path)
    table = {}
    for section in SAMPLED_SECTIONS:
        for name, spec in (cfg.get(section) or {}).items():
            table[name] = ParamPrior(name=name, mu=_number(spec["mu"]), sd=_number(spec["sd"]), log_space=name.startswith("log"),
                                     min=spec.get("min"), max=spec.get("max"))
    return table
