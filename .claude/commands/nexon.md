# nexon — Nexon Class Reference

The `Nexon` handle class is the root object of every Nexus session. Everything hangs off `nexon.console.BASE.*`.

---

## Key Properties

| Path | Content |
|------|---------|
| `nexon.console.BASE.DTS` | Active Data Table/Struct — primary data carrier |
| `nexon.console.BASE.params` | Session parameters (paths, extractCfg, experiment name, bands, …) |
| `nexon.console.BASE.registry` | Category / LUT registry built by `nexInit_registry` |
| `nexon.console.BASE.router` | Session/subject routing config |
| `nexon.settings` | Global settings (Colors, headless flag, …) |
| `nexon.UserData` | Arbitrary session-level storage |

---

## Methods

### `appendToDTS(nexon, DTS)`
Merges a new DTS timetable into `console.BASE.DTS`, re-sorts by `sessionLabel`/`trialNumber`, and updates the router dropdowns. If `DTS` is the first batch, runs `nex_panelStartup` to initialize all UI panels.

---

## Startup Cache — `nexCachePath` / `saveRegistry` / `loadRegistry`

### Cache path convention

```matlab
p = nexon.nexCachePath(cacheKey)
% → Nexus/Startup/Cache/<cacheKey>_<experiment>.mat
```

The experiment tag is read from `nexon.console.BASE.params.experiment`, then `params.extractCfg.experiment`, falling back to `"default"`. The tag is sanitized with `matlab.lang.makeValidName` so the filename is always valid.

This method is the single place that knows the cache root and naming convention. All future cached artifacts should call it rather than hardcoding a path.

### `saveRegistry(nexon)`

Saves `nexon.console.BASE.registry` to the experiment-scoped cache file:
```
Nexus/Startup/Cache/registry_<experiment>.mat
```

Call after `nexInit_registry` completes to avoid rebuilding the registry (which reads every sessionLabel column from HDF5) on the next session.

### `loadRegistry(nexon)`

Loads the cached registry back into `nexon.console.BASE.registry`. Emits a warning and returns without modifying state if no cache exists yet.

### Adding a new cached artifact

1. Save: `save(nexon.nexCachePath('myKey'), 'myVar')`
2. Load: `S = load(nexon.nexCachePath('myKey'), 'myVar'); nexon.console.BASE.myThing = S.myVar;`

No new methods needed — `nexCachePath` is the only coordination point.

---

## Router — `initializeRouterCfg` / `routerEntryChanged`

The router is a cascading hierarchy of session-label dimensions. Each level filters the labels available to the next. Dimensions are:

```
subj → date → phase → [site] → trial
```

`site` is optional — it is included only when `parseSessionLabelUnique(DTS.sessionLabel, "site")` returns a non-empty result.

### `initializeRouterCfg(DTS)` → `routerCfgParams`

Builds the initial dropdown items for each level by walking the cascade from the first available value at each level. Returns a struct with fields `subj`, `date`, `phase`, `trial`, and optionally `site`.

### `routerEntryChanged(nexon, entryPanel, entryfield)`

Called by every router dropdown's `ValueChangedFcn`. Cascades downward from the changed field:

1. Syncs the changed value into both `entryPanel.entryParams` and `nexon.console.BASE.router.entryParams`.
2. Recomputes available items for every level below the change.
3. At each level: if the current selection is no longer in the available items, resets it to the first available value.
4. Sets both `.Items` and `.Value` together on each dropdown before using the value to filter the next level — this prevents the "Items must be 1-by-N" crash that occurs when an empty array is assigned.
5. Writes the working copy `ep` back to `nexon.console.BASE.router.entryParams` at the end.

**Why both `.Items` and `.Value` must be set together:**
Setting `.Items` before `.Value` ensures MATLAB never sees a `.Value` that isn't a member of `.Items`. Setting them in the wrong order, or setting `.Items` to an empty array, causes a hard error.

**The `site` level is gated:**
```matlab
hasSitePanel = isfield(nexon.console.BASE.router.Panel, 'site') && isfield(ep, 'site');
```
If the router UI has no site panel or the DTS has no site dimension, the block is skipped entirely — no errors, no stale state.

### Cascade invariant

At every level, the filtering chain is:
```
subjLabels
  → contains(ep.date)     → subjXdateLabels
  → contains(ep.phase)    → subjXdateXphaseLabels
  → contains(ep.site)     → terminalLabels          ← only if site present
  → strcmp(terminalLabels(1)) → trialNums
```

Each label set falls back to its parent if filtering returns empty, so no downstream level ever operates on an empty set.

### Adding a new optional cascade level

