classdef nexPanel_BASE < handle
    properties
        nexon
        router 
        controlPanel
        DTS
        params
        UserData
        nexObjs
    end
    
    methods
        % Constructor
        function obj = nexPanel_BASE(nexon,DTS, params)
            obj.DTS=DTS;
            obj.UserData = struct();
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
    end
end