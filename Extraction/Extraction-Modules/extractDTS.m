function extractDTS(params)
    sessionsToExtract = params.extrctItms.DTS.sessionsToExtract;
    sessions = sessionsToExtract.sessions;
    extData = params.paths.Data.EXT;
    DTS = [];
    for i = 1:length(sessions)
        session = sessions{i};
        extFields = fieldnames(extData);        
        dts = [];
        for j = 1:length(extFields)
            extField = extFields{j};            
            if sessionExists(params, session, extField, "EXT")
                sessionFile = sprintf("%s.mat",session);
                % LOAD AND CONDITION
                DT = load(fullfile(extData.(extField).cloud,sessionFile));
                dtField = fieldnames(DT);
                dtField = dtField{1};
                DT = DT.(dtField);
                DT.trialNum = cell2mat(DT.trialNum(~cellfun('isempty',DT.trialNum)));   
                if isempty(dts)
                    dts = DT;
                else
                    dts = outerjoin(dts, DT, "Keys", {'sessionLabel','trialNum'},"MergeKeys",true);
                end                
            end
        end
        DTS = [DTS; dts];
    end

end