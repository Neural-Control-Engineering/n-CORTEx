function dict = dtsIO_buildDictionary(DTS, dfIDs)
    % given list of DTS cols, retrieve unique values and compile into a
    % struct-like dictionary with dfIDs as struct fields
    dict = struct;
    for i = 1:length(dfIDs)
        dfID = dfIDs(i);
        uniqueVals = unique(DTS.(dfID));
        dict.(dfID) = uniqueVals;
    end
end