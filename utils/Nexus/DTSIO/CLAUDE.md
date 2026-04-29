# DTSIO — CLAUDE.md

## Overview

`DTSIO/` handles all reading and writing of the DTS (Data Table/Struct). It supports two DTS modes transparently:

- **In-memory DTS** — plain MATLAB table; all data in RAM as cell/numeric columns.
- **Disk-backed manifest** — lightweight table with `h5_path` + `h5_root` columns; per-trial numeric data lives in HDF5. Detected automatically by the presence of the `h5_path` column.

---

## Column Classification Rule

When exporting or classifying DTS columns, the rule is:

| Column type | Destination |
|-------------|-------------|
| `iscell` column, first non-empty element is a **non-scalar numeric array** | HDF5 (per-trial DF data) |
| `iscell` column, first non-empty element is a **scalar** | Manifest table (per-trial metadata) |
| Plain numeric column (`isnumeric && ~iscell`) | Manifest table (scalar-per-trial values, e.g. `withdrawalScore`, `stimOnset_advance`) |
| Non-numeric (strings, structs, cell-of-strings, etc.) | Manifest table |

**Rationale:** scalar-per-trial behavioral scores and timing values (numeric) must be in the manifest so the selection pipeline (`nex_applySelectionMask`) can filter by them without triggering HDF5 reads. Large array-per-trial data (LFP, PCA, etc.) goes to HDF5 to keep the manifest lightweight.

---

## Key Functions

### `nexus_exportDTS(DTS, h5File)` → `DTS_manifest`

Export in-memory DTS to HDF5. Returns a manifest table with `h5_path` + `h5_root` routing columns. Non-numeric columns and scalar-per-trial numeric columns are preserved in the manifest table; array-per-trial cell columns go to HDF5.

Assign the returned manifest back to `nexon.console.BASE.DTS` to enable disk-backed IO.

### `nexus_spliceDTS(DTS_manifest, DTS_source, dfIDs)` → `DTS_out`

Splice specific dfIDs from an in-memory `DTS_source` into an existing disk-backed `DTS_manifest`, without re-exporting the entire DTS. Row-matching by `sessionLabel|trialNumber` key.

- Non-numeric dfIDs → added as manifest table columns.
- Numeric dfIDs → written to HDF5 trial-by-trial using existing `h5_root` addresses.

Use this to recover columns missing from an older manifest (e.g. `nexus_spliceDTS(DTS_manifest, DTS_original, "signal_types")`).

### `dtsIO_readTFH5(DTS, dfID, idxSel, modifier)` → `out`

Unified column reader. Transparently handles manifest columns and HDF5 dfIDs.

```matlab
out = dtsIO_readTFH5(DTS, dfID)                   % all rows
out = dtsIO_readTFH5(DTS, dfID, idxSel)            % selected rows (logical or numeric)
out = dtsIO_readTFH5(DTS, dfID, idxSel, 'simple')  % extract .df and return {N×1} cell
```

- **Direct manifest column** (`signal_types`, scalars, strings): returns the raw column slice.
- **HDF5 / in-memory DF column**: scalar `idxSel` → single DF struct; multiple → `{N×1}` cell.
- **`'simple'` modifier**: extracts `.df` from each DF struct → `{N×1}` cell where missing trials are `[]` (not dropped). Preserves trial indexing.

### `dtsIO_readDFIDs(DTS)` → `dfIDs`  (string array)

Returns all dfIDs in a DTS — manifest column names first, then HDF5 leaf group names from a sample trial (row 10 by default). Equivalent of `DTS.Properties.VariableNames` but includes disk-backed HDF5 keys.

---

## HDF5 Category Selection Extension

`dtsIO_classifyCategory(DTS, key)` uses a three-priority lookup:

| Priority | Check | Returns |
|----------|-------|---------|
| 1 | `key` found in `sessionLabel` fields (via `parseSessionLabel`) | `"sessionLabel"` |
| 2 | `key` is a direct column in `DTS.Properties.VariableNames` | `"var"` |
| 3 | DTS is disk-backed and `key` is in `dtsIO_readDFIDs(DTS)` | `"h5"` |
| — | Not found anywhere | `[]` (key silently skipped by `nex_applySelectionMask`) |

`dtsIO_readTF_category` handles the `"h5"` branch by calling `dtsIO_readTFH5(..., 'simple')` and flattening scalars to a double vector (missing trials → `NaN`, which never matches any `keySel` value). This lets `nex_applySelectionMask` filter on HDF5-backed scalar columns like `withdrawalScore` or `stimOnset_advance` without any changes to the selection pipeline.

**Cost:** building a `selCond` from an HDF5 scalar column requires one `h5read` call per trial. This is acceptable for mask-building (infrequent), not for tight loops.

---

## Applying `selCond` to Disk-Backed DTS

Slicing the manifest is free — it only filters the in-memory routing table:

```matlab
selCond  = nex_applySelectionMask(DTS, S);
DTS_sel  = DTS(selCond, :);              % free — table slice, no HDF5 access
DF       = dtsIO_readTFH5(DTS_sel, 'lfp', []);  % only reads selected trials
```

Per-trial HDF5 layout (each trial = its own group) means "read only selected trials" is natural — just iterate over the filtered manifest rows.

---

## HDF5 Layout

```
/{subject}/{date}/{phase}/trial_{N:04d}/{dfid}/df        ← numeric data array
/{subject}/{date}/{phase}/trial_{N:04d}/{dfid}/{axis}    ← axis arrays (f, t, chans, ...)
/{subject}/{date}/{phase}/trial_{N:04d}/{dfid}/args      ← optional args array
```

`dim_order` attribute on `/df` encodes axis→dimension mapping (e.g. `"chans,t"`).

---

## `dtsIO_writeDF_toHDF5` — axisKeyWords filter

The writer only writes axis arrays whose names are in `axisKeyWords = ["f","t","chans","factor","dropout","latent"]`. This is intentional — it prevents unintended writes from numeric fields that happen to be in `DF.ax`. Do not remove this filter. Type-dispatch for other data structures (struct→group, table→parallel datasets) belongs in dedicated writers, not in the per-trial DF path.
