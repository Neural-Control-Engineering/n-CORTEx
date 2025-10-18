function opCfgEntryChanged_v2(nexObj, cfgObj, nexPanel, entryfield, args) 
    % Passive entry field updating when extra method not needed
    % Update args to be passed into a given method
    % cfgFieldName = args.cfgFieldName;
    value = nexPanel.editFields.(entryfield).uiField.Value;
    % nexPanel.editFields.(entryfield) = value;
    % nexObj.(cfgFieldName).entryParams.(entryfield) = value;      
    cfgObj.(entryfield) = value; % update cfg field
    nexObj.operate();
end