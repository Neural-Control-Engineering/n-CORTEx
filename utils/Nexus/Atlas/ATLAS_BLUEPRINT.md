# Nexus Ephys Atlas — Architecture Blueprint

## Overview

The Nexus Ephys Atlas is a per-subject, session-accumulating probabilistic framework that infers
the most likely brain region identity for each channel along a Neuropixels probe. It fuses three
sources of evidence:

1. **Allen CCF prior** — the registered probe trajectory from Neuropixels Trajectory Explorer (NTE),
   already stored per-subject and loaded at nexon startup
2. **IBL Brain-Wide Map reference** — per-region electrophysiological feature distributions pulled
   from the IBL ONE API (spontaneous and Brain-Wide Map sessions)
3. **Your own recordings** — per-channel firing rate, waveform, and LFP spectral statistics
   extracted from the DTS each session and used to update a Bayesian posterior

The output is a `region × channel` probability heatmap that sharpens with every session and
integrates directly into Nexus' visualization and color-mapping infrastructure.

---

## Design Principles

- **Channel backbone, not unit backbone.** Channels are the primary spatial axis because they are
  stable across sessions and co-index LFP and spike data naturally. Units are registered *to*
  channels via their spatial centroid — they inherit region probability from the channel they live
  on rather than carrying independent region assignments.

- **Probability over labels.** Every output is a distribution over candidate regions, not a hard
  assignment. The MAP (maximum a posteriori) label is one readable summary, but the full
  `[n_channels × n_regions]` posterior is what evolves and what downstream consumers should read.

- **Session-accumulating.** Each session contributes a likelihood update. The posterior after
  session N becomes the prior for session N+1. The atlas literally gets more confident over time.

- **One file per subject, not per session.** The atlas is a persistent belief state about a
  subject's probe placement, not a per-session result. It lives at the subject level alongside
  the NTE region mapping.

---

## Storage

### Location
```
Subject/<subjectID>/npxls/
├── region_mapping.csv          ← NTE prior, already present, hard channel→region
└── ephys_atlas.h5              ← NEW: probabilistic atlas, grows each session
```

### HDF5 Schema

```
ephys_atlas.h5
│
├── /prior/
│   ├── channel_depths      (n_ch,)          µm along probe shank
│   ├── region_acronyms     (n_regions,)     e.g. ["SSp","CA1","VPM","VPL","ZI","STN"]
│   └── P_region_channel    (n_ch × n_reg)   soft NTE prior, Gaussian-blurred at boundaries
│
├── /reference/                              IBL ONE API pull — cached, not session-specific
│   ├── firing_rate         (n_reg × 2)      [µ, σ] per region
│   ├── cv_isi              (n_reg × 2)
│   ├── waveform_width      (n_reg × 2)
│   ├── lfp_beta_power      (n_reg × 2)
│   ├── aperiodic_exp       (n_reg × 2)
│   └── last_updated        string           ISO timestamp; drives refresh cadence
│
├── /sessions/
│   └── /<sessionLabel>/
│       ├── phase               string          'spontaneous' / 'spontaneous-CCI' / ...
│       ├── features_immediate  (n_ch × n_feat) ISI + waveform — written at extraction
│       ├── features_deferred   (n_ch × n_feat) rtPMTM bands, fooof — written post-extraction
│       ├── posterior_contrib   (n_ch × n_reg)  this session's likelihood update
│       └── contributed         bool            has this been folded into phase posterior yet
│
├── /posteriors/
│   ├── /<phase>/                              one group per observed phase
│   │   ├── posterior      (n_ch × n_reg)
│   │   ├── n_sessions     scalar
│   │   └── last_updated   string
│   └── /canonical/                           merged from eligible phases
│       ├── posterior      (n_ch × n_reg)
│       ├── phases_included  string array     phases that passed eligibility
│       └── last_updated   string
│
│   Merge eligibility: phase must have (1) n_sessions > 0 AND
│   (2) listed in /config/canonical_eligible_phases (user-controlled).
│   Weights proportional to n_sessions. Implemented in nexAtlas_mergeCanonical.
│
├── /config/
│   ├── canonical_eligible_phases   string array   default: ['spontaneous', 'Baseline']
│   └── reference_note              string         "IBL BWM task sessions; phase-agnostic
│                                                   population prior on region identity"
│
├── /units/                                  cross-session unit identity catalog
│   ├── /catalog/
│   │   ├── global_id           (n_units,)
│   │   ├── ch_centroid         (n_units,)   depth in µm; anchors unit to channel backbone
│   │   ├── template_KS4_mean   (n_units × n_samples × n_ch)
│   │   ├── template_RTS_mean   (n_units × n_samples × n_ch)
│   │   ├── template_fused      (n_units × n_samples × n_ch)   weighted blend, evolving
│   │   ├── n_sessions_KS4      (n_units,)
│   │   └── n_sessions_RTS      (n_units,)
│   └── /sessions/
│       └── /<sessionLabel>/
│           ├── KS4_local_ids   local cluster IDs from Kilosort4
│           ├── RTS_local_ids   local unit IDs from RTSort
│           ├── global_ids      mapped global catalog IDs (NaN = new unit)
│           └── match_conf      UnitMatch confidence scores
```

