function DTS_manifest = nexus_exportDTS(DTS, h5File)
% Export in-memory DTS to HDF5. Returns a lightweight manifest table.
%
%   DTS_manifest = nexus_exportDTS(DTS, '/data/nexus_dts.h5')
%
% DTS          : nexon.console.BASE.DTS (in-memory trial table)
% h5File       : absolute path for HDF5 output (created or appended)
%
% DTS_manifest : sessionLabel / trialNumber (+ signal_types if present) rows,
%                plus h5_path and h5_root routing columns — no data arrays.
%                Assign it back to nexon.console.BASE.DTS to enable disk-backed IO.
%
% HDF5 layout  : /{subject}/{date}/{phase}/trial_{N:04d}/{dfid}/{suffix}   (DF columns)
%                /{subject}/{date}/{phase}/trial_{N:04d}/{colName}          (simple columns)
%
% All dtsIO_* functions detect the manifest automatically (h5_path column
% present) and switch to h5read — no other code changes required.

    tableVars = string(DTS.Properties.VariableNames);

    % ── Manifest columns (everything else goes to HDF5) ───────────────────
    manifestCols = ["sessionLabel", "trialNumber"];
    if ismember("signal_types", tableVars)
        manifestCols(end+1) = "signal_types";
    end

    h5Cols = tableVars(~ismember(tableVars, manifestCols));

    % ── Classify h5 columns ───────────────────────────────────────────────
    % DF-group columns : cell arrays whose first non-empty element is a
    %                    non-scalar numeric array (e.g. lfp_df, lfp_t).
    %                    Written via dtsIO_writeDF_toHDF5.
    % Simple columns   : everything else (scalars, strings, cell-of-strings,
    %                    cell-of-scalars). Written as one dataset per trial.
    % DF columns: numeric arrays, OR string/cellstr arrays whose stub (last
    % _token) is a recognized axis key (e.g. a 'measure' label axis) so they fold
    % into the DF group as a string axis instead of spilling out as a simple
    % column. String columns whose stub is NOT an axis key (e.g. *_quality) stay
    % simple. Keep this list synchronized with the other DTSIO axisKeyWords.
    axisKeyWords = nex_axisKeyWords();
    isArrayDF = false(1, numel(h5Cols));
    for j = 1:numel(h5Cols)
        col = DTS.(char(h5Cols(j)));
        if iscell(col)
            idx = find(~cellfun('isempty', col), 1);
            if ~isempty(idx)
                v = col{idx};
                parts = strsplit(h5Cols(j), "_");
                stubIsAxis = numel(parts) > 1 && any(strcmp(axisKeyWords, parts{end}));
                isArrayDF(j) = (isnumeric(v) && ~isscalar(v)) || ...
                               ((isstring(v) || iscellstr(v)) && stubIsAxis);
            end
        end
    end

    dfCols     = h5Cols(isArrayDF);
    simpleCols = h5Cols(~isArrayDF);

    % Drop simpleCols whose values are tables, structs, or handle objects —
    % these require dedicated writers and cannot be written by h5writeSimple.
    h5writable = true(1, numel(simpleCols));
    for j = 1:numel(simpleCols)
        col = DTS.(char(simpleCols(j)));
        if iscell(col)
            idx = find(~cellfun('isempty', col), 1);
            if ~isempty(idx)
                v = col{idx};
                h5writable(j) = ~istable(v) && ~isstruct(v) && ~isobject(v);
            end
        elseif istable(col) || isstruct(col) || isobject(col)
            h5writable(j) = false;
        end
    end
    if any(~h5writable)
        fprintf('  Skipping non-writable columns (table/struct/object): %s\n', ...
            strjoin(simpleCols(~h5writable), ', '));
    end
    simpleCols = simpleCols(h5writable);

    % Build dfID / suffix mapping for DF-group columns
    nDF      = numel(dfCols);
    colDFIDs = strings(1, nDF);
    colSuffs = strings(1, nDF);
    for j = 1:nDF
        parts = strsplit(dfCols(j), "_");
        if numel(parts) == 1
            colDFIDs(j) = parts{1};
            colSuffs(j) = "df";
        else
            colDFIDs(j) = strjoin(parts(1:end-1), "_");
            colSuffs(j) = parts{end};
        end
    end
    uniqueDFIDs = unique(colDFIDs, 'stable');

    nRows   = height(DTS);
    h5Roots = strings(nRows, 1);

    fprintf('Exporting %d trials to %s ...\n', nRows, h5File);
    for i = 1:nRows
        sl   = string(DTS.sessionLabel(i));
        tNum = DTS.trialNumber(i);

        h5Root = nex_buildH5Root(sl, tNum);
        h5Roots(i) = h5Root;

        % DF-group columns → reconstruct DF struct per dfID → dtsIO_writeDF_toHDF5
        for d = 1:numel(uniqueDFIDs)
            dfid = uniqueDFIDs(d);
            mask = colDFIDs == dfid;
            DF   = struct();

            for j = find(mask)
                suf = char(colSuffs(j));
                raw = DTS.(char(dfCols(j)));
                arr = [];
                if iscell(raw) && numel(raw) >= i
                    arr = raw{i};
                elseif isnumeric(raw) && size(raw,1) >= i
                    arr = raw(i,:);
                end
                if isempty(arr), continue; end

                if strcmp(suf, 'df')
                    if isnumeric(arr), DF.df = double(arr); end
                elseif isnumeric(arr)
                    DF.ax.(suf) = double(arr);
                elseif isstring(arr) || iscellstr(arr)
                    DF.ax.(suf) = string(arr);   % string axis (e.g. measure labels)
                end
            end

            if ~isfield(DF, 'df'), continue; end
            if isfield(DF, 'ax')
                DF = nex_initAxisPointer_v2(DF);
            end
            dtsIO_writeDF_toHDF5(h5File, char(h5Root), char(dfid), DF);
        end

        % Simple columns → one dataset per column directly under h5Root
        for j = 1:numel(simpleCols)
            colName = char(simpleCols(j));
            raw = DTS.(colName);
            val = extractTrialVal(raw, i);
            if isempty(val), continue; end
            h5writeSimple(h5File, [char(h5Root) '/' colName], val);
        end

        if mod(i, 50) == 0
            fprintf('  %d / %d trials written\n', i, nRows);
        end
    end
    fprintf('Export complete.\n');

    % ── Build manifest ────────────────────────────────────────────────────
    DTS_manifest = DTS(:, cellstr(manifestCols));
    DTS_manifest.h5_path = repmat(string(h5File), nRows, 1);
    DTS_manifest.h5_root = h5Roots;
