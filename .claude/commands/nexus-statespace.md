# nexus-statespace — State-Space nexObj Design Skill

Reference for `nexObj_stateSpace` and its full curation/animation infrastructure.

---

## DF_postOp as the coordinate system prototype

`DF_postOp` is the single source of truth for every downstream component:

| Component | How it uses DF_postOp |
|-----------|----------------------|
| **Pointer** (`windowCfgPanel`) | `DF_postOp.ptr` — axis handles captured by reference in `breakoutAxisFields`; spinners update in-place with no orphaning |
| **Domain axes** | `DF_postOp.ax` field names → D1/ANI candidates (excluding `'factor'`) |
| **Factor labels** | `DF_postOp.ax.factor` → F bus candidate values (e.g. `['pc1','pc2','pc3']`) |
| **Axis values in STATE.G** | `reportAverage` stamps `DF_postOp.ax` onto `AVG.ax`; `nexOp_stackSTAT` expands per-sample into `STATE.G` columns |
| **sampleNumber range** | `STATE.ptr.sampleNumber.range = [1, T]` where T is the DF_postOp trajectory length |

**Consequence for DF-as-VW**: raw DF rows and AVG rows both live in the DF_postOp coordinate
space — same T frames, same factor columns, same axis layout. Pointer filtering applies
identically to both.

`DF_postOp` is upgraded to `nexObj_DF` at construction (after `nex_initAxisPointer_v2`) so its
`ax` property is `SetObservable`. A `PostSet` listener on `DF_postOp.ax` fires `refreshPointer()`
automatically when pooling changes axis lengths.

---

## Data model: STAT → AVG → STATE

```
STAT  : MATLAB table — rows = trials/groups, cols = df (cell of arrays) + grouping labels
          ↓  reportAverage()   [stamps DF_postOp.ax onto every AVG row]
AVG   : table — rows = group averages; cols = df (cell) + grouping label(s) + ax (cell of struct)
          ↓  buildSTATE() → nexOp_stackSTAT(AVG)
STATE : struct
  .Z   — [N × d] matrix of embedding coordinates (all samples stacked)
  .G   — table [N × nProps] — grouping labels + sampleNumber + axis value columns (t, ch, ...)
  .S   — [N × d] covariance/size data (optional)
  .ptr — nexObj_ptr; sampleNumber axis only (range = [1, T], per-group trajectory length)
```

### How axis values reach STATE.G

`reportAverage` stamps `DF_postOp.ax` onto each AVG row:
```matlab
T_AVG.ax = repmat({nexObj.DF_postOp.ax}, height(T_AVG), 1);
```

`nexOp_stackSTAT` expands ax fields per-sample alongside `sampleNumber`:
```matlab
% Inside nexOp_stackSTAT — runs when STAT.ax column is present:
axCols = cellfun(@(ax_i, df_i) ...
    ax_i.(f)(min((1:size(df_i,1))', numel(ax_i.(f))))', ...
    STAT.ax, STAT.df, "UniformOutput", false);
```
This makes `STATE.G.t`, `STATE.G.f`, etc. naturally present — no post-hoc stamping needed.

### G_DF shape (raw DF rows)

`G_DF` mirrors the same schema: `sampleNumber` + ax field columns, no grouping columns.
Missing grouping columns (relative to `G_AVG`) are imputed with `NaN` / `''` before vertical concat.

### STATE.ptr vs DF_postOp.ptr

**`DF_postOp.ptr` is the single authoritative animation pointer for all nexObjects, including
`nexObj_stateSpace`.** `DF_postOp` is the virtual coordinate-space prototype for every
trajectory plotted — its `ptr` defines the range, value, and window that `stepAnimate` advances.

`STATE.ptr` (if present) carries metadata about the stacked STATE layout (e.g. sampleNumber
range = [1, T]) but is **not** what `stepAnimate` reads. The base `nexObject.stepAnimate`
always uses `DF_postOp.ptr.(domain.animate)` and calls `visualize()` — no override needed in
`nexObj_stateSpace`.

```
DF_postOp.ptr.sampleNumber.range  = [1, T]   % T = trajectory length
DF_postOp.ptr.sampleNumber.value  = current frame (advanced by stepAnimate)
DF_postOp.ptr.sampleNumber.window = display window (used by nexVisualization_stateSpace)
```

