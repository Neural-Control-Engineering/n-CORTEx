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

    sampleRow = min(10, height(DTS));
    h5File = char(DTS.h5_path(sampleRow));
    h5Root = char(DTS.h5_root(sampleRow));

    try
        info    = h5info(h5File, h5Root);
        leafFcn = @(fullPath) fullPath(find(fullPath == '/', 1, 'last') + 1 : end);
        % DF-group entries: info.Groups.Name is a full path → extract leaf
        h5IDs = string({});
        if ~isempty(info.Groups)
            h5IDs = [h5IDs, string(cellfun(leafFcn, {info.Groups.Name}, 'UniformOutput', false))];
        end
        % Flat dataset entries: info.Datasets.Name is already the leaf name
        if ~isempty(info.Datasets)
            h5IDs = [h5IDs, string({info.Datasets.Name})];
        end
        dfIDs = [dfIDs, h5IDs];
    catch
        warning('[dtsIO_readDFIDs] Could not read HDF5 from %s%s', h5File, h5Root);
    end
end
