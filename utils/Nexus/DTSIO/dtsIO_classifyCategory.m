function categoryType = dtsIO_classifyCategory(DTS, category)
    dtsVars = DTS.Properties.VariableNames;

    % Priority 1: sessionLabel-nested field
    TF_sl = DTS.sessionLabel;
    TF    = cellfun(@(var) parseSessionLabel(convertCharsToStrings(var), category), ...
                    TF_sl, "UniformOutput", false);
    TF    = cat(1, TF{:});
    if ~isempty(TF)
        categoryType = "sessionLabel";
        return;
    end

    % Priority 2: direct manifest table column
    if ismember(category, dtsVars)
        categoryType = "var";
        return;
    end

    % Priority 3: HDF5 dfID (disk-backed manifest only)
    if ismember('h5_path', dtsVars)
        allIDs = dtsIO_readDFIDs(DTS);
        if ismember(category, allIDs)
            categoryType = "h5";
            return;
        end
    end

    categoryType = [];
end