"""python -m groundtruthgen generate --N 2 --M 5000 --config groundtruthgen/configs/priors_N2.yaml --seed 42 --out run_N2.parquet"""
import argparse

from groundtruthgen.compositor import generate_ground_truth


def main(argv=None):
    p = argparse.ArgumentParser(prog="groundtruthgen")
    sub = p.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("generate", help="write a ground-truth dataset to parquet")
    g.add_argument("--N", type=int, required=True, choices=(1, 2, 3))
    g.add_argument("--M", type=int, required=True)
    g.add_argument("--config", required=True)
    g.add_argument("--seed", type=int, default=None)
    g.add_argument("--out", required=True, help="parquet path")
    g.add_argument("--h5", default=None, help="also write a nexDTS-style .h5 here")
    a = p.parse_args(argv)
    ds = generate_ground_truth(a.N, a.M, a.config, a.seed)
    ds.to_parquet(a.out)
    if a.h5: ds.to_nexdts_h5(a.h5)
    print(f"wrote {a.M} samples (N={a.N}) to {a.out}" + (f" and {a.h5}" if a.h5 else ""))


if __name__ == "__main__":
    main()
