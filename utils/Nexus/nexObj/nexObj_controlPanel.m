classdef nexObj_controlPanel < handle
    properties
        nexon
        Children
        Parents
        Partners
        Figure
        averagingSelection

    end
    methods
        % CONSTRUCTOR
        function obj = nexObj_controlPanel(nexon)
            obj.nexon = nexon;
            %% Averaging Selection        
            % obj.averagingSelection = nexObj_selectionBus(obj, key, values)
            obj.averagingSelection = nexSelect_averaging(obj);
            nexFigure_controlPanel(obj);
            %% 
        end
    end
end