---

## How IBL Data and Your Data Fuse

They never merge as raw datasets. The fusion is indirect:

**IBL data → used once, offline, to fit the Gaussians in `/reference/`**

    IBL: 200 STN neurons across 14 probes
         → PTD values: mean=0.38ms, std=0.12ms
         → written to /reference/STN/mu, /reference/STN/sigma
         → done. IBL is not touched again during analysis.

**Your data → evaluated against those Gaussians each session**

    You record a unit on ch=60 with PTD=0.35ms.
    Ask: how likely is PTD=0.35 under each region's model?
        STN model N(0.38, 0.12): fairly likely   → high score
        ZI  model N(0.42, 0.15): somewhat likely → medium score
        CA1 model N(0.52, 0.20): unlikely        → low score
    Those scores weight the posterior update.

The contact point is a single line — the Gaussian evaluation in nexAnalysis_ephysAtlas:

    -0.5 * ((your_PTD - IBL_mu) / IBL_sigma)^2 - log(IBL_sigma)

IBL defines the coordinate system (what features look like per region).
Your data moves probability mass within it. That's the full extent of their interaction.

**Calibration caveat:** If your neurons systematically differ from IBL's (anesthesia,
species prep, recording conditions), the Gaussians are miscalibrated and posterior updates
will be biased. The wide σ in literature priors partially absorbs this. The principled fix
is empirical Bayes — re-estimate µ/σ per region from your own accumulated sessions and
replace the IBL values in `/reference/`. Worth revisiting once you have enough sessions to
see whether the IBL reference produces sensible posteriors on your data.

---

## The Bayesian Update Loop

```
Each session:

  nexDTS.h5  (trial-level spike + LFP data)
      │
      ▼  nexAnalysis_ephysAtlas: aggregate per channel
  features   [n_ch × n_features]
      │  firing rate, CV, waveform width, LFP band powers, aperiodic exponent
      │
      ▼  likelihood:  P(features | region)  from /reference/ Gaussians (IBL)
      ▼  prior:       /posterior_current    from previous session
      ▼  multiply per channel, normalise over regions
      │
  posterior_new   [n_ch × n_regions]
      │
      ├──▶  write  /sessions/<date>/posterior
      └──▶  overwrite  /posterior_current
            │
            ▼  nexon startup next session
        channel registry annotated with MAP region + probability
            │
            ▼  CLR bus:  "ax--region", "ax--region_prob"
        all nexObjects with chans axis gain region coloring automatically
```

---

## IBL ONE API Integration

### Access

```python
from one.api import OneAlyx
one = OneAlyx(base_url='https://openalyx.internationalbrainlab.org',
              password='international', silent=True)
```

