function rowIdx = dtsIO_findSentinelRow(nexon, dfID)
% dtsIO_findSentinelRow  First DTS row with written data for dfID.
%   Tries three locations in order, falling through on failure:
%   1. Patch column (h5_path_<dfID>) — row-by-row scan, newest first.
%   2. In-memory foliated columns (<dfID>_df, <dfID>_unit, …).
%   3. Base diskDTS (h5_path) — row-by-row h5info scan, newest first.
%   Returns [] if no row has data.

    rowIdx = [];
    DTS    = nexon.console.BASE.DTS;
    dfID   = char(dfID);

    % --- 1. Disk-backed patch (h5_path_<dfID> column) --------------------
    % Scan newest-first so recently-added dfIDs are found without traversing
    % old trials. Falls through to base-HDF5 check when nothing is found
    % (handles the case where patch column exists but data landed in base).
    patchCol = ['h5_path_' dfID];
    if ismember(patchCol, DTS.Properties.VariableNames)
        try
            allPaths = string(DTS.(patchCol));
            h5roots  = string(DTS.h5_root);
            for ri = numel(allPaths):-1:1
                p = allPaths(ri);
                if p == "" || p == "0", continue; end
                try
                    h5info(char(p), [char(h5roots(ri)) '/' dfID]);
                    rowIdx = ri;
                    return;
                catch
                end
            end
        catch
        end
        % fall through — patch column present but data not there
    end

    % --- 2. In-memory foliated columns (<dfID>_df, <dfID>_unit, …) -------
    [cols, ~] = dtsIO_resolveDFID(DTS, dfID);
    if ~isempty(cols)
        col = DTS.(char(cols(1)));
        if iscell(col)
            rowIdx = find(~cellfun(@isempty, col), 1, 'last');
        end
        return;
    end

    % --- 3. Base diskDTS (dfID group in main HDF5) -----------------------
    % Scan newest-first — newer trials more likely to have recently-added dfIDs.
    if ismember('h5_path', DTS.Properties.VariableNames)
        try
            h5paths   = string(DTS.h5_path);
            h5roots   = string(DTS.h5_root);
            validRows = find(strlength(h5paths) > 0 & strlength(h5roots) > 0);
            if isempty(validRows), return; end
            h5File = char(h5paths(validRows(1)));
            for ri = validRows(end:-1:1)'
                try
                    h5info(h5File, [char(h5roots(ri)) '/' dfID]);
                    rowIdx = ri;
                    return;
                catch
                end
            end
        catch
        end
    end
end
