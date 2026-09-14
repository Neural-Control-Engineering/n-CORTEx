# Co-Registered Axes — Architecture Notes

## Status (as-built)

| Item | State |
|---|---|
| `DF.coIdx` written by `dtsIO_composeDF` | ✅ done |
| `nexOp_coAlign` (mask propagation) | ✅ done — lives in `nexOp_coIndexPairs.m`, but the function inside is named `nex_coIndexPairs`, not `nexOp_coIndexPairs`. Works (MATLAB falls back to filename dispatch) but throws a name-mismatch warning; rename when convenient. |
| Call sites: `poolAxes`, poolMap Tier-1 lazy path, `applyPointer`/`applyPointerDF` | ✅ done |
| `nexOp_alignCoAxes` (STAT-level canonical REG alignment) | ✅ done, called from `nexOp_compileSTAT` — **on raw TF, before pooling** (see below) |
| Align-before-pool ordering in `nexOp_compileSTAT` | ✅ fixed — `nexOp_alignCoAxes` now runs on raw `TF` before `nexOp_poolAxes`, not after. Was backwards: positional (axID) pooling computes bins from each trial's own raw axis extent (session-relative), so aligning afterward meant canonicalizing already-scrambled labels instead of true cross-session identity. NaN-fill (see below) + `pm.pool()`'s existing `'omitnan'` means padding never biases the pooled mean. |
| `REG` on Domain bus + mdlObj figure selector (`refreshREG`) | ✅ done (`nexFigure_lda`, `nexFigure_ssm`) |
| `CTG` / `SWP` buses (`collector.View`) | ✅ done via `initViewBus`/`applyViewBus` |
| CTG × SWP sweep producing a stacked STAT-shaped RESULT table | ✅ done in `nexAnalysis_cvPermute.m` — **shape differs from the original design below, see "Output STAT Shape (as-built)"** |
| NaN-fill (not 0-fill) for structural absence in `nexOp_alignCoAxes` | ✅ done — disambiguates "no data here" from "real zero measurement" so pooling's `omitnan` averaging isn't biased. Resolved to 0 only as a terminal step immediately before a design matrix is built (`zeroFillRemainingNaN` in `nexAnalysis_cvPermute.m`), since no fit function handles NaN input. |
| Per-SWP-value canonical cropping + `fitSentinel` | ✅ done, but not the form originally sketched below — see "SWP clamping Mechanics" and "fitSentinel" sections |
| Inference-time projection (`transform(DF_X)` onto fit-time canonical set) | ✅ done, via a SEPARATE model-level `mdlObj.fitSentinel` (base `mdlObject` property; distinct from the per-CTG×SWP-row `RESULT.fitSentinel` above — see "fitSentinel — as-built"). `nexOp_alignCoAxes` gained an optional `canonRegOverride` input (+ `canonReg`/`ftrAxis` outputs) so a single new DF can be projected onto a previously-established canonical set instead of deriving a fresh union. `nexOp_compileSTAT` caches the result on `mdlObj.fitSentinel`; `scaleApply_transform` (base `mdlObject.m`) applies it to each raw per-trial DF before calling `transform()`. First consumer: `mdlObj_pca`, whose older `nexOp_unitsToChannels` channel-sum mechanism was retired in favor of this (it was silently overriding/ignoring REG canonicalization on both the fit and transform paths — see git history for the removed `mapSTAT_unitsToChannels`/`mapUnitsToChannels_DF`/`resolveCanonicalChans`). Persisted through `mdlObj_pca.saveFit`/`loadFit`'s existing `pca_state.mat` sidecar; NOT yet wired into the generic `mdlObject.saveState()`/`mdlObj_fromState` dehydrate/rehydrate path used by other subclasses. |
| SWP clamp/restore via Pointer bus, `nexAnalysis_sweepFit` | ❌ not built — superseded by the simpler direct-slice approach already in `nexAnalysis_cvPermute.m` |
| Canonicalization timing (once globally vs. once per CTG×SWP iteration) | ✅ resolved: **global-once**, inside `nexOp_compileSTAT`, not re-scoped per CTG combo. The "wasted padding width" concern that motivated per-combo scoping is instead handled downstream by the per-SWP-value crop (`cropCanonicalREG`) — cheaper than re-deriving alignment per combo, and sufficient because pooling of real duplicates is already trial-local, so global alignment loses no information, only wastes width until cropped. |
| `nexOp_reportSTAT.m` canonicalization (session-averaging path) | ❌ **not started — flagged follow-up.** `nexOp_reportSTAT` (the `nexObject`/`reportAverage` comparison pipeline) does NOT call `nexOp_compileSTAT` — it's a separate path (`nexOp_compileTF` → `applyPointerTF` → `nexOp_permuteApply`) with no `nexOp_alignCoAxes` or `nexOp_poolAxes` call in it at all today. The `compileSTAT` align-before-pool fix does **not** reach this path. If session-averaging should also canonicalize before averaging across sessions, `nexOp_alignCoAxes` needs to be wired into `nexOp_reportSTAT.m` separately. |
| `nexOp_stackSTAT` generalized to arbitrary extra dims + role-derived (not name-derived) F-axis exclusion from `G_stack` | ✅ done |
| `domain.D1` → `domain.DN` (multi-select training-domain axis) | ✅ done, `mdlObject` family only — `nexObject` family kept `domain.D1` unchanged (different semantics, not touched) |

