function loadTrialDF(nexObj, MOD)
    % MOD : nCORTEx-modality corresponding to trial recording location
    % getdir action (user points to trial to be loaded)
    % dataDir_local = strcat("\\?\",nexObj.nCORTEx.params.paths.Data.RAW.(MOD).local);
    dataDir_local = strcat(nexObj.nCORTEx.params.paths.Data.RAW.(MOD).local);
    [files, folder] = uigetfile({'*.*', 'All Files'}, 'Select files', dataDir_local, 'MultiSelect', 'on');
    trialDataSel = dir(folder);
    trialNames = convertCharsToStrings(struct2table(trialDataSel).name);
    selIdx = listdlg('ListString',trialNames);
    trialSel = trialNames(selIdx);
    trialSel = rmExtension(trialSel);
    [trialNum,~,sessionLabel] = decodeTrigger(trialSel);
    % sessionLabel = split(trialSel,'.');
    % sessionLabel = sessionLabel{1}; % remove file-type suffix        
    % [~,~,sessionLabel] = decodeTrigger(sessionLabel);    

    % dataDir = dir(dataDir_local);    
    % shortPath=files;
    % Use PowerShell to expand the full path
    % longPath = expandShortPath(shortPath)
    switch MOD
        case "NPXLS"
            % get data type
            chan_imec = 1:385;
            data = ReadSGLXData(trialSel, folder, chan_imec);
            % for now assuming lfp
            DFID = "lfp";
            DF = nexExtract_LFP(data);            
        case
    end
    % write to nexon (if accessible)
    rowAddress.sessionLabel=sessionLabel;
    rowAddress.trialNumber=trialNum;
    dtsIO_writeDF(nexObj.nexon,DF,DFID,rowAddress);

end