function DTS_out = nexus_spliceDTS(DTS_manifest, DTS_source, dfIDs)
% Splice specific dfIDs from DTS_source into an existing DTS_manifest.
% Rows are matched by (sessionLabel, trialNumber) pair — order need not match.
%
%   DTS_out = nexus_spliceDTS(DTS_manifest, DTS_source, dfIDs)
%
%   DTS_manifest : current manifest (disk-backed or in-memory)
%   DTS_source   : original in-memory DTS containing the columns to add
%   dfIDs        : string array of dfID names to splice, e.g. ["signal_types","lfp"]
%
% Non-numeric dfIDs (e.g. signal_types) are added as columns in the returned
% manifest table.  Numeric dfIDs are written to HDF5 via the manifest's
% h5_path / h5_root — DTS_out is unchanged for those columns.
%
% After calling, save the returned DTS_out back to wherever DTS_manifest lives.

    DTS_out    = DTS_manifest;
    isManifest = ismember('h5_path', DTS_manifest.Properties.VariableNames);

    % Row-match key: sessionLabel|trialNumber (unique per trial)
    srcKey = string(DTS_source.sessionLabel) + "|" + string(DTS_source.trialNumber);
    dstKey = string(DTS_manifest.sessionLabel) + "|" + string(DTS_manifest.trialNumber);

    for di = 1:numel(dfIDs)
        dfID = char(dfIDs(di));

        % Find all source columns belonging to this dfID
        srcVars  = string(DTS_source.Properties.VariableNames);
        colMask  = srcVars == dfID | startsWith(srcVars, dfID + "_");
        colNames = srcVars(colMask);

        if isempty(colNames)
            warning('[nexus_spliceDTS] dfID "%s" not found in DTS_source — skipped', dfID);
            continue;
        end

        % Classify by content of the primary column
        sampleCol = DTS_source.(char(colNames(1)));
        if iscell(sampleCol)
            idx = find(~cellfun('isempty', sampleCol), 1);
            isNumeric = ~isempty(idx) && isnumeric(sampleCol{idx});
        else
            isNumeric = isnumeric(sampleCol);
        end

        if isNumeric
            % ── Numeric: write DF to HDF5 trial-by-trial ─────────────────
            if ~isManifest
                warning('[nexus_spliceDTS] DTS_manifest is not disk-backed; skipping numeric dfID "%s"', dfID);
                continue;
            end
            h5File = char(DTS_manifest.h5_path(1));
            nWritten = 0;
            for r = 1:height(DTS_manifest)
                srcIdx = find(srcKey == dstKey(r), 1);
                if isempty(srcIdx), continue; end

                DF = struct();
                for ci = 1:numel(colNames)
                    col = char(colNames(ci));
                    raw = DTS_source.(col);
                    arr = [];
                    if iscell(raw) && numel(raw) >= srcIdx
                        arr = raw{srcIdx};
                    elseif isnumeric(raw) && size(raw,1) >= srcIdx
                        arr = raw(srcIdx,:);
                    end
                    if isempty(arr) || ~isnumeric(arr), continue; end

                    if strcmp(col, dfID)
                        DF.df = double(arr);
                    else
                        suf = char(extractAfter(col, dfID + "_"));
                        if strcmp(suf,'df'),  DF.df = double(arr);
                        else,                 DF.ax.(suf) = double(arr); end
                    end
                end

                if ~isfield(DF,'df'), continue; end
                if isfield(DF,'ax'), DF = nex_initAxisPointer_v2(DF); end

                h5Root = char(DTS_manifest.h5_root(r));
                dtsIO_writeDF_toHDF5(h5File, h5Root, dfID, DF);
                nWritten = nWritten + 1;
            end
            fprintf('[nexus_spliceDTS] "%s" → HDF5  (%d / %d trials)\n', ...
                    dfID, nWritten, height(DTS_manifest));

        else
            % ── Non-numeric: add column(s) directly to manifest table ─────
            for ci = 1:numel(colNames)
                col     = char(colNames(ci));
                raw     = DTS_source.(col);
                isCell  = iscell(raw);
                colData = cell(height(DTS_manifest), 1);

                for r = 1:height(DTS_manifest)
                    srcIdx = find(srcKey == dstKey(r), 1);
                    if isempty(srcIdx), continue; end
                    if isCell,    colData{r} = raw{srcIdx};
                    else,         colData{r} = raw(srcIdx); end
                end

                % If source column was not a cell, try to flatten back to array
                if ~isCell
                    try, colData = cell2mat(colData); catch, end
                end
                DTS_out.(col) = colData;
            end
            fprintf('[nexus_spliceDTS] "%s" → manifest table\n', dfID);
        end
    end
end
