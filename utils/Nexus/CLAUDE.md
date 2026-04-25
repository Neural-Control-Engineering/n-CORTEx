# Nexus — CLAUDE.md

## Overview

Nexus is the analysis and visualization framework embedded in n-CORTEx. It handles real-time and offline neural data analysis through a modular, operator-based pipeline built around the `Nexon` handle object.

**Entry points:**
- `startNexus(params, DTS)` — MATLAB initialization, returns a `Nexon` instance
- `startNexus.ipynb` — Jupyter notebook interface
- `nex_addpath.py` — Python path configuration

**Python environment:** `~/miniconda3/envs/nexus/bin/python` (Python 3.10, PyTorch, OutOfProcess execution mode)

---

## Core Object Model

### `Nexon` (handle class)
The root object. Everything hangs off it.

| Property | Purpose |
|----------|---------|
| `nexon.console` | UI panels and display objects (`BASE`, `NPXLS`, `SLRT`, ...) |
| `nexon.UserData` | Arbitrary user/session data storage |
| `nexon.settings` | Global settings (Colors, etc.) |
| `nexon.console.BASE.DTS` | The active Data Table/Struct — primary data carrier |
| `nexon.console.BASE.router` | Session/subject routing configuration |

Key method: `nexon.appendToDTS(DTS)` — merges new data into the active DTS and updates the router.

---

## Directory Structure

```
utils/Nexus/
├── Nexon.m                   # Root handle class
├── startNexus.m              # Initialization function
├── Analysis/                 # Analysis domain modules
│   ├── Classification/       # LDA and classifiers
│   ├── DimensionReduction/   # DR algorithms
│   ├── Embedding/            # CEBRA, PCA, UMAP, t-SNE
│   ├── Filtering/            # Kalman, CAR, ICA
│   ├── MachineLearning/      # MLCTL, model objects (MLCTL, mdlObj)
│   ├── mdlObj/               # Model object classes (LDA, logistic, CEBRA, SSM)
│   ├── Modeling/             # General modeling
│   ├── NeuralFieldModels/    # Neural field models (CTBG)
│   ├── NeuralNetworks/       # Deep learning (RTSpec, STATICnet)
│   ├── Pooling/              # Data pooling
│   ├── Regression/           # Logistic, linear regression
│   ├── Smoothing/            # ASLS smoothing
│   ├── SpectralAnalysis/     # Band ratio, FOOOF, PSD
│   ├── Statistics/           # STAT, Welford averaging, fold allocation
│   └── Transformation/       # Wavelet, STFT, Hilbert, CSD
├── Operators/                # Data transformation functions (~95 files)
│   ├── Init/                 # Registry and pMap initialization
│   ├── Alignment/            # Data alignment operators
│   ├── LFP/                  # LFP-specific operators
│   └── *.m                   # Core operator functions
├── nexObj/                   # UI and data object constructors
├── nexFigure/                # Figure management
├── nexEntry/                 # Entry point / configuration dialogs
├── nexIO/                    # Input/output handling
├── Route/                    # Data routing and pipeline control
├── Buffer/                   # Data buffering
├── RealtimeControl/          # Real-time control interfaces (cortexCtrl, Proxy)
├── DTSIO/                    # DTS input/output
├── CVIO/                     # Computer vision I/O
├── Selections/               # Data selection utilities
├── Visualization/            # Visualization framework
├── Write/                    # Data export (ML, Format, Export)
├── Animate/                  # Animation
├── Draw/                     # Drawing utilities
├── Compute/                  # Computational utilities
├── Generate/                 # Code/data generation
├── Map/                      # Mapping utilities
├── Figures/                  # Figure generation
├── Traceback/                # Error tracking
├── Update/                   # Update utilities
├── Directory/                # Directory structure management
└── python/                   # Python modules (embedding, etc.)
```

---

## Naming Conventions

