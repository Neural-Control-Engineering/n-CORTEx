function TF = dtsIO_readTF_category(dataObj, category, idxSel)
    categoryParts = split(category,"--");
    categoryLabel = categoryParts(1);
    categoryID = categoryParts(2);
    switch categoryLabel
        case "sessionLabel"
            TF = dtsIO_readVar(dataObj, categoryLabel, idxSel);
            TF = cellfun(@(var) parseSessionLabel(convertCharsToStrings(var), categoryID), TF, "UniformOutput", true);
        case "var"        
            TF = dtsIO_readVar(dataObj, categoryID, idxSel);
    end
end