function DF = nex_initAxisPointer_v2(DF)
    % Flat/scalar DF -- e.g. a plain per-trial category value compiled as
    % its own dfID (responseThreshold_g-style), which has no axes at all.
    % Confirmed directly: this previously assumed DF.ax unconditionally
    % present, erroring "Unrecognized field name 'ax'" on a DF with no
    % such field. Nothing to build a pointer for -- empty ax/ptr instead
    % of erroring. Every downstream consumer (nexStat_breakoutDF's own
    % DF.ax/DF.ptr table row, nexOp_sliceDF/nexOp_buildSliceIndex) already
    % tolerates an empty struct here, just not a MISSING field.
    if ~isfield(DF, 'ax')
        DF.ax  = struct();
        DF.ptr = nexObj_ptr(struct());
        return;
    end
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
