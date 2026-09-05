#!/usr/bin/env python3
"""
nexAtlas_setReference.py
Manually set or inspect per-region reference values in ephys_atlas.h5.

Usage (show):
    python nexAtlas_setReference.py <atlas_h5> --show
    python nexAtlas_setReference.py <atlas_h5> --show --region STN

Usage (set one feature):
    python nexAtlas_setReference.py <atlas_h5> --region STN --feature firing_rate --mu 6.1 --sigma 15.0
    python nexAtlas_setReference.py <atlas_h5> --region STN --feature cv_isi --mu 0.9 --sigma 0.30 --n 45

Features: ptd_ms | firing_rate | cv_isi

Notes:
  - Only the named feature is updated; other features for that region are preserved.
  - If the region has no /reference entry yet, it is created with NaN for all
    other features (they will be ignored by the Bayesian update until filled in).
  - --n sets the n_units credit recorded in the HDF5.  Defaults to the existing
    value for an already-written region, or 0 for a brand-new one.
    Use a small value (e.g. 30) for literature priors so real IBL data overrides
    them easily; use a larger value for values derived from many units.
"""

import argparse
import sys
import numpy as np
import h5py
from pathlib import Path

FEATURE_NAMES = ['ptd_ms', 'firing_rate', 'cv_isi']


def _decode_strings(raw):
    return [x.decode() if isinstance(x, bytes) else str(x) for x in raw]


def show_reference(atlas_h5, region=None):
    with h5py.File(atlas_h5, 'r') as f:
        ref = f.get('/reference')
        if ref is None:
            print('No /reference group in atlas.')
            return
        regions = sorted(ref.keys()) if region is None else [region]
        for reg in regions:
            if reg not in ref:
                print(f'{reg}: not in /reference')
                continue
            grp    = ref[reg]
            mu     = grp['mu'][:]     if 'mu'            in grp else np.full(len(FEATURE_NAMES), np.nan)
            sigma  = grp['sigma'][:]  if 'sigma'         in grp else np.full(len(FEATURE_NAMES), np.nan)
            n      = float(grp['n_units'][0]) if 'n_units'      in grp else 0.0
            fnames = _decode_strings(grp['feature_names'][:]) if 'feature_names' in grp else FEATURE_NAMES
            print(f'\n{reg}  (n={n:.0f})')
            for i, fn in enumerate(fnames):
                m = mu[i]    if i < len(mu)    else np.nan
                s = sigma[i] if i < len(sigma) else np.nan
                tag = '  <- NaN (will be ignored by Bayesian update)' if not np.isfinite(m) else ''
                print(f'  {fn:<20}  mu={m:>9.4f}  sigma={s:>8.4f}{tag}')


def set_reference(atlas_h5, region, feature, mu_val, sigma_val, n_override):
    with h5py.File(atlas_h5, 'a') as f:
        grp_path = f'/reference/{region}'

        if grp_path in f:
            grp    = f[grp_path]
            fnames = _decode_strings(grp['feature_names'][:]) if 'feature_names' in grp else list(FEATURE_NAMES)
            mu     = grp['mu'][:].tolist()    if 'mu'      in grp else [np.nan] * len(fnames)
            sigma  = grp['sigma'][:].tolist() if 'sigma'   in grp else [np.nan] * len(fnames)
            n_prev = float(grp['n_units'][0]) if 'n_units' in grp else 0.0
        else:
            fnames = list(FEATURE_NAMES)
            mu     = [np.nan] * len(fnames)
            sigma  = [np.nan] * len(fnames)
            n_prev = 0.0

        if feature not in fnames:
            print(f'Unknown feature "{feature}". Valid: {fnames}')
            sys.exit(1)

        idx = fnames.index(feature)
        mu[idx]    = float(mu_val)
        sigma[idx] = float(sigma_val)
        n_write    = float(n_override) if n_override is not None else n_prev

        if grp_path in f:
            del f[grp_path]
        grp = f.create_group(grp_path)
        grp.create_dataset('mu',            data=np.array(mu,     dtype=np.float64))
        grp.create_dataset('sigma',         data=np.array(sigma,  dtype=np.float64))
        grp.create_dataset('n_units',       data=np.array([n_write], dtype=np.float64))
        grp.create_dataset('feature_names', data=np.array(fnames, dtype=object),
                           dtype=h5py.string_dtype())

    print(f'[nexAtlas_setReference] {region}/{feature}: mu={mu_val}  sigma={sigma_val}  n={n_write:.0f}')


def parse_args():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('atlas_h5',  help='Path to ephys_atlas.h5')
    p.add_argument('--show',    action='store_true', help='Print current reference values and exit')
    p.add_argument('--region',  help='Region acronym (e.g. STN, ZI, CA1, VPM)')
    p.add_argument('--feature', choices=FEATURE_NAMES,
                   help='Feature to update: ptd_ms | firing_rate | cv_isi')
    p.add_argument('--mu',      type=float, help='Mean value in feature units')
    p.add_argument('--sigma',   type=float, help='Standard deviation in feature units')
    p.add_argument('--n',       type=int,   default=None,
                   help='n_units credit (default: keep existing, or 0 for new region). '
                        'Use ~30 for literature priors, higher for values from many units.')
    return p.parse_args()


def main():
    args = parse_args()
    atlas_h5 = Path(args.atlas_h5)
    if not atlas_h5.exists():
        print(f'Atlas file not found: {atlas_h5}')
        sys.exit(1)

    if args.show:
        show_reference(atlas_h5, region=args.region)
        return

    missing = [f'--{k}' for k, v in [('region',  args.region),
                                       ('feature', args.feature),
                                       ('mu',      args.mu),
                                       ('sigma',   args.sigma)] if v is None]
    if missing:
        print(f'Missing required arguments: {", ".join(missing)}')
        p = argparse.ArgumentParser()
        p.print_usage()
        sys.exit(1)

    set_reference(atlas_h5, args.region, args.feature, args.mu, args.sigma, args.n)


if __name__ == '__main__':
    main()
