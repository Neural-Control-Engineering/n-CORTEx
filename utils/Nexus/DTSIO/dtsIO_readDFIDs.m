function dfIDs = dtsIO_readDFIDs(DTS)
% Return all dfIDs present in a DTS — manifest columns plus HDF5 group names.
% Equivalent of DTS.Properties.VariableNames for a disk-backed manifest.
%
%   dfIDs = dtsIO_readDFIDs(DTS)
%
% For an in-memory DTS, returns DTS.Properties.VariableNames as a string array.
% For a disk-backed manifest, also appends the HDF5 dfID group names read from
% a sample trial root (row 1), returning just the leaf name (e.g. "lfp", not
% the full group path).

    dfIDs = string(DTS.Properties.VariableNames);

    if ~ismember('h5_path', dfIDs)
        return;
    end

    h5File = char(DTS.h5_path(10));
    h5Root = char(DTS.h5_root(10));

    try
        info    = h5info(h5File, h5Root);
        leafFcn = @(fullPath) fullPath(find(fullPath == '/', 1, 'last') + 1 : end);
        h5IDs   = string(cellfun(leafFcn, {info.Groups.Name}, 'UniformOutput', false));
        dfIDs   = [dfIDs, h5IDs];
    catch
        warning('[dtsIO_readDFIDs] Could not read HDF5 groups from %s%s', h5File, h5Root);
    end
end
