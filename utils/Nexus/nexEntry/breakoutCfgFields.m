function breakoutCfgFields(nexon, nexObj, nexPanel, cfgParams, entryChangedFcn)
    % VERSION 2 : draw entry panel but ensure entryChangedFcn modifies the 
    entryFields = fieldnames(cfgParams);
    panelSize = nexPanel.ph.Position;
    panelW = panelSize(3);
    panelH = panelSize(4);
    yStepScaler = 25;
    entryHeightScaler = 10;
    m=1;
    % newEntryFcn = str2func("writeNewEntryFieldCallback");
    for i=1:length(entryFields)
        editField = entryFields{i};
        value = cfgParams.(editField);        
        nexPanel.editFields.(editField).Label = uitextarea(nexPanel.ph,"Value",sprintf("%s",editField), "Position", [4,panelH-(m)*yStepScaler,panelW*0.95,panelH/entryHeightScaler], "BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen);
        switch class(value)
            case "double"                                   
                if size(value,2) == 1                                        
                    nexPanel.editFields.(editField).uiField = uieditfield(nexPanel.ph, "numeric", "Position", [4,panelH-(m+1)*yStepScaler,panelW*0.8,panelH/entryHeightScaler], "Value", cfgParams.(editField),"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen);                            
                elseif size(value,2) > 1                    
                    nexPanel.editFields.(editField).uiField = uieditfield(nexPanel.ph,"text", "Position", [4,panelH-(m+1)*yStepScaler,panelW*0.8,panelH/entryHeightScaler], "Value", array2string(cfgParams.(editField)),"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen);
                end                          
                nexPanel.editFields.(editField).uiField.ValueChangedFcn = @(~,~)entryChangedFcn(nexon, nexObj, nexPanel, editField);          
                entryParams.(editField) = value;
            case "string"
                if size(value,1) == 1
                    nexPanel.editFields.(editField).uiField = uieditfield(nexPanel.ph,"text", "Position", [4,panelH-(m+1)*yStepScaler,panelW*0.8,panelH/entryHeightScaler], "Value", array2string(cfgParams.(editField)),"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen,"ValueChangedFcn",@(~,~)entryChangedFcn(nexon, nexObj, nexPanel, editField));
                    entryParams.(editField) = value;
                elseif size(value,1) > 1
                    nexPanel.editFields.(editField).uiField = uidropdown(nexPanel.ph,"Position",[4,panelH-(m+1)*yStepScaler,panelW*0.8,panelH/entryHeightScaler],"Value",value(1),"Items",value,"BackgroundColor",nexon.settings.Colors.cyberGreen,"FontColor",[0,0,0],"ValueChangedFcn",@(~,~)entryChangedFcn(nexon, nexObj, nexPanel, editField));
                    entryParams.(editField) = value(1);
                end
        end
        m = m+2;
    end
end