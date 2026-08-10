function dtsIO_writeDF(nexon, DF, DFID, dtsIdx, forceMem)
    % general purpose data-frame writing from nexus datastore
    %
    % forceMem (optional, default false): when true, bypass the disk-backed path
    %   and write in-memory even if the DTS has an h5_path column. Use this for
    %   realtime capture so new trials land in a hybrid in-memory row and are only
    %   flushed to disk on an explicit sink. New rows written with forceMem=true
    %   receive h5_path="" so the table stays concat-compatible with the manifest.
    if nargin < 5, forceMem = false; end

    DTS = nexon.console.BASE.DTS;
    % An uninitialized DTS is [] (not a table) — a fresh in-memory nexon before
    % its first write. Only probe for the disk-backed h5_path column once DTS is
    % actually a table; otherwise fall through to the in-memory new-row path
    % (nex_searchRowAddress + appendToDTS both handle an empty base).
    if ~forceMem && istable(DTS) && ismember('h5_path', DTS.Properties.VariableNames)
        dtsIO_writeHDF5(nexon, DF, char(DFID), dtsIdx);
        return;
    end

    % classify input DF
    if isstruct(DF)
        dfType = 'DF';
    else
        dfType = 'df';
    end
    % classify index type
    if isstruct(dtsIdx)
        % search logic and fieldname logic
        rowIdx = nex_searchRowAddress(nexon.console.BASE.DTS, dtsIdx);
        if isempty(rowIdx)
            % start a new row (with address coordinates (e.g. sl, trialNum,
            % etc.))
            % for i = 1:length(addressFields)
            %     writeDataFrame(nexon, dfColName, df, rowIdx);
            % end
            rowStruct = dtsIdx;
            rowStruct.(DFID) = DF;
            row_dts = dtsIO_compileDTS(rowStruct, []);
            % Pad h5 routing columns so this row is concat-compatible with any
            % manifest rows already in the DTS (hybrid mode).
            if istable(DTS) && ismember('h5_path', DTS.Properties.VariableNames)
                row_dts.h5_path = "";
                row_dts.h5_root = "";
            end
            nexon.appendToDTS(row_dts);
        else
            % alternate storage method
            switch dfType
                case 'DF'
                    writeDF(nexon, DFID, DF, rowIdx);
                case 'df'
                    writeDataframe(nexon, DFID, DF, rowIdx);
            end
        end
        
    else
        % alternate storage method
        switch dfType
            case 'DF'
                writeDF(nexon, DFID, DF, dtsIdx);
            case 'df'
                writeDataframe(nexon, DFID, DF, dtsIdx);
        end
    end
    
end