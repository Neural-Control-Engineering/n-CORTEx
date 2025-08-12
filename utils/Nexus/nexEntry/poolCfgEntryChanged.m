function poolCfgEntryChanged(event, source, poolMap, ID_field)
    % event.Value
    poolMap.(ID_field) = event.Value;
    % poolMap.divsPerBin = poolCfgPanel.uiSpinner_divsPerBin.Value;
    % poolMap.binType = poolCfgPanel.uiDropDown_binType.Value;
end