Sections below are the original design writeup. Where the as-built code diverged,
that's called out inline rather than silently rewritten.

## Problem

`ax.chans` and `ax.units` are co-indexed flat vectors of the same length written by
`dtsIO_readDF`. Their positional correspondence (index i in `ax.chans` ↔ index i in
`ax.units`) is currently declared in a whitelist subroutine but not surfaced at the DF
level. Three separate operations need to respect this binding — so the whitelist should
become a first-class DF field rather than a side channel.

---

## Core Primitive

Because the axes are co-indexed (not joined on metadata), the alignment rule is trivial:
**the same index mask applies to all co-registered axes simultaneously.**

Selecting `ax.chans` positions `[2, 5, 9]` implicitly selects `ax.units` positions
`[2, 5, 9]`. No join, no foreign-key lookup — just mask propagation.

---

## DF Contract Change

Add a `coIdx` field at the DF level, written by `dtsIO_readDF`:

```matlab
DF.coIdx = {{'chans', 'units'}};   % list of co-indexed axis pairs
```

This makes co-registration self-describing and discoverable by any operator without
importing an external whitelist function.

---

## Shared Hook — `nexOp_coAlign`

`nexOp_coAlign` is mask-type agnostic: it propagates whatever `primaryMask`
structure the caller passes.  The caller's choice of mask type sets the mode.

### Filter mode — `nDivsPerBin = Inf` (applyPointer callers)

```matlab
% flat index vector → flat propagation, 1:1 co-registration preserved
masks = nexOp_coAlign(DF, 'chans', [3 4]);
% masks.chans = [3 4]
% masks.unit  = [3 4]   → ax.unit stays flat: [4, 5]
```

### Pool mode — finite `nDivsPerBin` (pm.pool callers)

```matlab
% cell array of index groups → membership sets propagated to co-axes
masks = nexOp_coAlign(DF, 'chans', {[3 4], [5 6]});
% masks.chans = {[3 4], [5 6]}
% masks.unit  = {[3 4], [5 6]}  → ax.unit becomes {[4,5], [6,7]}
%   one cell per output bin — co-registration survives pooling as 1:many
```

`ax.unit` as a cell array of membership sets records which units contributed
to each bin.  Downstream consumers must handle both forms:
- flat vector  → pre-pool or `Inf` case (individual units, 1:1)
- cell array   → post-pool (bin membership sets, 1:many)

`pm.pool` is responsible for calling `nexOp_coAlign` with grouped indices and
writing the resulting cell into `DF.ax.(pairedAxis)`.

