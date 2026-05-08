# nexObj — CLAUDE.md

## Overview

`nexObj/` contains the nexObject base class and all nexObject subclasses. A nexObject is a handle object that owns a data source, a collector (selection bus set), and a figure. It is the primary unit of interactive visualization and analysis in Nexus.

---

## nexObject Base Class

`nexObject.m` defines shared properties and methods inherited by all subclasses:

| Property | Purpose |
|----------|---------|
| `nexon` | Root Nexon handle |
| `DF` | Raw source dataframe |
| `DF_postOp` | Post-operative DF (pooled/transformed); handle object (`nexObj_DF`) |
| `domain` | Axis role assignments (D1, D2, animate, F) — see Domain section below |
| `pMap` | Pool map for axis grouping |
| `collector` | Struct of named selectionBus instances — the object's state interface |
| `RESULTS` | Named store of post-operative/comparative results (STAT-shaped tables) |
| `Figure` | Struct of UI handles |
| `player` | Animation timer |

Key base methods:
- `inferDomain()` — auto-computes D1/D2/animate from DF axes; subclasses may override
- `setAnimateAxis(axKey)` — sets D2 and animate, then calls inferDomain()
- `updateScope()` — applies pooling then re-visualizes; called by cfgEntryChanged_v2
- `saveState()` — dehydrate to a plain struct for cross-workspace serialization (see below)

---

## Dehydrate / Rehydrate — `saveState` / `nexObj_fromState`

nexObjects are handle objects and **cannot cross MATLAB worker boundaries**. Use `saveState` / `nexObj_fromState` to serialize and reconstruct them in agent workspaces.

### `state = nexObj.saveState()`

Returns a plain struct (no handles, no function handles, no data arrays):

| Field | Content |
|-------|---------|
| `className` | Full MATLAB class name, e.g. `"nexObj_categorical"` |
| `classID` | Short ID, e.g. `"ctg"` |
| `dfID_source` | Source data ID |
| `headline` | Window title string |
| `domain` | Plain struct of axis role assignments (D1, D2, animate) |
| `cfg` | All `nexObj_cfg` sub-trees as primitives via `nex_serializeCfg` — function handles dropped |
| `collector` | Selection bus values as plain structs (resolved via `nex_returnSelectionMask`) |
| `selectionBus` | (nexObj_categorical only) category and item selection values |

### `nexObj = nexObj_fromState(state, nexon, Partner)`

Reconstructs the subclass headlessly:
1. Calls `str2func(state.className)(nexon, Partner, dfID_source, [], headline)` — normal constructor, headless nexon suppresses figure
2. Restores `domain` fields
3. Calls `nex_restoreCfg(nexObj.cfg, state.cfg)` — overwrites entryParams, preserves live function handles
4. Restores collector bus selections (matches saved string value to current `selKeys` index)
5. Restores selectionBus category/item selections (nexObj_categorical)

**After `nexObj_fromState`, the object reads data via the manifest nexon's HDF5-backed DTS.** No full DTS is loaded into the agent workspace.

### What is NOT saved

- `nexon`, `Parent`, `Partners`, `Children` — live handle references; re-wired at load time
- `DF`, `DF_postOp` — derived from `dfID_source` + nexon at construction
- `pMap` — derived from `DF_postOp` at construction
- `Figure` — UI handles; headless mode skips figure construction entirely
- `RESULTS` — analysis outputs; saved separately to `resultsPath` by the analysis function

---

## Domain Convention (nexObject)

For **nexObject** subclasses, D1/D2 semantics differ from mdlObject:

| Field | Meaning |
|-------|---------|
| `domain.D1` | Complement of D2 — axes NOT on the primary canvas (e.g. `"chans"`, `"f"`) |
| `domain.D2` | **Primary sweep axis** — rendered on the canvas (e.g. `"t"`); auto-inferred to `"t"` if present |
| `domain.animate` | Currently animated member of D2 |
| `domain.F` | Active latent/factor selection (indices into `DF.ax.latent`) |

