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
| `nexAnalysis_*` | Standalone analysis function |
| `nexExtract*` | Data extraction function |
| `applyMethod` | Runs a configured analysis method on a timecourse dataFrame |
| `grabDataFrame` / `grabDF` | Retrieve a named dataframe from the nexon object |
| `grabSession` | Retrieve session data |

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
