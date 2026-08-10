# Population State-Space Analysis — Design & Roadmap

**Date:** 2026-08-09
**Branch:** `Dev_MS_realtimeControl_diskDTS`
**Scope:** Near-real-time + cross-session/cross-subject population trajectory analysis on
rtsort spiking (and later LFP) data, feeding the Nexus RealtimeControl / diskDTS pipeline.

This document captures both the **conceptual framing** and the **concrete architecture** worked
out in a long design session, so the reasoning behind the code is retained alongside the code.

---

## 0. Motivation

Pain-neuroscience program: chronic constriction injury (CCI) vs. sham, von Frey mechanical
stimulation, withdrawal thresholds/delays, neural implants across subjects that are **not** in
identical locations or conditions. Two coupled goals:

1. **Immediate visceral read** — see population trajectories as data comes off, to feel out which
   features are exploitable.
2. **Statistically compounded findings** — pool across sessions/days/subjects (diskDTS) into
   unifying, principled descriptions.

The through-line ambition: **localize what CCI changes** to a specific component of a shared
dynamical system, expressed in aligned latent coordinates.

---

## 1. Conceptual Framework

### 1.1 Geometry vs. Dynamics (the core decomposition)

"State-space analysis" is two separable operations, and conflating them is what makes real-time
feel hard:

- **Latent geometry** — the manifold the population lives on (*where* the trajectories are).
- **Latent dynamics** — the flow/vector field on it (*how* state evolves: rotations, fixed points,
  forecasting).

**You do not need a dynamics model to see a trajectory** — a trajectory is geometry indexed by
time. That dissolves the "EM is too slow for real-time" tension.

**Litmus test:** shuffle the time order of samples. Output changes → *dynamics*; unchanged →
*geometry*.

| Method | Class |
|--------|-------|
| PCA, dPCA, CEBRA | geometry (shuffle-invariant) |
| jPCA, LGSSM/LDS | dynamics (shuffle-destroyed) |

**Key unifier:** inside an LGSSM the two collapse into two matrices — **`C` = geometry** (where the
manifold sits in neural space), **`A` = dynamics** (how state flows). `B` = input coupling (distinct
from `C`). PCA/dPCA/jPCA are the fast, un-fitted diagnostics you climb before fitting the generative
model.

### 1.2 The real-time ladder (by training cost)

| Tier | Method | Training | Online cost | In repo |
|------|--------|----------|-------------|---------|
| Instant | smoothed rates → PCA projection | none / reference block | one matmul | `mdlObj_pca`, `mdlObj_reducer` |
| Train-offline / filter-online | LGSSM | EM (batch, offline) | Kalman filter O(k²)/step | `mdlObj_ssm` |
| Offline-train / embed-online | CEBRA | offline, GPU | forward pass | `mdlObj_cebra` |

The **EM/Kalman split** is the crux: EM is batch (offline); the online cost is the *filter*. "Train
offline, bring it here" is exactly the `mdlObj_ssm` pattern (`transform()` → `W.filter()`).

### 1.3 Cross-subject alignment (the central object)

Empirical foundation ("preserved neural manifolds" — Gallego/Miller; CEBRA — Schneider/Mathis):
single-neuron tuning is fragile across animals, but **low-dimensional latent dynamics are far more
preserved**. So imperfect implant placement is tolerable — you bet a shared latent process is sampled
through subject-specific readouts. That bet is **testable, not assumed**.

- **Alignment is a first-class operation**, anchored on behavioral labels (subject, CCI/sham,
  days-post-injury, von Frey force, withdrawal).
- Two convergent tracks: **shared-`C` LGSSM stitching** (shared dynamics `A`, per-subject readout
  `C`) + **CEBRA** (behavior-contrastive). Agreement between a constrained generative model and a
  flexible contrastive one is the robust finding.
- **Validation discipline** (alignment can manufacture agreement): leave-one-subject-out, shuffled-
  label nulls, and held-out decode (decode force / days-post-CCI from an *unseen* subject's aligned
  latent).

### 1.4 Input-driven vs. autonomous (honest caveat for a sensory system)

