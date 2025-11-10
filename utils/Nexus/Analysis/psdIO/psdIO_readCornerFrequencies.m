function df_cf = psdIO_readCornerFrequencies(f_psd, df_psd)

    % CFG HEADER
    thresh = 1.4;
    debounceRange = 13;
    smoothFactor = 0.15;

    %% patch 60 Hz noise
    band = (f_psd>56)&(f_psd<62);
    band_rep = (f_psd>62)&(f_psd<65);
    mean_rep = mean(df_psd(band_rep));
    % df_psd(band) = mean_rep;        
    %% lowess smoothing
    % df_smooth  = lowess(df_psd', 0.55);
    % df_smooth = lowess(df_psd',smoothFactor);
    DF_psd.df=df_psd;
    args = extractMethodCfg('smooth_ASLS');
    DF_smooth = smooth_ASLS(DF_psd, args);
    df_smooth =DF_smooth.df';
    %% rate of change
    numTicks = 40;    
    % f_ticks = ((logspace(log10(f_psd(1)),log10(f_psd(end)-1), numTicks)));
    f_ticks = ((logspace(log10(f_psd(2)),log10(f_psd(end)-1), numTicks)));
    f_ticks = (unique(floor(f_ticks)));
    df_smooth_resamp = df_smooth(f_ticks); % resample on log scale    
    df_smooth_diff = diff(df_smooth_resamp); % derivative
    % df_smooth_diffDiff = diff(df_smooth_diff);
    %% exponential thresholding
    df_smooth_diff_exp = exp(abs(df_smooth_diff));
    % figure; plot(df_smooth_diff_exp);
    df_smooth_diff_exp_diff = diff(df_smooth_diff_exp);
    % figure; plot(df_smooth_diff_exp_diff); title("diff1")
    % hold on
    % df_smooth_diff_exp_diff_diff = diff(df_smooth_diff_exp_diff);
    % plot(df_smooth_diff_exp_diff); title("diff2")
    % isolate order of magnitude difference
    % gain_diff = df_smooth_diff_exp_diff(2:end) ./ df_smooth_diff_exp_diff(1:end-1);
    gain_diff = df_smooth_diff_exp_diff(2:end) ./ df_smooth_diff_exp_diff(1:end-1);
    % gain_diff = 1.1.^(df_smooth_diff_exp_diff);
    % figure; plot(f_ticks(1:length(gain_diff)), gain_diff);    
    % figure; plot(abs(gain_diff)); title("gain")
    % figure; plot(log(abs(gain_diff)))
    % need 'debounce' (no consecutive within 10 Hz)    
    gainVals = abs(gain_diff);
    gainVals_debounce = [];
    i = 1;
    while i <= length(gainVals)
        gainVal = gainVals(i);        
        if log(gainVal) > thresh
            % fprintf('Event at %d\n', i);            
            % Skip next 10 samples
            gainVals_debounce = [gainVals_debounce, gainVal];
            i = i + debounceRange;
            continue;
        end        
        i = i + 1;
    end    
    % select top two    
    gainVals_sort = sort(gainVals_debounce);    
    idx_gainVals_sel = find(any(((gainVals==gainVals_sort)),2));
    % topGainVals = gainVals_sort(end-1:end);
    % resolve indices
    % idx_cf = find(gainVals_sort>10)+2;
    % f_cf = f_ticks(idx_cf);    
    f_cf = f_ticks(idx_gainVals_sel)    
    df_cf = f_cf;
end