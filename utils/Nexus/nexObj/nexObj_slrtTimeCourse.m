classdef nexObj_slrtTimeCourse < handle
    properties
        classID
        dataFrame % This will hold any type of data, such as a struct  
        DF
        nexon
        dfIDs
        UserData
        entryPanel
        Figure
        eventAlignmentSelection
    end
    
    methods
        % Constructor
        function nexObj = nexObj_slrtTimeCourse(nexon, dfIDs)
            nexObj.classID = "tc_slrt";
            nexObj.nexon = nexon;
            % nexObj.dataFrame=dataFrame;            
            nexObj.dfIDs = dfIDs;
            nexObj.UserData=struct();
            nexObj.UserData.colorMap = [];
            nexObj.UserData.Fs = 1000;
            [nexObj.eventAlignmentSelection, IDs_signals] = nexSelect_eventAlignment(nexObj, dfIDs);
            nexObj.dfIDs = IDs_signals;
            IDs_events = nexObj.eventAlignmentSelection.selKeys.events;
            nexObj.DF = nexSLRT_compileDataFrames(nexObj.nexon, IDs_signals, IDs_events);
            nexObj = nexPlot_slrt_timeCourse(nexon, nexObj);
        end

        function updateScope(nexObj,  nexon, parent)  
            colorMap = nexObj.UserData.colorMap;
            try
                updateSlrtTimeCourse(nexObj, colorMap)
            catch e
                disp(getReport(e));
            end
        end
        
        % Example method to set UserData
        function setUserData(nexObj, data)
            nexObj.UserData = data;
        end
        
        % Example method to retrieve UserData
        function data = getUserData(nexObj)
            data = nexObj.UserData;
        end
    end
end