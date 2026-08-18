function dtsIO_patchManifest(nexon, dfColName, h5FileOut)
% Register a dfColumn-specific HDF5 file in the DTS manifest.
%
% Two modes:
%
%   dtsIO_patchManifest(nexon, dfColName, h5FileOut)
%     Normal mode: nexTract has already written to h5FileOut. Adds the
%     "h5_path_<dfColName>" column to the live DTS and saves a
%     _manifest_patch.mat alongside h5FileOut for parallel-session merging.
%
%   dtsIO_patchManifest(nexon, dfColName, [])
%     Pending mode: nexTract wrote to the in-memory DTS but no file exists
%     yet. Registers dfColName in nexon.UserData.patchRegistry so that
%     nexDTS_sinkPatchCols creates a dedicated patch HDF5 at sink time
%     instead of folding these columns into the main nexDTS.h5.

    dfColName = char(dfColName);

    if isempty(h5FileOut)
        % ── Pending registration ──────────────────────────────────────────
        if ~isfield(nexon.UserData, 'patchRegistry') || ...
                isempty(nexon.UserData.patchRegistry)
            nexon.UserData.patchRegistry = {dfColName};
        elseif ~ismember(dfColName, nexon.UserData.patchRegistry)
            nexon.UserData.patchRegistry{end+1} = dfColName;
        end
        return;
    end

    % ── Normal mode: file already exists ─────────────────────────────────
    colName  = char("h5_path_" + string(dfColName));
    DTS      = nexon.console.BASE.DTS;
    nRows    = height(DTS);
    pathCol  = repmat(string(h5FileOut), nRows, 1);

    % Hybrid routing: in-memory source rows (h5_path == "") don't get their
    % output written to the patch file (they have no per-trial h5_root, so
    % nexTract writes their output into the in-memory row instead). Leave their
    % h5_path_<dfID> == "" so dtsIO_composeDF routes the read to the foliated
    % in-memory columns rather than the shared "/<dfID>" patch group.
    if ismember('h5_path', DTS.Properties.VariableNames)
        inMem = strlength(string(DTS.h5_path)) == 0;
        pathCol(inMem) = "";
    end

    if ismember(colName, nexon.console.BASE.DTS.Properties.VariableNames)
        nexon.console.BASE.DTS.(colName) = pathCol;
    else
        newCol = table(pathCol, 'VariableNames', {colName});
        nexon.console.BASE.DTS = [nexon.console.BASE.DTS, newCol];
    end

    % Save a patch file alongside the output HDF5 so parallel sessions can
    % be merged without a live nexon reference.
    patchFile = strrep(h5FileOut, '.h5', '_manifest_patch.mat');
    try
        patch.dfColName = dfColName;   %#ok<STRNU>
        patch.h5FileOut = char(h5FileOut); %#ok<STRNU>
        patch.colName   = colName;     %#ok<STRNU>
        patch.pathCol   = pathCol;     %#ok<STRNU>
        save(patchFile, '-struct', 'patch');
    catch
    end
end
