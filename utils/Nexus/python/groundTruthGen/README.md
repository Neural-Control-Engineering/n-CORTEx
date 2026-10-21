# groundTruthGen — Synthetic Aperiodic/Periodic Spectral Ground-Truth Generator

## Purpose

We're fitting a segmented, multi-knee Lorentzian ("broken power-law") model to
neural power spectra, and the fit has a known identifiability problem: for a
given spectrum, many different combinations of corner frequency (FC) and
exponent (EXP) land on visually/numerically equivalent fits. We're resolving
that with a hierarchical shrinkage scheme (per-parameter population priors
pooled across many real trials, used to regularize each individual fit), but
that scheme can never be validated against real data alone — real data has no
known ground truth, so a method with a *systematic* bias (as opposed to
random noise) would look self-consistent forever and we'd never catch it.

**This package exists to break that circularity.** It generates synthetic
power spectra from *known* parameter values (sampled from configurable prior
distributions), so the real fitting/shrinkage pipeline can be run against
data where the right answer is known in advance. The output of this package
feeds three deliverables we need from the synthetic side:

1. **Recovery bias**: `mean(estimated_param − true_param)` per parameter, per
   model order N — nonzero means the detector/fitter has a structural bias
   that more real-world trials cannot fix.
2. **Calibration**: do the shrinkage estimator's credible intervals actually
   contain the true parameter at their nominal rate?
3. **Model-order recovery**: given data simulated with a known true N, does
   BIC-based model selection recover that N?

Those three checks (plus standard R²/MAE against the known-clean spectrum)
are computed downstream, in the orchestration layer that also owns the
real-data population priors and the FC-ordering/BIC/shrinkage constraints.
**Your scope is the generator itself: given a model order N, a prior config,
and a sample count M, produce a dataset of (true parameters, clean spectrum,
noisy spectrum) tuples that are faithful to the real forward model below.**
See "Interface / ownership seam" at the bottom for exactly where your
responsibility ends and the orchestration side picks up.

---

## The forward model

### Two different quantities named with the same letters — keep them apart

`EXP1, EXP2, EXP3` means **one specific thing throughout this document and
in the real codebase: the local, independently-measured log-log slope in
each frequency band**, exactly as you already use the term when
hand-titrating a fit or reading out a real segmented fit's result. That's
what `specParam_multiExp.m` actually produces — it slices the spectrum into
frequency segments at the corner frequencies and fits each segment
independently, in `specparam`'s plain `'fixed'` (single-exponent, no knee)
mode, using only that segment's own data. `EXP2` has no numerical
relationship to `EXP1`; it's just "what the slope looked like in that
window." **This is the quantity this package samples priors for and
reports as ground truth.**

The kernel that actually synthesizes a smooth, continuous curve —
`kernel/kernel_specparam_segmented_multiexp.m` — needs a *different*
quantity as input, which this document calls `d_k` (never `EXP_k`, to avoid
exactly the confusion this section exists to prevent):

```
fit_AP = -log10((1+if/FC1)^d1) - log10((1+if/FC2)^d2) - log10((1+if/FC3)^d3)
```

Each term is a classic single-knee Lorentzian: ~flat for `f ≪ FC_k`,
settling into a constant `-d_k` slope for `f ≫ FC_k`, and it never flattens
again afterward. Stack three of these with `FC1 < FC2 < FC3` and the
*visible* local slope in each band is the **cumulative sum** of the `d`'s
up to that point, not the individual `d_k`:

- between FC1–FC2: `≈ -d1`               → this band's `EXP1 = d1`
- between FC2–FC3: `≈ -(d1 + d2)`         → this band's `EXP2 = d1 + d2`
- beyond FC3: `≈ -(d1 + d2 + d3)`         → this band's `EXP3 = d1 + d2 + d3`

```
EXP_k = d1 + d2 + ... + dk          (atomize: kernel increments -> local slopes)
d_k = EXP_k - EXP_{k-1}, EXP_0 = 0  (local slopes -> kernel increments)
```

Atomizing a jointly-fit kernel's `d`'s back into locally-meaningful slopes
is exactly this partial-sum — no information lost, no re-fitting needed.
It's exact in the well-separated-knee limit (each term has mostly saturated
before the next one's transition starts, true for the kernel's own
defaults FC1=7/FC2=63/FC3=250, roughly a decade apart each); if corners sit
close together the true instantaneous slope blends smoothly through the
transition rather than stepping cleanly, so the correspondence gets blurry
near the boundary — worth knowing, not a blocker here.

