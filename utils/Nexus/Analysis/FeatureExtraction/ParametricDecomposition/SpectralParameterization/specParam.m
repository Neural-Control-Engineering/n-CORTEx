function DF_specs = specParam(DF_chg, args)
    % INPUTS: df_chg --> 'channelgram' derived dataframe containing PSD
    % group
    % OUTPUTS: df_specs --> spectral parameterization time series

    % CFG HEADER
    peakWidth_min = args.peakWidth_min; % default = 2
    peakWidth_max = args.peakWidth_max; % default = 8    
    numPeaks_max = args.numPeaks_max; % default = 8
    peakHeight_min = args.peakHeight_min; % default = 0.2    
    peakThreshold = args.peakThreshold; % default = 2

    df_chg = DF_chg.df;
    f = DF_chg.ax.f;
    % specparam inputs
    peak_width_limits = py.tuple([peakWidth_min, peakWidth_max]);
    max_n_peaks = py.int(numPeaks_max);
    min_peak_height = py.int(peakHeight_min);
    peak_threshold = py.int(peakThreshold);
    aperiodic_mode = py.str(aperiodicMode);
    % data inputs
    freqs = py.numpy.array(double(f), pyargs('dtype', 'int64'));
    spectra = py.numpy.array(double(10.^(df_chg(:,:,1)/10)), pyargs('dtype', 'float64')); % de-log

    % instantiate spectralFittingModel
    specParam = py.importlib.import_module('specparam');    
    fg = specParam.SpectralGroupModel(peak_width_limits, max_n_peaks, min_peak_height, peak_threshold);
    fg.fit(freqs, spectra);

    % fit to DF


end