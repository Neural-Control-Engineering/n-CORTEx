# cfg-header — CFG HEADER Formatting Rules

The `% CFG HEADER` pattern lets `nex_generateCfgObj` / `extractMethodCfg` automatically parse default parameter values from function or method source files and build an `entryParams` struct with UI-configurable spinners/dropdowns.

---

## Correct format

```matlab
function myFunc(nexObj, args)

    % CFG HEADER
    param1 = args.param1; % default = 0.5
    param2 = args.param2; % default = 10
    flagA  = args.flagA;  % default = true
```

### Rules

1. **The marker line must be exactly `% CFG HEADER`** — nothing else on that line.
2. **Assignments must immediately follow** — no blank lines, no comment-only lines between `% CFG HEADER` and the first assignment, and no gaps between assignments.
3. **Each assignment must be on one line**: `varName = args.varName; % default = <value>`
4. The `% default = <value>` comment is required and must appear on the same line.
5. The parser stops at the **first blank line or non-assignment line** after the block begins.
6. No trailing descriptions or notes above the assignments — they will cause the parser to stop early.

### What breaks parsing

```matlab
% CFG HEADER
% zLim_low: lower z limit    % <-- comment line BEFORE assignment — breaks parser
zLim_low = args.zLim_low; % default = -1

zLim_high = args.zLim_high; % default = 1  % <-- blank line gap — breaks parser
```

---

## Class method CFG HEADERs

To source `entryParams` from a **class method**, use `"ClassName.methodName"` syntax:

```matlab
nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexObject.stepAnimate"));
```

`extractMethodCfg` handles this by:
1. Detecting the `.` separator
2. Loading the class file via `which('nexObject.m')`
3. Trimming to the method's `function` line before applying the parser

This is how `stepAnimate`'s `stride` default is surfaced to the animation cfg panel without a stub function.

---

## Standalone function CFG HEADERs

```matlab
nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_monoGram"));
```

`extractMethodCfg` reads `nexVisualization_monoGram.m` directly and parses the CFG HEADER block.

---

## What gets built

`nex_generateCfgObj` returns a struct with:
- `.fcn` — function handle
- `.entryParams` — struct of `{paramName: defaultValue}` parsed from CFG HEADER
- `.cfgVars` — raw parsed variable info

`entryParams` is passed directly as the `args` argument to the function.
