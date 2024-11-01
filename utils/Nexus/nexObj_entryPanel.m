classdef nexObj_entryPanel < handle
    properties
        Panel        
        entryParams
        UserData
    end
    
    methods
        % Constructor
        function obj = nexObj_entryPanel(nexon, entryParams_form, valueChangedFcn)
            obj.Panel.fh = uifigure("Position",[100,560,500,800],"Color",[0,0,0]);   
            obj.Panel.ph = uipanel(obj.Panel.fh,"Position",[5,5,490,790],"BackgroundColor",[0,0,0]);    
            obj.entryParams = breakoutEditFields(nexon, obj, entryParams_form, valueChangedFcn);
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