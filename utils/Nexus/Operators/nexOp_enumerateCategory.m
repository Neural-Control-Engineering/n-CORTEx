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

    % Search 2: HDF5 flat dfID — read all values and return unique set
    if prefix == "h5"
        DTS      = nexObj.nexon.console.BASE.DTS;
        raw      = dtsIO_readTFH5(DTS, char(bareKey), [], 'simple');
        nonEmpty = raw(~cellfun('isempty', raw));
        if ~isempty(nonEmpty) && (ischar(nonEmpty{1}) || isstring(nonEmpty{1}))
            items = unique(string(cellfun(@string, nonEmpty, 'UniformOutput', false)));
        else
            vals  = cellfun(@(c) scalarOrNaN(c), raw);
            items = unique(vals(~isnan(vals)));
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