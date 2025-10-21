function [specs, scores] = specParam(f, spectra, args, version)
    % specparam inputs    
    peak_width_limits = py.tuple([args.peakWidth_min, args.peakWidth_max]);
    max_n_peaks = py.int(args.numPeaks_max);
    min_peak_height = py.int(args.peakHeight_min);
    peak_threshold = py.int(args.peakThreshold);
    % dataframing
    freqs = py.numpy.array(double(f), pyargs('dtype', 'int64'));
    spectra_deLog = double(10.^(squeeze(spectra)/10));
    spectra_deLog = [spectra_deLog; spectra_deLog];
    spectra = py.numpy.array(spectra_deLog,pyargs('dtype','float64'));
    % module import
    switch version
        case "fooof"
            specparam = py.importlib.import_module('fooof');
            % Initialize a FOOOFGroup object, specifying some parameters
            fg = specparam.FOOOFGroup(peak_width_limits=peak_width_limits, max_n_peaks=max_n_peaks,min_peak_height=min_peak_height,peak_threshold=peak_threshold);                        
        case "specparam"
            specParam = py.importlib.import_module('specparam');               
            % Initialize a FOOOFGroup object, specifying some parameters
             % mode_PE = 'skewed_gaussian';
            mode_PE = 'gaussian';
            % use 'doublexp'
            mode_AP = 'fixed';
            % mode_AP = 'doublexp';
            fg = specParam.SpectralGroupModel(peak_width_limits, max_n_peaks, min_peak_height, peak_threshold,aperiodic_mode=mode_AP, periodic_mode=mode_PE);                      
    end
    % Fit specparam model across the matrix of power spectra
    fg.fit(freqs, spectra)
    specs = fg.results.group_results;
    % MATLAB Formatting
    specs = cell((specs))';
    [specs, scores] = cellfun(@(x) formatSpecParamOutputs(x, args), specs, "UniformOutput", false);
end