classdef nexObj_controlPanel < handle
    properties
        nexon
        Children
        Parents
        Partners
        Figure
        averagingSelection
    end
    properties (SetObservable)
        trig_trialChanged=0
        clock=0 % global time (sec)
    end
    methods
        % CONSTRUCTOR
        function nexObj = nexObj_controlPanel(nexon)
            nexObj.nexon = nexon;
            %% Averaging Selection        
            % obj.averagingSelection = nexObj_selectionBus(obj, key, values)
            if ~isempty(nexon.console.BASE.DTS)
                nexObj.averagingSelection = nexSelect_averaging(nexObj);                            
            end            
            nexFigure_controlPanel(nexObj);
            %% 
        end

        function appendToDTS(nexObj)
            % add more data to the datastore
            % update control Panel selection items
        end
    end
end