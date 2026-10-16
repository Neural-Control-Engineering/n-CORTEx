# mdlObj — CLAUDE.md

## Overview

`mdlObj/` contains `mdlObject` (base class) and all model object subclasses. A `mdlObject` owns a model, a design-matrix builder, a fitting function, and an optional `Predictor` link. It is the primary unit of offline and agentic analysis in Nexus.

---

## mdlObject Base Class

Key properties:

| Property | Purpose |
|----------|---------|
| `modelID` | String identifier, e.g. `"ssm"`, `"lda"`, `"linear"` |
| `dfID_source` | Input data ID — HDF5 manifest key for the source dataframe |
| `dfID_target` | Dual-role field: for **transform models** (SSM, CEBRA) this is the output artifact ID written to the HDF5 manifest (e.g. `"ssm_lfp"`); for **predictor models** (linear, LDA, logistic) this is the STAT column name used as the prediction label (e.g. `"responseThreshold_g"`). Set by `applyTargetBus` from `collector.Target.Y` for supervised models. |
| `cfg.fitCfg` | `nexObj_cfg` with `.fcn` (fit function handle) and `.entryParams` |
| `cfg.dmCfg` | Format string (`"stack"`, `"batch"`, `"supervised"`, `"regression"`) |
| `cfg.cvCfg` | Cross-validation params (`numFolds`, `isShuffle`) |
| `domain` | Axis role assignments: `DN` (training-domain axis(es), default `"t"` alone — a string array, so multiple physical axes can be selected jointly; scoring still only resolves `DN(1)`), `FTR` (feature axis), `REG` (cross-sample registration identity axis, default `"None"`), `CTG` (category columns for training stratification), `SWP` (single Pointer axis name for the outer sweep loop, default `"None"`) |
| `collector` | Target bus (`.Target.Y`) and Domain bus (`.Domain`) |
| `fitPath` | Absolute path to saved model weights folder |
| `W`, `Scaler`, `Reducer` | Fitted model artifacts (Python objects + MATLAB wrappers) |
| `STAT`, `TRAIN`, `TEST`, `DM` | Runtime data; not persisted in state |
| `Predictor` | Downstream supervised node (points to self when this IS the predictor) |

Key base methods:

| Method | Purpose |
|--------|---------|
| `compileSTAT()` | Build trial table from nexObj_ctg selection → reads from DTS/HDF5 |
| `getDesignMatrix()` | Split STAT by trainMask → TRAIN/TEST; call `stat2dm_*` (or, for a `needsHR` mdlObj, the reduce-then-pool sequence — see below) |
| `fit()` | compileSTAT → getDesignMatrix → `cfg.fitCfg.fcn(mdlObj, args)` |
| `fitReduce(STAT_fit)` | Fit a `nexHR` block-PCA basis on raw (pre-pool) STAT; CV-agnostic. See "Reduce-Then-Pool" below. |
| `applyReduce(STAT, HR, layout)` | Apply an already-fitted `nexHR` model tree to raw STAT. CV-agnostic counterpart to `fitReduce`. |
| `flattenInput(DF_X)` | Convert a single-trial DF to a 2D feature matrix — `nexHR_transform` directly, or the reduce-then-pool sequence when `needsHR` |
| `transformSTAT(STAT)` | Apply fitted transform to every row in STAT → returns STAT_tf |
| `applyPointer(STAT)` / `applyPointerDF(DF)` | Slice STAT/a single DF along axes where `collector.Pointer` has a non-trivial selection. Skips the FTR/pool axes entirely when `needsHR` — see "Reduce-Then-Pool" below. |
| `applyPointerDM(axisName, vals, ax)` | DM-level counterpart to `applyPointer` — narrows an already-resolved SWP candidate list (not raw STAT) by the Pointer bus selection. `needsHR`-only; used by `nexAnalysis_cvPermute`. |
| `scaleApply_transform()` | Row-by-row transform over DTS selection; writes dfID_target to manifest |
| `saveState()` | Dehydrate to plain struct (see below) |
| `saveFit(uniqueID)` | Save Python model weights to `fitPath` (subclass override) |
| `loadFit(fitDir)` | Restore from `fitPath` (subclass override) |

