function locateSyncOffsetPointer(t_edge, t_edge_ref, prevSyncOffset, refType)
    t_edge0_ref = t_edge_ref(1);
    t_edge1_ref = t_edge_ref(2);
    %% prevSyncOffset landmarking
    if isempty(prevSyncOffset) % if no previous syncOffset (this is the first trial from the assoc. trial-gate)
        t_edge0 = t_edge(1); % use first RE-time 
    else % locate matching RE-latency idx using previously discovered syncOffset (important for multiple trials in one trial-gate)
        projected_firstEdge = t_edge0_ref - prevSyncOffset;
        % locate corresponding RE in pMOD data (peripheral modality) 
        t_RE_diff = t_edge - projected_firstEdge;
        [minVal, idx_min] = min(abs(t_RE_diff));
        % store located corresponding RE
        t_edge0 = t_edge(idx_min); % search t_RE closest to projected (given known previous offset -> local sampling drift tracking/correction
    end            
    % use >/< rule (verify first slrt RE time is longer than mod,
    % assuming slrt->pMod delay is less than the sync period)
    switch refType
        case "world"
            syncOffset_0 = t_edge0_ref - t_edge0; % offset as RE-latency diff between World timer and MOD (peripheral recording modality)
            syncOffset_1 = t_edge1_ref - t_edge0;
        otherwise
            syncOffset_0 = t_edge0 - t_edge0_ref; % offset as RE-latency diff between MOD and SLRT (peripheral recording modality)
            syncOffset_1 = t_edge1 - t_edge0_ref;
    end    
    syncOffsets = [syncOffset_0, syncOffset_1];    
    syncOffsets = syncOffsets(syncOffsets>0); % positive only
    [syncOffset, idx_trueOffset] = min(syncOffsets);
    % report syncOffsets across all edges
    switch refType
        case "world"
            t_edges_slrt = t_edge_slrt(idx_trueOffset:end);
            t_edges = t_edge(1:length(t_edges_slrt)); % tentative slicing rule
            syncOffsets = t_edges_slrt - t_edges;
        otherwise
    end
    
    disp(syncOffset);
end