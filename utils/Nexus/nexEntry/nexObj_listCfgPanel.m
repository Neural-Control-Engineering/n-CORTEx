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
        function obj =  nexObj_listCfgPanel(nexon, panelObj, selectionBus, maxSels, extraWidth, widthScale)
            if nargin < 5 || isempty(extraWidth), extraWidth = 0; end
            if nargin < 6 || isempty(widthScale), widthScale = 1; end
            obj.ph = panelObj.ph;
            obj.listPanels = struct;
            obj.panelCount = 1;
            obj.xPosPointer = 5;
            h_ph = panelObj.ph.Position(4);
            d_inner_listBox = 25; % subtractor
            % for each selBus key
            % removeStrs = ["listBoxes","selIdxs"]
            keyFields = convertCharsToStrings(fieldnames(selectionBus.selKeys));
            % Per-listbox slot width, scaled to THIS panel's own key count
            % (panelWidth/(nKeys+0.3) — the "+0.3" is the same headroom
            % ratio the original divisor used for exactly 2 keys). Each
            % selectionBus panel (Collector/Domain/Pointer/...) is sized
            % by its OWN caller to comfortably fit its OWN key count —
            % overflow, when a panel is deliberately narrower than its
            % content needs to be, is handled one level up by that
            % panel's own PARENT (a Scrollable="on" container the caller
            % builds around it), not by shrinking listboxes here.
            %
            % Floored at MIN_SLOT_WIDTH: some buses have a key count the
            % caller never sized its panel for at all (e.g. the control
            % panel's averagingSelection — subj/phase/date/site plus one
            % key per signal-tag type found in the DTS, easily 6-10+,
            % against a fixed 255px panel) — the unfloored formula drove
            % w_ph below d_inner_listBox there, producing a negative
            % uicontrol width and crashing startNexus outright. Flooring
            % instead lets those extra keys overflow horizontally (same
            % "parent's own Scrollable container" fallback as above)
            % rather than shrinking every listbox to nothing.
            % MIN_SLOT_WIDTH raised 80->100 (user-requested global bump —
            % the listbox-bus regression this session traced through
            % nexObj_listCfgPanel/nex_buildCollectorViewPanel's related
            % floor/formula drift). extraWidth/widthScale are optional,
            % per-caller overrides for a bus that's "close but still a bit
            % cramped" even above the floor (e.g. mdlObj's Domain/Pointer
            % panels: +10px flat; controlPanel's averagingSelection: +25%
            % scale) — applied AFTER the floor so they always have their
            % stated effect regardless of whether the floor would
            % otherwise have dominated. Default extraWidth=0, widthScale=1
            % is a no-op for every pre-existing caller.
            MIN_SLOT_WIDTH = 100;
            w_ph = max(panelObj.ph.Position(3) / (max(length(keyFields), 1) + 0.3), MIN_SLOT_WIDTH) ...
                   * widthScale + extraWidth;
            for i=1:length(keyFields)
                key = keyFields{i};
                % listID = sprintf("%s",selectionBus.selKeys.(key));
                listID = key;
                obj.listPanels.(listID).ph = uipanel("Parent",obj.ph,"Title",listID,"BackgroundColor",[0,0,0],"Position",[obj.xPosPointer,5,w_ph-d_inner_listBox,h_ph-10],"ForegroundColor",nexon.settings.Colors.cyberGreen);
                if isempty(maxSels)
                    maxSel = length(selectionBus.selKeys.(key));            
                else
                    maxSel = maxSels(i);
                end
                % Seed the listbox's initial Value from the bus's own
                % current selection instead of leaving it at uicontrol's
                % implicit default of 1 — this class rebuilds its widgets
                % from scratch on every call (e.g. nexObj_bar's
                % rebuildPointerPanel on every SRC switch), and without
                % this the fresh widget always shows "item 1 highlighted"
                % regardless of what selectionBus.selections actually
                % holds, desyncing the visible selection from the one
                % actually driving the plot. No-op for a genuinely fresh
                % bus (buildSelection also defaults selections.(key) to 1),
                % so this only changes behavior for a rebuild where the
                % selection has since moved.
                initSel = 1;
                try
                    sel = selectionBus.selections.(key);
                    sel = sel(sel >= 1 & sel <= numel(selectionBus.selKeys.(key)));
                    if ~isempty(sel), initSel = sel; end
                catch
                end
                obj.listPanels.(listID).listBox = uicontrol(obj.listPanels.(listID).ph, "Style","listbox","Position",[2,2,w_ph-30,h_ph-30],"String",selectionBus.selKeys.(key),'Max',maxSel,'Value',initSel,'BackgroundColor','black',"ForegroundColor",nexon.settings.Colors.cyberGreen,'Callback',@(src,event)listCfgEntryChanged(src, event, key, selectionBus));
                selectionBus.listBoxes.(key) = obj.listPanels.(listID).listBox;
                obj.xPosPointer = obj.xPosPointer + w_ph - d_inner_listBox;
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