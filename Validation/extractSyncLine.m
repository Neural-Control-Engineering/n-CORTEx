function syncLine = extractSyncLine(syncData, insertData, Fs, syncFrequency, type, ref, groupSize, t_seg, t_advance)
    typeIds = split(type,"-");
    edgeType = typeIds(1);
    edgeMarker = typeIds(2);
    % find edges
    switch edgeType
        case "RE"
            idx_edges = find(diff(syncData) > 0);
            if ~isempty(insertData)
                idx_insert = find(diff(insertData) >= 1);
            else
                idx_insert = [];
            end
        case "FE"
            idx_edges = find(diff(syncData) < 0);
            if ~isempty(insertData)
                idx_insert = find(diff(insertData) <= -1);
            else
                idx_insert = [];
            end
    end
    % figure;plot(syncData(1:100000));xline(find(edges(1:100000)>0)+1);
    if strcmp(edgeMarker,"end")
        % shift indices rightward by one to locate end of falling/rising
        % edge
        idx_edges = idx_edges+1;    
    end
    t = [0:length(syncData)-1] ./Fs;
    t_edges = t(idx_edges);
    if ~isempty(idx_insert)
        t_insert = t(idx_insert);
    else
        t_insert = [];
    end
    % figure;plot(t,syncData);xline(t_edges);
    t_edges = filterSyncEdges(t_edges,1/syncFrequency);
    syncLine.IPD = measureInterPulseDelay(t_edges,groupSize);
    % syncLine.t_edges = t_edges;
    syncLine.t_edges = t_edges + t_seg + t_advance;
    syncLine.t_insert = t_insert;
    syncLine.type=type;
    syncLine.ref = ref;
    syncLine.Freq=syncFrequency;
end
% sync_1Hz_ext
% cont_pulseGen1Hz