function panel = breakoutEntryFields(panel, rtStream, entryObj)
    entryFields = fieldnames(entryObj);
    panelSize = panel.ph.Position;
    panelW = panelSize(3);
    panelH = panelSize(4);
    m=1;
    % newEntryFcn = str2func("writeNewEntryFieldCallback");
    for i=1:length(entryFields)
        editField = entryFields{i};
        value = entryObj.(editField);
        panel.(editField).Label = uitextarea(panel.ph,"Value",sprintf("%s",editField), "Position", [4,panelH-(m)*25,panelW*0.95,panelH/30], "BackgroundColor",[0,0,0],"FontColor",[0.24,0.96,0.46]);
        switch class(value)
            case "double"                                   
                if size(value,2) == 1                    
                    % panel.(editField).uiField = uieditfield(panel.ph, "numeric", "Position", [4,panelH-(m+1)*25,panelW*0.8,panelH/30], "Value", entryObj.(editField), "ValueChangedFcn", newEntryFcn(panel, rtStream, editField));        
                    panel.(editField).uiField = uieditfield(panel.ph, "numeric", "Position", [4,panelH-(m+1)*25,panelW*0.8,panelH/30], "Value", entryObj.(editField),"BackgroundColor",[0,0,0],"FontColor",[0.24,0.96,0.46]);        
                elseif size(value,2) > 1
                    % panel.(editField).uiField = uieditfield(panel.ph,"text", "Position", [4,panelH-(m+1)*25,panelW*0.8,panelH/30], "Value", array2string(entryObj.(editField)), "ValueChangedFcn", newEntryFcn(panel, rtStream, editField));
                    panel.(editField).uiField = uieditfield(panel.ph,"text", "Position", [4,panelH-(m+1)*25,panelW*0.8,panelH/30], "Value", array2string(entryObj.(editField)),"BackgroundColor",[0,0,0],"FontColor",[0.24,0.96,0.46]);
                end            
                panel.(editField).uiField.ValueChangedFcn = @(src,event)writeNewEntryFieldCallback(panel, rtStream, editField);
        end
        m = m+2;
    end
end