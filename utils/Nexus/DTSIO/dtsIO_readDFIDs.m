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

    cols  = string(DTS.Properties.VariableNames);
    dfIDs = cols;

    if ~ismember('h5_path', dfIDs)
        return;
    end

    % Translate h5_path_<dfID> routing columns → their dfIDs.
    % Patch dfIDs live in dedicated HDF5 files (not under the main h5_root),
    % so HDF5 group sampling below would never find them. Parse the column
    % names directly — they are present regardless of which rows have data.
    patchCols  = cols(startsWith(cols, "h5_path_"));
    patchDfIDs = erase(patchCols, "h5_path_");

    % Remove raw routing column names from the visible list and add resolved dfIDs.
    dfIDs = [cols(~startsWith(cols, "h5_path_")), patchDfIDs];

    % Sample the last row for the main-HDF5 group scan — it has the most
    % complete set of groups compared to row 10 which may predate new dfIDs.
    sampleRow = height(DTS);
    h5File = char(DTS.h5_path(sampleRow));
    h5Root = char(DTS.h5_root(sampleRow));

    try
        info    = h5info(h5File, h5Root);
        leafFcn = @(fullPath) fullPath(find(fullPath == '/', 1, 'last') + 1 : end);
        h5IDs = string({});
        if ~isempty(info.Groups)
            h5IDs = [h5IDs, string(cellfun(leafFcn, {info.Groups.Name}, 'UniformOutput', false))];
        end
        if ~isempty(info.Datasets)
            h5IDs = [h5IDs, string({info.Datasets.Name})];
        end
        dfIDs = unique([dfIDs, h5IDs], "stable");
    catch
        warning('[dtsIO_readDFIDs] Could not read HDF5 from %s%s', h5File, h5Root);
    end
end
