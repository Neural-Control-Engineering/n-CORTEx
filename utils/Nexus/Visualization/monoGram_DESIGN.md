# monoGram — design attunements for significance-grid rendering

`nexObj_monoGram` ("2-D surf visualization") was extended this session to
double as the heatmap renderer for `mdlObj_lme`'s p-value grids
(`chainFit*` RESULTS), on top of its original role rendering raw PSD-style
`chans`/`f`/`t` surfaces. Everything below was found and fixed against real
data; kept here so the reasoning doesn't have to be re-derived if a related
bug shows up later. Files involved: `nexObj/nexObj_monoGram.m`,
`nexFigure/nexFigure_monoGram.m`, `Visualization/nexVisualization_monoGram.m`,
`Visualization/nexVis_sequentialColormap.m`,
`Visualization/nexVis_legacyCyberGreenColormap.m`, and the shared base class
`nexObj/nexObject.m` (`remodelDomain`, `onVWChanged`,
`refreshPointerForSRC`).

---

## 1. `sigThreshold` — how monoGram knows a RESULTS table holds p-values

A RESULTS table (e.g. `mdlObj_lme.RESULTS.chainFit4`) carries an optional
`sigThreshold` column (one value per row/stratum). Its **presence** is the
gate for every p-value-specific behavior below (`hasSigThreshold` in
`nexVisualization_monoGram.m`); its **value** is the live threshold used for
the significance test. This was deliberately NOT a hardcoded "is this an
mdlObj_lme" check — `.df` is reused by every mdlObj subclass for different
things (p-values here, accuracy/weights elsewhere), so the real question is
"does this DF's values mean p-values," which is a property of the data, not
the producing class. `mdlObj_lme.fitAndReport` is the first (and so far
only) producer of this column.

The threshold is user-editable live, per stratum: a spinner in the Vis panel
(manually added in `nexFigure_monoGram.m`, continuing
`breakoutCfgFields_v4`'s own layout step convention rather than using the
auto-generated cfg-panel mechanism, since its backing store is a RESULTS
column, not `cfg.visCfg.entryParams`) reads/writes
`RESULT.sigThreshold(r)` directly via `nexObj_monoGram.onSigThresholdChanged`,
and `nexVisualization_monoGram.m` pushes the spinner's `Visible`/`Value` to
match whichever row is currently on screen, every render.

`resolveActiveResultRow()` (on `nexObj_monoGram`) is the single place that
resolves which RESULTS row is active (`useResults`, `RESULT`, `r`,
`DF_src`) — factored out of what used to be inlined logic in
`nexVisualization_monoGram.m` specifically so the sigThreshold spinner's
write-back callback can never resolve a *different* row than the one being
rendered.

---

## 2. Pointer bus going stale on a VW switch (not just SRC)

**Symptom**: Pointer listbox selections (which region/time-window/etc. is
pinned) would silently reset or desync whenever VW (which stratum/RESULTS
row is displayed) changed — but *not* on a SRC change, where things worked.

**Root cause**: `remodelDomain` (the method that rebuilds
`collector.Pointer.selKeys`/`selections` to match whichever row's axis
shape is now active) was only ever called from `applySRC`. VW's listbox had
no custom callback, so it fell through to the generic
`listCfgEntryChanged`, which re-renders via `visualize()` but never
re-syncs Pointer. Two different strata can have genuinely different axis
composition (e.g. region coverage varies by subject/stratum), so an index
that meant one region under the old row could mean a *different* region
under the new one.

