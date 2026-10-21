# Nexus — Work In Progress

Running backlog of identified-but-deferred architecture work — ideas that came
up mid-conversation, got designed enough to be worth keeping, but were
explicitly held off rather than implemented immediately. Each entry should
carry enough context to pick up cold, without needing to re-derive the design.

Entry format: **Status**, **Context** (what prompted it), **Design**, **Touches**
(files/functions affected), **Depends on** (prerequisites that should land first).

---

## 1. Multi-axis `domain.DN` support in the scoring pipeline

**Status:** Designed, not started. Deferred until the single-DN CTG×SWP
sweep + co-registration/pooling path (this session's main work) is confirmed
stable end to end.

**Context:** `domain.D1` was generalized to `domain.DN` (a string array) so a
model could train/score jointly across more than one physical axis at once
(e.g. time AND frequency, not just time) — see `mdlObj/CLAUDE.md` and
`nexInit_domain.m`. That rename covers the *plumbing* (Domain bus UI now
allows multi-select, `domain.DN` holds an array) but scoring itself still
only ever resolves `DN(1)` — every consumer of DN downstream of the domain
bus assumes exactly one axis. This entry is the design for actually
supporting more than one.

**Design — three roles, not two:**

Every axis in a trial's `df` array plays exactly one of three roles once DN
can hold multiple entries:

- **DN** (`domain.DN`, 1..k axes) — the training/scoring domain. Stacked
  together into one combined sample dimension for fitting, then the fit's
  predictions get reshaped back into the *same* DN-shaped grid at score
  time, now holding an accuracy/R² value at each grid location instead of a
  raw sample.
- **FTR** (`domain.FTR`) — the feature dimension. Becomes the design
  matrix's columns. Never stacked, never iterated — always the model's
  input feature vector.
- **Everything else** — iterated externally, becoming an extra dimension in
  the RESULTS tensor rather than being stacked into training rows or
  decompressed into an accuracy grid.

The key realization: **SWP is not special-cased machinery, it's the existing
instance of "everything else."** Today `SWP` is handled by an explicit
pre-slice-then-loop in `nexAnalysis_cvPermute.m` because there's no general
rule for a third role — under this design, any leftover dimension gets the
same treatment automatically, with SWP simply being the one case that
already exists and works. No SWP-specific code should be needed once this
lands; the existing SWP behavior should just become a special case of the
general "everything else" rule (k=1 axis in that role).

**Fit-side mechanics:**
1. `nexOp_permute2First` generalizes from moving a single `dimSel` to the
   front, to moving *all* of `domain.DN`'s resolved dimensions to positions
   `1..k` (in `domain.DN`'s order), leaving FTR and "everything else" in
   place behind them. Still a pure `permute`, no reshape — `setdiff` already
   handles excluding a vector of dims identically to excluding a scalar, so
   this part needs no new logic, just resolving `k` dimension indices
   instead of one.
2. `nexOp_stackSTAT` generalizes its hardcoded `FtrDim = 2` to
   `FtrDim = numel(domain.DN) + 1`. The existing `permute(df,[1,3:ndims(df),2])`
   + `reshape(...,[],F)` logic already correctly flattens however many
   leading dims exist into one combined row dimension — it just needs to
   stop assuming F always sits at position 2.

**Score-side mechanics (the actually new part — `scoreFold` in
`nexAnalysis_cvPermute.m`):**
- Today: predicts on the flat stacked vector, reshapes back to
  `[nTime × nTest]` (hardcoded 2-D), computes balancedAccuracy/R² per time
  column (aggregating across the trial/`nTest` dimension only).
- Generalized: reshape the flat prediction vector back to
  `[DN_1 × DN_2 × ... × DN_k × nTest]` (N-D, sizes from `domain.DN`'s
  resolved axis lengths, not hardcoded), then aggregate along *only* the
  trial dimension for every combination of DN indices — producing an
  accuracy value at every point in the DN grid, not a single vector.
- **Critical correctness constraint:** the reshape order here must exactly
  invert `stackSTAT`'s flattening order (same axis-fastest-varying
  convention), or scores will silently land at the wrong DN-grid
  coordinates. This is the one piece of this whole design that's genuinely
  new math, not a generalization of existing code — get it wrong and
  results look plausible but are mislabeled, not obviously broken.

**Downstream packing:**
- `scores` preallocation (`nan(nFolds, 1+nPermute, nTime, nSwp)`) becomes
  variable-rank: `nan([nFolds, 1+nPermute, dnSizes, otherSizes])` — MATLAB's
  `nan()`/`zeros()` accept an arbitrary-length size vector, so this is
  mechanical once `dnSizes` is computed.
- `R.ax` construction (`R.ax.t = dnAx; if hasSwp, R.ax.(swpID) = swpVals; end`)
  becomes a loop over `domain.DN`'s axis names instead of a single hardcoded
  `t` field, plus the existing "everything else" handling generalized the
  same way SWP is packed today.

**Touches:** `nexOp_permute2First.m`, `nexOp_stackSTAT.m` (the `FtrDim`
constant), `nexAnalysis_cvPermute.m` (`scoreFold`'s reshape/aggregate logic,
the `scores` preallocation, `R.ax` construction). None of these five are
individually hard, but they only work correctly if changed together —
partially generalizing one (e.g. `permute2First` alone) without the others
will either silently misalign X/Y at score time or just not do anything
useful.

**Depends on:** Nothing architecturally — this is independent of the
co-registration/REG/CTG/SWP work already built. It's blocked only by
priority (get single-DN training fully confirmed working first) and by the
fact that it's a coordinated, five-file change rather than an isolated fix.

---

## 2. Bridge UnitMatch `global_ids` into `domain.REG = 'unit'`

**Status:** Not started. UnitMatch itself is now reachable from the UI
(`nexObj_ephysAtlas`'s new Units tab — `runUnitMatch()`/`reconcileCatalog()`,
wrapping `nexAtlas_runUnitMatch.m`/`nexAtlas_reconcileCatalog.m`), but its
output doesn't reach anything `nexOp_alignCoAxes` can see yet.

**Context:** `CoRegistration_Design.md`'s "REG — Registration Identity Axis"
section states the intended end state plainly:

```matlab
Domain.REG = 'chans'   % pre-unitMatch: channel position is stable identity
Domain.REG = 'units'   % post-unitMatch: matched unit IDs are stable identity
```

and claims *"UnitMatch online: once unit IDs are matched across sessions,
REG transitions from `chans` (proxy) to `unit` (true); the bus selection
drives this, no code change needed."* That claim is only half true today:
`nexOp_alignCoAxes`/`refreshREG`/the REG bus genuinely are axis-agnostic and
need no changes — but nothing currently *writes* a cross-session-stable
value onto any DF's `ax.unit`. `nexAtlas_runUnitMatch` writes its matched
IDs to `/units/sessions/<label>/<sorterTag>/global_ids` in `ephys_atlas.h5`
— a side artifact, never joined back onto the per-trial DF axes that
`compileSTAT`/`nexOp_alignCoAxes` actually operate on. Selecting
`REG = 'unit'` today aligns on session-local cluster IDs, which are *not*
stable across sessions — silently wrong, not just inert.

**Design — what's missing, concretely:**
1. A new small operator (something like `nexOp_applyUnitMatchIDs(DF, subjectDir, sorterTag)`
   or a batch equivalent) that reads `/units/sessions/<label>/<sorterTag>/{local_ids,global_ids}`
   for a given session and remaps that session's `ax.unit` values from local
   cluster IDs to UnitMatch's global IDs — in place, or into a new axis
   (e.g. `ax.unit_matched`) if keeping both identities visible is preferable
   to overwriting.
2. Decide *where* this remap happens: at DTS-read time (`dtsIO_readDF`/
   `dtsIO_composeDF`, so every consumer sees matched IDs transparently), or
   as an explicit step inside `nexOp_compileSTAT` alongside the existing
   `nexOp_alignCoAxes` call (gated the same way, on `domain.REG == "unit"`)?
   The former is more transparent but touches a much more load-bearing path;
   the latter is more contained but means raw-DF consumers outside
   `compileSTAT` (e.g. `scaleApply_transform`'s per-trial reads) still see
   unmatched local IDs unless they're updated too — same shape of gap as
   the `mdlObj_pca` units-to-channels vs. `alignCoAxes` split this session
   already worked through.
3. `nexAtlas_reconcileCatalog`'s catalog-level `global_id` merge is a
   *different* consumer (the atlas's own per-subject unit catalog, not a
   per-trial DF) — this item is specifically about wiring matched IDs into
   the DTS/DF axis path that `nexOp_alignCoAxes` reads, not about the
   catalog itself (already handled by the atlas's own reconcile step).

**Touches (anticipated):** a new `nexOp_*` operator (or two), `dtsIO_readDF`/
`dtsIO_composeDF` or `nexOp_compileSTAT` (depending on the timing decision
above), and possibly `nexOp_computeREGOptions`/`nexOp_coIndexPairs` per the
design doc's own note that those are the only two sites expected to need
touching when this lands.

**Depends on:** UnitMatch actually having been run + reconciled for the
subject in question (the new Units tab makes this reachable, but running it
is a manual, per-subject action, not automatic) — and, on this Linux dev
machine specifically, `7z`/`p7zip` needs to be installed for
`nexAtlas_runUnitMatch`'s waveform decompression step to do anything
(`nexAtlas_runUnitMatch.m`'s `resolveSevenZip_()` degrades gracefully but
silently if it's absent).

---

## 3. Reduce-mode (`nexHR`) runs *after* pool-mode has already collapsed other axes

**Status:** Not started, deliberately deferred. Discovered while wiring up
nested SWP sweep + time-window pooling for `mdlObj_lda`. Not being fixed for
now — routing around it instead (see "Resolution" below) — but the ordering
bug itself is still real and still latent for the next person who combines
reduce-mode and pool-mode axes in one `mdlObj`.

**Context:** A pMap axis with negative `divsPerBin` is reduce-mode (deferred
to `nexHR_fit`'s block-PCA, fit later on the assembled design matrix); an
axis with positive `divsPerBin` is pool-mode (collapsed immediately via
`splitapply(mean,...)` inside `nexOp_poolAxes`/`nexObj_poolMap.pool()`, at
STAT-compile time). The bug: if `domain.FTR` (e.g. `unit`) is reduce-mode
while another axis (e.g. `t`) is pool-mode, `t`'s pooling happens *first*,
inside `nexOp_compileSTAT`'s "AXIS POOLING" step — long before
`getDesignMatrix()` → `initReducer()` → `nexHR_fit` ever runs on `unit`. So
the block-PCA basis for `unit` gets fit using only the already-time-averaged
samples (e.g. 2 window-means per trial) instead of the full raw-timepoint
resolution — a real loss of statistical power/information for the reduction
step, not just a hypothetical.

**Why it's not a quick fix:** `nexHR_fit` needs `FTR_layout`
(`buildFTRLayout()`), which is derived from the *already-pooled* `STAT.ax`/
`.ptr` — reduction is architecturally tied to the fully-assembled, stacked
design matrix, not to raw per-trial DFs. Making reduce-mode actually run
before pool-mode would mean: splitting `nexOp_poolAxes`'s single per-field
loop into two real passes (resolve every reduce-mode axis's block-PCA basis
first, from a stack of *raw* per-trial DFs, before any pool-mode axis
collapses anything), computing `FTR_layout` from pre-pool axis info, and
relocating `nexHR_fit`'s call site out of `getDesignMatrix()`. That also
forces a decision this session's precompile work didn't have to make for
pooling: should the reduction basis be fit once and cached (like REG
alignment) or re-derived fresh every `compileSTAT()` call (like pooling
currently is, deliberately, so pMap edits after Compile still take effect)?
PCA fitting is expensive enough that "fresh every Fit" is a real cost pooling
never had to pay.

**Resolution (why this is deferred, not fixed):** realized mid-discussion
that this only bites when *incidental preprocessing* dimensionality
reduction is smuggled into a Predictor `mdlObj`'s own `pMap`. The codebase
already has the right tool for that case — the Phase-Based Pipeline
Convention (`mdlObj/CLAUDE.md`): fit/transform `unit` down to N components
explicitly via `mdlObj_pca` first (Phase 1, full raw-timepoint resolution,
no `t`-pooling of its own to conflict with), write the reduced dfID, then
point `mdlObj_lda` (Phase 2) at *that* dfID. `mdlObj_lda`'s own `pMap` then
only ever needs pool-mode for `t` — no reduce-mode axis left to collide with
it, no ordering bug triggered. `nexHR`/Reducer stays fully wired and
untouched for its actual intended use: hierarchical block-PCA as a
first-class analysis question in its own right (e.g. "how much variance does
each anatomical block explain, reduced within its own nested group"), not as
implicit preprocessing inside a classifier.

**Touches (if ever fixed for real):** `nexOp_poolAxes.m` (split the
per-field loop by mode), `nexOp_compileSTAT.m` ("AXIS POOLING" section),
`mdlObject.m` (`getDesignMatrix`/`initReducer`/`buildFTRLayout`),
`nexHR_fit.m`/`nexHR_transform.m` (would need to accept raw per-trial DFs
instead of an assembled `DM`), and a caching-lifetime decision mirroring
`precompiledAligned`.

**Depends on:** Nothing architecturally. Purely deferred by priority + the
existence of a working alternative (Phase 1/2 split) for the case that
surfaced it.

**Update:** superseded — actually needed after all (region-blocked unit
reduction is itself the analysis, not incidental preprocessing, so the
Phase 1/2 workaround above doesn't give per-region blocks the way `nexHR`'s
own layout does). Now being implemented for real; see entry 4.

---

## 4. `nexOp_stackByFTR` (and `fitReduce`/`applyReduce` built on it) only support a single FTR axis

**Status:** In progress, as part of implementing entry 3's real fix.
`nexOp_stackByFTR.m` is written and deliberately scoped to exactly one FTR
axis for now.

**Context:** `nexHR_fit`/`nexHR_transform` support a genuinely hierarchical,
multi-axis layout (recursing block-PCA across more than one feature axis at
once — see their own docstrings). `nexOp_stackByFTR(STAT, ftrAxis)`, needed
to feed them raw (pre-pool) stacked data so reduction happens before a
pool-mode axis collapses anything, currently takes a *single* axis name and
explicitly documents multi-axis FTR as unsupported. This matches every
actual caller today — `domain.FTR` has only ever been one axis in this
codebase — so it's not a regression, just a narrower implementation than
`nexHR_fit` itself is capable of.

**Design (when generalized):** `ftrAxis` becomes `ftrAxes` (ordered string
array, outermost-first — same convention `buildFTRLayout` already uses).
Per trial: resolve each axis's own `.ptr.(axis).dim` (still always by name,
never positional), move *all* of them to the trailing dimensions (in
`ftrAxes` order) instead of just one, fold every remaining dim into the
leading sample dimension exactly as now. The per-sample companion table `G`
construction (expand each folded-in axis's values, Nbefore/Nafter) doesn't
change in kind, just needs to skip every `ftrAxes` member instead of one.

**Touches:** `nexOp_stackByFTR.m`, and whatever in `mdlObject.m`
(`fitReduce`/`applyReduce`, once those land) passes it a single axis name
today.

**Depends on:** Entry 3 landing first (this is a narrowing within that
work, not a separate feature) — and an actual use case with more than one
reduce-mode FTR axis to design/test against, which doesn't exist yet.

---

## 5. `needsHR` reduce-then-pool is only wired up for `dmCfg.format == "supervised"`

**Status:** Not started beyond the `"supervised"` case. Surfaced while fixing
entry 3/4's plain-`fit()` path (the "Fit" button / `nexFigure_lda_visualize`'s
transform call) for `mdlObj_lda`.

**Context:** `nexOp_compileSTAT` skips *all* pMap pooling for a `needsHR`
mdlObj, unconditionally — the skip isn't gated on `dmCfg.format`. Two
consumers were updated to compensate with an explicit reduce-then-pool
sequence (`fitReduce`/`applyReduce` + `nexOp_poolStackedDM` +
`nexOp_quantizeY` + `nexOp_buildSupervisedDM`): `nexAnalysis_cvPermute.m`
(per fold/SWP) and `mdlObject.getDesignMatrix()`/`flattenInput()` (for a
plain, non-CV fit). Both gate the new path on
`strcmp(mdlObj.cfg.dmCfg.format, "supervised")` — `nexOp_buildSupervisedDM`'s
Y-encoding (`nexOp_labelEncode`, quantile bins via `nexOp_quantizeY`, `DM.K`)
is specific to that format, and `"supervised"` (LDA/logistic) is the only
format this sequence has actually been built and exercised against. Any
`mdlObj` with `dmCfg.format` = `"stack"`, `"batch"`, or `"regression"` *and*
a `needsHR` pMap (e.g. an SSM or CEBRA model with a reduce-mode FTR axis
coexisting with a pool-mode axis) still falls through to the old
`dmFcn`/`buildFTRLayout`/`initReducer` path — which, since
`nexOp_compileSTAT`'s pooling skip isn't format-gated either, still sees a
fully unpooled pool-mode axis for those formats. Same underlying bug as
entry 3, just not yet fixed outside `"supervised"`.

**Design (when generalized):** The reduce+pool half
(`fitReduce`/`applyReduce` → `nexOp_poolStackedDM`) is already format-agnostic
— it only produces `{X, G}`, no `Y`/label handling at all. What's
format-specific is exactly the DM-assembly tail: `"supervised"` needs
`nexOp_buildSupervisedDM` (X, quantized Y, K); `"stack"`/`"batch"` (SSM/CEBRA,
unsupervised) would need nothing more than `DM = X` directly, no Y step at
all; `"regression"` would need something between the two (continuous Y, no
quantization/label-encoding) — check `stat2dm_regression.m`'s own DM shape
before assuming `nexOp_buildSupervisedDM` can just be reused as-is. The
`strcmp(..., "supervised")` gates in `getDesignMatrix()`/`flattenInput()`/
`nexAnalysis_cvPermute.m` would become a dispatch on format instead (mirroring
how `dmFcn = str2func(sprintf("stat2dm_%s", ...))` already dispatches today).

**Touches:** `mdlObject.m` (`getDesignMatrix`, `flattenInput` — the
`strcmp(...,"supervised")` gates), `nexAnalysis_cvPermute.m` (same gate, if
it has one at the point this is read — check its needsHR branch), a new
format-specific DM-assembly helper per non-supervised format that needs one
(alongside `nexOp_buildSupervisedDM.m`).

**Depends on:** An actual `needsHR` use case in a non-`"supervised"` format
to design/test against — doesn't exist yet (this codebase's reduce-mode +
pool-mode combination has only been exercised via `mdlObj_lda`).

---

## 6. `nexObj_bar`: true 3D ("lego") nesting across two Pointer axes at once

**Status:** Not started. `nexVisualization_bar`/`nexOp_barStatFromScores`
now support nesting exactly ONE Pointer axis's multi-item selection as an
extra CTG-style tier (2D nested/clustered bars — `resolveExpandAxis` picks
the first qualifying axis by field order); any *other* axis with a
multi-item Pointer selection still collapses via mean, same as before this
landed.

**Context:** Came up discussing why multi-selecting a Pointer axis on the
bar chart just averaged the selected items together instead of showing them
as separate bars. The 2D case (one expanded axis, nested alongside CTG) was
implemented; a true two-axis version — bars arranged on an X×Y categorical
grid with height as Z, informally a "lego plot" — was explicitly deferred
as a bigger step: `bar3`/`bar3h` (MATLAB's own 3D-bar primitive) don't
support per-bar `FaceColor='flat'` + error bars the way the current
persistent `bar()`/`errorbar()`/`yline()` handle set does, so this would
mean hand-drawing 3D bars from patches — and the error-bar/null-band
comparison that's this chart's whole point gets much harder to read in 3D
regardless.

**Design (if pursued):** `resolveExpandAxis` would need to return up to two
axes instead of one; `nexOp_barStatFromScores` would need to expand along
both simultaneously (nested loop over both axes' kept indices, rather than
the current single `for j = 1:nItems` loop) instead of collapsing every
axis beyond the first; and the rendering side would need an actual 3D
drawing path (patches or `bar3`) plus a decision on how to still show
error/null-band information in that view — none of which exists today.

**Touches (anticipated):** `nexVisualization_bar.m` (`resolveExpandAxis`,
the rendering section — would likely become a real branch: 2D `bar()` path
vs. a new 3D path), `nexOp_barStatFromScores.m` (generalize the single
`expandAxis` to up to two).

**Depends on:** Nothing architecturally — deferred purely because the 2D
case covers the immediate need and the 3D rendering/error-display questions
above aren't resolved yet.

---

## 7. `nexObj_fitScope`: `readSlice()` doesn't check its own previously-saved output patch

**Status:** Not started. Surfaced while making `saveFit()`'s output format
robust (the unified `df`/`ax`/`df_fit`/`ax_fit`/`kernel` sibling patch,
keyed by the user-typed output label).

**Context:** `saveFit()` already reads-before-writes its OWN output patch
(`specparam_<label>`) so repeated saves — today, or reopening the same
label in a later session — accumulate into one growing `df_fit` volume
instead of clobbering each other. But `readSlice()` (which seeds the
spinner panel's starting values, at construction and nowhere else per the
"Pointer nav shouldn't reset hand-tuning" fix) only ever checks `dfID_ap`/
`dfID_pe` — the *pre-existing*, `nexFit_specParam`-produced batch patches
passed into the constructor. It never looks at whatever the user has
already saved under their own output label. So reopening `fitScope` on a
label you've been building up over several sessions currently starts every
slice back at the kernel's bare defaults (or the batch fit, if any) even
for a chan/t you already hand-tuned and saved last time — your own saved
work isn't visible until you happen to re-tune and re-save that exact slot
again.

**Design (if pursued):** Add a `dfID_fit` constructor arg/property (the
label-derived `specparam_<label>` patch — the SAME one `saveFit` writes,
not `dfID_ap`/`dfID_pe`) that's optional (empty until the first save, or
passed in directly to resume an existing label). `readSlice()` would check
it FIRST (highest priority — "what I already saved here" should win over
"what the batch pipeline produced"), falling through to the existing
`dfID_ap`/`dfID_pe` check, then the kernel's bare defaults, same as today.
Reading a slot out of `df_fit` just means indexing
`DF_fit.df_fit(ci, ti, :)` against `DF_fit.ax_fit.param` and building a
kernel_args struct from the name/value pairs — the literal inverse of
`spcpmIO_kernel2vector`, small enough it may not even need its own helper
file.

**Touches (anticipated):** `nexObj_fitScope.m` (`readSlice`, constructor —
new `dfID_fit` property/arg), `nexLaunchAdapt_fitScope.m` (would need to
pass/derive `dfID_fit` too, or leave it empty for a fresh launch).

**Depends on:** Nothing architecturally — deferred because the immediate
ask was making the SAVE side robust, not resuming a label across sessions
yet.

---

## 8. Migrate DTSIO's storage backend from HDF5 to Zarr (write fresh, don't convert old data)

**Status:** Not started, deliberately deferred — decided to stay on
single-writer/single-reader HDF5 for now and revisit this soon, rather than
adopt SWMR as the concurrency fix. Surfaced by a real bug: a second `nexon`
session (writing patches via `scaleApply_transform`) caused a first session's
INSPECT launcher "Refresh sources" to silently lose all *base* dfIDs (`lfp`,
`RTS_spk_activity`, ...) while patch dfIDs survived — and the same pattern
was independently observed in `nexObj_categorical`'s h5-backed category
listing.

**Context — what was actually verified before landing on this decision:**
- Root cause traced to `dtsIO_readDFIDs.m`: patch dfIDs come from parsing
  `h5_path_<dfID>` column names already on the DTS table (no I/O, can't
  fail); base dfIDs come *only* from a live `h5info` scan of the main file,
  wrapped in a silent `catch` (now fixed to log — see that file's current
  code — but the underlying cause was left as this entry, not patched away).
- Confirmed via an actual two-separate-MATLAB-process test (not just docs):
  plain `h5info`/`h5read` (no SWMR flag — this codebase's pattern
  everywhere) fails against a file another process has open for writing.
  This is expected, correct HDF5 behavior, not a bug in this codebase's use
  of it — HDF5 enforces exclusive-ish file locking by default absent SWMR.
- Scoped SWMR as the fix and confirmed it's technically viable here:
  installed HDF5 is 1.14.4 (well above the 1.10 SWMR minimum);
  `dtsIO_writeDF_toHDF5.m` and `dtsIO_readHDF5.m` are *already* on the
  low-level `H5F`/`H5D`/`H5P` API (for an unrelated fd-leak reason), so
  adding SWMR there is small; only 4 call sites
  (`dtsIO_readDFIDs.m`, `dtsIO_findSentinelRow.m` ×2, `mdlObject.m`'s
  `scaleApply_transform` skip-check) still use the high-level `h5info`,
  which has no SWMR flag and would each need a small low-level
  group-listing replacement. Verified the writer must flush once
  immediately after `H5F.start_swmr_write` before concurrent readers can
  reliably open the file (a real timing gotcha, not just a formality).
- Decided against SWMR anyway: it's fundamentally Single-**Writer**/Multiple-
  Reader — it would fix "one nexon writes, others browse," but does nothing
  for genuine multi-writer, and existing `.h5` files aren't retroactively
  SWMR-capable (libver bounds are a creation-time property — old files would
  need re-export regardless). Zarr was identified as the alternative that
  gets true multi-writer *and* multi-reader for free, structurally — each
  chunk is its own file/object, so concurrent writers touching different
  chunks never conflict at the filesystem level, no single-writer exception
  needed.

**Design — the key simplifying decision:** old data is being re-extracted
anyway right now, so **write newly-extracted data straight into Zarr and
leave existing HDF5-backed DTS manifests as-is** — no HDF5→Zarr conversion
path needed for old data. This sidesteps what would otherwise be the
hardest part of this migration (a lossless converter preserving `dim_order`,
per-axis attributes, chunking, and the `h5_path`/`h5_root`/`h5_path_<dfID>`
routing-column semantics for every existing session). A DTS row's storage
backend becomes a property of *when it was extracted*, not something that
needs unifying retroactively — old sessions keep reading through the
existing HDF5 path (`dtsIO_readHDF5.m`, unchanged), new sessions get a
parallel Zarr path. Whether DTSIO dispatches between the two backends by a
new manifest column (e.g. `zarr_path`/`zarr_root`, mirroring `h5_path`/
`h5_root`) or by some other per-row marker is an open question for when this
is actually scoped — not decided yet.

**Open questions to resolve before implementation (not yet scoped):**
1. No first-party MATLAB Zarr reader/writer exists. Two paths: (a) write a
   minimal native MATLAB Zarr implementation (the format itself — plain
   directories, JSON metadata (`.zarray`/`.zgroup`), raw/compressed binary
   chunks — is simple enough that a *minimal* reader/writer covering this
   codebase's actual access patterns is plausible, not a full spec
   implementation), or (b) route through `py.zarr` via the Python interop
   this codebase already leans on for CEBRA/sklearn — needs `zarr` added to
   the `nexus` conda env and a decision on whether per-trial-read
   performance through the Python bridge is acceptable for the real-time
   paths that currently read HDF5 directly in MATLAB.
2. Chunking/layout scheme: does each (trial, dfID) become its own Zarr
   array (closest mapping to today's per-trial HDF5 groups), or does this
   restructure toward one Zarr array per dfID with trial as a chunked
   dimension (fewer, larger arrays; different concurrency/access tradeoffs)?
3. How much of the *existing* DTSIO abstraction (`dtsIO_readDF`,
   `dtsIO_composeDF`, `dtsIO_listDFIDs`/`dtsIO_readDFIDs`, the `ptr`-based
   hyperslab-read convention) can be reused by writing a Zarr-backed sibling
   to `dtsIO_readHDF5.m`/`dtsIO_writeDF_toHDF5.m` behind the same interface,
   versus how much is HDF5-shaped enough (group hierarchy, `dim_order`
   attribute convention) to need rethinking for Zarr's own metadata model.

**Touches (anticipated):** new `dtsIO_writeDF_toZarr.m` / `dtsIO_readZarr.m`
(siblings to the existing HDF5 read/write pair), `dtsIO_readDF.m`/
`dtsIO_composeDF.m` (backend dispatch), `dtsIO_listDFIDs.m`/
`dtsIO_readDFIDs.m` (Zarr-side enumeration), `nexus_exportDTS.m` or
wherever the extraction pipeline currently calls into DTSIO's write path
(this is specifically about the *extraction* write target, not a DTS-wide
conversion), and `Setup/` (conda env — `zarr` package) if the Python-interop
route is chosen over a native reader.

**Depends on:** A concrete decision between the native-MATLAB-reader and
`py.zarr`-interop approaches (item 1 above) before any of the rest can be
scoped file-by-file the way SWMR was. The SWMR investigation above is the
direct predecessor context — same underlying problem, this is the chosen
long-term fix instead.

---

## 9. `nexObject.source` vs. `nexObject.Origin`/`Parent` — possible redundant reference pair

**Status:** Not started — parked as an open question, not a bug. Surfaced
while generalizing `nexObj_bar`'s mdlObj-source constructor wiring
(`resolveNexonFromSource`/`wireModelSource`) up to the `nexObject` base
class, which is what gave `source` its own first-class property there.

**Context:** `nexObject` now carries three properties that can each point
"outward" from an instance: `Parent` (the categorical/nexObject hub an
instance was built from), `Origin` (set alongside `Parent` in the usual
construction path — e.g. `nexObj_monoGram`'s constructor does
`nexObj.Origin = Parent.Origin` when `Parent` is non-empty, or
`nexObj.Origin = nexObj` when building from a bare `dfID_source`), and the
new `source` (set only via `wireModelSource`, when a viewer is constructed
directly off a live `mdlObject` instance rather than off a categorical
`Parent`/`dfID_source`). On the surface `source` reads like it could just be
another value `Origin` takes — one property, either shape.

**Why they were kept separate (analysis done, not yet revisited):**
- `Origin`/`Parent` carry a real, load-bearing type contract elsewhere in
  the codebase: always nexObject-family or occasionally the raw manifest
  `Nexon`, always compileSTAT-capable, always exposing `selectionBus`/
  `DF_postOp`. Existing call sites (e.g. `mdlObj.Origin.selectionBus.categories`)
  assume this shape unconditionally, with no type check first.
- `source` points at an `mdlObject` — a genuinely different class hierarchy
  that exposes none of that shape (no `selectionBus`, no `DF_postOp` in the
  same sense). Repurposing `Origin` to sometimes hold an mdlObj would
  silently break every existing `Origin.selectionBus...`-style call site the
  first time it happened to hold one.
- Checked whether they're ever populated simultaneously for the same
  instance today: they aren't. `nexObj_bar`'s constructor explicitly passes
  `Parent=[]` (and never sets `Origin`) on the source-watching path — so
  today `source` and `Origin`/`Parent` are mutually exclusive alternates for
  two different construction modes (built-from-categorical-hub vs.
  built-from-live-mdlObj), not two overlapping references describing the
  same mode. That made "just merge them" not obviously a net win: it would
  trade one property for a type-checked union plus defensive guards at every
  existing `Origin.<nexObject-only-member>` call site.

**Design (deferred — this is the actual open question):** whether a more
parsimonious contract exists once there's more than one construction mode
relying on this pattern — e.g. a single "source" concept typed as a tagged
union/duck-typed dispatch (nexObject-family vs. mdlObject-family), with
`Origin`'s current call sites updated to check shape before assuming
nexObject members — versus leaving them as two deliberately separate,
mutually-exclusive properties (current state) on the grounds that the
type contracts are different enough that merging just relocates the
type-checking rather than removing it. Revisit once there's a second
source-typed construction path (beyond mdlObj) to see whether the pattern
generalizes or whether mdlObj really is a one-off.

**Touches (anticipated, if ever merged):** `nexObject.m` (`Origin`/`source`
properties, `resolveNexonFromSource`/`wireModelSource`), every current
`Origin.<member>` call site across nexObj subclasses (would need shape
guards), `nexObj_bar.m`/`nexObj_monoGram.m` constructors (the two current
`source`-path callers).

**Depends on:** Nothing architecturally — deferred purely because it's a
"revisit once there's more evidence" question, not a known-wrong design.

---

## 10. Subject-specific region pooling (`pMap.getBinEdges`) for multi-subject STAT

**Status:** In progress — design settled, implementing now.

**Context:** Discovered while chasing a chain of multi-subject canonicalization
bugs in `nexOp_compileSTAT`/`mdlObject.compileSTAT`/`nexAnalysis_cvPermute`
(per-subject REG width desync, `applyDomainMSR`'s broadcast clobber — both
fixed). Verifying those fixes surfaced a deeper, previously-invisible issue:
region-mode channel→region binning (`nexObj_poolMap.getBinEdges`'s `mapID`
branch, used by `nexHR_fit`'s block-PCA and by plain `nexOp_poolAxes`
pooling) is **not subject-specific at all**. `poolMap.Map` is a single fixed
table, built *once* at `nexObj` construction time
(`nexInit_pMap.m:20-24`, `regMap = nexon.console.NPXLS.shanks.shank1.regMap`
— whatever subject happened to be live in the NPXLS UI panel at that exact
moment), then reused unchanged, via a shared handle
(`mdlObject.m:88`, `mdlObj.pMap = mdlObj.Origin.pMap`), for every subsequent
subject `nexAnalysis_cvPermute` ever processes. Raw channel 45 silently gets
whichever region label was true for one captured subject, applied blindly to
every other subject's channel 45 — the same class of bug as the REG-width
desync, one step further downstream (label assignment, not identity-matching).

**The data needed to fix this already exists** —
`nexon.console.BASE.registry.SUBJ.(subjKey).regMap` (`subjKey` =
`"subj_" + subj-string with '-'→'_'`), populated for *every* subject up front
at registry-init time (`nexInit_registry.m:56-83`) from that subject's own
`.../Subjects/<subject>/npxls/trajectory/imec0/map_channel-region.mat` — a
real per-subject histology/trajectory file, not a shared default. This is
the same table `nex_axisColorFromRegistry.m`/`nexOp_selectedSubjectsRegMap.m`
already use for per-subject region *color* lookups (a different consumer of
the same registry).

**Design — three cases, one mechanism (`subj_internal`), one real
restructuring:**

1. **`subj_internal`** — a new STAT column, not a separately-tracked
   peripheral array. Built once in `nexOp_compileSTAT.m` from the *existing*
   `subjID` (already read directly from DTS via
   `dtsIO_readTF_category(nexon, "sessionLabel--subj", idxSel)`, independent
   of whatever categories are selected in the UI — this was already built
   for the within-subject REG canonicalization work and just needs reuse,
   not re-derivation). Assigned onto `STAT` alongside `Y.trialNumber` (after
   `idx_sort`, so it's already in final row order) so it rides through every
   later row-reordering/subsetting STAT undergoes (`idx_sort`, CTG combo
   masking, fold masking, `applyPointer`, `applyDomainMSR`) automatically —
   a real table column is immune to the whole class of desync bug a
   hand-maintained parallel array would reintroduce (exactly what
   `applyDomainMSR`'s broadcast bug was). Excluded from `nexObject`'s
   CTG/VW-selectable candidate lists (the existing `DF_STRUCT_FIELDS`-style
   exclusion arrays already present at several spots in `nexObject.m`) so it
   never surfaces as a spurious selectable category. No exclusion needed on
   the `mdlObj` side — its CTG candidates come from
   `Origin.selectionBus.categories`, not from `STAT.Properties.VariableNames`,
   so `subj_internal` can't leak in there regardless.

2. **`nexObj_poolMap.getBinEdges(poolMap, axis, divsPerBinOverride, subjID)`**
   — new optional 4th arg. When given (and `poolMap.axID` is a
   registry-backed hook — today only `'chans'`, mirroring
   `nex_axisColorFromRegistry`'s own axis routing; generalizes to any future
   axis with a `registry.SUBJ.*` entry), resolve the *correct* `Map` table
   from the registry for that subject instead of `poolMap.Map` — same
   non-mutating style the existing `divsPerBinOverride` already uses (falls
   back to `poolMap.Map` on any lookup failure, with a log line so the
   fallback is visible, never silent).

3. **Three cases for threading `subj_internal` through, NOT symmetric —
   this is the part that isn't just "pass an argument everywhere":**
   - **`~needsHR`** (plain `nexOp_poolAxes`, called per-DF via `cellfun` in
     `nexOp_compileSTAT`'s "AXIS POOLING" step): no restructuring. Each DF
     already gets pooled independently and already has a known subject
     (`subjID(i)`) — switch to an indexed loop, pass that DF's own subject
     straight into `getBinEdges`. No merging, no ambiguity — each call binds
     exactly one DF to exactly one subject's table.
   - **`needsHR` + subject in CTG**: no restructuring either. Every CTG
     combo (and therefore every fold's `STAT_train`/`STAT_test`) is
     subject-pure by construction — `nexHR_fit` already only ever sees one
     subject's data per call. Just replace the stale/wrong-subject
     `pMap.chans.Map` with the *combo's actual* subject via
     `STAT_train.subj_internal` — purely the lookup-correctness fix, same
     mechanism as case 1.
   - **`needsHR` + subject NOT in CTG** (genuine cross-subject pooling, one
     fit spans multiple subjects): **this is the real architectural gap.**
     `nexHR_fit` computes one set of block boundaries and fits one PCA basis
     per block, once, for the *entire* stacked `X_raw` — every row (sample,
     any subject) sharing one column/feature layout. If subject A's channels
     1-10 are genuinely STN and subject B's channels 1-10 are genuinely HY,
     there is no single call where "switch to the right regMap" has
     anywhere to attach — block *structure itself* would need to differ
     per subject, which `nexHR_fit`'s signature (one `binEdges` per call)
     cannot express. Merging regMaps first (vertcat, first-occurrence-wins —
     the convention `nexOp_selectedSubjectsRegMap.m` already uses for color
     lookups) was considered and rejected: it produces *a* coherent block
     structure, but a column range that's genuinely two different regions
     across subjects still gets collapsed into one arbitrary label, and the
     resulting block-PCA basis would be fit across what is actually a mix of
     two anatomically different signals. The real fix: **wrap `nexHR_fit` in
     an outer per-subject loop** (hardcoded, not a generalized
     "any grouping axis" abstraction, for now) — split `STAT_train`/`X_raw`
     by `subj_internal`, run `fitReduce`/`nexHR_fit` separately per subject
     (each with its own `regMap`, own block boundaries, own fitted PCA basis
     per region), producing per-subject reduced output labeled by **region
     name** (e.g. `STN_pc1`, `HY_pc1`) instead of raw channel index. *Then*
     canonicalize/union those per-subject region-labeled outputs across
     subjects — the same hierarchical per-subject-then-across-subjects
     pattern already used for raw REG identity, just one tier higher, after
     reduction instead of before it. One real wrinkle in the combine step:
     `nexHR_fit` clamps `nComp_actual` per region to that subject's own
     available units/samples, so the *same* region can come out with a
     different component count per subject (e.g. `STN_pc1-3` for one
     subject, `STN_pc1-2` for another) — reconcile by padding the shorter
     one with NaN up to the union's max-per-region width, reusing the exact
     convention `Wfull`'s own consolidation step in `nexAnalysis_cvPermute.m`
     already established (NaN, not zero or drop, so every NaN-aware
     downstream consumer — `mean`/`std` `'omitnan'` — already treats it
     correctly as "no data" rather than "zero signal").

4. **Relocate the Pointer-bus second-tier union to run post-pooling, by
   region name, not pre-pooling by raw channel index.** The cross-subject
   union built earlier this session (`pointerSeedDF`/`repDFs` in
   `nexOp_compileSTAT.m`'s per-subject alignment branch; the `applySRC`
   row-union fix in `nexObject.m`) currently operates on `TF`/`TF_aligned` —
   raw-channel-canonicalized, pre-pooling. For the union to reflect region
   *names* the way this design intends, it needs to run on `TF_pooled`
   (post-pooling) instead — `nexOp_alignCoAxes` already coerces non-numeric
   REG values to string for its union (confirmed in its own code), so once
   it's pointed at the right (post-pooling) data, region-name unioning falls
   out with no further changes to `alignCoAxes` itself. For the lighter,
   decoupled `refreshPointerFromPool`/`nexOp_poolAx` path (which exists
   specifically to stay cheap and separate from the real `TF_pooled` data
   pass), the same subject-awareness needs to land there too, independently
   — not via waiting on `TF_pooled`, to preserve that path's own reason for
   existing.

**Touches:** `nexObj_poolMap.m` (`getBinEdges`, new resolver), `nexInit_pMap.m`
(no change expected — construction-time `Map` stays as today's fallback),
`nexOp_compileSTAT.m` (`subj_internal` column, per-DF `subjID` threading into
`nexOp_poolAxes`, relocating the Pointer-union to post-pooling),
`nexObject.m` (CTG/VW exclusion lists, `applySRC`'s union fix point),
`mdlObject.m` (`fitReduce`/`applyReduce`/`initReducer`, `refreshPointerFromPool`),
`nexHR_fit.m` (accept a resolved `regMap`/subject context per call),
`nexAnalysis_cvPermute.m` (the `needsHR` branch's fold-outer section — the
real restructuring: split-by-subject, per-subject `fitReduce`, combine by
region name before the rest of the SWP/LDA machinery runs — everything
downstream of that combine step is unchanged, it just sees one well-formed
matrix like it does today).

**Depends on:** Nothing architecturally — the registry data this needs
already exists and is already populated per-subject at registry-init time.

---

## 11. Feature axis as a first-class, coIdx-registered identity + `blockColRanges` shape bug (WIP #10 follow-on)

**Status:** In progress — design settled, implementing now.

**Context:** Built on #10's per-combo `R.featureLabels` companion
(`nexAnalysis_cvPermute.m`'s `if hasW` block — labels each reduced feature
column by the real region/band identity it represents). Goal: make that
identity drive Nexus's existing co-registration machinery (`DF.coIdx`/
`nexOp_coIndexPairs`) so a results viewer (`nexObj_bar`, `nexObj_monoGram`)
can select/color by feature identity automatically, the way `chans`/`unit`
already do — rather than requiring new per-viewer special-casing.

**The problem collapses to FTR-swept vs. FTR-not-swept, and coIdx is only
correct in one of them:**

- **FTR swept** — each swept value (e.g. region `"STN"`) gets its own PCA
  basis fit on just that value's own population. `"STN"`'s component 1 and
  `"HY"`'s component 1 aren't the same index wearing two labels — they're
  unrelated bases that happen to share a column slot in the padded `Wfull`
  array purely for rectangular storage (confirmed from `Wfull`'s own
  construction: `[nFeatures x nFolds x nPerm x nSwpPerAxis...]`, feature and
  the swept axis are independent array dimensions). So `ax_W.feature` can
  only ever be a combo-invariant ROLE label (`"pc1","pc2",...`), never an
  absolute identity, and there is no `coIdx` pairing to make here — `coIdx`
  means "two names for the same index," which isn't true of two orthogonal
  array dimensions. The one true per-cell fact ("slot 2 under STN is STN's
  own 2nd PC") is inescapably 2-D (`feature × swept-value`) and lives in
  `R.featureLabels` instead, which is deliberately NOT a Pointer axis —
  Nexus's axis/coIdx machinery has no slot for a label that depends on which
  value of a *different* axis you're also looking at. **This branch stays
  as-is** (already landed under #10); no coIdx work applies here.
- **FTR not swept** — there's exactly one feature vector (every region's/
  band's components laid out once, fixed order, no competing basis). Column
  `k` always corresponds to exactly one region/band, every time — so
  "feature" and "which identity fed this column" are two names for the
  identical index, structurally the same relationship `chans`/`unit`
  already have. This genuinely is the textbook `coIdx` case, not just a
  convenient same-shaped sibling.

**Fix — three pieces:**

1. **`nexAnalysis_cvPermute.m`'s `if hasW` block (non-swept branch only)**:
   `ax_W.feature` carries the full embodied label (`"STN_pc1"`, bare
   `"delta"` for a single-component block, from `blockColRanges_full`) —
   PLUS a new `ax_W.(char(ftrAxisStr))` sibling, same length, holding just
   the base identity per position (no `_pcN` suffix) — set unconditionally
   (not gated on whether `ftrAxisStr` happens to be one of the four
   registry-colorable names; "unambiguous which axis fed the feature space"
   holds regardless, color resolution is a bonus that activates
   automatically when it matches). Swept branch: `ax_W.feature` becomes
   `"pc1","pc2",...` instead of a bare numeric index (cosmetic — same
   combo-invariant-role meaning as today, just labeled).

2. **`nexOp_coIndexPairs.m`**: added `{'feature','chans'}`,
   `{'feature','unit'}`, `{'feature','f'}`, `{'feature','map'}`,
   `{'feature','dropout'}` to `allPairs`. Confirmed NOT redundant with
   `{'chans','unit'}` already being present — `nexVis_resolveClrAxis`
   (`nexVisualization_monoGram.m:330-346`) only checks one pair deep from
   whatever key it's resolving, so `feature`→`chans`→`unit` does not chain
   implicitly; `unit` needed its own explicit `feature` pair.
   **Accepted tradeoff, deliberately not re-architected**: `.coIdx` in this
   codebase is a *cache* of this same global whitelist, not a
   self-discovering in-situ registry — `dtsIO_composeDF.m` sets
   `DF.coIdx = nexOp_coIndexPairs(DF.ax)` (literally calls the hardcoded-list
   function), and `nexVis_resolveClrAxis` doesn't even read a stored
   `.coIdx` — it calls `nexOp_coIndexPairs(ax)` fresh every time. So a
   locally-stamped `Rw.coIdx` pair (e.g. for a hypothetical future FTR
   identity not in `allPairs`, like `"t"`) would be invisible to monoGram's
   actual coloring resolution regardless of where it's stamped. Considered
   and rejected: inferring pairs from axis co-presence/length instead of
   enumeration — `nex_initAxisPointer_v2` already rejected that approach for
   the same reason (same-length-and-present isn't sufficient evidence of
   same-index; `nex_coIndexAxisLabels()` is an explicit allowlist for
   exactly this reason). Net: adding a new FTR identity type in the future
   costs one `allPairs` line, same maintenance cost `{'chans','unit'}`
   already has — not a newly-introduced brittleness.

3. **`mdlObject.fitReduceMultiSubject_`** — a related but separate bug,
   surfaced while re-deriving the swept-case `R.featureLabels` logic against
   the actual multi-subject path: `blockColRanges` returned from this method
   is a `struct('bySubject',true,'perSubject',{...})` wrapper, but EVERY
   real consumer (`resolveSWPMaskHR` in `nexAnalysis_cvPermute.m`,
   `nexAudit_blockVariance.m`, and #10's `R.featureLabels` code) expects the
   flat `.label`/`.cols` shape `fitReduce`'s single-subject path returns.
   `blockColRanges.bySubject` is never actually read anywhere (confirmed
   codebase-wide — only `HR.bySubject` and `fitSentinel.bySubject` are), so
   nothing needs the wrapper shape for this one return value.
   `resolveSWPMaskHR` would hard-crash (`Reference to non-existent field
   'cols'`) — independent of whether FTR is swept — the first time ANY fit
   call's `STAT.subj_internal` has more than one unique subject not
   otherwise separated by CTG/SWP (e.g. a fold's own train split happens to
   mix two subjects). Fix: build the flat shape directly over the UNION
   columns — group `unionLabels` by base region/band name (stripping the
   `_pcN` suffix) and collect ALL matching union-column indices per label
   via `find(...)`, NOT assumed contiguous (`unique(...,'stable')` can
   append a later subject's extra component for an already-seen region
   after a different region's label was already inserted — e.g. union
   `["STN_pc1","STN_pc2","HY_pc1","STN_pc3"]` leaves STN's columns as the
   non-adjacent `[1,2,4]`). `HR`/`layout` keep their per-subject wrapper
   (genuinely needed by `applyReduceMultiSubject_` for correct per-subject
   transform) — only `blockColRanges` changes shape.
   **Flagged, not fixed:** `nexAudit_blockVariance.m` also assumes `HR` is a
   flat cell (`HR{b}.reducer...`), which would hit the same class of break
   on `HR`'s own wrapper when `auditOn` + multi-subject-sharing-one-combo
   coincide. Left alone — fixing it means either giving up `HR`'s genuinely-
   needed per-subject structure, or writing an audit-specific unwrap, not
   requested.

**Touches:** `nexAnalysis_cvPermute.m` (`if hasW` block),
`nexOp_coIndexPairs.m` (`allPairs`), `mdlObject.m`
(`fitReduceMultiSubject_`).

**Depends on:** #10 (`subj_internal`, `fitReduceMultiSubject_`,
`R.featureLabels` — all already landed).

---

## 12. Mixed-Effects Modeling for Nexus — generalizable architecture notes (running log)

**Status:** In progress — building MVP diagnostic visualizations now (day 1
of a ~3-day push). Unlike this doc's other entries, this one is a *running
log*, not a single deferred design — appended to as generalizable patterns
surface while building, not written once and implemented later. Treat each
numbered observation below as independently pick-up-able.

**Context:** Follows directly from a long debugging arc (pseudoreplication
fix, `nexOp_stackSTAT` struct-array gap, per-subject region/band pooling —
this doc's #10 — and a `compileSTAT()` trim/broadcast bug fixed generically
for any `mapID`-pooled axis, not just `chans`) that produced a working
standalone-function pipeline: `build_bandPowerRegionTable` →
`build_bandHierarchy` (per-cell `m0`/`m1`/`m2` `fitlme` hierarchy + BH-FDR)
→ `run_mixedEffectPipeline` (CCI × side stratification) →
`plot_bandHierarchyGrid`/`compute_bandHierarchyClim` (shared-scale dark-mode
heatmaps), all under `Analysis/Statistics/MixedEffect/`. The current goal is
promoting this from "functions that happen to take an `mdlObj`" toward a
properly Nexus-integrated capability — eventually a `nexObject`-level
implementation once the pattern stabilizes (see observation 3) — while
building two MVP diagnostic figure types that make a heatmap cell traceable
back to real per-trial data: (1) an `m0`→`m1`→`m2` per-subject trajectory
figure (intercepts/fixed-slope/random-slope, spaghetti-plot convention) and
(2) a `nexDraw_violin`-based per-cell scatter (trial-level `bandPower`,
condition × subject), eventually scanned via `collector.Domain`/
`collector.Pointer` instead of explicit function arguments.

**Generalizable observations (append more below as found):**

1. **CTG combo selection already *is* the stratification mechanism — it
   just hadn't been named as such.** Building the long-format table only
   required selecting `sessionLabel_subj` and `sessionLabel_phase` as
   categories; nearly every mixed-effects question asked so far (per-subject
   random effects, the CCI × side four-way stratification) turned out to
   already be expressible as "which CTG combo(s) is this STAT restricted
   to." The CTG selection bus isn't just a filter upstream of the modeling —
   it's functioning as the actual **experimental-design specification**:
   it jointly determines the scientific question (what's held fixed vs.
   compared), the model structure (what `subject`/`condition` even mean in
   a given `fitlme` call), and what the visualization is allowed to show.
   Worth exploiting explicitly rather than re-deriving `side`/`cci`-style
   boolean columns ad hoc per analysis, as `build_bandPowerRegionTable.m`
   currently does for `sessionLabel_phase`.

2. **`collector.Domain`/`collector.Pointer` is the natural mechanism for
   per-cell navigation (band × region × t), deferred for now, not
   abandoned.** Scanning a `plot_bandHierarchyGrid` cell's underlying trial
   data should eventually reuse the same Pointer-bus windowing every other
   Nexus visualization already uses, rather than a bespoke
   `(band, region, t)` argument triple — but it has the most
   infrastructure-wiring dependency of anything in this build, so day-1 MVP
   diagnostic figures are plain callable functions first; Pointer wiring
   comes once both figure types exist and their actual input needs are
   known, not designed blind.

3. **`nexObj_monoGram`'s dual-mode is a constructor-time boolean, not a
   per-render branch — real precedent, but less exotic than it first
   looks.** `isMdlSource = ~isempty(Parent) && isa(Parent,'mdlObject')`
   (`nexObj_monoGram.m:36`) picks one of two *setup* paths once, at
   construction (seeds `DF_postOp`/`pMap`/collector scaffolding
   differently); `visualize()`/`updateScope()`/`operate()` are identical
   code for both modes afterward. Honest caveat: the "pure visualization"
   branch is really the *generic* `SRC=RESULTS.key` pathway every
   nexObject already gets for free (VW+Pointer navigating an
   already-computed table — standard per `nexObj/CLAUDE.md`), not something
   `monoGram` invented. Still the right structural precedent for the
   eventual mixed-effects nexObject — branch the constructor on `Parent`'s
   class, share the render path — just budget for "one class, two
   constructors sharing a render function," not more than that.

4. **`nexDraw_violin` vs. `nexVisualization_bar`'s "liveness" — the
   valuable half is free, the real half is a deferrable optimization.**
   Investigated directly (`nexVisualization_bar.m`, `nexObj_bar.m`): the
   redraw *trigger* (Pointer/Domain selection change → redraw) isn't
   bar-specific at all — it's the standard nexObject
   selection-change→`updateScope()`→`visualize()` chain every object gets,
   and `nexDraw_violin` could hook into that exact same free mechanism
   whenever Pointer wiring (observation 2) actually lands. What IS
   bar-specific: persistent plot handles mutated in place
   (`set(hBar,'XData',...)`) instead of `cla()`+rebuild. `nexDraw_violin`
   today always does the latter (confirmed: its one real caller,
   `nexObj_categorical.drawCanvas()`, calls `nexDraw_clearViolin()` before
   every call; no re-entry path exists) — same convention
   `nexObj_categorical` already ships with, not a shortfall unique to it.
   Correction to the earlier framing here: `nexVisualization_bar` does NOT
   do true 3-D "lego" nesting — its own header comment and WIP #6 both say
   this directly; what exists is N Pointer axes as flat stacked label
   tiers under a 1-D bar chart. **Practical conclusion: the day-1 violin
   diagnostic needs zero "liveness" work** — call `nexDraw_violin` plainly,
   once per cell, `cla()`+rebuild and all. Persistent-handle updates are a
   targeted performance optimization worth revisiting specifically when
   Pointer-driven scanning is actually being built, not before.

5. **Two nexObjects sharing a contract, not one nexObject swapping render
   modes — and the contract needs two granularities, not one.** Considered
   upgrading `nexObj_bar` to alternate bar/violin rendering vs. a separate
   `nexObj_violin` (plus `nexObj_trajectory` for the `m0`/`m1`/`m2` figure)
   reading a shared `R`/STAT contract. Observation 4's finding settles
   this: violin's `violinplot` patch-based object model doesn't map onto
   bar's single-mutable-handle liveness trick, so "add a mode flag to
   `nexObj_bar`" would fight violin's actual rendering mechanics rather
   than reuse them — two objects is the sounder bet. But the contract
   itself isn't as simple as "one `R` shape both read": `nexObj_trajectory`
   needs *fitted* per-(subject x condition) values (`predict()` output,
   doesn't exist pre-fit) while `nexObj_violin` needs *raw* per-trial
   values (the model's input, pre-fit) — different granularities, not
   just different renderings of the same rows. The existing multi-facet
   `RESULTS`-row convention (`df` alongside `W`/`ax_W`/`ptr_W`, the mdlObj
   weights facet — WIP #11, `nexObj/CLAUDE.md`) is the natural mechanism to
   extend rather than reinvent: a `df` facet (raw trial rows, what
   `nexObj_violin` reads) plus a new fitted-value facet (per-subject/
   per-condition `predict()` output, what `nexObj_trajectory` reads) on the
   same `R` row. Not yet designed in detail — flagged here so the eventual
   nexObject work starts from this shape instead of rediscovering the
   granularity mismatch mid-implementation.

6. **Mixed-effects modeling should itself become an `mdlObj` (e.g.
   `mdlObj_MEM`), with `nexObj_violin`/`nexObj_trajectory` relating to it
   the same way `nexObj_bar` already relates to `mdlObj_lda` — and this is
   not hypothetical, it's already proven working in this exact session.**
   `bar=nexon.UserData.launchedFigures{1,4}; bar.loadResult('cv_...')`
   (used earlier this session to debug `nexOp_loadResult`'s cell-vs-double
   `h5readNumLL` bug) is `nexObj_bar` pointed at a *different* mdlObj's
   (the LDA's) saved RESULTS via the standard `nexOp_saveResult`/
   `nexOp_loadResult` HDF5 contract. `nexObj_violin` could reuse that exact
   mechanism for `mdlObj_MEM`: `mdlObj_MEM.fit()` writes RESULTS through
   the same `nexOp_saveResult` path (extended with observation 5's
   multi-facet df + fitted-value shape), `nexObj_violin`/`nexObj_trajectory`
   call `.loadResult()` against it exactly like `bar` does today — no new
   save/load plumbing, reusing a path already debugged and confirmed
   working. Becoming a proper `mdlObj` also means `compileSTAT()` ⟵
   `build_bandPowerRegionTable`'s logic, `fit()` ⟵ the `m0`/`m1`/`m2` grid,
   and the CTG/Pointer/Domain buses (observations 1, 2) attach to
   something that already expects them, not bespoke wiring.
   **Open question, deliberately not resolved here:** which figure is the
   *head* figure — trajectory (needs one cell already selected to mean
   anything; would need a sensible default cell to show anything on open)
   or the heatmap grid (meaningful immediately, zero selection needed;
   trajectory becomes the Pointer-driven drill-down once observation 2
   lands)? Matches the established `mdlObj` convention
   (`nexFigure_lda`-style: head figure = primary, always-meaningful
   overview) better if the grid is the head and trajectory is secondary —
   worth deciding deliberately before building the figure, not defaulting
   into it.

7. **The DN vs. SWP distinction, crystallized while actually building
   `mdlObj_lme`'s grid (observation 6's `mdlObj_MEM` is now real, named
   `mdlObj_lme`).** Verified directly in `nexAnalysis_cvPermute.m`'s own
   fold×SWP loop (not just its doc comment — the actual `for si = 1:nSwp`
   body): `mdlObj.STAT = STAT_si; mdlObj.getDesignMatrix();
   mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);` — a genuinely separate `fit()`
   call per SWP combo, assembled into one array indexed by the combo
   axes afterward. That's structurally a multiple-comparisons design —
   one independent, correction-pooled test per sub-cell — not a single
   fit that sees the whole domain jointly. `domain.DN` is the opposite
   role: the axis(es) ONE fit sees at once, which is what lets a model
   learn something that spans the domain (a trajectory over time, a
   spatial pattern over channels) rather than one independent answer per
   slice. `mdlObj_lme`'s grid (band/chans/t, one independent `fitlme`
   chain per cell) is unambiguously SWP-shaped, not DN-shaped — so
   `domain.SWP` is what it reads for grid dimensions (subsuming a
   short-lived standalone "Grid columns" text field in `nexFigure_lme.m`,
   now removed). LME doesn't actually have a DN-shaped need to begin
   with: a trial already *is* the sample (fixed by `compileSTAT`, not an
   axis choice), so there's no axis playing DN's role even before asking
   whether overloading it would be safe.

   **Forward-looking, not yet started:** this SWP-vs-DN framing
   (independent-per-cell vs. joint-across-domain) is the right lens to
   check a future neural-network-backed `mdlObj` (e.g. TensorFlow under
   the hood) against. The entire appeal of a NN over per-cell LME would
   be learning something that spans band/chans/t *jointly* — a true
   spatial/temporal pattern, not N independent cell-wise answers — which
   is exactly DN's existing role, not SWP's. Worth deciding deliberately
   against this framing when that work actually starts, not re-deriving
   it from scratch.

8. **REG's candidate list was needlessly coupled to FTR — fixed — and
   genuine multi-axis co-registration is a real, separate future need,
   deliberately deferred.** Surfaced while defaulting `mdlObj_lme`'s FTR
   to "None" (LME has no feature-axis consumer): `nexOp_computeREGOptions`
   restricted REG's dropdown to co-indexed partners of the CURRENTLY-
   SELECTED FTR axis, so FTR="None" collapsed REG down to "None" only —
   blocking REG="chans"/"unit" even when cross-session channel/unit
   identity genuinely needs canonicalizing (e.g. firing-rate/unit work).
   Verified directly in `nexOp_alignCoAxes.m` that this coupling was pure
   UI artifact, not a real dependency — the actual alignment logic reads
   only `domain.REG`'s own value plus its own internally-resolved
   co-indexed sibling (`nexOp_coIndexPairs`), never `domain.FTR`. Fixed:
   `nexOp_computeREGOptions` now returns every real axis except
   `t`/`latent`, regardless of FTR. REG itself stays single-select
   (`nexOp_alignCoAxes`/`nexOp_compileSTAT` both take it as one scalar
   axis name) — picking either half of a co-indexed pair (e.g. `chans` or
   `unit`) already canonicalizes both, so this covers today's actual
   need. **Deferred, not started:** genuinely INDEPENDENT multi-axis
   canonicalization (several axes at once, not just resolving one
   co-indexed pair) — would need real changes to `nexOp_alignCoAxes`/
   `nexOp_compileSTAT`'s core shared logic, not just the REG bus/UI.
   Revisit when a concrete use case actually needs two unrelated axes
   canonicalized simultaneously, not before.

9. **`isfield()` on a `nexObj_ptr` always returns false, same pitfall
   family as `DF_postOp`/`collector.Domain`, despite `nexObj_ptr` using
   `dynamicprops` (which is *supposed* to be the exception) — verified by
   direct test, not assumed.** Hit this as a real, blocking bug in
   `buildLongSTAT.m`'s `resolveFeatureAxis` (`isfield(ptr_ref, f) &&
   isequal(ptr_ref.(f).dim, 2)` — always false, "no feature axis found"
   even when the real `STAT.ptr(1).f.dim` correctly held `2`). Fixed there
   with the same `ismember(f, fieldnames(ptr_ref))` workaround used
   elsewhere for this pitfall family. **Not fixed, logged instead:**
   `nexOp_stackSTAT.m` line ~69 has the exact same broken pattern
   (`isfield(ptr_ref, f)`) — never surfaced visibly there because its
   consequence is benign (`fAxes` stays empty, so nothing gets excluded
   from `G_stack`'s column expansion — the feature axis's own values just
   become one redundant extra `G` column nothing downstream minds). Left
   alone deliberately: proven, heavily-depended-on code
   (`nexAnalysis_cvPermute`, `build_bandPowerRegionTable`), zero current
   symptom to justify touching it. Worth fixing opportunistically if that
   function is ever modified for an unrelated reason, not proactively.

10. **`computeSignificance`'s `tooFewGroups` skip (and the plain
    `height(Tc) < 10` one right next to it) fail silently -- no print,
    unlike the `fitlme`-error catch branch right below them which does.**
    Surfaced in testing: `domain.CTG` had been set to include
    `sessionLabel_subj` -- the SAME variable the chain's random effect
    groups on (`(1|sessionLabel_subj)`) -- so every combo ended up with
    exactly one subject, `tooFewGroups` correctly fired on every single
    grid cell (a random effect needs multiple groups to estimate any
    variance across), and the result was silently all-`NaN` with zero
    console explanation for why. The guard's LOGIC is correct; it just
    doesn't announce itself the way this project's own established
    convention requires (every other statistical skip/decision in this
    session's work prints or annotates why -- `build_bandHierarchy.m`'s
    "too little data", the paired-comparison test choice, etc.). Fix:
    add an `fprintf` to both skip branches (cell index, reason, and for
    `tooFewGroups` specifically, name the grouping variable and its
    single remaining value) mirroring the existing `catch ME` branch's
    own message. Deliberately not done yet -- user explicitly deferred
    it ("that's ok for now... we'll put it in later") rather than asking
    for it mid-session.

11. **`STAT.trialNumber` is NOT a globally-unique trial key within one
    combo-child's own STAT -- it resets to 1 at the start of every
    recording session, and one CTG stratum routinely spans several
    sessions for the same subject.** Surfaced via the exact same kind of
    live debugging as observation 10: `buildLongSTAT`'s per-trial
    quantization step (dedupe-then-broadcast, so the quantile cutoff is
    computed from one value per real trial, not once per expanded
    band/chans/t row) was deduping on `G.trialNumber` alone. Confirmed
    directly on real data: `find(STAT.sessionLabel_subj=="<subj>" &
    STAT.trialNumber==1)` returned 4 separate STAT rows for one subject
    within one stratum -- 4 different sessions, each with its own trial
    "1". Averaging those together under one quantile bin silently mixed
    different sessions' threshold values; the same collision also showed
    up as an apparent "5x duplication" when masking T_long down to one
    (chans, t, band) grid cell -- not a pooling bug, just 4-5 genuinely
    different trials all sharing one `trialNumber` value that downstream
    code assumed was unique.
    **Fix landed:** `nexOp_compileSTAT.m` now also sets
    `STAT.trialUID = (1:height(STAT))'` right where the final table
    is assembled -- a plain, never-resetting row index, so it stays
    unique no matter how many sessions/subjects a later row-subset (e.g.
    `fitByCombo`'s `child.STAT = mdlObj.STAT(mask,:)`) spans.
    `buildLongSTAT.m` now builds `T.trial` from `trialUID` and dedupes
    the quantization step on it instead of `trialNumber`.
    `STAT.trialNumber` itself is left untouched (still potentially useful
    as a within-session display value) -- only which column counts as
    "the" trial key changed.
    **Deferred, deliberately not built now:** a real cross-stratum
    *pairing* vector (e.g. "trial N of stratum A" matched to "trial N of
    stratum B" for a future paired-comparison test). Discussed directly:
    resetting `trialUID` at each CTG/stratum boundary instead of
    never resetting it would NOT reintroduce the session-collision bug
    above (a stratum is a coarser boundary than a session, so it's safe)
    -- but a reset-per-stratum counter still wouldn't automatically make
    "position N in stratum A" mean the same real event as "position N in
    stratum B"; that only holds if the underlying trial ORDER was
    deliberately aligned across strata when the numbers were assigned,
    which isn't true today and needs real design thought once a paired
    test is actually wanted. When that happens, build a separate,
    explicitly-named column for it (not a second job piled onto
    `trialUID`, whose only contract right now is "guaranteed unique,
    nothing more").

**Touches (anticipated, growing):**
`Analysis/Statistics/MixedEffect/*.m` (all of today's standalone
functions), `Draw/nexDraw_violin.m`, `Visualization/nexVisualization_bar.m`,
eventually new `mdlObj_MEM.m` (or similar name) plus
`nexObj_trajectory.m`/`nexObj_violin.m` objects sharing a multi-facet `R`
contract via the existing `nexOp_saveResult`/`nexOp_loadResult` path
(observations 5, 6) once observation 3's seam is understood,
`nexObj_monoGram.m`/`nexVisualization_monoGram.m` (read, not yet modified).

**Depends on:** Nothing architecturally blocking — this builds on #10
(already landed) and is additive to the existing `MixedEffect/` functions,
not a rework of them.

---

## 13. `nexDraw_violin.m`: multi-tier label-matching breaks for 2+ active categories

**Status:** Open — reproduced directly, worked around in the caller, not
fixed in `nexDraw_violin.m` itself.

**Context:** Found building `plot_mixedEffectViolin.m` (#12's figure type
2) — tried condition as tier 1, subject nested as tier 2 via
`S_categories = struct('C1',"condition",'C2',"subject")`, matching
`nexObj_categorical`'s own documented multi-slot convention.

**Design — root cause:** `nexStat_binSTAT.m` correctly encodes a combined
multi-tier `X` position per row (e.g. 2 conditions x 6 subjects = 12
distinct values, condition contributing an integer part, subject
contributing a fractional offset within it). But `nexDraw_violin.m`'s own
label-matching line —
```matlab
xLabels_sub = xLabels{1}; xTicks_sub = xTicks{1};
L = arrayfun(@(x) xLabels_sub(x==xTicks_sub), X, "UniformOutput", true);
```
— only checks `X` against **tier 1's own tick list** (`xTicks{1}`, e.g.
just `[0,1]` for 2 conditions), not the full combined multi-tier range.
Any row whose `X` includes a nonzero lower-tier (subject) offset doesn't
equal either tier-1 tick exactly, so `xLabels_sub(x==xTicks_sub)` returns
`[]` instead of a scalar — `arrayfun`'s `UniformOutput` then throws
`"Non-scalar in Uniform output"`. Reproduced directly: 2-tier
condition+subject call errors every time; condition alone (1 tier) does
not. This line only works when `X`'s value range exactly equals tier 1's
own range, i.e. when there's exactly one active category — multi-tier use
is a real, currently-broken code path, not a hypothetical one.
**Not yet investigated:** whether `nexObj_categorical`'s own typical usage
ever actually exercises 2+ simultaneously-active categories in practice
(its `S_categories` has up to 87 slots, mostly `"None"` — unclear how
often more than one is live at once), which would explain why this has
stayed latent.

**Workaround in place:** `plot_mixedEffectViolin.m` uses a single tier
(`condition` only) and drops per-subject visual distinction in the violin
entirely — per-subject identity lives in `plot_mixedEffectTrajectory.m`
instead (#12's figure type 1), not duplicated here.

**Touches (anticipated fix):** `Draw/nexDraw_violin.m` (the `L=...` line
and whatever downstream logic assumes `xLabels{1}`/`xTicks{1}` represent
the full combined range — likely needs the FULL concatenated multi-tier
tick/label set, not just tier 1's, or a different matching approach
entirely, e.g. reconstructing `L` from `Y_enum` per tier directly instead
of reverse-matching `X` against a single tier's ticks).

**Depends on:** Nothing blocking — safe to fix independently whenever
someone wants real 2+-tier violin nesting (e.g. if `nexObj_violin`,
observation 6, wants condition x subject nesting rather than the current
single-tier workaround).

---

## 14. `nexDraw_violin.m`: `violinplot(ax, Z)` passes the axes handle as DATA — fixed

**Status:** Fixed. Found and resolved in the same build pass as #13 (same
function, different bug — this one blocked even single-tier use once
`plot_mixedEffectViolin.m` hit real multi-subject data; #13's workaround
alone wasn't sufficient).

**Context:** `plot_mixedEffectViolin(results, "postCCI_R", "gamma", "STN",
"0.967", mdlObj.nexon)` against real saved results threw `Error in
violinplot (line 176): elseif ismatrix(data{1})` — `"Brace indexing is not
supported for variables of this type."`

**Design — root cause:** `violinplot.m`
(`utils/UnitMatch/MATLAB/Dependencies/Plotting/Violinplot/violinplot.m`,
third-party, signature `violinplot(data, cats, varargin)`) never accepts
an axes handle as an argument at all — it operates exclusively on `gca`
internally (`set(gca,...)` at lines 163/174/185). `nexDraw_violin.m`
called it as `violinplot(ax, Z)`, so `ax` silently became `data` and `Z`
became `cats`. Since `cats` (`Z`, a real matrix) is non-empty,
`hascategories` evaluates true; since `ax` matches none of
`isa(...,'dataset')`/`isstruct`/`istable`/`iscell`/`isnumeric`, none of
the main branches fire, and execution falls through to `elseif
ismatrix(data{1})` — `data` is still the untouched axes handle, so
`data{1}` (brace-indexing an axes object) throws. **Confirmed
deterministic, not data-dependent** — reproduced directly in isolation
with both balanced and NaN-padded synthetic matrices, both failing
identically regardless of shape.

**Resolved loose end:** an earlier synthetic smoke test of
`plot_mixedEffectViolin.m` reported success despite calling this same
broken pattern. Root-caused: MATLAB (R2023a+) ships its OWN native
`violinplot` (returns `matlab.graphics.chart.primitive.ViolinPlot`),
which — unlike the third-party one — DOES accept an axes handle as its
first argument. The earlier test's `addpath` never included
`utils/UnitMatch/.../Violinplot`, so it silently resolved to the native
function instead, which happens to tolerate the exact calling pattern
that breaks the third-party one. The real session's error trace (`Error
in violinplot (line 176)`, matching this file's actual line content) and
a direct `which violinplot` both confirm the real environment resolves to
the third-party file — so the fix below targets the right implementation;
the earlier pass was a test-environment artifact, not evidence the bug
was data-dependent.

**Fix:** `nexDraw_violin.m` — make the axes current before calling, per
`violinplot`'s actual `gca`-only convention:
```matlab
axes(ax);
V.v = violinplot(Z);
```
instead of `V.v = violinplot(ax, Z);`. Verified via isolated direct test
(`axes(ax); violinplot(Z)` on a plain 2-column matrix succeeds) and via
`plot_mixedEffectViolin.m`'s own full smoke test post-fix.

**Touches:** `Draw/nexDraw_violin.m` (one call site). No other callers of
`violinplot` found in the repo, so blast radius is contained to this one
function.

**Depends on:** Nothing — already landed.

---

## 15. `nexDraw_violin.m`: two more latent bugs, found/fixed in the same pass as #14

**Status:** Fixed. Both surfaced immediately after #14's fix, continuing
with real `postCCI_R`/STN data (202 rows, 7 subjects) — this function had
apparently never been exercised end-to-end against the actual installed
`violinplot`/`Violin` classes before this session.

**Bug A — `nexDraw_scatter.m` read `vSub.FaceColor` on a `Violin` object.**
The third-party `Violin` class (`Violin.m`) exposes color via the
dependent property `ViolinColor` (itself reading the internal
`ViolinPlot.FaceColor` patch) — there is no bare `FaceColor` property on
`Violin` directly. `ViolinColor` also returns a cell (supports up to two
colors for split violins), so a plain RGB triplet needs `{1}`.
Fix: `vSub.FaceColor` → `vSub.ViolinColor{1}`.

**Bug B — `linkaxes` failing on mismatched ruler types.** The nested
multi-tier label-axes loop (just below #13's affected code) builds an
invisible overlay axis via `plot(ax_i, categorical(cats), nan(size(cats)))`
— this makes `ax_i`'s x-ruler a true `CategoricalRuler`, which cannot be
`linkaxes()`'d against the primary violin axis's `NumericRuler` (ticks set
via plain `XTick`/`XTickLabels`, confirmed while fixing #14's follow-on
`ax.XAxis.Categories` → `ax.XAxis.TickLabels` correction in the same
block). This loop only has a reason to run at all when there's a second
tier to nest — for a single active category it's pure redundant overhead
that also happens to crash. Fix: guard the whole loop on
`size(xTicks,1) > 1`; `linkaxes(axList)`/`uistack` left unconditional
afterward since both are harmless no-ops on a single-element `axList`.

**Touches:** `Visualization/nexDraw_scatter.m` (one line), `Draw/nexDraw_violin.m`
(the `cats` lookup and the nested-label loop's guard condition).

**Depends on:** Nothing — already landed. Entry #13 (multi-tier label
matching) remains separately open — this entry's loop-guard means
single-tier use never reaches #13's still-broken code path, but does not
fix it.

**Addendum — visual cleanup pass, same session, one more library bug
found and avoided rather than fixed:** once rendering without error, the
violins showed (a) two overlapping sets of differently-sized scatter
points, (b) grey violin edges regardless of fill color. (a) was
`violinplot`'s own internal scatter (`'ShowData'` defaults `true`,
`MarkerSize=36`) rendering alongside `nexDraw_scatter`'s separate layer
(size 100) — tried suppressing via `'ShowData',false`, which surfaced a
**sixth bug**: `Violin.m`'s own default-color branch (taken whenever
`'ViolinColor'` isn't explicitly given) unconditionally reads
`args.scpltBool` — a field never assigned anywhere in the file, confirmed
by direct search — only reachable when `ShowData=false` skips the
scatter-plot creation that branch otherwise falls back on reading color
from. Not fixed (third-party library internals, out of scope for today);
avoided instead: left `ShowData` at its default and hid each violin's
`ScatterPlot.Visible='off'` post-hoc, inside a `try/catch` matching this
file's own existing defensive style, rather than ask violinplot not to
create it. (b) fixed directly: `EdgeColor` synced to each violin's own
`ViolinColor{1}` post-construction, since `EdgeColor` is independently
settable after the fact (confirmed via its own `set.EdgeColor` method)
unlike the per-group scatter suppression. One deliberately-unresolved
observation, not a bug: violin tails look "cut off" rather than tapering
smoothly — confirmed via direct source check that `Violin.m` never sets
`ylim` anywhere, so this is the genuine shape of `ksdensity`'s kernel
density estimate at its auto-selected bandwidth for this sample size
(~30-40 trials/group), not a clipping bug. Fixable via an explicit,
wider `'Bandwidth'` argument, but that's a real smoothness-vs-detail
tradeoff left to the user, not changed here.

---

## 16. Trial-relative `epoch` binning as a new `poolMap` mapID source (`t` axis)

**Status:** Designed, not started.

**Context:** Came up planning the next phase past `mdlObj_lme` on band
power — extending the same chain-fitting pattern to firing-rate-derived
features (PCA/dPCA/jPCA/SSM eigenspectra), specifically region-wise +
time-windowed SSM fits swept per `(region, time-epoch)` cell via
`domain.SWP`, the same way band/chans/t already sweep for LME. That plan
assumed `t` could be region-pooled the same way `chans` already is (one
`divsPerBin=Inf` edge per named group, groups kept separate) — which
surfaced two things worth recording on their own, independent of whether
the SSM work proceeds immediately:

1. **`divsPerBin=Inf`'s behavior depends on which `binType` the axis is
   using, and this is easy to get backwards.** For a `mapID`-type axis
   (region/band/event — a table of raw positions → named labels),
   `Inf` correctly collapses each NAMED GROUP to one pooled value, groups
   kept separate — this IS what region pooling already does today, and
   is also what a hypothetical epoch mapID would need. For a plain
   `axID`-type axis (raw numeric position, no label table — `t`'s OTHER
   existing binType), `Inf` collapses the ENTIRE axis into a single bin.
   Conflating the two during the SWP-sweep discussion produced a wrong
   first pass ("Inf keeps 3 epochs separate") that direct verification in
   `nexObj_poolMap.getBinEdges` corrected.
2. **`t`'s existing `mapID` option ("event", via `map_events2time.m`,
   wired unconditionally in `nexInit_pMap.m:9-14`) is itself just a
   single static lookup table, built once at `nexObj` construction time
   and reused unchanged for every subsequent trial** — confirmed directly
   by reading `map_events2time.m` (`LUT_events = buildLUT_map(events);
   Map = LUT_events;`, no per-trial anything). Real event timestamps vary
   trial-to-trial, so "event" has the exact same staleness limitation
   WIP #10 already found and fixed for region pooling (`poolMap.Map`
   frozen at whichever subject was live at construction) — just never
   flagged for `t` specifically before now. This matters here because it
   means a correctly-built `epoch` mapID (resolved fresh per trial, see
   below) would be MORE correct than today's "event," not a lesser
   stand-in for it.

**Design — phased, two related but genuinely different-complexity
questions, deliberately not tackled together:**

- **`epoch` (this entry's actual scope):** assumes exactly ONE
  already-chosen alignment/zero event (whatever `t=0` already represents
  for a given DF) and derives named sub-windows proportionally relative
  to it. Lower risk, no new per-trial event-extraction/validation needed
  beyond what already puts a real zero on the `t` axis.
- **`event`, full version (explicitly deferred, not started, tracked
  here only so it isn't rediscovered as a surprise later):** genuine
  multi-landmark canonicalization — using SEVERAL events of interest per
  trial (e.g. both onset AND withdrawal) as internal anchors, defining
  segments relative to multiple real behavioral timestamps rather than
  one chosen zero. Strictly more capable (subsumes `epoch` as the
  one-event special case) and strictly harder (needs robust per-trial
  multi-event extraction/validation before the canonicalization logic
  even starts). Revisit once `epoch` is working and there's real
  appetite for the harder version.
- **A real mapID *selector* for `t` (deferred, separate from both of the
  above):** `nexInit_pMap.m` currently hardcodes exactly ONE mapID source
  per axis with no choice mechanism at all — today `t` always builds
  from `map_events2time`, unconditionally. Introducing `epoch` right now
  means swapping that one hardcoded branch, not building a selector
  between candidates (event/epoch/future options) — since `event`'s full
  version is being deferred anyway, there's nothing to select between
  yet. A real selector is its own future item once `event`'s full
  version actually exists as a second real option.

**`epoch`'s resolved semantics:**
- "during" = centered on zero, extending for a small, explicitly-sized
  micro-context window on both sides (NOT starting-at-zero-and-extending-
  forward — confirmed this reading directly).
- "before"/"after" = baseline periods safely outside the during-window
  on each side (pseudo-baseline / post-baseline) — exact relationship to
  during's edges (flush partition vs. an explicit buffer/gap) not yet
  pinned down; "safely outside" suggests the latter may be intended,
  worth confirming before implementation.
- Exactly ONE free parameter — during's own width — with before/after as
  pure residual on either side. Deliberately not three independent
  percentages (which can be misconfigured: sum ≠ 100%, gaps, overlaps);
  one width + residual is well-defined by construction for every trial
  regardless of length.
- Width is a PROPORTION of each trial's own `t`-axis span, not a fixed
  absolute duration — chosen because trial length genuinely varies
  (short vs. long responses, confirmed directly, not assumed), though
  most trials cluster near ~11s in practice so the proportional-vs-fixed
  distinction may rarely bite in this particular dataset. Proportional is
  still the correct default regardless, since it degrades gracefully on
  whatever trial eventually doesn't match that typical length.

**Resolution mechanism — must be dynamic, not a cached table:** because
trial length/alignment genuinely varies, `epoch`'s position→label
correspondence cannot be a single table built once and reused (the same
mistake already latent in "event," see above). The right pattern already
exists in this codebase: `nexObj_poolMap.getBinEdges`'s own `subjID`
override (`resolveSubjectMap_`) resolves a context-specific `Map` on
demand instead of using the one frozen at `pMap` construction time — the
same shape of fix, just keyed by TRIAL context (this trial's own axis
length + zero-index position) instead of by subject. A
`map_epochs2time(axisLength, zeroIdx, duringWidthProportion)`-shaped
function, computed fresh per call rather than cached, producing the same
`{axID positions, mapID labels[, color]}` shape `map_events2time.m`/
`map_regions2chans.m` already produce, rides the EXACT SAME generic
`nexObj_poolMap`/`getBinEdges` dispatch with zero changes needed to that
class — confirmed by reading `getBinEdges` directly (its `mapID` branch
is already fully generic over whatever `Map` table it's handed; nothing
in it assumes "region" specifically).

The `duringWidthProportion` itself fits the existing config-on-`nexon`
convention (same idea as other `nexon.settings`/registry-held
parameters) — editable in one place, triggering a rebuild of whichever
pMap(s)/registry entries depend on it when changed, per the user's own
proposal; not yet decided exactly where under `nexon` this should live.

**Touches (anticipated):** new `map_epochs2time.m` (sibling to
`map_events2time.m`/`map_regions2chans.m`), `nexInit_pMap.m` (swap the
`t`-axis branch, currently lines ~9-14, to build from it instead of
`map_events2time` for now), a new `nexon`-level config field for
`duringWidthProportion` (location TBD). **No changes needed to
`nexObj_poolMap.m` itself** — confirmed its dispatch is already fully
generic.

**Depends on:** Nothing architecturally for `epoch` itself — the data/
mechanism it needs (a dynamically-resolved Map, mirroring
`resolveSubjectMap_`'s existing pattern) is buildable today. The full
multi-landmark `event` canonicalization and the mapID-selector mechanism
are both separate, explicitly deferred follow-ons — not prerequisites.

---

## 17. `t` has no cross-trial canonical sentinel — `refreshPointerFromPool` silently seeds Pointer from trial #1 alone (#16 follow-on, genuinely latent/pre-existing)

**Status:** Designed enough to log, not started. Two real, unresolved
forks: which mechanism to build, and (independently) trim vs. pad. Not
blocking #16 (epoch itself works today for `divsPerBin=Inf`); surfaced
while scoping `divsPerBin=0` for epoch (full raw-resolution per-position
labeling, wanted for the firing-rate/SSM eigenspectra follow-on work).

**Context — what was actually wanted, clarified over two rounds:**
1. First framing (rejected): seed Pointer's `t` candidates from the
   DEDUPLICATED label set (`["before","during","after"]`, always 3,
   trial-invariant). **Not what was wanted.**
2. Real target: Pointer should show the FULL per-position label
   sequence, exactly what `getBinEdges`'s own `divsPerBinOverride==0`
   branch already produces — `["before","before",...,"during",...,
   "after","after",...]`, or `["before_1","before_2",...]`-style
   sub-indexed labels for a finite `divsPerBin` — never deduplicated,
   never bare position-index numbers.
3. The deeper, actual ask: regardless of what any ONE trial's own Pointer
   display shows, **precompile itself** should produce a canonical
   sentinel reflecting the TRUTH across every STAT row — "how many time
   points we have across all STAT rows, whether because we trimmed away
   the excess or padded in to match lengths" — so Pointer (and anything
   else precompile seeds) reads from that one authoritative sentinel,
   not from whichever trial happens to be first.

**Design — the confirmed gap, traced directly (not assumed):**
`precompileSTAT`'s own header comment claims Pointer options get seeded
"to the true canonical set... every pMap-pooled axis, not just REG" via
`refreshPointerFromPool`. Read that function directly
(`mdlObject.m:308-403`) — it does this:
```matlab
TF1 = mdlObj.precompiledAligned.TF{1};   % trial #1 -- arbitrary
...
ax_out = nexOp_poolAx(mdlObj.pMap, TF1, [], subjID);
mdlObj.refreshPointerAxes_(ax_out);
```
One single trial, pooled through the current pMap, seeds every axis's
Pointer candidates. For **REG** (chans/unit) this happens to be correct
— not because this function does anything REG-specific, but because
`nexOp_alignCoAxes` already ran *earlier* in `nexOp_compileSTAT` and
reslotted every trial's REG axis into one shared canonical union before
`TF1` ever reaches here; `TF1.ax.<REG>` already *is* the global canonical
set by the time this function reads it. **`t` never goes through that
upstream step at all** — confirmed directly in `nexOp_alignCoAxes.m`:
it only ever canonicalizes whichever ONE axis is passed in as `regAxis`
(always `unit`/`chans` in every real call site), never `t`. So
`TF1.ax.t` is genuinely just trial #1's own raw, uncanonicalized time
axis — Pointer's `t` candidates are silently trial-1-specific TODAY,
independent of epoch or `divsPerBin` entirely. This is a pre-existing,
latent gap for ANY cross-trial-varying-length axis (confirmed this
session: trial length genuinely varies — "some short responses, others
longer") — epoch's `divsPerBin=0` doesn't introduce it, it just makes
the consequence newly visible (Pointer's candidate COUNT would visibly
change depending on which trial happens to land as `TF1`).

**Two real approaches, not yet chosen between:**
1. **Extend `nexOp_alignCoAxes.m` to also canonicalize `t`** — treat it
   as a second union-and-NaN-pad target alongside REG, reusing the exact
   mechanism already proven for unit/chans (union across every TF's own
   axis values, reslot each TF into that shared canonical layout,
   NaN-fill structural absence). Would need `nexOp_compileSTAT.m`'s
   alignment step to call this for `t` too (today only called once, for
   whichever axis `domain.REG` names).
2. **A separate, dedicated sentinel mechanism** for axes like `t` that
   computes either the trial-wise MINIMUM (trim — drop the excess beyond
   the shortest trial) or MAXIMUM (pad — NaN-fill shorter trials up to
   the longest) length across every STAT row, independent of REG's own
   union-based approach. Lighter-weight than reusing `alignCoAxes`, but a
   second, parallel canonicalization code path rather than one shared
   mechanism.

**Genuinely unresolved, by design — not an oversight:** trim vs. pad
itself. Trimming loses real recorded data on longer trials; padding
leaves NaN gaps that every downstream consumer (pooling, model fitting)
needs to already handle correctly (pooling already does, via `omitnan`
— unclear whether an eventual SSM/dynamax fit path would, un-audited).
Not decided here deliberately — a real tradeoff, not a default to pick
silently.

**Touches (anticipated):** `nexOp_alignCoAxes.m` (if approach 1 — would
need to accept/process a second axis, or be called twice),
`nexOp_compileSTAT.m` (the alignment call site, if approach 1),
`mdlObject.m` (`refreshPointerFromPool`, `precompileSTAT` — regardless of
which approach, since this is where the wrong single-trial assumption
currently lives), a new standalone sentinel-computation function (if
approach 2).

**Depends on:** The trim-vs-pad decision and the approach-1-vs-2 choice,
both genuinely open — not blocked on anything architectural. Builds on
#16 (`map_epochs2time.m`, the `epoch` mapID itself, already landed and
independent of this gap for the `divsPerBin=Inf` case).

---

## 18. `mdlObj_ssm`: real per-grid-cell SWP sweep (region x epoch, or any SWP combo) — not yet started, design settled

**SUPERSEDED by #19.** The design below proposed a `fitSWPGrid` method
living on `mdlObj_ssm` specifically. The user then asked to generalize
this to `fit()` itself for every mdlObj subclass (CTG outer, SWP inner,
reusing `fitByCombo`'s skeleton), simultaneously unifying SSM's own
per-region PCA reduction onto the shared `needsHR` sequence rather than
keeping its bespoke `Reducer`/`Scaler`. That landed as `mdlObject.
fitSWPGrid` (base class) — see #19 for the actual shape. Left in place
for the "why not reuse cvPermute directly" correction below, which is
still accurate and not repeated in #19.

**Status (historical):** Designed, not started. `collector.View`'s SWP listbox was
just switched from single-select to multi-select
(`nexFigure_ssm.m`) ahead of this landing — honest about intent, but
currently inert: `domain.SWP` is set correctly by a multi-selection, but
nothing in `nexFit_ssm.m` reads it yet, so it sits unused exactly as it
did at the old single-select cap.

**Context:** Came up wanting region-wise + time-windowed SSM fits (one
independent fit per `(region, epoch)` cell, epoch via #16's mapID),
mirroring how `mdlObj_lme` already does an independent `fitlme` chain
per grid cell. Initially assumed this could reuse `nexAnalysis_cvPermute.m`'s
own internal SWP-combo-slicing machinery directly — **checked directly
and that assumption was wrong, corrected here:** `nexFit_lme.m`'s actual
SWP usage is
```matlab
swpSel   = string(mdlObj.domain.SWP);
gridCols = cellstr(swpSel(swpSel ~= "None"))';
T_long   = buildLongSTAT(mdlObj.STAT, chain.variables, gridCols, targetInfo);
mdlObj.W = mdlObj.computeSignificance(T_long, chain);
```
`domain.SWP` is just a list of column NAMES handed to `buildLongSTAT`;
the actual per-grid-cell loop (`ind2subVec`-style masking, one `fitlme`
chain per cell, assembled into an N-D `pGrid`) is a hand-written PRIVATE
METHOD on `mdlObj_lme` (`computeSignificance`), modeled on
`build_bandHierarchy.m`'s own proven grid loop — it does **not** call into
`nexAnalysis_cvPermute.m` at all. So there is no shared, already-built
"SWP combo slicer" to import for SSM; the grid loop itself needs writing,
same as LME's own was.

**Design — directly analogous to `mdlObj_lme.computeSignificance`, with
one structural difference in what a cell's fit produces:**

1. **New method on `mdlObj_ssm`** (name TBD, e.g. `fitSWPGrid`) — reads
   `domain.SWP` the same way `nexFit_lme.m` does (grid-dimension column
   names, `swpSel ~= "None"`), builds the same kind of grid-cell
   enumeration (`ind2subVec`/masking by grid coordinate), and for each
   cell runs `nexFit_ssm.m`'s existing Scaler → Reducer → `model.fit()`
   sequence, scoped to just that cell's own sliced rows — instead of
   `fitlme` per cell.
2. **Per-cell output is richer than LME's scalar p-value** — a full
   fitted system (`A`/`C`/`Q`/`R`, same shape `nexFit_ssm_buildSYS`
   already produces), not one number. `pGrid`'s single N-D array doesn't
   fit this; the per-cell result needs its own `SYS`-like struct,
   assembled into a RESULTS table with one row per combo (`df`/`ax` per
   row), mirroring `mdlObj_lme.fitAndReport`'s own table-assembly
   convention rather than `computeSignificance`'s single flat grid.
3. **Direct tie-in to #16/#17 (epoch pooling)**: each grid cell (e.g.
   region=STN, epoch=during) needs to gather every raw timepoint tagged
   with that epoch label, across every trial in the combo, and feed them
   as a batch of sequences into that cell's own fresh SSM fit.
   `nexFit_ssm.m`'s existing 3D path (`(num_trials x T x channels)`,
   confirmed already implemented — see its `isBatch`/`DM_perm` branch) is
   already shaped for exactly this; the new piece is ASSEMBLING that
   per-cell batch correctly from a `divsPerBin=0`-pooled, epoch-labeled
   STAT in the first place, which is #17's own still-open canonical-
   sentinel question (trim vs. pad, trial-length variation) — this entry
   depends on that one being resolved for real, not just in the
   `divsPerBin=Inf` case #16 already covers.

**Touches (anticipated):** `mdlObj_ssm.m` (new `fitSWPGrid`-equivalent
method), `nexFit_ssm.m` (dispatch to it when `domain.SWP` names real grid
columns, mirroring how `nexFit_lme.m` dispatches to `computeSignificance`),
a new RESULTS-assembly step (mirroring `mdlObj_lme.fitAndReport`) to turn
however many per-cell `SYS` structs result into one row-per-combo table.

**Depends on:** #17 (the `t`-axis canonical sentinel) for the
`divsPerBin=0` case specifically — the `divsPerBin=Inf` case (one pooled
value per epoch, no raw-resolution batching) doesn't need #17 and could
be prototyped against this design sooner if useful as an intermediate
step.

---

## 19. `mdlObject.fitSWPGrid` — `fit()` generalized to a CTG x SWP grid, every subclass; `mdlObj_ssm` unified onto the shared `needsHR` sequence

**Status:** Landed. `fit()` is now a one-line wrapper around
`fitSWPGrid()`; `fitByCombo` is retired in place (not deleted, no longer
called).

**Shape:** CTG outer (one independently-fit child per unique
`domain.CTG` combo, same child-construction skeleton `fitByCombo` always
used) x SWP inner (full Cartesian product across `domain.SWP`'s selected
axes — multi-select, per `applyViewBus`'s own pre-existing comment, not
single-axis as #18 assumed). Degenerates to the exact old single-model
`fit()` body when both are empty/"None" — one cell, same end state.

Per-axis SWP resolution (`nexOp_resolveSWPAxis.m`, new) ports
`nexAnalysis_cvPermute.m`'s own per-axis `swpAxes` logic (its section 4)
rather than re-deriving it: a `needsHR` mdlObj's reduce-mode FTR axis
resolves to post-reduction BLOCK labels ("ftr" mode); its deferred
pool-mode axis resolves to post-pooling WINDOW bin-IDs ("pool" mode);
anything else resolves to raw per-value STAT slices ("raw" mode).
`nexOp_sliceSTAT.m`/`nexOp_matchesSWPValue.m`/`nexOp_swpLinToSubs.m`/
`nexOp_resolveAxisDim.m` (also new) extract cvPermute's own
`sliceSTAT`/`matchesSWPValue`/`swpLinToSubs`/`resolveAxisDim` local
functions to shared files — cvPermute's own copies are now thin
forwarders, DRY, no behavior change there.

Masking strategy per CTG combo, decided once by whether that combo is
`needsHR`:
- **needsHR:** `getDesignMatrix()` runs ONCE (the expensive block-PCA
  reduce+pool step); every SWP combo in this CTG combo just MASKS the
  one already-built `DM`/`TRAIN.G` — "ftr" mode masks COLUMNS via the
  (now-stashed, previously-discarded) `FTR_blockColRanges`; every other
  axis masks ROWS via `TRAIN.G.(axisID)==val` (`nexOp_stackByFTR` folds
  every non-FTR axis into its own `TRAIN.G` column, so "pool" mode and
  "other raw axis under needsHR" are literally the same masking
  operation). No re-reduction per SWP combo.
- **not needsHR:** no reduce/pool step to reuse — every axis is "raw,"
  chain-sliced sequentially (mirrors cvPermute's own multi-axis
  `sliceSWPCombo`), then `getDesignMatrix()` runs once per resulting cell.

`comboFits` gained a third field, `swpVal` (a struct, one field per swept
axis — `struct()` when SWP wasn't used) — kept SEPARATE from `key`
deliberately: `nexOp_matchComboRow` (used by `scaleApply_transform` at
inference time) treats any `key` field absent from a row's own STAT/DTS
columns as "can't match," so merging `swpVal` into `key` would silently
break every row's match, not just fail to disambiguate multiple
SWP-children sharing one CTG key.

**Known gap, not addressed:** `scaleApply_transform`'s per-DTS-row combo
lookup only matches on CTG — when SWP produces multiple children per CTG
combo, inference-time row→child matching doesn't yet pick the right one.
Latent until something actually calls `scaleApply_transform` on a
SWP-gridded fit.

**`mdlObj_ssm` unification, same pass:**
- `getDesignMatrix`'s needsHR branch no longer gates on
  `dmCfg.format=="supervised"` — admits every format unconditionally
  (SSM's own `"stack"` included). The Y-encoding step (`nexOp_
  buildSupervisedDM`) stays `"supervised"`-only; every other format uses
  the reduced+pooled X directly as `DM` (no Y step) — flat 2D, same as
  before, no 3D reshape at this layer.
- `flattenInput`'s needsHR branch had the identical, narrower bug (gated
  on `"supervised"` even though its own body is X-only, no Y-handling at
  all) — same fix, and it also now returns `G_flat` as an optional 2nd
  output (existing callers requesting 1 output are unaffected) so a
  caller whose output needs real trial/time structure (SSM) can
  reconstitute it.
- **Scaling, newly added to the shared sequence, not just SSM:**
  `fitReduce`/`applyReduce` now standardize `X_raw` via `mdlObj.Scaler`
  (fit once in `fitReduce`, transform-only — never re-fit — in
  `applyReduce`) BEFORE block-PCA. This was a real, pre-existing gap for
  *any* needsHR mdlObj, not an SSM-specific fix: `nexHR_fit`'s own PCA
  whitening only normalizes OUTPUT component variance, never the INPUT
  channels feeding it, so a block spanning channels on very different
  raw scales had its principal axes dominated by whichever channel was
  loudest. SSM's own bespoke `Scaler.model.fit_transform` call was
  compensating for exactly this gap in its own parallel, non-shared way.
- `mdlObj_ssm`'s own `initReducer` override (built `Reducer.setBlocks`
  directly from `pMap.(ftrAxis).getBinEdges`) and its `nexFit_ssm.m`
  `Scaler.fit_transform`/`Reducer.fit_transform` preamble are retired —
  `mdlObj.DM` now arrives from `getDesignMatrix` already scaled, reduced,
  and pooled via the shared sequence.
- `pMap.chans.divsPerBin` flips from positive (plain pooling) to
  `-Inf` (reduce-mode, one block per named region, same magnitude as
  before — user-confirmed only the sign needed to change) +
  `pMap.chans.reducerDim` set from `cfg.fitCfg.entryParams.reducerDim`
  (the generic property `nexHR_fit` already reads as `pm.reducerDim`).
- `nexFit_ssm_buildSYS`/`buildCmask` rewired off `mdlObj.
  FTR_blockColRanges`'s `.label`/`.cols` (`nCompActual(b) =
  numel(ranges(b).cols)`) instead of `mdlObj.Reducer.MDL.ax.
  binLabels`/`nCompActual`.
- **Trial/time reconstitution, the one place SSM genuinely differs from
  every other needsHR consumer:** `nexOp_poolStackedDM`'s flat
  `(nGroups, nFeatures)` output is deliberately trial-blind (right
  contract for PCA/LDA, which want i.i.d. samples) — SSM needs real
  array dims because dynamax's own batched EM (`ssm.py`'s `fit_em`,
  confirmed directly in the installed dynamax source, not just the
  `pytafix` wrapper: `vmap(partial(self.e_step, params))(batch_emissions,
  ...)`) treats a 3D `(num_trials, T, emission_dim)` input as
  INDEPENDENT per-trial sequences, not one concatenated one — confirmed
  the same way on the `filter()` side (`jax.vmap` over axis 0 when
  `ndim==3`). New `nexOp_reshapeStackedByTrial.m` reconstitutes
  `(nTrials, nBins, nFeat)` from the flat `X`+`TRAIN.G`'s `trialIdx`/
  poolAxis-bin columns, erroring (not silently truncating) if trials
  don't share the same pooled bin count — guaranteed rectangular today
  under the "epoch" mapID default (`map_epochs2time` always returns
  exactly 3 rows/trial) but not a general guarantee for every possible
  pMap config.

---

## 20. dynamax `fit_sgd` (real minibatched EM) not yet wired through `pytafix`'s `LGSSM` wrapper — blocks memory-constrained grid-sweeping

**Status:** Not started, logged instead of bundled into #19 at the
user's own call ("log it, finish unification first").

**Context:** `pytafix/ssm/lgssm_dynamax.py`'s `LGSSM.fit` only calls
dynamax's `model.fit_em(...)`. Confirmed directly in the installed
dynamax source (`ssm.py`): `fit_em` always `vmap`s the E-step across the
**entire** batch every EM iteration — there is no chunking inside it, so
every trial must be resident (GPU-resident, for GPU fitting) simultaneously,
every iteration. This is the user's own stated bottleneck ("the biggest
limitation until now... really slowed down inference") and a real
constraint on `fitSWPGrid` (#19) grid-sweeping at scale: each grid cell's
fit still hits this same ceiling, grid-sweeping just multiplies how many
times it's hit.

dynamax's own answer is a **different method**, not a flag on `fit_em`:
`ssm.py`'s `fit_sgd` — takes `batch_size` ("number of sequences per
minibatch"), optimizes the marginal log-likelihood via gradient descent
(`optax`) through `run_sgd`, genuinely streaming minibatches instead of
vmapping the whole batch at once. Different algorithm (SGD vs EM), own
hyperparameters (optimizer, learning rate, `num_epochs`, `batch_size`,
`shuffle`) — not a drop-in memory-efficient EM.

**Touches (anticipated):** a new `LGSSM.fit_sgd` classmethod in
`lgssm_dynamax.py` (mirroring `LGSSM.fit`'s structured-init pattern, but
calling `model.fit_sgd(...)` instead of `model.fit_em(...)`); a
`fitMethod = "em" | "sgd"` cfg option in `nexFit_ssm.m`'s CFG HEADER,
dispatching to whichever `LGSSM` classmethod; `isBlock` block-diagonal
constrained fitting has no SGD counterpart in the wrapper today either
(`fit_block_diagonal` is its own hand-rolled EM loop, not `model.fit_em`)
— would need its own SGD-equivalent if block-diagonal + minibatched
fitting together is ever needed, not just unconstrained + minibatched.

---
