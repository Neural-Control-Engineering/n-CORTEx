function rowIdx = dtsIO_findSentinelRow(nexon, dfID)
% dtsIO_findSentinelRow  First DTS row with written data for dfID.
%
%   Disk-backed patch: reads h5info once on the patch file and intersects
%   written h5_root groups against the DTS manifest — no row-by-row reads.
%   In-memory: finds the first non-empty cell in the dfID column.
%   Returns [] if no row has data yet.

    rowIdx = [];
    DTS    = nexon.console.BASE.DTS;
    dfID   = char(dfID);

    % --- Disk-backed patch -----------------------------------------------
    patchCol = ['h5_path_' dfID];
    if ismember(patchCol, DTS.Properties.VariableNames)
        try
            allPaths  = string(DTS.(patchCol));
            patchFile = char(allPaths(find(allPaths ~= "" & allPaths ~= "0", 1)));
            info = h5info(patchFile);
            % h5info only populates immediate children; BFS over the struct
            % tree to collect every group name at all depths (no extra I/O).
            allNames = string.empty(0, 1);
            stack    = info.Groups(:);
            while ~isempty(stack)
                allNames(end+1, 1) = string(stack(1).Name); %#ok<AGROW>
                stack = [stack(2:end); stack(1).Groups(:)];
            end
            [~, ia] = intersect(string(DTS.h5_root), allNames, 'stable');
            if ~isempty(ia), rowIdx = ia(1); end
        catch
        end
        return;
    end

    % --- In-memory -------------------------------------------------------
    if ismember(dfID, DTS.Properties.VariableNames)
        col = DTS.(dfID);
        if iscell(col)
            rowIdx = find(~cellfun(@isempty, col), 1);
        end
        return;
    end

    % --- Base diskDTS (dfID in main HDF5, no patch column) ---------------
    % All rows are written together at export time, so presence in any one
    % row implies presence in all — just verify the dfID group exists.
    if ismember('h5_path', DTS.Properties.VariableNames)
        try
            validH5 = find(strlength(string(DTS.h5_path)) > 0, 1);
            h5File  = char(DTS.h5_path(validH5));
            h5Root  = char(DTS.h5_root(validH5));
            h5info(h5File, [h5Root '/' dfID]);   % throws if group absent
            rowIdx = validH5;
        catch
        end
    end
end
