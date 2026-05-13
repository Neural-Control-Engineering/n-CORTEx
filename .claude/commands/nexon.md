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

## `nexInit_registry` — what the registry contains

Built by `nexInit_registry(nexon)`, stored at `nexon.console.BASE.registry`:

| Field | Content |
|-------|---------|
| `registry.categories.(key)` | Unique values for each sessionLabel category and signal type |
| `registry.LUT.(key)` | Color lookup table (`label`, `color` columns) for each sessionLabel category |

LUT keys match CLR column names used in visualization (e.g. `registry.LUT.sessionLabel_subj`). `nexOp_resolveGroupColors` reads these as its first priority when assigning per-point colors.
