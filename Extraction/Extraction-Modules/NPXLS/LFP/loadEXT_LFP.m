function LFP = loadEXT_LFP(params, session)
    % disp('loading LFP for %s',session);
    % LFP.meta.fs = 2500/5;
    LFP.trialNum = {};
    LFP.sessionLabel = {};
    LFP.lfp = {};
    LFP.pulse1Hz = {};
    LFP.npxlsTrig = {};
    LFP.fs = {};
    LFP.QC = {};
    if sessionExists(params, session, "NPXLS", "RAW")
        sessionDataPath = fullfile(params.paths.Data.RAW.NPXLS.cloud,session);
        numImecs = length(categorize(sessionDataPath,'imec'));
        for i = 1:numImecs
            imecTag = sprintf("imec%d",(i-1));
            sessionImec = sprintf("%s_imec%d",session,i-1);
            sortedDataPath = fullfile(sessionDataPath,sessionImec);            
            numTrigs = length(categorize(sortedDataPath,'sorted'));            
            sortedSessions = string(categorize(sortedDataPath,'sorted'));
            for j = 1:numTrigs                
                % sessionSorted = sprintf("%s_t%d_sorted",session,j-1);
                sortedSession = sortedSessions(j);
                sessionLabelParts = split(sortedSession,'_');
                trialTag = sessionLabelParts(end-1);
                sortedTrialPath = fullfile(sortedDataPath,sortedSession);
                lfp = load(fullfile(sortedTrialPath,'lfp.mat'),'lfp').lfp;
                nidq = load(fullfile(sortedTrialPath,'nidq.mat'),'nidq').nidq;                
                LFP.trialNum = [LFP.trialNum; sscanf(trialTag,"t%d")];
                LFP.sessionLabel = [LFP.sessionLabel; session];
                LFP.lfp = [LFP.lfp; lfp];
                LFP.pulse1Hz = [LFP.pulse1Hz; nidq.dataArray(1,:)];
                LFP.npxlsTrig = [LFP.npxlsTrig; nidq.dataArray(2,:)];
                LFP.fs = [LFP.fs; 2500/5];
                LFP.QC = [LFP.QC; 0];
                
                % LFP.data.(trigTag).(imecTag).lfp = lfp;
                % LFP.data.(trigTag).(imecTag).pulse1Hz = nidq.dataArray(1,:); % change when valid
            end  
        end
    end
    LFP = struct2table(LFP);
end