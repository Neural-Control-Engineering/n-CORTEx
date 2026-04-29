function categories = nexOp_listCategories_h5(nexon)
% Return category keys for HDF5-backed scalar dfIDs, prefixed with "h5--".
% Only disk-backed (manifest) DTS instances have HDF5 dfIDs; returns empty
% for in-memory DTS.  Manifest-only columns (sessionLabel, trialNumber, etc.)
% are excluded — only IDs that live exclusively in HDF5 are returned.

    categories = string.empty(0,1);
    DTS = nexon.console.BASE.DTS;
    if ~ismember('h5_path', string(DTS.Properties.VariableNames))
        return;
    end

    allIDs      = dtsIO_readDFIDs(DTS);
    manifestIDs = string(DTS.Properties.VariableNames);
    h5IDs       = setdiff(allIDs, manifestIDs, 'stable');

    if isempty(h5IDs)
        return;
    end
    categories = arrayfun(@(id) sprintf("h5--%s", id), h5IDs, 'UniformOutput', true);
end
