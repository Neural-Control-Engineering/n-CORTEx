function DF = nex_initAxisPointer_v2(DF)
    % loop through ax fields and initiate ptr for each
    axFields = fieldnames(DF.ax);
    df = DF.df;
    dimsTaken = [];

    % Co-indexed labels (e.g. per-unit 'chans') yield a shared dimension to their
    % sibling axis (e.g. 'unit') instead of claiming it by field order — keeps
    % this path consistent with nexInit_axisPointer.
    coIndexLabels = nex_coIndexAxisLabels();
    axLens        = cellfun(@(f) length(DF.ax.(f)), axFields);

    for i = 1:length(axFields)
        axField = axFields{i};
        ax = DF.ax.(axField);
        axLen = length(ax);

        if ismember(string(axField), coIndexLabels) && sum(axLens == axLen) > 1
            axDim = [];   % co-indexed label with a sibling of the same length — yield the dim
        else
            dims  = find(axLen == size(df));
            axDim = [];
            for j = 1:length(dims)
                if ~ismember(dims(j), dimsTaken)
                    axDim = dims(j);
                    break
                end
            end
            if ~isempty(axDim), dimsTaken = [dimsTaken, axDim]; end
        end

        DF.ptr.(axField).dim    = axDim;
        DF.ptr.(axField).value  = 1;
        DF.ptr.(axField).range  = [1, axLen];   % start/end indices for display range
        DF.ptr.(axField).window = axLen;        % view window size; initialized to full range
    end
    % upgrade to nexPtr
    DF.ptr = nexObj_ptr(DF.ptr);
end