`inferDomain()` always recomputes D1 as `setdiff(allAxes, D2)`. D2 is preserved if already set, otherwise auto-inferred.

> For **mdlObject** subclasses, D1 is `"t"` and D2 is the complement — opposite convention. See `Analysis/mdlObj/CLAUDE.md`.

---

## Collector / selectionBus as Universal State Interface

Every nexObject's `collector` is its **observable state machine** — not just visualization config but the full data lifecycle: what sources are available, what comparisons exist, what is selected for display.

Standard buses:

| Bus | Purpose |
|-----|---------|
| `collector.Domain` | F / D1 / ANI axis selectors |
| `collector.View` | SRC / VW / CLR (standard, most nexObjects) + subclass keys e.g. AVG |
| `collector.Pointer` | Per-axis value selectors (one key per DF.ax field, excluding `latent`) |

**Standard View keys** — always present, initialized by `nexInit_collectorView`:

| Key | Default | Meaning |
|-----|---------|---------|
| `SRC` | `"DF"` | Active data source — `"DF"` (router path) or any `RESULTS` key. `nexObj_categorical` uses `"DTS"` instead of `"DF"` |
| `VW` | `""` | Group labels within the active RESULT; empty until `reportSTAT` |
| `CLR` | `""` | Column(s) for trace colorization. Two key forms: bare column name (group-level, one color per result row) or `"ax--<field>"` (per-trace, from `DF.ax.(field)` at Pointer indices). See CLR Color Resolution section. |

Subclass-specific keys (e.g. `AVG` for `nexObj_stateSpace`) are passed via `viewDict` and appear before the standard keys in the bus:
```matlab
nexObj.collector.View = nexInit_collectorView(nexObj);              % SRC/VW/CLR only
nexObj.collector.View = nexInit_collectorView(nexObj, viewDict);    % viewDict keys first, then SRC/VW/CLR
```

**`nexObj_categorical` exception — SRC / CLR / CMP / GRP only:**

`nexObj_categorical` does **not** use `nexInit_collectorView` and intentionally omits `VW` and `Pointer` from its collector. The reason: `selectionBus.categories` and `selectionBus.items` already serve those roles natively —

| Standard key | Categorical equivalent |
|---|---|
| `VW` | `selectionBus.categories` — selects which grouping dimensions are active |
| `Pointer` | `selectionBus.items` — navigates values within each dimension |

Instead, categorical's `collector.View` carries four keys seeded at construction time:

| Key | Default | Meaning |
|-----|---------|---------|
| `SRC` | `"DTS"` | Active source — `"DTS"` (raw DTS path) or any `RESULTS` key |
| `CLR` | `""` | Column for per-bar colorization |
| `CMP` | category IDs | Compare variable(s) for `reportSTAT` |
| `GRP` | category IDs | Group variable(s) for `reportSTAT` |

When `SRC` changes, `applySRC` calls two methods in order before drawing:
1. **`updateSentinel()`** — rebuilds `DF_postOp.ax` to match the new SRC (see Sentinel Architecture below)
2. **`restoreItems()`** — re-enumerates every category slot in the items bus by calling `sBus.updateScope` per key, which dispatches through `enumerateItemsFor` automatically

**Pointer bus** (for all other nexObjects) is rebuilt via `refreshPointer()`, triggered automatically by a PostSet listener on `DF_postOp.ax`. This is the canonical example of a correct leaf-level PostSet listener — narrow scope, single trigger, no downstream dependencies of its own.

---

## nexObj_categorical Sentinel Architecture

`DF_postOp.ax` is the **sentinel** that drives items population for ax-type categories. When SRC changes, the sentinel must be updated to reflect the new data source before any items enumeration occurs.

### The two nodes of items control

**Node 1 — `nexObj_selectionBus.updateScope` → `enumerateItemsFor`**

