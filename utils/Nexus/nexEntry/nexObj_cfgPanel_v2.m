classdef nexObj_cfgPanel_v2 < handle
    properties
        ph        
        editFields
        UserData
    end
    
    methods
        % Constructor
        function nexPanelObj = nexObj_cfgPanel_v2(nexObj, cfgObj, panelObj, entryParams, entryChangedFcn, entryChangedFcnArgs)            
            nexPanelObj.ph = panelObj.ph;
            nexPanelObj.editFields=struct;
            nexPanelObj.UserData=struct;
            breakoutCfgFields_v4(nexObj, cfgObj, nexPanelObj, entryParams, entryChangedFcn, entryChangedFcnArgs);
            nexPanelObj.UserData = struct;
        end             
    end
end