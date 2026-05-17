function dtsIO_patchManifest(nexon, dfColName, h5FileOut)
% Register a dfColumn-specific HDF5 file in the DTS manifest.
%
% After nexTract writes dfColName to h5FileOut, this function adds the column
% "h5_path_<dfColName>" to nexon.console.BASE.DTS so that dtsIO_readDF can
% route reads for that dfID to the correct file.
%
% For parallel multi-session nexTract runs, each session calls this after its
% own run completes. Because sessions have independent nexon objects, the
% patches need to be merged into the shared manifest afterward:
%
%   dtsIO_loadManifestPatches(nexon, patchDir)
%
% The patch .mat file is saved alongside h5FileOut automatically.

    colName  = char("h5_path_" + string(dfColName));
    nRows    = height(nexon.console.BASE.DTS);
    pathCol  = repmat(string(h5FileOut), nRows, 1);

    if ismember(colName, nexon.console.BASE.DTS.Properties.VariableNames)
        nexon.console.BASE.DTS.(colName) = pathCol;
    else
        newCol = table(pathCol, 'VariableNames', {colName});
        nexon.console.BASE.DTS = [nexon.console.BASE.DTS, newCol];
    end

    % Save a patch file alongside the output HDF5 so parallel sessions can be
    % merged without needing a live nexon reference.
    patchFile = strrep(h5FileOut, '.h5', '_manifest_patch.mat');
    try
        patch.dfColName = char(dfColName);  %#ok<STRNU>
        patch.h5FileOut = char(h5FileOut);  %#ok<STRNU>
        patch.colName   = colName;          %#ok<STRNU>
        patch.pathCol   = pathCol;          %#ok<STRNU>
        save(patchFile, '-struct', 'patch');
    catch
    end
end