When the user picks a category in the categories listbox, `listCfgEntryChanged` calls `selectionBus.items.updateScope(key, categoryVal)`. `updateScope` dispatches:
```
if parent implements enumerateItemsFor:
    selItems = parent.enumerateItemsFor(categoryVal)   ← SRC-aware
else:
    selItems = nexOp_enumerateCategory(parent, categoryVal)  ← DTS only (fallback)
```

`enumerateItemsFor(nexObj, category)` on `nexObj_categorical`:
- **DTS** → delegates to `nexOp_enumerateCategory` (tries `DF_postOp.ax.(field)` first, then DTS registry)
- **RESULTS** → pulls `unique(T.(col))` from the matching RESULTS table column, mapping `"ax--fieldname"` → `"ax_fieldname"` (the convention used by `nexStat_breakoutDF`: `sprintf("ax_%s", axID)`)

**Node 2 — `DF_postOp.ax` PostSet → `nexOp_sBus_alignItems2ax`**

A PostSet listener on `DF_postOp.ax` fires whenever the ax sentinel changes, calling `nexOp_sBus_alignItems2ax`. This scans the categories bus for slots with `"ax--"` values and overwrites those slots' items from `DF_postOp.ax.(field)`.

### `updateSentinel(nexObj)` — forging the sentinel

Called from `applySRC` before any items refresh:

| SRC | Action |
|-----|--------|
| `"DTS"` | Calls `updateScope()` — re-pools raw `DF` through `pMap` and writes both `DF_postOp.df` and `DF_postOp.ax`. PostSet fires → `nexOp_sBus_alignItems2ax`. |
| `RESULTS.(key)` | Extracts all `ax_*` columns from the RESULTS table, builds `newAx.(field) = unique(values)` per column, assigns directly to `DF_postOp.ax`. PostSet fires → `nexOp_sBus_alignItems2ax`. |

The RESULTS path does **not** touch `DF_postOp.df` — only `.ax` is forged, because the items bus (not the canvas) is what needs updating.

### Full `applySRC` sequence for categorical

```
applySRC(srcKey)
  1. updateSentinel()
       DTS    → updateScope() → DF_postOp.df + DF_postOp.ax ← PostSet → nexOp_sBus_alignItems2ax
       RESULTS → forge DF_postOp.ax from ax_* RESULTS columns ← PostSet → nexOp_sBus_alignItems2ax
  2. restoreItems()
       for each category slot → sBus.updateScope(key, val) → enumerateItemsFor(val)
           DTS    → nexOp_enumerateCategory (DF_postOp.ax then DTS registry)
           RESULTS → unique(T.(col)) from RESULTS table
  3. draw
       RESULTS → drawFromRESULT(srcKey)
       DTS     → reportStats([])
```

### Helper methods

| Method | Purpose |
|--------|---------|
| `getCurrentSRC()` | Returns current SRC string from `collector.View`; defaults to `"DTS"` on any error |
| `enumerateItemsFor(category)` | SRC-aware Node 1 dispatch; maps `"ax--field"` → `"ax_field"` for RESULTS lookup |
| `updateSentinel()` | SRC-aware Node 2 forge; assigns `DF_postOp.ax` to trigger PostSet |
| `restoreItems()` | Forces full items refresh for all category slots via `sBus.updateScope` |

---

## RESULTS / reportSTAT Architecture *(planned — not yet implemented)*

### Motivation

`reportSTAT(nexObj, fcn, groupVars, compareVar, resultID)` is a **base nexObject method** that applies a comparative/cross-DF function (DTW, subtraction, etc.) across groups in STAT, stores the grouped result in `nexObj.RESULTS.(resultID)`, and refreshes the SRC bus. The result shape (scalar / timecourse / trajectory) determines which nexObject subclass visualizes it.

### RESULTS store

```matlab
nexObj.RESULTS.(resultID)   % STAT-shaped table: df, ax, ptr, + grouping columns
```

