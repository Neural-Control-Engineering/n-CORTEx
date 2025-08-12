classdef nexObj_xMarker_event < handle
    properties
        Parent % some nexObj with a defined acquisition preBufflen and sampleRate for time indexing
        xLine
        ID_event
        Listener
    end
    methods
        function nexObj = nexObj_xMarker_event(Parent, axis, Src, eventID, eventColor)
            nexObj.Parent = Parent;
            nexObj.ID_event = eventID;
            nexObj.xLine = xline(axis, 1, "Color", hex2rgb(eventColor));
            nexObj.updateXValue();
            nexObj.Listener = addlistener(Src,'trig_trialChanged','PostSet',@(~,~)nexObj.updateXValue());
        end
        function updateXValue(nexObj)
            % self-deduce (using parentObj) new xValue and reassign
            newXVal = nex_getEventTime(nexObj);
            if ~isnan(newXVal) & ~isempty(newXVal)
                nexObj.xLine.Value = newXVal;
            else
                nexObj.xLine.Value = 0;
            end
        end
    end
end