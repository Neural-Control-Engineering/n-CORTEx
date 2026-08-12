function ptr = nexInit_axisPointer(df, ax)
    % Build a nexObj_ptr from a df array and ax struct.
    % Infers .dim for each ax field by matching axis length to df array dimensions.
    % Mirrors nex_initAxisPointer_v2 but takes (df, ax) directly rather than a DF struct.
    %
    % Usage:
    %   ptr = nexInit_axisPointer(df_pooled.df, df_pooled.ax)

    axFields  = fieldnames(ax);
    dimsTaken = [];
    sPtr      = struct();

    % Co-indexed labels (e.g. per-unit 'chans') yield a shared dimension to their
    % sibling axis (e.g. 'unit') instead of claiming it by field order.
    coIndexLabels = nex_coIndexAxisLabels();
    axLens        = cellfun(@(f) numel(ax.(f)), axFields);

    for i = 1:numel(axFields)
        f     = axFields{i};
        axLen = numel(ax.(f));

        if ismember(string(f), coIndexLabels) && sum(axLens == axLen) > 1
            dim = [];   % co-indexed label with a sibling of the same length — yield the dim
        else
            dims = find(axLen == size(df));
            dim  = [];
            for j = 1:numel(dims)
                if ~ismember(dims(j), dimsTaken)
                    dim = dims(j);
                    break;
                end
            end
            if ~isempty(dim), dimsTaken = [dimsTaken, dim]; end
        end

        sPtr.(f).dim    = dim;
        sPtr.(f).value  = 1;
        sPtr.(f).range  = [1, axLen];
        sPtr.(f).window = axLen;
    end

    ptr = nexObj_ptr(sPtr);
end