```matlab
function masks = nexOp_coAlign(DForAx, primaryAxis, primaryMask)
% primaryMask: flat index vector (filter) or cell of index groups (pool)
    masks.(primaryAxis) = primaryMask;
    % resolve coIdx from DF.coIdx, DF.ax, or plain ax struct (fallback)
    for each pair in coIdx that contains primaryAxis:
        pairedAxis = the other member of the pair;
        masks.(pairedAxis) = primaryMask;   % same structure propagated
    end
end
```

---

## Three Hook Locations

All three call `nexOp_coAlign` after computing their primary axis mask:

| Operation | Trigger | Primary axis | Co-aligned axis |
|---|---|---|---|
| `poolMap` postSet | axis relabels from `chans` → `region` | `chans` | `units` |
| `applyPointer` | pointer window selects chans subset | `chans` | `units` |
| `poolAxes` | pool rule filters/decimates chans | `chans` | `units` |

---

## Filtering Without Decimating (`nDivsPerBin = Inf`)

Concrete use case — train PCA/LDA on STN units only:

1. In `nexFigure_PCA`, change poolMap `chans` groupBy from `'chans'` → `'region'`
2. Set `nDivsPerBin = Inf` (keep all members of selected group, no averaging)
3. Pointer selects region = `'STN'`
4. `applyPointer` computes chans mask = indices where chans ∈ STN
5. `nexOp_coAlign` propagates the same mask to `units`
6. `compileSTAT` → `poolAxes` outputs a DF with only STN channels and their units,
   not decimated, just filtered

---

## Cross-Session Canonical Alignment (`nexOp_alignCoAxes`)

### Future: More Ambitious Co-Registrations

The current co-index registry seeds from a single pair `{chans, unit}` — sufficient for
channel-position and unit-ID cross-session alignment. Anticipated extensions:

- **Probe geometry / electrode arrays**: co-register across shanks or probes; the identity axis becomes `shank` or `probe` rather than `chans`
- **Multi-area hierarchies**: a `region` axis co-indexed with both `chans` and `unit`, allowing REG to anchor at the anatomical level
- **Matched stimulus IDs / event labels**: for non-neural modalities where the identity axis is a stimulus code or trial type, not a recording channel
- **UnitMatch online**: once unit IDs are matched across sessions, REG transitions from `chans` (proxy) to `unit` (true); the bus selection drives this, no code change needed

When these are added, only two sites change: `nexOp_coIndexPairs` (extend the pair registry) and `nexOp_computeREGOptions` (note is already there). The REG bus, `nexOp_alignCoAxes`, and `refreshREG` are all axis-agnostic and need no modification.

---

### REG — Registration Identity Axis

The `coIdx` pair `{chans, units}` does not specify which axis provides cross-sample
identity. A new Domain field **REG** carries this:

```matlab
Domain.REG = 'chans'   % pre-unitMatch: channel position is stable identity
Domain.REG = 'units'   % post-unitMatch: matched unit IDs are stable identity
```

REG sits alongside D1, FTR, and MSR in the Domain bus and is exposed as a selector
in the mdlObj figure.

### Unified Alignment Rule (parameterised by REG)

```
canonical = union(ax.REG across samples)
for each value v in canonical:
    nodes = co-registered FTR values mapping to v in this sample
    |nodes| > 1  →  applyPoolFn(nodes)   [defaults to @mean]
    |nodes| = 1  →  pass through
    |nodes| = 0  →  0-fill (structural absence, not missing-at-random)
```

When `REG = 'chans'`: multiple units may map to the same channel → pooling is live.  
When `REG = 'units'`: unitMatch guarantees one unit per canonical position → pooling
is a structural no-op (always hits the |nodes|=1 branch).

The same `nexOp_alignCoAxes` call handles both cases; REG is a parameter.

### coAlignMode Tag

```matlab
STAT.Properties.CustomProperties.coAlignMode = 'channel_avg';  % REG='chans'
STAT.Properties.CustomProperties.coAlignMode = 'unit_id';      % REG='units'
```