1. Add the level between phase and trial in both `initializeRouterCfg` and `routerEntryChanged`.
2. Gate on presence in the panel and `ep`: `isfield(router.Panel, 'myLevel') && isfield(ep, 'myLevel')`.
3. Use `terminalLabels` (not `subjXdateXphaseLabels`) as the input so new levels compose correctly.

---

## SLRT Signals / Events Framework

### `signal_types` column

Every DTS row carries a `signal_types` cell entry — an `N×2` cell array:

| Column | Content |
|--------|---------|
| `col 1` | dataID string (e.g. `"stim_raw"`, `"lickPort_event"`) |
| `col 2` | type string — one of `"signal"`, `"event"`, `"tag"`, `"affix"` |

Type semantics:

| Type | Meaning |
|------|---------|
| `"event"` | Scalar sample index stored per trial — used as alignment anchor |
| `"signal"` | Behavioral timecourse stored per trial — rendered in the time-course figure |
| `"tag"` | Categorical label per trial — enumerated for the averaging/selection panel |
| `"affix"` | Like tag; secondary categorical label |

`signal_types` is always kept in the manifest table (not pushed to HDF5) so it is available without an HDF5 read.

**Max-N row convention**: old trials may have fewer `signal_types` entries if new signals were added mid-session. Both `nex_getEventTypes` and `nex_getSignalTypes` select the row with the most entries (`max(size(st,1))`) to get the most complete type registry.

---

### Helper functions

```matlab
IDs_events  = nex_getEventTypes(nexon)   % → string array of "event"-typed IDs
IDs_signals = nex_getSignalTypes(nexon)  % → string array of "signal"-typed IDs
```

Both read `nexon.console.BASE.DTS.signal_types`, find the max-N row, and filter by type.

`dtsIO_listSignals(DTS, ["tag","affix"])` does the same for tag/affix types — used by `nexSelect_averaging`.

---

### `nexSelect_eventAlignment(nexObj, IDs_signals)`

Builds the event-alignment `nexObj_selectionBus` for the SLRT time-course panel.

```matlab
[eventSelection, IDs_signals, IDs_events] = nexSelect_eventAlignment(nexObj, IDs_signals)
```

Steps:
1. Read `DTSCols` via `dtsIO_readDFIDs` (manifest + HDF5 leaf names).
2. Call `nex_getSignalTypes` → `IDs_signals_st`; merge with caller-supplied `IDs_signals` via `unique(...,'stable')`.
3. Call `nex_getEventTypes` → `IDs_events`; **filter against `DTSCols`** so only events with data written are included.
4. Signals are **not** filtered — missing signal data is handled gracefully by `nexSLRT_compileDataFrames`, and the selection must remain valid for aligning nexObjs whose signal data isn't written yet.
5. Build `"<eventID>_<signalID>"` tags for every event×signal pair → stored as `eventSelection.selKeys.events`.

**Tag format** `"<eventID>_<signalID>"` is shared with `nexOp_compileTF`. The event ID is always the prefix up to the first `_` that matches a known event ID (resolved by `startsWith` against known event IDs, robust to underscores in either ID).

---

### `nexSLRT_compileDataFrames(nexon, IDs_signals, eventTag, Fs, preBuffLen)`

Single-trial display — reads whichever trial the router is currently pointing to and aligns each signal to the selected event.

```matlab
DF = nexSLRT_compileDataFrames(nexon, IDs_signals, eventTag, Fs, preBuffLen)
```

Flow:
1. Parse `eventID` from `eventTag` using `startsWith(tag, eventID + "_")` match against known event IDs (robust to underscores).
2. `dtsIO_readDF(nexon, eventID, [])` — empty index → router selects current trial automatically.
3. For each signal in `IDs_signals`: `dtsIO_readDF(nexon, sigID, [])` → `nexOp_eventAlignDF(DF_sig, sample_event, Fs, preBuffLen, 1)`.
4. Signals absent from the DTS are silently skipped; `nexPlot_slrt_timeCourse` renders only populated fields.

Returns `DF.df.(fieldName)` and `DF.ax.t.(fieldName)` for each successfully aligned signal.

---

### `nexObj_slrtTimeCourse` constructor and update flow

```matlab
% Constructor (inside nexPanel_SLRT)
[nexObj.eventAlignmentSelection, IDs_signals, ~] = nexSelect_eventAlignment(nexObj, dfIDs);
nexObj.dfIDs     = IDs_signals;
allEventTags     = nexObj.eventAlignmentSelection.selKeys.events;
nexObj.pMap_time = poolMap_time(allEventTags);
defaultTag       = allEventTags(1);   % first tag as default
nexObj.DF        = nexSLRT_compileDataFrames(nexon, IDs_signals, defaultTag, Fs, preBuffLen);
nexObj           = nexPlot_slrt_timeCourse(nexon, nexObj);
```