end

% ── Local helpers ─────────────────────────────────────────────────────────────

function val = extractTrialVal(raw, i)
% Extract the i-th trial value from any column type.
    val = [];
    if iscell(raw)
        if numel(raw) >= i && ~isempty(raw{i}), val = raw{i}; end
    elseif isnumeric(raw)
        if size(raw,1) >= i, val = raw(i,:); end
    elseif isstring(raw)
        if numel(raw) >= i, val = raw(i); end
    elseif ischar(raw)
        % char matrix: rows are trials, columns are characters
        if size(raw,1) >= i, val = strtrim(raw(i,:)); end
    elseif iscategorical(raw)
        if numel(raw) >= i, val = string(raw(i)); end
    end
end

function h5writeSimple(h5File, dset, val)
% Write a scalar, numeric array, or string/char/categorical value as an HDF5 dataset.
    if isnumeric(val)
        arr = double(val);
        try
            h5create(h5File, dset, size(arr), 'Datatype', 'double');
        catch ME
            if ~contains(ME.message, 'already exists'), rethrow(ME); end
            fid = H5F.open(h5File, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            H5L.delete(fid, dset, 'H5P_DEFAULT');
            H5F.close(fid);
            h5create(h5File, dset, size(arr), 'Datatype', 'double');
        end
        h5write(h5File, dset, arr);
    else
        % Normalise all text types → cellstr before passing to h5write
        c = cellstr(string(val));
        try
            h5create(h5File, dset, size(c), 'Datatype', 'string');
        catch ME
            if ~contains(ME.message, 'already exists'), rethrow(ME); end
        end
        h5write(h5File, dset, c);
    end
end
