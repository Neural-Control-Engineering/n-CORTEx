function rebuildExtractionLog(params)
    extractionLayerFields = fieldnames(params.paths.Data);
    for i=1:length(extractionLayerFields) % REDOUBLE RAW ONLY
        
        rawLayerDir_cloud = params.paths.Data.RAW.SLRT.cloud; % assuming eveyrthing is currently on cloud
        sessionList = struct2table(dir(rawLayerDir_cloud));
        for j = 3:height(sessionList)
            SessionName = strrep(string(sessionList.name{j}),".mat","");
            sessionFolder = string(sessionList.folder{j});
            tic
            slrtLoad = load(fullfile(sessionFolder,SessionName));
            if toc > 30
                continue
            end
            if isfield(slrtLoad,"realtimeLog")
                logsout = slrtLoad.realtimeLog.data;
            elseif isfield(slrtLoad,"logsout")
                logsout = slrtLoad.logsout;
            else
                disp(SessionName);
                error("logsout could not be identified by the ID realtimLog or logsout");
            end
            TrialMask = recoverTrialMask(logsout);
            if isempty(TrialMask)
                continue
            end
            Extracted = 1;            
            formatString = repmat('%d-',size(TrialMask,1),size(TrialMask,2));
            TrialMask = string(compose(formatString,TrialMask));            
            extractionRow = table(SessionName,Extracted,TrialMask);
            
            expmntPath = fullfile(params.paths.projDir_cloud,"Experiments",params.experiment);
            try
                log4Extraction(expmntPath,extractionRow,'csv');
            catch e
                disp(getReport(e));
                disp(SessionName);
                disp("Could not be logged");
            end
        end
    end
end