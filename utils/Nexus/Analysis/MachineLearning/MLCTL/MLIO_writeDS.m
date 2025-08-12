function MLIO_writeDS(params, DTS, DFID, writeFcn, args)
    % visit each entry in DTS and write labeled sample to DS    

    % CFG HEADER
    n_folds = args.n_folds; % default = 5

    n_dtsRows = height(DTS);    
    n_samplesPerFold = floor(n_dtsRows / n_folds);   
    path_FTR = nexon.console.BASE.params.paths.Data.FTR.local;
    dsType = split(func2str(exportFcn),"_"); dsType = convertCharsToStrings(dsType(end));
    dfID_target = split(DFID_postOp,"--"); dfID_target = dfID_target(end);
    name_DS = sprintf("%s--%s", dsType, dfID_target);
    folder_DS =  fullfile(path_FTR,name_DS);
    buildPath(folder_DS);
    for i = 1:n_dtsRows
        % grab DF(s)
        DF_source = dtsIO_readDF(nexon, DFID_preOp, i);
        DF_target = dtsIO_readDF(nexon, DFID_postOp, i);
        %% Directory mapping/setup
        foldNum =  floor((i-1)/n_samplesPerFold)+1;
        foldDir = fullfile(folder_DS,sprintf("Fold%d",foldNum));
        buildPath(foldDir);
        % label index
        fn_index = fullfile(folder_DS,'index.csv');
        % Create an empty CSV file (if not already existing)
        fclose(fopen(fn_index, 'w'));  % Opens and immediately closes, creating an empty file
        % Now open it for reading
        fid_index = fopen(fn_index, 'r');        
        % export (rtSpec, whole sample, etc.)
        % path_sample = fullfile(foldDir)
        writeFcn(nexon, DF_target, DF_source, [], fid_index, foldDir)
    end
end