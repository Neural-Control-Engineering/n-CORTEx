function entryParams = breakoutEditFields(nexon, entryPanel, cfgParams, entryChangedFcn, yStepScaler, entryHeightScaler, forceDropDown)
    if nargin < 7
        forceDropDown=0;
    end
    entryFields = fieldnames(cfgParams);
    panelSize = entryPanel.Panel.ph.Position;
    panelW = panelSize(3);
    panelH = panelSize(4);
    if isempty(yStepScaler); yStepScaler = 20; end
    if isempty(entryHeightScaler); entryHeightScaler = 15; end
    m=1;
    % newEntryFcn = str2func("writeNewEntryFieldCallback");
    for i=1:length(entryFields)
        editField = entryFields{i};
        value = cfgParams.(editField);        
        entryPanel.Panel.(editField).Label = uitextarea(entryPanel.Panel.ph,"Value",sprintf("%s",editField), "Position", [4,panelH-(m)*yStepScaler,panelW*0.95,panelH/entryHeightScaler], "BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen);
        switch class(value)
            case "double"                                   
                if size(value,2) == 1 & (forceDropDown==0)
                    % panel.(editField).uiField = uieditfield(panel.ph, "numeric", "Position", [4,panelH-(m+1)*yStepScaler,panelW*0.8,panelH/entryHeightScaler], "Value", entryObj.(editField), "ValueChangedFcn", newEntryFcn(panel, rtStream, editField));        
                    entryPanel.Panel.(editField).uiField = uieditfield(entryPanel.Panel.ph, "numeric", "Position", [4,panelH-(m+1)*yStepScaler,panelW*0.8,panelH/entryHeightScaler], "Value", cfgParams.(editField),"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen);                            
                elseif size(value,2) > 1
                    % panel.(editField).uiField = uieditfield(panel.ph,"text", "Position", [4,panelH-(m+1)*yStepScaler,panelW*0.8,panelH/entryHeightScaler], "Value", array2string(entryObj.(editField)), "ValueChangedFcn", newEntryFcn(panel, rtStream, editField));
                    entryPanel.Panel.(editField).uiField = uieditfield(entryPanel.Panel.ph,"text", "Position", [4,panelH-(m+1)*yStepScaler,panelW*0.8,panelH/entryHeightScaler], "Value", array2string(cfgParams.(editField)),"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen);
                end                          
                entryPanel.Panel.(editField).uiField.ValueChangedFcn = @(~,~)entryChangedFcn(nexon, entryPanel, editField);          
                entryParams.(editField) = value;
            case "string"
                if size(value,1) == 1 & (forceDropDown==0)
                    entryPanel.Panel.(editField).uiField = uieditfield(entryPanel.Panel.ph,"text", "Position", [4,panelH-(m+1)*yStepScaler,panelW*0.8,panelH/entryHeightScaler], "Value", array2string(cfgParams.(editField)),"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen,"ValueChangedFcn",@(~,~)entryChangedFcn(nexon, entryPanel, editField));
                    entryParams.(editField) = value;
                elseif size(value,1) > 1 || (forceDropDown==1)
                        entryPanel.Panel.(editField).uiField = uidropdown(entryPanel.Panel.ph,"Position",[4,panelH-(m+1)*yStepScaler,panelW*0.8,panelH/entryHeightScaler],"Value",value(1),"Items",value,"BackgroundColor",nexon.settings.Colors.cyberGreen,"FontColor",[0,0,0],"ValueChangedFcn",@(~,~)entryChangedFcn(nexon, entryPanel, editField));
                        entryParams.(editField) = value(1);
                end
        end
        m = m+2;
    end
end