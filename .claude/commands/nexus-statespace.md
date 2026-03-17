# nexus-statespace — State-Space nexObj Design Skill

Reference for building out `nexObj_stateSpace` and its curation/animation infrastructure.
`nexObj_embedding_single` is the animation reference. `nexObj_stateSpace` is the upgrade target.

---

## Data model: STAT → STATE

```
STAT  : MATLAB table — rows = trials/groups, cols = df (cell of arrays), ax, grouping labels
          ↓  buildSTATE()
STATE : struct
  .Z   — [N × d] matrix of embedding coordinates (all samples stacked)
  .G   — table [N × nProps] — grouping labels per row (from nexOp_stackSTAT)
  .S   — [N × d] covariance/size data (optional, for ellipsoids/SEM)
  .ptr — pointer struct indexing rows of Z (see below)
```

`nexOp_stackSTAT(STAT)` stacks `STAT.df{:}` into Z, replicates grouping columns per row,
adds `sampleNumber` column to G.

### STATE.ptr — design

STATE.Z rows are indexed by a ptr struct that mirrors `DF_postOp.ptr`:

```
STATE.ptr.(axKey).dim    % which logical axis this indexes in Z rows
STATE.ptr.(axKey).value  % current row position
STATE.ptr.(axKey).range  % [start, end] — full available extent
STATE.ptr.(axKey).window % (optional) viewing window size — only applied when
                         %   this axis is BOTH (1) in domain.D1 AND (2) == domain.animate
```

The `window` field limits how many rows are rendered per frame during pan mode.
When `window` is set and active: display slice = `[value : value + window - 1]` within range.
When `window` is not set or axis is not being animated as D1: full range is shown.

`sampleNumber` from STATE.G is the natural row axis. DF.ax axes (e.g. `t`) can be included
in STATE.G at stack time so they are available as ptr keys.

STATE is built **once** (expensive), cached in `nexObj.STATE`.
Rebuild triggered only when `dfID_source` changes (new embedding/data source loaded).
All domain changes (F, D1, D2, collector.*) re-visualize only — F just selects which
columns of the already-built STATE.Z to display.

---

## Domain roles for state-space

```
domain.axes    % string array — full list of DF.ax keys (source of truth, same as monoGram)
domain.D1      % string array — DF.ax axes for primary display (pan/trace when animated)
domain.D2      % string array — DF.ax axes for stepwise sweep (snapshot slices when animated)
domain.F       % string array — factor/embedding dimensions (columns of STATE.Z)
                %   e.g. ["d1","d2","d3"] for CEBRA, ["PC1","PC2","PC3"] for PCA
                %   analogous to domain.axes but scoped to the embedding output space
domain.animate % string — which axis the player currently steps; member of D1 or D2
```

**D1 and D2 come exclusively from `DF.ax`** — temporal/spatial axes of the embedding input
(e.g. `t`, `ch`). Group labels, trial IDs, and conditions live in STAT.G and are accessed
via the View selectionBus, not through D1/D2.

**F is the factor space**: columns of STATE.Z for the active embedding. The Domain selectionBus
curates which F elements map to scatter3 X/Y/Z. Both D1 and D2 sub-buses expose all `domain.axes`
(i.e. all DF.ax fields) for independent assignment with no assumed complement relationship.

---

## Two animation modes — dispatch on domain.animate membership

### Mode A: animate ∈ D1 — pan / trajectory trace

```
domain.animate = "t"  (a D1 axis — primary display)
```

The full scatter3 cloud stays static. A **tracker** (co-registered graphic under `.graphics`)
trails through it as the window advances along the D1 axis.

- Advance `STATE.ptr.(animate).value` by stride (wraps within range)
- If `STATE.ptr.(animate).window` is set: display slice = `[value : value + window - 1]`
- Only tracker XData/YData/ZData are updated each frame (canvas is not redrawn)
- tracker renders `STATE.Z(windowSlice, F_dimIndices)` — the active viewing window

