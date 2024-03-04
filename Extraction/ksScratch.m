% Import the Python module
mod = py.importlib.import_module('runKilosort4_tst');
% Define the parameters
data_dir = 'C:\SGL_DATA\Project_Neuromodulation-for-Pain\Archived_Raw_Neuropixel_Data\date_2024-01-24_subj_3386-20240120_pgx_DBH-Gq-DREADD_npxls_R-VPL-S2_phase_spontaneous_g0\2024-01-24_3386_L-LC-CAG-LSL-Gq-DREADD_R-VPL-S2-Npxls0_spontaneous_g0_g0_imec0\sorted';
results_dir = 'C:\SGL_DATA\Project_Neuromodulation-for-Pain\Archived_Raw_Neuropixel_Data\date_2024-01-24_subj_3386-20240120_pgx_DBH-Gq-DREADD_npxls_R-VPL-S2_phase_spontaneous_g0\2024-01-24_3386_L-LC-CAG-LSL-Gq-DREADD_R-VPL-S2-Npxls0_spontaneous_g0_g0_imec0\sorted';
chanMap = 'neuropixPhase3A_kilosortChanMap.mat';
% Call the function

results = mod.runKilosort4_tst(data_dir, results_dir, chanMap);