The two modes produce **incompatible feature spaces** — a model trained under
`channel_avg` cannot accept `unit_id` data. The tag makes the mismatch detectable.

### Pooling Function

```matlab
function val = applyPoolFn(nodes, poolFn)
    if isempty(poolFn), poolFn = @mean; end
    val = poolFn(nodes);
end
```

`poolFn` is isolated behind this local so any anonymous function drops in later
(`@max`, `@(x) quantile(x,0.75)`, custom burst estimator) without touching the
alignment logic. Default is `@mean` (mean firing rate across units on same channel).
MSR already governs feature-level reduction; `poolFn` governs the REG-level
many-to-one collapse — they default to the same operation but are separately
parameterisable.

### Inference-Time Projection (transform)

At `transform(DF_X)` time, `DF_X` is projected onto `fitSentinel.ax.REG`:

```
missing from DF_X relative to fitSentinel  →  0-fill
extra in DF_X not in fitSentinel           →  drop (by REG ID, not channel)
```

"Drop by REG ID" — if REG='chans', drop by channel position; session-local unit
cluster IDs are never compared across sessions. If REG='units' (unitMatch active),
drop by matched unit ID.

If drop ratio > threshold (suggested 20%), log a warning via `coAlignMode` tag
without blocking execution.

### fitSentinel — as-built

Not a single per-mdlObj snapshot of the whole sentinel DF as originally sketched
above. Instead, `nexAnalysis_cvPermute.m` builds one **per SWP value**, as a
`{1×nSwp}` cell on each RESULT row:

```matlab
% inside the `for si = 1:nSwp` loop, after cropCanonicalREG:
sentinels{si} = sentinel;   % struct: surviving canonical labels for axes riding
                             % the REG-owning dimension, for this CTG×SWP slice
...
R.fitSentinel = sentinels;  % packed into the RESULT row alongside df/ax/ptr
```

Lighter than a full DF snapshot — it only records which canonical REG-axis
labels survived `cropCanonicalREG`'s crop for that particular slice, which is
exactly what's needed to know which canonical positions a given SWP value's
model actually saw. Does **not** yet serialize in the generic
`saveState()`/`mdlObj_fromState()` path, and does not itself govern
inference-time projection — this row-level sentinel was never meant to (see
below).

**A separate, model-level sentinel now covers inference-time projection.**
`mdlObj.fitSentinel` (a base `mdlObject` property, distinct from this
per-row one) is set once per `compileSTAT()` call — from the SAME single,
global `nexOp_alignCoAxes` call `nexAnalysis_cvPermute` already runs before
any CTG/SWP splitting, so it matches the uncropped canonical width the
final full-CTG refit (see "Canonicalisation Timing" below) actually deploys.
`scaleApply_transform` projects each new raw per-trial DF onto
`mdlObj.fitSentinel` before calling `transform()`, via `nexOp_alignCoAxes`'s
`canonRegOverride` parameter — implementing exactly the rule this doc
specified under "Inference-Time Projection" above (missing → structural-
absence fill, extra → dropped). No per-CTG/per-SWP threading needed: the
per-row `fitSentinel`s answer "what did this specific fold see" (diagnostic);
`mdlObj.fitSentinel` answers "what does the deployed model expect"
(projection) — genuinely different questions, no reconciliation required.

### Canonicalisation Timing in GRP×SWP Loops

Each (CTG × SWP) iteration may produce a different canonical set (STN units ≠
VPM units). Canonicalise **once per iteration** at the top of the fit loop, store
in `fitSentinel` for that iteration's RESULTS row, and restore `Origin.DF_postOp`
to the union-of-all canonical after the full loop so the Pointer reflects all
possibilities for the next interactive session.