```matlab
% Pan mode update
val  = STATE.ptr.(animate).value;
win  = STATE.ptr.(animate).window;   % may be empty → use full range
if ~isempty(win)
    slice = val : val + win - 1;
else
    slice = STATE.ptr.(animate).range(1) : STATE.ptr.(animate).range(2);
end
nexObj.Figure.panel0.tiles.graphics.tracker.XData = STATE.Z(slice, f1);
nexObj.Figure.panel0.tiles.graphics.tracker.YData = STATE.Z(slice, f2);
nexObj.Figure.panel0.tiles.graphics.tracker.ZData = STATE.Z(slice, f3);
```

### Mode B: animate ∈ D2 — stepwise sweep

```
domain.animate = "trial"  (a D2 axis — secondary slicing)
```

- Advance `STATE.ptr.(animate).value` by stride (wraps within range)
- Refilter STATE.Z rows by matching `STATE.G.(animate) == ptr.value`
- Full canvas (scatter3) redrawn for the new snapshot
- tracker is not updated in this mode (or hidden)
- Analogous to monoGram's existing `stepAnimate` behavior

---

## stepAnimate override in nexObj_stateSpace

`nexObject.stepAnimate` handles D2 sweep mode naturally (ptr value stepping + visualize).
Override only to add D1 pan dispatch:

```matlab
function stepAnimate(nexObj, args)
    % CFG HEADER
    stride = args.stride; % default = 1
    axSel  = nexObj.domain.animate;
    if ismember(axSel, nexObj.domain.D1)
        % Pan/trace mode: advance value, apply window, update tracker only
        r   = nexObj.STATE.ptr.(axSel).range;
        N   = r(2) - r(1) + 1;
        nexObj.STATE.ptr.(axSel).value = r(1) + mod(nexObj.STATE.ptr.(axSel).value - r(1) + stride, N);
    else
        % Sweep mode: delegate to base (D2 value stepping via DF_postOp.ptr)
        stepAnimate@nexObject(nexObj, args);
    end
    nexObj.visualize();
end
```

---

## Canvas / tracker graphics convention

All co-registered graphics on the same axes live as named subfields of `.graphics`:

```
nexObj.Figure.panel0.tiles.graphics.canvas   % primary scatter3 — full point cloud
nexObj.Figure.panel0.tiles.graphics.tracker  % trailing window — scatter3 or line3
```

This generalizes to any nexObj that needs layered graphics: just add named subfields.
Initialization in `nexFigure_stateSpace`:

```matlab
nexObj.Figure.panel0.tiles.graphics.canvas  = scatter3(ax, [], [], [], ...);
nexObj.Figure.panel0.tiles.graphics.tracker = scatter3(ax, [], [], [], ...);  % or plot3
```

---

## SelectionBus hierarchy

Three bus groups in `nexFigure_stateSpace`, each a sub-panel:

### View bus — controls what is shown and how it is colored
| Sub-bus | Writes to | Purpose |
|---------|-----------|---------|
| AVG | `collector.AVG` | Which G column to group/average by |
| VW | `collector.VW` | Which group values to show (multi-select filter on STATE.G) |
| CLR | `collector.CLR` | Which G column drives color; resolved via nexon.console.BASE.registry LUT |

### Domain bus — controls which axes fill D1, D2, F
| Sub-bus | Writes to | Source menu | Trigger |
|---------|-----------|-------------|---------|
| F | `domain.F` | embedding output column names | → STATE rebuild |
| D1 | `domain.D1` | all `domain.axes` (DF.ax fields) | → re-visualize |
| D2 | `domain.D2` | all `domain.axes` (DF.ax fields) | → re-visualize |

D1 and D2 sub-buses each expose the full `domain.axes` list. No complement rule enforced
here — both can contain any DF.ax field. Future nexObj_selectionBus will manage this UI.

### Pointer bus — trajectory isolation (collector.Pointer)

One listbox per `DF.ax` dimension. Candidate values are the **actual axis values**
(e.g. channel names, Hz values, time indices) — human-readable, not raw indices.
`nex_returnSelectionMask(collector.Pointer)` returns `S.(axKey) = axValues(selectedIndices)`.

| Axis role | Listbox behaviour | Effect |
|-----------|-------------------|--------|
| `domain.animate` (primary, e.g. `t`) | All values selectable (multi-select) | Animation drives which values are rendered each frame; Pointer selection sets the starting window position |
| Secondary non-animated (e.g. `ch`, `f`) | Multi-select | **Each selected value yields a separate trajectory** overlaid in the scatter — e.g. select f=15 Hz and f=36 Hz to compare trajectories at both frequencies simultaneously |

