function nexTract(nexon, fcn, dfID, mask, fcnName, dfColName, opts)
%   nexTract(nexon, fcn, dfID)
%   nexTract(nexon, fcn, dfID, mask, fcnName)
%   nexTract(nexon, fcn, dfID, mask, fcnName, dfColName)
%   nexTract(nexon, fcn, dfID, mask, fcnName, dfColName, opts)
%
% dfColName overrides the default "<dfID>_<fcnName>" output column name.
% Use this to write alternate parameters without overwriting an existing run.
%
% opts.poolRestartInterval  — restart the parallel pool every N rows to
%   reclaim worker heap that MATLAB's allocator does not return to the OS
%   between tasks. Default = Inf (never restart). Recommended: 20–50 for
%   parfor-backed functions on large datasets.
% opts.skipExisting  — when true, skip any row whose output already exists
%   in the DTS (disk-backed: checks the output HDF5 group; in-memory:
%   checks that the dfColName column is present and non-empty). Default false.

    if nargin < 5 || isempty(fcnName)
        fcnName = func2str(fcn);
    end
    if nargin < 7 || isempty(opts)
        opts = struct();
    end
    poolRestartInterval = inf;
    if isfield(opts, 'poolRestartInterval')
        poolRestartInterval = opts.poolRestartInterval;
    end
    % Rewrite policy. overwrite=false (default): skip a trial that already carries
    % this output — location-agnostic (disk patch group OR in-memory foliated
    % column). overwrite=true: recompute and rewrite regardless of where it lives.
    % Legacy 'skipExisting' is honored as the inverse alias (skipExisting=true ==
    % overwrite=false) so older calls keep working.
    overwrite = false;
    if isfield(opts, 'skipExisting'), overwrite = ~logical(opts.skipExisting); end
    if isfield(opts, 'overwrite'),    overwrite = logical(opts.overwrite);    end

    rowStart = 1;
    rowsSinceRestart = 0;

    dtsRows    = height(nexon.console.BASE.DTS);
    dfID_entry = strrep(dfID, "_df", "");
    if nargin < 6 || isempty(dfColName)
        dfColName = sprintf("%s_%s", dfID_entry, fcnName);
    else
        dfColName = string(dfColName);
    end

    nOut = numel(dfColName);  % 1 for single-output functions, N for multi-output

    isDiskBacked = ismember('h5_path', nexon.console.BASE.DTS.Properties.VariableNames);

    % Each nexTract run writes to its own dfColumn-specific HDF5 file.
    % This avoids flock(LOCK_EX) conflicts with concurrent RDONLY sessions on
    % the shared source file — no locking workarounds needed.
    % For N outputs: N independent files, skip-checked independently per output.
    if isDiskBacked
        h5FileIn  = char(nexon.console.BASE.DTS.h5_path(1));
        [d, b, e] = fileparts(h5FileIn);
        h5FileOut = arrayfun(@(name) fullfile(d, [b '_' char(name) e]), dfColName, 'UniformOutput', false);
    end

    % minLength — read lengths from the INPUT file (source dfID)
    if isDiskBacked
        lengths  = zeros(1, dtsRows);
        fapl_len = H5P.create('H5P_FILE_ACCESS');
        H5P.set_fclose_degree(fapl_len, 'H5F_CLOSE_STRONG');
        fid_len = H5F.open(h5FileIn, 'H5F_ACC_RDONLY', fapl_len);
        H5P.close(fapl_len);
        for ii = 1:dtsRows
            dset_path = char(nexon.console.BASE.DTS.h5_root(ii) + "/" + dfID_entry + "/df");
            try
                if H5L.exists(fid_len, dset_path, 'H5P_DEFAULT')
                    did_l = H5D.open(fid_len, dset_path);
                    sid_l = H5D.get_space(did_l);
                    [~, sz_l] = H5S.get_simple_extent_dims(sid_l);
                    lengths(ii) = sz_l(1);
                    H5S.close(sid_l);
                    H5D.close(did_l);
                end
            catch
            end
        end
        H5F.close(fid_len);
        minLength = min(lengths(lengths > 0));
    else
        minLength = arrayfun(@(x) size(x{1},2), nexon.console.BASE.DTS.(dfID), "UniformOutput", true);
        minLength(minLength == 0) = [];
        minLength = min(minLength);
    end

    % Register manifest patches before the loop so that other MATLAB workers
    % can call dtsIO_loadManifestPatches and start consuming completed rows
    % without waiting for the full nexTract run to finish.
    % The patch records a path only — no HDF5 file existence required.
    if isDiskBacked
        for k = 1:nOut
            dtsIO_patchManifest(nexon, dfColName(k), h5FileOut{k});
        end
    end

    % Row selection: honor an explicit mask (logical vector or numeric row
    % indices) so callers can extract just the routed trial; empty/absent →
    % all rows. minLength above still spans the whole column so a single
    % re-extracted trial stays length-consistent with the rest.
    if nargin < 4 || isempty(mask)
        rowList = rowStart:dtsRows;
    elseif islogical(mask)
        rowList = find(mask(:)).';
    else
        rowList = double(mask(:)).';
    end

    DFOUT = {}; %#ok<NASGU>
    for i = rowList
        disp(i);

        % Skip check — independent per output k. When NOT overwriting, skip a
        % trial whose output ALL exist already, wherever they live (disk patch
        % group for a disk row, foliated <dfID>_df column for an in-memory row).
        % overwrite=true bypasses this and always recomputes.
        skip = false(1, nOut);
        if ~overwrite
            for k = 1:nOut
                hf = '';
                if isDiskBacked, hf = h5FileOut{k}; end
                skip(k) = nexTract_outputExists(nexon, dfColName(k), i, isDiskBacked, hf);
            end
            if all(skip), continue; end
        end

        % Periodic pool restart — reclaims worker heap accumulated over prior rows.
        rowsSinceRestart = rowsSinceRestart + 1;
        if rowsSinceRestart >= poolRestartInterval
            p = gcp('nocreate');
            if ~isempty(p)
                delete(p);
                fprintf('nexTract: restarted parallel pool at row %d\n', i);
            end
            rowsSinceRestart = 0;
        end

        DF_in = dtsIO_readDF(nexon, dfID_entry, i);
        try
            df = DF_in.df;
        catch
            continue
        end
        if ~isempty(df)
            try
                if size(df, 2) > minLength * 1.01
                    ptr = nexInit_axisPointer(DF_in.df, DF_in.ax);
                    DF_in.df = df(:, 1:minLength);
                    axFields = convertCharsToStrings(fieldnames(DF_in.ax));
                    axDims = [];
                    for j = 1:length(axFields); axDims = [axDims; ptr.(axFields(j)).dim]; end %#ok<AGROW>
                    axSel = axFields(axDims == 2);
                    try
                        ax = DF_in.ax.(axSel);
                    catch
                        try
                            ax = DF_in.ax.t;  axSel = "t";
                        catch e
                            disp(getReport(e));
                        end
                    end
                    DF_in.ax.(axSel) = ax(1:minLength);
                end
                args         = extractMethodCfg(fcnName);
                args.idx_row = i;
                if nOut > 1
                    varout = cell(1, nOut);
                    [varout{:}] = fcn(DF_in, args);
                else
                    varout = {fcn(DF_in, args)};
                end
            catch e
                disp(getReport(e));
                continue
            end
        else
            continue
        end

        for k = 1:nOut
            if isDiskBacked && skip(k), continue; end
            try
                if isDiskBacked
                    h5Root = char(nexon.console.BASE.DTS.h5_root(i));
                    if isempty(h5Root)
                        % Hybrid in-memory source row (h5_path/h5_root == ""): it
                        % has no per-trial h5_root to key a unique patch group, so
                        % all such rows would collide at "/<dfID>" in the patch
                        % file. Write the output into the IN-MEMORY row instead
                        % (forceMem foliates it into <dfID>_* columns); dtsIO_composeDF
                        % reads it back from those columns for rows whose h5_path
                        % is "". dtsIO_patchManifest leaves h5_path_<dfID> = "" for
                        % these rows so the read routes to memory, not the patch.
                        dtsIO_writeDF(nexon, varout{k}, dfColName(k), i, true);
                    else
                        % Disk-backed row: per-trial patch group, as before.
                        dtsIO_writeDF_toHDF5(h5FileOut{k}, h5Root, char(dfColName(k)), varout{k});
                    end
                else
                    dtsIO_writeDF(nexon, varout{k}, dfColName(k), i);
                end
            catch e
                warning("nexTract: write failed for row %d output '%s' — %s\nAborting.", i, dfColName(k), e.message);
                break
            end
        end
    end

