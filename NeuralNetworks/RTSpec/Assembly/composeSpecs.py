import numpy as np
import h5py
import os

def composeSpecs(params, specs):
    with h5py.File(os.path.join(params['dataDir'], 'f.mat'), 'r') as file:
        f = file['freq'][:]
    bias = specs[0]
    exponent = specs[1]
    sig = np.log10(1/(f**exponent))    
    for i in range(2, len(specs), 3):
        if i < len(specs) - 3:
            mu = specs[i]  # CF
            sigma = specs[i + 2]  # BW
            A = specs[i + 1]  # PW
            G = A * np.exp(-(f - mu)**2 / (2 * sigma**2))
            # add each peak
            sig = sig + G
    sig = sig + bias       
    return sig