`maxSels = []` for the Pointer bus: each axis gets `Max = length(axis values)`,
enabling full multi-select for all dimensions.

#### How visualize() uses the Pointer mask

```matlab
ptrSel = nex_returnSelectionMask(nexObj.collector.Pointer);
% ptrSel.(axKey) = selected value(s) on that axis
% For each non-animated axis: filter STATE.G rows where G.(axKey) ∈ ptrSel.(axKey)
% For animated axis: row range is driven by STATE.ptr.(animAxis).value + window
```

**Prerequisite**: STATE.G must include a column for each DF.ax axis so row-level
filtering is possible. These columns should be populated at `buildSTATE` time
(replicate axis values per row, matching how `nexOp_stackSTAT` replicates group labels).

#### canvas vs canvas_tracker

```
graphics.canvas                      — full point cloud scatter3; all STATE.Z rows
                                       matching the Pointer mask, across all time.
                                       Updated when Pointer / VW selections change.

graphics.canvas_tracker.(groupName)  — one scatter3 handle per VW-selected group.
                                       Each traces that group's STATE.Z rows within
                                       the current window of the primary (animated) axis.
                                       Keyed by group name so per-group color (CLR) applies.
```

**Pan and tracker are complementary, not the same thing:**

- The **pan** governs which slice of the primary dimension's window is currently shown —
  it advances `STATE.ptr.(animate).value` each timer tick.
- The **canvas_tracker** renders, *for each VW group*, the scatter points that fall
  within that window. As the window slides, each tracker redraws its group's path
  through the cloud.
- The visual result looks like a moving highlight tracing through the full cloud —
  but `canvas` (the cloud) and `canvas_tracker` (the group traces) are distinct objects.

**Lifecycle — strict two-tier separation (latency guardrail):**

`visualize()` is called at animation frame rate and must never perform structural
graphics operations. All handle create/delete work belongs in `rebuildTrackers()`.

```
rebuildTrackers()          — structural tier (slow, called only on VW change)
  • create scatter3 for new groups, delete handles for removed groups
  • called by refreshVW() and by the Refresh button
  • NEVER called from visualize() or stepAnimate()

visualize()                — data tier (fast, called every frame)
  • set(handle, 'XData', x, 'YData', y, 'ZData', z) only
  • if isfield(graphics.canvas_tracker, grp) && isvalid(handle): update
  • if handle missing or invalid: skip silently this frame — rebuildTrackers
    will fix it on the next structural update
  • no delete(), no scatter3(), no hold(), no drawnow()
```

Guard pattern inside `nexVisualization_stateSpace`:
```matlab
grp = char(groupName);
if isfield(gfx.canvas_tracker, grp) && isvalid(gfx.canvas_tracker.(grp))
    set(gfx.canvas_tracker.(grp), 'XData', x, 'YData', y, 'ZData', z);
    % also update CData if CLR changed
end
% — no else branch: missing handle is silently skipped this frame
```

`nexFigure_stateSpace` initialises `graphics.canvas_tracker = struct()` (empty).
`rebuildTrackers()` populates it; subsequent `visualize()` calls only write data.

In sweep mode (animate ∈ D2), tracker fields are cleared by `rebuildTrackers()`
when mode changes; `visualize()` only redraws `canvas` for each snapshot.

---

## LUT registry and CLR bus

LUTs live at `nexon.console.BASE.registry`. The CLR selectionBus key lists
`fieldnames(nexon.console.BASE.registry)` as candidate options.

The CLR selection has a dual role: the selected registry field name is both the
**LUT identifier** (which registry entry to use for color mapping) and the **G column key**
(which column of STATE.G to map through that LUT). This works when registry field names
match grouping label column names — which is the design intent (e.g.,
`'sessionLabel_phase'` is both the LUT name and the G table column).

```matlab
viewSel = nex_returnSelectionMask(nexObj.collector.View);
LUT = nexObj.nexon.console.BASE.registry.(char(viewSel.CLR));
C   = arrayfun(@(g) LUT.color(ismember(LUT.phase, g)), STATE.G.(char(viewSel.CLR)));
```

