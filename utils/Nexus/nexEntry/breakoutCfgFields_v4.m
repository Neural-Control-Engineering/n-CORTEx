function breakoutCfgFields_v4(nexObj, cfgObj, nexPanel, cfgParams, entryChangedFcn, entryChangedFcnArgs)
    % VERSION 3 : draw entry panel using spinners instead of numeric edit fields
    entryFields = fieldnames(cfgParams);
    panelSize = nexPanel.ph.Position;
    panelW = panelSize(3);
    panelH = panelSize(4);
    panelBASE = 5;
    % entryField scalers
    yStepScaler = 25;
    entryHeightScaler = 10;
    
    % Override scalers if specified
    if isfield(entryChangedFcnArgs,"yStepScaler")
        yStepScaler = entryChangedFcnArgs.yStepScaler;
    end
    if isfield(entryChangedFcnArgs,"entryHeightScaler")
        % Legacy knob, preserved for callers that already tune it explicitly.
        entryHeightScaler = entryChangedFcnArgs.entryHeightScaler;
        entryHeight = panelH/entryHeightScaler;
    else
        % Fixed, readable height derived from the row spacing itself, not
        % panelH — panelH/entryHeightScaler produced unreadably slim, wide
        % fields on the compact fitCfg panels (e.g. 80-170px tall) that call
        % this with no override. The panel is scrollable, so there's no need
        % to squeeze every row to fit within panelH.
        entryHeight = max(18, yStepScaler - 5);
    end

    m = 1;

    for i = 1:length(entryFields)
        editField = entryFields{i};
        value = cfgParams.(editField);        
        
        % Label
        nexPanel.editFields.(editField).Label = uitextarea(nexPanel.ph, ...
            "Value", sprintf("%s", editField), ...
            "Position", [4, panelBASE + (m+1)*yStepScaler, panelW*0.95, entryHeight], ...
            "BackgroundColor", [0, 0, 0], ...
            "FontColor", nexObj.nexon.settings.Colors.cyberGreen);
        
        % UI Control
        switch class(value)
            case "double"
                if isscalar(value)
                    % Use spinner instead of numeric field
                    nexPanel.editFields.(editField).uiField = uispinner(nexPanel.ph, ...
                        "Position", [4, panelBASE + (m+0)*yStepScaler, panelW*0.8, entryHeight], ...
                        "Value", value, ...
                        "Step", 1, ...
                        "Limits", [-Inf, Inf], ...
                        "BackgroundColor", [0, 0, 0], ...
                        "FontColor", nexObj.nexon.settings.Colors.cyberGreen);
                else
                    % Use text field for vector/matrix
                    nexPanel.editFields.(editField).uiField = uieditfield(nexPanel.ph, "text", ...
                        "Position", [4, panelBASE + (m+0)*yStepScaler, panelW*0.8, entryHeight], ...
                        "Value", array2string(value), ...
                        "BackgroundColor", [0, 0, 0], ...
                        "FontColor", nexObj.nexon.settings.Colors.cyberGreen);
                end

                nexPanel.editFields.(editField).uiField.ValueChangedFcn = ...
                    @(~,~)entryChangedFcn(nexObj, cfgObj, nexPanel, editField, entryChangedFcnArgs);

            case "string"
                if isscalar(value)
                    nexPanel.editFields.(editField).uiField = uieditfield(nexPanel.ph, "text", ...
                        "Position", [4, panelBASE + (m+0)*yStepScaler, panelW*0.8, entryHeight], ...
                        "Value", char(value), ...
                        "BackgroundColor", [0, 0, 0], ...
                        "FontColor", nexObj.nexon.settings.Colors.cyberGreen, ...
                        "ValueChangedFcn", @(~,~)entryChangedFcn(nexObj, cfgObj, nexPanel, editField, entryChangedFcnArgs));
                else
                    nexPanel.editFields.(editField).uiField = uidropdown(nexPanel.ph, ...
                        "Position", [4, panelBASE + (m+0)*yStepScaler, panelW*0.8, entryHeight], ...
                        "Value", value(1), ...
                        "Items", cellstr(value), ...
                        "BackgroundColor", nexObj.nexon.settings.Colors.cyberGreen, ...
                        "FontColor", [0, 0, 0], ...
                        "ValueChangedFcn", @(~,~)entryChangedFcn(nexObj, cfgObj, nexPanel, editField, entryChangedFcnArgs));
                end
        end
        
        m = m + 2;
    end
end
