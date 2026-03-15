# nexus-statespace — State-Space nexObj Design Skill

Reference for building out `nexObj_stateSpace` and its curation/animation infrastructure.
`nexObj_embedding_single` is the animation reference. `nexObj_stateSpace` is the upgrade target.

---

## Data model: STAT → STATE (not DF_postOp)

State-space objects hold a different data model than monoGram/monoGraph:

```
STAT  : MATLAB table — rows = trials/groups, cols = df (cell of arrays), ax, grouping labels
          ↓  buildSTATE()
STATE : struct
  .Z  — [N × d] matrix of embedding coordinates (all samples stacked)
  .G  — table, [N × nProps] — grouping labels per row (from nexOp_stackSTAT)
  .S  — [N × d] covariance/size data (optional, for ellipsoids/SEM)
```

`nexOp_stackSTAT(STAT)` is the canonical stacker: concatenates `STAT.df{:}` into Z, replicates
grouping columns to match row count, adds `sampleNumber` column to G.

STATE is built **once** (expensive) and cached in `nexObj.STATE`. Visualization slices it.
Unlike DF_postOp/ptr, STATE is not pointer-indexed — slicing is done by group membership (G).

---

## Domain roles for state-space

```
domain.axes    — embedding dimension indices or labels (e.g. ["d1","d2","d3"] or ["PC1","PC2","PC3"])
domain.D1      — dimensions shown in scatter3 (typically 3 axes → X, Y, Z of scatter)
domain.D2      — secondary axes used for stepwise slicing (trial, condition, time index)
domain.F       — string array of active factor/embedding IDs (CEBRA, PCA, UMAP, LDA, ...)
                 selects which STATE matrix or STAT source to use
domain.animate — which axis is currently stepped by the player
```

**D1 vs D2 in stateSpace matters for animation mode** (see below).

Visualization extracts D1 indices into `STATE.Z` columns:
```matlab
d1 = find(domain.axes == domain.D1(1));
d2 = find(domain.axes == domain.D1(2));
d3 = find(domain.axes == domain.D1(3));   % for scatter3
```

---

## The collector struct (pre-selectionBus)

Currently hardcoded in `visualize()` — needs to become selectionBus-driven:

```matlab
nexObj.collector.AVG  % string: which G column to average/group by
nexObj.collector.VW   % string array: which group values to show (view filter)
nexObj.collector.CLR  % string: which G column drives point color via LUT
```

These map to three selectionBus sub-panels:
- **AVG bus**: group-by selector — writes to `collector.AVG`
- **VW bus**: multi-select filter — writes to `collector.VW`
- **CLR bus**: color-by selector + LUT reference — writes to `collector.CLR`

Color resolution: `G.(collector.CLR)` → LUT → RGB per row of STATE.Z.
LUT is currently `nexObj.nexon.console.BASE.map_phase` — needs to become a configurable
domain property or passed via the CLR bus.

---

## Two animation modes — dispatch on domain.animate membership

When `stepAnimate` (or a stateSpace-specific override) is called, check whether
`domain.animate` is a D1 member or a D2 member:

### Mode A: animate ∈ D2 — stepwise slice (like monoGram)

```
domain.animate = "trial"  (or "condition", "session", ...)
```

- Advance `ptr.(animate).value` by stride (wraps within `ptr.(animate).range`)
- Refilter STATE.Z/G by the current value of the animate axis
- Full scatter3 redrawn for the new slice — no tracer needed
- Equivalent to monoGram's existing `stepAnimate` via inherited `nexObject.stepAnimate`

### Mode B: animate ∈ D1 — pan/trace mode (from nexObj_embedding_single)

```
domain.animate = "d1"  (or "PC1", time within an embedding, ...)
```

- Advance `ptr.(animate).range` by stride — the window *slides*, not a single value step
- The full scatter3 stays static (all points rendered)
- A **tMarker** (separate graphic object) traces the window: renders `STATE.Z(rangeWindow, D1dims)`
- Visual result: the trajectory path "moves" through the cloud as the window pans

tMarker pattern from `nexVisualization_embedding_single`:
```matlab
% tMarker0 is a separate scatter3 or line3 on the same axes
markerSlice = ptr.(animate).range(1) : ptr.(animate).range(1) + len_trail - 1;
nexObj.Figure.panel0.tiles.graphics.tMarker0.graphic.XData = STATE.Z(markerSlice, d1);
nexObj.Figure.panel0.tiles.graphics.tMarker0.graphic.YData = STATE.Z(markerSlice, d2);
nexObj.Figure.panel0.tiles.graphics.tMarker0.graphic.ZData = STATE.Z(markerSlice, d3);
```