Rotational/autonomous-dynamics framing comes from **motor cortex**. Nociception is largely
**stimulus-driven**. Expect higher tangling, more input-driven structure. Reframe the likely *vital*
finding: not "there's an attractor," but **how the input-driven response geometry reorganizes after
CCI**. Model the stimulus as `u_t` and ask what injury changes:

- `C` — manifold remaps (representational reorganization)
- `A` — altered intrinsic flow (persistent pain state)
- `B` — input gain up (sensitization as gain change)
- `Q`/`R` — noisier/less reliable

`Q`/`R` (uncertainty) is what upgrades cross-session pooling from *descriptive* to *statistical*.

### 1.5 Trivial vs. vital dynamics — runnable tests

1. **Prediction beats an AR/persistence null (decisive).** Partition latent variance into
   *stimulus-driven + autonomous-predictable + noise*. Vital iff the autonomous-predictable slice is
   non-negligible **and** structured.
2. **Tangling** (Russo). Low = state determines flow (autonomous description apt); high = input-
   driven (an autonomous model is the wrong description). Expect higher tangling than motor cortex.
3. **Cross-condition/subject flow generalization.** One flow field explaining held-out
   subjects/conditions = a real invariant.

jPCA rotations are a cheap *screen*, suggestive not confirmatory in a sensory system.

### 1.6 Reinforcement learning — decomposition

RL = state + dynamics + action + reward. **Have:** state (latent), dynamics (LGSSM *is* a world
model). **Lack:** action (no actuator yet), reward (undefined).