**Constraint: `EXP1 < EXP2 < EXP3` (a spectrum can't get shallower at higher
frequency) is equivalent to requiring `d_k > 0` for every k — not a separate
rule to check.** Since `EXP_k = d1 + ... + dk`, non-negative (and, for a
continuous positive-support prior, strictly positive) `d`'s make `EXP_k`
automatically non-decreasing in `k`. **This means `d` — not `EXP` — is the
thing to sample from a prior**, exactly like the FC ordering increments:
draw each `d_k` from a strictly-positive distribution (log-space Normal, see
config schema below) and derive `EXP_k` as its cumulative sum, rather than
sampling `EXP_k` directly and trying to recover `d` by subtraction. One
honest caveat: this hard-codes "every knee adds steepness, none ever
removes it" — if that assumption turns out to be wrong for some real
spectra, relaxing it means allowing negative `d_k`, which breaks both the
automatic ordering and the "a knee is a non-negative dose of extra
steepness" reading of the kernel. Not needed now; worth remembering why the
constraint is there if it's ever revisited.

**Known issue in the existing MATLAB pipeline, flagged for your awareness,
not yours to fix as part of this package:** `spcpmIO_specs2kernel.m`
currently takes a real segmented fit's own `EXP1/EXP2/EXP3` (local slopes)
and assigns them *directly* into the kernel's `args.EXP1/EXP2/EXP3` (i.e.
what this doc calls `d1/d2/d3`) with no conversion. Any reconstruction that
goes through that path currently over-steepens bands 2 and 3 by
compounding — it won't match the true piecewise fit except trivially in
band 1. That's a real inconsistency independent of this generator.

**Rule for this package: sample priors for `d1, d2, d3` (strictly positive,
kernel-native), but report only `EXP1, EXP2, EXP3` (local slopes, `=
cumsum(d)`) in the dataset.** `EXP` is the form directly comparable to what
`specParam_multiExp.m` outputs on real data; `d` is purely an internal
generation detail — sampled and consumed inside `compositor.py`/`kernel.py`,
never exposed in the dataset's output columns. If the `EXP = cumsum(d)`
bookkeeping is implemented incorrectly, every downstream bias/calibration
check becomes meaningless — see the required round-trip sanity check below.

### Periodic component

```
fit_PE = Σ_j  PW_j * exp( -(f - CF_j)^2 / (2 * BW_j^2) )     # Gaussian peaks
fit = fit_AP_log + 10 * fit_PE
```

Independent of aperiodic model order N — driven by however many CF/PW/BW
triplets are configured. Keep it a separate config axis from N.

---

## Model order N, and what unused slots contain

N ∈ {1, 2, 3} is the number of active knees. The parameter vector is always
7 aperiodic slots wide (`OFF, EXP1, EXP2, EXP3, FC1, FC2, FC3`); N controls
which slots are sampled from a real prior vs. filled by a fixed rule. **The
fixed rule is not a free choice — use exactly this:**

| slot | k ≤ N (active) | k > N (inactive) |
|---|---|---|
| `FC_k` | sampled from its prior | **`Inf`** |
| `EXP_k` (local slope, reported) | sampled from its prior | **`NaN`** (not sampled, not 0, not Inf) |

**Why `FC_k = Inf`, not some large finite number:** it's the literal
mathematical limit of "this knee is arbitrarily far out," and it's exact and
numerically safe — `f/Inf = 0` in IEEE float, so `(1+0)^d_k = 1` and the
term contributes nothing, for *any* finite `d_k`. No special-casing needed
in the kernel.

