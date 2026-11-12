# Neural Field Model (NFM) — Side Note

**Status:** Optional / bonus track. Not on the Paper 2 critical path.
**Created:** 2026-10-31
**Go/no-go:** end of manuscript month 2 (~early January 2027). No working fit by then →
moves to thesis Chapter 3 or a standalone collaborative paper.

Starting point already in this folder: `CTBG/` — a corticothalamic–basal-ganglia field
model (`CTBG001.slx`, `setCTBGparams.m`, Robinson / van Albada-style parameter table),
built early 2025.

---

## Why an NFM — the bridge between PSD and SSM

A linear(ized) dynamical system's power spectrum is determined by its **poles**
(eigenvalues). Spectral peaks = oscillatory poles; aperiodic slope/knee = damped real poles.

| Analysis | What it measures |
|---|---|
| LGSSM on firing rates (`mdlObj_ssm`) | Poles of the *spiking* population dynamics (eigenvalues of `A` → τ, f) |
| PSD bands / aperiodic shape | Spectral signature of poles in the *field* (LFP) dynamics |
| **NFM** | Mechanistic link: physiological parameters (synaptic time constants, gains, conduction delays, spatial coupling along the probe) → poles → spectrum |

The NFM is also the answer to the specparam identifiability frustration: it replaces a
phenomenological description (exponent + peaks) with parameters that carry physiological
meaning.

**Precedent:** Robinson corticothalamic field theory fit to EEG spectra; Freestone et al.
Kalman-type estimation of neural field models from intracranial data; DCM for steady-state
LFP spectra (Moran, Friston). **Novel here:** fitting along a Neuropixels depth axis through
STN / ZI / thalamus (VPL, VPM, LD) / CA / SSp, contrasted by von Frey threshold and pre/post CCI.

---

## Technical path

The NFM is nonlinear — existing LGSSM machinery does not apply directly. Two options:

1. **Linearize around steady state → transfer function → fit PSDs directly.**
   Cheapest, most common. Recommended first route.
2. **EKF / UKF** for time-domain fitting. Later, if needed.

What carries over from Nexus: subject × phase × task-variable scoping, disk-backed h5
datastores, mdlObj fit/score structure. What's new: the estimator itself.

**Identifiability (again):** NFMs have more parameters than spectra can constrain. Fix most
from literature (the `setCTBGparams.m` table); fit only the few the threshold / injury
contrast speaks to (e.g. a gain or time constant in the STN / thalamic loop).

---

## Place in the manuscript

- **Paper 2 must be complete without it.** Fig 3 (gamma band finding) stays purely empirical.
- **Slot:** Fig 6 or supplement — "a field model reproduces the threshold-dependent gamma
  change through a shift in parameter X, consistent with the SSM timescale change."
- **Fallback if it doesn't land:** Fig 6 is the empirical trial-by-trial gamma ↔ latent-
  dynamics bridge (already planned).

---

## Collaboration scope (draft for collaborator)

**Question.** Can a neural field model defined along the probe's depth axis reproduce
(a) the region-resolved LFP spectra during von Frey stimulation, and (b) the
high- vs low-threshold gamma difference at withdrawal, via a small, physiologically
interpretable parameter shift? Stretch: does the same model capture the pre → post CCI change?

**Division of labor.**
- *Me:* data package + interface; integration into Nexus fit/score machinery.
- *Collaborator:* model architecture, parameter selection / fixing, forward model.

**Data package (per subject × phase × condition × epoch):**
- depth × frequency PSDs (multitaper), with trial counts
- channel geometry (depths in µm, shank layout)
- CSD / locally re-referenced spectra
- region labels: NTE prior + ephys-atlas MAP + posterior confidence
- (optional) LGSSM eigenvalue summaries (τ, f) per region for cross-checking

Format: HDF5, one file per subject, keyed by phase / condition / epoch. Spec to be agreed
before export.

**Success criteria.**
1. Forward model produces spectra in the empirical range along depth (sanity).
2. Fit to baseline spectra with ≤ ~5 free parameters; held-out-trial spectra predicted
   better than a specparam-style phenomenological baseline.
3. The threshold contrast is captured by a shift in a small subset of parameters,
   with bootstrap CIs, consistent across mice.

**Timeline.** Data spec agreed → export (weeks 1–3) → first forward-model fit (by ~week 6)
→ go/no-go at end of month 2.

**Authorship.** Agree up front: (a) Fig 6 / supplement in Paper 2 → collaborator as co-author;
(b) if it grows into its own paper → shared lead, order to be agreed now.

---

## Open questions

- Which parameters are free vs fixed? (Collaborator's call, informed by `setCTBGparams.m`.)
- Spatial extent: model the full probe trajectory, or the STN / ZI / thalamic segment only?
- Epoch handling: fit steady-state spectra per epoch (before / during / after), or a single
  model with epoch-dependent input?
- Does fitting need LFP spectra from all ~9–10 baseline mice, or is a subset enough for a first pass?
