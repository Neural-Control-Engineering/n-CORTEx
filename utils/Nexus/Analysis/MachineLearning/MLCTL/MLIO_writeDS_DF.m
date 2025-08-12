function MLIO_writeDS_DF(params, DF_smp, Y, args)

    % recover fold/sample 'address'
    foldNum = args.foldNum;
    sampleNum = args.sampleNum;
    sessionLabel = args.sessionLabel;
    trialNum = args.trialNumber;
    DFID = args.DFID_smp;
    
    % locate dataset
    ID_DS = sprintf("DS--rtspec_%s",DFID);
    path_FTR = params.paths.Data.FTR.local;
    path_DS = fullfile(path_FTR, ID_DS);
    % loop through each sample-'slice' (use source if necessary)
    for i = 1:size(df,1)
        
        % check index for pre-existing sample / channel
    end
end