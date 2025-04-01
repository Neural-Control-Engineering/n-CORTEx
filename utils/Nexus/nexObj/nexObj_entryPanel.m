classdef nexObj_entryPanel < handle
    properties
        Panel        
        entryParams
        UserData
    end
    
    methods
        % Constructor
        function obj = nexObj_entryPanel(nexon, Parent, entryParams_form, valueChangedFcn, yScaler, hScaler)            
            if isempty(Parent)
                obj.Panel.fh = uifigure("Position",[5,5,300,400],"Color",[0,0,0]);
                obj.Panel.ph = uipanel(obj.Panel.fh,"Position",[5,5,290,390],"BackgroundColor",[0,0,0]);    
            else
                obj.Panel=Parent;
            end
            obj.entryParams = breakoutEditFields(nexon, obj, entryParams_form, valueChangedFcn, yScaler,hScaler);
            obj.UserData = struct;
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