function segEXT_SLRT(params)
    % apply pre-segmentation method (in case in-situ segmentation could not be
    % performed)
    % Utilize this method by updating your extraction configuration in your
    % selected project and experiment directory (or experiment modules directory)

    % segEXT_SLRT will call your preferred presegmentation method given the
    % following inputs:

    % 1) params - a general purpose configuration of your instantion of
    % nCORTEx and a directory mapping of your associated experiment    

    % and expects the following outputs:

    % 1) logsout - the realtime logging of your signals collected during
    % the experiment, now (by your custom method) updated to include
    % 'signals' encoding the timestamps of: a) the beginnings of 'trials' (denoted using
    % the label trialSeg) and b) notable events you want to be included in the
    % segmentation process, according to the signal logging dictionary
    % included in the nCORTEx extraction paradigm (see documentation
    % online)
 
    %% ISOLATE UNSEGMENTED SLRT FILES (using extraction log)
    extrctModules = params.extrctItms.EXT.extrctModules;
    extractionLog = params.extrctItms.EXT.extractionLog;    
    % process datastreams relative to SLRT
    try
        load(fullfile(params.paths.expmntPath_cloud,"extractCfg.mat"),"extractCfg");
    catch
        extractCfg = struct;
        extractCfg.EXT = struct;
        disp("extractCfg file not found, proceeding...");
    end    

    %% ITERATE THROUGH SLRT FILES
    sessions = params.extrctItms.EXT.sessionsToExtract.sessions;
    numSessions = size(sessions,1)
    for i = 1:numSessions
        %% Apply segmentation method (this will add at least one new signal)
        %% Save result back for next segmentation step
    end

    

end