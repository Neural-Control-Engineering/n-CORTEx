function DF_out = nexSpec_bandRatio(DF_in, args)

    % CFG HEADER
    freq_A = args.freq_A; % default = 37
    freq_B = args.freq_B; % default = 8

    % take band power ratios given freq A and freq B (A/B)
    f = DF_in.ax.f;
    fCond_A = find(f==freq_A);
    fCond_B = find(f==freq_B);
    % slice at freq A
    df_A = DF_in.df(:,fCond_A,:);
    sem_A = DF_in.sem(:, fCond_A, :);
    % slice at freq B
    df_B = DF_in.df(:,fCond_B,:);
    sem_B = DF_in.sem(:, fCond_B, :);

    % propagate error (no covariance yet)
    R = df_A ./ df_B;
    SEM_R = R .* (sqrt( (sem_A ./ df_A).^2 + (sem_B ./ df_B).^2 ));

    DF_out = DF_in;
    % format result
    DF_out.df = R;
    DF_out.ax = DF_in.ax;
    DF_out.sem = SEM_R;
    
    

end