Rows are the output of `splitapply` — grouping already happened upstream. Each row carries `df`, `ax`, `ptr`, and whatever grouping columns were used (e.g. `sessionLabel_subj`, `comparison`). RESULTS rows are structurally identical to STAT rows so all existing STAT-consuming machinery works unchanged.

### SRC bus

`collector.View.SRC` lists available data sources:
- `"DF"` — router-selected DF (default)
- `"AVG"` — legacy `reportAverage` path
- Any key in `nexObj.RESULTS`

### applySRC cascade

`applySRC(srcKey)` is the **single root entry point** when SRC changes. Always use structured callbacks here — not PostSet listeners — because the chain is linear and order matters:

```
applySRC(srcKey)
  1. resolveDATA(srcKey)        → {df, ax, ptr}
  2. DF_postOp.df = DATA.df
  3. DF_postOp.ax = DATA.ax     → PostSet fires → refreshPointer() automatically
  4. refreshDomainAxes(DATA.ax) → update D1/ANI/F selectors in collector.Domain
  5. rebuildWindowPanel()       → update slot dropdowns to new ptr fieldnames
  6. [subclass-specific rebuild, e.g. nexObj_stateSpace calls buildSTATE()]
  7. visualize()
```

Step 6 is **subclass-specific** — `buildSTATE()` belongs to `nexObj_stateSpace` only; other subclasses have their own equivalent (or none). Do not call `buildSTATE` from base `applySRC`.

### SRC mode determines active navigation interface

**Standard nexObjects** (stateSpace, monoGraph, etc.):

| SRC | Active controls | Rationale |
|-----|----------------|-----------|
| `"DF"` / `"AVG"` | categories / items | Pre-aggregation: grouping of raw DTS trials still needed |
| `RESULTS.(key)` | VW + Pointer | Post-aggregation: grouping already happened in `reportSTAT` |

**categories/items** = pre-aggregation interface. **VW + Pointer** = post-aggregation interface. These operate at different pipeline stages and are never both active simultaneously. `applySRC` shows/hides the appropriate controls.

When SRC = RESULTS.(key), VW is populated from the RESULT table's non-structural grouping columns (e.g. `sessionLabel_subj`, `comparison`). Pointer navigates within the selected row's axes (e.g. `dropout`).

**`nexObj_categorical`** — categories/items serve both roles at all times:

| SRC | Active controls | What changes |
|-----|----------------|--------------|
| `"DTS"` | categories + items (DTS values) | `updateSentinel` re-pools DF; `enumerateItemsFor` reads DTS registry |
| `RESULTS.(key)` | categories + items (RESULTS columns) | `updateSentinel` forges `DF_postOp.ax` from `ax_*` columns; `enumerateItemsFor` reads RESULTS table |

The items bus is the sole navigation interface regardless of SRC. No VW or Pointer panel is shown in `nexFigure_categorical`.

---

## Window Panel — Pre-allocated Slot Architecture *(planned — not yet implemented)*

The Window panel controls `ptr` range/window per axis. Pre-allocate **3–5 fixed slots** (avoid teardown/rebuild cost), each containing:
- A **UIDropdown** header listing `fieldnames(ptr)` + `"—"`
- Range min / max spinners
- Window spinner

`rebuildWindowPanel()` only updates dropdown `.Items` and `.Value` — no uicontrol creation. Each slot's `ValueChangedFcn` re-reads `ptr.(dropdown.Value)` and sets spinner limits/values. Empty slots show `"—"` with disabled spinners.

**Rules:**
- `rebuildWindowPanel()` called from `applySRC` only (structural change) — never from `stepAnimate`
- Spinner writes go directly to `ptr.(axSel).range/.window` then call `visualize()`
- Duplicate slot bindings (two slots → same axis) are allowed — harmless
- Construction logic lives in `buildWindowPanel(nexObj)` — called once at figure init; `rebuildWindowPanel` reuses it

