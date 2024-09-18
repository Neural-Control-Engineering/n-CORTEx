classdef npxls_shank < handle
    properties
        regMap % This will hold any type of data, such as a struct
        scope        
        config
        UserData
    end
    
    methods
        % Constructor
        function obj = npxls_shank(nexon)
            obj.UserData = struct(); % Initialize as an empty struct
            obj.scope = struct();
            % configure Shank Mapping
            params = nexon.console.BASE.params;            
            regMapDir = fullfile(nexon.console.BASE.router.UserData.subjectDir,"npxls/trajectory/imec0","map_channel-region.mat");            
            load(regMapDir);
            obj.regMap = regMap;    
            % start user with one timeCourse
            dataFrame = grabDataFrame(nexon,"lfp");
            obj.scope.timeCourse1 = nexObj_npxlsTimeCourse(nexon, obj, dataFrame, "lfp");
            obj.config = struct();
            % draw config Panel
            obj.config = drawShankCfgPanel(nexon, obj);                          
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