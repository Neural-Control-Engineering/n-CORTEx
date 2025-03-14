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
        function obj =  nexObj_listCfgPanel(panelObj, listDict)
            obj.ph = panelObj.ph;
            obj.listPanels = struct;
            obj.panelCount = 1;
            obj.xPosPointer = 5;
            w_ph = panelObj.ph.Position(3);
            h_ph = panelObj.ph.Position(4);
            listID = sprintf("list_%s",listDict.key);
            obj.listPanels.(listID) = uipanel("Title",listDict.key,"BackgroundColor",[0,0,0],"Position",[xPosPointer,5,w_ph-10,h_ph-10]);
            obj.listbox = uicontrol(obj.listPanels.(listID)., "Style","listbox","Position",)
        end

        function addListCfg(obj, listDict)
        end
    end    
end


% Create the header label with white text
headerLabel = uicontrol(f, 'Style', 'text', 'Position', [50, 160, 200, 30], ...
    'String', 'Select Fruits', 'FontSize', 12, 'FontWeight', 'bold', ...
    'ForegroundColor', 'white', 'BackgroundColor', 'black');

% Create the listbox with black background and white text
listbox = uicontrol(f, 'Style', 'listbox', 'Position', [50, 50, 200, 100], ...
    'String', {'Apple', 'Banana', 'Cherry', 'Date'}, ...
    'Max', 3, ...               % Enable multiple selection (can select up to 3 items)
    'Value', 1, ...
    'BackgroundColor', 'black', ... % Set background color of listbox
    'ForegroundColor', 'white', ... % Set text color to white
    'Callback', @(src, event) disp(['Selected: ' strjoin(src.String(src.Value), ', ')]));