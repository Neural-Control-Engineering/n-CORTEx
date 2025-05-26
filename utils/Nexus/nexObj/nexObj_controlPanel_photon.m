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
        function obj = nexObj_controlPanel_photon(nexon, proxon)
            obj.nexon = nexon;
            obj.proxon = proxon;
            %% Averaging Selection        
            % obj.averagingSelection = nexObj_selectionBus(obj, key, values)            
            nexFigure_controlPanel_photon(obj);
            %% 
        end
    end
end