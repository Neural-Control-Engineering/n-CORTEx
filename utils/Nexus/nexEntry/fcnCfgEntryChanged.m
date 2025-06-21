function fcnCfgEntryChanged(nexObj, nexPanel, entryfield, args, actOnCallback)
    % recover Obj's operation parameters and use the associated
    % operation method to apply to dataframe

    % Update args to be passed into a given method
    value = nexPanel.editFields.(entryfield).uiField.Value;
    % nexPanel.editFields.(entryfield).uiField. = value;
    fcnArgs = nexObj.(ID_fcnCfg).entryParams;
    if actOnCallback
        nexObj.(ID_fcnCfg).fcn(nexObj.dataFrame, opArgs);
    end
    nexObj.(ID_fcnCfg).entryParams.(entryfield) = value;
    
    nexObj.updateScope(nexon);
end