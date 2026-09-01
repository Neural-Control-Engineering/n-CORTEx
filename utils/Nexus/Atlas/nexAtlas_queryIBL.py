#!/usr/bin/env python3
"""
nexAtlas_queryIBL.py
Query IBL brain-wide map for per-region [µ, σ] feature distributions.
Writes /reference/<region>/{feature_names, mu, sigma, n_units} into ephys_atlas.h5.

Usage:
    python nexAtlas_queryIBL.py <ephys_atlas_h5>
    python nexAtlas_queryIBL.py <ephys_atlas_h5> --regions STN ZI VPM VPL
    python nexAtlas_queryIBL.py <ephys_atlas_h5> --max_sessions 100

First run prompts for IBL Alyx credentials; subsequent runs use the local ONE cache.
Requires: ONE-api, ibllib, iblatlas, h5py, numpy, pandas
          conda env nexus:  ~/miniconda3/envs/nexus/bin/python nexAtlas_queryIBL.py ...

Features written (units match nexOp_unitFeatures output):
    ptd_ms          peak-to-trough duration (ms)    from clusters.peakToTrough
    firing_rate     mean firing rate (Hz)            from clusters.firing_rate
    cv_isi          ISI coefficient of variation     from spikes (skipped if unavailable)
"""

import argparse
import sys
import warnings
import numpy as np
import h5py
from pathlib import Path

FEATURE_NAMES = ['ptd_ms', 'firing_rate', 'cv_isi']

# Default target regions (Allen CCF acronyms matching our probe trajectory)
DEFAULT_REGIONS = ['STN', 'ZI', 'VPM', 'VPL', 'CA1', 'SSp']

# Cap on sessions to load per region - trade-off between accuracy and runtime
DEFAULT_MAX_SESSIONS = 80


# ── Literature fallback ────────────────────────────────────────────────────────
# Used when IBL data is unavailable.  Values from IBL BWM paper + published ephys.
# [ptd_ms µ, ptd_ms σ,  fr_hz µ, fr_hz σ,  cv_isi µ, cv_isi σ]
LITERATURE_PRIORS = {
    'STN': [0.38, 0.12,  25.0,  15.0,  0.85, 0.35],
    'ZI':  [0.42, 0.15,  12.0,   8.0,  0.95, 0.40],
    'VPM': [0.45, 0.14,  12.0,  10.0,  1.20, 0.55],
    'VPL': [0.44, 0.14,  10.0,   8.0,  1.15, 0.50],
    'CA1': [0.52, 0.20,   4.0,   5.0,  1.10, 0.50],
    'SSp': [0.50, 0.18,   8.0,   7.0,  0.90, 0.40],
}

# n_units credited to literature priors (low weight = easily overwritten by real data)
LITERATURE_N = 30


def parse_args():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('atlas_h5', help='Path to ephys_atlas.h5')
    p.add_argument('--regions', nargs='+', default=None,
                   help='Allen CCF region acronyms (default: read unique regions from '
                        '/prior/channel_regions in atlas_h5)')
    p.add_argument('--max_sessions', type=int, default=DEFAULT_MAX_SESSIONS,
                   help='Maximum sessions to load per region (default %(default)s)')
    p.add_argument('--fallback_only', action='store_true',
                   help='Skip IBL query; write literature priors only')
    p.add_argument('--base_url', default='https://openalyx.internationalbrainlab.org',
                   help='Alyx server URL')
    return p.parse_args()


def read_prior_regions(atlas_h5):
    """Read unique region acronyms from the atlas prior.
    Tries /prior/region_acronyms first (already deduplicated), then falls back
    to /prior/channel_regions.  Handles the case where MATLAB h5write encoded
    an entire string array as one bytes-repr blob (b'STN' b'ZI' ...).
    """
    import re
    skip = {'', 'root', 'void', 'Not classified', 'unassigned'}

    def _decode_dataset(raw):
        regions = []
        for r in raw.flat:
            text = r.decode() if isinstance(r, bytes) else str(r)
            # MATLAB may encode the whole array as one repr string: "[b'STN' b'ZI' ...]"
            if "b'" in text:
                regions.extend(re.findall(r"b'([^']+)'", text))
            else:
                t = text.strip()
                if t:
                    regions.append(t)
        return [r for r in dict.fromkeys(regions) if r not in skip]

    with h5py.File(atlas_h5, 'r') as f:
        for key in ('/prior/region_acronyms', '/prior/channel_regions'):
            if key not in f:
                continue
            unique = _decode_dataset(f[key][:])
            if unique:
                return unique
    return None


