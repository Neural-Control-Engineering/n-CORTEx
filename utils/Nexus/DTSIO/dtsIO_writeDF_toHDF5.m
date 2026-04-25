function dtsIO_writeDF_toHDF5(h5File, h5Root, DFID, DF)
% Write one DF struct into an HDF5 file under h5Root/DFID/.
% Writes df array, axis arrays, args, and a dim_order attribute on df.
% Shared by dtsIO_writeHDF5 and nexus_exportDTS.

    axisKeyWords = ["f","t","chans","factor","dropout","latent"];

    if isfield(DF, 'df') && ~isempty(DF.df)
        dsetPath = [h5Root '/' DFID '/df'];
        h5writeSafe(h5File, dsetPath, double(DF.df));
        dimOrder = resolveDimOrder(DF);
        if ~isempty(dimOrder)
            h5writeatt(h5File, dsetPath, 'dim_order', dimOrder);
        end
    end

    if isfield(DF, 'ax')
        axFields = fieldnames(DF.ax);
        for k = 1:numel(axFields)
            suf = axFields{k};
            if any(strcmp(axisKeyWords, suf)) && ~isempty(DF.ax.(suf))
                h5writeSafe(h5File, [h5Root '/' DFID '/' suf], double(DF.ax.(suf)));
            end
        end
    end

    if isfield(DF, 'args') && isnumeric(DF.args) && ~isempty(DF.args)
        h5writeSafe(h5File, [h5Root '/' DFID '/args'], double(DF.args));
    end
end

% ── Helpers ───────────────────────────────────────────────────────────────

function dimOrder = resolveDimOrder(DF)
% Comma-separated axis names in array-dimension order, e.g. "chans,t".
% Uses DF.ptr.dim when present; falls back to length matching.
    if ~isfield(DF, 'ax') || isempty(DF.df)
        dimOrder = '';
        return;
    end
    axFields  = fieldnames(DF.ax);
    nDims     = ndims(DF.df);
    dimNames  = repmat({''}, 1, nDims);
    dimsTaken = [];

    for k = 1:numel(axFields)
        f = axFields{k};
        d = [];
        try
            d = DF.ptr.(f).dim;   % authoritative when ptr is present
        catch
        end
        if isempty(d)
            axLen = numel(DF.ax.(f));
            dims  = find(axLen == size(DF.df));
            for j = 1:numel(dims)
                if ~ismember(dims(j), dimsTaken)
                    d = dims(j);
                    break;
                end
            end
        end
        if ~isempty(d) && d >= 1 && d <= nDims && isempty(dimNames{d})
            dimNames{d} = f;
            dimsTaken(end+1) = d; %#ok<AGROW>
        end
    end
    dimOrder = strjoin(dimNames, ',');
end

function h5writeSafe(h5File, dset, arr)
    try
        h5create(h5File, dset, size(arr), 'Datatype', 'double');
    catch ME
        if ~contains(ME.message, 'already exists')
            rethrow(ME);
        end
    end
    h5write(h5File, dset, arr);
end
