"""Check 4: FC1 < FC2 < FC3 and EXP1 < EXP2 < EXP3 in 100% of N >= 2 samples, by construction."""
import numpy as np
import pytest

from conftest import config_path
from groundtruthgen import generate_ground_truth


@pytest.mark.parametrize("N", [2, 3])
def test_ordering(N):
    v = np.array([r.true_params[:7] for r in generate_ground_truth(N, 2000, config_path(N), seed=4).rows])
    EXP, FC = v[:, 1:1 + N], v[:, 4:4 + N]
    assert (np.diff(FC, axis=1) > 0).all()
    assert (np.diff(EXP, axis=1) > 0).all()
