classdef nexObj_eventMarker < handle
    properties
        Parent % some nexObj with a defined acquisition preBufflen and sampleRate for time indexing
        graphic
        ID_event
        Listener
    end
    methods
        function nexObj = nexObj_eventMarker(Parent, axis, Src, eventID, eventColor, graphic)
            nexObj.Parent = Parent;
            nexObj.ID_event = eventID;
            % nexObj.gphObj = xline(axis, 1, "Color", hex2rgb(eventColor));
            nexObj.graphic = graphic;
            nexObj.updateValue();
            nexObj.Listener = addlistener(Src,'trig_trialChanged','PostSet',@(~,~)nexObj.updateValue());
        end
        function updateValue(nexObj)
            % self-deduce (using parentObj) new marker Value and reassign
            newXVal = nex_getEventTime(nexObj);
            if ~isnan(newXVal) & ~isempty(newXVal)
                nexObj.graphic.Value = newXVal;
            else
                nexObj.graphic.Value = 0;
            end
        end
    end
end