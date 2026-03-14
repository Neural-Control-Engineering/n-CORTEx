import numpy as np
import jax.numpy as np
import jax.random as jr
from dynamax.linear_gaussian_ssm import LinearGaussianSSM
from dynamax.linear_gaussian_ssm.inference import lgssm_smoother
from dynamax.utils.utils import monotonically_increasing, random_rotation

class LGSSM:

    """
    Dynamax LGSSM wrapper - Marc Sorrentino"
    """

    # ---------- core ----------
    def __init__(self, model, params):
        self.model = model
        self.params = params

    # ---------- constructors ----------
    @classmethod
    def fit(cls, emissions, state_dim=3, num_iters=50):

        emissions = np.asarray(emissions)
        emissionDim = emissions.shape[-1]
        print(f"fitting emissions")

        model = LinearGaussianSSM(
            state_dim=state_dim,
            emission_dim=emissionDim
        )

        init_key = jr.PRNGKey(42)
        params, param_props = model.initialize(init_key)

        print("fitting ssm...")

        params, marginal_lls  = model.fit_em(
            params,
            param_props,
            emissions,
            num_iters=num_iters
        )

        # assert monotonically_increasing(marginal_lls, atol=1e-2, rtol=1e-2)

        print("results: ", params)

        return cls(model, params)


    @classmethod
    def from_params(cls, params): 
        return

    @classmethod
    def load(cls, path): 
        return

    @classmethod
    def random(cls, state_dim, emission_dim):
        return

    # ---------- inference ----------
    def smooth(self, emissions):
        return

    def filter(self, emissions):
        print("filtering ssm...")
        Z = self.model.filter(self.params, emissions)
        return Z

    def predict(self, steps):
        return

    # ---------- utilities ----------
    def save(self, path):
        return

    def get_params(self):
        return
