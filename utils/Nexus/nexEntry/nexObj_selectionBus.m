classdef nexObj_selectionBus < handle
    properties
        classID
        Parent
        Children
        listBoxes
        selKeys
        listCfgPanel
        Listeners=struct;
    end
    properties (SetObservable)
        selections
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
            % Enumerate items for the given category slot and update listbox.
            % Dispatches to enumerateItemsFor if the parent implements it
            % (e.g. nexObj_categorical, SRC-aware), otherwise falls back to
            % the global nexOp_enumerateCategory (DTS registry + DF_postOp.ax).
            if ~strcmp(selectionVal,"None")
                if ismethod(obj.Parent, "enumerateItemsFor")
                    selItems = obj.Parent.enumerateItemsFor(selectionVal);
                else
                    selectionVal = convertCharsToStrings(split(selectionVal,"--")); selectionVal = selectionVal(end);
                    selItems = nexOp_enumerateCategory(obj.Parent, selectionVal);
                end
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