# ── ONE / iblatlas setup ───────────────────────────────────────────────────────

def get_region_ids(br, acronym):
    """Return all Allen CCF IDs (including descendants) for a region acronym."""
    parent_ids = br.acronym2id(acronym, mapping='Allen', hemisphere=None)
    if hasattr(parent_ids, '__len__'):
        parent_ids = np.array(parent_ids).flatten()
    else:
        parent_ids = np.array([parent_ids])
    parent_ids = parent_ids[parent_ids > 0]   # drop NaN / mirror hemisphere

    all_ids = set()
    for pid in parent_ids:
        bunch = br.descendants(ids=int(pid))
        all_ids.update(bunch.id[bunch.id > 0].tolist())
    result = np.array(sorted(all_ids), dtype=int)

    if len(result) == 0:
        print(f'  {acronym}: NOT FOUND in Allen CCF atlas - will use literature prior')
    else:
        print(f'  {acronym}: resolved to {len(result)} Allen CCF ID(s)')
    return result


def load_one(base_url):
    from one.api import ONE
    print(f'[nexAtlas_queryIBL] Connecting to ONE ({base_url})...')
    # IBL public read-only credentials - no account needed.
    # silent=True suppresses interactive prompts (required when called from MATLAB system()).
    try:
        one = ONE(base_url=base_url, password='international', silent=True)
    except Exception as e:
        print(f'  ONE connection failed: {e}')
        return None
    return one


# ── Probe-level data loader ───────────────────────────────────────────────────

def probe_collection(insertion):
    """
    Derive the alf collection path from an Alyx insertion record.
    IBL convention: probe label 'probe00' ->collection 'alf/probe00'.
    Falls back to 'alf' when the label is absent (single-probe legacy sessions).
    """
    label = insertion.get('name', '') or insertion.get('probe_label', '')
    if label:
        return f'alf/{label}'
    return 'alf'


def _find_ccf_collection(one, eid, base_collection):
    """
    Try base_collection then known subcollection variants (IBL changed layout over time).
    Returns (collection_path, region_ids_array) or (None, None) if not found.
    Variants tried: base, base/pykilosort, base/ks2, base/ks2_5.
    """
    candidates = [base_collection,
                  base_collection + '/pykilosort',
                  base_collection + '/ks2',
                  base_collection + '/ks2_5']
    for coll in candidates:
        try:
            data = one.load_dataset(eid, 'clusters.brainLocationIds_ccf_2017',
                                    collection=coll)
            if data is not None and len(data) > 0:
                return coll, np.array(data).flatten().astype(int)
        except Exception:
            pass
    return None, None


def load_probe_clusters(one, eid, collection, target_ids):
    """
    Load cluster features for one probe (one collection path), filtered to target_ids.
    Returns dict: feature ->np.array (may be empty), plus '_status' string for logging.
    Tries base collection and known IBL subcollection variants (pykilosort, ks2, ...).
    """
    out = {k: np.array([]) for k in FEATURE_NAMES}
    out['_status'] = ''
    try:
        collection, region_ids = _find_ccf_collection(one, eid, collection)
        if collection is None or region_ids is None:
            out['_status'] = 'no CCF registration'
            return out

        # IBL stores left-hemisphere units with negative Allen CCF IDs - use abs()
        mask = np.isin(np.abs(region_ids), target_ids)
        if not mask.any():
            out['_status'] = f'0/{len(region_ids)} units in region'
            return out

        hits = []

        try:
            ptd_s = one.load_dataset(eid, 'clusters.peakToTrough', collection=collection)
            if ptd_s is not None:
                out['ptd_ms'] = np.abs(np.array(ptd_s)[mask]) * 1000.0
                hits.append('ptd+')
            else:
                hits.append('ptd-')
        except Exception:
            hits.append('ptd-')

        try:
            fr = one.load_dataset(eid, 'clusters.firing_rate', collection=collection)
            if fr is not None:
                out['firing_rate'] = np.array(fr)[mask]
                hits.append('fr+')
            else:
                hits.append('fr-')
        except Exception:
            hits.append('fr-')

        # CV-ISI: computed from spike trains (not a pre-stored IBL dataset)
        try:
            spike_t = one.load_dataset(eid, 'spikes.times',    collection=collection)
            spike_c = one.load_dataset(eid, 'spikes.clusters', collection=collection)
            if spike_t is not None and spike_c is not None:
                spike_t = np.array(spike_t)
                spike_c = np.array(spike_c)
                cv_vals = []
                for uid in np.where(mask)[0]:
                    t = spike_t[spike_c == uid]
                    if len(t) >= 3:
                        isis = np.diff(np.sort(t))
                        cv_vals.append(np.std(isis) / (np.mean(isis) + 1e-12))
                    else:
                        cv_vals.append(np.nan)
                out['cv_isi'] = np.array(cv_vals)
                hits.append('cv+')
            else:
                hits.append('cv-')
        except Exception:
            hits.append('cv-')

        out['_status'] = f'{int(mask.sum())} units  ' + '  '.join(hits)

    except Exception as e:
        out['_status'] = f'ERROR: {e}'

    return out


