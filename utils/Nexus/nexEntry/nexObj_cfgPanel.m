classdef nexObj_cfgPanel < handle
    properties
        ph        
        editFields
        UserData
    end
    
    methods
        % Constructor
        function nexPanelObj = nexObj_cfgPanel(nexon, nexObjParent, panelObj, entryParams, entryChangedFcn, entryChangedFcnArgs)            
            nexPanelObj.ph = panelObj.ph;
            breakoutCfgFieldsV2(nexon, nexObjParent, nexPanelObj, entryParams, entryChangedFcn, entryChangedFcnArgs);
            nexPanelObj.UserData = struct;
        end             
    end
end