function items = nexOp_enumerateCategory(nexObj, category)
    parts   = convertCharsToStrings(split(category,"--"));
    prefix  = parts(1);
    bareKey = parts(end);

    % Search 1: DF postOp axes
    try
        if isfield(nexObj.DF_postOp.ax, char(bareKey))
            items = nexObj.DF_postOp.ax.(char(bareKey));
            return;
        end
    catch
    end

    % Search 2: HDF5 dfID OR direct manifest ("var") column — read all values
    % and return the unique set. dtsIO_readTFH5 returns a {N×1} cell for HDF5
    % dfIDs, and the raw column (numeric / string / cell) for a direct manifest
    % column, so handle both shapes.
    if prefix == "h5" || prefix == "var"
        DTS = nexObj.nexon.console.BASE.DTS;
        raw = dtsIO_readTFH5(DTS, char(bareKey), [], 'simple');
        if prefix == "var"
            % Hybrid DTS: a manifest "var" column may be empty for disk-backed
            % rows whose value lives in HDF5 — fill so those values are listed.
            raw = dtsIO_hybridFillVar(DTS, char(bareKey), ':', raw);
        end
        if iscell(raw)
            nonEmpty = raw(~cellfun('isempty', raw));
            if ~isempty(nonEmpty) && (ischar(nonEmpty{1}) || isstring(nonEmpty{1}))
                items = unique(string(cellfun(@string, nonEmpty, 'UniformOutput', false)));
            else
                vals  = cellfun(@(c) scalarOrNaN(c), raw);
                items = unique(vals(~isnan(vals)));
            end
        elseif isnumeric(raw)
            items = unique(raw(~isnan(raw)));
        else
            items = unique(string(raw));
        end
        return;
    end

    % Search 3: registry
    switch class(nexObj)
        case "nexon"
            items = nexObj.console.BASE.registry.categories.(char(bareKey));
        otherwise
            items = nexObj.nexon.console.BASE.registry.categories.(char(bareKey));
    end
end

function v = scalarOrNaN(c)
    if isnumeric(c) && isscalar(c)
        v = double(c);
    else
        v = NaN;
    end
end