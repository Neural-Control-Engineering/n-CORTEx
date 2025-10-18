function MLIO_writeDS_rtspec(params, DF_smp, FID, args)

    % recover fold/sample 'address'
    % foldNum = args.foldNum;    
    % sampleNum = args.sampleNum;
    sampleAddress = args.sampleAddress;
    DSCfg = args.DSCfg; % 
    % numFolds = DSCfg.numFolds;
    % sessionLabel = sampleAddress.sessionLabel;
    % trialNum = sampleAddress.trialNum;
    conn_index = FID.conn_index;
    fld_DS = FID.fld_DS;
    file_index = FID.file_index;
    
    DFID = args.DFID_smp;
    % nexObj = args.nexObj_fitScope;
    % labelMode = args.labelMode;    
    
    % % locate dataset
    % ID_DS = sprintf("DS--rtspec_%s",DFID);
    % path_FTR = params.paths.Data.FTR.local;
    % path_DS = fullfile(path_FTR, ID_DS);
    % % build directory if doesnt exist AND save config
    % if ~isfolder(path_DS)
    %     [conn_index, file_index, fld_DS]=MLIO_buildDSDirectory(path_DS, DSCfg);    
    % end
    % write sample to dataset     
    sampleAddress.sampleFile = MLIO_writeSample(FID, DF_smp, sampleAddress, "hdf5");
    % write sample to index    
    % MLIO_appendSample2Index(fid_index, sampleAddress, DF_smp);
    MLIO_insertSample(conn_index, sampleAddress, DF_smp);
    % Only if the file is new/empty      
    % CASE - AUTO - loop through each sample individually

end