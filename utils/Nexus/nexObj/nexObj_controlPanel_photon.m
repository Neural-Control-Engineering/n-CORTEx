classdef nexObj_controlPanel_photon < handle
    properties
        nexon
        proxon
        Children
        Parents
        Partners
        Figure
        averagingSelection

    end
    methods
        % CONSTRUCTOR
        function obj = nexObj_controlPanel(nexon, proxon)
            obj.nexon = nexon;
            %% Averaging Selection        
            % obj.averagingSelection = nexObj_selectionBus(obj, key, values)            
            nexFigure_controlPanel(obj);
            %% 
        end
    end
end