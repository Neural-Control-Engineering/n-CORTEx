function DF_specs = spectralParameterization(DF_chg, args)
    % INPUTS: df_chg --> 'channelgram' derived dataframe containing PSD
    % group
    % OUTPUTS: df_specs --> spectral parameterization time series

    % CFG HEADER
    peakWidth_min = args.peakWidth_min; % default = 2
    peakWidth_max = args.peakWidth_max; % default = 8    
    numPeaks_max = args.numPeaks_max; % default = 8
    peakHeight_min = args.peakHeight_min; % default = 0.2    
    peakThreshold = args.peakThreshold; % default = 2
    chanRange_start  = args.chanRange_start; % default = 1
    chanRange_end = args.chanRange_end; % default = 384
    fRange_start = args.fRange_start; % default = 1
    fRange_end = args.fRange_end; % default = 50

    % version = "fooof";
    version="specparam";
    df_chg = DF_chg.df;
    f = DF_chg.ax.f;
    fCond = (f>=fRange_start)&(f<=fRange_end);
    f = f(fCond);
    df_chg = df_chg(:,fCond,:);
    t = DF_chg.ax.t;
    tRange_start=1;
    tRange_end=2;
    tCond = (t>=tRange_start)&(t<=tRange_end);
    df_chg=df_chg(:,:,tCond);
    % specparam inputs
    % peak_width_limits = py.tuple([peakWidth_min, peakWidth_max]);
    % max_n_peaks = py.int(numPeaks_max);
    % min_peak_height = py.int(peakHeight_min);
    % peak_threshold = py.int(peakThreshold);
    % % aperiodic_mode = py.str(aperiodicMode);
    % % data inputs
    % freqs = py.numpy.array(double(f), pyargs('dtype', 'int64'));
    % spectra = py.numpy.array(double(10.^(squeeze(df_chg(16,:,:))'/10)), pyargs('dtype', 'float64')); % de-log

    % load to cuda
    chanRange = [chanRange_start : chanRange_end];
    dfBuffer = ((df_chg(chanRange,:,:)));
    % gpuBuffer = downsample(gpuBuffer,1);        
    dfBuffer = permute(dfBuffer,[1,3,2]);    

    S = {};  
    R = {};
    % for each channel
    parfor i = 1:size(dfBuffer,1)
        freqs = py.numpy.array(double(f), pyargs('dtype', 'int64'));
        spectra = squeeze(dfBuffer(i,:,:));
        %% SPECPARAM BREAKOUT
        peak_width_limits = py.tuple([args.peakWidth_min, args.peakWidth_max]);
        max_n_peaks = py.int(args.numPeaks_max);
        min_peak_height = py.int(args.peakHeight_min);
        peak_threshold = py.int(args.peakThreshold);
        % dataframing
        freqs = py.numpy.array(double(f), pyargs('dtype', 'int64'));
        spectra_deLog = double(10.^(squeeze(spectra)/10));
        spectra = py.numpy.array(spectra_deLog,pyargs('dtype','float64'));
        % module import
        switch version
            case "fooof"
                specparam = py.importlib.import_module('fooof')
                % Initialize a FOOOFGroup object, specifying some parameters
                fg = specparam.FOOOFGroup(peak_width_limits=peak_width_limits, max_n_peaks=max_n_peaks,min_peak_height=min_peak_height,peak_threshold=peak_threshold);                        
            case "specparam"
                specParam = py.importlib.import_module('specparam');               
                % Initialize a FOOOFGroup object, specifying some parameters
                % fg = specParam.SpectralGroupModel(peak_width_limits, max_n_peaks, min_peak_height, peak_threshold, aperiodic_mode='knee');                      
                % specParam.SpectralModel()
                % modes = specParam.modes.modes.Modes();
                % specParam.modes.modes.Modes.get_modes()
                % use 'skewed_gaussian'
                % mode_PE = 'skewed_gaussian';
                mode_PE = 'gaussian';
                % use 'doublexp'
                mode_AP = 'doublexp';
                fg = specParam.SpectralGroupModel(peak_width_limits, max_n_peaks, min_peak_height, peak_threshold,aperiodic_mode=mode_AP,periodic_mode=mode_PE);                      
        end
        % Fit specparam model across the matrix of power spectra
        fg.fit(freqs, spectra)
        specs = fg.results.group_results;
        % specs = fg.results;
        % MATLAB Formatting
        specs = cell((specs))';
        [specs, scores] = cellfun(@(x) formatSpecParamOutputs(x, args), specs, "UniformOutput", false);                
        %% SPECPARAM BREAKOUT
        specs = cell2mat(specs);
        scores = cell2mat(scores);
        % figure; plot()
        S{i} = specs;
        R{i} = scores;
    end     
    
    % OUTPUT
    DF_specs.df = permute(cat(3,S{:}),[3,2,1]);
    DF_specs.ax.f = f;
    DF_specs.ax.t = DF_chg.ax.t;
    DF_specs.ax.chans = chanRange;
    DF_specs.scores = permute(cat(3,R{:}),[3,2,1]);
    DF_tgt=DF_specs;
    DF_src=DF_chg;
end