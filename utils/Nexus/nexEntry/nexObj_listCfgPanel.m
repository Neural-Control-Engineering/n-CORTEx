classdef nexObj_listCfgPanel < handle
    properties
        ph
        listPanels
        xPosPointer
        panelCount
        listbox
        UserData
    end

    methods
        % constructor
        function obj =  nexObj_listCfgPanel(nexon, panelObj, selectionBus, maxSels)
            obj.ph = panelObj.ph;
            obj.listPanels = struct;
            obj.panelCount = 1;
            obj.xPosPointer = 5;
            w_ph = panelObj.ph.Position(3);
            h_ph = panelObj.ph.Position(4);
            % for each selBus key
            % removeStrs = ["listBoxes","selIdxs"]
            keyFields = convertCharsToStrings(fieldnames(selectionBus.selKeys));
            for i=1:length(keyFields)
                key = keyFields{i};
                % listID = sprintf("%s",selectionBus.selKeys.(key));
                listID = key;
                obj.listPanels.(listID).ph = uipanel("Parent",obj.ph,"Title",listID,"BackgroundColor",[0,0,0],"Position",[obj.xPosPointer,5,w_ph-25,h_ph-10],"ForegroundColor",nexon.settings.Colors.cyberGreen);
                if isempty(maxSels)
                    maxSel = length(selectionBus.selKeys.(key));            
                else
                    maxSel = maxSels(i);
                end
                obj.listPanels.(listID).listBox = uicontrol(obj.listPanels.(listID).ph, "Style","listbox","Position",[2,2,w_ph-30,h_ph-30],"String",selectionBus.selKeys.(key),'Max',maxSel,'BackgroundColor','black',"ForegroundColor",nexon.settings.Colors.cyberGreen,'Callback',@(src,event)listCfgEntryChanged(src, event, key, selectionBus));
                selectionBus.listBoxes.(key) = obj.listPanels.(listID).listBox;
                obj.xPosPointer = obj.xPosPointer + w_ph;
            end
            % retain handle on list cfg panel (for future updates, changes)
            selectionBus.listCfgPanel = obj;
        end

        function addListCfg(obj, listDict)
        end

        function updateScope(obj)
            % use Child listCfgPanels updated options to recover new list
            % options
        end
    end    
end


% % Create the header label with white text
% headerLabel = uicontrol(f, 'Style', 'text', 'Position', [50, 160, 200, 30], ...
%     'String', 'Select Fruits', 'FontSize', 12, 'FontWeight', 'bold', ...
%     'ForegroundColor', 'white', 'BackgroundColor', 'black');
% 
% % Create the listbox with black background and white text
% listbox = uicontrol(f, 'Style', 'listbox', 'Position', [50, 50, 200, 100], ...
%     'String', {'Apple', 'Banana', 'Cherry', 'Date'}, ...
%     'Max', 3, ...               % Enable multiple selection (can select up to 3 items)
%     'Value', 1, ...
%     'BackgroundColor', 'black', ... % Set background color of listbox
%     'ForegroundColor', 'white', ... % Set text color to white
%     'Callback', @(src, event) disp(['Selected: ' strjoin(src.String(src.Value), ', ')]));