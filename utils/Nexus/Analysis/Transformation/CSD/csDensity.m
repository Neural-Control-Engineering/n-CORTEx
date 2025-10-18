function DF_out = csDensity(DF_in, args)
    
    % CFG HEADER
    spacing = args.spacing; % default = 1

    DF_out = DF_in;
    df_in = DF_in.df;
    % DF_out.df = computeCSD(df_in, spacing);
    df_in= df_in(2:2:385,:);
    DF_out.df = computeCSD(df_in, (3.84/13/1000));

end