All groups move in lockstep. The full stack stays visible on the canvas; tracker windows
show only the current frame.

STATE is built **once** (expensive), cached in `nexObj.STATE`. Does NOT call `visualize()` —
call `applyDomainBus()` or `updateScope()` separately to trigger visualization.

---

## applyPool vs buildSTATE — what each updates

```
applyPool button → updateScope()
    → nexOp_poolAxes → DF_postOp.df / DF_postOp.ax updated
    → PostSet fires → refreshPointer() (axis values / Pointer bus remapped)
    → visualize() with CACHED STATE
        — dot sizes update (divsPerBin read live from pMap)
        — Pointer filter updates (new axis values)
        — STATE.Z positions are STALE until buildSTATE is re-run

reportAvgButton → reportAverage() → AVG.ax stamped from current DF_postOp.ax
buildSTATEButton → buildSTATE() → STATE.Z / STATE.G rebuilt from current AVG
```

STATE.Z (embedding positions) is only valid relative to the pool state at the time
`buildSTATE` was last run. Pool changes require `reportAverage` + `buildSTATE` to propagate
into embedding positions.

---

## Domain roles

```
domain.axes    % string array — DF_postOp.ax field names (excluding 'factor')
domain.D1      % primary axes (pan/trace when animated)
domain.D2      % secondary axes (sweep mode)
domain.F       % factor labels from DF_postOp.ax.factor (columns of STATE.Z)
domain.animate % which axis the player steps
```

`'factor'` is a reserved ax keyword for DR outputs (PCA, SSM, CEBRA). It is excluded from
D1/ANI/Pointer and handled exclusively by the F sub-bus.

### applyDomainBus ordering rule

F must be applied **after** `inferDomain()` because the base-class `inferDomain()` resets
`domain.F = string(dfID_source)`. Order in `applyDomainBus`:
1. D1 → `inferDomain()`
2. ANI → `setAnimateAxis()` (internally calls `inferDomain()` again)
3. F **last** — reads from `collector.Domain` selectionBus, not `domain.F`

`nexVisualization_stateSpace` reads F **directly from `collector.Domain`** via
`nex_returnSelectionMask`, bypassing `domain.F` entirely.

---

## Collector buses

### View bus (`collector.View`)
| Key | Candidate values | Purpose |
|-----|-----------------|---------|
| AVG | non-DF STAT columns | which G column to group/average by |
| VW  | unique values from `nexObj.AVG` group column | which groups to show; defaults to **all selected** on `refreshVW()` |
| CLR | same as AVG pool | which G column to color by; resolved via `registry.LUT.(clrCol)` |

`refreshVW()` always selects all groups (`1:nVW`). User can deselect manually after.

### Domain bus (`collector.Domain`)
| Key | Candidate values | Max selections |
|-----|-----------------|---------------|
| F   | `DF_postOp.ax.factor` values | 3 (scatter3 X/Y/Z cap) |
| D1  | `domain.axes` (DF_postOp.ax fields, no 'factor') | 1 |
| ANI | same as D1 | 1 |

`refreshDomainF()` does full three-field update of F sub-bus after `buildSTATE`.
Listbox changes update `bus.selections` via `listCfgEntryChanged`; `applyDomainBus()` reads
them on Refresh — no direct domain callback needed.

### Pointer bus (`collector.Pointer`)
One listbox per `DF_postOp.ax` dimension (excluding 'factor'). Candidate values =
actual axis values from `DF_postOp.ax.(f)` (human-readable). `maxSels = []` → full multi-select.

Listener: `addlistener(DF_postOp, 'ax', 'PostSet', @(~,~) nexObj.refreshPointer())`

**`refreshPointer()` selection preservation rules:**
- Axis unchanged (`isequal(newVals, oldVals)`) → skip entirely, user selection preserved
- Axis changed (pooling) → map selection by **value range**, not index:
  ```matlab
  selRange = oldVals(validSel);
  newSel = find(newVals >= min(selRange) & newVals <= max(selRange));
  if isempty(newSel), newSel = 1:nVals; end  % fallback to all
  ```
  This preserves the user's intended time/frequency window across pool changes.

