function DF = nex_initAxisPointer_v2(DF)
    % loop through ax fields and initiate ptr for each
    axFields = fieldnames(DF.ax);
    df = DF.df;
    for i = 1:length(axFields)
        axField = axFields{i};
        ax = DF.ax.(axField);
        axLen = length(ax);
        dim = find(axLen==size(df));
        DF.ptr.(axField).value=1;
        DF.ptr.(axField).dim = dim;
    end
    % upgrade to nexPtr
    DF.ptr = nexObj_ptr(DF.ptr);
end