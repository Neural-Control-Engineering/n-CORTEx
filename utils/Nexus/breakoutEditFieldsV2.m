function entryPanel = breakoutEditFieldsV2(nexon, obj, cfgPanel, cfgParams, entryChangedFcn)
    % VERSION 2 : draw entry panel but ensure entryChangedFcn modifies the 
    entryFields = fieldnames(cfgParams);
    % panelSize = entryPanel.Panel.ph.Position;
    panelSize = cfgPanel.Panel.ph.Position;
    panelW = panelSize(3);
    panelH = panelSize(4);
    m=1;
    % newEntryFcn = str2func("writeNewEntryFieldCallback");
    for i=1:length(entryFields)
        editField = entryFields{i};
        value = cfgParams.(editField);        
        entryPanel.Panel.(editField).Label = uitextarea(entryPanel.Panel.ph,"Value",sprintf("%s",editField), "Position", [4,panelH-(m)*25,panelW*0.95,panelH/30], "BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen);
        switch class(value)
            case "double"                                   
                if size(value,2) == 1                    
                    % panel.(editField).uiField = uieditfield(panel.ph, "numeric", "Position", [4,panelH-(m+1)*25,panelW*0.8,panelH/30], "Value", entryObj.(editField), "ValueChangedFcn", newEntryFcn(panel, rtStream, editField));        
                    entryPanel.Panel.(editField).uiField = uieditfield(entryPanel.Panel.ph, "numeric", "Position", [4,panelH-(m+1)*25,panelW*0.8,panelH/30], "Value", cfgParams.(editField),"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen);                            
                elseif size(value,2) > 1
                    % panel.(editField).uiField = uieditfield(panel.ph,"text", "Position", [4,panelH-(m+1)*25,panelW*0.8,panelH/30], "Value", array2string(entryObj.(editField)), "ValueChangedFcn", newEntryFcn(panel, rtStream, editField));
                    entryPanel.Panel.(editField).uiField = uieditfield(entryPanel.Panel.ph,"text", "Position", [4,panelH-(m+1)*25,panelW*0.8,panelH/30], "Value", array2string(cfgParams.(editField)),"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen);
                end                          
                entryPanel.Panel.(editField).uiField.ValueChangedFcn = @(~,~)entryChangedFcn(nexon, obj, entryPanel, editField);          
                entryParams.(editField) = value;
            case "string"
                if size(value,1) == 1
                    entryPanel.Panel.(editField).uiField = uieditfield(entryPanel.Panel.ph,"text", "Position", [4,panelH-(m+1)*25,panelW*0.8,panelH/30], "Value", array2string(cfgParams.(editField)),"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen,"ValueChangedFcn",@(~,~)entryChangedFcn(nexon, obj, entryPanel, editField));
                    entryParams.(editField) = value;
                elseif size(value,1) > 1
                    entryPanel.Panel.(editField).uiField = uidropdown(entryPanel.Panel.ph,"Position",[4,panelH-(m+1)*25,panelW*0.8,panelH/30],"Value",value(1),"Items",value,"BackgroundColor",nexon.settings.Colors.cyberGreen,"FontColor",[0,0,0],"ValueChangedFcn",@(~,~)entryChangedFcn(nexon, obj, entryPanel, editField));
                    entryParams.(editField) = value(1);
                end
        end
        m = m+2;
    end
end