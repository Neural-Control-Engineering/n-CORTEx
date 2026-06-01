classdef nexObj_selectionBus < handle 
    properties
        classID
        Parent
        Children
        listBoxes
        selections
        selKeys
        listCfgPanel
        Listeners=struct;
    end
    methods
        % Constructor
        function obj = nexObj_selectionBus(Parent, key, values, initSel)
             % Optional argument
            if nargin < 4
                initSel = 1;            
            end
            obj.classID="sbus";
            if ~isempty(Parent)
                obj.Parent = Parent;
            end
            obj.listBoxes = struct;
            obj.selections = struct;
            if nargin > 0 % Ensure input argument is provided
                obj.addKey(key, values);
            end
            obj.selections.(key) = initSel; % initialize selection
        end

        % Method to dynamically add a property
        function addKey(obj, key, values, initSel)
            if nargin < 4
                initSel = 1;            
            end
            propName = key;
            propValue = values;
            obj.selKeys.(propName) = propValue;
            obj.selections.(key) = initSel;
        end

        function updateScope(obj, selectionID, selectionVal)
            % update associated listCfg panel settings given new
            % environment
            % update keys and values
            % obj.listBoxes.();
            % obj.selections.();
            % obj.selections;
            %% to be updated and revised...
            % use selectionVal to list items
            selectionVal = convertCharsToStrings(split(selectionVal,"--")); selectionVal = selectionVal(end);
            if ~strcmp(selectionVal,"None")
                selItems = nexOp_enumerateCategory(obj.Parent,selectionVal);
            else
                selItems = "";
            end
            % update selection (listboxes, entries, etc)
            obj.selections.(selectionID) = 1; % reset selection index
            obj.selKeys.(selectionID) = selItems;
            % obj.listBoxes.(selectionID).String=convertStringsToChars(selItems);
            obj.listBoxes.(selectionID).Value=1; % reset selection index
            obj.listBoxes.(selectionID).String=convertCharsToStrings(selItems);
            obj.listBoxes.(selectionID).Max=length(selItems);
        end
    end
end
