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
| `domain` | Axis role assignments: `D1` (always `"t"`), `FTR` (feature axis) |
| `collector` | Target bus (`.Target.Y`) and Domain bus (`.Domain`) |
| `fitPath` | Absolute path to saved model weights folder |
| `W`, `Scaler`, `Reducer` | Fitted model artifacts (Python objects + MATLAB wrappers) |
| `STAT`, `TRAIN`, `TEST`, `DM` | Runtime data; not persisted in state |
| `Predictor` | Downstream supervised node (points to self when this IS the predictor) |

Key base methods:

| Method | Purpose |
|--------|---------|
| `compileSTAT()` | Build trial table from nexObj_ctg selection → reads from DTS/HDF5 |
| `getDesignMatrix()` | Split STAT by trainMask → TRAIN/TEST; call `stat2dm_*` |
| `fit()` | compileSTAT → getDesignMatrix → `cfg.fitCfg.fcn(mdlObj, args)` |
| `transformSTAT(STAT)` | Apply fitted transform to every row in STAT → returns STAT_tf |
| `scaleApply_transform()` | Row-by-row transform over DTS selection; writes dfID_target to manifest |
| `saveState()` | Dehydrate to plain struct (see below) |
| `saveFit(uniqueID)` | Save Python model weights to `fitPath` (subclass override) |
| `loadFit(fitDir)` | Restore from `fitPath` (subclass override) |

---

## dmCfg.format — Design Matrix Conventions

| Format | Builder | Used by |
|--------|---------|---------|
| `"stack"` | `stat2dm_stack` | SSM, CEBRA — unsupervised, all train samples concatenated along D1 |
| `"batch"` | `stat2dm_batch` | Batch-mode unsupervised fitting |
| `"supervised"` | `stat2dm_supervised` | LDA, logistic — stacks X, encodes Y from `dfID_target` |
| `"regression"` | `stat2dm_regression` | Linear regression — stacks X, Y is continuous |

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

## Adding a New mdlObj Subclass

1. Create `mdlObj_<modelID>.m` in this directory, inheriting `mdlObject`
2. Set `cfg.dmCfg.format` in constructor (`"stack"` for unsupervised, `"supervised"` for classifiers)
3. Create `nexFit_<modelID>.m` — reads `mdlObj.DM`, fits the model, stores weights in `mdlObj`
4. Override `transform(mdlObj, DF_X)` — returns `DF_Z` with transformed df and updated ax
5. Override `saveFit(uniqueID)` and `loadFit(fitDir)` — serialize/restore Python model objects
6. Set `cfg.fitCfg = nex_generateCfgObj(@nexFit_<modelID>)` and `cfg.dmCfg.format` in constructor
7. If supervised: set `cfg.dmCfg.format = "supervised"`, call `initTargetBus()` in constructor
