classdef nexObj_slrtTimeCourse < handle
    properties
        classID
        dataFrame % This will hold any type of data, such as a struct  
        nexon
        dfID
        UserData
        entryPanel
        Figure
        eventAlignmentSelection
    end
    
    methods
        % Constructor
        function obj = nexObj_slrtTimeCourse(nexon, dataFrame, dfID)
            obj.classID = "tc_slrt";
            obj.nexon = nexon;
            obj.dataFrame=dataFrame;            
            obj.dfID = dfID;
            obj.UserData=struct();
            obj.UserData.colorMap = [];
            obj.UserData.Fs = 1000;
            obj.eventAlignmentSelection = nexSelect_eventAlignment(obj);
            obj = nexPlot_slrt_timeCourse(nexon, obj);
        end

        function updateScope(obj,  nexon, parent)  
            colorMap = obj.UserData.colorMap;
            try
                updateSlrtTimeCourse(obj, colorMap)
            catch e
                disp(getReport(e));
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