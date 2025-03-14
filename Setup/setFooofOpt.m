function opt = setFooofOpt()
    opt.freq_range = [0.2859, 50,0286];
    opt.peak_width_limits = [0.5000,12];
    opt.max_peaks = 5;
    opt.min_peak_height = 0.3500;
    opt.aperiodic_mode = 'fixed';
    opt.peak_threshold = 2;
    opt.return_spectrum = 1;
    opt.border_threshold = 1;
    opt.power_line = '50';
    opt.peak_type = 'gaussian';
    opt.proximity_threshold = 2;
    opt.guess_weight = 'none';
    opt.thresh_after = 1;
    opt.sort_type = 'param';
    opt.sort_param = 'frequency';
    opt.sort_bands = {'delta','2, 4'; 'theta','5, 7';'alpha','8, 12'; 'beta', '15, 29'; 'gamma1', '30, 59'; 'gamma2', '60, 90'};
end