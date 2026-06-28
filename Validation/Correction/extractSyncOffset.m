function sync = extractSyncOffset(syncLine_ref, sync, t_start)
    % find world-time alignment and extract offsets at each edge-point
    % landmark type I: rising edge (start)
    % landmark type II: rising edge (end)
    % landmark type III: falling edge (start)
    % landmark type IV: falling edge (end)

    % extract target acquisition delay (relative to SLRT)
    syncLineNames = fieldnames(sync.lines);
    syncLineFreqs = cellfun(@(x) split(x,"_"), syncLineNames, "UniformOutput",false);
    syncLineFreqs = cellfun(@(x) str2double(strrep(x{2},"Hz","")), syncLineFreqs, "UniformOutput",false);
    syncLineFreqs = cell2mat(syncLineFreqs);
    [syncLineFreqs_sorted, sortIdx] = sort(syncLineFreqs);
    % iterate through syncLines, inferring rising-edge offsets, sorted from slowest to fastest
    % syncOffset_line = [];
    syncOffsets = [];
    for i = 1:length(syncLineNames)
        idx = sortIdx(i);
        % freqTitle = sprintf("%dHz",syncLineFreqs(idx));
        syncLineName = syncLineNames{idx};
        syncLine = sync.lines.(syncLineName);
        t_edge = syncLine.t_edges; % pMod sync line
        % colNames_slrt = convertCharsToStrings(row_SLRT.Properties.VariableNames);
        % t_edge_refCol = contains(colNames_slrt,"t-syncEdges") & contains(colNames_slrt,freqTitle);
        % t_edge_ref = row_SLRT.(colNames_slrt(t_edge_refCol==1)){1}; % slrt sync line
        t_edge_ref = syncLine_ref.t_edges;
        t_inserts = syncLine.t_insert; % temporal insert at acquisition to ensure rising edge alignment
        t_inserts_ref = syncLine_ref.t_insert;

        % cutoff to point within 1 sec deviation (for scheme A)
        eof = min([length(t_edge),length(t_edge_ref)]);
        % t_edge_deviation = t_edge(1) - t_edge_ref(1:eof);
        t_edge_deviation = t_edge_ref(1) - t_edge(1:eof);
        t_edge_deviation_mag = abs(t_edge_deviation);
        % idx_min_deviation = find(round(t_edge_deviation,4)==round(min(abs((t_edge_deviation))),4));
        % idx_min_deviation = find((min(((t_edge_deviation)))));
        % FIX #6: use min's index output. find(==min) can return MULTIPLE indices
        % on ties, which would make t_edge(idx:end) misbehave; [~,idx]=min picks
        % the first minimum deterministically.
        [~, idx_min_deviation] = min(t_edge_deviation_mag);
        t_edge = t_edge(idx_min_deviation:end);

        % to achieve full sync-precision:
        % cascade offset correction from previous, slower pulses (update each t_RE to reflect
        % offset from slower sync line - this is a recurrent process as we
        % iterate to faster sync lines)
        % if ~isempty(syncOffsets) % assuming previous, slowest, initial syncLine has been visited
        %     % recurse ...
        %     [syncOffsets_next, insertOffsets_next] = measureSyncOffsets(t_edge,t_edge_ref,t_inserts,t_inserts_ref,syncLine.ref);
        %     sync.lines.(syncLineName).syncOffsets = syncOffsets_next;
        %     sync.lines.(syncLineName).insertOffsets = insertOffsets_next;
        %     sync.lines.(syncLineName).t_edges_ref = t_edge_ref;
        %     slope_offsets = (syncOffsets_next(end)-syncOffsets_next(1))/(t_edge_ref(end) - t_edge_ref(1));
        %     offset0 = slope_offsets * (-t_start) + syncOffsets(1);
        %     if strcmp(syncLine.ref,"world")
        %         sync.lines.(syncLineName).offset0=offset0;
        %     end
        %     % figure; plot(t_edge_ref(1:length(t_edge_ref)-1),syncOffsets_next);
        %     % t_RE = t_RE + syncOffset; % new-corrected t_RE (from previous, slower line)
        %     % t_edge0_slrt = t_edge_ref(1); 
        %     % t_edge1_slrt = t_edge_ref(2);
        %     % % slowerSyncOffset landmarking            
        %     % projected_firstRE_prevLine = t_edge0_slrt - syncOffset;
        %     % t_edge_diff_prevLine = t_edge - projected_firstRE_prevLine;
        %     % [minVal, idx_min] = min(abs(t_edge_diff_prevLine));
        %     % % store
        %     % t_RE0_prevLine = t_edge(idx_min);
        %     % % implement internal/external rule here for subtracting/adding
        %     % % offset...
        %     % 
        %     % %% prevSyncOffset landmarking
        %     % if isempty(prevSyncOffset)
        %     %     t_edge0 = t_edge(1); % here
        %     % else
        %     %     % faster line landmarking
        %     %     projected_firstEdge = t_edge0_slrt - prevSyncOffset;
        %     %     % locate closest RE (to projection based on prev offset)
        %     %     t_RE_diff = t_edge - projected_firstEdge;
        %     %     [minVal, idx_min] = min(abs(t_RE_diff));
        %     %     % store
        %     %     t_edge0 = t_edge(idx_min);
        %     % end            
        %     % % t_RE_diff = t_RE_slrt - t_RE0;            
        %     % % [syncOffset_line, idx_min] = min(abs(t_RE_diff)); % locate projected t_RE, update syncOffset_line from next, faster line
        %     % 
        %     % syncOffset_0 = t_edge0_slrt - t_edge0; % offset as RE-latency diff between SLRT and MOD (peripheral recording modality)
        %     % syncOffset_1 = t_edge1_slrt - t_edge0;
        %     % syncOffsets = [syncOffset_0, syncOffset_1];
        %     % syncOffsets = syncOffsets(syncOffsets>0); % positive only
        %     % syncOffset_line = min(syncOffsets);
        %     % % syncOffset_line = min(abs([syncOffset_0, syncOffset_1])); % smallest difference thats not negative
        %     % syncOffset = syncOffset + syncOffset_line; % offset convergently accumulated across all lines
        %     % disp(syncOffset);
        % else % still on first, slowest line, self-locate (using prevSyncOffset, if available) and compute first itr. of next syncOffset
        %     % first (two) RE offsets
        [syncOffsets, insertOffsets] = measureSyncOffsets(t_edge,t_edge_ref,t_inserts,t_inserts_ref,syncLine.ref);
        sync.lines.(syncLineName).syncOffsets=syncOffsets;
        sync.lines.(syncLineName).insertOffsets=insertOffsets;
        sync.lines.(syncLineName).t_edges_ref=t_edge_ref;
        % extrapolate (backwards)
        slope_offsets = (syncOffsets(end)-syncOffsets(1))/(t_edge_ref(end) - t_edge_ref(1));
        offset0 = slope_offsets * (-t_start) + syncOffsets(1);
        if strcmp(syncLine.ref,"world")
            sync.lines.(syncLineName).offset0=offset0;
        end
            % t_edge0_slrt = t_edge_slrt(1);
            % t_edge1_slrt = t_edge_slrt(2);
            % %% prevSyncOffset landmarking
            % if isempty(prevSyncOffset) % if no previous syncOffset (this is the first trial from the assoc. trial-gate)
            %     t_edge0 = t_edge(1); % use first RE-time 
            % else % locate matching RE-latency idx using previously discovered syncOffset (important for multiple trials in one trial-gate)
            %     projected_firstEdge = t_edge0_slrt - prevSyncOffset;
            %     % locate corresponding RE in pMOD data (peripheral modality) 
            %     t_RE_diff = t_edge - projected_firstEdge;
            %     [minVal, idx_min] = min(abs(t_RE_diff));
            %     % store located corresponding RE
            %     t_edge0 = t_edge(idx_min); % search t_RE closest to projected (given known previous offset -> local sampling drift tracking/correction
            % end            
            % % use >/< rule (verify first slrt RE time is longer than mod,
            % % assuming slrt->pMod delay is less than the sync period)
            % syncOffset_0 = t_edge0_slrt - t_edge0; % offset as RE-latency diff between SLRT and MOD (peripheral recording modality)
            % syncOffset_1 = t_edge1_slrt - t_edge0;
            % syncOffsets = [syncOffset_0, syncOffset_1];
            % syncOffsets = syncOffsets(syncOffsets>0); % positive only
            % syncOffset = min(syncOffsets);
            % disp(syncOffset);
            % syncOffset = min(abs([syncOffset_0, syncOffset_1]));
            % syncOffset_line = syncOffset;
        % end        
    end
end