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
