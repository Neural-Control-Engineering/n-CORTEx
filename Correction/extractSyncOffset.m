function syncOffset = extractSyncOffset(row_SLRT, sync, prevSyncOffset)
    % extract target acquisition delay (relative to SLRT)
    syncLineNames = fieldnames(sync.lines);
    syncLineFreqs = cellfun(@(x) split(x,"_"), syncLineNames, "UniformOutput",false);
    syncLineFreqs = cellfun(@(x) str2double(strrep(x{2},"Hz","")), syncLineFreqs, "UniformOutput",false);
    syncLineFreqs = cell2mat(syncLineFreqs);
    [syncLineFreqs_sorted, sortIdx] = sort(syncLineFreqs);
    % iterate through syncLines, inferring rising-edge offsets, sorted from slowest to fastest
    % syncOffset_line = [];
    syncOffset = [];
    for i = 1:length(syncLineNames)
        idx = sortIdx(i);
        freqTitle = sprintf("%dHz",syncLineFreqs(idx));
        syncLineName = syncLineNames{idx};
        syncLine = sync.lines.(syncLineName);
        t_RE = syncLine.t_RE; % pMod sync line
        colNames_slrt = convertCharsToStrings(row_SLRT.Properties.VariableNames);
        t_RE_slrtCol = contains(colNames_slrt,"t-RE") & contains(colNames_slrt,freqTitle);
        t_RE_slrt = row_SLRT.(colNames_slrt(t_RE_slrtCol==1)){1}; % slrt sync line
        % to achieve full sync-precision:
        % cascade offset correction from previous, slower pulses (update each t_RE to reflect
        % offset from slower sync line - this is a recurrent process as we
        % iterate to faster sync lines)
        if ~isempty(syncOffset) % assuming previous, slowest, initial syncLine has been visited
            % recurse ...
            % t_RE = t_RE + syncOffset; % new-corrected t_RE (from previous, slower line)
            t_RE0_slrt = t_RE_slrt(1); 
            t_RE1_slrt = t_RE_slrt(2);
            %% prevSyncOffset landmarking
            if isempty(prevSyncOffset)
                t_RE0 = t_RE(1); % here
            else
                % faster line landmarking
                projected_firstRE = t_RE0_slrt - prevSyncOffset;
                % locate closest RE (to projection based on prev offset)
                t_RE_diff = t_RE - projected_firstRE;
                [minVal, idx_min] = min(abs(t_RE_diff));
                % store
                t_RE0 = t_RE(idx_min);
            end            
            % t_RE_diff = t_RE_slrt - t_RE0;            
            % [syncOffset_line, idx_min] = min(abs(t_RE_diff)); % locate projected t_RE, update syncOffset_line from next, faster line
            
            syncOffset_0 = t_RE0_slrt - t_RE0; % offset as RE-latency diff between SLRT and MOD (peripheral recording modality)
            syncOffset_1 = t_RE1_slrt - t_RE0;
            syncOffsets = [syncOffset_0, syncOffset_1];
            syncOffsets = syncOffsets(syncOffsets>0); % positive only
            syncOffset_line = min(syncOffsets);
            % syncOffset_line = min(abs([syncOffset_0, syncOffset_1])); % smallest difference thats not negative
            syncOffset = syncOffset + syncOffset_line; % offset convergently accumulated across all lines
        else % still on first, slowest line, self-locate (using prevSyncOffset, if available) and compute first itr. of next syncOffset
            % first (two) RE offsets
            t_RE0_slrt = t_RE_slrt(1);
            t_RE1_slrt = t_RE_slrt(2);
            %% prevSyncOffset landmarking
            if isempty(prevSyncOffset) % if no previous syncOffset (this is the first trial from the assoc. trial-gate)
                t_RE0 = t_RE(1); % use first RE-time 
            else % locate matching RE-latency idx using previously discovered syncOffset (important for multiple trials in one trial-gate)
                projected_firstRE = t_RE0_slrt - prevSyncOffset;
                % locate corresponding RE in pMOD data (peripheral modality) 
                t_RE_diff = t_RE - projected_firstRE;
                [minVal, idx_min] = min(abs(t_RE_diff));
                % store located corresponding RE
                t_RE0 = t_RE(idx_min); % search t_RE closest to projected (given known previous offset -> local sampling drift tracking/correction
            end            
            % use >/< rule (verify first slrt RE time is longer than mod,
            % assuming slrt->pMod delay is less than the sync period)
            syncOffset_0 = t_RE0_slrt - t_RE0; % offset as RE-latency diff between SLRT and MOD (peripheral recording modality)
            syncOffset_1 = t_RE1_slrt - t_RE0;
            syncOffsets = [syncOffset_0, syncOffset_1];
            syncOffsets = syncOffsets(syncOffsets>0); % positive only
            syncOffset = min(syncOffsets);
            % syncOffset = min(abs([syncOffset_0, syncOffset_1]));
            % syncOffset_line = syncOffset;
        end        
    end
end