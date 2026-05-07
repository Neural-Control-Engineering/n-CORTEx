# nexon — Nexon Class Reference

The `Nexon` handle class is the root object of every Nexus session. Everything hangs off `nexon.console.BASE.*`.

---

## Key Properties

| Path | Content |
|------|---------|
| `nexon.console.BASE.DTS` | Active Data Table/Struct — primary data carrier |
| `nexon.console.BASE.params` | Session parameters (paths, extractCfg, experiment name, bands, …) |
| `nexon.console.BASE.registry` | Category / LUT registry built by `nexInit_registry` |
| `nexon.console.BASE.router` | Session/subject routing config |
| `nexon.settings` | Global settings (Colors, headless flag, …) |
| `nexon.UserData` | Arbitrary session-level storage |

---

## Methods

### `appendToDTS(nexon, DTS)`
Merges a new DTS timetable into `console.BASE.DTS`, re-sorts by `sessionLabel`/`trialNumber`, and updates the router dropdowns. If `DTS` is the first batch, runs `nex_panelStartup` to initialize all UI panels.

---

## Startup Cache — `nexCachePath` / `saveRegistry` / `loadRegistry`

### Cache path convention

```matlab
p = nexon.nexCachePath(cacheKey)
% → Nexus/Startup/Cache/<cacheKey>_<experiment>.mat
```

The experiment tag is read from `nexon.console.BASE.params.experiment`, then `params.extractCfg.experiment`, falling back to `"default"`. The tag is sanitized with `matlab.lang.makeValidName` so the filename is always valid.

This method is the single place that knows the cache root and naming convention. All future cached artifacts should call it rather than hardcoding a path.

### `saveRegistry(nexon)`

Saves `nexon.console.BASE.registry` to the experiment-scoped cache file:
```
Nexus/Startup/Cache/registry_<experiment>.mat
```

Call after `nexInit_registry` completes to avoid rebuilding the registry (which reads every sessionLabel column from HDF5) on the next session.

### `loadRegistry(nexon)`

Loads the cached registry back into `nexon.console.BASE.registry`. Emits a warning and returns without modifying state if no cache exists yet.

### Adding a new cached artifact

1. Save: `save(nexon.nexCachePath('myKey'), 'myVar')`
2. Load: `S = load(nexon.nexCachePath('myKey'), 'myVar'); nexon.console.BASE.myThing = S.myVar;`

No new methods needed — `nexCachePath` is the only coordination point.

---

## Router — `initializeRouterCfg` / `routerEntryChanged`

The router is a cascading hierarchy of session-label dimensions. Each level filters the labels available to the next. Dimensions are:

```
subj → date → phase → [site] → trial
```

`site` is optional — it is included only when `parseSessionLabelUnique(DTS.sessionLabel, "site")` returns a non-empty result.

### `initializeRouterCfg(DTS)` → `routerCfgParams`

Builds the initial dropdown items for each level by walking the cascade from the first available value at each level. Returns a struct with fields `subj`, `date`, `phase`, `trial`, and optionally `site`.

### `routerEntryChanged(nexon, entryPanel, entryfield)`

Called by every router dropdown's `ValueChangedFcn`. Cascades downward from the changed field:

1. Syncs the changed value into both `entryPanel.entryParams` and `nexon.console.BASE.router.entryParams`.
2. Recomputes available items for every level below the change.
3. At each level: if the current selection is no longer in the available items, resets it to the first available value.
4. Sets both `.Items` and `.Value` together on each dropdown before using the value to filter the next level — this prevents the "Items must be 1-by-N" crash that occurs when an empty array is assigned.
5. Writes the working copy `ep` back to `nexon.console.BASE.router.entryParams` at the end.

**Why both `.Items` and `.Value` must be set together:**
Setting `.Items` before `.Value` ensures MATLAB never sees a `.Value` that isn't a member of `.Items`. Setting them in the wrong order, or setting `.Items` to an empty array, causes a hard error.

**The `site` level is gated:**
```matlab
hasSitePanel = isfield(nexon.console.BASE.router.Panel, 'site') && isfield(ep, 'site');
```
If the router UI has no site panel or the DTS has no site dimension, the block is skipped entirely — no errors, no stale state.

### Cascade invariant

At every level, the filtering chain is:
```
subjLabels
  → contains(ep.date)     → subjXdateLabels
  → contains(ep.phase)    → subjXdateXphaseLabels
  → contains(ep.site)     → terminalLabels          ← only if site present
  → strcmp(terminalLabels(1)) → trialNums
```

Each label set falls back to its parent if filtering returns empty, so no downstream level ever operates on an empty set.

### Adding a new optional cascade level

1. Add the level between phase and trial in both `initializeRouterCfg` and `routerEntryChanged`.
2. Gate on presence in the panel and `ep`: `isfield(router.Panel, 'myLevel') && isfield(ep, 'myLevel')`.
3. Use `terminalLabels` (not `subjXdateXphaseLabels`) as the input so new levels compose correctly.

---

## `nexInit_registry` — what the registry contains

Built by `nexInit_registry(nexon)`, stored at `nexon.console.BASE.registry`:

| Field | Content |
|-------|---------|
| `registry.categories.(key)` | Unique values for each sessionLabel category and signal type |
| `registry.LUT.(key)` | Color lookup table (`label`, `color` columns) for each sessionLabel category |

LUT keys match CLR column names used in visualization (e.g. `registry.LUT.sessionLabel_subj`). `nexOp_resolveGroupColors` reads these as its first priority when assigning per-point colors.