# ── Main query ────────────────────────────────────────────────────────────────

def get_insertions_for_region(one, acronym):
    """
    Query Alyx insertion records that traverse the named region.
    Returns list of (eid, collection) pairs - already scoped to the target region,
    so no per-session region-label loading is needed.
    Falls back to a broad session search when the Alyx REST endpoint is unavailable.
    """
    try:
        # Alyx tags each probe insertion with the brain regions it traverses.
        # This pre-filters to only probes that went through `acronym` - no scanning needed.
        insertions = one.alyx.rest('insertions', 'list', atlas_acronym=acronym)
        pairs = [(ins['session'], probe_collection(ins)) for ins in insertions]
        print(f'  {acronym}: {len(pairs)} registered probe insertions in IBL')
        return pairs
    except Exception as e:
        print(f'  {acronym}: Alyx insertion query unavailable ({e})')
        print(f'    falling back to broad session scan - will be slow for common regions')
        try:
            sessions = one.search(datasets='clusters.peakToTrough', query_type='remote')
            # Expand single-probe and likely dual-probe sessions
            pairs = []
            for eid in sessions:
                for label in ('probe00', 'probe01'):
                    pairs.append((eid, f'alf/{label}'))
            return pairs
        except Exception as e2:
            print(f'  search also failed: {e2}')
            return []


def query_region(one, br, acronym, max_sessions):
    """
    Load cluster features across IBL probe insertions for one Allen CCF region.
    Returns dict: feature ->np.array of pooled values across all matched probes.
    """
    target_ids = get_region_ids(br, acronym)
    if len(target_ids) == 0:
        print(f'  {acronym}: no Allen IDs found - skipping')
        return None

    probe_pairs = get_insertions_for_region(one, acronym)
    if not probe_pairs:
        return None

    accum = {k: [] for k in FEATURE_NAMES}
    n_used = 0
    n_skip = 0
    cap = min(max_sessions, len(probe_pairs))

    for eid, collection in probe_pairs:
        if n_used >= max_sessions:
            break
        d = load_probe_clusters(one, eid, collection, target_ids)
        status = d.pop('_status', '')
        if any(len(d[k]) > 0 for k in FEATURE_NAMES):
            n_used += 1
            print(f'    [{acronym}]  {n_used}/{cap}  {status}  ({collection})', flush=True)
            for k in FEATURE_NAMES:
                if len(d[k]) > 0:
                    accum[k].append(d[k])
        else:
            n_skip += 1

    pooled = {k: np.concatenate(v) if v else np.array([]) for k, v in accum.items()}

    # Per-region summary
    print(f'  {acronym} summary: {n_used} probes used, {n_skip} skipped')
    for feat in FEATURE_NAMES:
        v = pooled[feat]
        finite = v[np.isfinite(v)] if len(v) > 0 else np.array([])
        if len(finite) >= 3:
            print(f'    {feat:<18}  n={len(finite):>4}  mu={np.mean(finite):.3f}  sd={np.std(finite):.3f}')
        else:
            print(f'    {feat:<18}  n={len(finite):>4}  ->will use literature prior')

    return pooled


def compute_stats(values):
    """[µ, σ] ignoring NaN; returns (nan, nan) when fewer than 3 samples."""
    v = values[np.isfinite(values)]
    if len(v) < 3:
        return np.nan, np.nan
    return float(np.mean(v)), float(np.std(v))


# ── HDF5 writer ───────────────────────────────────────────────────────────────