**Floating-point membership**: axis values in `STATE.G.(f)` and `sel` from the Pointer bus
can differ by ~1e-6 due to float accumulation. Use `round(..., 6, 'significant')` on both
sides before `ismember` — 6 significant figures eliminates noise while generalizing across
all axis types (time in s, frequency in Hz, integer channel indices):
```matlab
gVals   = round(double(STATE.G.(f)), 6, 'significant');
selVals = round(double(sel),         6, 'significant');
mask_ptr = mask_ptr & ismember(gVals, selVals);
```

Pointer mask in `nexVisualization_stateSpace`:
```matlab
ptrSel = nex_returnSelectionMask(nexObj.collector.Pointer);
for k = 1:numel(ptrAxes)
    f = ptrAxes{k};  sel = ptrSel.(f);
    if ~isempty(sel) && ~isequal(sel,"") && ismember(f, gCols)
        mask_ptr = mask_ptr & ismember(STATE.G.(f), sel);
    end
end
mask_canvas = mask_VW & mask_ptr;
```

---

## Canvas / tracker graphics convention

```
graphics.canvas                      — full VW+Pointer filtered point cloud (all time)
graphics.canvas_tracker.(groupFld)   — one scatter3 per VW group, trajectory within window
```

Field names in `canvas_tracker` are group labels with hyphens replaced by underscores
(e.g. `"L-hind-paw-CCI"` → `"L_hind_paw_CCI"`). `rebuildTrackers()` uses
`strrep(activeGrps, '-', '_')` consistently for both create and remove.

**Strict two-tier separation:**

```
rebuildTrackers()   — structural tier (slow): create/delete scatter3 handles per VW change
                      called by refreshVW() and after Refresh; NEVER from visualize()
visualize()         — data tier (fast): set() on existing handles only; no hold/drawnow
```

**Tracker scrubbing** — after the per-group tracker loop, clear stale data from any handles
whose group is no longer in `vwGroups` (e.g. user deselected a group from VW):
```matlab
allFlds = fieldnames(gfx.canvas_tracker);
for i = 1:numel(allFlds)
    fld = allFlds{i};
    if ~ismember(fld, activeFlds) && isvalid(gfx.canvas_tracker.(fld))
        set(gfx.canvas_tracker.(fld), 'XData', [], 'YData', [], 'ZData', []);
    end
end
```
`activeFlds` is `strrep(vwGroups, '-', '_')` — the currently selected group fields.

**Scatter sizes** — set via `SizeData` in every `visualize()` call (not baked at creation):
```
canvas:  baseSize  = 100 × divsPerBin(animAx)
tracker: baseSize  = 150 × divsPerBin(animAx)
```
`divsPerBin` is read live from `nexObj.pMap.(animAx).divsPerBin` so it updates on applyPool
without rebuilding STATE.

**D1 context window** — canvas is restricted to a ±half window centered on the current D1
pointer value, where `half = DF_postOp.ptr.(d1Ax).window / 2`:
```matlab
d1Start = curD1 - half;   d1End = curD1 + half;   % clamped to axis range
mask_canvas = mask_canvas & d1Vals_G >= d1Start & d1Vals_G <= d1End;
```
This is applied before the brightness gradient so brightness normalizes to the visible window.

**Tracker after-image** — each tracker shows `len_afterImage` steps trailing behind the
current ANI pointer value (read from `DF_postOp.ptr.(aniAx).value`):
```matlab
winStart_ani = curANI - len_afterImage;
winEnd_ani   = curANI;
mask_grp = group_mask & aniVals >= winStart_ani & aniVals <= winEnd_ani;
```
`len_afterImage` comes from `nexObj.cfg.aniCfg.entryParams.len_afterImage` (default 5).
This unified approach works for any D1/ANI combination — the tracker always trails along
the ANI axis regardless of what D1 is, giving a highlighted "trial" slice of the manifold.

---

## D1 brightness gradient

