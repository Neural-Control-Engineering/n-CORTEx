classdef nexObj_axisPanel < handle
    properties
        Parent        
        ph
        editFields
        UserData
    end
    methods
        function nexPanel = nexObj_axisPanel(nexObj, axPtr, panel)
            % read dimensions of nexObj.DF to dynamically create
            % spinner axes to sweep through DF dims and re-plot 
            nexPanel.ph = panel.ph;
            nexPanel.editFields=struct;
            nexPanel.UserData=struct;
            % axPtr = nexObj.DF_pos
            breakoutAxisFields(nexObj, nexPanel, axPtr);
            nexPanel.UserData = struct;
        end
    end
end

% classdef nexObj_cfgPanel_spinner < handle
%     properties
%         ph        
%         editFields
%         UserData
%     end
% 
%     methods
%         % Constructor
%         function nexPanelObj = nexObj_cfgPanel_spinner(nexon, nexObjParent, panelObj, entryParams, entryChangedFcn, entryChangedFcnArgs)            
%             nexPanelObj.ph = panelObj.ph;
%             nexPanelObj.editFields=struct;
%             nexPanelObj.UserData=struct;
%             breakoutCfgFields_spinner(nexon, nexObjParent, nexPanelObj, entryParams, entryChangedFcn, entryChangedFcnArgs);
%             nexPanelObj.UserData = struct;
%         end             
%     end
% end