classdef nexObj_npxlsTimeCourse < handle
    properties
        dataFrame % This will hold any type of data, such as a struct  
        dfID
        UserData
        entryPanel
        tcFigure
    end
    
    methods
        % Constructor
        function obj = nexObj_npxlsTimeCourse(nexon, shank, dataFrame, dfID)
            obj.dataFrame=dataFrame;            
            obj.dfID = dfID;
            obj.UserData=struct();
            obj.UserData.Fs = 500;
            obj = nexPlot_npxls_timeCourse(nexon, shank, obj);
        end

        function updateScope(obj,  nexon, shank)            
            regMap = shank.regMap;
            updateTimeCourse(shank, obj, regMap)
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