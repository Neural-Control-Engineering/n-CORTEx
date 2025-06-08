classdef nexObj_cfgPanel_spinner < handle
    properties
        ph        
        editFields
        UserData
    end
    
    methods
        % Constructor
        function nexPanelObj = nexObj_cfgPanel_spinner(nexon, nexObjParent, panelObj, entryParams, entryChangedFcn, entryChangedFcnArgs)            
            nexPanelObj.ph = panelObj.ph;
            nexPanelObj.editFields=struct;
            nexPanelObj.UserData=struct;
            breakoutCfgFields_spinner(nexon, nexObjParent, nexPanelObj, entryParams, entryChangedFcn, entryChangedFcnArgs);
            nexPanelObj.UserData = struct;
        end             
    end
end