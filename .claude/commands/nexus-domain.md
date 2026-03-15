# nexus-domain — Domain and Ptr System Tenets

These are the rules governing the `domain` struct and `ptr` system used by `nexObject` subclasses for dimensional-agnostic visualization.

---

## The `domain` struct

```
domain.axes    % string array — full list of available ax keys (source of truth)
domain.D1      % string array — primary display axes
domain.D2      % string array — secondary / animation axes
domain.F       % string array — factor sources (= dfID_source, expandable)
domain.animate % string       — single axis currently driven by the player timer
```

No `domain.display` — visualization functions index D1 directly (`D1(1)`, `D1(2)`, etc.).

### Rules

- **All values must be MATLAB `string` type** — not `char`. Cast with `string(...)` at assignment.
- `domain.animate` is always a single axis; must be a member of D2.
- `domain.D2` defaults to `['t']` if present among ax fields; otherwise first axis.
- `domain.F` is a string array of factor sources — currently single element (`dfID_source`).

### D1 / D2 relationship

**Auto-infer default** (`inferDomain`, no selectionBus): `D1 = setdiff(axes, D2)` — the complement. This is a convenience only, not a permanent rule.

**When `nexObj_selectionBus` is active**: D1 and D2 are **independently assigned** from the full `domain.axes` menu. Both sub-buses expose all available axes. The user decides what belongs in each — do not assume or enforce any complement relationship between D1 and D2.

### Updating domain dynamically

`nexObject.setAnimateAxis(axKey)` replaces D2 with the selected axis and re-runs `inferDomain`:

```matlab
% Replace D2 (not append) — dropdown selects which axis is D2, not accumulates.
% D2 is a string array for future multi-axis support via nexObj_selectionBus.
nexObj.domain.D2      = string(axKey);
nexObj.domain.animate = string(axKey);
nexObj.domain = nexObj.inferDomain();   % recomputes D1 as complement of new D2
```

The D2 dropdown in the figure calls `setAnimateAxis` via its `ValueChangedFcn`.

---

## The `ptr` system

`ptr` lives in `DF_postOp.ptr`. Every axis has three fields:

```
ptr.(axKey).dim    % integer — dimension index of this axis in DF.df
ptr.(axKey).value  % integer — current position (single-slice index)
ptr.(axKey).range  % [start, end] — display / animation window
```

Initialized by `nex_initAxisPointer_v2(DF)` — sets `range = [1, length(ax)]` for every axis.

### Slicing with ptr

```matlab
Z = squeeze(sliceDF(DF.df, ptr, [rowKey, colKey], "range"));
```

- "range" mode: named axes (`[rowKey, colKey]`) expand to their full `ptr.range` window.
- All other axes collapse to `ptr.(axKey).value`.
- Transpose check: if `ptr.(rowKey).dim > ptr.(colKey).dim`, Z needs `Z'` to be `[nRows × nCols]`.

### Animation wrapping within range

`stepAnimate` (on `nexObject`) wraps the pointer within `ptr.(axSel).range`:

```matlab
r    = ptr.(axSel).range;  % [start, end]
span = r(2) - r(1) + 1;
axVal = r(1) + mod(ptr.(axSel).value - r(1) + stride, span);
```

This means the user can narrow the range spinners in the axis panel to animate a sub-window.

---

## `stepAnimate` — inherited animation method

Lives on `nexObject`. Never override per-subclass; all nexObj classes inherit it.

```matlab
function stepAnimate(nexObj, args)
    % CFG HEADER
    stride = args.stride; % default = 1
    % ...wraps ptr within range, calls nexObj.visualize()
end
```

The timer is always:
```matlab
nexObj.player = timer(...
    'TimerFcn', @(~,~) nexObj.stepAnimate(nexObj.cfg.aniCfg.entryParams));
```

`aniCfg` is sourced from `nex_generateCfgObj(str2func("nexObject.stepAnimate"))`.
Do **not** create per-subclass animate stub functions.

---

## Axis panel — range spinners

`breakoutAxisFields(nexObj, nexPanel, axPtr)` builds per-axis UI in the axis control panel:
- Label (axis name)
- Value spinner — current ptr value
- "range" label + rangeStart / rangeEnd spinners side by side
- Each range spinner calls `axisRangeChanged(src, event, nexObj, axPtr, axField, rangeIdx)`

Range changes take effect immediately in both slicing (display) and animation wrapping.

---

## Domain inference — `inferDomain()` on `nexObject`

`inferDomain` lives on the **base class** (`nexObject`) and is inherited by all subclasses. Do not reimplement it in subclasses unless the axis layout is genuinely non-standard.

**First call** (domain.D2 not yet set): auto-infers D2 from `'t'` axis, falls back to first axis.
**Subsequent calls** (domain.D2 already set): respects current D2 and animate, recomputes only D1.

This makes `setAnimateAxis` a thin wrapper:

```matlab
function setAnimateAxis(nexObj, axKey)
    % Replace D2 (not append) — dropdown selects which axis is D2, not accumulates.
    % D2 is a string array for future multi-axis support via nexObj_selectionBus.
    nexObj.domain.D2      = string(axKey);
    nexObj.domain.animate = string(axKey);
    nexObj.domain = nexObj.inferDomain();   % recomputes D1 as complement of new D2
end
```

`inferDomain` is the single source of truth for D1 — never duplicate the `setdiff` logic elsewhere.

Future: `nexObj_selectionBus` will curate D1/D2/F dynamically from a UI.
