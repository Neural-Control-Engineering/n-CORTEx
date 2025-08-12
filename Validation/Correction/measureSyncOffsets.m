function [syncOffsets, insertOffsets] = measureSyncOffsets(t_edge, t_edge_ref, t_inserts, t_inserts_ref, refType)
    % matching pulse edge candidates
    t_edge0_ref = t_edge_ref(1);
    % t_edge2Insrt0_ref = t_inserts_ref - t_edge0_ref; 
    t_edge1_ref = t_edge_ref(2);
    % t_edge2Insrt1_ref = t_inserts_ref - t_edge1_ref;
    prevSyncOffset=[]; % vestigial code
    %% prevSyncOffset landmarking
    if isempty(prevSyncOffset) % if no previous syncOffset (this is the first trial from the assoc. trial-gate)
        t_edge0 = t_edge(1); % use first RE-time 
        % t_edge2Insrt0 = t_inserts - t_edge0;
        t_edge1 = t_edge(2);
        % t_edge2Insrt1 = t_inserts - t_edge1;
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
    % first t_edge
    syncOffset_00 = t_edge0_ref - t_edge0; % offset as RE-latency diff between World timer and MOD (peripheral recording modality)
    syncOffset_10 = t_edge1_ref - t_edge0;    
    % second t_edge
    syncOffset_01 = t_edge0_ref - t_edge1; % offset as RE-latency diff between World timer and MOD (peripheral recording modality)
    syncOffset_11 = t_edge1_ref - t_edge1;

    IPD = t_edge1_ref - t_edge0_ref;
    
    switch refType
        case "world"
            % world-ref synchronizer implies mod acquisitions start after
            % slrt acquisitions
            syncOffsets = [syncOffset_00, syncOffset_10]; 
            syncOffsets = syncOffsets(syncOffsets>0); % positive only
            [syncOffset, idx_trueOffset] = min(syncOffsets);
            t_edges_ref = t_edge_ref(idx_trueOffset:end);
            % t_edges = t_edge(1:length(t_edges_ref)); % tentative slicing rule            
            syncCutoff = min([length(t_edge),length(t_edges_ref)]);
            if length(t_edge) > length(t_edges_ref)
                t_edge = t_edge(1:syncCutoff);
            else                
                t_edges_ref = t_edges_ref(1:syncCutoff);
            end
            
            % validate insert distance
            if ~isempty(t_inserts_ref)
                insertDists_ref = t_edges_ref - t_inserts_ref;
            else
                insertDists_ref = [];
            end
            if ~isempty(t_inserts)
                insertDists = t_edge - t_inserts;
            else                
                insertDists = [];
                insertDists_ref = []; % cancel insert differential measurement
            end            
            syncOffsets = t_edges_ref - t_edge;
            insertOffsets = insertDists_ref - insertDists;
        otherwise
            % slrt-ref synchronizer implies mod-recorded slrt signals lag
            % behind slrt-recorded slrt signals
            % check for early-aliased mod edges (50% cutoff: if offset greater than 0.5, assume edge was from prior cycle)
            % if syncOffset_1/IPD >= 0.5
            %     syncOffset = syncOffset_01;
            % else
            %     syncOffset = 
            % end
            syncOffsets = [syncOffset_00, syncOffset_01];
            idx_trueOffset = min(find(syncOffsets<0)); % assuming sorted in order (ascending)            
            t_edges = t_edge(idx_trueOffset:length(t_edge_ref)); % tentative slicing rule
            t_edges_ref = t_edge_ref(1:length(t_edges));            
            syncOffsets = t_edges_ref - t_edges;
    end   

    % gt comparison (for both)
    % t_edges_ref_gt = linspace(t_edge_ref(1), t_edge_ref(end), length(t_edge_ref));
    % figure; plot(t_edges_ref_gt); hold on; plot(t_edge_ref);
    % 
    % t_edges_gt = linspace(t_edge(1), t_edge(end), length(t_edge));
    % figure; plot(t_edges_gt); hold on; plot(t_edge);
    
    % if syncOffset_1/IPD >= 0.5
    %     syncOffset = syncOffset_01;
    % else
    %     syncOffsets = [syncOffset_0, syncOffset_1];    
    %     syncOffsets = syncOffsets(syncOffsets>0); % positive only
    %     [syncOffset, idx_trueOffset] = min(syncOffsets);
    % end

    % switch refType
    %     case "world"
    %         syncOffset_0 = t_edge0_ref - t_edge0; % offset as RE-latency diff between World timer and MOD (peripheral recording modality)
    %         syncOffset_1 = t_edge1_ref - t_edge0;
    %     otherwise
    %         syncOffset_0 = t_edge0 - t_edge0_ref; % offset as RE-latency diff between MOD and SLRT (peripheral recording modality)
    %         syncOffset_1 = t_edge0 - t_edge1_ref;
    % end    
    
    
    % report syncOffsets across all edges
    % switch refType
    %     case "world"
    %         t_edges_slrt = t_edge_slrt(idx_trueOffset:end);
    %         t_edges = t_edge(1:length(t_edges_slrt)); % tentative slicing rule
    %         syncOffsets = t_edges_slrt - t_edges;
    %     otherwise
    % end    
    
end