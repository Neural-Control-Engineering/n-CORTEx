classdef nexPanel_BASE < handle
    properties
        router % This will hold any type of data, such as a struct
        DTS
        params
        UserData
    end
    
    methods
        % Constructor
        function obj = nexPanel_BASE(nexon,DTS, params)
            obj.DTS=DTS;
            obj.router = setupRouter(nexon, DTS);
            obj.params = params; % Initialize as an empty struct                  
            obj.UserData = struct();
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