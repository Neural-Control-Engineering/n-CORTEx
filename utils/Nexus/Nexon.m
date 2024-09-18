classdef Nexon < handle
    properties
        console % This will hold any type of data, such as a struct
        UserData
        settings
    end
    
    methods
        % Constructor
        function obj = Nexon(nexon)
            obj.console=struct();
            obj.UserData = struct(); % Initialize as an empty struct      
            settings=struct();
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