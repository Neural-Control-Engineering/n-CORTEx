function dict = dtsIO_buildDictionary(DTS, dfIDs)
    % given list of DTS cols, retrieve unique values and compile into a
    % struct-like dictionary with dfIDs as struct fields
    dict = struct;
    for i = 1:length(dfIDs)
        dfID = dfIDs(i);
        try
            dfCol = DTS.(dfID);
        catch
            try
                dfCol = dtsIO_readTFH5(DTS, dfID, [],'simple');
            catch
                keyboard
            end
            % dfCol = dtsIO_readTFH5(DTS, dfID, []);
            dfCol = cat(1,dfCol{:});
        end
        uniqueVals = unique(dfCol);
        % uniqueVals = unique(DTS.(dfID));
        dict.(dfID) = uniqueVals;
    end
end