def write_reference(atlas_h5, region, mu, sigma, n_units, feature_names):
    """Write [µ, σ, n_units, feature_names] to /reference/<region>/ in atlas HDF5."""
    with h5py.File(atlas_h5, 'a') as f:
        grp_path = f'/reference/{region}'
        if grp_path in f:
            del f[grp_path]
        grp = f.create_group(grp_path)

        grp.create_dataset('mu',    data=np.array(mu,    dtype=np.float64))
        grp.create_dataset('sigma', data=np.array(sigma, dtype=np.float64))
        grp.create_dataset('n_units', data=np.array([n_units], dtype=np.float64))

        # Feature names as variable-length strings
        dt = h5py.string_dtype()
        grp.create_dataset('feature_names', data=np.array(feature_names, dtype=object),
                           dtype=dt)

    print(f'  [{region}]  mu={np.round(mu,3)}  sigma={np.round(sigma,3)}'
          f'  n={n_units}')


def write_fallback(atlas_h5, region):
    """Write literature-derived priors when IBL query fails or region not in IBL."""
    if region not in LITERATURE_PRIORS:
        print(f'  [{region}]  no literature prior available - skipping')
        return
    vals = LITERATURE_PRIORS[region]  # [ptd_µ, ptd_σ, fr_µ, fr_σ, cv_µ, cv_σ]
    mu    = [vals[0], vals[2], vals[4]]
    sigma = [vals[1], vals[3], vals[5]]
    write_reference(atlas_h5, region, mu, sigma, LITERATURE_N, FEATURE_NAMES)
    print(f'    (literature prior - update by re-running without --fallback_only)')


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    args = parse_args()
    atlas_h5 = Path(args.atlas_h5)

    if not atlas_h5.exists():
        print(f'[nexAtlas_queryIBL] atlas file not found: {atlas_h5}')
        print('  Create it first by running nexAtlas_initFromPrior in MATLAB.')
        sys.exit(1)

    # Resolve region list: CLI override ->prior in atlas ->hardcoded fallback
    regions = args.regions
    if regions is None:
        regions = read_prior_regions(atlas_h5)
        if regions:
            print(f'[nexAtlas_queryIBL] regions from prior: {regions}')
        else:
            regions = DEFAULT_REGIONS
            print(f'[nexAtlas_queryIBL] /prior/channel_regions not found; using defaults')

    print(f'[nexAtlas_queryIBL] target: {atlas_h5}')
    print(f'  regions:      {regions}')
    print(f'  max_sessions: {args.max_sessions}')

    if args.fallback_only:
        print('[nexAtlas_queryIBL] --fallback_only: writing literature priors')
        for region in regions:
            write_fallback(atlas_h5, region)
        print('[nexAtlas_queryIBL] done.')
        return

    # Try IBL query
    try:
        from iblatlas.atlas import BrainRegions
        br = BrainRegions()
    except ImportError:
        print('[nexAtlas_queryIBL] iblatlas not found. Run: pip install iblatlas')
        sys.exit(1)

    one = load_one(args.base_url)
    if one is None:
        print('[nexAtlas_queryIBL] Falling back to literature priors.')
        for region in regions:
            write_fallback(atlas_h5, region)
        return

    for region in regions:
        print(f'\n[nexAtlas_queryIBL] querying region: {region}')
        data = query_region(one, br, region, args.max_sessions)

        if data is None:
            write_fallback(atlas_h5, region)
            continue

        mu, sigma, n = [], [], None
        for feat in FEATURE_NAMES:
            m, s = compute_stats(data[feat])
            mu.append(m)
            sigma.append(s)
            if n is None:
                n = int(np.sum(np.isfinite(data[feat])))

        # Fall back per-feature to literature if IBL returned too few units
        if n is None or n < 10:
            print(f'  {region}: too few units ({n}) from IBL - using literature prior')
            write_fallback(atlas_h5, region)
            continue

        # Blend NaN features (e.g. cv_isi) with literature prior, note which
        sources = ['IBL'] * len(FEATURE_NAMES)
        if region in LITERATURE_PRIORS:
            lp = LITERATURE_PRIORS[region]
            lit_mu    = [lp[0], lp[2], lp[4]]
            lit_sigma = [lp[1], lp[3], lp[5]]
            for i in range(len(FEATURE_NAMES)):
                if not np.isfinite(mu[i]):
                    mu[i], sigma[i] = lit_mu[i], lit_sigma[i]
                    sources[i] = 'literature'

        src_str = '  '.join(f'{f}={s}' for f, s in zip(FEATURE_NAMES, sources))
        print(f'  {region}: writing - sources: {src_str}')
        write_reference(atlas_h5, region, mu, sigma, n, FEATURE_NAMES)

    print('\n[nexAtlas_queryIBL] done.')


if __name__ == '__main__':
    main()