> **RESOLVED — as-built deviates here, deliberately.** `nexOp_alignCoAxes` runs
> once, globally, inside `nexOp_compileSTAT` — before the CTG/SWP loop in
> `nexAnalysis_cvPermute` even starts (and now before pooling too — see the
> align-before-pool fix). Every SWP value (e.g. `STN`-only vs `VPM`-only)
> therefore gets NaN-padded against the *global* union of REG values across the
> whole dataset, not a tight per-iteration canonical set. This is safe — pooling
> of real duplicates is already trial-local, so global alignment loses no
> information, only leaves wasted width — and the waste is handled downstream
> instead: `cropCanonicalREG` (called per SWP value inside `nexAnalysis_cvPermute`'s
> `for si = 1:nSwp` loop) drops whichever canonical positions are NaN for every
> trial in that specific CTG×SWP slice, right before the design matrix is built.
> Net effect: global-once canonicalization (cheap, one alignment pass) + per-
> iteration tightening (cheap, no re-alignment, just a crop) — rather than
> re-running `nexOp_alignCoAxes` per iteration. `fitSentinel` (see below) records
> which canonical labels survived that crop, one per SWP value.

---

## mdlObj Collector — CTG and SWP Buses

### Full Collector Bus Table

| Bus | Existing? | Role |
|---|---|---|
| `View` (SRC, VW, CLR) | existing | visualization control |
| `Domain` (D1, FTR, MSR, REG) | existing + REG new | axis role assignment |
| `Pointer` | existing | windowing into result axes |
| `CTG` | **new** | grouping variables for training (mirrors CTG in nexObj_categorical) |
| `SWP` | **new** | outer-loop axis name (reads values from Pointer) |

**CTG** mirrors the existing `nexObj_categorical` CTG bus exactly — `CTG = {'subj','phase'}`
means train one independent model per (subj × phase) cell, no cross-contamination.
The fewer changes made to the existing Collector architecture the better; CTG is
the name already understood system-wide.

### Output STAT Shape (as-built)

`nexAnalysis_cvPermute.m` implements this differently than originally designed:
- Each **row** = one CTG combination only (SWP does *not* fan out into rows)
- **Label columns**: one per CTG variable (from `comboTbl`)
- **`df` column**: `[nFolds × (1+nPermute) × nTime × nSWP]` — SWP is an inner
  dimension of `df`, navigated the same way the pre-existing "outer axis" was
  (via `ax.(swpID)` / `ptr`), not via VW row selection.

So VW items = CTG label joins only (e.g. `"subj1 | phase1"`); SWP values within
a row are inspected via the Pointer/axis machinery on that row's `df`, not by
picking a different VW row. This is simpler than the row-fanout design below and
reuses the existing outer-axis slicing code path, at the cost of SWP comparisons
living inside one cell rather than across rows.

The original design (kept for reference, not current behavior):
- Each row = one (CTG₁ × CTG₂ × … × SWP) combination
- Label columns: one per CTG variable + one for the SWP value
- `df` column: DF struct `[nFolds × (1+nPermute) × nTime]` (no outer dim, since SWP was the row)
- VW items = join of CTG+SWP label columns per row → `"subj1 | phase1 | STN"`

---

## poolMap → Pointer PostSet Chain

### Existing Wiring (confirmed in `nexObj_stateSpace`)

The chain already exists for nexObj:

```
applyPoolButton  →  nexObj.updateScope()
                     ↓
                 nexOp_poolAxes(pMap, DF, ptr)  →  DF_pooled
                     ↓
                 DF_postOp.ax = DF_pooled.ax     ← triggers PostSet
                     ↓
                 addlistener(DF_postOp, 'ax', 'PostSet', @refreshPointer)
                     ↓
                 refreshPointer()  →  updates all Pointer bus entries + UI listboxes
```

`DF_postOp` is a `nexObj_DF` handle object with `SetObservable` on `.ax`.
The listener is constructor-wired once. `refreshPointer` smart-maps selections:
preserves user selections when axis values haven't changed, resets to full range
when axis content changes (e.g. channel numbers → region labels).

### Two-Tier Lazy / Commit Architecture

The poolMap panel (v3: `uidropdown` + `uispinner`) exposes two tiers:

