function methodCfgEntryChanged(nexon, entryPanel, entryfield)
    % Update args to be passed into a given method
    value = entryPanel.Panel.(entryfield).uiField.Value;
    entryPanel.Panel.entryParams.(entryfield) = value;
end