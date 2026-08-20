function DF_out = nexOp_eventAlignDF(DF_in, sample_event, Fs, t_preBuff, isShift)

    % realign '0' of time vector by the sample number of the given event,
    % given preBuffLen and samplingFrequency

    ratio_origin = 7/22; % proportion of sample as 'preBuffer'

    DF_out=DF_in;
    ax_t = DF_in.ax.t;
    df = DF_out.df;
    ptr = nexInit_axisPointer(df, DF_in.ax);

    idx_origin = round(length(ax_t) * ratio_origin);
    
    if isempty(sample_event)
        sample_event = t_preBuff*Fs;
        disp("Missing Event Index: Skipping Alignment");
    end

    try
        ax_t = ax_t - (sample_event / Fs - t_preBuff);    
    catch
        ax_t = ax_t - (sample_event / Fs);            
        disp("WARNING: check preBuffer settings (missing t_preBuff");
    end
   
    [~, idx_origin_new] = (min(abs(ax_t)));    
    
    if isShift % shift         
        dim_t = ptr.t.dim;
        s_shift =  idx_origin - idx_origin_new; % samples to shift by (default = t_preBuff)
        df_shift= circshift(df, s_shift, dim_t);
        % figure; imagesc(squeeze(df(1,:,:))); figure; imagesc(squeeze(df_shift(1,:,:)));
        df=df_shift;
        % control ax edge effects by expanding         
        dx = mean(diff(ax_t));   % spacing (robust if uniform)
        n_extend = abs(s_shift);         % how many points to add on each side
        N_ext = numel(ax_t) + 2*n_extend;
        ax_t_extended = linspace(ax_t(1) - n_extend*dx, ax_t(end) + n_extend*dx, N_ext);
        ax_t_shift = circshift(ax_t_extended, s_shift);
        % cutoff to length (remove s_shift on each side)
        % N = numel(ax_t_extended) - 2*n_extend;   % original length
        N = length(ax_t);
        start_idx = n_extend + 1;
        end_idx   = start_idx + N - 1;        
        ax_t = ax_t_shift(start_idx:end_idx);

    end

    DF_out.df = df;
    DF_out.ax.t = ax_t;
    
end