slrt_file = 'date--2024-05-13_subj--3387-20240121_geno--Wt_npxls--R-npx10_phase--phase3_g0.mat';
slrt_path = '~/NEC_Drive/Project_Selective-Attention/Experiments/SELECT_DETECT/Data/RAW/SLRT/';
slrt_data = extractEXT_SLRT(strcat(slrt_path, slrt_file));
stim_signals = {'left_trigger', 'right_trigger'};
response_window_duration = 0.2;

npxls_path = '~/NEC_Drive/Project_Selective-Attention/Experiments/SELECT_DETECT/Data/RAW/NPXLS/date--2024-05-13_subj--3387-20240121_geno--Wt_npxls--R-npx10_phase--phase3_g1/date--2024-05-13_subj--3387-20240121_geno--Wt_npxls--R-npx10_phase--phase3_g1_imec0/date--2024-05-13_subj--3387-20240121_geno--Wt_npxls--R-npx10_phase--phase3_g1_t2_sorted/kilosort4/';
npxls_data = extractEXT_AP(slrt_data, npxls_path, stim_signals, response_window_duration);
