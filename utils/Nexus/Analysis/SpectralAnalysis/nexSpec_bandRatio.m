function DF_out = nexSpec_bandRatio(DF_in, args)

    % CFG HEADER
    freq_A = args.freq_A; % default = 36
    freq_B = args.freq_B; % default = 8

    % take band power ratios given freq A and freq B (A/B)
    f = DF_in.ax.f;
    fCond_A = find(f==freq_A);
    fCond_B = find(f==freq_B);
    % slice at freq A
    df_A = DF_in.df(:,fCond_A,:);
    if isfield(DF_in,"sem")
        sem_A = DF_in.sem(:, fCond_A, :);
    else
        sem_A = [];
    end
    % slice at freq B
    df_B = DF_in.df(:,fCond_B,:);
    if isfield(DF_in,"sem")
        sem_B = DF_in.sem(:, fCond_B, :);
    else
        sem_B = [];
    end

    % propagate error (no covariance yet)
    R = df_A ./ df_B;
    if ~isempty(sem_A) & ~isempty(sem_B)
        SEM_R = R .* (sqrt( (sem_A ./ df_A).^2 + (sem_B ./ df_B).^2 ));
    else
        SEM_R = [];
    end

    DF_out = DF_in;
    % format result
    DF_out.df = squeeze(R);
    DF_out.ax = DF_in.ax;
    DF_out.ax = rmfield(DF_out.ax,"f"); % lose frequency axis
    DF_out.sem = SEM_R;
    
    

end