After CLR color is resolved, brightness is modulated along the **D1 axis**:
```matlab
d1Vals  = double(STATE.G.(d1Ax));
d1Min   = min(d1Vals(mask_canvas));   % normalize to VISIBLE sub-selection, not full range
d1Max   = max(d1Vals(mask_canvas));
brightness = 0.15 + 0.85 * (d1Vals - d1Min) / (d1Max - d1Min);
brightness = max(0.15, min(1.0, brightness));  % clamp out-of-selection rows
C_all = C_all .* brightness;   % N×3 .* N×1 broadcast — hue preserved, luminance scaled
```
Normalizing to `mask_canvas` (not full trajectory) ensures the full dark→bright range is
always used regardless of which sub-range the Pointer selects.

---

## LUT registry

```
nexon.console.BASE.registry.LUT.(sessionLabel_phase)  % table: {label, color (hex RRGGBB)}
nexon.console.BASE.registry.LUT.(sessionLabel_subj)   % same format
```

Built in `nexInit_registry` `%% LUT` block. `sessionLabel_phase` reuses colors from
`nexPanel_BASE.map_phase` (already generated) so both stay in sync — no second random call.
Other sessionLabel categories get new color tables via `nexGenerate_phaseMap`.

Future LUT sources (e.g. `ax_f`, `ax_chans`) use the same `registry.LUT.(key)` path with
`{label, color}` columns. Key naming convention: always include the source prefix
(`sessionLabel_`, `ax_`, etc.) to avoid namespace collisions.

CLR bus key = registry LUT key = G column name — the triple identity is the design intent.

Color resolution in `nexVisualization_stateSpace`:
```matlab
lut = nexObj.nexon.console.BASE.registry.LUT.(clrCol);
% lut.label → group value strings, lut.color → hex strings 'RRGGBB'
hex = char(lut.color(k));
rgb = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255;
```
Falls back to `lines()` auto-assign if LUT not found.

---

## nexVisualization_stateSpace pipeline

1. **Guard**: return if `STATE` empty or `STATE.Z` empty
2. **Factor columns**: read F from `collector.Domain` (not `domain.F`); map to column indices via `DF_postOp.ax.factor`; pad to 3 with zeros if only 2 selected
3. **View selections**: `nex_returnSelectionMask(collector.View)` → groupCol, vwGroups, clrCol
4. **VW mask**: `ismember(STATE.G.(groupCol), viewSel.VW)`
5. **Pointer mask**: per-axis `ismember(STATE.G.(f), ptrSel.(f))` for each non-empty selection
6. **`mask_canvas = mask_VW & mask_ptr`**
7. **D1 context window**: refine `mask_canvas` to ±half window around `DF_postOp.ptr.(d1Ax).value`
8. **ANI pointer**: read `curANI` from `DF_postOp.ptr.(aniAx).value`; `winStart_ani = curANI - len_afterImage`
9. **Color**: registry LUT lookup on `STATE.G.(clrCol)`; fallback `lines()`
10. **D1 brightness**: normalize `STATE.G.(d1Ax)` within `mask_canvas` rows → scale `C_all`
11. **Scatter size**: `100 × divsPerBin` canvas, `150 × divsPerBin` tracker (read live from pMap)
12. **Canvas**: `set(gfx.canvas, XData/YData/ZData/CData/SizeData)` on `mask_canvas` rows
13. **Axis labels**: from Domain F selected names
14. **ANI title**: `nexTract_axisTitle(nexObj, nexObj.DF_postOp, string(animAx))` → set on `ax.Title` in cyberGreen — shows current animation frame value (tracker position), not D1 context center
15. **Tracker**: if `vwGroups == ""` return early; else per-group `mask_grp = group & ANI in [winStart_ani, curANI]`; `set()` on `canvas_tracker.(fld)` including `SizeData`

---

## nexTract_axisTitle — stale domain.D1 pitfall

Always pass `string(d1Ax)` (resolved from `domSel.D1` via `nex_returnSelectionMask`) as the
`dimList` argument — **never** `nexObj.domain.D1`, which may be stale or set to `"factor"`
by a prior `inferDomain()` reset:

```matlab
% WRONG — domain.D1 may be stale/"factor"
axTitle = nexTract_axisTitle(nexObj, nexObj.DF_postOp, nexObj.domain.D1);

% CORRECT — d1Ax comes from live selectionBus read at top of visualize()
axTitle = nexTract_axisTitle(nexObj, nexObj.DF_postOp, string(d1Ax));
```

