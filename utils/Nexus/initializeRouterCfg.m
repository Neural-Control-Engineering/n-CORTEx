function routerCfgParams = initializeRouterCfg(DTS)
    routerCfgParams.subj = parseSessionLabelUnique(DTS.sessionLabel, "subj");

    subjLabels = DTS.sessionLabel(contains(DTS.sessionLabel, routerCfgParams.subj(1)));

    routerCfgParams.date = parseSessionLabelUnique(subjLabels, "date");
    subjXdateLabels = subjLabels(contains(subjLabels, routerCfgParams.date(1)));

    routerCfgParams.phase = parseSessionLabelUnique(subjXdateLabels, "phase");
    subjXdateXphaseLabels = subjXdateLabels(contains(subjXdateLabels, routerCfgParams.phase(1)));

    % Optional 'site' — included only when present in the session labels
    terminalLabels = subjXdateXphaseLabels;
    siteCands = parseSessionLabelUnique(DTS.sessionLabel, "site");
    if ~isempty(siteCands) && ~all(siteCands == "")
        routerCfgParams.site = parseSessionLabelUnique(subjXdateXphaseLabels, "site");
        terminalLabels = subjXdateXphaseLabels(contains(subjXdateXphaseLabels, routerCfgParams.site(1)));
        if isempty(terminalLabels), terminalLabels = subjXdateXphaseLabels; end
    end

    trialNums = DTS.trialNumber(strcmp(DTS.sessionLabel, terminalLabels(1)));
    routerCfgParams.trial = string(num2str(trialNums))';
end