No account required. Public read-only access to the full IBL dataset.

### Atlas hierarchy — use Beryl (not Allen)

| Mapping  | N regions | Notes |
|----------|-----------|-------|
| Allen    | 1328      | Too fine — sparse counts per region |
| **Beryl**| **308**   | Used in BWM papers; right granularity for reference distributions |
| Cosmos   | 10        | Too coarse |

### Reference build pattern

```python
from iblatlas.regions import BrainRegions
br = BrainRegions()

your_regions = ['SSp', 'CA1', 'VPM', 'VPL', 'ZI', 'STN']

for region in your_regions:
    eids, _ = one.search(brain_region=region,
                         dataset=['spikes.times', 'clusters.metrics'])
    # Pull pre-computed metrics (no raw spike train streaming needed)
    for eid in eids[:20]:
        clusters = one.load_object(eid, 'clusters', collection='alf/probe*')
        region_id   = br.acronym2id(region, mapping='Beryl')
        region_mask = clusters.brainLocationIds_ccf_2017 == region_id
        # accumulate firing_rate, waveform_width, etc. from clusters.metrics
```

Cache result as `/reference/` datasets in `ephys_atlas.h5`. Refresh periodically via
`last_updated` timestamp.

### LFP spectral features

IBL BWM does not precompute band powers or aperiodic exponent. Two paths:

1. **Self-normalising depth profile.** Use your own recording's depth gradient for LFP features.
   The relative shift crossing ZI → STN matters more than absolute values. No external reference
   needed; compare depth profile shape against the NTE boundary predictions.

2. **Compute from IBL raw LFP.** For 3–5 BWM sessions per region with clean coverage, download
   LFP via ONE and run your existing rtPMTM + FOOOF pipeline. One-time computation, cached in
   `/reference/`.

For now: approach 1 for LFP; approach 2 deferred until spike-feature reference is working.

---

## Sorter Integration — KS4 and RTSort as Complementary, Not Redundant

RTSort and Kilosort4 have structurally different strengths:

- **Kilosort4**: template matching via convolution across the full probe. High-quality templates
  from the full session. Runs offline.
- **RTSort**: spike localization via spatial channel footprints. More robust to template drift
  and waveform overlap. Runs online and outputs in near-real time.

Rather than RTSort being a provisional pass that KS4 overwrites, both sorters are treated as
independent evidence sources that are fused in the unit catalog.

### Session workflow

```
During session:   RTSort → online templates → registered to catalog at session end
                  (provisional global_ids, match_conf typically lower)

Overnight:        KS4 → offline templates → registered to same catalog
                  (does NOT overwrite RTSort entries — adds parallel KS4 track)

Both:             template_KS4_mean and template_RTS_mean maintained separately
                  template_fused = weighted blend, weights driven by n_sessions_* counts
                  and per-sorter match confidence
```

### Unit confidence metric

A unit seen by both sorters in the same session and matched to the same global_id is the
highest-confidence evidence. Progressively:

| Evidence | Confidence |
|----------|------------|
| Both sorters, same session, same global_id | Highest |
| One sorter, multiple sessions, consistent global_id | High |
| One sorter, single session | Provisional |
| Sorter mismatch (KS4 and RTS disagree on global_id) | Flagged for review |

### Fusion roadmap

Initially: two separate template stores in catalog, matched independently.  
Eventually: a joint template model that takes KS4's waveform shape fidelity and RTSort's
spatial localization precision and produces a single fused template per global unit, driving
a more robust cross-session matcher than either sorter alone.

---

## Nexon Registry Integration

### Startup hook (extends existing NTE load)

```matlab
% Existing — hard NTE prior (unchanged)
regMap = nexAtlas_loadRegMap(subjectDir);

% New — probabilistic posterior
atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');
if isfile(atlasFile)
    atlas = nexAtlas_load(atlasFile);
else
    atlas = nexAtlas_initFromPrior(regMap);   % first session: NTE prior as posterior
end

nexon.atlas    = atlas;
nexon.registry = nexAtlas_annotateChannels(atlas, nexon.registry);
% Injects: registry.ax.region (MAP string per channel)
%          registry.ax.region_prob (posterior probability of MAP label)
```

