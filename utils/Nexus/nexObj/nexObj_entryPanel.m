classdef nexObj_entryPanel < handle
    properties
        Panel        
        entryParams
        UserData
    end
    
    methods
        % Constructor
        function panelObj = nexObj_entryPanel(nexon, Parent, entryParams_form, valueChangedFcn, yScaler, hScaler, forceDropDown)            
            if nargin < 7
                forceDropDown = 0;
            end
            if isempty(Parent)
                panelObj.Panel.fh = uifigure("Position",[5,5,300,400],"Color",[0,0,0]);
                panelObj.Panel.ph = uipanel(panelObj.Panel.fh,"Position",[5,5,290,390],"BackgroundColor",[0,0,0]);    
            else
                panelObj.Panel=Parent;
            end
                panelObj.entryParams = breakoutEditFields(nexon, panelObj, entryParams_form, valueChangedFcn, yScaler,hScaler, forceDropDown);
            % obj.entryParams = breakoutEditFieldsV2(nexon, obj, entryParams_form, valueChangedFcn, yScaler,hScaler);
            panelObj.UserData = struct;
        end

        function updateEntryDropDownFields(panelObj, newEntryParams)
            newEntryFields = fieldnames(newEntryParams);            
            for i = 1:length(newEntryFields)
                entryField = newEntryFields{i};
                uiField = panelObj.Panel.(entryField).uiField;
                if strcmp(class(uiField),'matlab.ui.control.DropDown')                
                    entryVals = newEntryParams.(entryField);
                    entryVals_cell = arrayfun(@(x) {char(x)}, entryVals, "UniformOutput",true);
                    uiField.Items = entryVals_cell;
                end
            end
            panelObj.entryParams=newEntryParams;
        end        
      
    end
end