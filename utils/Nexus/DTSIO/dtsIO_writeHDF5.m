function dtsIO_writeHDF5(nexon, DF, DFID, dtsIdx)
% Write a DF struct to HDF5 when DTS is in disk-backed manifest mode.
% Called exclusively from dtsIO_writeDF after it detects h5_path in DTS.
%
%   dtsIdx : numeric row index (update existing row)
%              OR struct with sessionLabel + trialNumber (new row)

    DTS    = nexon.console.BASE.DTS;
    h5File = char(DTS.h5_path(1));   % all rows share the same file

    if isnumeric(dtsIdx)
        % ── Update existing row ─────────────────────────────────────────
        h5Root = char(DTS.h5_root(dtsIdx));
        writeDF_toHDF5(h5File, h5Root, DFID, DF);

    elseif isstruct(dtsIdx)
        % ── New row: write data + append manifest row ───────────────────
        sl   = string(dtsIdx.sessionLabel);
        tNum = dtsIdx.trialNumber;

        parts  = strsplit(sl, "--");
        parts  = parts(~cellfun('isempty', parts));
        h5Root = "/" + strjoin([parts(:)', {sprintf("trial_%04d", tNum)}], "/");

        writeDF_toHDF5(h5File, h5Root, DFID, DF);

        % Build manifest row — matches disk-backed DTS schema
        manifestRow = table(sl, tNum, string(h5File), h5Root, ...
            'VariableNames', {'sessionLabel','trialNumber','h5_path','h5_root'});

        % Carry any extra metadata columns that dtsIdx provides
        extraFields = fieldnames(dtsIdx);
        extraFields = extraFields(~ismember(extraFields, ...
            {'sessionLabel','trialNumber'}));
        for i = 1:numel(extraFields)
            f = extraFields{i};
            if ~isstruct(dtsIdx.(f)) && ~iscell(dtsIdx.(f))
                manifestRow.(f) = dtsIdx.(f);
            end
        end

        nexon.appendToDTS(manifestRow);
    end
end

% ---------------------------------------------------------------------------
function writeDF_toHDF5(h5File, h5Root, DFID, DF)
    dtsIO_writeDF_toHDF5(h5File, h5Root, DFID, DF);
end
