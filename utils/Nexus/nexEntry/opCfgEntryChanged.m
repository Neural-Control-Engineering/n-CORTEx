function opCfgEntryChanged(nexon, nexObj, nexPanel, entryfield, args)
    % recover Obj's operation parameters and use the associated
    % operation method to apply to dataframe

    % Update args to be passed into a given method
    value = nexPanel.editFields.(entryfield).uiField.Value;
    % nexPanel.editFields.(entryfield).uiField. = value;
    opArgs = nexObj.opCfg.entryParams;
    nexObj.opCfg.entryParams.(entryfield) = value;
    % nexObj.opCfg.opFcn(nexObj.dataFrame, opArgs);
    nexObj.updateScope(nexon);
end