| Prefix/Pattern | Meaning |
|----------------|---------|
| `nex_*` | General Nexus utility function |
| `nexObj_*` | Constructor for a UI or data object |
| `nexPanel_*` | Constructor for a UI panel (`nexPanel_BASE`, `nexPanel_NPXLS`, `nexPanel_SLRT`) |
| `nexInit_*` | Initialization routine |
| `nexOp_*` | Operator function (slice, transform, etc.) |
| `nexWrite_*` | Data formatting/export function |
| `nexPlot_*` | Plotting function |
| `nexAnalysis_*` | Standalone analysis function (agent-callable; no live objects required) |
| `nexAgent_*` | Agent entry point or contract builder |
| `nexExtract*` | Data extraction function |
| `applyMethod` | Runs a configured analysis method on a timecourse dataFrame |
| `grabDataFrame` / `grabDF` | Retrieve a named dataframe from the nexon object |
| `grabSession` | Retrieve session data |
| `*_fromState` | Headless object reconstructor from a saved state struct |

---

## Operator Pattern

Operators are functions in `Operators/` that transform a `df_in` → `df_out` given an `args` struct. The `applyMethod` function is the standard dispatch mechanism:

```matlab
% applyMethod.m pattern
methodCfg = timeCourse.UserData.methodCfg;
args = methodCfg.Panel.entryParams;
df_in = timeCourse.dataFrame;
df_out = methodCfg.UserData.methodFcn(df_in, args);
timeCourse.dataFrame = df_out;
```

New operators should follow: `function df_out = myOperator(df_in, args)` and be registered via the pMap (`nexInit_pMap.m`).

---

## Panel/UI Object Pattern

Panels are constructed with `nexObj_*` or `nexPanel_*` functions that return a struct or object attached to `nexon.console`. They typically hold:
- `.Figure` — the uifigure/uipanel
- `.UserData` — state and data references
- `.dataFrame` — active data
- `.methodCfg` — bound analysis method configuration

---

## Data Flow

```
DTS (Data Table) → Router → Selection → Operator Pipeline → timeCourse.dataFrame → Visualization
```

- **DTS**: Core timetable/struct, rows = trials, columns = modalities/features
- **Router**: Filters DTS by session, subject, experiment (`initializeRouterCfg`, `setupRouter`)
- **Selections**: Masks and subsets (`nex_compileSelection`, `nex_applySelectionMask`)
- **Operators**: Transform data frames; applied via `applyMethod`
- **Visualization**: Panels update via `updateTimeCourse`, `updateNpxlsPanel`, etc.

---

## Python Integration

Python is invoked out-of-process. Modules live in `python/` and `Analysis/Embedding/`.

```matlab
% Standard Python setup (in startNexus.m)
pyenv(Version="~/miniconda3/envs/nexus/bin/python", ExecutionMode="OutOfProcess");
```

Python functions are called via `py.*` from MATLAB. Path injection uses `py.sys.path`.

---

## nexObj_cfgPanel_v2 — Callback Convention

`nexObj_cfgPanel_v2` wires each entry field's `ValueChangedFcn` to:
```matlab
entryChangedFcn(nexObj, cfgObj, nexPanel, editField, entryChangedFcnArgs)
```

**Generic handler:** `cfgEntryChanged_v2` — use this for any `nexObj_cfgPanel_v2` panel unless the object needs special post-update behavior:
```matlab
nexObj_cfgPanel_v2(nexObj, cfgObj, panelObj, entryParams, str2func("cfgEntryChanged_v2"), [])
```
It updates `cfgObj.entryParams.(field)` from the UI value, then calls `nexObj.updateScope()` only if that method exists (`ismethod(nexObj, 'updateScope')`).

**Special cases** (require a custom callback):
- `visCfg` panels — must call `nexObj.visualize()` after param update
- Any panel where a parameter change must immediately retrigger computation/rendering

Do NOT write per-figure `fitCfgEntryChanged`, `aniCfgEntryChanged`, etc. — use `cfgEntryChanged_v2` instead.

---

## Domain Convention

Every Nexus object (both `nexObject` subclasses and `mdlObject` subclasses) carries a `domain` struct that describes which axes play which role.