**`updateScope`** — reads the currently selected listbox index, picks the matching tag, recompiles and re-renders:
```matlab
selIdx      = nexObj.eventAlignmentSelection.selections.events;
selectedTag = allEventTags(selIdx);
nexObj.DF   = nexSLRT_compileDataFrames(nexon, IDs_signals, selectedTag, Fs, preBuffLen);
updateSlrtTimeCourse(nexObj, colorMap);
```

**`visualize`** — thin wrapper so `listCfgEntryChanged` auto-triggers a replot when the user changes the event/signal selection in the panel:
```matlab
function visualize(nexObj)
    nexObj.updateScope([], []);
end
```

---

### `nexSelect_averaging` and `signal_types`

The `if isfield(DTS, "signal_types")` guard in `nexSelect_averaging` **must use `ismember`**, not `isfield`, because DTS is a MATLAB table:

```matlab
% Correct check for a table column
if ismember("signal_types", string(nexon.console.BASE.DTS.Properties.VariableNames))
```

`isfield` always returns false for table objects; the signal_types block silently never runs.

---

## Category Taxonomy — sessionLabel / h5 / ax prefixes

Every category key carries a two-part prefix that encodes where its values live and how it participates in filtering and batching:

| Prefix | Example | Value source | Role |
|--------|---------|--------------|------|
| `sessionLabel--` | `sessionLabel--subj` | `DTS.sessionLabel` string (parsed by `parseSessionLabel`) | Trial grouping; cheap to read — no HDF5 |
| `h5--` | `h5--responseThreshold` | HDF5 scalar dfID (one read per trial via `dtsIO_readTFH5`) | Within-batch grouping; requires HDF5 read |
| `ax--` | `ax--f`, `ax--t` | `DF_postOp.ax.(field)` axis array | **Ptr filter** — becomes a hyperslab constraint on TF reads |

`nexOp_listCategories` assembles all three in order: `sessionLabel--*` first, then signal-type vars, then `h5--*` (deduplicated against the others). The `ax--` entries are appended by `nexSelect_categories` from `nexOp_listDfDims`.

In `collector.View.CTG` and STAT column names the `--` separator is replaced with `_` (via `strrep("--","_")`), so `"sessionLabel--subj"` becomes `"sessionLabel_subj"`. The raw `selectionBus.categories` still uses `--`.

---

## TF Load Chain — compileSTAT → compileTF → readTF → readHDF5

```
nexOp_compileSTAT(nexObj, dfID, S_categories, S_items, idxSel)
  │  builds ptr_filter from ax-- selections  →  nexOp_buildPtrFromAxSel
  │  applies global + CTG item filter        →  idxSel (logical)
  ↓
nexOp_compileTF(nexObj, idxSel, dfID, ptr)
  │  resolves nexon, applies averagingSelection fallback
  │  calls event alignment (SLRT) if available
  ↓
dtsIO_readTF(nexon, dfID, IDX, h5Modifier, ptr)
  ├─ DTS column path  →  dtsIO_readDF(nexon, dfID, idx, ptr)
  └─ HDF5 path        →  dtsIO_readTFH5(DTS, dfID, IDX, modifier, ptr)
                              └─ dtsIO_composeDF(DTS, dfID, row, ptr)
                                   └─ dtsIO_readHDF5(DTS, dfID, row, ptr)
                                        └─ h5read(file, dset, start, count)  ← hyperslab
```

Every function in the chain accepts `ptr` as its last optional argument. Callers that don't need filtering pass `[]` — existing behavior is unchanged.

---

## ax-- selections → ptr filter → hyperslab reads

`nexOp_buildPtrFromAxSel(S_categories, S_items, nexObj)` — standalone function, called by both `nexOp_compileSTAT` and `reportAverage_batched`.

**For each ax-- slot in S_categories:**
1. Extract bare axis name: `extractAfter("ax--f", "ax--")` → `"f"`
2. Get selected item values from `S_items.(Ci)` (may be a scalar or array)
3. Look up each value in `nexObj.DF_postOp.ax.(axName)` — nearest index for numeric axes, exact match for string axes
4. Collapse to `[min(indices), max(indices)]` — covers the full span of the selection
5. Set `ptr.(axName).range = [i1, i2]`

Returns `[]` when no ax-- slots are active (no-op path). The resulting `ptr` is a plain struct (not a `nexObj_ptr` handle) — safe for `parfor` broadcast.

