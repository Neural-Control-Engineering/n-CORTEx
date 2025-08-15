function cfgEntryChanged(nexon, nexObj, nexPanel, entryfield, args) 
    % Passive entry field updating when extra method not needed
    % Update args to be passed into a given method
    cfgFieldName = args.cfgFieldName;
    value = nexPanel.editFields.(entryfield).uiField.Value;
    % nexPanel.editFields.(entryfield) = value;
    nexObj.(cfgFieldName).entryParams.(entryfield) = value;      
    nexObj.updateScope();
end