### CLR bus propagation

Once `ax.region` and `ax.region_prob` are in the channel registry, they surface as `"ax--region"`
and `"ax--region_prob"` in every nexObject's CLR bus — the same mechanism as `"ax--chans"` today.
No per-nexObject changes required. polyGraph, waterfall, stateSpace, and any future nexObject with
a `chans` axis automatically gain region coloring and confidence coloring.

---

## Feature Extraction (per channel, per session)

All features computed by `nexAnalysis_ephysAtlas` from the DTS before the Bayesian update:

| Feature | DTS Source | Notes |
|---------|-----------|-------|
| Mean firing rate | `KS_spk_activity_df` rate slice | mean over trials, per unit → root channel bin |
| CV of ISI | `KS_spk_activity_df` raster | `nexOp_ISIstats` — to be written |
| Waveform peak-to-trough width | `KS_spk_templates_df` | argmin − argmax on peak channel template |
| LFP aperiodic exponent | FOOOF output | already extracted per channel |
| LFP theta/beta/gamma power | rtPMTM spectrogram | already computed |

All features are aggregated into 50 µm depth bins, matching the channel spacing, so spike and
LFP features live on the same spatial axis.

---

## Build Sequence

| Step | Component | Output / Unblocks |
|------|-----------|-------------------|
| 1 | `nexAtlas_queryIBL(regions)` — Python | `atlas_reference.mat` cached per subject |
| 2 | `nexAtlas_load` / `nexAtlas_save` | HDF5 plumbing for `ephys_atlas.h5` |
| 3 | `nexAtlas_initFromPrior(regMap)` | Bootstrap from NTE when no sessions yet |
| 4 | `nexAtlas_annotateChannels` | CLR bus gains `ax.region` immediately, before Bayesian machinery |
| 5 | `nexOp_ISIstats` | Completes the per-channel feature vector |
| 6 | `nexAnalysis_ephysAtlas` | Full Bayesian update per session |
| 7 | `nexVisualization_ephysAtlas` | Region × channel heatmap nexObject (the HUD) |
| 8 | `nexAtlas_registerSession` | Unit catalog: KS4 + RTSort → global IDs via UnitMatch |
| 9 | Sorter fusion | Weighted template blend, joint matching metric |

Steps 3–4 give visible payoff (region-colored channels everywhere) before any Bayesian update
logic exists. Step 8 onward is the unit-tracking layer and can proceed independently once the
channel-level atlas is stable.

---

## Key External Dependencies

| Tool | Role | Status |
|------|------|--------|
| `one-api` (3.5.2) | IBL data access | Installed in nexus conda env |
| `iblatlas` (1.2.0) | CCF region queries, Beryl mapping | Installed |
| `brainbox` | Per-unit metrics from IBL sessions | Installed |
| `ibllib` (4.0.1) | IBL processing pipelines | Installed |
| **UnitMatch** | Cross-session unit identity matching | To be installed |

---

## Open Questions