**Tier 1 — Lazy (auto-fires on `ValueChangedFcn` of `groupBy` / `nDivsPerBin`):**
- Calls `nexOp_poolAx(pMap, DF)` — computes only output axis labels from pMap
  metadata + `DF.ax`; never touches `DF.df`
- Writes result to `DF_postOp.ax` → PostSet fires → `refreshPointer()`
- Cheap and data-independent; user sees Pointer update immediately

**Tier 2 — Commit (`applyPool` button → `updateScope()`):**
- Full `nexOp_poolAxes` as today — pools `DF.df` and writes both `DF_postOp.df`
  and `DF_postOp.ax`
- Sentinel is now stable and fit-ready

`nexOp_poolAx(pMap, DF)` is the new operator implied by Tier 1. The axis structure
of any pooled result (bins, labels, count) is determinable from pMap + `DF.ax`
alone — no data array required. `poolCfgEntryChangedFcn` calls this after updating
the pMap property.

Both spinners and dropdowns fire discrete `ValueChangedFcn` events — no debounce needed.

### Extension to mdlObj

mdlObj figures need to wire the same listener against their `Origin.DF_postOp`.
`refreshPointer` and `updateScope` are base-class methods — the wiring is one
`addlistener` call in the mdlObj figure constructor, identical to `nexObj_stateSpace`.

`nexOp_coAlign` fires **inside** `updateScope` / `nexOp_poolAxes` to propagate
the chans mask to units before the result is written to `DF_postOp.ax`. This means
co-registration is handled before the PostSet fires, so `refreshPointer` always
sees fully co-aligned axes.

---

## SWP Clamping Mechanics — NOT BUILT, superseded

This section described clamping the Pointer bus per SWP value via
`clampPointer`/`restorePointer` and a standalone `nexAnalysis_sweepFit`. None of
that exists in code. What shipped instead, inside `nexAnalysis_cvPermute.m`:

- `mdlObj.domain.SWP` names the axis (same contract as designed)
- The loop calls `sliceSTAT(STAT_ctg, swpDim, si)` directly on the STAT table for
  each SWP index — no Pointer clamp/restore round-trip, no `fitSentinel`
- Results for all `si` are accumulated into one `scores` array
  `[nFolds × (1+nPermute) × nTime × nSwp]` per CTG combo, then packed into that
  combo's single RESULT row (see "Output STAT Shape (as-built)" above)

This is strictly simpler than the clamp/restore design — no bus mutation to undo,
no risk of leaving the Pointer in a clamped state. A lightweight per-SWP-value
`fitSentinel` (surviving canonical labels after `cropCanonicalREG`, not a full
DF snapshot) was added later — see "fitSentinel — as-built" above.

---

## Implementation Order (status)

