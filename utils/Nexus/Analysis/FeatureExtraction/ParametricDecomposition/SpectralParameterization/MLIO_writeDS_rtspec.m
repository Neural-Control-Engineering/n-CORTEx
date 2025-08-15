function MLIO_writeDS_rtspec(params, DF_smp, Y, args)

    % recover fold/sample 'address'
    foldNum = args.foldNum;
    sampleNum = args.sampleNum;
    sessionLabel = args.sessionLabel;
    trialNum = args.trialNumber;
    DFID = args.DFID_smp;
    nexObj = args.nexObj_fitScope;
    labelMode = args.labelMode;    
    
    % locate dataset
    ID_DS = sprintf("DS--rtspec_%s",DFID);
    path_FTR = params.paths.Data.FTR.local;
    path_DS = fullfile(path_FTR, ID_DS);
    % loop through each sample-'slice' (use source if necessary)
    for i = 1:size(df,1)        
        df_chan = df(i,:,t);
        nexObj.DF.df = df_chan;
        switch labelMode
            case "manual"
                nexObj.updateScope();            
                % Wait for user entry
                uiwait(nexObj.fh);           
            case "auto"
        end
    end
end