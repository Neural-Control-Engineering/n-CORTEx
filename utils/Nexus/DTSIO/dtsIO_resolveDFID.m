function [cols, baseDFID] = dtsIO_resolveDFID(DTS, DFID)
% dtsIO_resolveDFID  Single source of truth: map a dfID to its in-memory DTS
% columns and the base dfID to split them on.
%
%   [cols, baseDFID] = dtsIO_resolveDFID(DTS, DFID)
%
% Shared by dtsIO_composeDF (assembly), dtsIO_readDF (routing) and the launcher
% presence check, so all four agree on what "this dfID exists" means. Returns
% cols = strings(0,1) when DFID resolves to nothing.
%
% Resolution order:
%   1. Foliated DF — columns whose name minus the trailing _<stub> equals DFID
%      (e.g. DFID="lfp" -> lfp_df, lfp_t, lfp_chans; plus a bare column named
%      DFID if the df is stored directly).
%   2. _df normalization — if DFID ends in "_df" and step 1 found nothing, retry
%      with "_df" stripped, so the data-column name ("RTS_spk_activity_df")
%      resolves to the same DF as its base ("RTS_spk_activity").
%   3. Single-column DF — a bare column named exactly DFID with no foliated
%      siblings (a scalar/struct stored in one column).
%
% Disk-backed DTS is out of scope here (dfIDs are HDF5 groups, not columns) —
% callers gate on the h5_path manifest before reaching this.

    DFID    = string(DFID);
    allCols = string(DTS.Properties.VariableNames);
    if isempty(allCols)
        cols = strings(0,1); baseDFID = DFID; return;
    end
    baseCol = arrayfun(@localBase, allCols);   % base of each column ("" if bare)

    % 1. foliated DF (has <DFID>_<stub> siblings)
    if any(baseCol == DFID)
        cols = allCols((baseCol == DFID) | (allCols == DFID));  % siblings + bare df col
        baseDFID = DFID; return;
    end

    % 2. _df normalization (data-column name -> its base group)
    if endsWith(DFID, "_df")
        base = regexprep(DFID, "_df$", "");
        if any(baseCol == base)
            cols = allCols((baseCol == base) | (allCols == base));
            baseDFID = base; return;
        end
    end

    % 3. genuine single-column DF
    if any(allCols == DFID)
        cols = DFID; baseDFID = DFID; return;
    end

    cols = strings(0,1); baseDFID = DFID;   % not found
end

function b = localBase(col)
% The dfID a foliated column belongs to = the name minus its trailing _<stub>.
% Bare columns (no underscore) have no base.
    parts = split(col, "_");
    if numel(parts) <= 1
        b = "";
    else
        b = strjoin(parts(1:end-1), "_");
    end
end