end

% ── helpers ──────────────────────────────────────────────────────────────────

function tf = nexTract_outputExists(nexon, dfColName, rowIdx, isDiskBacked, h5FileOut)
% Does this trial already carry the extraction output? Location-agnostic, matching
% where nexTract writes it: a DISK row -> the patch file's h5_root/<dfID>/df group;
% an IN-MEMORY row (or a pure in-memory DTS) -> the foliated <dfID>_df column that
% writeDF lays down on the row.
    tf  = false;
    DTS = nexon.console.BASE.DTS;
    dfc = char(dfColName);

    rowRoot = '';
    if isDiskBacked, rowRoot = char(DTS.h5_root(rowIdx)); end

    if isDiskBacked && ~isempty(rowRoot)
        if isempty(h5FileOut) || ~exist(h5FileOut, 'file'), return; end
        fapl = H5P.create('H5P_FILE_ACCESS');
        H5P.set_fclose_degree(fapl, 'H5F_CLOSE_STRONG');
        fid  = H5F.open(h5FileOut, 'H5F_ACC_RDONLY', fapl);
        H5P.close(fapl);
        grp = [rowRoot '/' dfc];
        try
            tf = H5L.exists(fid, [grp '/df'],    'H5P_DEFAULT') || ...
                 H5L.exists(fid, [grp '/df_im'], 'H5P_DEFAULT');
        catch
        end
        H5F.close(fid);
    else
        % in-memory row (hybrid) or pure in-memory DTS: foliated <dfID>_df column
        col = [dfc '_df'];
        tf  = ismember(col, DTS.Properties.VariableNames) && ...
              rowIdx <= height(DTS) && iscell(DTS.(col)) && ~isempty(DTS.(col){rowIdx});
    end
end