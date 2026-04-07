function STAT_postOp = subr_dropoutTransform_regions(mdlObj, args)

    % CFG HEADER
    region = args.region; % default = "STN"

    % STAT-wise subroutine: allocate dropout matrices to test dropout
    % hypotheses, and return transformed STAT for analysis and inspection
    STAT = mdlObj.STAT;
    ptr = STAT.ptr(1);
    df = STAT.df{1};
    chanDim = ptr.chans.dim;
    slice = repmat({':'},1,ndims(df));

    % apply dropout
    regMap = mdlObj.nexon.console.NPXLS.shanks.shank1.regMap;
    regIdx = find(ismember(regMap.region,region));
    regChans = sort(cell2mat(regMap.channel(regIdx))');
    slice{chanDim} = regChans;
    STAT_struct = arrayfun(@(s) {s}, table2struct(STAT));
    % STAT_slice = cellfun(@(DF) nexOp_sliceDF(DF, "chans", regChans), STAT_struct);
    STAT_dropout = cellfun(@(DF) nexOp_dropoutAx(DF, slice), STAT_struct);    

    % transform
    STAT_tf = mdlObj.transformSTAT(STAT_dropout);

    % breakout (hypotheses)
    % STAT_postOp = nexStat_breakoutDF()

    % return
    
end