1. **IBL spontaneous vs. task sessions as reference.** BWM used a visual decision task; your
   recordings are spontaneous or sensory-evoked under anesthesia. Firing rate reference from
   spontaneous IBL sessions (where available) will be more comparable than BWM task-engaged
   rates. Verify coverage of your specific regions (STN, ZI) in IBL spontaneous sessions before
   relying on the reference.

   **Phase stratification (design decision, locked):** Atlas maintains one posterior per phase,
   plus a merged canonical posterior. HDF5 layout:

   ```
   /posteriors/
       spontaneous/
           posterior      (n_ch × n_reg)
           n_sessions     scalar
           last_updated   string
       spontaneous-CCI/
           posterior      (n_ch × n_reg)
           n_sessions     scalar
           last_updated   string
       canonical/
           posterior      (n_ch × n_reg)   — merged from eligible phases
           phases_included  string array   — which phases contributed
           last_updated   string
   ```

   **External reference is phase-agnostic:** The IBL brain-wide map reference is a
   population-level distribution [µ, σ] per region derived from BWM task sessions — it carries
   no phase label and is a valid comparator for any of your phases as a region identity prior.
   "Has an external reference" does not mean IBL has a matching experimental phase; it means
   the region has real IBL-derived data (n_units > LITERATURE_N) that is interpretable as a
   baseline for probe localization.

   **Merge eligibility:** A phase participates in canonical if (1) `n_sessions > 0` and (2) it
   is listed in `/config/canonical_eligible_phases` — a user-controlled list, default
   `['spontaneous', 'Baseline']` (both are treated as equivalent pre-condition baselines). Adding a phase to this list is a deliberate judgment that its physiology
   is comparable enough to the IBL reference for probe localization to be meaningful. For
   example, `spontaneous-CCI` may eventually qualify if its distributions remain coherent with
   the reference; task/stimulation phases likely never qualify.

   **Merge strategy (to be implemented in `nexAtlas_mergeCanonical`):** weighted average of
   eligible per-phase posteriors, weights proportional to `n_sessions`. In practice today
   canonical = spontaneous; the merge machinery activates automatically when a second eligible
   phase accumulates sessions. At nexon startup, canonical posterior is loaded by default.

2. **LFP reference — deferred until spike-feature cycle is validated.**
   IBL does not provide pre-computed LFP features (no fooof, no band powers). Their
   `_iblqc_ephysSpectralDensityLF.power` dataset contains raw per-channel LFP PSD, but
   extracting per-region [µ, σ] from it requires a custom pipeline (load PSD, map channels
   to CCF regions, compute bands / fooof per region across sessions) — non-trivial legwork.
   For now: `/reference/<region>/` will only hold spike features (ptd_ms, firing_rate_hz,
   cv_isi). The Bayesian update is additive and skips absent features automatically, so LFP
   slots in cleanly whenever it's ready.

   When revisiting: the natural split is rtPMTM band powers at extraction time (fast, already
   in pipeline) and fooof aperiodic exponent as a post-augment step via `nexAtlas_updateSession`.
   IBL LFP PSD can supplement the reference for common regions (CA1, SSp, VPM) once that
   pipeline exists; STN/ZI will likely stay self-referential from your own recordings.

3. **UnitMatch thresholds.** The match confidence threshold for declaring two units the same
   neuron across sessions will need calibration against your specific probe model and recording
   stability. Start conservative (high threshold, more new-unit declarations) and relax as the
   catalog matures.

4. **RTSort↔KS4 within-session matching.** Before cross-session fusion, we need within-session
   matching: which RTSort unit is the same neuron as which KS4 unit in the same session? This
   is the first fusion step and determines the quality of the fused template.

5. **IBL query: pre-filter by probe insertion region (TODO).** Current `nexAtlas_queryIBL.py`
   iterates all sessions in chronological order and loads cluster region labels per-session just
   to check membership — slow for dense regions (CA1, SSp). Replace `one.search(datasets=...)` 
   with a probe-insertion query (`one.search(atlas_acronym=<region>)` or via the `/insertions`
   Alyx endpoint) so only sessions where the probe actually traversed the target region are
   fetched. Also add `Good_ID` quality filtering when ready to tighten the reference distributions.

6. **Multi-database blend mode (TODO).** `nexAtlas_queryIBL.py` queries only the IBL Alyx
   instance (alyx.internationalbrainlab.org). To supplement STN/ZI coverage from other sources
   (Allen Cell Types DB, CRCNS, DANDI), add a `--blend` flag that merges a second-pass query
   result with existing `/reference/` entries rather than overwriting — weighted by `n_units` so
   the larger dataset dominates. Each source would be a separate adapter function alongside the
   ONE query.