`len_trail` should be a CFG HEADER parameter on the visualization function.

---

## Animation dispatch — override stepAnimate in nexObj_stateSpace

`nexObject.stepAnimate` handles D2-mode out of the box (ptr value stepping).
For D1/pan mode, `nexObj_stateSpace` should override `stepAnimate`:

```matlab
function stepAnimate(nexObj, args)
    % CFG HEADER
    stride = args.stride; % default = 1
    axSel = nexObj.domain.animate;
    if ismember(axSel, nexObj.domain.D1)
        % Pan mode: slide the range window
        r   = nexObj.DF_postOp.ptr.(axSel).range;
        len = r(2) - r(1);
        N   = length(nexObj.DF_postOp.ax.(axSel));
        newStart = mod(r(1) - 1 + stride, N) + 1;
        nexObj.DF_postOp = nex_setAxisPointer_v2(nexObj.DF_postOp, axSel, newStart);
        % update range to slide with it
        nexObj.DF_postOp.ptr.(axSel).range = [newStart, min(newStart + len, N)];
    else
        % Slice mode: delegate to base class (value stepping)
        stepAnimate@nexObject(nexObj, args);
    end
    nexObj.visualize();
end
```

---

## nexFigure_stateSpace — panel layout to build

Current state: scatter3 canvas, animation cfg panel, two placeholder comment-out panels.

Target layout (right column, bottom-up):
- **panel5** — axis/ptr control (inherited `nexObj_axisPanel`)
- **panel4** — animation cfg (`aniCfg` panel)
- **panel3** — visualization cfg (`visCfg` panel)
- **panel2** — CLR selectionBus (color-by column + LUT)
- **panel1** — VW selectionBus (view filter — multi-select group values)
- **panel0** (left) — scatter3 canvas

Play button + D2 dropdown (inherited pattern from monoGram).
Add **D1 dimension dropdowns** (3× for scatter3 X/Y/Z) — write to `domain.D1`.
Add **factor dropdown** — writes to `domain.F`, triggers STATE rebuild.

---

## nexVisualization_stateSpace — target CFG HEADER

```matlab
% CFG HEADER
axLim     = args.axLim;     % default = 5
len_trail = args.len_trail; % default = 40
```

Visualization pipeline (domain-driven, no hardcoding):
1. Read `domain.D1` → resolve column indices d1, d2, d3 into `STATE.Z`
2. Apply `collector.VW` → row mask on `STATE.G`
3. Apply `collector.CLR` → map G column through LUT → RGB per row
4. Update canvas XData/YData/ZData/CData
5. If animate ∈ D1: update tMarker from `ptr.(animate).range`
6. Update axis labels from `domain.D1` names, title from `domain.F`

---

## Current gaps in nexObj_stateSpace (upgrade checklist)

- [ ] Inherit `nexObject` fully (constructor, cfg, domain, ptr) — partially done (inherits but doesn't use DF/ptr)
- [ ] Replace `visualize()` hardcoded collector values with domain/selectionBus reads
- [ ] Replace hardcoded `d1/d2/d3 = 1/2/3` with `domain.D1` index resolution
- [ ] Replace `phaseLUT` reference with configurable LUT property
- [ ] Implement `nexAnimate_stateSpace` (currently stub) using dispatch logic above
- [ ] Cache `STATE` properly — rebuild only when STAT/factor changes, not on every visualize
- [ ] Wire `buildSTATE()` to trigger on `domain.F` change (new embedding selected)
- [ ] Add tMarker graphic to `nexFigure_stateSpace` (separate scatter3 on same axes)
- [ ] Add D1 dimension dropdowns + factor dropdown to figure
- [ ] Move `collector.*` to selectionBus panels

---

## Embedding paradigm notes

| Paradigm | STATE.Z columns | Typical D1 | Typical D2 |
|----------|----------------|------------|------------|
| CEBRA    | latent dims (3–8) | ["d1","d2","d3"] | ["trial","condition"] |
| PCA      | PC components | ["PC1","PC2","PC3"] | ["session","trial"] |
| UMAP     | UMAP dims | ["u1","u2","u3"] | ["condition"] |
| LGSSM    | latent state dims | ["x1","x2","x3"] | ["t","trial"] |
| LDA      | discriminant dims | ["LD1","LD2","LD3"] | ["phase","condition"] |

`domain.F` selects which paradigm is active. `domain.axes` lists the available columns
of STATE.Z for that paradigm. D1/D2 assignment is then made by selectionBus curation
or inferDomain default.
