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
            % Update control Panel selection items to reflect newly added
            % trials. Called from Nexon.appendToDTS alongside the router
            % refresh so the averaging bus tracks new subjects/phases/dates/
            % signal tags as they stream in during online/in-memory capture.
            if isempty(nexObj.averagingSelection), return; end
            nexRefresh_averaging(nexObj);
        end
    end
end