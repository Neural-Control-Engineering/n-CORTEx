function MLIO_writeDS_rtspec(params, DF_smp, FID, args)

    % recover fold/sample 'address'
    % foldNum = args.foldNum;    
    % sampleNum = args.sampleNum;
    sampleAddress = args.sampleAddress;
    DSCfg = args.DSCfg; % 
    numFolds = DSCfg.numFolds;
    sessionLabel = sampleAddress.sessionLabel;
    trialNum = sampleAddress.trialNum;
    fid_index = FID.fid_index;
    fld_DS = FID.fld_DS;
    file_index = FID.file_index;
    
    % DFID = args.DFID_smp;
    % nexObj = args.nexObj_fitScope;
    % labelMode = args.labelMode;    
    
    % locate dataset
    ID_DS = sprintf("DS--rtspec_%s",DFID);
    path_FTR = params.paths.Data.FTR.local;
    path_DS = fullfile(path_FTR, ID_DS);
    % build directory if doesnt exist AND save config
    if ~isdir(path_DS)
        [fid_index, file_index, fld_DS]=MLIO_buildDSDirectory(path_DS, DSCfg);
    else
        if
        else
        end
    end
    % write sample to dataset and index
    writeTable(fid_index);

    
    % loop through each sample-'slice' (use source if necessary)
    % % for i = 1:size(df,1) % chans 
    % %     ptr_chans = i;        
    % %     for j = 1:size(df,3) % times
    % %         ptr_t = j;
    % %         % df_chan = df(ptr_chans,:,ptr_t);
    % %         % nexObj.DF.df_sig = df_chan;
    % %         % switch labelMode
    % %         %     case "manual"
    % %         %         nexObj.fitCfg.fitPtr.chans=ptr_chans;
    % %         %         nexObj.fitCfg.fitPtr.t=ptr_t;
    % %         %         nexObj.updateScope();            
    % %         %         % Wait for user entry
    % %         %         uiwait(nexObj.fh);                           
    % %         %         isSave = nexObj.UserData.isSave;
    % %         %     case "auto"
    % %         %         isSave = 1;
    % %         % end
    % % 
    % %         if isSave
    % %             % write to dataset
    % %             fid_index;
    % %             samplePath;
    % %         end
    % %     end
    % % end
end