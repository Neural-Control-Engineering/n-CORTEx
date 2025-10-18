function DF = nex_initAxisPointer(DF)
    % loop through ax fields and initiate ptr for each
    axFields = fieldnames(DF.ax);
    for i = 1:length(axFields)
        axField = axFields{i};
        DF.ptr.(axField)=1;
    end
end