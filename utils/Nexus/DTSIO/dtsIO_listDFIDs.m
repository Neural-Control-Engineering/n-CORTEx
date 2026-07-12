function dfIDs = dtsIO_listDFIDs(DTS)
% dtsIO_listDFIDs  Display-level dfIDs present in a DTS — the enumeration
% counterpart to dtsIO_resolveDFID (which resolves one).
%
%   dfIDs = dtsIO_listDFIDs(DTS)
%
% Disk-backed manifest → HDF5 group names (via dtsIO_readDFIDs). In-memory DTS →
% base dfIDs, collapsing foliated <base>_<stub> columns to <base> (so a DF spread
% across lfp_df/lfp_t/lfp_chans lists once as "lfp"), plus bare columns as-is.
% Used by the launcher source list so it shows composable dfIDs, not raw stubs.

    cols = string(DTS.Properties.VariableNames);
    if ismember('h5_path', cols)
        dfIDs = string(dtsIO_readDFIDs(DTS));
        return;
    end

    bases = strings(0,1);
    for i = 1:numel(cols)
        b = localBase(cols(i));
        if b == ""
            bases(end+1) = cols(i);   %#ok<AGROW> bare column
        else
            bases(end+1) = b;         %#ok<AGROW> foliated -> its base
        end
    end
    dfIDs = unique(bases, "stable");
end

function b = localBase(col)
    parts = split(col, "_");
    if numel(parts) <= 1
        b = "";
    else
        b = strjoin(parts(1:end-1), "_");
    end
end
