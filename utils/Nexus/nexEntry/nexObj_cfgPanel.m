classdef nexObj_cfgPanel < handle
    properties
        ph        
        editFields
        UserData
    end
    
    methods
        % Constructor
        function nexPanelObj = nexObj_cfgPanel(nexon, nexObjParent, panelObj, entryParams, entryChangedFcn, entryChangedFcnArgs)            
            % if nargin <7
            %     scrollable=0                
            % end
            nexPanelObj.ph = panelObj.ph;
            nexPanelObj.editFields=struct;
            nexPanelObj.UserData=struct;
            breakoutCfgFieldsV2(nexon, nexObjParent, nexPanelObj, entryParams, entryChangedFcn, entryChangedFcnArgs);
            nexPanelObj.UserData = struct;
        end             
    end
end