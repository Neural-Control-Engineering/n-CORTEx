function DF_out = regionDropout(nexon, DF_in, args)
    
    % CFG HEADER
    t_cutoff = args.t_cutoff; % default = 5500

    df = DF_in.df;
    ax = DF_in.ax;
    ptr = nexInit_axisPointer(DF_in.df, DF_in.ax);
    dim_t = ptr.t.dim;
    ndims_df = ndims(df);
    slice = repmat({':'}, 1, ndims_df);
    % tLim = [1:5500];
    tLim=[1:length(ax.t)];
    slice{dim_t}=tLim;
    df = df(slice{:});
    ax_cutoff = ax;
    ax_t = ax.t;
    ax_cutoff.('t') = ax_t(tLim);
    % recover regMap by subject (use registry)
    idx_row=args.idx_row;
    sessionLabel = nexon.console.BASE.DTS.sessionLabel{idx_row};
    subject = convertCharsToStrings(parseSessionLabel(sessionLabel,"subj"));
    subjectID = sprintf("subj_%s",strrep(subject,"-","_"));
    regMap = nexon.console.BASE.registry.SUBJ.(subjectID).regMap;
    % regMap = nexon.console.NPXLS.shanks.shank1.regMap;
    regions = unique(convertCharsToStrings(regMap.region));
    df_dropout = [df];
    ax_dropout = ["NULL"];
    
    for i = 1:length(regions)
        region = regions(i);
        % apply dropout        
        slice = repmat({':'},1,ndims(df));
        chanDim = ptr.chans.dim;
        
        regIdx = find(ismember(regMap.region,region));
        regChans = sort(cell2mat(regMap.channel(regIdx))');
        slice{chanDim} = regChans;
    
        sliceData  = df(slice{:});
        sliceSize  = size(sliceData);
        sliceMin   = min(sliceData(:,10:end), [], 'all');
        sliceMax   = max(sliceData(:,10:end), [], 'all');
        noiseSlice = sliceMin + rand(sliceSize) * (sliceMax - sliceMin);
        df_dropout_i = df;
        df_dropout_i(slice{:}) = noiseSlice;

        dropoutID_i = region;

        catDim = ndims_df+1;
        df_dropout = cat(catDim, df_dropout, df_dropout_i);
        ax_dropout = [ax_dropout, dropoutID_i];
    end

    DF_dropout = DF_in;
    DF_dropout.ax=ax_cutoff;
    DF_dropout.df=df_dropout;
    DF_dropout.ax.dropout=ax_dropout;
    DF_dropout.ptr = nexInit_axisPointer(DF_dropout.df, DF_dropout.ax);
    DF_out = DF_dropout;

end