---

## dmCfg.format — Design Matrix Conventions

| Format | Builder | Used by |
|--------|---------|---------|
| `"stack"` | `stat2dm_stack` | SSM, CEBRA — unsupervised, all train samples concatenated along DN(1) |
| `"batch"` | `stat2dm_batch` | Batch-mode unsupervised fitting |
| `"supervised"` | `stat2dm_supervised` | LDA, logistic — stacks X, encodes Y from `dfID_target` |
| `"regression"` | `stat2dm_regression` | Linear regression — stacks X, Y is continuous |

---

## Reduce-Then-Pool for Hierarchical Block-PCA (`needsHR`)

A pMap axis is **reduce-mode** when its `divsPerBin < 0` — deferred to
`nexHR_fit`'s hierarchical block-PCA instead of collapsed immediately. A
mdlObj is `needsHR` whenever *any* axis in `mdlObj.pMap` is reduce-mode. The
same one-line check (`any(pMap.(f).divsPerBin < 0)` over `fieldnames(pMap)`)
is duplicated at every site that needs it: `nexOp_compileSTAT.m`,
`mdlObject.getDesignMatrix`/`flattenInput`/`applyPointer`, and
`nexAnalysis_cvPermute.m`.

### Why ordering matters

A **pool-mode** axis (`divsPerBin > 0`, e.g. `t` windowed into time bins)
collapses immediately at STAT-compile time via `nexOp_poolAxes`/
`nexObj_poolMap.pool()`. If a reduce-mode FTR axis (e.g. `unit`, block-PCA'd
per anatomical region) coexists with a pool-mode axis, pooling *before*
reduction starves the block-PCA basis of resolution — it would only ever see
already-time-averaged samples instead of full raw-timepoint variance.
`nexOp_compileSTAT` avoids this by skipping **all** pMap pooling/relabeling
when `needsHR` (`TF_pooled = TF`), unconditionally — deferring both
reduction and pooling to whichever consumer builds the design matrix.

### The reduce-then-pool sequence

Every `needsHR` consumer runs the same three steps, in order, on raw (still
fully unpooled) STAT:

