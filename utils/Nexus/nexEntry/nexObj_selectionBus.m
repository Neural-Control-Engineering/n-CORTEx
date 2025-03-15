classdef nexObj_selectionBus < handle
    properties
        Parent
        listBoxes
        selections
        selKeys
    end
    methods
        % Constructor
        function obj = nexObj_selectionBus(Parent, key, values)
            if ~isempty(Parent)
                obj.Parent = Parent;
            end
            obj.listBoxes = struct;
            obj.selections = struct;
            if nargin > 0 % Ensure input argument is provided
                obj.addKey(key, values);
            end
        end

        % Method to dynamically add a property
        function addKey(obj, key, values)
            propName = key;
            propValue = values;
            obj.selKeys.(propName) = propValue;
        end
    end
end
