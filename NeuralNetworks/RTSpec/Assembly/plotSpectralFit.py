import numpy as np
from scipy.io import loadmat
import os
from matplotlib import pyplot as plt
import h5py

def plotSpectralFit(params, specs, psds, ID):
    f = None
    # with h5py.File(os.path.join(params['dataDir'], 'f.mat'), 'r') as file:
    #     # List all groups and datasets in the file
    #     print("Keys: %s" % file.keys())

    #     # If you see nested keys, you may need to explore further
    #     for key in file.keys():            
    #         print(f"{key}: {list(file[key])}")

    with h5py.File(os.path.join(params['dataDir'], 'f.mat'), 'r') as file:
        f = file['freq'][:]
    # extract peak params and aperiodic params & compose into PSD    
    # num_plots = specs.shape[0] // 10
    # num_plots = specs.shape[0]
    num_plots = 5
    # print('num_plots: ', num_plots)
    fig, axs = plt.subplots(1, num_plots, figsize=(20, 6))
    fig.patch.set_facecolor('#98b69e')
    for ax in axs:
        ax.set_facecolor('#98b69e')
        ax.tick_params(colors='white')
        ax.spines['bottom'].set_color('white')
        ax.spines['top'].set_color('white')
        ax.spines['right'].set_color('white')
        ax.spines['left'].set_color('white')
        ax.xaxis.label.set_color('white')
        ax.yaxis.label.set_color('white')
        ax.title.set_color('white')
    m=0
    step = round(specs.shape[0],-1) // num_plots
    if step == 0:
        step = 1
        eof = specs.shape[0]
    else:
        eof = specs.shape[0] - 1
    print('Step: ', step)
    print("specs: ", specs.shape)
    print("psds: ", psds.shape)
    
    for j in range(0, eof, step):
        spec = specs[j, 0, :]  
        psd = psds[j, :]
        bias = spec[0]
        exponent = spec[1]
        fract_fit = np.log10(1/(f**exponent))
        sig = fract_fit
        for i in range(2, len(spec), 3):
            if i < len(spec) - 3:
                mu = spec[i]  # CF
                sigma = spec[i + 2]  # BW
                A = spec[i + 1]  # PW
                G = A * np.exp(-(f - mu)**2 / (2 * sigma**2))
                # add each peak
                sig = sig + G
        sig = sig + bias   
        
        # Plot spectral fit over sample PSD
        ax = axs[m]
        ax.plot(f, (psd), 'w', label='Sample PSD', color='white')
        ax.plot(f, sig, 'g', label='Spectral fit', color='lime')
        ax.legend()
        ax.set_xlabel('Frequency (Hz)', color='white')
        ax.set_ylabel('Power (dB)', color='white')
        ax.set_title('Spectral fit: ' + ID, color='white')
        # ax.set_facecolor('black')
        ax.set_facecolor('black')
        m+=1
    
    plt.tight_layout()
    plt.show()
    # Report similarity metrics
    # Compute similarity metrics
    # RMSE
    rmse = np.sqrt(np.mean(((psd) - sig)**2))
    # R^2
    ss_res = np.sum(((psd) - sig)**2)
    ss_tot = np.sum(((psd) - np.mean((psd)))**2)
    r2 = 1 - (ss_res / ss_tot)
    # Print metrics
    print('RMSE: ', rmse)
    print('R^2: ', r2)
    # add metrics to plot 
    # plt.text('RMSE: ' + str(rmse), fontsize=12, ha='center')
    # plt.text('R^2: ' + str(r2), fontsize=12, ha='center')
    plt.show()
    return sig