**On the read side**, `dtsIO_readHDF5` reads the `dim_order` attribute written by `dtsIO_writeDF_toHDF5` (e.g. `"f,t"`) to map axis names to HDF5 dataset dimensions, then calls `h5read(file, dset, start, count)` for a partial load. I/O savings require a **chunked** dataset — use `nexon.rechunkDTS` to rechunk existing data.

---

## HDF5 Chunking and rechunkDTS

`nexon.rechunkDTS(newH5File, chunkTargetBytes, targetDFID, batchSize, tmpDir)` — rewrites the DTS HDF5 with axis-aware chunking and updates `h5_path` in the manifest.

| Arg | Default | Notes |
|-----|---------|-------|
| `newH5File` | required | Relative paths resolved against `DTS.h5_path(1)` directory |
| `chunkTargetBytes` | `128*1024` (128 KB) | Target chunk size; 64 KB–1 MB is the useful range |
| `targetDFID` | `''` (all) | Rechunk only this dfID; others copied verbatim (still a complete file) |
| `batchSize` | `50` | Trials per parfor batch; for large dfIDs (≥1 GB/trial) use `1` |
| `tmpDir` | `''` | Write to fast scratch first, then move — eliminates read/write contention on the source drive |

**Chunking is ptr-agnostic**: the rechunk worker uses `inferPtr` (shape-based axis→dim inference) to compute chunk sizes; no ptr ranges are applied. The ptr only affects the read side.

**Compression**: add `'Deflate', 4` to `h5create` calls in `h5writeSafeChunk` for 3–6× compression on fCWT spectrograms — biggest single win for USB HDD workflows.

---

## reportAverage_batched — disk-friendly batched averaging

`nexObj.reportAverage_batched(resultID, nBins)` — available on all nexObject subclasses. Bypasses `compileSTAT` entirely; loads one session-label batch at a time.

**Batch boundary** = `sessionLabel--*` categories in the CTG selection (C1, C2, ...). Batch membership is determined from `DTS.sessionLabel` alone using `parseSessionLabel` — zero HDF5 reads needed to form batches.

**`h5--` categories** are within-batch grouping variables (not yet implemented in prototype — deferred). Each batch currently produces one averaged result row.

**ax-- categories** become the `ptr_filter` passed to `nexOp_compileTF`, triggering hyperslab reads within each batch.

**Algorithm:**
```
1. global filter (averagingSelection) → rowIdx
2. apply sessionLabel-- item filters from CTG items bus → further filter rowIdx
3. build ptr_filter from ax-- CTG selections via nexOp_buildPtrFromAxSel
4. read sessionLabel columns from DTS (parseSessionLabel cellfun) → batch groups
5. for each (subj, phase, ...) batch:
     a. nexOp_compileTF(nexon, batchMask, dfID, ptr_filter)  ← hyperslab read
     b. nexOp_poolAxes(pMap, TF, DF_postOp.ptr)              ← axis pooling
     c. nexOp_averageTF(TF, ptr_avg, 2)                      ← average trials
6. assemble RESULT table with sessionLabel grouping columns
7. update SRC bus, call refreshVW
```

**Prototype scope**: batches at the C1/C2 sessionLabel levels (subj + phase). `h5--` within-batch subgrouping and memory-adaptive batch size selection are deferred.

---

## initCollectorView — CTG-driven, no compileSTAT

`nexObject.initCollectorView` now reads grouping keys from `nexObj.Parent.selectionBus.categories` (the CTG parent's selection bus) instead of from `nexObj.STAT` columns. This means nexObject subclasses no longer call `compileSTAT` at construction — it is fully lazy.

**Key detail**: `ax--` entries are **excluded** from `grpKeys` in `collector.View.CTG`. They are ptr constraints, not grouping columns, and never appear as STAT table columns. The filter is `~startsWith(catVals, "ax--")`.

**Fallback**: if no CTG parent is available, falls back to reading group keys from `nexObj.STAT` (legacy path for standalone objects).

`compileSTAT` is still called inside `reportAverage` overrides in subclasses — that on-demand call remains correct.

---

## `nexInit_registry` — what the registry contains

Built by `nexInit_registry(nexon)`, stored at `nexon.console.BASE.registry`:

| Field | Content |
|-------|---------|
| `registry.categories.(key)` | Unique values for each sessionLabel category and signal type |
| `registry.LUT.(key)` | Color lookup table (`label`, `color` columns) for each sessionLabel category |

LUT keys match CLR column names used in visualization (e.g. `registry.LUT.sessionLabel_subj`). `nexOp_resolveGroupColors` reads these as its first priority when assigning per-point colors.
