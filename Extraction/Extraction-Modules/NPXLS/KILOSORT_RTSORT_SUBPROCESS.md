# Kilosort4 & RT-Sort — MATLAB → Subprocess Migration (nexus env)

_Last updated: 2026-06-28_

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
| 8 | `could not broadcast input array from shape (330000,) into shape (1800000,)` in `save_traces_si` | **Recording segment shorter than the detection window.** `recording_window_ms=(0, 60000)` sizes braindance's on-disk traces buffer at 1.8 M samples, but an ~11 s trigger segment only yields 330 k samples (`get_traces` clamps to real length). Fix: clamp the window to the segment duration in `runRTSort.py` (`min(60000, floor(dur_ms))`). |

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
  reads the whole imec folder; `_select_trigger` selects only the requested
  `_tN` segment **in memory**. The raw `.ap.bin` is never moved/linked/copied.
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

Not yet exercised:
- **Multi-trigger** recordings: `_select_trigger` assumes ascending-trigger →
  segment order for a single gate. Verify the correct segment is picked.
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
