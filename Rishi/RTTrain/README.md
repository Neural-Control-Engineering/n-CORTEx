# RTTrain

Agentic labeling pipeline for Neuropixels spectral parameterization (see the RTT blueprint). Upload one nexDTS
`.h5` recording. The pipeline samples spectra, fits them with the lab's 37-parameter kernel, sends every unit
through the LLM council, and queues anything uncertain for human review. Accepted labels land in
`training/accepted/`; human-approved ones also land in `gold/`, which the council uses as its reference set.

Synthetic data comes from `groundtruthgen/` (spec: `README_marc.md`): spectra drawn from known parameters
(per-N YAML priors in `groundtruthgen/configs/`) with chi-squared noise, written to parquet. Generate from the
Upload & Run page, or `python -m groundtruthgen generate --N 2 --M 5000 --config groundtruthgen/configs/priors_N2.yaml --seed 42 --out run_N2.parquet`.

Label convention (both the pipeline and the generator): `EXP_k` is the local slope of band k
(`= d_1 + … + d_k`, where `d` is the kernel's per-knee increment); inactive knees are `FC = Inf`, `EXP = NaN`;
`N` is stored explicitly. Sanity checks: `python -m pytest groundtruthgen/tests`.

## Run

```bash
uv venv --python 3.12 ~/.venvs/rttrain          # keep the venv off the iCloud-synced Desktop
uv pip install --python ~/.venvs/rttrain/bin/python -r requirements.txt
cd Rishi/RTTrain && ~/.venvs/rttrain/bin/streamlit run app.py
```

**Agents are currently off** (`agents_enabled = False` in `rtt/configuration.py`): runs fit and gate spectra in code
only and send anything unclear to Review, with no API calls. Set it to `True` to turn the analyzer, council and
report summary back on. Needs Python 3.10+. `ANTHROPIC_API_KEY` is read from `Rishi/.env`. The run page shows calls, tokens and dollars
live; totals per model also go into `runs/<run_id>/report.md`.

## Layout

| Path | What |
|---|---|
| `app.py`, `ui/` | Streamlit: Upload & Run, Review |
| `rtt/graph.py` | the LangGraph StateGraph |
| `rtt/state.py` | shared state (one work unit = one spectrum) |
| `rtt/configuration.py` | models, thresholds, budget, folders |
| `rtt/prompts.py` | analyzer, judge, report prompts |
| `rtt/nodes/` | one module per agent: orchestrator, collector, analyzer, labeler, council, writer |
| `rtt/tools/` | deterministic tools: h5 I/O, fitting, flags, gold retriever, plots, review queue |
| `groundtruthgen/` | ground-truth generator: kernel, paramspec (EXP ↔ d), priors, noise, compositor, schemas, cli, configs, tests |
| `sp_*.py` | the fitting code, on `kernel_specparam_segmented_multiexp` via `groundtruthgen.kernel` |

## Flow

`collector → planner → next_unit → analyzer → labeler → gate → judge ×3 → tally`
then `write_training`, `queue_review`, or back to `analyzer` (revise, max 3), and finally `next_unit → … → report`.

Labels use the `spcpmIO_paramNames` layout: `OFF, EXP1-3, FC1-3, CF/PW/BW ×10` (NaN-padded), plus `N`. OFF and
PW are log10 power (×10 = dB). The labeler currently always fits N = 3.

## Output folders (created on first run)

`uploads/`, `normalized/`, `training/accepted/<run_id>.h5`, `gold/gold_fits.h5`, `review/queue.jsonl` +
`decisions.jsonl`, `runs/<run_id>/report.md` + `council_log.jsonl`, `checkpoints.sqlite`.
