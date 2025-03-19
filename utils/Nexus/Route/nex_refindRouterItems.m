function nex_refindRouterItems(nexon)
    % refind dropdown items    
    entryParams = nexon.console.BASE.router.entryParams;
    if isfield(entryParams,"subject")
        subjSessionLabels = nexon.console.BASE.DTS.sessionLabel(contains(nexon.console.BASE.DTS.sessionLabel,entryParams.subject));    
    elseif isfield(entryParams,"subj")
        subjSessionLabels = nexon.console.BASE.DTS.sessionLabel(contains(nexon.console.BASE.DTS.sessionLabel,entryParams.subj));    
    end
    parseSessionLabelUnique(subjSessionLabels,"date");
    subjXdateSessionLabels = subjSessionLabels(contains(subjSessionLabels,entryParams.date));    
    subjXdateXphaseLabels = subjXdateSessionLabels(contains(subjXdateSessionLabels,entryParams.phase));    
    nexon.console.BASE.router.Panel.date.uiField.Items=parseSessionLabelUnique(subjSessionLabels,"date");
    nexon.console.BASE.router.Panel.phase.uiField.Items=parseSessionLabelUnique(subjXdateSessionLabels,"phase");
    subjXdateXphaseTrialList = nexon.console.BASE.DTS.trialNumber(strcmp(nexon.console.BASE.DTS.sessionLabel,subjXdateXphaseLabels(1)));    
    nexon.console.BASE.router.Panel.trial.uiField.Items=string(num2str(subjXdateXphaseTrialList))';   
end