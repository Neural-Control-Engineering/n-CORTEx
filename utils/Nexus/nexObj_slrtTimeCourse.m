classdef nexObj_slrtTimeCourse < handle
    properties
        dataFrame % This will hold any type of data, such as a struct  
        dfID
        UserData
        entryPanel
        tcFigure
    end
    
    methods
        % Constructor
        function obj = nexObj_slrtTimeCourse(nexon, dataFrame, dfID)
            obj.dataFrame=dataFrame;            
            obj.dfID = dfID;
            obj.UserData=struct();
            obj.UserData.colorMap = [];
            obj.UserData.Fs = 1000;
            obj = nexPlot_slrt_timeCourse(nexon, obj);
        end

        function updateScope(obj,  nexon, parent)  
            colorMap = obj.UserData.colorMap;
            updateSlrtTimeCourse(obj, colorMap)
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