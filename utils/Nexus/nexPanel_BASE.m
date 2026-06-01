classdef nexPanel_BASE < handle
    properties
        nexon
        router 
        registry
        controlPanel
        DTS
        map_phase
        params
        UserData
        nexObjs
    end
    
    methods
        % Constructor
        function obj = nexPanel_BASE(nexon,DTS, params)
            obj.DTS=DTS;
            obj.UserData = struct();
            if ~isempty(DTS)
                list_phases = parseSessionLabelUnique(DTS.sessionLabel,"phase");
                obj.map_phase =  nexGenerate_phaseMap(list_phases);
            end
            obj.nexon = nexon;
            % obj.controlPanel = nexObj_controlPanel(nexon);
            % obj.router = setupRouter(obj, nexon, DTS);
            obj.params = params; % Initialize as an empty struct                              
        end
        
        % Example method to set UserData
        function setUserData(obj, data)
            obj.UserData = data;
        end
        
        % Example method to retrieve UserData
        function data = getUserData(obj)
            data = obj.UserData;
        end

        function updateControlPanel(obj)
            % update nexus control panel to reflect current DTS
            if isempty(controlPanel)
                % initiate if doesnt exist
            end
            % update controlPanel selections
            
        end
    end
end