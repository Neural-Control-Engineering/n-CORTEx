function dtsIO_loadManifestPatches(nexon, patchDir)
% Merge dfColumn manifest patches from parallel nexTract sessions.
%
% After running nexTract on multiple dfColumns in separate MATLAB sessions,
% each session leaves a <dfColName>_manifest_patch.mat alongside its output
% HDF5 file. Call this in the main session to register all of them at once:
%
%   dtsIO_loadManifestPatches(nexon, '/path/to/data/')
%
% patchDir defaults to the directory of the first h5_path in the DTS.

    if nargin < 2 || isempty(patchDir)
        patchDir = fileparts(char(nexon.console.BASE.DTS.h5_path(1)));
    end

    patchFiles = dir(fullfile(patchDir, '*_manifest_patch.mat'));
    if isempty(patchFiles)
        fprintf('dtsIO_loadManifestPatches: no patch files found in %s\n', patchDir);
        return
    end

    nRows = height(nexon.console.BASE.DTS);
    for k = 1:numel(patchFiles)
        p = load(fullfile(patchFiles(k).folder, patchFiles(k).name));
        if ~isfield(p, 'colName') || ~isfield(p, 'pathCol'), continue; end
        if numel(p.pathCol) > nRows
            warning('dtsIO_loadManifestPatches: patch "%s" has %d rows, DTS has %d — skipping.', ...
                p.colName, numel(p.pathCol), nRows);
            continue
        end
        % Patch covers fewer trials than the DTS: pad unanalyzed rows with ""
        % so previously written data is accessible while new trials stay empty.
        pathColFull = strings(nRows, 1);
        pathColFull(1:numel(p.pathCol)) = string(p.pathCol(:));
        if numel(p.pathCol) < nRows
            fprintf('  note: patch "%s" covers %d/%d trials — %d rows left empty.\n', ...
                p.colName, numel(p.pathCol), nRows, nRows - numel(p.pathCol));
        end
        if ismember(p.colName, nexon.console.BASE.DTS.Properties.VariableNames)
            nexon.console.BASE.DTS.(p.colName) = pathColFull;
        else
            newCol = table(pathColFull, 'VariableNames', {p.colName});
            nexon.console.BASE.DTS = [nexon.console.BASE.DTS, newCol];
        end
        fprintf('  registered: %s → %s\n', p.colName, p.h5FileOut);
    end
end
