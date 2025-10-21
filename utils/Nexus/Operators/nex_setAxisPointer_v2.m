function DF = nex_setAxisPointer_v2(DF, axSel, axVal)
    % move selected axis pointers
    axFields = convertCharsToStrings(fieldnames(DF.ax));
    % axSel = axFields{dim};    
    if ~isfield(DF,"ptr")
        DF.ptr=struct;
        for i = 1:length(axFields)
            axField = axFields{i};
            DF.ptr.(axField).value=1;
        end
    end
    DF.ptr.(axSel).value = axVal;
end