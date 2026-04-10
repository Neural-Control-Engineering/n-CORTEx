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
| `collector.View` | AVG / VW / CLR / SRC group selectors |
| `collector.Pointer` | Per-axis value selectors (one key per DF.ax field, excluding `latent`) |

**Pointer bus** is rebuilt via `refreshPointer()`, which is triggered automatically by a PostSet listener on `DF_postOp.ax`. This is the canonical example of a correct leaf-level PostSet listener — narrow scope, single trigger, no downstream dependencies of its own.

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

| SRC | Active controls | Rationale |
|-----|----------------|-----------|
| `"DF"` / `"AVG"` | categories / items | Pre-aggregation: grouping of raw DTS trials still needed |
| `RESULTS.(key)` | VW + Pointer | Post-aggregation: grouping already happened in `reportSTAT` |

**categories/items** = pre-aggregation interface. **VW + Pointer** = post-aggregation interface. These operate at different pipeline stages and are never both active simultaneously. `applySRC` shows/hides the appropriate controls.

When SRC = RESULTS.(key), VW is populated from the RESULT table's non-structural grouping columns (e.g. `sessionLabel_subj`, `comparison`). Pointer navigates within the selected row's axes (e.g. `dropout`).

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
| `nexObj_categorical` | Hierarchical violin/bar plots; owns categories/items selection buses; driven by DTS grouping |
| `nexObj_monoGraph` | Single-axis timecourse; lightweight, used as output target for averaged results |
| `nexObj_controlPanel` | Global session/subject router; drives DTS row selection upstream of all other nexObjects |
| `nexObj_DF` | Handle wrapper around a plain DF struct; enables PostSet listeners on `.ax` and `.df` |
| `nexObj_ptr` | Handle wrapper around a ptr struct; enables stable references across ptr reinit |

> `buildSTATE()` is **specific to `nexObj_stateSpace`**. It compiles AVG/DF into `STATE.Z` and initializes `STATE.ptr`. It is not a general nexObject concept.

---

## PostSet Listener Rules

Use PostSet listeners **only at leaf level**:
- Single, well-defined trigger
- No downstream dependencies of their own
- Safe to fire during construction and animation

**Correct:** `DF_postOp.ax` → `refreshPointer()` — updates Pointer bus from new axis values.
**Incorrect:** chaining PostSets across multiple properties to propagate a SRC change — use `applySRC` structured callback instead.
