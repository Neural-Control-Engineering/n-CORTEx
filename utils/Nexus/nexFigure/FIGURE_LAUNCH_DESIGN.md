# Figure Launch & Trial-Traversal — Design Note

_General-purpose toolbox to launch Nexus figures on demand, automate figure
startup at the end of pipelines/routines (per-machine), and keep every launched
figure repopulating on router/trial changes. Lives in `utils/Nexus/nexFigure/`.
Motivating consumer: the realtime `stopCapture` path (see
`RealtimeControl/REALTIME_CAPTURE_STREAM_DESIGN.md`)._

## Layers

```
Layer 1  nexLaunch(nexon, dfID, figType)          ← the primitive ("switch")
           ctg = nexLaunch_getCategorical(nexon,dfID);   % one cached hub per dfID
           obj = reg.(figType)(ctg);                     % construct on the hub
           nexRegister_figure(nexon, obj);               % record for traversal

Layer 2  nexLaunch_auto(nexon, trigger)            ← config-driven ("scene")
           read per-machine JSON; for entries whose .trigger matches (or "*"),
           call Layer 1. Guards: source-present, figType-known, session dedup.

Layer 3  hook points call Layer 2:
           nex_panelStartup end   → nexLaunch_auto(nexon,"panelStartup")   [offline/first load]
           proxy_npxls.stopCapture end → nexLaunch_auto(nexon,"stopCapture") [realtime]

Traversal  routerEntryChanged → nexRefresh_launchedFigures(nexon)
           reloadFromRouter() on every live launched figure; prune closed ones.
```

Layer 2 is just a `for` loop over Layer 1. Layer 1 is the single chokepoint every
launch flows through (INSPECT panel, auto, or a bare call), which is why
registration and dedup can live there without per-call-site bookkeeping.

## Registry — self-registering adapters (auto-sync)

`nexLaunch_registry()` globs `nexLaunchAdapt_*.m` in this folder → struct
`{figType → @nexLaunchAdapt_<figType>}`. Adding a launchable figure = drop one
`nexLaunchAdapt_<figType>.m` (`function obj = nexLaunchAdapt_<figType>(ctg)`); it
appears in every launcher dropdown (`nexLaunch_panel` reads `fieldnames(reg)`) and
every auto-launch config with **no edit to the registry**. figType convention =
the class suffix (`nexObj_<figType>`), e.g. `polyGraph`, `waterfall`.

Current adapters: monoGraph, monoGram, pixelGram, stateSpace, polyGraph, waterfall.

**Why adapters instead of inferring the call from the constructor:** the registry
is an *adapter*, not a list — each figure's constructor has a different arg order
(`nexObj_monoGraph(Parent,...)` vs `nexObj_monoGram(nexon,Parent,...)`). A
name-based auto-adapter (map arg name → ctg/nexon/dfID_source/[]) reproduces 5 of 6
exactly but **breaks `stateSpace`**: the arg name `Partner` means *the hub* in
`pixelGram` but *an optional second partner left empty* in `stateSpace`. That's
real per-figure knowledge not recoverable from a filename or signature — so each
adapter is written explicitly and co-located with the figure.

## Auto-launch config (Layer 2)

- File: `Startup/Cache/autoLaunch_<COMPUTERNAME>.json` — raw COMPUTERNAME, hyphens
  included (NOT `matlab.lang.makeValidName` — that mangles the hyphen and desyncs
  from a hand-created filename). Opt-in per machine: missing file → no auto-launch.
- Shape: JSON array of `{"dfID":..., "figType":..., "trigger":...}`. `trigger`
  names the hook (`"stopCapture"`, `"panelStartup"`) or `"*"` for all; omit →`"*"`.
- The trigger tag is what lets one file drive *different* figure sets at different
  hooks (offline-load vs realtime-capture). Without it, every hook fires the whole
  list.

## nexon.UserData stores (three, distinct jobs — overlap is intentional)

| Store | Populated by | Keyed | Purpose |
|-------|-------------|-------|---------|
| `launchCategoricals` | `nexLaunch_getCategorical` | dfID | one categorical hub per source (STAT/selection surface) |
| `autoLaunched` | `nexLaunch_auto` | `trigger\|dfID\|figType` | dedup: launch each auto entry once, reuse while alive |
| `launchedFigures` | `nexRegister_figure` (via `nexLaunch`) | flat cell | traversal target: every live figure, to refresh on router change |

`autoLaunched` figures also appear in `launchedFigures` — that's single-responsibility
(dedup needs the keyed map, traversal needs the flat list), not redundancy to remove.
Categorical **hubs deliberately do not** join `launchedFigures`: they aggregate
across trials, so per-trial `reloadFromRouter` is not their refresh model.

## Trial traversal

