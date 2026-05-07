function DTS_manifest = nexus_exportDTS(DTS, h5File)
% Export in-memory DTS to HDF5. Returns a lightweight manifest table.
%
%   DTS_manifest = nexus_exportDTS(DTS, '/data/nexus_dts.h5')
%
% DTS          : nexon.console.BASE.DTS (in-memory trial table)
% h5File       : absolute path for HDF5 output (created or appended)
%
% DTS_manifest : same sessionLabel / trialNumber rows, plus h5_path and
%                h5_root columns — no data arrays. Assign it back to
%                nexon.console.BASE.DTS to enable the disk-backed IO path.
%
% HDF5 layout  : /{subject}/{date}/{phase}/trial_{N:04d}/{dfid}/{suffix}
%
% All dtsIO_* functions detect the manifest automatically (h5_path column
% present) and switch to h5read — no other code changes required.

    tableVars = string(DTS.Properties.VariableNames);
    metaCols  = ["sessionLabel","trialNumber"];
    allExtra  = tableVars(~ismember(tableVars, metaCols));

    % Classify extra columns: numeric DF data (→ HDF5) vs metadata (→ manifest).
    % Check first non-empty cell to determine type.
    isNumericDF = false(1, numel(allExtra));
    for j = 1:numel(allExtra)
        col = DTS.(char(allExtra(j)));
        if iscell(col)
            idx = find(~cellfun('isempty', col), 1);
            isNumericDF(j) = ~isempty(idx) && isnumeric(col{idx});
        elseif isnumeric(col)
            isNumericDF(j) = true;
        end
    end
    dataCols  = allExtra(isNumericDF);   % go to HDF5
    extraMeta = allExtra(~isNumericDF);  % non-numeric: preserved in manifest as-is

    % Identify dfID and suffix for each numeric data column.
    % Convention: last _-separated token is the suffix; everything before is dfID.
    nData    = numel(dataCols);
    colDFIDs = strings(1, nData);
    colSuffs = strings(1, nData);
    for j = 1:nData
        parts = strsplit(dataCols(j), "_");
        if numel(parts) == 1
            colDFIDs(j) = parts{1};
            colSuffs(j) = "df";
        else
            colDFIDs(j) = strjoin(parts(1:end-1), "_");
            colSuffs(j) = parts{end};
        end
    end

    nRows    = height(DTS);
    h5Roots  = strings(nRows, 1);

    uniqueDFIDs = unique(colDFIDs, 'stable');

    fprintf('Exporting %d trials to %s ...\n', nRows, h5File);
    for i = 1:nRows
        sl   = string(DTS.sessionLabel(i));
        tNum = DTS.trialNumber(i);

        % Build HDF5 group: split sessionLabel on "--", keep parts as hierarchy
        parts  = strsplit(sl, "--");
        parts  = strtrim(parts(~cellfun('isempty', parts)));
        h5Root = "/" + strjoin([parts(:)', {sprintf("trial_%04d", tNum)}], "/");
        h5Roots(i) = h5Root;

        % Reconstruct one DF struct per dfID and write through the shared writer
        % (dtsIO_writeDF_toHDF5 handles dim_order, axis arrays, and writeSafe)
        for d = 1:numel(uniqueDFIDs)
            dfid = uniqueDFIDs(d);
            mask = colDFIDs == dfid;
            DF   = struct();

            for j = find(mask)
                suf = char(colSuffs(j));
                raw = DTS.(char(dataCols(j)));
                arr = [];
                if iscell(raw) && numel(raw) >= i
                    arr = raw{i};
                elseif isnumeric(raw) && size(raw,1) >= i
                    arr = raw(i,:);
                end
                if isempty(arr) || ~isnumeric(arr), continue; end

                if strcmp(suf, 'df')
                    DF.df = double(arr);
                else
                    DF.ax.(suf) = double(arr);
                end
            end

            if ~isfield(DF, 'df'), continue; end

            % Build ptr so dim_order uses the authoritative path
            if isfield(DF, 'ax')
                DF = nex_initAxisPointer_v2(DF);
            end

            dtsIO_writeDF_toHDF5(h5File, char(h5Root), char(dfid), DF);
        end

        if mod(i, 50) == 0
            fprintf('  %d / %d trials written\n', i, nRows);
        end
    end
    fprintf('Export complete.\n');

    % Build manifest: metaCols + non-numeric columns + routing columns
    DTS_manifest = DTS(:, cellstr([metaCols, extraMeta]));
    DTS_manifest.h5_path = repmat(string(h5File), nRows, 1);
    DTS_manifest.h5_root = h5Roots;
end