1. **Stack raw** — `nexOp_stackByFTR(STAT, ftrAxis)` → `[X_raw, G]`. Keeps
   only the FTR axis as feature columns; folds every other axis (including
   the still-raw pool axis) into rows, via each row's own `.ptr` (never a
   positional dim assumption). Single-FTR-axis only today — `domain.FTR`
   has only ever been one axis in practice, but this is a real scoping limit
   if that changes (see `nexOp_stackByFTR.m`'s own docstring / `WIP.md` #4).
2. **Reduce** — `mdlObj.fitReduce(STAT_fit)` (fit) or
   `mdlObj.applyReduce(STAT, HR, layout)` (apply an already-fitted model) →
   `[X_reduced, G]`. CV-agnostic — neither method has any notion of folds;
   `STAT_fit`/`STAT` is whatever the caller considers the fit-on/apply-to
   set. `fitReduce` also computes `blockColRanges` (each block's column
   range in the concatenated reduced output, via `nexHR_blockColRanges`) and
   sets `mdlObj.HR`/`mdlObj.FTR_layout` as a side effect, mirroring
   `initReducer()`'s own convention — so `flattenInput()`/later inference
   calls see a usable model without the caller wiring it manually. pMap is
   resolved via `nexOp_resolvePMapEntry`, which checks the FTR axis's
   co-indexed sibling too (pMap is typically configured on the *primary*
   sibling, e.g. `chans`'s physical position, not `unit`'s cross-session
   identity — see `nexOp_coIndexPairs`).
3. **Pool** — `nexOp_poolStackedDM(X_reduced, G, pMap, poolAxis)` →
   `[X_pooled, G_pooled]`. Groups rows by `(trialIdx, window-bin-of
   G.(poolAxis))` and mean-pools (position-based binning per trial, matching
   `nexOp_poolAxes`'s own convention exactly). `poolAxis` is resolved via
   `nexOp_resolvePoolAxis(pMap)` (the one field with `divsPerBin > 0`, or
   `""` if none).

Terminal NaN resolution (`X_raw(isnan(X_raw)) = 0`) happens inside
`fitReduce`/`applyReduce` themselves, right after stacking — same convention
as `getDesignMatrix()`'s own zero-fill, since `nexOp_alignCoAxes` NaN-pads
structurally-absent canonical positions and nothing downstream (block-PCA
included) handles NaN input.

### Where this runs

| Consumer | Runs on | Notes |
|----------|---------|-------|
| `nexAnalysis_cvPermute.m` | Once per fold (train/test split via `fitReduce`/`applyReduce` separately), then sliced per SWP combo | SWP resolves dual-mode post-reduce: the FTR axis sweeps by **column-block** (`blockColRanges`, matched by block label), a pool-mode SWP axis sweeps by **row-group** (matched by window bin-ID) — see the local function `resolveSWPMaskHR`. Also re-fits on the full CTG data (no train/test split) after the fold loop so the transform path (`flattenInput`) stays valid against the full canonical width. |
| `mdlObject.getDesignMatrix()` | Once, on `STAT_train` (no folds) | For a plain, non-CV `fit()`. Gated on `strcmp(mdlObj.cfg.dmCfg.format, "supervised")` — other formats still fall through to the old `dmFcn`/`buildFTRLayout`/`initReducer` path, which does *not* handle `needsHR` pooling correctly (see `WIP.md` #5). |
| `mdlObject.flattenInput(DF_X)` | Once, on a single-trial `DF_X` | Wraps `DF_X` into a 1-row STAT-shaped table (cell-wraps `.df` to match `STAT.df`'s own storage convention, since `nexOp_stackByFTR` indexes `STAT.df{i}`) before calling `applyReduce`. Used by every subclass `transform()` (e.g. `nexFigure_lda_visualize`'s per-trial scatter). Same `"supervised"`-format gate as `getDesignMatrix()`. |

Y-handling (quantile quantization via `nexOp_quantizeY`, label encoding,
`DM.K.(tVar)`) is assembled separately via `nexOp_buildSupervisedDM(X, Y,
tVar, edges)` — factored out specifically because it's
`"supervised"`-format-specific, while the reduce+pool steps above are
format-agnostic (shared by `nexAnalysis_cvPermute.m` and `mdlObject.m`).

### Pointer filtering at the DM level (`applyPointerDM`)

`applyPointer(STAT)` — the usual mechanism for narrowing STAT by the Pointer
bus's current axis selection — **skips the FTR axis (and its co-indexed
siblings) and the pool axis entirely when `needsHR`**, regardless of whether
the Pointer bus's selection type happens to match STAT's raw values. This
isn't the older type-mismatch skip (which only fires on a genuine type
mismatch) — it's unconditional, because slicing those axes on raw STAT
*before* reduction breaks the block-PCA basis (which needs every raw unit
within a region to fit its per-block model) and any later `nexHR_transform`
call (which expects data at the exact width the model was fitted against).

Instead, `mdlObj.applyPointerDM(axisName, vals, ax)` narrows a
caller-supplied candidate value list — already resolved to post-reduce/
post-pool granularity (block labels or window bin-IDs) — against the Pointer
bus's current selection, with the same co-indexed-sibling resolution
`nexOp_resolvePMapEntry` uses. `nexAnalysis_cvPermute.m`'s `swpAxes`
construction calls it right after resolving each `needsHR` axis's candidate
`vals`, so a Pointer selection like "STN, HY only" actually narrows the SWP
sweep instead of being silently ignored.

---

## Dehydrate / Rehydrate — `saveState` / `mdlObj_fromState`

mdlObjects are handle objects and **cannot cross MATLAB worker boundaries**. Use `saveState` / `mdlObj_fromState` to serialize and reconstruct them in agent workspaces.

### `state = mdlObj.saveState()`

Returns a plain struct (no handles, no Python objects, no data arrays):

| Field | Content |
|-------|---------|
| `className` | Full MATLAB class name, e.g. `"mdlObj_ssm"` |
| `modelID` | Short ID, e.g. `"ssm"` |
| `headline` | Window title string |
| `dfID_source` | Input data ID |
| `dfID_target` | Output artifact ID (transform models) or label column name (predictor models) |
| `fitPath` | Path to saved model weights on disk |
| `domain` | Axis role assignments as plain strings |
| `cfg` | All `nexObj_cfg` sub-trees as primitives via `nex_serializeCfg` |
| `collector` | Target and Domain bus values as plain structs |

### `mdlObj = mdlObj_fromState(state, Parent, Origin)`

Reconstructs the subclass headlessly:
1. Calls the subclass constructor — headless nexon suppresses figure
2. `Parent` is wired as `mdlObj.Parent`, making `compileSTAT()` work without any additional nexObj arg
3. Restores `fitPath`, `dfID_target`, `domain`
4. Calls `nex_restoreCfg(mdlObj.cfg, state.cfg)` — overwrites entryParams, preserves live function handles
5. Restores collector selections

Then call `mdlObj.loadFit(state.fitPath)` to restore trained weights.

```matlab
mdlObj = mdlObj_fromState(state, nexObj_ctg, nexObj_ctg);
mdlObj.loadFit(state.fitPath);
```

### What is NOT saved

- `W`, `Scaler`, `Reducer`, `model` — Python model objects; live at `fitPath`, restored by `loadFit`
- `STAT`, `TRAIN`, `TEST`, `DM` — derived at runtime from the manifest DTS
- `nexon`, `Parent`, `Origin`, `Predictor` — live handle refs; re-wired at load time
- `Figure` — headless mode skips figure construction

---

## Phase-Based Analysis Convention

Each mdlObj operates as a **single pipeline phase**, not as a link in a live chain. Phases communicate through named dfIDs written to the HDF5 manifest:

```
Phase 1: mdlObj_ssm   dfID_source="lfp"      → fit → scaleApply_transform → writes "ssm_lfp"
Phase 2: mdlObj_lda   dfID_source="ssm_lfp"  → cvPermute → writes RESULTS
```

The chain is the dfID lineage in HDF5. No live Predictor link is required between phases. This makes each phase independently dispatchable via `nexAgent_run`.

---

## Collector Architecture for Predictor mdlObjects (linear, lda, logistic)

Predictor mdlObjects own a `collector` with three buses, initialized in `nexFigure_<modelID>`:

### `collector.View`  — initialized via `initViewBus()` (wraps `nexInit_collectorView(mdlObj, viewDict)`)

| Key | Default | Meaning |
|-----|---------|---------|
| `CTG` | derived from `Origin.selectionBus.categories`, else `"sessionLabel_phase"` | Multi-select category columns for training stratification. Mirrors `nexObj_categorical` CTG. All-selected-by-default is overridden to nothing-selected. |
| `SWP` | `["None", <collector.Pointer axis names>]`, selection = `"None"` | Single-select outer-loop axis name. Values to iterate come from the Pointer bus on that axis, not stored here. |
| `SRC` | `"fit"` | Active artifact. `"fit"` = current in-memory fit. Any key in `RESULTS` = a stored comparative result. |
| `VW` | `""` | Group/row labels from the active `RESULTS.(srcKey)` table. One item per row. All selected by default. |
| `CLR` | `""` | Column for per-point colorization; unused by default. |

`SRC` for mdlObjects defaults to `"fit"` (not `"DF"`) because there is no live router/DTS path — the model has already been trained.

`applyViewBus()` reads the CTG/SWP selections off `collector.View` into `domain.CTG`/`domain.SWP`; call it from the CTG/SWP listbox callbacks the same way `applyDomainBus()` is called from Domain listbox callbacks. See `nexFigure_lda.m`/`nexFigure_ssm.m` for the wiring pattern.

### `collector.Domain` — initialized via `buildSelection(mdlObj, domainDict)`

| Key | Values | Meaning |
|-----|--------|---------|
| `DN` | axis names from `Origin.DF_postOp.ax` | Training-domain axis(es) — multi-select, defaults to `"t"` alone. Listbox max-selections is `numel(axNames)`, not 1 (only `REG` is forced single-select). Scoring still only resolves `DN(1)` — see `nexAnalysis_cvPermute`. |
| `FTR` | same axis names | Feature selection axis |
| `REG` | `nexOp_computeREGOptions(FTR, ax)` — `"None"` ∪ co-indexed partners of the selected FTR axis(es) | Cross-sample registration identity axis (e.g. `"chans"` pre-unitMatch, `"unit"` post-unitMatch). Single-select. Call `mdlObj.refreshREG()` from the FTR-changed callback to keep candidates in sync — see `nexFigure_lda_onDomainChange`/`nexFigure_ssm_onDomainChange`. Consumed by `nexOp_alignCoAxes` inside `nexOp_compileSTAT`, and by `applyPointer`/`applyPointerDF` (via `nexOp_coAlign`) to propagate a mask from a co-indexed label axis to the sibling axis that owns the real DF dimension. |

Full co-registration mechanics (mask propagation, canonical alignment, the CTG×SWP sweep that produces stacked STAT results) are documented in `../CoRegistration_Design.md` — that doc also tracks a couple of open deviations between the original design and what's actually implemented in `nexAnalysis_cvPermute.m`.

### `collector.Pointer` — initialized via `buildSelection(mdlObj, ptrDict)`

One key per non-`latent` axis in `Origin.DF_postOp.ax`. Values = axis tick labels. Used to window into the active result's `df` axes (e.g. `regionDropout`, `f`, `chans`). Built at figure init from `Origin.DF_postOp.ax`; rebuilt via `refreshPointer()` when axes change.

---

## VW Bus and RESULTS Table Shape

`RESULTS.(resultID)` is a STAT-shaped table where **each row = one group/condition** being compared. This is the direct output of `nexOp_reportSTAT(nexObj, dfID, fcn, compareVars, groupVars, k)`:

- `compareVars` — defines the comparison axis (e.g. `"sessionLabel_phase"` → phases compared pairwise)
- `groupVars` — defines stratification (e.g. `"sessionLabel_subj"` → within each subject)
- Each row in the resulting STAT table carries the DF result for one (groupVar × compareVar) combination

**VW items = non-structural row-label columns** (`setdiff(columnNames, ["df","ax","ptr","avgCfg"])`). Selecting multiple VW items overlays those group traces on the canvas. `refreshVW(resultID)` builds row labels by joining grouping column values with ` | ` and wires them into the listbox.

For `nexAnalysis_cvPermute` results stored as plain DF structs (not tables), `refreshVW` creates a single VW item from `resultID`. The outer axis (e.g. `regionDropout`) is navigated via `collector.Pointer`, not VW.

---

## Results Lifecycle

```matlab
% Store a result and switch the canvas to it:
mdlObj.storeResult(resultID, STAT_or_DF)

% Manually switch source view:
mdlObj.applySRC('fit')          % → scatter Y_pred vs Y_actual, VW hidden
mdlObj.applySRC(resultID)       % → show VW panel, populate from RESULTS rows, render

% Populate VW without switching SRC:
mdlObj.refreshVW(resultID)
```

`applySRC` controls VW panel visibility: hidden when `SRC = "fit"`, shown when `SRC` is a RESULTS key. This keeps the panel uncluttered during normal fitting.

---

## Adding a New mdlObj Subclass

1. Create `mdlObj_<modelID>.m` in this directory, inheriting `mdlObject`
2. Set `cfg.dmCfg.format` in constructor (`"stack"` for unsupervised, `"supervised"` for classifiers)
3. Create `nexFit_<modelID>.m` — reads `mdlObj.DM`, fits the model, stores weights in `mdlObj`
4. Override `transform(mdlObj, DF_X)` — returns `DF_Z` with transformed df and updated ax
5. Override `saveFit(uniqueID)` and `loadFit(fitDir)` — serialize/restore Python model objects
6. Set `cfg.fitCfg = nex_generateCfgObj(@nexFit_<modelID>)` and `cfg.dmCfg.format` in constructor
7. If supervised: set `cfg.dmCfg.format = "supervised"`, call `initTargetBus()` in constructor
