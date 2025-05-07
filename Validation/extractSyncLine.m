function syncLine = extractSyncLine(syncData, Fs, syncFrequency, type, ref, groupSize)
    typeIds = split(type,"-");
    edgeType = typeIds(1);
    edgeMarker = typeIds(2);
    % find edges
    switch edgeType
        case "RE"
            idx_edges = find(diff(syncData) > 0);
        case "FE"
            idx_edges = find(diff(syncData) < 0);
    end
    % figure;plot(syncData(1:100000));xline(find(edges(1:100000)>0)+1);
    if strcmp(edgeMarker,"end")
        % shift indices rightward by one to locate end of falling/rising
        % edge
        idx_edges = idx_edges+1;    
    end
    t = [0:length(syncData)-1] ./Fs;
    t_edges = t(idx_edges);
    % figure;plot(t,syncData);xline(t_edges);
    syncLine.IPD = measureInterPulseDelay(t_edges,groupSize);
    syncLine.t_edges = t_edges;
    syncLine.type=type;
    syncLine.ref = ref;
    syncLine.Freq=syncFrequency;
end