function categoryType = dtsIO_classifyCategory(DTS, category)
    % search the datastore
    dtsVars = DTS.Properties.VariableNames;
    % priority 1 (sessionLabel)
    TF_sl = DTS.sessionLabel;
    TF = cellfun(@(var) parseSessionLabel(convertCharsToStrings(var), category), TF_sl, "UniformOutput", false);
    % TF_sl = dtsIO_readTF_category(DTS, category, []);
    % TF_t = cellfun(@(var) parseSessionLabel(convertCharsToStrings(var), "vhtScore"), TF_sl, "UniformOutput", false);
    TF = cat(1,TF{:});
    if isempty(TF)
        % priority 2 (var)
        isVar = ismember(category, dtsVars);
        if isVar
            categoryType = "var"; % did find key in the other var columns
        else
            categoryType = [];
        end
    else
        categoryType = "sessionLabel"; % did find key in the sessionLabel column
    end
    
    % identify and return
end