**Fix**: extracted `remodelDomain`'s call site out of `applySRC` into a
reusable `refreshPointerForSRC(realKey)`, and added `onVWChanged` (mirrors
`onSRCChanged`'s shape) wired to VW's listbox in `nexFigure_monoGram.m`,
calling `refreshPointerForSRC` too.

**A second, subtler layer of the same bug**: even after the above fix,
`remodelDomain` unconditionally rebuilt every axis's selection on every
call, with no check for whether that axis's values had even changed —
unlike `refreshPointerAxes_`/`nexObj_bar`'s own `applySRC`, which skip an
axis entirely when `isequal(newVals, oldVals)`. Fixed by adding the same
skip-if-unchanged guard to `remodelDomain`.

**A third layer, purely cosmetic but confusing**: `remodelDomain`'s
fallback for an axis it *couldn't* preserve was always "select item 1"
(deliberately, not "select all" — a residual/pinned axis must collapse to
exactly one value for the canvas to render at all, see
`nexOp_sliceAndCollapse`'s own rule). But `nexOp_sliceAndCollapse` already
*ignores* a single-item Pointer selection on whichever axis is currently a
**display** axis (D1) — a lone index there just falls through to full
range. So a display axis's listbox showing "item 1 only" highlighted had
zero rendering effect, but looked exactly like a reset. Fixed by having
`remodelDomain` resolve the current `Domain.D1` names and default a
display axis's fallback to "select all" instead — residual axes keep the
single-item default unchanged.

---

## 3. Two colormaps, gated on `hasSigThreshold`

- `nexVis_sequentialColormap.m` — linear black → cyberGreen → white
  (same formula `plot_bandHierarchyGrid.m`'s own local `sequentialColormap`
  uses, duplicated rather than refactored out of that proven/untouched
  file). Used for p-value grids.
- `nexVis_legacyCyberGreenColormap.m` — the original
  `cmap-cyberGreen.mat` table (desaturated through its midpoint — the
  "washed out" look). Used for everything else (raw PSD, accuracy/weights
  facets, ...).

Set at figure-construction time as a safe default (legacy), then
re-evaluated and reapplied **every render** in `nexVisualization_monoGram.m`
based on `hasSigThreshold` for whichever row is currently active. Applied
to the **axes** (`colormap(ax, ...)`), not the figure
(`colormap(nexObj.Figure.fh, ...)`) — `nexObj.Figure.fh` is a `uifigure`,
and figure-level `colormap()` does not reliably propagate to a uifigure's
child axes the way it does for a classic `figure()` (confirmed directly:
setting it at the figure level alone left the canvas visually unchanged).

---

## 4. Region depth-ordering — cosmetic, gated on axis name only

`chans`/`dropout`/`map`-type axes are reordered deep → shallow via
`nexOp_regionDepthOrder`, same convention `plot_bandHierarchyGrid.m`'s own
`orderLevels` uses — purely a display convenience so monoGram's region
order matches the reference heatmaps for easy side-by-side comparison.
Confirmed directly (region-by-region value diff) that the underlying data
was already correct before this; this only changes which row position a
given region's data is drawn at.

**Deliberately gated on axis NAME, not on `sigThreshold`/mdlObj_lme** — it
applies equally to a raw PSD view over chans/f/t with no significance facet
involved at all. Implemented as a local helper,
`nexVis_regionDepthSortIdx`, returning a permutation applied to **both**
the tick labels and the matching dimension of `Z` together (never one
without the other — see the `t`-axis fix below for why that distinction
matters).

---

## 5. `t`-axis lexicographic-string sort (same bug class as #4, different axis)

`buildLongSTAT.m` stores `t` as a string-wrapped categorical (needed for
grid-cell matching). `categorical()`'s own default category order for
strings is lexicographic ("-1.033" sorts before "-2.033"), not numeric —
same bug `plot_bandHierarchyGrid.m`'s `orderLevels` already patches for its
own display. `nexVis_axisToNumeric` now detects when a non-numeric axis's
labels all parse cleanly as numbers and sorts them numerically instead,
returning the sort permutation (3rd output, `sortIdx`) so the caller can
permute the matching dimension of `Z` in lockstep — **labels and data must
move together**, or you reproduce the exact kind of silent label/data
misalignment this session spent a long time hunting down in
`buildLongSTAT.m` itself (a real, separate bug, fixed earlier — see git
history / WIP.md for the `gridCols`/`G.f` name-collision root cause).

---

## 5b. CLR (color-by-axis) coloring didn't keep up with #4/#5's reordering

**Symptom**: selecting `CLR = ax--chans` made the per-region coloring look
misaligned with the actual region labels — after #4 (depth-ordering) and
#5 (`t` numeric-sort) were added.

**Root cause**: the CLR section resolves `rowAnchor`/`colAnchor` (one RGB
anchor color per row/column) from `ax_slice.(rowKey)(:)`/
`ax_slice.(colKey)(:)` directly — `nexOp_sliceAndCollapse`'s own output,
still in its **original**, un-reordered axis order. But by the time this
section runs, `Y`/`X`/`Z` (and `yTickLabels`/`xTickLabels`) may have
already been permuted by #4 or #5. `anchorGrid(ri,ci,:) = ... rowAnchor(ri,:)
...` indexes by the **final** row/column position, so a color resolved in
the old order ends up attached to the wrong region once reordering is in
play — the same species of label/data misalignment bug this session kept
running into elsewhere (`buildLongSTAT.m`'s `gridCols`/`G.f` collision,
the `t`-axis lexicographic sort itself).

**Fix**: resolve anchor colors from `yTickLabels`/`xTickLabels` instead of
`ax_slice.(rowKey)`/`.(colKey)` whenever they're non-empty (i.e. whenever
the axis is non-numeric and could have been reordered) — those are
already in the same final order as `Y`/`X`/`Z` by construction. Falls back
to `ax_slice` directly only for a genuinely numeric axis, where
`yTickLabels` stays empty because neither #4 nor #5 ever reorders it.

**Lesson for next time a reordering is added here**: any axis-labeled data
read elsewhere in this function (CLR anchors, tick labels, titles, future
features) must key off `yTickLabels`/`xTickLabels` — or carry the same
permutation forward explicitly — never off `ax_slice` directly, once an
axis can be reordered after `nexOp_sliceAndCollapse` returns it.

---

## 5c. CLR anchor-gradient direction: dark→anchor, not light→anchor

`nex_hueGradientCData.m` (shared utility, currently monoGram's only
caller) originally graded each row/column/cell from a near-white tint of
the anchor hue (low value) up to the anchor's own color (high value).
Changed to grade from a dark/deep shade of the anchor hue (low value,
brightness pushed low via HSV, same hue/saturation kept) up to the
anchor's own true color (high value) — low reads as dark/muted, high
reads as the region's own vivid color, rather than low reading as
washed-out/white. The helper that builds the low-end color was renamed
`tintTowardWhite` → `shadeTowardDark` accordingly (pushes HSV value down,
not saturation down).

---

## 6. `surf()`'s shared-corner face-dropping, and why NaN can delete a VALID neighbor's cell

**The mental model**: `surf()` doesn't draw independent tiles like
`imagesc()`. Each visible square ("face") is stretched between **four
corner vertices shared with its row/column neighbors** (via
`nexVis_padForSurfEdges`'s edge-grid construction). If *any one* of those
four corners has a `NaN` height, `surf()` drops the **entire face** — not
just that one corner.

**Symptom found directly**: depth-ordering (#4) placed `nst` (an
all-`NaN`, sparse-coverage region) immediately adjacent to `STN` (a region
with perfectly valid data) in the reordered grid. `STN`'s own cells
vanished entirely as a result, even though its own values were never
`NaN` — confirmed via a print-debug showing every drawn star sat on a
real, correct sub-threshold value, which only made sense once the
shared-corner mechanic was understood. Several other regions adjacent to
a sparse region in the depth-ordered list are affected the same way — not
isolated to STN.

**Fix**: capture a `nanMaskOrig` mask once, **immediately after `Zraw = Z`
is captured, before either scale-transform branch runs** (see #7 for why
the timing here is itself a trap), then replace those cells in the
*display* copy of `Z` with `cLim_low` before `surf()` ever sees them —
`Zraw` (used for the significance test) is never touched, so stars still
correctly skip true no-data cells.

**A second-order problem this created**: "set to `cLim_low`" only reads as
black for as long as `cLim_low` genuinely stays the bottom of whatever
color range is active. It silently breaks the moment `cLim` gets rescaled
independently afterward (e.g. switching to `scale='log'`, which puts the
real data on a totally different numeric range). Fixed by **forcing these
cells to literal black directly in the rendered color**, independent of
`cLim`/colormap: whenever `any(nanMaskOrig(:))`, `Z` gets converted to a
truecolor (RGB) `CData` — real cells mapped through the *current* colormap
by hand (`surf` can't mix a scalar+colormap cell with a literal-color cell
in the same `CData`), then the masked positions overwritten to `[0,0,0]`
on top of that.

**A third-order problem**: `homeLimits()` ("Home" button) reads
`canvas.ZData` directly to auto-scale `zLim`/`cLim` — which, after the
patch above, includes the `cLim_low` placeholder values as if they were
real data, dragging the auto-scaled range toward whatever `cLim_low`
happened to be at patch time. Fixed by stashing `nanMaskOrig` (padded to
match `ZData`'s own shape) on `canvas.UserData` every render;
`homeLimits()` reads it back and excludes those positions from its own
min/max.

---

## 7. `-log10(p)` display transform, gated on `hasSigThreshold && scale=='log'`

When viewing a p-value grid with the existing Vis-panel `scale` control
set to `'log'`, `nexVisualization_monoGram.m` computes `-log10(max(Z,
eps))` directly instead of routing through `nexOp_applyComplexTransform`'s
generic log behavior (meant for complex-valued signals, e.g. PSD
magnitude — meaningless for real-valued p-values, and backwards in
direction: plain `log10(p)` gets *more negative* as `p` shrinks, the
opposite of "smaller p is brighter"). `component` is skipped entirely in
this branch for the same real-valued-data reason. `Zraw` (captured before
either transform branch) still drives the significance test in raw
p-value space, never `-log10(p)` space.

**A genuine MATLAB trap found here**: `max(Z, eps)` is the **two-argument,
element-wise** form of `max`, whose documented behavior is to return the
**non-`NaN` operand** when one side is `NaN` — i.e. `max(NaN, eps) ==
eps`, not `NaN`. Every originally-missing cell was silently laundered into
`eps` before `-log10` ever ran, becoming `-log10(eps) ≈ 15.65` — a huge,
spuriously "very significant" value, with literally no `NaN` left to find
afterward. This is exactly why `nanMaskOrig` (#6) must be captured
**before** this transform, not after — capturing it after found zero
`NaN` cells in log mode specifically, silently disabling both the
black-forcing and Home-exclusion fixes for that one mode only. The
`-log10` branch now explicitly re-applies `NaN` to `nanMaskOrig`'s
positions afterward, undoing the laundering, so `Z` itself stays
semantically correct too.

---

## 8. Star color flips with the same log/linear gate

Linear mode: the raw p-value is small-is-significant, and `cLim` is
threshold-anchored so a more-significant cell sits closer to `cLim_low` —
the **dark** end of either colormap. A white star reads clearly there.

Log mode (`-log10(p)`, #7): the transform inverts this — a
more-significant cell now has a *larger* value, pushing it toward
`cLim_high` — the **bright/white** end. A white star on a white cell is
invisible. Star color is now picked with the same `scale=='log'` check
used to gate the transform itself: black stars in log mode, white stars
in linear mode.

---

## Quick reference — what's gated on what

| Behavior | Gated on |
|---|---|
| Sequential vs legacy colormap | `hasSigThreshold` |
| `-log10(p)` transform override | `hasSigThreshold && scale=='log'` |
| Star color (white/black) | `scale=='log'` (only reached when `hasSigThreshold`) |
| Significance stars drawn at all | `hasSigThreshold` |
| sigThreshold spinner visible | `hasSigThreshold` |
| Region depth-ordering | axis name (`chans`/`dropout`/`map`) — **never** `hasSigThreshold` |
| `t`-axis numeric sort | axis labels all parse as numbers — **never** `hasSigThreshold` |
| NaN → black face-drop fix, Home exclusion | any `NaN` present — **never** `hasSigThreshold` |
| Pointer bus resync on VW/SRC change | always (base `nexObject` behavior, not monoGram-specific) |
