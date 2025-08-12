classdef nexObj_windowKeyListener < handle
    properties
        Figure            % Handle to the figure
        isCtrlPressed = false  % State of Ctrl key (default: not pressed)
    end
    
    methods
        function obj = nexObj_windowKeyListener(fh)
            % Constructor: Attach key event listeners to the figure
            obj.Figure = fh;
            obj.Figure.WindowKeyPressFcn = @(src, event) obj.ctrlKeyDown(event);
            obj.Figure.WindowKeyReleaseFcn = @(src, event) obj.ctrlKeyUp(event);
        end
        
        function ctrlKeyDown(obj, event)
            % Detect when Ctrl key is pressed
            if strcmp(event.Key, 'control')
                obj.isCtrlPressed = true;
            end
        end
        
        function ctrlKeyUp(obj, event)
            % Detect when Ctrl key is released
            if strcmp(event.Key, 'control')
                obj.isCtrlPressed = false;
            end
        end
        
        function state = isCtrlHeld(obj)
            % Returns whether Ctrl key is currently held down
            state = obj.isCtrlPressed;
        end
    end
end
