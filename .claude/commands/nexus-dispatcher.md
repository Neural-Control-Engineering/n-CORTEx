# nexus-dispatcher — Agentic Analysis Dispatch Design

Reference for the analysis dispatcher pattern: how selections, analysis schemas, and
RESULTS tables connect the scientist's questions to agentic/async computation.

---

## Core Principle

Every analysis answers exactly one question. The question drives the RESULTS shape.
The axes are the dimensions of that question. Do not design a universal schema —
design one schema per analysis type.

---

## Two Dispatch Modes

### Mode 1 — Trial-space transform
Fit once on pooled selected trials, transform each trial, write a new dfID to HDF5.

```
selection mask
  → pool STAT rows
  → fit(pooled df)           ← one model fit across all selected trials
  → nexTract-style loop
  → dtsIO_writeDF per trial  ← new group in HDF5 (e.g. pca_lfp/)
```

Result lives in HDF5 as a new dfID. Any nexObj can load it via the DTS source path.
`mdlObj_reducer` (PCA, etc.) is the canonical example.

### Mode 2 — Cross-trial analysis
Operates across trial groups, produces a RESULTS table stored in `nexObj.RESULTS.(resultID)`.

```
selection mask
  → nexOp_compileSTAT → STAT table
  → analysisFn(STAT, cvCfg)
  → nexObj.RESULTS.(resultID)   ← RESULTS table: df + ax + grouping cols
```

`reportSTAT` / `nexObj.reportSTAT` is the canonical entry point.

---

## analysisSpec

A struct passed to the dispatcher that fully describes one analysis job:

| Field | Purpose |
|---|---|
| `mode` | `"transform"` or `"analyze"` |
| `fn` | MATLAB function handle or Python callable string |
| `inputDFID` | Source dfID (e.g. `"lfp_nex_pcaNoiseRm"`) |
| `cvCfg` | `nFolds`, `nPermute`, `permuteFn` — empty if no CV |
| `resultID` | Key in `nexObj.RESULTS` where output is stored |
| `outputShape` | Description of expected df + ax (for contract validation) |

---

## RESULTS Table Shape Convention

Each analysis type has a fixed output shape. The shape is baked into the analysis
type — not negotiated at runtime.

| Question | df shape | axes | Viewer |
|---|---|---|---|
| SSM/predictor validity (CV + permutation) | scalar accuracy | `fold`, `permute`, `condition` | `nexObj_categorical` + `nexObj_monoGraph` |
| Dynamic timescales (eigenspectra) | `[nEigen × 1]` complex (re/im split) | `condition`, `region` | `nexObj_eigenspec` |
| LDA AUROC | `[1 × nThresh]` | `fold`, `permute`, `condition` | `nexObj_monoGraph` |
| AIC / BIC vs state dim | scalar | `state_dim`, `model` | `nexObj_categorical` |
| PCA variance explained | `[1 × nComponents]` | `component`, `region` | `nexObj_monoGraph` |

### Complex numbers in HDF5
HDF5 does not store complex doubles natively. Store as two real suffixes:
```
ax.eig_re = real(eigenvalues)
ax.eig_im = imag(eigenvalues)
```
The viewer reconstructs `complex(eig_re, eig_im)` internally.

---

## mdlObj Role in the New Architecture

`mdlObj` is an **artifact loader and compute interface**, not primarily a training engine.
Fitting may happen out of process (Python, HPC, agent). The object's value is:

1. **Deserialization** — `loadFit(path)` reconstructs W, Scaler, Reducer from the
   `mdlObj_ssm_{id}/` folder regardless of how they were trained
2. **Transform** — `transform()` applies the loaded model to selected trials,
   writes state DFs to HDF5 via `dtsIO_writeDF`
3. **reportX methods** — `reportEigenspectra`, `reportAIC`, etc. compute RESULTS
   tables from fitted parameters → consumed by nexObj viewers
4. **Visualization bridge** — serves as `Parent` for `nexObj_stateSpace`

Interactive fitting (`mdlObj.fit()`) remains for exploratory single-fit work.
For batch/CV/agentic workflows, fitting happens elsewhere and `loadFit` is the
primary entry point.

---

## New nexObj_X — When to Build One

Only build a new `nexObj_X` when the visualization geometry is genuinely novel.
Most analyses reuse existing viewers:

- **Bar/scalar RESULTS** → `nexObj_categorical`
- **Timecourse RESULTS** → `nexObj_monoGraph`
- **Unit circle / complex plane** → `nexObj_eigenspec` (build this)
- **3D trajectory** → `nexObj_stateSpace`

The build list for new analyses is mostly **compute functions + RESULTS shapes**,
not new figure classes.

---

## Async / Agent Execution

For heavy fits, `fn` is a thin MATLAB wrapper around `py.*` — same pattern as
`mdlObj_ssm`. For non-blocking execution:

```matlab
f = parfeval(@nexAnalysis_async, 1, nexon, spec, STAT);
afterEach(f, @(~, res) nexObj.storeResult(spec.resultID, res));
```

An agent receiving the spec needs only:
- The selection (STAT table or HDF5 trial indices)
- The analysisSpec struct
- Write access to the HDF5 file and `nexObj.RESULTS`

It returns a completion signal. MATLAB reloads the result via `nexObj.applySRC`.

---

## Division of Labor

**Scientist:**
- Define the question → drives analysis schema + RESULTS shape
- Curate the selection via `nexObj_categorical` + router
- Design the visualization → which `nexObj_X` answers the question
- Interpret the result

**Agent / dispatcher:**
- Receive spec (selection + schema + resultID + cfg)
- Fit, validate, permute — all expensive compute
- Write artifacts to disk (HDF5 for DFs, `saveFit/` for models)
- Write RESULTS table in the agreed shape
- Return completion signal

The tighter the output schema contract per analysis type, the less supervision the
agent requires. Each solidified schema becomes a primitive the agent can invoke
without discussion — freeing scientific bandwidth for question design and
interpretation.

---

## Established Analysis Primitives (build list)

| Name | Mode | Status |
|---|---|---|
| `nexAnalysis_cvPermute` | analyze | planned |
| `nexAnalysis_cvLDA` | analyze | planned |
| `mdlObj_ssm.reportEigenspectra` | analyze | planned |
| `mdlObj_ssm.reportAIC` | analyze | planned |
| `nexTract` + `mdlObj_reducer` (PCA transform) | transform | exists |
| `nexTract` + `mdlObj_ssm` (state transform) | transform | exists |
