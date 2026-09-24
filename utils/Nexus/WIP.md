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

---
