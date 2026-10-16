# RTTrain

Agentic labeling pipeline for Neuropixels spectral parameterization (see the RTT blueprint). Upload one nexDTS
`.h5` recording. The pipeline samples spectra, fits them with the lab's 37-parameter kernel, builds 5 synthetic
spectra per real one, sends every unit through the LLM council, and queues anything uncertain (plus every
synthetic spectrum) for human review. Accepted labels land in `training/accepted/`; human-approved ones also
land in `gold/`, which the council uses as its reference set.

## Run

```bash
uv venv --python 3.12 ~/.venvs/rttrain          # keep the venv off the iCloud-synced Desktop
uv pip install --python ~/.venvs/rttrain/bin/python -r requirements.txt
cd Rishi/RTTrain && ~/.venvs/rttrain/bin/streamlit run app.py
```

Needs Python 3.10+. `ANTHROPIC_API_KEY` is read from `Rishi/.env`. The run page shows calls, tokens and dollars
live; totals per model also go into `runs/<run_id>/report.md`.

## Layout

| Path | What |
|---|---|
| `app.py`, `ui/` | Streamlit: Upload & Run, Review |
| `rtt/graph.py` | the LangGraph StateGraph |
| `rtt/state.py` | shared state (one work unit = one spectrum) |
| `rtt/configuration.py` | models, thresholds, budget, folders |
| `rtt/prompts.py` | analyzer, judge, report prompts |
| `rtt/nodes/` | one module per agent: orchestrator, collector, analyzer, labeler, synthesizer, council, writer |
| `rtt/tools/` | deterministic tools: h5 I/O, fitting, flags, gold retriever, plots, synthetic data, review queue |
| `sp_*.py` | the fitting code, ported to `kernel_specparam_segmented_multiexp` |

## Flow

`collector → planner → next_unit → analyzer → labeler → synthesizer → gate → judge ×3 → tally`
then `write_training`, `queue_review`, or back to `analyzer` (revise, max 3), and finally `next_unit → … → report`.

Labels use the `spcpmIO_paramNames` layout: `OFF, EXP1-3, FC1-3, CF/PW/BW ×10` (NaN-padded). OFF and PW are
log10 power (×10 = dB).

## Output folders (created on first run)

`uploads/`, `normalized/`, `training/accepted/<run_id>.h5`, `gold/gold_fits.h5`, `review/queue.jsonl` +
`decisions.jsonl`, `runs/<run_id>/report.md` + `council_log.jsonl`, `checkpoints.sqlite`.