The dual-role convention simplifies the bus (one key selects both), but means LUT names
must be kept in sync with G column names. Document this constraint when registering new LUTs.

---

## SelectionBus full update rule

**Updating only `selKeys` is not enough.** Three fields must be kept in sync whenever
bus candidate values change (pattern from `nexOp_sBus_alignItems2ax`):

```matlab
bus.selKeys.(key)         = newValues;   % candidate list
bus.selections.(key)      = 1;           % reset index (or clamp to valid range)
if isfield(bus.listBoxes, key) && ~isempty(bus.listBoxes.(key))
    bus.listBoxes.(key).Value  = 1;
    bus.listBoxes.(key).String = newValues;
    bus.listBoxes.(key).Max    = numel(newValues);
end
```

The listbox guard is needed because a bus may be initialized before the figure is built
(construction order: bus init → figure build → listbox wired into bus.listBoxes).

### Listener-driven cascade (nexObj_categorical reference)

`nexObj_categorical` wires a `PostSet` listener on `DF_postOp.ax` to trigger
`nexOp_sBus_alignItems2ax` automatically when pooling reshapes an axis:

```matlab
nexObj.selectionBus.items.Listeners.ax = addlistener( ...
    nexObj.DF_postOp, 'ax', 'PostSet', ...
    @(~,~) nexOp_sBus_alignItems2ax(nexObj.selectionBus.items));
```

Parent/child hierarchy is also set so the cascade function can walk the bus tree:
```matlab
nexObj.selectionBus.categories.Parent   = nexObj.selectionBus.items;
nexObj.selectionBus.items.Children.sbus = nexObj.selectionBus.categories;
```

For `nexObj_stateSpace`, `refreshVW` is called explicitly (after `reportAverage`)
rather than via a listener, because VW depends on `nexObj.AVG` (not an observable
property). If `AVG` is later made observable, a listener-driven refresh is preferable.

---

## nexVisualization_stateSpace — target CFG HEADER

```matlab
% CFG HEADER
axLim     = args.axLim;     % default = 5
len_trail = args.len_trail; % default = 40
```

Domain-driven pipeline (no hardcoding):
1. Resolve F column indices into STATE.Z from `domain.F`
2. Apply `collector.VW` → row mask on STATE.G
3. Apply `collector.CLR` → map G column through registry LUT → RGB per row
4. Update canvas XData/YData/ZData/CData (full point cloud)
5. If `animate ∈ domain.D1`: update tracker from `STATE.ptr.(animate).value + window`
6. Update axis labels from active F dims, title from `domain.F` source

---

## Embedding paradigm reference

| Paradigm | STATE.Z columns | Typical F | Typical D1 (DF.ax) | Typical D2 |
|----------|----------------|-----------|---------------------|------------|
| CEBRA    | latent dims | ["d1","d2","d3"] | ["t"] | [] |
| PCA      | PC components | ["PC1","PC2","PC3"] | ["t"] | [] |
| UMAP     | UMAP dims | ["u1","u2","u3"] | ["t"] | [] |
| LGSSM    | latent state | ["x1","x2","x3"] | ["t"] | [] |
| LDA      | discriminant dims | ["LD1","LD2","LD3"] | ["t","ch"] | [] |

---

## Upgrade checklist for nexObj_stateSpace

- [ ] Design STATE.ptr init (extend nex_initAxisPointer_v2 or STATE-specific variant)
- [ ] Add `ptr.(axKey).window` field; expose in Pointer bus UI (enabled only for D1+animate)
- [ ] Add `domain.F` inference from embedding output column names in buildSTATE
- [ ] Replace hardcoded `d1/d2/d3 = 1/2/3` with domain.F index resolution
- [ ] Replace hardcoded collector.* in visualize() with selectionBus reads
- [ ] Implement nexAnimate_stateSpace stub → override stepAnimate with D1/D2 dispatch
- [ ] Add tracker graphic to nexFigure_stateSpace alongside canvas
- [ ] Build View / Domain / Pointer selectionBus panels in nexFigure_stateSpace
- [ ] Wire domain.F change → STATE rebuild; D1/D2 change → re-visualize only
- [ ] Register LUTs into nexon.console.BASE.registry; wire CLR bus to registry
