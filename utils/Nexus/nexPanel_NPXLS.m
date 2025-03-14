classdef nexPanel_NPXLS < handle
    properties
        shanks % This will hold any type of data, such as a struct        
        config        
    end
    
    methods
        % Constructor
        function obj = nexPanel_NPXLS(nexon, numShanks)
            obj.shanks=struct();            
            obj.config = struct(); % Initialize as an empty struct                  
            for i = 1:numShanks
                obj.shanks.(sprintf("shank%d",i)) = npxls_shank(nexon);
            end
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