function time_event = nex_getEventTime(nexObj)
    % xLine marker obj uses parent and router to get index and then 
    % compute time of designated event
    preBuffLen = nexObj.Parent.preBuffLen;
    Fs_slrt = nexObj.Parent.nexon.console.SLRT.signals.Fs;
    eventID = nexObj.ID_event;
    idx_event = grabDataFrame(nexObj.Parent.nexon,eventID,[]);
    % time calculation (special case for event-aligned signals)
    parentType = class(nexObj.Parent);
    switch parentType
        case "nexObj_slrtTimeCourse"
            % use ID of plotted signal to calculate event-times
            signalID = nexObj.xLine.Parent.YLabel.String;
            alignmentID = split(signalID,"_"); alignmentID = alignmentID{1};
            idx_alignedEvent = grabDataFrame(nexObj.Parent.nexon,alignmentID,[]);
            idx_event = preBuffLen*Fs_slrt + (idx_event - idx_alignedEvent);        
    end
    time_event = idx_event ./ Fs_slrt - preBuffLen;       
    
end