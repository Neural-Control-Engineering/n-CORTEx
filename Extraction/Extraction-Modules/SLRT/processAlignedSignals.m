function SLRT = processAlignedSignals(SLRT, signalID, newSignalID, procFcn, procArgs)
    slrtCols = SLRT.Properties.VariableNames;
    idx_alignedSignalCols = find(contains(slrtCols, signalID) & contains(slrtCols,"aligned") & ~contains(slrtCols,"time"));
    alignedSignalCols = slrtCols(idx_alignedSignalCols);
    for i = 1:length(alignedSignalCols)
        alignedSignalID = alignedSignalCols{i};
        alignedSignalCol = SLRT.(alignedSignalID);
        S = {};
        parfor j = 1:length(alignedSignalCol)
            x = alignedSignalCol{j};
            S{j} = procFcn(x, procArgs);
        end
        % assign new, corresponding aligned col
        newAlignedSignalID = strrep(alignedSignalID,signalID,newSignalID);
        SLRT.(newAlignedSignalID) = S';
        % propagate time col
        alignedSignalTimeID = sprintf("%s_time",alignedSignalID);
        newAlignedSignalTimeID = strrep(alignedSignalTimeID,signalID, newSignalID);
        SLRT.(newAlignedSignalTimeID) = SLRT.(alignedSignalTimeID);
    end
end