## nexTract_axisTitle

`nexTract_axisTitle(nexObj, DF, dimList)` — builds a title string from the current ptr values
of the specified axes. `dimList` defaults to `domain.D2` when omitted (backward-compatible).
Pass `domain.D1` from stateSpace to show the current primary dimension slice:

```matlab
axTitle = nexTract_axisTitle(nexObj, nexObj.DF_postOp, nexObj.domain.D1);
ax.Title.String = char(axTitle);
ax.Title.Color  = nexObj.nexon.settings.Colors.cyberGreen;
```

`DF.ptr.(d).value` indexes into `DF.ax.(d)` (or `DF.labels.(d)`) to get the current value.

---

## STAT construction from categorical Parent

When `nexObj_stateSpace` has a categorical (`ctg`) Parent, `nexOp_compileSTAT` is called at
construction to inherit the Parent's compiled STAT. **Pass `nexObj` (the stateSpace object
itself) as the first argument — not `nexObj.Parent`:**

```matlab
nexObj.STAT = nexOp_compileSTAT(nexObj, nexObj.dfID_source, S_categories, S_items, []);
```

`nexObj.Parent` is the ctg object; `nexOp_compileSTAT` needs the nexObject that owns the data
context (DTS, router, etc.), which is `nexObj` itself.

---

## isfield vs isprop rule

`DF_postOp` is a `nexObj_DF` handle object — use `isprop`, not `isfield`:
```matlab
isprop(nexObj.DF_postOp, 'ptr')   % correct
isprop(nexObj.DF_postOp, 'ax')    % correct
isfield(nexObj.DF_postOp.ax, 'factor')  % correct — ax itself is a struct
```

---

## Headline

`nexObj_stateSpace` accepts an optional `headline` arg (last positional):

```matlab
nexObj = nexObj_stateSpace(nexon, Parent, Partner, dfID_source, headline)
```

Stored on `nexObject.headline`; `applyHeadline()` sets `Figure.fh.Name` at the end of
`nexFigure_stateSpace`. Pass `[]` or omit to leave the title bar at the MATLAB default.
All nexObj subclasses follow the same pattern — `headline` is always the final arg.

---

## Animation config

`aniCfg` is generated from the base `nexObject.stepAnimate` — no subclass animate function:
```matlab
nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexObject.stepAnimate"));
```
CFG Header params: `stride` (default 1), `len_afterImage` (default 10).

### stepAnimate — Pointer-aware sequencing

`stepAnimate` uses `collector.Pointer.selections.(animAx)` as the animation sequence when
present, falling back to `DF_postOp.ptr.(animAx).range` otherwise:

```matlab
curPos = find(sel == curVal, 1);
if isempty(curPos), curPos = 1 - stride; end   % snap to sel(1) on first step
axVal  = sel(mod(curPos - 1 + stride, numel(sel)) + 1);
```

Key properties:
- Steps through `sel` as an **ordered sequence** — handles discontinuous/fragmented selections
- If `curVal` is not in `sel` (e.g. initial `ptr.value = 1` outside the selected range),
  `curPos = 1 - stride` ensures the first step lands on `sel(1)`
- Wraps around at the end of `sel`
- Falls back to `ptr.range` modular arithmetic when no Pointer bus or empty selection

`DF_postOp.ptr.(animAx).value` is updated directly (not via `nex_setAxisPointer_v2` which
uses `isfield` and would wipe `range`/`window`/`dim` on handle objects).

---

## Key method call chain

```
buildSTATEButton  → buildSTATE()          [expensive; does NOT call visualize()]
reportAvgButton   → reportAverage()        → AVG.ax stamped → refreshVW() → rebuildTrackers()
Refresh button    → applyDomainBus()       → updateScope() → visualize()
applyPool button  → updateScope()          → DF_postOp updated → refreshPointer() → visualize()
                                             [STATE.Z stale; dot sizes / Pointer update live]
Play button       → startPlayer()          → timer → stepAnimate() → visualize()
poolCfgEntry      → poolCfgEntryChanged()  → pMap.divsPerBin updated (no auto-visualize)
```
