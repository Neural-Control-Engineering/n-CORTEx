classdef nexObj_timeCourse < handle
    properties
        dataFrame % This will hold any type of data, such as a struct  
        dfID
        entryPanel
    end
    
    methods
        % Constructor
        function obj = nexObj_timeCourse(dataFrame, dfID)
            obj.dataFrame=struct();            
            obj.dfID = dfID;
        end

        % function updateScope(obj)
        %     obj.spgFigure.Ax.CData =obj.dataFrame(obj.UserData.chanSel,:,:);
        %     obj.spgFigure.Ax.YData=obj.f;
        %     obj.spgFigure.Ax.XData=obj.t;            
        %     drawnow;
        % end
        
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