**Why `EXP_k = NaN`, not `0` and not `Inf`:** both alternatives collide with
a meaning they already have elsewhere, which makes them unsafe sentinels.
`0` is a value a *real, existing* knee can legitimately have (a genuinely
flat segment is a real physiological case, not just a stand-in for "no
knee here") — reusing it for "doesn't exist" destroys that distinction.
`Inf` has no equivalent physical limit story for a slope the way it does
for a frequency — there's no "exponent of a knee that doesn't exist" to
asymptote toward, and mechanically it doesn't even matter: once `FC_k =
Inf`, the term is already fully dead regardless of what `EXP_k` is, so
writing *any* value there carries zero information and risks being
misread as meaningful. Mark it missing, explicitly.

**This has a direct, non-optional consequence for the output schema:
`N` (or equivalently `active_knees`) must be its own reported column, not
something a consumer infers by inspecting FC/EXP magnitudes.** A downstream
model trained on this dataset should predict `N` as a categorical head and
mask the continuous `EXP_k`/`FC_k` losses by the true `N` per sample — not
be asked to learn that "very large" or "exactly zero" means "ignore this."
A regression head is bad at reliably producing extreme values on cue anyway
(MSE actively fights large-magnitude targets); gating on an explicit
categorical `N` is the robust version of what you were trying to get a
numeric sentinel to do. The *generator's* job is just to emit `(Inf, NaN)`
by rule for inactive slots and never sample them — the masking/categorical
architecture is a note for whoever trains against this dataset, not
something this package needs to implement itself.

**Open item, your call, not the collaborator's:** `spcpmIO_multiSpecs2vector.m`
currently pads the *real* pipeline's output differently —
`s_AP = [s_AP, 0]; s_FC = [s_FC, 249]` for `rows < 3`. Both `0` and `249`
are a placeholder **exponent** and a placeholder **corner frequency in
Hz** respectively (`249` is unrelated to sample/bin count — it's not the
same kind of quantity as `frequency_axis.n_points` below, don't conflate
the two). If this package reports `(Inf, NaN)` while the real fitting
pipeline emits `(0, 249)`, every recovery-bias check for N<3 will show a
large, fake "bias" that's actually just two parts of the system
disagreeing about an encoding.

Decision for now: don't migrate `spcpmIO_multiSpecs2vector.m` yet. Instead,
add one small translation function — living only in the downstream
comparison/scoring code, not in this package — that maps the real
pipeline's `(EXP=0, FC=249)` to `(EXP=NaN, FC=Inf)` immediately before any
bias/calibration number is computed. This package's own output stays
exactly `(Inf, NaN)` as specified above; nothing here changes.

---

## Noise model: chi-squared, not additive Gaussian

Real PSD estimates are not Gaussian-noise-corrupted power values. A single,
unaveraged periodogram bin's power is `(true PSD) × χ²₂ / 2` — exactly,
not approximately — because a Fourier coefficient's real and imaginary
parts are each independent Gaussians (CLT over the time-domain samples),
and power is the sum of their squares, which is the literal definition of a
chi-squared variable with 2 degrees of freedom. Averaging `K` independent
segments/tapers (Welch/multitaper) sums `K` independent χ²₂'s into a
χ²_{2K}, scaled: `(true PSD) × χ²_{2K} / (2K)`. This is why real spectra get
smoother (lower relative variance, `∝ 1/K`) with more averaging, and why
they're right-skewed and floored at zero for small `K` rather than
symmetric — properties plain additive Gaussian-in-dB noise doesn't have.
Gaussian noise isn't a wrong alternative, it's the `K → ∞` limit of this
same construction; for short real-time epochs (small `K`, the actual
closed-loop use case) you're far from that limit and the skew matters.

```python
from scipy.stats import chi2

noisy_linear_power = true_linear_power * chi2.rvs(df, size=true_linear_power.shape) / df
noisy_db = 10 * np.log10(noisy_linear_power)
```

`df` (= 2K, number of averaged segments/tapers) is a required config knob —
the model-order-recovery and calibration checks need to sweep it to find
where recovery breaks down as epochs get shorter. Treating bins as
independent (ignoring windowing-induced bin-to-bin correlation) is an
accepted simplification for v1, not a blocker.

---

## Config schema: per-N Gaussian recipes

One YAML file per N. Every sampled parameter is specified as a Normal
distribution with `(mu, sd)` — no other distribution families. For
quantities that must stay strictly positive (`FC1` itself, and the
FC-increments that enforce ordering), the Normal is placed on the
**log** of the quantity — still literally "a normal distribution equation,"
just applied to a transformed variable, and it guarantees a positive draw
without needing truncation or rejection sampling.

```yaml
N: 2
aperiodic:
  OFF:   {mu: 10.0, sd: 1.5}                 # normal, linear space
  logD1: {mu: log(2.0),  sd: 0.3}             # normal on log(d1) -> d1 lognormal, always positive. EXP1 = d1 (implied mean EXP1 ~ 2)
  logD2: {mu: log(12.0), sd: 0.4}             # normal on log(d2) -> d2 lognormal, always positive. EXP2 = d1+d2 (implied mean EXP2 ~ 14, NOT 12 -- comment the implied EXP mean here whenever hand-editing, it's easy to forget this is an increment)
  # logD3 omitted -> N=2, generator fixes EXP3 = NaN, d3 unused, no sampling
  logFC1:  {mu: log(7.0),  sd: 0.3}        # normal on log(FC1) -> FC1 lognormal, always positive
  logDFC2: {mu: log(56.0), sd: 0.5}        # normal on log(FC2 - FC1) -> ordering enforced by construction
  # logDFC3 omitted -> N=2, generator fixes FC3 = Inf, no sampling
peaks:
  count: {mu: 1.5, sd: 0.8, min: 0, max: 4}   # rounded/clamped draw, kept simple deliberately
  CF:    {mu: 20.0, sd: 10.0}
  logPW: {mu: -1.0, sd: 0.5}
  BW:    {mu: 3.0,  sd: 1.5}
noise:
  model: chi2
  df: 8                                     # averaging/taper count
frequency_axis:
  f_start: 2
  f_end: 50
  n_points: 200
```

Generation recipe per sample, in order:
1. Draw `OFF` from its Normal prior (linear space).
2. Draw `d1..dN` from `exp(Normal(mu, sd))` (log-space -> strictly
   positive). This single positivity requirement is what makes both the
   kernel's knee semantics and the `EXP1 < EXP2 < EXP3` ordering hold
   automatically — there is no separate ordering step for EXP.
3. Draw `FC1` from `exp(Normal(mu, sd))`; draw each ordering increment the
   same way and cumulative-sum them into `FC2, FC3` as needed for N.
4. Set every `d_k`/`FC_k` for `k > N` to unsampled/`Inf` respectively.
5. Call `kernel.py` directly with `(OFF, d1..d3, FC1..FC3)` to produce
   `psd_clean` — no conversion needed, `d` is already the kernel's native
   input.
6. Apply the chi-squared noise model (config `df`) to produce `psd_noisy`.
7. Compute `EXP_k = cumsum(d1..dk)` for `k ≤ N` for the *reported* columns
   only, and set `EXP_k = NaN` for `k > N`. Emit `true_params` in this
   local-slope form — `d` itself is never a dataset column.

This schema is a starting proposal in its exact keys/shape, but the four
invariants above (Normal-only, log-space for positivity, base+increment for
ordering, explicit NaN/Inf fills with no sampling of inactive slots) are
not — those are fixed by the design decisions above, not implementation
preference.

### Prior sampling interface — the parsimony contract

Every sampled parameter (`OFF`, each `d_k`, `FC1` and its ordering
increments, each peak's `CF`/`PW`/`BW`) must go through the same two types,
with no per-parameter special-cased sampling code anywhere else in the
package:

```python
@dataclass
class ParamPrior:
    name: str                  # matches a YAML key exactly, e.g. "logD2"
    mu: float
    sd: float
    log_space: bool = False    # True -> draw is exp(Normal(mu, sd))
    min: float | None = None   # only used by bounded draws, e.g. peak `count`
    max: float | None = None

    def sample(self, rng: np.random.Generator) -> float:
        x = rng.normal(self.mu, self.sd)
        x = np.exp(x) if self.log_space else x
        if self.min is not None or self.max is not None:
            x = np.clip(x, self.min, self.max)
        return x

def load_prior_table(config_path: str) -> dict[str, ParamPrior]:
    """One ParamPrior per YAML key. Every parameter this package samples
    has exactly one entry here. Retuning a parameter's (mu, sd), or adding
    a new one, is a YAML edit -- never a code change. compositor.py only
    ever calls prior_table[name].sample(rng); it never branches on which
    parameter it's sampling."""
```

This is the thing that makes "tune parsimoniously in the future" actually
true rather than just implied: `compositor.py` is generic over parameter
name, and the only parameter-specific logic anywhere in the package is (a)
which keys are present vs. omitted in a given N's YAML (handled by the
generator checking which keys the loaded table actually has, not by
hardcoded per-name branches), and (b) the deterministic post-sampling steps
that aren't really "sampling" at all — the `EXP = cumsum(d)` bookkeeping and
the N-based `Inf`/`NaN` fills.

---

## Interface spec

```python
def generate_ground_truth(
    N: int,                 # 1, 2, or 3 — aperiodic model order
    M: int,                 # number of samples to generate
    config_path: str,       # path to the YAML above
    seed: int | None = None,
) -> GroundTruthDataset
```

```
groundtruthgen generate --N 2 --M 5000 --config priors_N2.yaml --seed 42 --out run_N2.parquet
```

**Output schema** — one row per sample:

| column | contents |
|---|---|
| `sample_id` | unique id |
| `N` | model order used — **required, explicit, not inferable from magnitudes** |
| `seed` | per-sample seed if drawn per-sample |
| `true_params` | `OFF, EXP1, EXP2, EXP3, FC1, FC2, FC3`, plus peak triplets — local-slope form, with `NaN`/`Inf` fills per the table above for `k > N` |
| `f` | frequency axis used |
| `psd_clean` | noise-free forward-model output |
| `psd_noisy` | `psd_clean` + chi-squared noise — what the real fitting pipeline actually receives |
| `noise_config` | noise parameters used for this sample (df, etc.) |

Keep `psd_clean` stored rather than re-derived later — recomputing it
requires re-running your exact kernel port, and drift between "the version
that generated this row" and "the version someone re-derives it with later"
is exactly the kind of bug this whole exercise exists to prevent elsewhere.

---

## Suggested module layout

Follow the existing Python-subpackage convention in this repo (see
`utils/Nexus/python/Pytafix/` — `pyproject.toml` at the package root,
source under a package-named subdirectory).

```
utils/Nexus/python/groundTruthGen/
├── pyproject.toml
├── README.md                    (this file)
├── groundtruthgen/
│   ├── __init__.py
│   ├── kernel.py                 # port of kernel_specparam_segmented_multiexp.m — takes d (increments), not EXP
│   ├── paramspec.py               # the fixed vector<->named-args mapping (spcpmIO_paramNames.m / spcpmIO_specs2kernel.m), extended with the EXP<->d conversion
│   ├── priors.py                  # YAML loading + Normal sampling, incl. log-space + base/increment reparameterization
│   ├── noise.py                   # chi2 noise model
│   ├── compositor.py              # priors -> EXP<->d conversion -> kernel -> noise -> GroundTruthDataset row
│   ├── schemas.py                  # GroundTruthDataset / row schema (pydantic or dataclass)
│   └── cli.py                     # the `groundtruthgen generate ...` entry point
└── tests/
    └── test_kernel_parity.py      # see "sanity checks" below
```

---

## Required sanity checks before handing data back

1. **Kernel parity**: for a handful of fixed `d`/`FC` vectors, confirm your
   Python `kernel.py` matches MATLAB's
   `kernel_specparam_segmented_multiexp.m` to floating-point precision.
   Ask for exported MATLAB test vectors if you need them. First check, not
   last — everything downstream depends on this.
2. **Local-slope round-trip (the critical one — this is the direct test of
   the `EXP ↔ d` conversion)**: generate samples at very low noise (large
   `df`), run the *real* MATLAB `specParam_multiExp.m` fitting pipeline on
   the resulting `psd_noisy`, and confirm the per-segment exponents it
   reports recover your `true_params`' `EXP1, EXP2, EXP3` closely. If this
   doesn't hold near-exactly at low noise, the conversion is implemented
   wrong and every later bias/calibration number is measuring an artifact
   of this bug, not real fitter behavior.
3. **N=1 null case**: confirm generated samples with N=1 produce
   `FC2 = FC3 = Inf` and `EXP2 = EXP3 = NaN` exactly (by construction, not
   by post-hoc filtering), and that `psd_clean` matches an independently
   computed plain single-exponent power law.
4. **Ordering holds by construction**: `FC1 < FC2 < FC3` *and*
   `EXP1 < EXP2 < EXP3` across 100% of N≥2 samples, because both are built
   from positive log-space increments (`dFC`, `d`), not verified after the
   fact. If you ever see either ordering violated, it means a `d`/`dFC`
   draw landed at exactly 0 or the cumulative-sum step has a bug — not
   something to post-hoc filter around.
5. **Noise is unbiased in expectation**: for fixed `true_params`, many
   `psd_noisy` draws should average toward `psd_clean` as draw count grows.

---

## Interface / ownership seam

**Supplied to you (from the real-data side):**
- Per-N prior config YAML files (the `(mu, sd)` presets) — these come from
  pooling real fitted parameters and will be revised repeatedly. Load them,
  never hardcode values.
- The fixed 7-slot layout, the local-slope reporting convention (`EXP_k` =
  local slope, always), and the `(Inf, NaN)` inactive-slot rule — fixed by
  the design above, not a choice.

**Owned by you:**
- `kernel.py` port, the `EXP ↔ d` conversion inside `compositor.py`, the
  chi-squared noise model, config loading, CLI, output schema, and all five
  sanity checks above — in particular #2, since it's the one that would
  otherwise fail silently.

**Not your scope (downstream, consumes your output):**
- Running the real shrinkage/BIC pipeline against `psd_noisy`.
- Computing recovery bias, calibration/coverage, model-order confusion
  matrices, R²/MAE. Your output schema needs to carry what those need
  (`psd_clean`, `true_params` with `N` explicit, `noise_config`) — you don't
  implement the checks themselves.