| Field | Meaning |
|-------|---------|
| `domain.D1` | **Primary axis** — rendered on the canvas itself (e.g. `"t"` for time). For all `mdlObject`s this is always `"t"`. |
| `domain.D2` | **Full complement** — `setdiff(allAxes, D1, "stable")`. The complete set of non-primary axes. Never set this manually; it is computed by `nexInit_domain`. |
| `domain.FTR` | **Feature selection** — a caller-chosen subset of `D2` (one axis or several). Not an alias for `D2`; can be narrowed at any time by `applyDomainBus`. |
| `domain.animate` | (`nexObject` only) The currently animated member of `D2`. |

**Initialization** — always use `nexInit_domain`:
```matlab
% base mdlObject constructor calls this automatically:
mdlObj.domain = nexInit_domain(mdlObj.Origin.DF_postOp);  % D1="t", D2=all other axes, FTR=D2 default

% subclasses narrow FTR to the axis they actually operate on:
mdlObj.domain.FTR = mdlObj.domain.D2(1);   % e.g. first non-t axis
```

**Rules:**
- Do NOT manually set `domain.D1` or `domain.D2` in subclass constructors — the base `mdlObject` constructor handles both via `nexInit_domain`.
- `FTR` is the only domain field subclasses should write after construction; it expresses *which* feature dimension(s) this model operates on and may be narrowed further by `applyDomainBus`.
- `FTR` is initialized to `D2` by `nexInit_domain` as a safe default; subclasses that know their operating axis should narrow it to `D2(1)` or a specific axis name.
- For `nexObject` subclasses, `D2` may contain `"t"` (the sweep axis lives in D2, D1 is the complement) — the semantics flip relative to `mdlObject`. Check `nexObject.inferDomain()` for that path.

---

## nexObject Architecture

See `nexObj/CLAUDE.md` for the full nexObject architecture including:
- Collector / selectionBus conventions
- RESULTS / reportSTAT architecture (planned)
- applySRC cascade and PostSet listener rules
- Window Panel slot architecture (planned)

---

## Agentic Analysis — Dehydrate / Rehydrate Paradigm

### Core Constraint

MATLAB handle classes (`nexObject`, `mdlObject`, `Nexon`) are reference types and **cannot be passed to parallel workers** (`parfeval`, `matlab -batch`, separate processes). The dehydrate-rehydrate schema is the canonical solution: serialize object state to a plain struct on the main session, reconstruct headless objects in the agent workspace from that struct.

### Dehydrate — `obj.saveState()`

Every `nexObject` and `mdlObject` subclass inherits `saveState()` from its base class. It returns a plain struct containing:

- Identity fields: `className`, `modelID`/`classID`, `dfID_source`, `headline`
- `domain` — axis role assignments (D1, FTR, etc.) as plain strings
- `cfg` — all `nexObj_cfg` sub-trees serialized via `nex_serializeCfg` (primitives only; function handles are dropped and re-derived at load time)
- `collector` — selection bus values as plain value structs
- `selectionBus` — (nexObject only) category/item selection values
- `fitPath` — (mdlObject only) path to saved model weights on disk

What is **not** saved: live Python model objects, figure handles, Parent/nexon/Origin references, raw data arrays. These are either re-derived at construction or loaded separately via `loadFit(fitPath)`.

```matlab
% Main session — dehydrate
state_ssm = mdlObj_ssm.saveState();
state_ctg = nexObj_ctg.saveState();
save('contract.mat', 'state_ssm', 'state_ctg', 'analysisCfg');
```

### Rehydrate — `*_fromState`

Two standalone constructors reconstruct headless objects from a saved state:

```matlab
% Agent workspace — rehydrate
nexon    = nexon_fromManifest(manifestPath);           % lightweight, HDF5-backed
nexObj   = nexObj_fromState(state_ctg, nexon, []);     % nexObject subclass
mdlObj   = mdlObj_fromState(state_ssm, nexObj, nexObj); % mdlObject subclass
mdlObj.loadFit(state_ssm.fitPath);                     % restore trained weights
```

The reconstructed objects behave identically to their main-session counterparts. All method calls (`compileSTAT`, `fit`, `transform`, `scaleApply_transform`) work unchanged because the manifest nexon wires HDF5-backed DTS IO transparently.

### Generic Cfg Utilities