---

## Key nexObject Subclasses

| Class | Purpose |
|-------|---------|
| `nexObj_stateSpace` | 3D latent trajectory visualization; owns `buildSTATE()`, `reportAverage()`, `rebuildTrackers()` |
| `nexObj_categorical` | Hierarchical violin/bar plots; categories/items buses replace VW+Pointer; collector.View = SRC/CLR/CMP/GRP; SRC-aware sentinel (`updateSentinel`/`enumerateItemsFor`) drives items from DTS or RESULTS |
| `nexObj_monoGraph` | Single-axis timecourse; lightweight, used as output target for averaged results |
| `nexObj_controlPanel` | Global session/subject router; drives DTS row selection upstream of all other nexObjects |
| `nexObj_DF` | Handle wrapper around a plain DF struct; enables PostSet listeners on `.ax` and `.df` |
| `nexObj_ptr` | Handle wrapper around a ptr struct; enables stable references across ptr reinit |

> `buildSTATE()` is **specific to `nexObj_stateSpace`**. It compiles AVG/DF into `STATE.Z` and initializes `STATE.ptr`. It is not a general nexObject concept.

---

## CLR Bus — Color Resolution Architecture

### CLR key types

The CLR selection bus in `collector.View` accepts two classes of key:

| Key form | Source | Semantics |
|----------|--------|-----------|
| `"sessionLabel_phase"`, `"responseThreshold"`, … | RESULT table column names (from `nexObj.STAT`) | **Group-level** — one color per result row, broadcast to all traces within that row |
| `"ax--chans"`, `"ax--f"`, `"ax--t"`, … | `"ax--" + fieldnames(DF_postOp.ax)` | **Per-trace** — one color per trace, resolved from `DF.ax.(field)` at Pointer-bus selected indices |

CLR keys are populated at construction by `initCollectorView`:
- Group-column keys come from `nexObj.STAT` columns (non-struct columns).
- `ax--X` keys are appended from `fieldnames(nexObj.DF_postOp.ax)`.

**`isfield` pitfall:** `DF_postOp` is a `nexObj_DF` handle object, not a struct. `isfield` returns `false` for handle objects even when the property exists. Use direct property access inside a `try/catch` block — never `isfield(nexObj.DF_postOp, 'ax')`.

---

### Resolution methods

Two distinct methods on `nexObject`, each with a different scope:

#### `resolveGroupColors(nexObj, dataTable, clrCols)` → `N×3`

**Table-level** — must be called with all N rows at once. Needed for group-column keys because `nexOp_resolveGroupColors` computes its HSV spread from the full set of unique values; calling it one row at a time gives `n_u = 1` → always `hues(1) = 0` → red for every row.

Two-pass blend:
1. **Pass 1 (LUT/atlas matched keys)** — Average all matched N×3 layers. If more than one matched layer, normalise per row (divide by row max) to keep hues vivid.
2. **Pass 2 (unmatched keys)** — If no LUT base, use the first unmatched key's spread directly. If LUT base present, apply HSV hue rotation ± `hue_spread/2` around the base color using the unmatched column values as the modulating variable. `n_u ≤ 1` skips the rotation (no differentiation possible).

`ax--X` entries in `clrCols` are translated to bare axis names (`col(5:end)`) before looking up in `dataTable`. If the bare name is not a column, the key is silently skipped. This lets stateSpace pass its `G_sel` table (bare column names) through `resolveGroupColors` without special-casing.

#### `resolveCLRColors(nexObj, DF, clrCols, nTraces [, rowTable])` → `[N×3, labels]`

**Per-trace, single-row** — called once per result row. Only meaningful for `ax--X` keys (per-trace differentiation). Group-column keys require the full table context — never pass them to this method via a single-row `rowTable`.