`nexRefresh_launchedFigures(nexon)` walks `launchedFigures`, calls
`reloadFromRouter()` (base `nexObject` method: re-read `dfID_source` for the
selected trial → operate → visualize) on each live figure, and prunes closed
windows. Wired into `routerEntryChanged` **augment-style**: it runs alongside the
legacy `NPXLS.shanks.(shank).scope.(scope)` and `SLRT.signals` hand-walks, which
are left untouched (no regression risk).

**Deferred migration:** once trusted in the field, the shank scopes can register
through `nexLaunch` too, collapsing the ~40-line hand-walk in
`routerEntryChanged` into the single `nexRefresh_launchedFigures` call.

## dfID resolution contract (in-memory DTS)

A launched figure reads its source through `dtsIO_readDF(nexon, dfID, [])`. The
online capture DTS is **pure in-memory (no `h5_path` manifest)** — DFs are foliated
into `<base>_<stub>` columns (`lfp` → `lfp_df`, `lfp_t`, `lfp_chans`;
`RTS_spk_activity` → `RTS_spk_activity_df`, `_t`, `_unit`, `_measure`). Resolution
was fragmented across `readDF` routing, `composeDF` matching, the launcher guard,
and the dropdown enumeration — which could disagree (the same class of bug that
broke the first capture render). It is now **one shared resolver**:

**`dtsIO_resolveDFID(DTS, DFID)` → `[cols, baseDFID]`** — the single source of truth
(in-memory only; disk-backed dfIDs are HDF5 groups, gated out before this).

Two levels, in this order:

```
readDF (disk vs memory)
  1. disk-backed? h5_path manifest (or h5_path_<DFID> override) AND DFID not a
     manifest column → dtsIO_readHDF5. done.
  2. else → dtsIO_composeDF → dtsIO_resolveDFID

resolveDFID (in-memory)     ← VIRTUAL/STUBBED FIRST, literal-exact LAST
  1. foliated: columns whose name minus trailing _<stub> == DFID (+ bare DFID col)
  2. _df normalization: DFID ends "_df" and (1) empty → strip "_df", retry base
  3. bare-exact: a lone column literally named DFID (single-column DF)
  4. none → cols = strings(0,1)  → composeDF returns []  (explicit not-found)
```

**Why foliated-first, not exact-first:** `RTS_spk_activity_df` *is* a literal
column (the activity data). Matching it exact-first would hand back that array with
**fabricated** axes, silently dropping its real `unit`/`t`/`measure` siblings.
Preferring the foliated match (via `_df` normalization → base `RTS_spk_activity`)
reassembles the whole DF. So the config dfID is the **base** (`RTS_spk_activity`),
though the `_df` form resolves to the same DF.

Consumers, all now on the shared logic:
- `dtsIO_composeDF` — assembles from `cols`, splits on `baseDFID`, returns `[]` on
  not-found (was a silent fieldless `struct()`).
- `dtsIO_readDF` — routes on disk-backed; in-memory → composeDF → resolver.
- `dfIDPresent` (launcher guard) — `~isempty(resolveDFID(...))` in-memory.
- `dtsIO_listDFIDs` — enumeration counterpart (foliated columns collapsed to base);
  drives the INSPECT dropdown so it lists `lfp`/`RTS_spk_activity`, not raw stubs.

## Gotchas / invariants (bugs caught during build)

- **Heterogeneous handles** → `launchedFigures` is a CELL, not a handle array:
  `nexObj_pixelGram` is `< handle`, the rest `< nexObject`, so `[a,b]` would throw
  "Cannot concatenate objects of different classes."
- **`pixelGram` has no `reloadFromRouter`** (not a `nexObject`) → traversal guards
  with `ismethod`; it stays registered but isn't router-refreshed.
- **`figureAlive` / `.Figure.fh`** — every launched figure sets `obj.Figure.fh`
  (design invariant). Traversal and dedup both rely on it.
- **Registry return** — each `nexLaunchAdapt_*` returns the constructed object so
  Layer 1 can register it and Layer 2 can dedup on it.

## Files

```
nexLaunch.m                  Layer 1 primitive (+ register)
nexLaunch_registry.m         glob nexLaunchAdapt_*.m → {figType → handle}
nexLaunchAdapt_<figType>.m   one per launchable figure (the explicit adapter)
nexLaunch_getCategorical.m   one cached ctg hub per dfID
nexLaunch_panel.m            INSPECT embedded launcher UI (routes through nexLaunch)
nexLaunch_auto.m             Layer 2 config-driven scene runner
nexLaunch_loadAutoCfg.m      per-machine JSON loader
nexRegister_figure.m         append to launchedFigures (cell, dedup by identity)
nexRefresh_launchedFigures.m router-driven refresh + prune

DTSIO/dtsIO_resolveDFID.m    shared dfID→columns resolver (single source of truth)
DTSIO/dtsIO_listDFIDs.m      enumeration counterpart (bases for in-memory dropdowns)
DTSIO/dtsIO_composeDF.m      in-memory DF assembly (delegates to resolveDFID)
DTSIO/dtsIO_readDF.m         disk-vs-memory routing
```