1. [x] Promote whitelist → `DF.coIdx` — done in `dtsIO_composeDF` (design said `dtsIO_readDF`; landed one call site over)
2. [x] Implement `nexOp_coAlign` (mask propagation primitive)
3. [x] Add call sites in `applyPointer`/`applyPointerDF`, `poolAxes`, poolMap Tier-1 lazy path
4. [x] Implement `nexOp_alignCoAxes` (STAT-level canonical alignment, called in `compileSTAT`, on raw TF before pooling — align-before-pool ordering fixed) — canonicalization-timing resolved as global-once + per-SWP-value crop, see above
5. [x] Add `REG` to Domain bus; expose in mdlObj figure selector (`nexFigure_lda`, `nexFigure_ssm`)
6. [ ] Wire `DF_postOp.ax` PostSet listener → `refreshPointer` in mdlObj figure constructor — `refreshPointer` exists on `mdlObject` but is called manually from `poolCfgEntryChanged_v3`, not via an `addlistener` PostSet hook. Confirm whether that's sufficient or the listener is still wanted.
7. [x] Add `CTG` and `SWP` buses to mdlObj collector — `initViewBus`/`applyViewBus`
8. [~] SWP outer loop — built, but as a direct-slice loop inside `nexAnalysis_cvPermute`, not the clamp/restore + `nexAnalysis_sweepFit` design (see above)
9. [~] Add `fitSentinel` at fit time — done in lightweight per-SWP-value form (surviving canonical labels, not a full DF snapshot) for per-row diagnostics, **plus** a separate model-level `mdlObj.fitSentinel` that now governs inference-time projection in `scaleApply_transform` (see "fitSentinel — as-built"). Still not done: serializing either form through the generic `saveState()`/`mdlObj_fromState()` dehydrate/rehydrate path (only `mdlObj_pca`'s own `saveFit`/`loadFit` persists it today).
10. [ ] Wire `nexOp_alignCoAxes` into `nexOp_reportSTAT.m` (session-averaging path) — flagged follow-up, separate from the mdlObj/fitting path; not started

---

## SWP (Sweep) Bus — Outer-Loop Iteration Over FTR Subsets

### Problem

Training `FTR = units` then wanting to iterate over region subsets
(`STN-only`, then `VPM-only`) is a different operation from:

- **poolMap**: structural grouping (chans → region relabeling + co-registration)
- **Pointer**: window selection within a single run

Neither is the right place to own "iterate this training over each group value
on a given axis." That outer loop needs its own bus: **SWP**.

---

### SWP Contract

```
mdlObj.SWP = 'region'   % axis name to sweep (empty = no outer loop)
```

`SWP` holds a **single axis name** — nothing else. The outer loop resolves
the values to iterate from the **Pointer bus** on that axis:

```
for each val in Pointer.(SWP).selectedValues:
    clamp FTR axis to val
    fit / cvPermute
    store result tagged with val
end
```

Pointer already handles which subset of values is active (the user selects
`{STN, VPM}` in Pointer.region; SWP='region' iterates exactly those two).
No redundant state, no new selection widget.

---

### Why Not SWP = value list?

An alternative design stores the values directly: `SWP = {'STN','VPM'}`.
This is redundant with Pointer — Pointer already expresses the selected
subset. Storing it again creates two sources of truth to keep in sync.

The axis-name design is strictly more parsimonious:
- `SWP` owns **which axis** to iterate
- Pointer owns **which values** on that axis
- The outer loop composes them at runtime

---

### Relationship to poolMap and Co-registration

1. **poolMap postSet** groups `chans → region` and propagates the same mask
   to `units` via `nexOp_coAlign`. After this, Pointer.region contains the
   available group values (`STN`, `VPM`, …).

2. **SWP = 'region'** tells the outer loop to iterate over whatever
   Pointer.region currently has selected.

3. **Inside each SWP iteration**, `applyPointer` clamps both `chans` and
   `units` to the current region value (again via `nexOp_coAlign`).

So poolMap owns the relabeling; Pointer owns value selection; SWP owns
iteration. No role is shared.

---

### Triplet Example

`nDivsPerBin = 3`, `SWP = 'chans'`:

1. poolMap groups raw channels into triplets: `{1-3, 4-6, …}`
2. Pointer.chans shows those triplet labels; user selects all (or a subset)
3. Outer loop iterates over each selected triplet, clamping FTR to that group
4. Result has outer axis `chans` with values `{1-3, 4-6, …}`

The mechanics are identical to the region case — SWP is axis-agnostic.

---

### SWP Implementation — as-built

No standalone `nexAnalysis_sweepFit` was added. The CTG × SWP loop lives inline
in `nexAnalysis_cvPermute.m`:

```matlab
% ── 2. CTG combo enumeration ── one row of comboTbl per unique CTG tuple
% ── 4. SWP outer-axis detection ── domain.SWP names the axis, or auto-detect
%      falls back to the legacy "any leftover ptr axis" behavior when SWP="None"
% ── 5. Main loop: for each CTG combo →
%        for each SWP value (si) → sliceSTAT + fold/permute loop → scores(...,si)
%        pack scores into one RESULT row for this CTG combo
```

See `nexAnalysis_cvPermute.m` directly for the current implementation — this
doc no longer tracks it line-for-line to avoid drifting out of sync again.
