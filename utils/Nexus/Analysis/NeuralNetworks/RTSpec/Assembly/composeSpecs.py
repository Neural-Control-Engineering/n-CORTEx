# import numpy as np
# import h5py
# import os
# import torch

# def composeSpecs(params, specs):
#     with h5py.File(os.path.join(params['dataDir'], 'f.mat'), 'r') as file:
#         f = file['freq'][:]
#     f = torch.tensor(f, dtype=torch.float32).cuda()
#     bias = specs[:, 0]
#     exponent = specs[:, 1]
#     sig = torch.log10(1/(f**exponent))
    
#     for i in range(2, len(specs[0]), 3):
#         if i < len(specs[0]) - 3:
#             mu = specs[:, i]  # CF
#             sigma = specs[:, i + 2]  # BW
#             A = specs[:, i + 1]  # PW
#             G = A * torch.exp(-(f.unsqueeze(1) - mu.unsqueeze(1))**2 / (2 * sigma.unsqueeze(1)**2))
#             sig = sig + G.sum(dim=1)
    
#     sig = sig + bias.unsqueeze(1)
#     return sig

import numpy as np
import h5py
import os
import torch

def composeSpecs(params, specs_batch):
    # Load frequency vector (shared across the batch)
    with h5py.File(os.path.join(params['dataDir'], 'f.mat'), 'r') as file:
        f = file['freq'][:]
    f = torch.tensor(f, dtype=torch.float32).cuda()
    # print('F: ',f.shape)
    # print('Specs: ',specs_batch.shape)

    # specs_batch: shape [batch_size, param_dim] 
    # (assuming param_dim = 2 for aperiodic params + 3*num_peaks for Gaussian params)
    batch_size = specs_batch.shape[0]

    # Expand f to handle batch dimension: shape [batch_size, num_freqs]
    f = f.squeeze(1).unsqueeze(0).expand(batch_size, -1).unsqueeze(2) # this gives [300, 195]
    # print('F: ',f.shape)

    # Aperiodic component: bias and exponent
    bias = specs_batch[:, 0, 0].unsqueeze(1).unsqueeze(1)
    exponent = specs_batch[:, 0, 1].unsqueeze(1).unsqueeze(1)
    # print('Bias: ',bias.shape)
    # print('Exponent: ',exponent.shape)
    
    # Compute aperiodic signal component for all batch samples: [batch_size, num_freqs]
    sig = torch.log10(1 / (f ** exponent))  

    # Iterate over Gaussian peaks (each peak has 3 params: mu, sigma, A)
    num_peaks = (specs_batch.shape[1] - 2) // 3
    for i in range(num_peaks):
        mu = specs_batch[:, 2 + i*3].unsqueeze(1)  # CF: [batch_size, 1]
        sigma = specs_batch[:, 2 + i*3 + 2].unsqueeze(1)  # BW: [batch_size, 1]
        A = specs_batch[:, 2 + i*3 + 1].unsqueeze(1)  # PW: [batch_size, 1]

        # mu = specs_batch[:, 2 + i*3]  # CF: [batch_size, 1]
        # sigma = specs_batch[:, 2 + i*3 + 2]  # BW: [batch_size, 1]
        # A = specs_batch[:, 2 + i*3 + 1]  # PW: [batch_size, 1]

        # Compute Gaussian for all batch samples at once: [batch_size, num_freqs]
        G = A * torch.exp(-(f - mu)**2 / (2 * sigma**2))

        # Add Gaussian to the signal
        sig = sig + G

    # Add bias term to the final signal
    sig = sig + bias

    return sig  # Shape: [batch_size, num_freqs]
