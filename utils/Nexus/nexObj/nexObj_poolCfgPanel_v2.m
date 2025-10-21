function poolCfgPanel = nexObj_poolCfgPanel_v2(nexObj, panel, poolCfgEntryChangedFcn)
    nexon = nexObj.nexon;
    % dropdown/spinner combo
    W_panel = panel.ph.Position(3);
    H_panel = panel.ph.Position(4); 
    
    h_button = 30;
    h_uiField = 20;
    padding = 5;
    % padding = h_uiField;
    
    yPtr = H_panel - padding - h_uiField;
    yStep = h_uiField + padding;
    
    w_dropdown = W_panel * 0.5 - padding * 1.5;
    w_spinner  = W_panel * 0.5 - padding * 1.5;
    
    % Collect fieldnames
    % axFields = fieldnames(poolCfg.ax);    
    % nexObjFields = convertCharsToStrings(properties(nexObj));      
    % check Origin for master pMap
    try
        pMap = nexObj.Origin.pMap;
    catch % use in-place pMap otherwise
        pMap = nexObj.pMap;
    end
    pMapFields = convertCharsToStrings(fieldnames(pMap));
    % if isempty(pMapFields)
    %     nexObjFields = convertCharsToStrings(fields(nexObj));        
    % end
    
    axFields = pMapFields(contains(pMapFields,"pMap_"));
    
    for i = 1:length(axFields)
        % axField = string(axFields{i});
        axField = axFields(i);
        % poolMap = nexObj.(axField);
        poolMap = pMap.(axField);
        % segOpts = poolCfg.ax.(axField).segOpts;
        segOpts = poolMap.binTypes;
        
        % Label
        uiTextID = sprintf("%s_label", axField);
        panel.(uiTextID) = uitextarea(panel.ph, ...
            "Position", [padding, yPtr, W_panel - 2*padding, h_uiField], ...
            "FontColor", nexon.settings.Colors.cyberGreen, ...
            "BackgroundColor", [0, 0, 0], ...
            "Value", axField);
    
        yPtr = yPtr - yStep;
    
        % Dropdown (left half)
        uiID = sprintf("%s_dropDown", axField);
        panel.(uiID) = uidropdown(panel.ph, ...
            "Items", segOpts, ...
            "Value", segOpts(1), ...
            "Position", [padding, yPtr, w_dropdown, h_uiField], ...
            "BackgroundColor", nexon.settings.Colors.cyberGreen, ...
            "FontColor", [0, 0, 0],...
            "ValueChangedFcn", @(src, event)poolCfgEntryChangedFcn(src, event, poolMap, "binType"));
    
        % Spinner (right half)
        uiID = sprintf("%s_spinner", axField);
        panel.(uiID) = uispinner(panel.ph, ...
            "Value", 1, ...
            "Position", [padding + w_dropdown + padding, yPtr, w_spinner, h_uiField], ...
            "BackgroundColor", [0, 0, 0], ...
            "FontColor", nexon.settings.Colors.cyberGreen, ...
            "Limits", [1, Inf], ...
            "Step", 1,...
            "ValueChangedFcn", @(src, event)poolCfgEntryChangedFcn(src, event, poolMap, "divsPerBin"));
    
        yPtr = yPtr - yStep;
    end
    
    % Apply button (10 units below last element)
    panel.applyPoolButton =  uicontrol(panel.ph, ...
        "Style", "pushbutton", ...
        "String", "", ...
        "Position", [padding, yPtr - 10, W_panel - 2*padding, h_button], ...
        "BackgroundColor", nexon.settings.Colors.cyberGreen, ...
        "ForegroundColor", [0, 0, 0], ...
        "FontWeight", "bold", ...
        "Callback", @(src, event)nexObj.updateScope());

    % return handle
    poolCfgPanel = panel;
    
end