- **RL-as-controller** (Bouton's read-write bypass): needs an actuator — *defer*, but design toward.
- **RL-as-model-of-computation:** the brain runs aversive-learning; test for **aversive prediction
  error** / sensitization-as-miscalibrated-value in the latent — available now, no stimulation.
- **Bridge:** system-ID and model-based RL are the same math. Offline RL (CQL/IQL) turns today's
  logged diskDTS transitions into tomorrow's stimulation policy. The transferable hard parts to build
  now are the **state representation** and the **reward** (a latent target region = the one normative
  choice; e.g. negative distance from the sham/healthy manifold).
- **Live RL-adjacent use:** bandits / active experimental design over stimulus choice (action =
  which von Frey to deliver; reward = information gain).

Trap to avoid: calling a pure description "RL" when there's no action and no reward.

### 1.7 Defining "latent state" and "reward/target"

- **Latent state = the ruler** (representation), decided offline: which observations, timescale,
  dimensionality, and — for cross-subject — the shared/aligned frame. *Not yet interpretation.*
- **Region meaning is discovered** (from behavioral labels), **the target is decided** (your
  normative judgment). Reward is a *function* over states (high near target), not just a labeled blob.
- **Online/offline circuitry:** offline = fit representation + calibrate target against labels;
  online = filter → locate in aligned space → score against target (a cheap projection + distance).

---

## 2. Concrete Architecture

### 2.1 Feature "sides"

| Side | Signal | Status | Notes |
|------|--------|--------|-------|
| **A** | rtsort firing rates | **v1 focus** | `RTS_spk_activity` `(unit × t × measure)`, `measure=["raster","rate","amp"]`; use `rate` |
| B | raw LFP snapshot | **dropped** | instantaneous voltage = phase/volume-conduction noise; info is spectral |
| C | LFP band-power | later | inherent short window; conflates aperiodic + oscillatory |
| D | spectral parameterization (specparam) | later | separates aperiodic 1/f (excitability, sensitization) from oscillations — *supersedes* C |

**Snapshot, not window:** the state is one time-slice; the `A` matrix does the temporal work, so
delay-embedding would double-count. Each channel is still a *smoothed estimate* — the smoothing
kernel width is a real tuning knob. **Start with Side A alone**, prove the loop, then add spectral.

### 2.2 Mapping onto existing infra (it's composition, not construction)

| Intent | Exists as |
|--------|-----------|
| Manual fit, scoped by categorical | `mdlObject.compileSTAT()` (ctg-driven) → `fit()` |
| Transform independently | `scaleApply_transform()` writes `dfID_target` row-by-row |
| Projector slots (plug/swap) | `nexFit_pca / _dpca / _ssm / _cebra / _lds / _tdr` |
| Accumulate across sessions | ctg selection spans diskDTS; `compileSTAT` reads HDF5 manifest |
| Load yesterday's / offline model | `saveFit`/`loadFit` + dehydrate/rehydrate (`mdlObj_fromState`) |
| Launch | `nexLaunch` + `nexLaunchAdapt_*` registry (ctg hub) |
| State color | `parseSessionLabel` → phase → CCI/noCCI |

### 2.3 Online/offline unification (the discipline)

**Fit is the only thing that differs; `transform` is shared.** Offline = fit + transform on the whole
DTS; online = `loadFit` a frozen projector + stream through `transform`. Never let the online path
have a bespoke transform. The "chain" across phases is the **dfID lineage in HDF5**
(`RTS_spk_activity → pca_spk`; `… → ssm_spk → dpca_ssm_spk`), not live object linkage.

**Frame consistency:** an evolving/accumulating fit rotates the basis, so **re-transform all data
through one basis when comparing**. Minimal provenance = "which fit-version produced these
coordinates," not a full manifold registry.

### 2.4 von Frey label bus

- Transmit from the cortex-host von Frey panel over `proxy_ncortex`, **keyed by the host-assigned
  trial index** (the join key to neural capture).
- **Triple duty:** epoch marker (cut trajectories at onset) + label (force, threshold, delay) +
  future `u_t`.
- **Causal vs. retrospective:** force is known at delivery; withdrawal threshold/delay are scored
  *after* — pipeline needs a "backfill color when the label arrives" path.
- **Clock (pragmatic, imec↔speedgoat stringing tabled):** SpikeGLX trigger = coarse `t=0`, prebuffer
  `-3.5 < t < 0`, `t > 0` after; manual cortex-host onset index = fine offset within the window.

### 2.5 Manual fit/transform via the categorical

The `nexObj_ctg` selection is the **single control surface**: it scopes the fit (curate out duds),
drives cross-session accumulation, and gates which von-Frey-keyed trials enter the manifold.
Independent fit/transform triggers mirror the existing `reportAvg`/`buildSTATE` split.
**Guard:** surface which fit-version the current coords came from (stale-fit foot-gun).

---

## 3. MSR — folded into the Domain bus (today's build)

### Problem
`RTS_spk_activity` is `(unit × t × measure)` with `measure = [raster, rate, amp]`. PCA fit
(`nexFit_pca`) needs a 2D `(samples × feature)` design matrix. `nexOp_stackSamples` keeps *all*
non-`D1` dims and **`FTR` is not actually used to reduce** — so `measure` won't collapse on its own.
The **Pointer bus cannot single-select** (single/full selections are pass-through by design), so it
can't isolate `rate`.

### Design — the three Domain selections **partition** the source axes
`MSR` is **not** a separate bus; it is a third selection *inside* `collector.Domain`, alongside the
existing `D1`/`FTR`, and synced by the existing `applyDomainBus`:

- **`D1`** → sample rows (`t`)                          *(axis-role selector)*
- **`FTR`** → concatenated feature columns (`unit`)     *(axis-role selector)*
- **`MSR`** → **value** selector over the residual axis left after D1/FTR (here `measure`)

**MSR semantics (differ from Pointer):** a subset selection *including a single value* **collapses**
the residual axis; a full selection is pass-through (**loop — dormant** until the fit path iterates
slices). Default = the `rate` value if present, else all. **Pointer stays untouched.**

### Built today (`utils/Nexus/Analysis/mdlObj/mdlObject.m`)
- `initDomainBus()` — builds `collector.Domain` with `D1`/`FTR` **+ `MSR`** (values of the residual
  axis), sets `domain.MSRaxis`, defaults MSR to `rate`. Mirrors the figures' inline domain build so
  it also works headlessly.
- `applyDomainBus()` — now also syncs `domain.MSR` from the bus (one method owns all three).
- `applyDomainMSR(STAT)` / `applyDomainMSRDF(DF)` — thin fit-side / transform-side adapters that both
  call one shared **`domainSliceAxis`** helper (DRY). No-ops unless `domain.MSRaxis` is set, so
  existing `ssm`/`dpca`/`lda`/`linear` are untouched.
- Wired: `applyDomainMSR` in `compileSTAT` (after Pointer), `applyDomainMSRDF` in
  `scaleApply_transform` (before permute).
- `mdlObj_pca`: constructor narrows `FTR → D2(1)` (`unit`) then calls `initDomainBus()`;
  `getDesignMatrix` overrides to `squeeze` the singleton residual so the fit sees 2D.

**No separate `collector.MSR`, no `initMSRBus`/`applyMSR` trio** — the earlier fragmented version was
replaced. **All untested** — needs a rig run.

---

## 4. Roadmap

### v1 — labeled firing-rate manifold (in progress)
1. MSR-in-Domain mechanism + `mdlObj_pca` wiring ✔ (built, untested).
2. `nexFigure_pca` ✔ (built, untested) — scree canvas + sidebar: Pointer / Domain (`D1`/`FTR`/`MSR`)
   / fit cfg / **Fit · Transform→DTS · Visualize** buttons. Domain built via `mdlObj.setupDomain()`
   (shared with the headless path). *Not yet added:* a View (SRC·VW·CLR) panel.
3. `nexLaunchAdapt_pca` ✔ + paired `pca → nexObj_stateSpace` ✔ (built, untested) — the adapter makes
   `pca` launchable from the ctg hub; the pca figure's **"→ StateSpace"** button opens
   `nexObj_stateSpace` on `mdlObj.dfID_target` (`pca_<source>`), scoped by the same ctg. Data
   dependency: run **Fit → Transform** (writes the dfID) *before* → StateSpace.
4. Color stateSpace by `parseSessionLabel` phase (CCI/noCCI) + withdrawal threshold/delay.
5. **Deliverable:** von-Frey-onset-aligned, labeled firing-rate manifold — pure geometry, no
   dynamics. This is the "region meaning discovered from labels" step + visual precursor to dPCA.

### v2 — dynamics + demixing + accumulation
- **dPCA on raw rates** (label-aware DM builder, marginalize by force/state/time) — canonical dPCA;
  becomes a stage-equal sibling of PCA. `xPCA ↔ SSM` sequencing free via dfID lineage.
- **SSM** (`A`,`C`) on rates; eigenspectrum, forecasting.
- **Input term `u_t`** (von Frey) → `B`; begin control/RL formalism.
- **Trivial-vs-vital tests** (prediction-vs-AR-null, tangling).
- **Cross-session shared-`C` stitching** + alignment validation (LOSO, nulls, held-out decode).

### Later
- CEBRA cross-subject embedding; Side D (specparam); **DN-as-loop** (per-slice fit for multi-value
  MSR); RL reward/target region on the aligned manifold.

---

## 5. Open questions / hazards
- **imec↔speedgoat clock stringing** deferred (needs SpikeGLX fetch refinement + a second
  speedgoat↔cortex_target axon line); coarse trigger alignment suffices for now.
- **Cross-session frame consistency** — re-transform on compare; light fit-versioning.
- **Domain/MSR init timing** — `DF_postOp.ax` may not be populated at pca construction, so
  `initDomainBus()` falls back to reading `dfID_source` from HDF5; `nexFigure_pca` should re-init once
  data is present. Also: interactively re-assigning `FTR` to a *different* residual axis won't
  auto-refresh the MSR candidate values (built once) — fine for the default flow; document if it bites.
- **`chans`** is a per-unit co-indexed label, not its own array dim — if it lands as `residual(1)`
  ahead of `measure` the MSR slice would target the wrong axis; verify residual ordering on the rig,
  and if needed skip axes without a distinct `ptr.dim`.
- **Everything built today is untested** — first rig run should: construct `mdlObj_pca` on a ctg
  scoped to `RTS_spk_activity`, confirm `collector.Domain` has an `MSR` key defaulting to `rate`
  (`domain.MSRaxis == "measure"`), run `fit()`, verify the design matrix is 2D `(T × unit)`.
