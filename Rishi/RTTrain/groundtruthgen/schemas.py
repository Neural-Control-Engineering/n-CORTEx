"""Dataset row and dataset; one row per sample, written to parquet or to a nexDTS-style h5."""
from dataclasses import asdict, dataclass
from datetime import date

import h5py
import numpy as np
import pyarrow as pa
import pyarrow.parquet as pq
import yaml

from groundtruthgen.paramspec import param_names


@dataclass
class GroundTruthRow:
    sample_id: str
    N: int  # model order, explicit (never inferred from FC/EXP magnitudes)
    seed: int  # per-sample seed
    true_params: list[float]  # OFF, EXP1-3 (local slopes), FC1-3, then CF/PW/BW per peak; EXP=NaN / FC=Inf for k > N
    f: list[float]
    psd_clean: list[float]  # noise-free forward model, dB
    psd_noisy: list[float]  # psd_clean + chi-squared noise, dB
    noise_config: dict


@dataclass
class GroundTruthDataset:
    rows: list[GroundTruthRow]
    config: dict  # the YAML the rows were drawn from
    seed: int | None = None  # master seed

    def to_nexdts_h5(self, path) -> str:
        """Same layout as nexDTS_specparam_fitScope.h5: df [t x f x chan] in dB, float64, with t = 1 time point and one
        channel per sample; t, f, chans as column vectors under an 8-level date/.../specparam_fitScope path.
        A sibling group groundtruth/ holds what the fitter must not see. Returns the inner group path."""
        N, M = self.config["N"], len(self.rows)
        f = np.asarray(self.rows[0].f, float)
        group = f"date/{date.today().isoformat()}_subj/groundtruth_geno/synthetic_npxls/N{N}_phase/seed{self.seed}_g0/trial_0001/specparam_fitScope"
        n_pk = max((len(r.true_params) - 7) // 3 for r in self.rows)
        params = np.full((M, 7 + 3 * n_pk), np.nan)  # NaN-padded peak slots
        for i, r in enumerate(self.rows): params[i, :len(r.true_params)] = r.true_params
        with h5py.File(path, "w") as h:
            g = h.create_group(group)
            g["df"] = np.array([r.psd_noisy for r in self.rows], float).T[None]  # (1, F, M)
            g["t"] = np.zeros((1, 1))
            g["f"] = f[:, None]
            g["chans"] = np.arange(1, M + 1, dtype=float)[:, None]
            gt = h.create_group("groundtruth")
            gt["psd_clean"] = np.array([r.psd_clean for r in self.rows], float).T[None]  # same layout as df
            gt["true_params"] = params  # [chan x param]: OFF, EXP1-3 (local slopes), FC1-3, CF/PW/BW...; EXP=NaN, FC=Inf for k > N
            gt["N"] = np.array([r.N for r in self.rows], float)[:, None]
            gt["noiseAmp"] = np.array([r.noise_config["amp"] for r in self.rows], float)[:, None]  # sqrt(2/dof); named so it can't be confused with df (the PSD data)
            gt["seed"] = np.array([r.seed for r in self.rows], np.int64)[:, None]
            gt["sample_id"] = np.array([r.sample_id for r in self.rows], dtype="S")
            gt.attrs["param_names"] = param_names(n_pk)
            gt.attrs["noise"] = yaml.safe_dump(self.rows[0].noise_config)
            gt.attrs["config_yaml"] = yaml.safe_dump(self.config)
            gt.attrs["data_group"] = group
        return group

    def to_parquet(self, path) -> None:
        table = pa.Table.from_pylist([asdict(r) for r in self.rows])
        meta = {b"config_yaml": yaml.safe_dump(self.config).encode(),
                b"true_params_layout": b"OFF,EXP1,EXP2,EXP3,FC1,FC2,FC3,(CF,PW,BW)*n_peaks; EXP=local slope; EXP=NaN,FC=Inf for k>N"}
        pq.write_table(table.replace_schema_metadata({**(table.schema.metadata or {}), **meta}), path)
