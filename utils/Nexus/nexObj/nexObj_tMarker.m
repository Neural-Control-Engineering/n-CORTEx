classdef nexObj_tMarker < handle
    properties
        Parent
        graphic
        updateFcn
        t_offset=0
        Listener
    end
    
    methods

        function nexObj = nexObj_tMarker(Parent, graphic, Src, t_offset)
            nexObj.Parent = Parent;
            nexObj.graphic = graphic;
            nexObj.t_offset = t_offset;
            nexObj.Listener = addlistener(Src,'clock','PostSet',@(~,event)nexObj.updateValue(event));
        end

        function updateValue(nexObj, event)
            % use update Fcn and clock time to update marker value
            % t_clock = nexObj.Parent.nexon.console.BASE.controlPanel.clock + nexObj.t_offset;
            t_clock = event.AffectedObject.clock - nexObj.t_offset;
            nexObj.graphic.Value = nexObj.Parent.getVal_tMarker(t_clock);
            drawnow limitrate nocallbacks
            % nexObj.graphic.Value = nexObj.updateFcn(nexObj.Parent, t_clock);
            % nexObj.graphic.Value = nexUpdate_time2markerValue_emb(Parent, t_clock);
        end
    end
end