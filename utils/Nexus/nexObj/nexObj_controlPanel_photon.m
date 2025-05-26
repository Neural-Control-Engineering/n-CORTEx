classdef nexObj_controlPanel_photon < handle
    properties
        nexon
        nCORTEx
        proxon
        Children
        Parents
        Partners
        Figure
        averagingSelection

    end
    methods
        % CONSTRUCTOR
        function obj = nexObj_controlPanel_photon(nexon, proxon, nCORTEx)
            obj.nexon = nexon;            
            obj.proxon = proxon;
            obj.nCORTEx = nCORTEx;
            %% Averaging Selection        
            % obj.averagingSelection = nexObj_selectionBus(obj, key, values)            
            nexFigure_controlPanel_photon(obj);
            %% 
        end
    end
end