# new-nexobj — Checklist for Creating a New nexObj Visualization Object

Use this checklist when building a new `nexObj_*` class in Nexus. `nexObj_monoGram` is the canonical reference implementation.

---

## 1. Inherit `nexObject`

```matlab
classdef nexObj_myThing < nexObject
    properties
        pMap
        player   % if animated
    end
```

`nexObject` provides: `classID`, `Parent`, `Children`, `Origin`, `nexon`, `DF`, `dfID_source`, `DF_postOp`, `dfID_target`, `collector`, `domain`, `pointer`, `Figure`, `UserData`, `cfg`.

---

## 2. Constructor signature

```matlab
function nexObj = nexObj_myThing(nexon, Parent, dfID_source, opCfgFcn, domain, headline)
    if nargin < 6, headline = []; end
```

- If `Parent` provided, pull `nexon` from it: `nexon = Parent.nexon;`
- Call super: `nexObj = nexObj@nexObject(nexon, Parent, dfID_source, headline);`
- Set `nexObj.classID = "xyz";` (short unique tag)
- `headline` is optional — when non-empty, `applyHeadline()` sets `Figure.fh.Name` (window
  title bar) after the figure is built. All existing nexObj subclasses accept it as their
  last positional argument.

---

## 3. DF loading

```matlab
if ~isempty(Parent)
    nexObj.DF     = Parent.DF_postOp;
    nexObj.Origin = Parent.Origin;
    nexObj.Parent.Children.(nexObj.classID) = nexObj;
elseif ~isempty(dfID_source)
    nexObj.DF     = dtsIO_readDF(nexObj.nexon, dfID_source, []);
    nexObj.Origin = nexObj;
end
```

---

## 4. Cfg objects

```matlab
nexObj.cfg.opCfg  = [];
if nargin >= 4 && ~isempty(opCfgFcn)
    nexObj.cfg.opCfg = nex_generateCfgObj(opCfgFcn);
end
nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_myThing"));
nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexObject.stepAnimate"));
```

`nex_generateCfgObj` calls `extractCfg` → `extractMethodCfg`, which reads the `% CFG HEADER` block and builds `entryParams` with defaults. For class methods, use `"ClassName.methodName"` syntax.

---

## 5. Operate → DF_postOp

```matlab
nexObj.operate();
nexObj.DF_postOp = nex_initAxisPointer_v2(nexObj.DF_postOp);
```

`operate()` applies `opCfg` or identity; `nex_initAxisPointer_v2` sets `ptr.(axKey).dim`, `.value`, `.range` for every axis.

---

## 6. Pool map + domain

```matlab
try
    nexObj.pMap = nexInit_pMap(nexObj, nexObj.DF_postOp);
catch e; disp(getReport(e)); end

if nargin >= 5 && ~isempty(domain)
    nexObj.domain = domain;
else
    nexObj.domain = nexObj.inferDomain();
end
```

---

## 7. Build figure + animation timer

```matlab
nexObj.buildFigure();
nexObj.player = timer('Period', 0.2, 'BusyMode', 'drop', ...
    'ExecutionMode', 'fixedRate', ...
    'TimerFcn', @(~,~) nexObj.stepAnimate(nexObj.cfg.aniCfg.entryParams));
```

---

## 8. Required methods

| Method | Role |
|--------|------|
| `inferDomain(nexObj)` | Auto-assign axes to D1/D2/F/animate/display |
| `operate(nexObj)` | Apply opCfg or identity; preserve ptr |
| `updateScope(nexObj)` | Pull from Parent, re-operate, re-visualize |
| `buildFigure(nexObj)` | Delegate to `nexFigure_myThing(nexObj)` |
| `visualize(nexObj)` | Delegate to `nexVisualization_myThing(nexObj, visArgs)` |
| `animate(nexObj)` | Call `nexObj.stepAnimate(nexObj.cfg.aniCfg.entryParams)` |
| `startPlayer(nexObj)` | Toggle timer from play button Value |
| `reportAverage(nexObj, idxSel)` | Compile → average → store → visualize |

Do **not** create per-subclass animate stub functions. `stepAnimate` is inherited from `nexObject`.

---

## 9. Companion files

| File | Location |
|------|----------|
| `nexFigure_myThing.m` | `nexFigure/` |
| `nexVisualization_myThing.m` | `Visualization/` |

### nexFigure checklist
- Build `uifigure`, `uipanel` for plot (panel0) + right-column config panels
- Config panels (bottom-up): axis control (panel5), animation (panel4), visualization (panel3), operation (panel2), pooling (panel1)
- Add play button, D2 dropdown, dfID edit field, report average button — all with short **tooltips**
- D2 dropdown callback: `@(src,~) nexObj.setAnimateAxis(src.Value)` — sets `domain.animate` and recomputes `domain.D1`
- Build surf canvas inline using `sliceDF(df, ptr, [rowKey, colKey], "range")` + transpose check

### nexVisualization checklist
- Begin with `% CFG HEADER` block (see cfg-header skill)
- Use `sliceDF(df, ptr, [rowKey, colKey], "range")` — no bespoke helper
- Transpose Z if `ptr.(rowKey).dim > ptr.(colKey).dim`
- Set `clim(ax, [cLim_low, cLim_high])` if color range needed
- End with `drawnow limitrate`
