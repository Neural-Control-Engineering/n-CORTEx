function psdIO_fitLorentzian(f_psd, df_psd)
    % locate corner frequencies
    df_cf = psdIO_readCornerFrequencies(f_psd, df_psd);
    df_cf = [df_cf, f_psd(end)];
    specParam = py.importlib.import_module('specparam');               
    mode_PE='gaussian';
    mode_AP='fixed';
    fg = specParam.SpectralModel(pyargs( ...
      'peak_width_limits', peak_width_limits, ...
      'max_n_peaks',       max_n_peaks, ...
      'min_peak_height',   min_peak_height, ...
      'peak_threshold',    peak_threshold, ...
      'aperiodic_mode',    mode_AP, ...
      'periodic_mode',     mode_PE));
    
    SPEC = [];
    SEG = {};
    % split/fit (specParam)
    for i = 1:length(df_cf)
        % if i==length(df_cf)
        %     f_end = f_psd(end);
        % else
        %     f_end = df_cf(i);        
        % end
        f_end = df_cf(i);        
        if i==1
            f_start = 0;                        
        else
            f_start = df_cf(i-1);            
        end
        fCond = (f>=f_start)&(f<=f_end);
        f_i = py.numpy.array(f_psd(fCond));
        psd_i = df_psd(fCond);
        psd_i_deLog = py.numpy.array(10.^((psd_i)/10));
        fg.fit(f_i,psd_i_deLog);
        % specs = fg.results.params;
        specs.aperiodic_params=fg.results.params.aperiodic;
        specs.periodic_params=fg.results.params.periodic;
        specs.metrics=fg.results.metrics;
        [specs_out, scores] = formatSpecParamOutputs(specs, args);
        SPEC = [SPEC; specs_out];
        SEG = [SEG; f(fCond)];
    end
    % convert to kernel args
    kernel_args.OFF=SPEC(1,1);
    % kernel_args.EXP1=SPEC(1,2);
    % kernel_args.EXP2=SPEC(2,2);
    % kernel_args.EXP3=SPEC(3,2);
    kernel_args.EXP1=1;
    kernel_args.EXP2=7;
    kernel_args.EXP3=49;
    % consolidate into lorentzian form
    ax.f = f_psd;
    psd_fit = kernel_specparam_segmented_multiexp(ax, kernel_args);
    figure; loglog(f_psd,10*log10(abs(10.^psd_fit)))
    hold on; loglog(f_psd,df_psd)
end