`nex_serializeCfg` / `nex_restoreCfg` are the shared engine behind `saveState` / `fromState` for both object families:

- `nex_serializeCfg(cfg)` — walks any `nexObj_cfg` or plain struct recursively; uses `properties()` for `nexObj_cfg` (dynamicprops) and `fieldnames()` for plain structs; keeps primitives, drops function handles and handle objects
- `nex_restoreCfg(target, serial)` — inverse walk; skips function handles already in the live target (they stay as-is), restores all primitive fields

Both functions are model-agnostic: the same call handles `fitCfg`, `visCfg`, `dmCfg`, `cvCfg` — any sub-cfg regardless of content.

### Manifest Nexon

`nexon_fromManifest(manifestPath)` creates a lightweight `Nexon` instance with:
- `settings.headless = true` — suppresses all figure construction
- `console.BASE.DTS` set to the saved manifest table (h5_path + h5_root columns only; no data arrays in memory)
- `console.BASE.controlPanel.averagingSelection` restored from saved state

All `dtsIO_readDF` calls on this nexon fetch from HDF5 on demand. The full DTS is never loaded into the agent workspace.

### Phase-Based Pipeline Convention

Analysis pipelines are composed as **independent phases**, not monolithic chains. Each phase has one primary mdlObj and communicates with the next phase through a named artifact written to the HDF5 manifest:

```
Phase 1:  mdlObj_ssm  reads dfID "lfp"       → fits SSM, transforms, writes dfID "ssm_lfp"
Phase 2:  mdlObj_lda  reads dfID "ssm_lfp"   → CV, scores, writes RESULTS to resultsPath
```

The "chain" is the dfID lineage in HDF5, not object linkage. Each phase is independently resumable, auditable, and agent-dispatchable.

### Agent Contract and Dispatch

```matlab
% Contract schema (saved as .mat or JSON)
contract.nexonManifestPath    % path to manifest .mat
contract.controlPanelState    % averagingSelection values
contract.nexObj_ctg_state     % saveState() output for the categorical nexObject
contract.mdlObj_state         % saveState() output for the primary mdlObject
contract.analysisID           % e.g. 'nexAnalysis_cvPermute'
contract.analysisCfg          % nFolds, nPermute, resultID, resultsPath, ...
```

```matlab
% nexAgent_run(contractPath) — universal agent entry point
% Callable via:  parfeval(@nexAgent_run, 0, contractPath)
%                matlab -batch "nexAgent_run('contract.mat')"
function nexAgent_run(contractPath)
    C       = load(contractPath);
    nexon   = nexon_fromManifest(C.nexonManifestPath, C.controlPanelState);
    nexObj  = nexObj_fromState(C.nexObj_ctg_state, nexon, []);
    mdlObj  = mdlObj_fromState(C.mdlObj_state, nexObj, nexObj);
    if ~isempty(mdlObj.fitPath)
        mdlObj.loadFit(mdlObj.fitPath);
    end
    feval(C.analysisID, mdlObj, C.analysisCfg);
end
```

The analysis function (`nexAnalysis_cvPermute`, `nexAnalysis_fitTransform`, etc.) takes only `(mdlObj, cfg)` — `nexObj_ctg` is already wired as `mdlObj.Parent` by `mdlObj_fromState`, so it never needs to be passed separately. The function is unaware of whether it's running in an agent or a live session.

---

## Adding New Analysis Modules

1. Create a directory under `Analysis/<Domain>/`
2. Implement the core function as `df_out = myAnalysis(df_in, args)`
3. If it needs a UI-configurable entry, add a `nexObj_cfg_*` or `nexEntry_*` panel
4. Register in `Operators/Init/nexInit_pMap.m` so `applyMethod` can dispatch to it
5. If Python-backed, add the module to `python/` and load via `py.*`

---

## Active Development

Current branch: `Dev_MS_realtimeControl_antigravity`

Recent focus:
- `RealtimeControl/` — antigravity real-time control system
- `Analysis/mdlObj/` — SSM (state-space models) and LDA model objects
- CEBRA embedding and animated visualization
- SLRT routing robustness