- For each `ax--X` key: reads `DF.ax.(X)` at Pointer-bus selected indices → assigns one value per trace (clamping `1:nTraces` into the selected index range). **Skips keys where all traces map to the same value** (`numel(unique(vals)) ≤ 1`) — single-value keys cannot differentiate traces and would collapse all colors to one tint.
- For each group-column key in `rowTable`: broadcasts one `rowTable.(key)` value to all nTraces. (Correct only if the full set of rows has already been handled upstream.)
- Collects all contributing N×3 layers in `all_C`, then returns their element-wise mean, normalised per row.
- `labels`: set from the first `ax--` key that resolves with >1 unique value; used by callers to build axis-value legend entries.

---

### Visualization file patterns

Each visualization file splits `clrCols` based on context:

#### `nexVisualization_monoGraph` (RESULTS branch)

Group-column keys dominate — each result row is exactly one trace (`nTraces = 1`), so `ax--` keys provide no per-trace differentiation. Call `resolveGroupColors` once **before the loop** on all matching rows:

```matlab
if ~isempty(clrCols)
    rowColors = nexObj.resolveGroupColors(RESULT(matchingRows,:), clrCols);
elseif nMatch > 1
    rowColors = nexVis_hsvSpread(nMatch);
else
    rowColors = repmat(GREEN, nMatch, 1);
end
% Inside loop:
clr = rowColors(ri,:);
```

#### `nexVisualization_waterfall` / `nexVisualization_polyGraph` (RESULTS branch)

Split `clrCols` into `axClrCols` and `grpClrCols` **before the loop**, then handle each independently:

```matlab
axClrCols  = clrCols(startsWith(clrCols, "ax--"));
grpClrCols = clrCols(~startsWith(clrCols, "ax--"));
if ~isempty(grpClrCols)
    rowBaseColors = nexObj.resolveGroupColors(RESULT(rowIdx,:), grpClrCols);
else
    rowBaseColors = [];
end

for gi = 1:numel(rowIdx)
    ...
    [C_traces, axLabels] = nexObj.resolveCLRColors(DF_g, axClrCols, nT);
    if ~isempty(rowBaseColors)
        baseClr = repmat(rowBaseColors(gi,:), nT, 1);
        if isempty(axClrCols)
            C_traces = baseClr;                          % group color only
        else
            C_traces = (C_traces + baseClr) / 2;         % blend group + per-trace
            maxC = max(C_traces, [], 2); maxC(maxC < eps) = 1; C_traces = C_traces ./ maxC;
        end
    end
    ...
end
```

Non-RESULTS branch: pass all `clrCols` to `resolveCLRColors` directly — there is only one "group" so cross-row spread is not needed, and group-column keys will be silently skipped (empty `rowTable`).

---

### `nexOp_resolveGroupColors` — resolution order

(`Operators/nexOp_resolveGroupColors.m`)

1. **Registry LUT** — `nexon.console.BASE.registry.LUT.(clrKey)`: exact label match. Cross-comparison `"A-×-B"` labels get HSV circular-mean blend of their component colors. → `matched = true`
2. **Atlas registry** — `nex_axisColorFromRegistry(nexon, clrKey, vals)` — handles structured axes like `dropout`, `chans`. → `matched = true`
3. **HSV spread fallback** — `hues = linspace(0, 1, n_u+1); hues(end) = []` — one maximally distinct hue per unique value. → `matched = false`

`matched` drives the two-pass blend in `resolveGroupColors`: matched layers go to Pass 1 (averaging), unmatched go to Pass 2 (hue rotation on the LUT base, or direct spread when no LUT base exists).

---

## PostSet Listener Rules

Use PostSet listeners **only at leaf level**:
- Single, well-defined trigger
- No downstream dependencies of their own
- Safe to fire during construction and animation

**Correct:** `DF_postOp.ax` → `refreshPointer()` — updates Pointer bus from new axis values.
**Incorrect:** chaining PostSets across multiple properties to propagate a SRC change — use `applySRC` structured callback instead.
