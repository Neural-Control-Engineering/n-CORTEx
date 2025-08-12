function routerCfgParams = initializeRouterCfg(DTS)
    % router.subject="33114-20240526";    
    % router.date="2024-06-13";    
    % router.trial=13;
    % router.phase="L-hind-paw";
    % router.signal="lfp";            
    routerCfgParams.subj = parseSessionLabelUnique(DTS.sessionLabel,"subj");
    % subjSel = routerCfgParams.subject(1)
    subjSessionLabels = DTS.sessionLabel(contains(DTS.sessionLabel,routerCfgParams.subj(1)));
    routerCfgParams.date = parseSessionLabelUnique(subjSessionLabels,"date");
    subjXdateSessionLabels = subjSessionLabels(contains(subjSessionLabels,routerCfgParams.date(1)));
    routerCfgParams.phase = parseSessionLabelUnique(subjXdateSessionLabels,"phase");
    subjXdateXphaseLabels = subjXdateSessionLabels(contains(subjXdateSessionLabels,routerCfgParams.phase(1)));
    subjXdataXphaseTrialList = DTS.trialNumber(strcmp(DTS.sessionLabel,subjXdateXphaseLabels(1)));
    routerCfgParams.trial = string(num2str(subjXdataXphaseTrialList));
    
end