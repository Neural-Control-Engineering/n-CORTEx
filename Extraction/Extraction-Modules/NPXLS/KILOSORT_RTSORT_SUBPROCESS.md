# Kilosort4 & RT-Sort — MATLAB → Subprocess Migration (nexus env)

_Last updated: 2026-07-03_

## Summary

Kilosort4 and RT-Sort extraction were run from MATLAB via **embedded Python**
(`py.importlib.import_module(...)`, `pyenv`) against the `nexus` conda env. On
Windows this fails because MATLAB and the nexus env's Python ship conflicting
copies of the same native DLLs (`libexpat.dll`, `hdf5.dll`, MKL/OpenMP, torch's
`c10.dll`). The fix migrates both sorters to run in a **clean Python
subprocess** (`system(...)`) on the nexus env, plus several env-version
alignments. No braindance code was modified.

Result: both Kilosort4 and RT-Sort run end-to-end under the single `nexus` env.

---

## Root causes (peeled back in order)

| # | Symptom | Real cause |
|---|---------|-----------|
| 1 | `OSError [WinError 1114]` loading `torch\lib\c10.dll` | torch loaded **in-process** in MATLAB; MKL/OpenMP collision |
| 2 | `numpy.dtype size changed (96 vs 88)` | env ABI rot: stale **scikit-learn 1.0.2**, **matplotlib 3.5.3**, **h5py 3.7.0** built against NumPy 1.x while env had NumPy 2.2.6 |
| 3 | `DLL load failed importing pyexpat: WinError 193` | nexus env's `pyexpat.pyd` links an **external `libexpat.dll`**; in MATLAB it binds to MATLAB's resident (incompatible) `libexpat.dll`. (kilosort env's older Python had expat bundled → never collided) |
| 4 | `FileNotFoundError ... no .meta/.bin` | `read_spikeglx` needs the **folder**, not the `.bin` file path |
| 5 | `KeyError: 'imDatPrb_type'` / `'probe_type'` | **Phase 3A** SpikeGLX metas lack the modern probe-type annotation |
| 6 | `TypeError: cannot pickle 'weakref.ReferenceType'` | braindance shares the recording across a `multiprocessing.Manager`; **spikeinterface 0.94.0** had no neo-reader pickling (`__getstate__`) vs **neo 0.13.3** |
| 7 | `save ... appears to be corrupt` | MATLAB `-v7.3` HDF5 save fails on **>260-char Windows paths** |
| 8 | `could not broadcast input array from shape (330000,) into shape (1800000,)` in `save_traces_si` | **Recording segment shorter than the detection window.** `recording_window_ms=(0, 60000)` sizes braindance's on-disk traces buffer at 1.8 M samples, but an ~11 s trigger segment only yields 330 k samples (`get_traces` clamps to real length). Fix: set the detection window to the segment duration in `runRTSort.py` (`floor(dur_ms)`; originally `min(60000, floor(dur_ms))` — the 60 s cap was dropped 2026-07-03 and is now an optional `window_s` CLI arg). |

### Why "in-process" was the umbrella problem
MATLAB loads its own `bin\win64\{libexpat,hdf5,...}.dll` into its process at
startup. Any DLL the embedded Python loads *by name* binds to MATLAB's resident
(incompatible) copy → load failure. `ExecutionMode="OutOfProcess"` does **not**
help on Windows: the OOP host (`MATLABPyHost.exe`) inherits MATLAB's PATH and
still loads MATLAB's `libexpat.dll`. The only robust fix is a fully separate
process (`system(...)`), which has none of MATLAB's DLLs loaded.

This is **Windows-specific**. The same code worked on Linux because (a) Linux
has no `libexpat.dll`, and (b) the Linux env had aligned spikeinterface/neo.

---

## Solution architecture

Both sorters now run as standalone CLI scripts invoked with `system(...)` on the
nexus env Python. They write results to disk; MATLAB reads them back natively.

```
extractRAW_NPXLS.m
  └─ system(nexus python  Extraction/runKilosort4.py  <data_dir> <fileName> <chanMap>)
        └─ kilosort4/ output folder on disk  → moved into <trig>_sorted/

extractRAW_rtSort.m
  └─ system(nexus python  NPXLS/runRTSort.py  <fileName> <inter_path>)
        ├─ read_spikeglx(folder) → select trigger segment (raw .bin untouched)
        ├─ detect_sequences → <inter_path>/rtsort/{rt_sort.pickle, scaled_traces.npy}
        └─ export_fields    → <inter_path>/rtsort/rtsort_fields.mat
  └─ extract_rtsort(<inter_path>/rtsort)   [native MATLAB load, no embedded Python]
```

### Output layout (per trigger)
```
<exp>_t0_sorted\
├── kilosort4\                  kilosort outputs
├── lfp.mat, nidq.mat, ...
└── rtsort\                     rtsort outputs ONLY (raw .bin never placed here)
    ├── rt_sort.pickle
    ├── scaled_traces.npy
    ├── rtsort_fields.mat       tensor fields exported for MATLAB
    ├── rtsort_results.mat      extract_rtsort output
    └── rtsort_*.png            quality / template plots
```

### Key design choices
- **Why subprocess, not OutOfProcess:** OOP still collides with MATLAB's
  `libexpat.dll` on Windows (see above).
- **Why a Python field-export step:** `rt_sort.pickle` holds **torch tensors**,
  so it can only be unpickled where torch imports cleanly (the subprocess).
  `runRTSort.py` dumps the needed fields to a plain `rtsort_fields.mat` so
  `extract_rtsort.m` never has to embed torch.
- **Single-trigger specificity without touching the binary:** `read_spikeglx`
  reads the whole imec folder as one multi-segment recording; `_select_trigger`
  selects only the requested segment **in memory** (raw `.ap.bin` never
  moved/linked/copied). spikeinterface addresses segments only by **position**,
  not by trigger name, so `_select_trigger` reconstructs neo's own ordering rule
  (`spikeglxrawio.scan_files`: numeric-sorted `(gate_num, trigger_num)` integer
  keys) and selects `recording.select_segments([keys.index((gate, trigger))])`.
  The `(g,t)` tuple never reaches `select_segments` — `keys.index(...)` converts
  it to the positional index; congruent-by-construction (same recipe + same
  files ⇒ same list), verified-by-count (see assertion below). Plain-language
  walkthrough lives in the coat-check comment above `_select_trigger`.
- **Phase 3A probe patch:** monkeypatch `probeinterface.read_spikeglx` to
  `setdefault` the missing `probe_type`/`imDatPrb_type` annotation to `0`
  (NP1.0-family ADC layout, correct for Phase 3A). No-op for modern probes.

---

## Files changed

### Code
| File | Change |
|------|--------|
| `Extraction/runKilosort4.py` | Added `if __name__ == "__main__":` CLI entry point |
| `Extraction/Extraction-Modules/extractRAW_NPXLS.m` | Embedded `py.*` kilosort call → `system(...)` subprocess (legacy call kept commented). `pyenv` line set to `OutOfProcess` (see note below) |
| `Extraction/Extraction-Modules/NPXLS/runRTSort.py` | **New.** RT-Sort CLI: probe patch, trigger-segment selection, `detect_sequences`, field export |
| `Extraction/Extraction-Modules/NPXLS/extractRAW_rtSort.m` | Embedded `py.*` call → `system(...)` subprocess (legacy call kept commented); calls `extract_rtsort(<inter_path>/rtsort)` |
| `Extraction/Extraction-Modules/NPXLS/extract_rtsort.m` | Pickle/torch-tensor load (embedded Python) → native `load('rtsort_fields.mat')`; final `save` uses `\\?\` long-path prefix |

### Legacy backups (for revert)
- `Extraction/runKilosort4_legacy.py` — original (function only, no CLI)
- `Extraction/Extraction-Modules/NPXLS/extract_rtsort_legacy.m` — original (embedded-Python version)
- In-file commented "legacy embedded call" blocks in `extractRAW_NPXLS.m` and `extractRAW_rtSort.m`

> Note: `pyenv(... OutOfProcess)` in `extractRAW_NPXLS.m` is no longer required
> by the subprocess kilosort/rtsort paths, but is left in place because other
> embedded-`py.*` code may still load Python in the session.

---

## Environment changes (nexus conda env)

`C:\Users\Primus\miniconda3\envs\nexus`

| Package | Before | After | Reason |
|---------|--------|-------|--------|
| scikit-learn | 1.0.2 | 1.7.2 | NumPy 2 ABI |
| matplotlib | 3.5.3 | 3.10.9 | NumPy 2 ABI |
| h5py | 3.7.0 | 3.16.0 | NumPy 2 ABI |
| **spikeinterface** | **0.94.0** | **0.101.2** | neo-reader **pickling** (Manager share) + `has_scaleable_traces()` API; compatible with neo 0.13.3 and braindance 0.1.7 |
| zarr | 2.18.3 | 2.17.2 | pulled by spikeinterface pin (minor) |

> braindance 0.1.7 does **not** pin spikeinterface, which is why it had drifted
> to a stale 0.94.0. 0.101.2 is the version braindance 0.1.7 targets (has
> pickling, `has_scaleable_traces()`, and still accepts deprecated
> `return_scaled`).

Reverting any upgrade: `pip install <pkg>==<old-version>`.

---

## Verification status

Verified (standalone, this machine):
- Full import chain clean: numpy/scipy/sklearn/matplotlib/pandas/numba/torch/spikeinterface/h5py + `from kilosort import run_kilosort`.
- spikeglx recording **pickles** under SI 0.101.2; `has_scaleable_traces()` and `get_traces(return_scaled=...)` work.
- Both CLI scripts byte-compile.

Verified end-to-end (real data, JOLT subj 10194, Phase 3A, single trigger):
- RT-Sort: 43 units detected → field export → native `.mat` load → waveforms,
  quality metrics, template plot. (Final `save` long-path fix applied after the
  first end-to-end run surfaced it.)

Verified end-to-end (real data, Kilosort4 subprocess, JOLT subj 10194, t12):
- Sorts to completion (74 units) → `kilosort4/` written → moved into
  `<exp>_tN_sorted/` by `extractRAW_NPXLS.m`. Surfaced one bug: `run_kilosort`
  in **kilosort 4.1.7** returns **9** values (added `kept_spikes`), but
  `runKilosort4.py` unpacked 8 → `ValueError` (exit 1) *after* sorting finished.
  Fixed by not unpacking the return tuple (subprocess ignores it anyway).

Multi-trigger segment selection (hardened 2026-07-02 — was previously flagged
as a latent "assumes ascending order" bug):
- **Not a bug for the standard layout.** `_select_trigger` reproduces neo's own
  segment-ordering rule rather than assuming one. Confirmed against neo 0.13.3
  source (`spikeglxrawio.scan_files`): each segment's index is the position of
  its integer `(gate_num, trigger_num)` key in the numerically sorted key set —
  triggers are parsed as `int`, so ordering is numeric (`t10` after `t2`, not
  lexicographic), and non-contiguous triggers (`t0, t2, t5`) map correctly
  because both sides index into the sorted set of *present* keys.
- **Two hardening changes vs. the original:**
  1. Match on `(gate, trigger)`, not trigger alone → correct when >1 gate is
     present (trigger `t1` can exist under both `g0` and `g1`).
  2. Assert `len(keys) == num_segments` before selecting → an `lf`-only trigger,
     a stray nested `.meta`, or extra gates in the walked tree now **raise**
     instead of silently mis-picking a segment.
- **Still pending:** an actual end-to-end run on a real multi-trigger recording.
  The ordering logic is verified against source and guarded, but not yet
  exercised on multi-segment data.

Not yet exercised:
- `.mat` round-trip orientation edge cases (ragged `seq_spike_trains` cell,
  `root_elecs` column) on recordings with different unit/channel counts.

---

## Output-size management (intermediate `.npy` cleanup)

`detect_sequences` writes three float16 `(num_chans x num_samples)` arrays into
`rtsort/`, each the **same footprint as the raw recording** (~1.4 GB/min at
384 ch / 30 kHz). Left in place they accumulate ~4 GB per trigger across daily
multi-trigger sessions. None are needed long-term:

| File | Read after detection by | Disposition |
|------|-------------------------|-------------|
| `model_traces.npy` | nothing (detection→clustering only) | deleted in `runRTSort.py` after `detect_sequences` |
| `model_outputs.npy` | nothing | deleted in `runRTSort.py` after `detect_sequences` |
| `scaled_traces.npy` | `extract_rtsort.m` (waveform/amp snippets) | deleted in `extractRAW_rtSort.m` after `extract_rtsort` returns |

Everything `extractEXT_SPK` consumes (spike trains → Gaussian-smoothed rates,
per-spike amps, root-channel templates, spatial profiles, quality, locs) lives
in the small `rtsort_results.mat`, so persistent footprint drops to a few MB per
trigger. `scaled_traces.npy` deletion is in the orchestrator (not inside
`extract_rtsort.m`) so a failed extraction keeps the traces for debugging and
`extract_rtsort` stays a pure read-only consumer. braindance's own
`delete_inter=True` is unusable here (it `rmtree`s the whole folder *and* skips
saving `rt_sort.pickle`).

> Tradeoff: re-running waveform extraction later (retuning window/quality)
> requires re-detecting or reading the original raw `.ap.bin` (a future
> "Tier 2b" deferred-extraction layer). The raw `.bin` is never touched/deleted.

---

## Notes / latent issues (pre-existing, not introduced here)

- `extractRAW_rtSort.m` reads `args.stringentThresh`/`looseThresh` but the
  detection call uses hardcoded `0.175`/`0.075` (preserved in `runRTSort.py`).
  To honor the args, pass them through as CLI arguments.
- `initRTSort.m` / `initRTSpec.m` still use embedded `py.*` (and `initRTSort.m`
  points at a separate `anaconda3\envs\RTSort` env). Not in the extraction
  pathway; would need the same subprocess treatment if used.
- The `"Unable to load Python object ... Saving ... not supported"` MATLAB
  warnings are cosmetic (a `py` handle landing in a struct later saved to .mat).

---

## Session 2026-07-03 — extraction robustness, plots, detection performance audit

Follow-up hardening plus a performance investigation. **No braindance code remains
modified** (a batching patch was applied and fully reverted — see below).

### Code changes
| File | Change |
|------|--------|
| `runRTSort.py` | (1) Detection window: dropped the hardcoded 60 s cap → full segment by default (`floor(dur_ms)`), now an optional 3rd CLI arg `window_s` (seconds), which `extractRAW_rtSort.m` sets to 300 s (5 min) to cap extraction time on long recordings — `min(window_s, segment)` leaves shorter triggers full-length. (2) `(gate,trigger)` trigger selection + `len(keys)==num_segments` assertion (see Verification section). (3) Startup device self-report; braindance forces `device="cuda"` with no CPU fallback, so it errors rather than silently running on CPU. |
| `runKilosort4.py` | Resolve device explicitly and pass it to `run_kilosort` (was relying on KS4's silent `None→cuda`); print it. |
| `extract_rtsort.m` | **Trace loader rewritten to a memory-map** (`openNPY_map` + `half2single`), replacing the whole-array `loadNPY`→`half2double`. Only per-spike N_WF windows are read → peak RAM ~hundreds of MB regardless of recording length (a full-array `single` load of a 1 h recording is ~166 GB, over the 128 GB box). Two new `try`-guarded validation plots: `rtsort_raster.png` (population rate + depth-ordered raster) and `rtsort_spatial.png` (probe map, depth-vs-rate/amp, rate/amp/depth distributions). |

### `memmapfile` long-path gotcha (extract_rtsort.m)
MATLAB `memmapfile` **cannot open >260-char paths and does not accept the `\\?\`
prefix** (unlike `save`; and unlike `fopen`, which tolerates the long path — so
`openNPY_map`'s header parse succeeds and only the lazy `mm.Data.x(...)` map fails
with "The system cannot find the path specified"). Fix: `openNPY_map` converts
`filepath` to its 8.3 short form (`for %~sI`) before mapping. Needs 8.3 generation
enabled on the volume (it is on C:); if ever disabled, stage the `.npy` to a short
path (e.g. `C:\npxlsTemp\`). Orientation verified numerically: `scaled_traces.npy`
is C-order `(chans, samples)`, mapped column-major as `[nSamp, nChan]` so
`x(sample, chan) == arr[chan, sample]`.

### Detection performance audit (RT-Sort ~1 h for a 10-min recording)
`extract_rtsort.m` is **not** the bottleneck (fast, GPU-idle MATLAB consumer). The
time is in Python `detect_sequences`, and it is **CPU/disk bound, not GPU bound**
(GPU sat ~13–38 %). Phases for a 10-min / 384-ch / 30 kHz recording (~12.77 GB
float16 per intermediate):
- `save_traces` → `scaled_traces.npy` (disk write).
- **inference loop** (`run_detection_model`): ~7 min. I/O-bound — per-window mmap
  reads + per-window writes into two 12.77 GB mmaps (`model_traces`,
  `model_outputs`), ~38 GB traffic; GPU under-fed.
- **`sort_offline` real-time replay (dominant):** replays `RTSort.running_sort`
  over the whole recording in `buffer_size=100`-sample chunks (~180 k Python
  iterations for 10 min), run **~twice** (once in `reassign_spikes_to_clusters` on
  `model_outputs`, once at the end on `scaled_traces` for precise peak times).
  Single-threaded, GPU idle → this is the hour.

**GPU-batching patch (attempted, reverted).** Batched the inference loop
(N windows/model call, re-traced conv for `B*num_chans` rows; `model_traces`
bit-exact, `model_outputs` within fp16 cuDNN-algorithm noise). ~No speedup: the
loop is I/O-bound and only ~12 % of runtime (Amdahl). Reverted fully.

**Conclusion.** Cost is structural to RT-Sort's "offline = replay the real-time
algorithm" design; `sort_offline` is inherently sequential (streaming state), so
batching cannot help and there is no accidental O(n²)/redundant-reload loop to fix.
Non-algorithmic levers only: a **shorter window** (`window_s`) or a **more
stringent detection threshold** (fewer sequences → cheaper per-chunk replay).
`buffer_size` (larger → fewer iterations) alters streaming granularity → not a
free/safe change.

### Recoverability (retention planning)
From `rt_sort.pickle` alone you can regenerate everything in `rtsort_fields.mat`
(spike trains, locs, root elecs, spatial `seqs_amps`, latencies, amp aggregates) —
but **not** the empirical mean-waveform templates or per-spike amplitudes, which
are cut from `scaled_traces.npy` (deleted post-extraction) → ultimately from the
raw `.bin`. The durable, env-independent artifact to keep before offloading raw
data is **`rtsort_results.mat`** (it bakes in the trace-derived products);
`rtsort_fields.mat` is a cheap hedge against pickle/env rot. The pickle is neither
sufficient (no waveforms) nor necessary (results.mat has more).

---

# extSPK → Nexus DTS pipeline — sync correction, seconds, axis schema

_Added 2026-06-28._

Downstream of the sorter subprocess work: the `extEXT_SPK` path that turns KS4 /
RTSort output into Nexus DataFrames. Three workstreams — cross-device sync
drift correction, a ms→seconds conversion, and a DF/axis schema rework.

## Cross-device sync drift correction in `extSPK`

`extSPK` previously binned spike times **directly** against SLRT trial-gate
times with no drift correction — KS4/RTSort spike times live in the imec
acquisition clock while trial windows are in the SLRT world clock, so the 1 Hz
sync pulse's slow drift desynchronized long recordings. Now mirrors `extLFP`:
loads `sync.mat`/`ap.mat`, runs `constructSync_slrt → filterSyncEdges →
extractSyncOffset → mapSyncTimeline` to build a per-imec-sample world-clock
timeline, and `applySyncOffset_spk` remaps each sorter's `spike_times_s` by
`round(t_s·fs)` sample-index lookup (the analog of extAP's `t_ap(spike_inds)`).
Single-sorter sessions continue (guard only exits when **both** are absent).
Optional `doViz` plots drift + per-edge before/after residual (the "after" trace
should sit on 0 across the whole session).

## Sync pipeline audit — shared `Validation/` code (affects AP/LFP/SPK)

| # | Fix | Why it mattered |
|---|-----|-----------------|
| 1 | extAP no longer overwrites its drift-corrected `spike_times` with a naive `linspace` | the correction was computed then **discarded** — AP shipped uncorrected times |
| 2 | `mapSyncTimeline` no longer re-adds `offset0` after the per-interval offsets | the loop already lands imec edges on SLRT edges; `+offset0` **double-counted** the base offset (masked by event-relative alignment → latent) |
| 3 | tail past the last edge holds the last offset (constant extrapolation) | those samples were uncorrected — worst exactly where drift is largest |
| 4 | binning boundaries reconstructed in the imec frame (`t_edges_ref − syncOffsets`) | ref-frame boundaries vs imec-frame samples mis-assigned a ~offset-wide band at each edge |
| 5 | first-edge match is **insert-anchored** (nearest distance-from-insert), nearest-edge fallback | the shared 1-per-trigger insert pulse disambiguates which reference pulse `imec(1)` is; old positive-min-of-two heuristic broke for >1-period start gaps + jitter-trailing edges and handled an asymmetric **clipped** first edge only by luck. Insert was previously computed into `insertOffsets` but never used for the match |
| 5b | post-match check warns when `min\|insertOffsets\| > IPD/2` | flags a slice that's off by a pulse |
| 6 | `[~,idx]=min` instead of `find(==min)` for the deviation pre-trim | ties returned multiple indices → bad slice |
| 7 | `filterSyncEdges` → greedy debounce (keep edges ≥ T/2 past last **accepted** edge) | old fixed-triplet rule **ate true edges** when bounces clustered (the anchor could itself be a bounce) |
| — | extAP: `amplitudes` filtered by the same `spike_inds>0` mask as times/clusters | otherwise per-spike amplitudes silently misaligned whenever non-positive spike_inds exist |

`offset0` machinery in `extractSyncOffset` left in place but **dormant** (no longer consumed).

## Time base: ms → seconds (whole SPK module)

`loadKS4_spk` / `loadRTSort_spk` / `formatSpk_toDTS` / `extSPK` /
`extractEXT_SPK` now track time in **seconds** (`spike_times_s`,
`bin_s = 0.005`, `sigma_s = 0.025`), matching AP/LFP and the rest of Nexus.
Firing rates stay Hz.

## Nexus DTS axis schema (DTSIO infra)

- **Axis-key whitelist extended** with `unit`, `wf`, `measure` (`factor` already
  present), synchronized across all five sites — `dtsIO_composeDF`,
  `dtsIO_writeDF_toHDF5`, `dtsIO_readHDF5`, both lists in `dtsIO_rechunkDTS`
  (+ `DTSIO/CLAUDE.md`). Unrecognized axis suffixes are silently dropped, so
  these **must stay in sync**.
- **String axes now round-trip** through `nexus_exportDTS`: a string column
  whose stub (last `_token`) is a whitelisted axis key folds into the DF group
  as a string axis. Writer (`h5writeStringSafe` branch) and reader (auto-detects
  `H5T_STRING` datasets → `DF.ax`) already supported strings; only the
  exporter's numeric-only classification blocked them. Lets
  `measure=["raster","rate","amp"]` / `factor=["root_elec","loc_x","loc_y"]`
  persist as readable labels. String columns with **non-axis** stubs (e.g.
  `*_quality`) stay simple columns.

## SPK output schema — 5 DFs/sorter, prefix naming

Routing rule (confirmed against `nexus_exportDTS` + `dtsIO_composeDF`):
**DFID = column minus its last `_token`; the last token is the routing stub**
(`df` or an axis key). So the sorter tag must be a **prefix** and the data
column needs an explicit **`_df`** — a bare multi-token name mis-splits
(`KS_spk_activity` → DFID `KS_spk`, stub `activity` → dropped). Per sorter
`S ∈ {KS, RTS}`:

```
S_spk_activity_df  (unit×t×measure)  + _unit, _t, _measure
S_spk_spatial_df   (unit×chan)       + _unit, _chans
S_spk_templates_df (wf×unit)         + _wf, _unit
S_spk_probe_df     (t×chan)          + _t, _chans
S_spk_units_df     (unit×factor)     + _unit, _factor   [root_elec, loc_x, loc_y]
S_spk_units_quality   (sibling simple string column, not in the units DF group)
```

`raster`/`rate`/`amp` collapsed into one `activity` DF along a `measure` axis
(stored `single` — `uint8` raster compactness traded for the unified stack).
**Event-aligned columns dropped** — alignment is on-demand via
`nexOp_eventAlignDF` (canonical `_t` axis + stored scalar event indices).

## Physical channel domain (full-probe scatter)

`spk_spatial_profiles` / `spk_probe` were coming out `N×374` (not 384) because
KS4 sorts only the channels it **keeps** — bad/unconnected channels are dropped,
so `templates.npy` / `channel_positions.npy` span the kept subset and
`N_CHANS = size(templates,3)` inherited it. The kept count varies per recording
(probe health) and can differ between KS and RTSort, so a positional `1:N_CHANS`
chans axis is **not comparable across sessions/sorters**.

Fix (`loadKS4_spk`): load `channel_map.npy` (physical index of each kept channel)
and **scatter** `unit_templates` / `spatial_profiles` / `channel_positions` onto
the full physical probe (`N_CHANS_FULL`, default 384) — kept channels land in
their physical slots, dropped channels stay `0` (data) / `NaN` (positions).
`unit_root_elecs` now holds the **physical** channel index; `n_chans` is the full
probe width. `loadRTSort_spk` detects on the whole probe, so it's already in the
physical space — a guard warns if its width ever disagrees with the probe.
`N_CHANS_PROBE = 384` is a per-loader constant (NP1.0 AP band); parameterize
per-probe when a non-NP1.0 probe is introduced.

## Design principle — physical domains, pool across sessions

> **Always materialize DF axes in their physical domain, not a data-dependent
> positional index.** Channels → full physical probe (fixed width, physical
> indices); time → world-clock seconds; units → stable ids. Any sorter /
> preprocessing step that drops or reorders elements must be scattered back to
> the canonical domain *at load time*. This keeps DFs comparable and **poolable
> across sessions and sorters** (the ideal case) instead of silently varying in
> width or meaning. The same reasoning drives the seconds conversion and the
> insert-anchored world-clock alignment above.

## Not yet verified / deferred

- **Round-trip on real data:** export a session, read back `KS_spk_activity` /
  `KS_spk_units`, confirm `DF.ax` holds the expected axes with `measure`/`factor`
  as strings.
- `nex_initAxisPointer_v2` infers axis→dim by **length-matching** → ambiguous if
  two axis lengths coincide (e.g. `measure`=3 and `N_UNITS`=3); the `dim_order`
  attribute written at export is the authoritative fallback.
- The `nexus_exportDTS` classification change touches **all** modalities' export
  — inert unless a string column's last token is a whitelisted axis key; sanity
  check on a known LFP/SSM session.
