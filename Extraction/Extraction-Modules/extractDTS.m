function extractDTS(params)
    sessionsToExtract = params.extrctItms.DTS.sessionsToExtract;
    sessions = sessionsToExtract.sessions;
    extData = params.paths.Data.EXT;
    dtsPath = fullfile(params.paths.Data.DTS.cloud);
   
    DTS = [];
    for i = 1:length(sessions)
        session = sessions{i}
        extFields = fieldnames(extData);    
        % ignore local and cloud fields
        dirMask = cell2mat(cellfun(@(x) ~strcmp(x,"local") & ~strcmp(x,"cloud"), extFields, "UniformOutput", false));
        extFields = extFields(dirMask);
        dts = [];
        for j = 1:length(extFields)
            extField = extFields{j};  
            disp(extField);
            if sessionExists(params, session, extField, "EXT")
                sessionFile = sprintf("%s.mat",session);
                % LOAD AND CONDITION
                DT = load(fullfile(extData.(extField).cloud,sessionFile));
                dtField = fieldnames(DT);
                dtField = dtField{1};
                DT = DT.(dtField);
                % standardized trialNumber and sessionLabel colum names
                % (camelback convention)                
                if any(ismember(DT.Properties.VariableNames,"trial_number"))
                    DT = renamevars(DT,["trial_number"],["trialNumber"]);
                end
                if any(ismember(DT.Properties.VariableNames,"session_label"))
                    DT = renamevars(DT,["session_label"],["sessionLabel"]);
                end
                if any(ismember(DT.Properties.VariableNames,"trialNum"))
                    DT = renamevars(DT,["trialNum"],["trialNumber"])
                end
                
                % DT.trialNum = cell2mat(DT.trialNum(~cellfun('isempty',DT.trialNum)));   
                DT.trialNumber = (DT.trialNumber(~cellfun('isempty',num2cell(DT.trialNumber))));   
                % ensure trialNumber is a cell array
                if ~(strcmp(class(DT.trialNumber),"cell"))
                    DT.trialNumber = num2cell(DT.trialNumber);
                end
                if isempty(dts)
                    dts = DT;
                else
                    if ~isempty(DT)                   
                        dts = outerjoin(dts, DT, "Keys", {'sessionLabel','trialNumber'},"MergeKeys",true);
                    end
                end                
            end
        end
        if ~isempty(DTS)
            if ~isempty(dts)
                DTS = mergeT_vertical(DTS, dts);
            else
                fprintf("ERROR, DOES NOT EXIST: %s",session)
            end
        else
            DTS = [DTS; dts];
        end        
        % outerjoin(DTS, dts,"Keys",dts.Properties.VariableNames,"MergeKeys",true);
    end

    % trialNumber conversion to double
    DTS.trialNumber = cell2mat(DTS.trialNumber);
    DTS_tall = tall((DTS));

    %  if size(dir(dtsPath),1) > 3
    %     DTS_prev = loadTall(dtsPath);
    % else
    %     DTS_prev = [];
    % end
    % DTS_full = [DTS_prev; DTS_tall];    
    % DTS = DTS_full;
    % Load pre-existing datastore
    % dsPrev = datastore(strcat("\\?\",fullfile(dtsPath,"D001")));    
    % DTS_prev = tall(dsPrev);
    if ispc
        DTS_prev = loadTall(strcat("\\?\",fullfile(dtsPath,"D008")));
        writePath = strcat("\\?\",fullfile(params.paths.Data.DTS.cloud));
    elseif isunix
        try 
            parpool("SpmdEnabled",false)
        catch
        end
        DTS_prev = loadTall(strcat(fullfile(dtsPath,"D008")));        
        writePath = strcat(fullfile(params.paths.Data.DTS.cloud));
    end
    if any(ismember(DTS_prev.Properties.VariableNames,"trialNum"))
        DTS_prev = renamevars(DTS_prev,["trialNum"],["trialNumber"]);
    end
    DTS_full = mergeTall_vertical(DTS_prev, DTS_tall);
    % write(pwd,DTS);
    % dts = datastore(fullfile(params.paths.Data.DTS.cloud,"dts.mat"),DTS_full);
    DTS = DTS_full;    
    write(strcat(fullfile(writePath,"D009")),DTS);
    % write(strcat("\\?\",fullfile(params.paths.Data.DTS.cloud,"D008\")),tall(DTS));
    % UPDATE EXTRACTION LOG
    extrctLog = params.extrctItms.DTS.extractionLog;
    sessionsExtrct = convertCharsToStrings(sessions);
    isExtrctIdx = find(ismember(extrctLog.SessionName,sessionsExtrct)==1);
    extrctLog(isExtrctIdx,:).Extracted=ones(size(isExtrctIdx,1),1);
    writetable(extrctLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","DTS")));
end