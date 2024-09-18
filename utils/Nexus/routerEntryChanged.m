function routerEntryChanged(nexon,entryPanel,entryfield)
    % update parameters and relevant scope dataframes, etc
    value = entryPanel.Panel.(entryfield).uiField.Value;
    entryPanel.entryParams.(entryfield) = value;
    params = nexon.console.BASE.params;
    if strcmp(entryfield,"subject")
        nexon.console.BASE.router.UserData.subjectDir =  fullfile(params.paths.nCORTEx_local,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subject);        
    end
    % NPXLS UPDATE (apply new dataFrame for each shank --> existing timeCourse, spectrogram, etc) 
    shankList = fieldnames(nexon.console.NPXLS.shanks);
    for i = 1:length(shankList)
        shank = shankList{i};
        scopeList = fieldnames(nexon.console.NPXLS.(shank).scopes);
        for j = 1:length(scopeList)
            scope = scopeList{i};
            dfID = nexon.console.NXPLS.(shank).(scope).dfID; % grab trial-wise corresponding dfID
        end
    end

    grabDataFrame(nexon,"lfp");
end