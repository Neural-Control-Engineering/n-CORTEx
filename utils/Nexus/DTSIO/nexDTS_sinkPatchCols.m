function [DTS_remaining, patchMap] = nexDTS_sinkPatchCols(DTS_inmem, manifest_in, nexon, patchDir)
% Route patch-eligible columns from DTS_inmem to dedicated HDF5 files,
% leaving only main-DTS columns in DTS_remaining.
%
% Two sources of patch candidates (unioned):
%   1. nexon.UserData.patchRegistry  — pending: nexTract wrote in-memory,
%      no file exists yet.  A new <dfID>.h5 is created in patchDir.
%   2. h5_path_<dfID> columns in manifest_in — known: extend the existing file.
%
% Inputs:
%   DTS_inmem   : in-memory table of new rows to be sunk (no h5_path column)
%   manifest_in : existing manifest (may be [] on first sink)
%   nexon       : live Nexon handle (for patchRegistry + updateControlPanel)
%   patchDir    : directory for newly-created patch HDF5 files
%
% Outputs:
%   DTS_remaining : DTS_inmem with patched columns removed
%   patchMap      : struct array with fields .dfID, .h5File, .isNew
%                   (one entry per dfID that was routed; useful for
%                   registering newly-created patches back on nexon)

    DTS_remaining = DTS_inmem;
    patchMap      = struct('dfID', {}, 'h5File', {}, 'isNew', {});

    if isempty(DTS_inmem) || ~istable(DTS_inmem), return; end

    tableVars = string(DTS_inmem.Properties.VariableNames);

    % ── Collect all patch candidates ──────────────────────────────────────
    % Source 1: pending (registered but no file yet)
    pending = {};
    if ~isempty(nexon) && isfield(nexon.UserData, 'patchRegistry')
        pending = nexon.UserData.patchRegistry;
    end

    % Source 2: known (manifest already has h5_path_<dfID> columns)
    known     = struct();   % dfID → h5File
    if ~isempty(manifest_in) && istable(manifest_in)
        mVars = string(manifest_in.Properties.VariableNames);
        patchCols = mVars(startsWith(mVars, "h5_path_") & mVars ~= "h5_path");
        for k = 1:numel(patchCols)
            dfID = char(extractAfter(patchCols(k), "h5_path_"));
            known.(dfID) = char(manifest_in.(char(patchCols(k)))(1));
        end
    end

    % Union — pending takes precedence for path-building; known supplies file
    allIDs = union(pending, fieldnames(known), 'stable');

    % ── Per-dfID: find columns, write, remove from DTS_remaining ─────────
    for i = 1:numel(allIDs)
        dfID = char(allIDs{i});

        % Columns belonging to this dfID (e.g. pca_df, pca_t, pca_chans)
        dfCols = tableVars(tableVars == dfID | startsWith(tableVars, dfID + "_"));
        if isempty(dfCols), continue; end

        % Resolve destination HDF5 file
        if isfield(known, dfID)
            h5File = known.(dfID);
            isNew  = false;
        else
            h5File = fullfile(patchDir, [dfID '.h5']);
            isNew  = true;
        end

        % Write per row
        nRows = height(DTS_inmem);
        for r = 1:nRows
            sl   = string(DTS_inmem.sessionLabel(r));
            tNum = DTS_inmem.trialNumber(r);
            h5Root = nex_buildH5Root(sl, tNum);

            DF = reconstructDF(DTS_inmem, dfCols, dfID, r);
            if isempty(DF), continue; end
            dtsIO_writeDF_toHDF5(h5File, char(h5Root), dfID, DF);
        end

        % Register newly-created patch on the live nexon
        if isNew && ~isempty(nexon)
            dtsIO_patchManifest(nexon, dfID, h5File);
        end

        patchMap(end+1) = struct('dfID', dfID, 'h5File', h5File, 'isNew', isNew); %#ok<AGROW>

        % Drop these columns so they don't also land in nexDTS.h5
        DTS_remaining = removevars(DTS_remaining, cellstr(dfCols));
    end

    % Clear the pending registry — everything in it has now been handled
    if ~isempty(nexon) && isfield(nexon.UserData, 'patchRegistry')
        nexon.UserData.patchRegistry = {};
    end
end

% ── Helper ────────────────────────────────────────────────────────────────

function DF = reconstructDF(DTS, dfCols, dfID, rowIdx)
% Reconstruct a DF struct for one row from a set of dfID-prefixed columns.
    DF = [];
    axisKeyWords = nex_axisKeyWords();
    for j = 1:numel(dfCols)
        col  = char(dfCols(j));
        raw  = DTS.(col);
        val  = [];
        if iscell(raw) && numel(raw) >= rowIdx
            val = raw{rowIdx};
        elseif isnumeric(raw) && size(raw,1) >= rowIdx
            val = raw(rowIdx,:);
        end
        if isempty(val), continue; end

        stub = char(extractAfter(string(col), dfID + "_"));
        if isempty(stub) || strcmp(stub, col)
            stub = "df";
        end

        if strcmp(stub, "df")
            if isempty(DF), DF = struct(); end
            DF.df = double(val);
        elseif any(strcmp(axisKeyWords, stub))
            if isempty(DF), DF = struct(); end
            if isnumeric(val)
                DF.ax.(stub) = double(val);
            else
                DF.ax.(stub) = string(val);
            end
        end
    end
    if ~isempty(DF) && isfield(DF, 'ax')
        DF = nex_initAxisPointer_v2(DF);
    end
end
